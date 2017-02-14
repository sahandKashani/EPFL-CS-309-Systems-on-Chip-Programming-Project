	component soc_system_nios_only is
		port (
			clk_clk                    : in    std_logic := 'X'; -- clk
			i2c_pio_0_i2c_scl          : out   std_logic;        -- scl
			i2c_pio_0_i2c_sda          : inout std_logic := 'X'; -- sda
			i2c_pio_0_pca9673_int_n    : in    std_logic := 'X'; -- int_n
			i2c_pio_0_pca9673_reset_n  : out   std_logic;        -- reset_n
			lepton_0_spi_cs_n          : out   std_logic;        -- cs_n
			lepton_0_spi_miso          : in    std_logic := 'X'; -- miso
			lepton_0_spi_mosi          : out   std_logic;        -- mosi
			lepton_0_spi_sclk          : out   std_logic;        -- sclk
			mcp3204_0_conduit_end_cs_n : out   std_logic;        -- cs_n
			mcp3204_0_conduit_end_mosi : out   std_logic;        -- mosi
			mcp3204_0_conduit_end_miso : in    std_logic := 'X'; -- miso
			mcp3204_0_conduit_end_sclk : out   std_logic;        -- sclk
			pwm_0_conduit_end_pwm      : out   std_logic;        -- pwm
			pwm_1_conduit_end_pwm      : out   std_logic;        -- pwm
			reset_reset_n              : in    std_logic := 'X'; -- reset_n
			ws2812_0_conduit_end_name  : out   std_logic         -- name
		);
	end component soc_system_nios_only;

	u0 : component soc_system_nios_only
		port map (
			clk_clk                    => CONNECTED_TO_clk_clk,                    --                   clk.clk
			i2c_pio_0_i2c_scl          => CONNECTED_TO_i2c_pio_0_i2c_scl,          --         i2c_pio_0_i2c.scl
			i2c_pio_0_i2c_sda          => CONNECTED_TO_i2c_pio_0_i2c_sda,          --                      .sda
			i2c_pio_0_pca9673_int_n    => CONNECTED_TO_i2c_pio_0_pca9673_int_n,    --     i2c_pio_0_pca9673.int_n
			i2c_pio_0_pca9673_reset_n  => CONNECTED_TO_i2c_pio_0_pca9673_reset_n,  --                      .reset_n
			lepton_0_spi_cs_n          => CONNECTED_TO_lepton_0_spi_cs_n,          --          lepton_0_spi.cs_n
			lepton_0_spi_miso          => CONNECTED_TO_lepton_0_spi_miso,          --                      .miso
			lepton_0_spi_mosi          => CONNECTED_TO_lepton_0_spi_mosi,          --                      .mosi
			lepton_0_spi_sclk          => CONNECTED_TO_lepton_0_spi_sclk,          --                      .sclk
			mcp3204_0_conduit_end_cs_n => CONNECTED_TO_mcp3204_0_conduit_end_cs_n, -- mcp3204_0_conduit_end.cs_n
			mcp3204_0_conduit_end_mosi => CONNECTED_TO_mcp3204_0_conduit_end_mosi, --                      .mosi
			mcp3204_0_conduit_end_miso => CONNECTED_TO_mcp3204_0_conduit_end_miso, --                      .miso
			mcp3204_0_conduit_end_sclk => CONNECTED_TO_mcp3204_0_conduit_end_sclk, --                      .sclk
			pwm_0_conduit_end_pwm      => CONNECTED_TO_pwm_0_conduit_end_pwm,      --     pwm_0_conduit_end.pwm
			pwm_1_conduit_end_pwm      => CONNECTED_TO_pwm_1_conduit_end_pwm,      --     pwm_1_conduit_end.pwm
			reset_reset_n              => CONNECTED_TO_reset_reset_n,              --                 reset.reset_n
			ws2812_0_conduit_end_name  => CONNECTED_TO_ws2812_0_conduit_end_name   --  ws2812_0_conduit_end.name
		);

