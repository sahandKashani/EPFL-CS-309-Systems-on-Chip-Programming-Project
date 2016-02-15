library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mcp3204_spi is
    port(
        -- 50 MHz
        clk        : in  std_logic;
        reset      : in  std_logic;
        busy       : out std_logic;
        start      : in  std_logic;
        channel    : in  std_logic_vector(1 downto 0);
        data_valid : out std_logic;
        data       : out std_logic_vector(11 downto 0);

        -- 1 MHz
        SCLK       : out std_logic;
        CS_N       : out std_logic;
        MOSI       : out std_logic;
        MISO       : in  std_logic
    );
end mcp3204_spi;

architecture rtl of mcp3204_spi is
    signal reg_clk_divider_counter : unsigned(4 downto 0) := (others => '0'); -- need to be able to count until 24
    signal reg_spi_en              : std_logic            := '0'; -- pulses every 0.5 MHz
    signal reg_falling_edge_sclk   : std_logic            := '0';

    -- 1 MHz (not actuall "clocked" at 1 MHz, but rather "enabled" every 1 MHz)
    type state is (STATE_CS_N_HIGH, STATE_CS_N_LOW, STATE_START, STATE_SGL, STATE_D2, STATE_D1, STATE_D0, STATE_SAMPLE, STATE_NULL, STATE_D_IN);
    signal reg_state, next_reg_state : state := STATE_CS_N_HIGH;

    signal reg_channel, next_reg_channel           : std_logic_vector(channel'range) := (others => '0');
    signal reg_data_counter, next_reg_data_counter : unsigned(3 downto 0)            := (others => '0'); -- need to be able to count until 11

    -- registered outputs
    signal reg_busy, next_reg_busy             : std_logic                    := '0';
    signal reg_data_valid, next_reg_data_valid : std_logic                    := '0';
    signal reg_data, next_reg_data             : std_logic_vector(data'range) := (others => '0');
    signal reg_sclk                            : std_logic                    := '0';
    signal reg_cs_n, next_reg_cs_n             : std_logic                    := '0';
    signal reg_mosi, next_reg_mosi             : std_logic                    := '0';

begin
    busy       <= reg_busy;
    data_valid <= reg_data_valid;
    data       <= reg_data;
    SCLK       <= reg_sclk;
    CS_N       <= reg_cs_n;
    MOSI       <= reg_mosi;

    clk_divider_generation : process(clk, reset)
    begin
        if reset = '1' then
            reg_clk_divider_counter <= (others => '0');
        elsif rising_edge(clk) then
            reg_clk_divider_counter <= reg_clk_divider_counter + 1;
            reg_spi_en              <= '0';
            reg_falling_edge_sclk   <= '0';

            if reg_clk_divider_counter = 24 then
                reg_clk_divider_counter <= (others => '0');
                reg_spi_en              <= '1';

                if reg_SCLK = '1' then
                    reg_falling_edge_sclk <= '1';
                end if;
            end if;
        end if;
    end process;

    SCLK_generation : process(clk, reset)
    begin
        if reset = '1' then
            reg_SCLK <= '0';
        elsif rising_edge(clk) then
            if reg_spi_en = '1' then
                reg_SCLK <= not reg_SCLK;
            end if;
        end if;
    end process;

    STATE_LOGIC : process(clk, reset)
    begin
        if reset = '1' then
            reg_state        <= STATE_CS_N_HIGH;
            reg_channel      <= (others => '0');
            reg_data_counter <= (others => '0');
            reg_busy         <= '0';
            reg_data_valid   <= '0';
            reg_data         <= (others => '0');
            reg_cs_n         <= '1';
            reg_mosi         <= '0';
        elsif rising_edge(clk) then
            if reg_falling_edge_sclk = '1' then
                reg_state        <= next_reg_state;
                reg_channel      <= next_reg_channel;
                reg_data_counter <= next_reg_data_counter;
                reg_busy         <= next_reg_busy;
                reg_data_valid   <= next_reg_data_valid;
                reg_data         <= next_reg_data;
                reg_cs_n         <= next_reg_cs_n;
                reg_mosi         <= next_reg_mosi;
            end if;
        end if;
    end process;

    NEXT_STATE_LOGIC : process(reg_state, reg_channel, reg_data_counter, reg_busy, reg_data_valid, reg_data, reg_cs_n, reg_mosi)
    begin
        next_reg_state        <= reg_state;
        next_reg_channel      <= reg_channel;
        next_reg_data_counter <= reg_data_counter;

        next_reg_busy       <= reg_busy;
        next_reg_data_valid <= reg_data_valid;
        next_reg_data       <= reg_data;
        next_reg_cs_n       <= reg_cs_n;
        next_reg_mosi       <= reg_mosi;

        case reg_state is
            when STATE_CS_N_HIGH =>
                if start = '1' then
                    next_reg_channel <= channel;
                    next_reg_busy    <= '1';
                    next_reg_cs_n    <= '0';

                    next_reg_state <= STATE_CS_N_LOW;
                end if;

            when STATE_CS_N_LOW =>
                next_reg_state <= STATE_START;

            when STATE_START =>
                -- "first clock received with CS_N low and D_IN high will 
                -- constiture a start bit".
                MOSI <= '1';
                CS_N <= '0';
                busy <= '1';

                next_reg_state <= STATE_SGL;

            when STATE_SGL =>
                -- SGL / DIFF_N bit (we use SGL)
                MOSI <= '1';
                CS_N <= '0';
                busy <= '1';

                next_reg_state <= STATE_D2;

            when STATE_D2 =>
                -- D2 = don't care
                CS_N <= '0';
                busy <= '1';

                next_reg_state <= STATE_D1;

            when STATE_D1 =>
                -- msb of channel
                MOSI <= reg_channel(1);
                CS_N <= '0';
                busy <= '1';

                next_reg_state <= STATE_D0;

            when STATE_D0 =>
                -- lsb of channel
                MOSI <= reg_channel(0);
                CS_N <= '0';
                busy <= '1';

                next_reg_state <= STATE_SAMPLE;

            when STATE_SAMPLE =>
                CS_N <= '0';
                busy <= '1';

                next_reg_state <= STATE_NULL;

            when STATE_NULL =>
                CS_N                  <= '0';
                busy                  <= '1';
                next_reg_data_counter <= to_unsigned(11, next_reg_data_counter'length);

                next_reg_state <= STATE_D_IN;

            when STATE_D_IN =>
                CS_N                                        <= '0';
                busy                                        <= '1';
                next_reg_data_counter                       <= reg_data_counter - 1;
                next_reg_data(to_integer(reg_data_counter)) <= MISO;

                if reg_data_counter = 0 then
                    data           <= reg_data;
                    data_valid     <= '1';
                    next_reg_state <= STATE_CS_N_HIGH;
                end if;
        end case;
    end process;

end architecture rtl;
