library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity lepton_stats is
  port (
    reset, clk : in  std_logic;
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

  signal u_pix_data               : unsigned(pix_data'range);
  signal u_resized_pix_data       : unsigned(stat_sum'range);
  signal running_min, running_max : unsigned(stat_min'range);
  signal running_sum, next_running_sum              : unsigned(stat_sum'range);
begin

  u_pix_data <= unsigned(pix_data);
  u_resized_pix_data <= resize(u_pix_data, running_sum'length);
  next_running_sum <= u_resized_pix_data + running_sum;
  
  p_stats : process (clk, reset)
    variable pix : unsigned(pix_data'range);
  begin
    if reset = '1' then
      running_max <= (others => '0');
      running_min <= (others => '1');
      running_sum <= (others => '0');
    elsif rising_edge(clk) then
      if pix_valid = '1' then
        if pix_sof = '1' then
          running_min <= u_pix_data;
          running_max <= u_pix_data;
          running_sum <= u_resized_pix_data;
        else
          if running_min > u_pix_data then
            running_min <= u_pix_data;
          end if;

          if running_max < u_pix_data then
            running_max <= u_pix_data;
          end if;

          running_sum <= next_running_sum;
        end if;
      end if;
    end if;
  end process p_stats;

  stat_min <= std_logic_vector(running_min);
  stat_max <= std_logic_vector(running_max);
  stat_sum <= std_logic_vector(next_running_sum);
  stat_valid <= pix_eof and pix_valid;
end rtl;
