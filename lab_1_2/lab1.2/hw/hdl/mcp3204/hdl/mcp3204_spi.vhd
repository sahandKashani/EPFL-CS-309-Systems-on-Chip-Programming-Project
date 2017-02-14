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
    signal reg_rising_edge_sclk    : std_logic            := '0';
    signal reg_falling_edge_sclk   : std_logic            := '0';

    signal reg_sclk : std_logic := '0';

begin
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
        -- TODO: complete this process
        if reset = '1' then
        elsif rising_edge(clk) then
        end if;
    end process;

end architecture rtl;
