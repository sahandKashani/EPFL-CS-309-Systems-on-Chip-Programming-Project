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

begin

end architecture rtl;
