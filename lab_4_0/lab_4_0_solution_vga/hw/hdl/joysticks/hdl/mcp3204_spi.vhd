-- #############################################################################
-- mcp3204_spi.vhd
-- ===============
-- MCP3204 SPI interface.
--
-- Author        : Philémon Favrod [philemon.favrod@epfl.ch]
-- Author        : Sahand Kashani-Akhavan [sahand.kashani-akhavan@epfl.ch]
-- Revision      : 1
-- Last modified : 2018-03-06
-- #############################################################################

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
        SCLK : out std_logic;
        CS_N : out std_logic;
        MOSI : out std_logic;
        MISO : in  std_logic
    );
end mcp3204_spi;

architecture rtl of mcp3204_spi is
    type state is (STATE_IDLE, STATE_START, STATE_SGL, STATE_D2, STATE_D1, STATE_D0, STATE_SAMPLE, STATE_NULL, STATE_D_IN, STATE_DATA_VALID);
    signal reg_state : state := STATE_IDLE;

    signal reg_clk_divider_counter : unsigned(4 downto 0) := (others => '0');  -- need to be able to count until 24
    signal reg_spi_en              : std_logic            := '0';  -- pulses every 0.5 MHz
    signal reg_rising_edge_sclk    : std_logic            := '0';
    signal reg_falling_edge_sclk   : std_logic            := '0';

    signal reg_channel      : std_logic_vector(channel'range) := (others => '0');
    signal reg_data_counter : unsigned(3 downto 0)            := (others => '0');  -- need to be able to count until 11

    -- registered outputs
    signal reg_busy       : std_logic                    := '0';
    signal reg_data_valid : std_logic                    := '0';
    signal reg_data       : std_logic_vector(data'range) := (others => '0');
    signal reg_sclk       : std_logic                    := '0';
    signal reg_cs_n       : std_logic                    := '1';
    signal reg_mosi       : std_logic                    := '0';

begin
    busy       <= reg_busy;
    data_valid <= reg_data_valid;
    data       <= reg_data;
    SCLK       <= reg_sclk when reg_state /= STATE_IDLE and reg_state /= STATE_DATA_VALID else '0';
    CS_N       <= reg_cs_n;
    MOSI       <= reg_mosi;

    clk_divider_generation : process(clk, reset)
    begin
        if reset = '1' then
            reg_clk_divider_counter <= (others => '0');
        elsif rising_edge(clk) then
            reg_clk_divider_counter <= reg_clk_divider_counter + 1;
            reg_spi_en              <= '0';
            reg_rising_edge_sclk    <= '0';
            reg_falling_edge_sclk   <= '0';

            if reg_clk_divider_counter = 24 then
                reg_clk_divider_counter <= (others => '0');
                reg_spi_en              <= '1';

                if reg_sclk = '0' then
                    reg_rising_edge_sclk <= '1';
                elsif reg_sclk = '1' then
                    reg_falling_edge_sclk <= '1';
                end if;
            end if;
        end if;
    end process;

    SCLK_generation : process(clk, reset)
    begin
        if reset = '1' then
            reg_sclk <= '0';
        elsif rising_edge(clk) then
            if reg_spi_en = '1' then
                reg_sclk <= not reg_sclk;
            end if;
        end if;
    end process;

    STATE_LOGIC : process(clk, reset)
    begin
        if reset = '1' then
            reg_state        <= STATE_IDLE;
            reg_channel      <= (others => '0');
            reg_data_counter <= (others => '0');
            reg_busy         <= '0';
            reg_data_valid   <= '0';
            reg_cs_n         <= '1';
            reg_mosi         <= '0';
        elsif rising_edge(clk) then
            if start = '1' then
                reg_busy    <= '1';
                reg_channel <= channel;

            elsif reg_falling_edge_sclk = '1' then
                case reg_state is
                    when STATE_IDLE =>
                        if reg_busy = '1' then
                            reg_state <= STATE_START;
                            -- "first clock received with CS_N low and D_IN high will
                            -- constiture a start bit".
                            reg_mosi  <= '1';
                            reg_cs_n  <= '0';
                        end if;

                    when STATE_START =>
                        -- SGL / DIFF_N bit (we use SGL)
                        reg_mosi  <= '1';
                        reg_state <= STATE_SGL;

                    when STATE_SGL =>
                        reg_state <= STATE_D2;
                        -- D2 = don't care
                        reg_mosi  <= '0';

                    when STATE_D2 =>
                        reg_state <= STATE_D1;
                        -- D1 = msb of reg_channel
                        reg_mosi  <= reg_channel(1);

                    when STATE_D1 =>
                        reg_state <= STATE_D0;
                        -- D0 = lsb of reg_channel
                        reg_mosi  <= reg_channel(0);

                    when STATE_D0 =>
                        reg_state <= STATE_SAMPLE;
                        -- Don't care about MOSI during sample
                        reg_mosi  <= '0';

                    when STATE_SAMPLE =>
                        reg_state <= STATE_NULL;
                        -- Don't care about MOSI during null bit
                        reg_mosi  <= '0';

                    when STATE_NULL =>
                        reg_state        <= STATE_D_IN;
                        -- Initialize counter for D_IN states
                        reg_data_counter <= to_unsigned(11, reg_data_counter'length);

                    when STATE_D_IN =>
                        if reg_data_counter /= 0 then
                            reg_data_counter <= reg_data_counter - 1;
                        else
                            reg_cs_n       <= '1';
                            reg_data_valid <= '1';
                            reg_state      <= STATE_DATA_VALID;
                        end if;

                    when STATE_DATA_VALID =>
                        reg_busy       <= '0';
                        reg_data_valid <= '0';
                        reg_state      <= STATE_IDLE;
                end case;
            end if;
        end if;
    end process;

    DATA_CAPTURE : process(clk, reset)
    begin
        if reset = '1' then
            reg_data <= (others => '0');
        elsif rising_edge(clk) then
            if reg_rising_edge_sclk = '1' then
                if reg_state = STATE_D_IN then
                    reg_data(to_integer(reg_data_counter)) <= MISO;
                end if;
            end if;
        end if;
    end process;

end architecture rtl;
