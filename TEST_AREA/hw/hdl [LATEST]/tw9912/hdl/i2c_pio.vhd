library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utils.all;

entity i2c_pio is
    generic (
        CLK_FREQ : natural := 50000000;
        SCL_FREQ : natural := 1000000;
        I2C_ADDR : natural := 16#48#;
        PORT_LEN : natural := 4);       -- Port width will be 2^PORT_LEN
    port(
        signal clk   : std_logic;
        signal reset : std_logic;

        -- Avalon-MM slave interface
        signal address   : in  std_logic_vector(PORT_LEN downto 0);
        signal read      : in  std_logic;
        signal write     : in  std_logic;
        signal readdata  : out std_logic_vector(7 downto 0);
        signal writedata : in  std_logic_vector(7 downto 0);

        -- PCA9673 signals
        signal pio_int_n   : in    std_logic;
        signal pio_reset_n : out   std_logic;
        signal scl         : out   std_logic;
        signal sda         : inout std_logic);
end entity i2c_pio;

architecture rtl of i2c_pio is

    constant PORT_WIDTH             : natural                      := 2**PORT_LEN;
    constant NUM_CLK_PER_SCL_PERIOD : natural                      := CLK_FREQ / SCL_FREQ;
    constant NUM_I2C_TRANSFER       : natural                      := PORT_WIDTH / 8;
    constant I2C_ADDR_VECT          : std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(I2C_ADDR, 7));

    -- Registers
    signal busy_reg  : std_logic;
    signal error_reg : std_logic;
    signal read_reg  : std_logic_vector(PORT_WIDTH - 1 downto 0);
    signal write_reg : std_logic_vector(PORT_WIDTH - 1 downto 0);

    signal write_requested : std_logic;

    -- Internal control signals
    signal start : std_logic;
    signal rwx   : std_logic;

    -- I2C Internals
    signal i2c_scl_counter  : natural range 1 to NUM_CLK_PER_SCL_PERIOD;
    signal i2c_bit_counter  : natural range 1 to 8;
    signal i2c_byte_counter : natural range 1 to NUM_I2C_TRANSFER;

    type i2c_state is (IDLE, START_BIT_WAIT, START_BIT, SLAVE_ADDR, RW, ADDR_ACK, DATA, DATA_ACK, STOP_BIT_WAIT, STOP_BIT);
    signal i2c_state_transition_enabled   : std_logic;
    signal i2c_middle_of_high_scl_enabled : std_logic;
    signal i2c_current_state              : i2c_state;
