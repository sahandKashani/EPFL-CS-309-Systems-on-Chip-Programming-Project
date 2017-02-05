------------------------------------------------------------------
-- i2c_interface.vhd -- I2C Master Interface for
--                      Avalon Bus Slave Interface
------------------------------------------------------------------
-- Author  : Cédric Gaudin
-- Version : 0.8 alpha
-- History :
--           20-mar-2002 CG 0.1 initial alpha release
--           20-mar-2002 CG 0.2 minor corrections
--           27-mar-2002 CG 0.6 interface is working yet
--           02-apr-2002 CG 0.7 minor corrections
--			 09-05 -2006 RB 0.8 synchronise scl_in and sda_in with rising_edge of clk
------------------------------------------------------------------
-- Registers description:
--
-- Adr RW Name
-- 00  RW DR - transmit and receive data register
-- 01  RW CR - control register (changed to RW mode)
-- 10  RO SR - status register
-- 11  RW CD - clock divisor
--
-- SR - status register bits
--
--  +---------+-------+-------+-------+-------+
--  |bit 7..5 | bit 3 | bit 2 | bit 1 | bit 0 |
--  +---------+-------+-------+-------+-------+
--  | UNUSED  | TIP   | IPE   | BSY   | LAR   |
--  +---------+-------+-------+-------+-------+
--
-- TIP   - transfer in progress
-- IPE   - interrupt pending
-- BSY   - I2C bus busy
-- LAR   - last acknowledge received
--
-- CR - control register bits
--
--  +---------+-------+-------+-------+-------+-------+-------+
--  | bit 7..6| bit 5 | bit 4 | bit 3 | bit 2 | bit 1 | bit 0 |
--  +---------+-------+-------+-------+-------+-------+-------+
--  | UNUSED  | IEN   | WR    | RD    | STA   | STP   | ACK   |
--  +---------+-------+-------+-------+-------+-------+-------+
--
-- ACK    - Acknowledge bit for reading
-- STP    - Generate a I2C Stop Sequence
-- STA    - Generate a I2C Start Sequence
-- RD     - Read command bit
-- WR     - Write command bit
-- IEN    - Interrupt Enable
--
-- To start a transfer WR or RD *MUST* BE set.
-- When command transfer has started TIP goes high
-- and write to CR are ignored until TIP goes low.
-- At end of transfer IRQ goes high if interrupt is enabled (IEN=1).
--
------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity i2c_interface is
    port(
        clk        : in    std_logic;
        reset      : in    std_logic;

        -- Avalon bus signals
        address    : in    std_logic_vector(1 downto 0);
        chipselect : in    std_logic;
        write      : in    std_logic;
        writedata  : in    std_logic_vector(7 downto 0);
        read       : in    std_logic;
        readdata   : out   std_logic_vector(7 downto 0);
        irq        : out   std_logic;

        -- I2C signals
        scl        : inout std_logic;
        sda        : inout std_logic
    );

end i2c_interface;

architecture structural of i2c_interface is
    component i2c_core
        port(
            -- I2C signals
            sda_in       : in  std_logic;
            scl_in       : in  std_logic;
            sda_out      : out std_logic;
            scl_out      : out std_logic;

            -- interface signals
            clk          : in  std_logic;
            rst          : in  std_logic;
            sclk         : in  std_logic;
            ack_in       : in  std_logic;
            ack_out      : out std_logic;
            data_in      : in  std_logic_vector(7 downto 0);
            data_out     : out std_logic_vector(7 downto 0);
            cmd_start    : in  std_logic;
            cmd_stop     : in  std_logic;
            cmd_read     : in  std_logic;
            cmd_write    : in  std_logic;
            cmd_done_ack : in  std_logic;
            cmd_done     : out std_logic;
            busy         : out std_logic

        -- debug signals
        --state  		: out std_logic_vector(5 downto 0)
        );
    end component;

    component i2c_clkgen
        port(
            signal clk     : in  std_logic;
            signal rst     : in  std_logic;

            signal clk_cnt : in  std_logic_vector(7 downto 0);

            -- I2C clock generated
            signal sclk    : out std_logic;

            -- I2C clock line SCL (used for clock stretching)
            signal scl_in  : in  std_logic;
            signal scl_out : in  std_logic
        );
    end component;

    -- I2C base clock
    signal i_sclk : std_logic;

    -- I2C serial clock output
    signal i_scl_out : std_logic;

    -- clock divisor register
    signal i_clkdiv_reg : std_logic_vector(7 downto 0);

    -- status register bits
    signal i_tip_reg    : std_logic;    -- transfer in progress      ( bit 3 )
    signal i_int_pe_reg : std_logic;    -- interrupt pending         ( bit 2 )
    signal i_busy_reg   : std_logic;    -- busy                      ( bit 1 )
    signal i_lar_reg    : std_logic;    -- last acknowledge received ( bit 0 )

    -- control register bits
    signal i_int_en_reg : std_logic;    -- interrupt enable          ( bit 5 )
    signal i_write_reg  : std_logic;    -- write command             ( bit 4 )
    signal i_read_reg   : std_logic;    -- read command              ( bit 3 )
    signal i_start_reg  : std_logic;    -- command with a start      ( bit 2 )
    signal i_stop_reg   : std_logic;    -- command with a stop       ( bit 1 )
    signal i_ack_reg    : std_logic;    -- acknowledge to send       ( bit 0 )

    -- data register
    signal i_data_out : std_logic_vector(7 downto 0);
    signal i_data_in  : std_logic_vector(7 downto 0);

    -- command done & acknowledge signals
    signal i_cmd_done_ack : std_logic;
    signal i_cmd_done     : std_logic;

    -- internal signals
    signal i_readdata : std_logic_vector(7 downto 0);
    signal i_irq      : std_logic;

    -- write strobe
    signal i_write_strobe : std_logic;

    -- read strobe
    signal i_read_strobe : std_logic;

    -- interrupt clear
    signal i_int_clr : std_logic;

    -- just implement open collector in module
    signal scl_in  : std_logic;
    signal sda_in  : std_logic;
    signal scl_out : std_logic;
    signal sda_out : std_logic;

