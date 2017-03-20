library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity level_adjuster is
    port(
        clk            : in  std_logic;
        raw_pixel      : in  std_logic_vector(13 downto 0);
        raw_max        : in  std_logic_vector(13 downto 0);
        raw_min        : in  std_logic_vector(13 downto 0);
        raw_sum        : in  std_logic_vector(26 downto 0);
        adjusted_pixel : out std_logic_vector(13 downto 0));
end level_adjuster;

architecture rtl of level_adjuster is
    component lpm_divider
        port(
            clock    : in  std_logic;
            denom    : in  std_logic_vector(13 downto 0);
            numer    : in  std_logic_vector(27 downto 0);
            quotient : out std_logic_vector(27 downto 0);
            remain   : out std_logic_vector(13 downto 0));
    end component;

begin
    -- TODO : complete this architecture
end rtl;