begin

    pio_reset_n <= not reset;

    -- purpose: generates I2C clock (SCL) and internal enable pulse for state transition
    -- type   : sequential
    p_scl : process (clk, reset)
    begin
        if reset = '1' then
            i2c_scl_counter              <= 1;
            i2c_state_transition_enabled <= '0';
        elsif rising_edge(clk) then
            i2c_state_transition_enabled <= '0';
            if i2c_scl_counter = 3 * NUM_CLK_PER_SCL_PERIOD / 4 - 1 then
                i2c_state_transition_enabled <= '1';
            end if;

            i2c_middle_of_high_scl_enabled <= '0';
            if i2c_scl_counter = NUM_CLK_PER_SCL_PERIOD / 4 - 1 then
                i2c_middle_of_high_scl_enabled <= '1';
            end if;

            if i2c_scl_counter < NUM_CLK_PER_SCL_PERIOD then
                i2c_scl_counter <= i2c_scl_counter + 1;
            else
                i2c_scl_counter <= 1;
            end if;
        end if;
    end process p_scl;
    scl <= 'Z' when i2c_scl_counter < NUM_CLK_PER_SCL_PERIOD / 2 else '0';

    -- purpose: internal counters of i2c
    -- type   : sequential
    p_i2c_counters : process (clk, reset)
    begin
        if reset = '1' then
            i2c_bit_counter  <= 1;
            i2c_byte_counter <= 1;
        elsif rising_edge(clk) then
            -- byte counter
            if i2c_current_state = SLAVE_ADDR or i2c_current_state = DATA then
                if i2c_state_transition_enabled = '1' and i2c_bit_counter < 8 then
                    i2c_bit_counter <= i2c_bit_counter + 1;
                end if;
            else
                i2c_bit_counter <= 1;
            end if;

            -- transfer_counter
            if i2c_current_state = IDLE then
                i2c_byte_counter <= 1;
            elsif i2c_current_state = DATA_ACK and i2c_state_transition_enabled = '1' then
                if i2c_byte_counter < NUM_I2C_TRANSFER then
                    i2c_byte_counter <= i2c_byte_counter + 1;
                end if;
            end if;
        end if;
    end process p_i2c_counters;

    -- purpose: describes the state transition during i2c transfer
    -- type   : sequential
    p_i2c_fsm : process (clk, reset)
    begin
        if reset = '1' then
            i2c_current_state <= IDLE;
        elsif rising_edge(clk) then
            if i2c_state_transition_enabled = '1' then
                case i2c_current_state is
                    when IDLE =>
                        if start = '1' then
                            i2c_current_state <= START_BIT_WAIT;
                        end if;

                    when START_BIT =>
                        i2c_current_state <= SLAVE_ADDR;

                    when SLAVE_ADDR =>
                        if i2c_bit_counter = 7 then
                            i2c_current_state <= RW;
                        end if;

                    when RW =>
                        i2c_current_state <= ADDR_ACK;

                    when ADDR_ACK =>
                        i2c_current_state <= DATA;

                    when DATA =>
                        if i2c_bit_counter = 8 then
                            i2c_current_state <= DATA_ACK;
                        end if;

                    when DATA_ACK =>
                        if i2c_byte_counter = NUM_I2C_TRANSFER then
                            i2c_current_state <= STOP_BIT_WAIT;
                        else
                            i2c_current_state <= DATA;
                        end if;

                    when STOP_BIT =>
                        i2c_current_state <= IDLE;
                    when others => null;
                end case;

            -- Handle state transition for start and stop bit that happens
            -- while SCL is high
            elsif i2c_middle_of_high_scl_enabled = '1' then

                case i2c_current_state is
                    when START_BIT_WAIT =>
                        i2c_current_state <= START_BIT;

                    when STOP_BIT_WAIT =>
                        i2c_current_state <= STOP_BIT;



                    when others => null;
                end case;
            end if;

        end if;
    end process p_i2c_fsm;

    -- purpose: generate the sda pulse
    -- type   : combinational
    p_sda : process (i2c_bit_counter, i2c_current_state, rwx)
    begin
        sda <= 'Z';
        case i2c_current_state is
            when START_BIT =>
                sda <= '0';
            when STOP_BIT_WAIT =>
                sda <= '0';
            when SLAVE_ADDR =>
                sda <= I2C_ADDR_VECT(6 - i2c_bit_counter + 1);
            when RW =>
                sda <= rwx;

            when DATA =>

                if rwx = '0' then
                    -- Write
                    sda <= write_reg(PORT_WIDTH - 8 * (i2c_byte_counter - 1) - i2c_bit_counter) or read_reg(PORT_WIDTH - 8 * (i2c_byte_counter - 1) - i2c_bit_counter);
                end if;

            when others => null;
        end case;
    end process p_sda;
    busy_reg <= '1' when i2c_current_state /= IDLE else '0';

    -- purpose: reads in read register
    -- type   : sequential
    p_i2c_read : process (clk, reset)
    begin
        if reset = '1' then
            read_reg <= (others => '0');
        elsif rising_edge(clk) then
            if i2c_current_state = DATA and i2c_middle_of_high_scl_enabled = '1' then
                read_reg(PORT_WIDTH - 8 * (i2c_byte_counter - 1) - i2c_bit_counter) <= sda;
            end if;
        end if;
    end process p_i2c_read;

    -- purpose: triggers I2C transfers
    -- type   : sequential
    p_trigger : process (clk, reset)
    begin
        if reset = '1' then
            start <= '0';
            rwx   <= '1';
        elsif rising_edge(clk) then
            start <= '0';
            if busy_reg = '0' then
                if pio_int_n = '0' then
                    rwx   <= '1';
                    start <= '1';
                elsif write_requested = '1' then
                    rwx   <= '0';
                    start <= '1';
                end if;
            end if;
        end if;
    end process p_trigger;

    -- purpose: Avalon-MM Slave Write
    -- type   : sequential
    p_avalon_write : process (clk, reset)
    begin
        if reset = '1' then
            write_reg       <= (others => '0');
            write_requested <= '0';
        elsif rising_edge(clk) then
            if busy_reg = '1' and rwx = '0' then
                write_requested <= '0';
            end if;

            if write = '1' then
                if unsigned(address) < PORT_WIDTH then
                    if busy_reg = '0' and start = '0' then
                        write_reg(to_integer(unsigned(address))) <= writedata(0);
                        write_requested                          <= '1';
                    end if;
                end if;
            end if;
        end if;

    end process p_avalon_write;

    -- purpose: Avalon-MM Slave Read
    -- type   : sequential
    p_avalon_read : process (clk, reset)
    begin
        if reset = '1' then
            readdata <= (others => '0');
        elsif rising_edge(clk) then
            readdata <= (others => '0');
            if read = '1' then
                if unsigned(address) < PORT_WIDTH then
                    readdata(0) <= read_reg(to_integer(unsigned(address)));
                else
                    readdata(0) <= busy_reg or start;

                end if;
            end if;
        end if;
    end process p_avalon_read;

    -- purpose: detects error condition
    -- type   : sequential
    p_error_detection : process (clk, reset)
    begin
        if reset = '1' then
            error_reg <= '0';
        elsif rising_edge(clk) then
            case i2c_current_state is
                when ADDR_ACK | DATA_ACK =>
                    if i2c_middle_of_high_scl_enabled = '1' and sda /= '0' then
                        error_reg <= '1';
                    end if;

                when IDLE =>
                    if start = '1' and i2c_state_transition_enabled = '1' then
                        error_reg <= '0';
                    end if;

                when others => null;
            end case;
        end if;
    end process p_error_detection;

end architecture;