begin
    scl_in <= scl when rising_edge(clk); -- RB 0.8
    sda_in <= sda when rising_edge(clk); -- RB 0.8

    --scl <= 'Z' when (scl_out = '1') else '0';
    scl <= '1' when (scl_out = '1') else '0'; -- RB 0.8 to have nice scl ( no more open collector !! )
    sda <= 'Z' when (sda_out = '1') else '0';

    clkgen : i2c_clkgen port map(
            clk     => clk,
            rst     => reset,
            clk_cnt => i_clkdiv_reg,
            sclk    => i_sclk,
            scl_in  => scl_in,
            scl_out => i_scl_out
        );

    core : i2c_core port map(
            clk          => clk,
            rst          => reset,
            sclk         => i_sclk,
            ack_in       => i_ack_reg,
            ack_out      => i_lar_reg,
            data_in      => i_data_in,
            data_out     => i_data_out,
            cmd_start    => i_start_reg,
            cmd_stop     => i_stop_reg,
            cmd_read     => i_read_reg,
            cmd_write    => i_write_reg,
            cmd_done_ack => i_cmd_done_ack,
            cmd_done     => i_cmd_done,
            busy         => i_busy_reg,
            sda_in       => sda_in,
            scl_in       => scl_in,
            sda_out      => sda_out,
            scl_out      => i_scl_out
        --	state        => state
        );

    -- read strobe
    i_read_strobe <= (chipselect and read);

    -- output to avalon bus
    data_out_sync : process(clk, reset)
    begin
        if (reset = '1') then
            readdata <= (others => '0');
            irq      <= '0';
        elsif (rising_edge(clk)) then
            if (i_read_strobe = '1') then
                readdata <= i_readdata;
            end if;
            irq <= i_irq;
        end if;
    end process;

    -- output multiplexer
    data_out_comb : process(address, i_ack_reg, i_stop_reg, i_start_reg, i_read_reg, i_write_reg, i_int_en_reg, i_data_out, i_lar_reg, i_busy_reg, i_int_pe_reg, i_tip_reg, i_clkdiv_reg)
    begin
        i_readdata <= (others => '0');
        case address is
            when "00" => i_readdata <= i_data_out;
            when "01" =>
                i_readdata(0) <= i_ack_reg;
                i_readdata(1) <= i_stop_reg;
                i_readdata(2) <= i_start_reg;
                i_readdata(3) <= i_read_reg;
                i_readdata(4) <= i_write_reg;
                i_readdata(5) <= i_int_en_reg;

            when "10" => i_readdata(0) <= i_lar_reg;
                i_readdata(1) <= i_busy_reg;
                i_readdata(2) <= i_int_pe_reg;
                i_readdata(3) <= i_tip_reg;

            when "11"   => i_readdata <= i_clkdiv_reg;
            when others => i_readdata <= (others => '0');
        end case;
    end process;

    -- output scl already syncronized in core
    scl_out <= i_scl_out;

    -- transfer in progress
    i_tip_reg <= (i_read_reg OR i_write_reg);

    -- write strobe
    i_write_strobe <= (chipselect and write);

    -- interrupt output
    i_irq <= (i_int_pe_reg AND i_int_en_reg);

    -- interrupt clear signal coming from outside
    i_int_clr <= '1' when (address = "00" and chipselect = '1') else '0';

    data_in_sync : process(clk, reset)
    begin
        if (reset = '1') then
            i_int_pe_reg   <= '0';
            i_data_in      <= (others => '0');
            i_int_en_reg   <= '0';
            i_write_reg    <= '0';
            i_read_reg     <= '0';
            i_start_reg    <= '0';
            i_stop_reg     <= '0';
            i_ack_reg      <= '0';
            i_clkdiv_reg   <= "10000011";
            i_cmd_done_ack <= '0';

        elsif (rising_edge(clk)) then
            i_cmd_done_ack <= '0';

            -- no transfer in progress
            if (i_tip_reg = '0') then
                if (i_write_strobe = '1') then
                    case address is
                        when "00" => i_data_in <= writedata;
                        when "01" => i_ack_reg <= writedata(0);
                            i_stop_reg            <= writedata(1);
                            i_start_reg           <= writedata(2);
                            i_read_reg            <= writedata(3);
                            i_write_reg           <= writedata(4);
                            i_int_en_reg          <= writedata(5);
                        when "11" => i_clkdiv_reg <= writedata;
                        when others => null;
                    end case;
                end if;

                if (i_int_clr = '1') then
                    i_int_pe_reg <= '0';
                end if;
            else
                if (i_cmd_done = '1') then
                    -- clear command bits
                    i_write_reg <= '0';
                    i_read_reg  <= '0';
                    i_start_reg <= '0';
                    i_stop_reg  <= '0';

                    -- set interrupt pending
                    i_int_pe_reg <= '1';

                    -- acknowledge cmd done to core controller
                    i_cmd_done_ack <= '1';
                end if;
            end if;
        end if;
    end process data_in_sync;

end structural;
