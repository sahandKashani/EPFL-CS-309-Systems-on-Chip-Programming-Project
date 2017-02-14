
module soc_system_nios_only (
	clk_clk,
	i2c_pio_0_i2c_scl,
	i2c_pio_0_i2c_sda,
	i2c_pio_0_pca9673_int_n,
	i2c_pio_0_pca9673_reset_n,
	lepton_0_spi_cs_n,
	lepton_0_spi_miso,
	lepton_0_spi_mosi,
	lepton_0_spi_sclk,
	mcp3204_0_conduit_end_cs_n,
	mcp3204_0_conduit_end_mosi,
	mcp3204_0_conduit_end_miso,
	mcp3204_0_conduit_end_sclk,
	pwm_0_conduit_end_pwm,
	pwm_1_conduit_end_pwm,
	reset_reset_n,
	ws2812_0_conduit_end_name);	

	input		clk_clk;
	output		i2c_pio_0_i2c_scl;
	inout		i2c_pio_0_i2c_sda;
	input		i2c_pio_0_pca9673_int_n;
	output		i2c_pio_0_pca9673_reset_n;
	output		lepton_0_spi_cs_n;
	input		lepton_0_spi_miso;
	output		lepton_0_spi_mosi;
	output		lepton_0_spi_sclk;
	output		mcp3204_0_conduit_end_cs_n;
	output		mcp3204_0_conduit_end_mosi;
	input		mcp3204_0_conduit_end_miso;
	output		mcp3204_0_conduit_end_sclk;
	output		pwm_0_conduit_end_pwm;
	output		pwm_1_conduit_end_pwm;
	input		reset_reset_n;
	output		ws2812_0_conduit_end_name;
endmodule
