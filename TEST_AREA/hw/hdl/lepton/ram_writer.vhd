library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_writer is
  
  port (
    clk, reset    : in  std_logic;
    pix_data      : in  std_logic_vector(13 downto 0);
    pix_valid     : in  std_logic;
    pix_sof       : in  std_logic;
    pix_eof       : in  std_logic;
    ram_data      : out std_logic_vector(15 downto 0);
    ram_wren      : out std_logic;
    ram_wraddress : out std_logic_vector(12 downto 0));

end ram_writer;

architecture rtl of ram_writer is
  signal wraddress_counter : unsigned(ram_wraddress'range);
begin

  p_address_gen: process (clk, reset)
  begin
    if reset = '1' then
      wraddress_counter <= (others => '0');
    elsif rising_edge(clk) then
      if pix_eof = '1' then
        wraddress_counter <= (others => '0');
      elsif pix_valid = '1' then
        wraddress_counter <= wraddress_counter + 1;
      end if;
    end if;
  end process p_address_gen;

  ram_data <= "00" & pix_data;
  ram_wren <= pix_valid;
  ram_wraddress <= std_logic_vector(wraddress_counter);

end rtl;
