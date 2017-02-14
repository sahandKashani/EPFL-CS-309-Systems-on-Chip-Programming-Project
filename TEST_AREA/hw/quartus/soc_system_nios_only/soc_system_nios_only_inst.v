	soc_system_nios_only u0 (
		.clk_clk                    (<connected-to-clk_clk>),                    //                   clk.clk
		.i2c_pio_0_i2c_scl          (<connected-to-i2c_pio_0_i2c_scl>),          //         i2c_pio_0_i2c.scl
		.i2c_pio_0_i2c_sda          (<connected-to-i2c_pio_0_i2c_sda>),          //                      .sda
		.i2c_pio_0_pca9673_int_n    (<connected-to-i2c_pio_0_pca9673_int_n>),    //     i2c_pio_0_pca9673.int_n
		.i2c_pio_0_pca9673_reset_n  (<connected-to-i2c_pio_0_pca9673_reset_n>),  //                      .reset_n
		.lepton_0_spi_cs_n          (<connected-to-lepton_0_spi_cs_n>),          //          lepton_0_spi.cs_n
		.lepton_0_spi_miso          (<connected-to-lepton_0_spi_miso>),          //                      .miso
		.lepton_0_spi_mosi          (<connected-to-lepton_0_spi_mosi>),          //                      .mosi
		.lepton_0_spi_sclk          (<connected-to-lepton_0_spi_sclk>),          //                      .sclk
		.mcp3204_0_conduit_end_cs_n (<connected-to-mcp3204_0_conduit_end_cs_n>), // mcp3204_0_conduit_end.cs_n
		.mcp3204_0_conduit_end_mosi (<connected-to-mcp3204_0_conduit_end_mosi>), //                      .mosi
		.mcp3204_0_conduit_end_miso (<connected-to-mcp3204_0_conduit_end_miso>), //                      .miso
		.mcp3204_0_conduit_end_sclk (<connected-to-mcp3204_0_conduit_end_sclk>), //                      .sclk
		.pwm_0_conduit_end_pwm      (<connected-to-pwm_0_conduit_end_pwm>),      //     pwm_0_conduit_end.pwm
		.pwm_1_conduit_end_pwm      (<connected-to-pwm_1_conduit_end_pwm>),      //     pwm_1_conduit_end.pwm
		.reset_reset_n              (<connected-to-reset_reset_n>),              //                 reset.reset_n
		.ws2812_0_conduit_end_name  (<connected-to-ws2812_0_conduit_end_name>)   //  ws2812_0_conduit_end.name
	);

