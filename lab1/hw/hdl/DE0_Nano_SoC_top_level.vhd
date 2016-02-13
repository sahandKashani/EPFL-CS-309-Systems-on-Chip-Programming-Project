-- #############################################################################
-- DE0_Nano_SoC_top_level.vhd
--
-- BOARD         : DE0-Nano-SoC from Terasic
-- Author        : Sahand Kashani-Akhavan from Terasic documentation
-- Revision      : 1.0
-- Creation date : 11/06/2015
--
-- Syntax Rule : GROUP_NAME_N[bit]
--
-- GROUP : specify a particular interface (ex: SDR_)
-- NAME  : signal name (ex: CONFIG, D, ...)
-- bit   : signal index
-- _N    : to specify an active-low signal
-- #############################################################################

library ieee;
use ieee.std_logic_1164.all;

entity DE0_Nano_SoC_top_level is
	port(
		-- CLOCK
		FPGA_CLK1_50     : in    std_logic;

		-- KEY
		KEY_N            : in    std_logic_vector(1 downto 0)
	);
end entity DE0_Nano_SoC_top_level;

architecture rtl of DE0_Nano_SoC_top_level is
	component soc_system is
		port(
			clk_clk               : in  std_logic := 'X';
			reset_reset_n         : in  std_logic := 'X';
			pwm_0_conduit_end_pwm : out std_logic;
			pwm_1_conduit_end_pwm : out std_logic
		);
	end component soc_system;

begin
	u0 : component soc_system
		port map(
			clk_clk               => FPGA_CLK1_50,
			reset_reset_n         => KEY_N(0),
			pwm_0_conduit_end_pwm => open,
			pwm_1_conduit_end_pwm => open
		);

end;
