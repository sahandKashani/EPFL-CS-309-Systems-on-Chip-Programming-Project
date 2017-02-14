-- #############################################################################
-- DE0_Nano_SoC_top_level_ext_board.vhd
--
-- BOARD         : PrSoC ext_board top level
-- Author        : Florian Depraz based on Sahand Kashani-Akhavan work
-- Revision      : 1.1
-- Creation date : 06/02/2016
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

entity DE0_Nano_SoC_ext_board_nios_top_level is
    port(


        -------------------------------
        -- Comment ALL unused ports. --
        -------------------------------

        -- CLOCK
        FPGA_CLK1_50     : in    std_logic;
        -- FPGA_CLK2_50     : in    std_logic;
        -- FPGA_CLK3_50     : in    std_logic;

        -- KEY on DE0 Nano SoC
        KEY_N            : in    std_logic_vector(1 downto 0);

        -- LEDs on DE0 Nano SoC
        LED              : out   std_logic_vector(7 downto 0);

        -- SWITCHES on DE0 Nano SoC
        -- SW               : in    std_logic_vector(3 downto 0);

        -- Servomotors pwm
        SERVO_0          : out   std_logic;
        SERVO_1          : out   std_logic;

        -- ADC Joysticks
        J0_SPI_CS_n      : out   std_logic;
        J0_SPI_MOSI      : out   std_logic;
        J0_SPI_MISO      : in    std_logic;
        J0_SPI_CLK       : out   std_logic;

        -- Lepton
        CAM_TH_SPI_CS_N  : out   std_logic;
        CAM_TH_MISO      : in    std_logic;
        CAM_TH_MOSI      : out   std_logic;
        CAM_TH_CLK       : out   std_logic;

        -- PCA9637
        PIO_SCL          : inout std_logic;
        PIO_SDA          : inout std_logic;
        PIO_INT_N        : in    std_logic;
        RESET_N          : out   std_logic;

        -- OV7670
        -- CAM_D            : in    std_logic_vector(9 downto 0);
        -- CAM_PIX_CLK      : in    std_logic;
        -- CAM_LV           : in    std_logic;
        -- CAM_FV           : in    std_logic;
        -- CAM_SYS_CLK      : out   std_logic;


        -- VGA and LCD shared signals
        -- VIDEO_CLK        : out   std_logic;
        -- VIDEO_VSYNC      : out   std_logic;
        -- VIDEO_HSYNC      : out   std_logic;
        -- VIDEO_B          : out   std_logic_vector(7 downto 0);
        -- VIDEO_G          : out   std_logic_vector(7 downto 0);
        -- VIDEO_R          : out   std_logic_vector(7 downto 0);

        -- LCD Specific signals
        -- LCD_DE           : out   std_logic;
        -- LCD_PIN_DAV_N    : ???   std_logic;
        -- LCD_DISPLAY_EN   : out   std_logic;
        -- SPI_MISO         : in    std_logic;
        -- SPI_ENA_N        : out   std_logic;
        -- SPI_CLK          : out   std_logic;
        -- SPI_MOSI         : out   std_logic;
        -- SPI_DAT          : inout std_logic;

        -- I2C TOUCH SCREEN
        -- TS_SCL           : inout std_logic;
        -- TS_SDA           : inout std_logic;

        -- BLUETOOTH (BLE)
        -- BLT_TXD          : in    std_logic;
        -- BLT_RXD          : out   std_logic;

        -- I2C For VGA, PAL and OV7670 cameras
        -- CAM_PAL_VGA_SDA  : inout std_logic;
        -- CAM_PAL_VGA_SCL  : inout std_logic;

        -- ONE WIRE
        -- BOARD_ID         : inout std_logic;

        -- PAL Camera
        -- PAL_VD_VD        : in    std_logic_vector(7 downto 0);
        -- PAL_VD_VSO       : in    std_logic;
        -- PAL_VD_HSO       : in    std_logic;
        -- PAL_VD_CLKO      : in    std_logic;
        -- PAL_PWDN         : out   std_logic;

        -- WIFI
        -- FROM_ESP_TXD     : in    std_logic;
        -- TO_ESP_RXD       : out   std_logic;

        -- LED RGB
         LED_BGR          : out   std_logic

    );
end entity DE0_Nano_SoC_ext_board_nios_top_level;

architecture rtl of DE0_Nano_SoC_ext_board_nios_top_level is
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
            ws2812_0_conduit_end_name             : out   std_logic;        -- led_bgr
            reset_reset_n              : in    std_logic := 'X'  -- reset_n
        );
    end component soc_system_nios_only;

begin
    u0 : component soc_system_nios_only
        port map(
            clk_clk                           => FPGA_CLK1_50,
            reset_reset_n                     => KEY_N(0),

            pwm_0_conduit_end_pwm             => SERVO_0,

            pwm_1_conduit_end_pwm             => SERVO_1,

            mcp3204_0_conduit_end_cs_n        => J0_SPI_CS_n,
            mcp3204_0_conduit_end_mosi        => J0_SPI_MOSI,
            mcp3204_0_conduit_end_miso        => J0_SPI_MISO,
            mcp3204_0_conduit_end_sclk        => J0_SPI_CLK,

            lepton_0_spi_cs_n                 => CAM_TH_SPI_CS_N,
            lepton_0_spi_miso                 => CAM_TH_MISO,
            lepton_0_spi_mosi                 => CAM_TH_MOSI,
            lepton_0_spi_sclk                 => CAM_TH_CLK,

            i2c_pio_0_i2c_scl                 => PIO_SCL,
            i2c_pio_0_i2c_sda                 => PIO_SDA,
            i2c_pio_0_pca9673_int_n           => PIO_INT_N,
            i2c_pio_0_pca9673_reset_n         => RESET_N,
            ws2812_0_conduit_end_name         => LED_BGR
        );


        LED(0) <= KEY_N(0) or KEY_N(1);
        LED(7 downto 1) <= "1000001";
end;
