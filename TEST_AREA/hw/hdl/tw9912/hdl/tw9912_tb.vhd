library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity tw9912_tb is

end tw9912_tb;

architecture tb of tw9912_tb is

	signal sysclk : std_logic := '1';
	signal reset  : std_logic := '1';

	signal avs_address   : std_logic_vector(2 downto 0);
	signal avs_write     : std_logic;
	signal avs_read      : std_logic;
	signal avs_writedata : std_logic_vector(31 downto 0);
	signal avs_readdata  : std_logic_vector(31 downto 0);

	-- Avalon-ST Source to output data
	signal asrc_data  : std_logic_vector(31 downto 0);
	signal asrc_valid : std_logic;
	signal asrc_ready : std_logic;

	-- Signal coming from the TW9912
	signal pal_clk   : std_logic;
	signal pal_vd    : std_logic_vector(7 downto 0);
	signal pal_vsync : std_logic;
	signal pal_hsync : std_logic;

begin

reset <= '0' after 50 ns;
sysclk <= not sysclk after 10 ns;
asrc_ready <= '1'; -- empty the fifo as soon as possible

stim : entity work.tw9912_stimulus port map (pal_clk, pal_vd);

uut : entity work.tw9912_adapter port map  (
	sysclk          => sysclk,
	reset           => reset,
	avs_address     => avs_address,
	avs_write       => avs_write,
	avs_read        => avs_read,
	avs_writedata   => avs_writedata,
	avs_readdata    => avs_readdata,
	asrc_data       => asrc_data,
	asrc_valid      => asrc_valid,
	asrc_ready      => asrc_ready,
	pal_clk         => pal_clk,
	pal_vsync       => pal_vsync,
	pal_hsync       => pal_hsync,
	pal_vd          => pal_vd,
	debug_capturing => open);


process
begin
	wait until falling_edge(reset);
	wait until falling_edge(sysclk);

	avs_address <= (others => '0');
	avs_write   <= '1';

	wait until falling_edge(sysclk);
	avs_write   <= '0';

	wait;
end process;


end architecture ;