library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lepton_stats is
    port(
        clk        : in  std_logic;
        reset      : in  std_logic;
        pix_data   : in  std_logic_vector(13 downto 0);
        pix_valid  : in  std_logic;
        pix_sof    : in  std_logic;
        pix_eof    : in  std_logic;
        stat_min   : out std_logic_vector(13 downto 0);
        stat_max   : out std_logic_vector(13 downto 0);
        stat_sum   : out std_logic_vector(26 downto 0);
        stat_valid : out std_logic);
end lepton_stats;

architecture rtl of lepton_stats is
begin
    -- TODO : complete this architecture
end rtl;
