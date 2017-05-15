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

    signal denom    : std_logic_vector(13 downto 0);
    signal numer    : std_logic_vector(27 downto 0);
    signal quotient : std_logic_vector(27 downto 0);
begin
    lpm_divider0 : lpm_divider
    port map(
        clock    => clk,
        denom    => denom,
        numer    => numer,
        quotient => quotient,
        remain   => open);

    numer          <= std_logic_vector((unsigned(raw_pixel) - unsigned(raw_min)) * resize(X"3fff", raw_pixel'length));
    denom          <= std_logic_vector(unsigned(raw_max) - unsigned(raw_min));
    adjusted_pixel <= quotient(13 downto 0);

end rtl;
