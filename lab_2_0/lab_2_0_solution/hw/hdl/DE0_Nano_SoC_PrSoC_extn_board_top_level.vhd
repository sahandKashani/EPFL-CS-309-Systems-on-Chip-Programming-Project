-- #############################################################################
-- DE0_Nano_SoC_PrSoC_extn_board_top_level.vhd
--
-- BOARD         : PrSoC extension board for DE0-Nano-SoC
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

entity DE0_Nano_SoC_PrSoC_extn_board_top_level is
    port(
        -------------------------------
        -- Comment ALL unused ports. --
        -------------------------------

        -- CLOCK
        FPGA_CLK1_50 : in std_logic;
     -- FPGA_CLK2_50 : in std_logic;
     -- FPGA_CLK3_50 : in std_logic;

        -- KEY on DE0 Nano SoC
        KEY_N : in std_logic_vector(1 downto 0);

        -- LEDs on DE0 Nano SoC
     -- LED : out std_logic_vector(7 downto 0);

        -- SWITCHES on DE0 Nano SoC
     -- SW : in std_logic_vector(3 downto 0);

        -- Servomotors pwm
        SERVO_0 : out std_logic;
        SERVO_1 : out std_logic;

        -- ADC Joysticks
        J0_SPI_CS_n : out std_logic;
        J0_SPI_MOSI : out std_logic;
        J0_SPI_MISO : in  std_logic;
        J0_SPI_CLK  : out std_logic

        -- Lepton
     -- CAM_TH_SPI_CS_N : out std_logic;
     -- CAM_TH_MISO     : in  std_logic;
     -- CAM_TH_MOSI     : out std_logic;
     -- CAM_TH_CLK      : out std_logic;

        -- PCA9637
     -- PIO_SCL   : inout std_logic;
     -- PIO_SDA   : inout std_logic;
     -- PIO_INT_N : in    std_logic;
     -- RESET_N   : out   std_logic;

        -- OV7670
     -- CAM_D       : in  std_logic_vector(9 downto 0);
     -- CAM_PIX_CLK : in  std_logic;
     -- CAM_LV      : in  std_logic;
     -- CAM_FV      : in  std_logic;
     -- CAM_SYS_CLK : out std_logic;

        -- VGA and LCD shared signals
     -- VIDEO_CLK   : out std_logic;
     -- VIDEO_VSYNC : out std_logic;
     -- VIDEO_HSYNC : out std_logic;
     -- VIDEO_B     : out std_logic_vector(7 downto 0);
     -- VIDEO_G     : out std_logic_vector(7 downto 0);
     -- VIDEO_R     : out std_logic_vector(7 downto 0);

        -- LCD Specific signals
     -- LCD_DE         : out   std_logic;
     -- LCD_PIN_DAV_N  :       ? ?? std_logic;
     -- LCD_DISPLAY_EN : out   std_logic;
     -- SPI_MISO       : in    std_logic;
     -- SPI_ENA_N      : out   std_logic;
     -- SPI_CLK        : out   std_logic;
     -- SPI_MOSI       : out   std_logic;
     -- SPI_DAT        : inout std_logic;

        -- I2C TOUCH SCREEN
     -- TS_SCL : inout std_logic;
     -- TS_SDA : inout std_logic;

        -- BLUETOOTH (BLE)
     -- BLT_TXD : in  std_logic;
     -- BLT_RXD : out std_logic;

        -- I2C For VGA, PAL and OV7670 cameras
     -- CAM_PAL_VGA_SDA : inout std_logic;
     -- CAM_PAL_VGA_SCL : inout std_logic;

        -- ONE WIRE
     -- BOARD_ID : inout std_logic;

        -- PAL Camera
     -- PAL_VD_VD   : in  std_logic_vector(7 downto 0);
     -- PAL_VD_VSO  : in  std_logic;
     -- PAL_VD_HSO  : in  std_logic;
     -- PAL_VD_CLKO : in  std_logic;
     -- PAL_PWDN    : out std_logic;

        -- WIFI
     -- FROM_ESP_TXD : in  std_logic;
     -- TO_ESP_RXD   : out std_logic;

        -- LED RGB
     -- LED_BGR : out std_logic;

        -- HPS
     -- HPS_CONV_USB_N   : inout std_logic;
     -- HPS_DDR3_ADDR    : out   std_logic_vector(14 downto 0);
     -- HPS_DDR3_BA      : out   std_logic_vector(2 downto 0);
     -- HPS_DDR3_CAS_N   : out   std_logic;
     -- HPS_DDR3_CK_N    : out   std_logic;
     -- HPS_DDR3_CK_P    : out   std_logic;
     -- HPS_DDR3_CKE     : out   std_logic;
     -- HPS_DDR3_CS_N    : out   std_logic;
     -- HPS_DDR3_DM      : out   std_logic_vector(3 downto 0);
     -- HPS_DDR3_DQ      : inout std_logic_vector(31 downto 0);
     -- HPS_DDR3_DQS_N   : inout std_logic_vector(3 downto 0);
     -- HPS_DDR3_DQS_P   : inout std_logic_vector(3 downto 0);
     -- HPS_DDR3_ODT     : out   std_logic;
     -- HPS_DDR3_RAS_N   : out   std_logic;
     -- HPS_DDR3_RESET_N : out   std_logic;
     -- HPS_DDR3_RZQ     : in    std_logic;
     -- HPS_DDR3_WE_N    : out   std_logic;
     -- HPS_ENET_GTX_CLK : out   std_logic;
     -- HPS_ENET_INT_N   : inout std_logic;
     -- HPS_ENET_MDC     : out   std_logic;
     -- HPS_ENET_MDIO    : inout std_logic;
     -- HPS_ENET_RX_CLK  : in    std_logic;
     -- HPS_ENET_RX_DATA : in    std_logic_vector(3 downto 0);
     -- HPS_ENET_RX_DV   : in    std_logic;
     -- HPS_ENET_TX_DATA : out   std_logic_vector(3 downto 0);
     -- HPS_ENET_TX_EN   : out   std_logic;
     -- HPS_GSENSOR_INT  : inout std_logic;
     -- HPS_I2C0_SCLK    : inout std_logic;
     -- HPS_I2C0_SDAT    : inout std_logic;
     -- HPS_I2C1_SCLK    : inout std_logic;
     -- HPS_I2C1_SDAT    : inout std_logic;
     -- HPS_KEY_N        : inout std_logic;
     -- HPS_LED          : inout std_logic;
     -- HPS_LTC_GPIO     : inout std_logic;
     -- HPS_SD_CLK       : out   std_logic;
     -- HPS_SD_CMD       : inout std_logic;
     -- HPS_SD_DATA      : inout std_logic_vector(3 downto 0);
     -- HPS_SPIM_CLK     : out   std_logic;
     -- HPS_SPIM_MISO    : in    std_logic;
     -- HPS_SPIM_MOSI    : out   std_logic;
     -- HPS_SPIM_SS      : inout std_logic;
     -- HPS_UART_RX      : in    std_logic;
     -- HPS_UART_TX      : out   std_logic;
     -- HPS_USB_CLKOUT   : in    std_logic;
     -- HPS_USB_DATA     : inout std_logic_vector(7 downto 0);
     -- HPS_USB_DIR      : in    std_logic;
     -- HPS_USB_NXT      : in    std_logic;
     -- HPS_USB_STP      : out   std_logic
    );
end entity DE0_Nano_SoC_PrSoC_extn_board_top_level;

architecture rtl of DE0_Nano_SoC_PrSoC_extn_board_top_level is
    component soc_system is
        port (
            clk_clk                    : in  std_logic := 'X';
            reset_reset_n              : in  std_logic := 'X';
            pwm_0_conduit_end_pwm      : out std_logic;
            pwm_1_conduit_end_pwm      : out std_logic;
            mcp3204_0_conduit_end_cs_n : out std_logic;
            mcp3204_0_conduit_end_mosi : out std_logic;
            mcp3204_0_conduit_end_miso : in  std_logic := 'X';
            mcp3204_0_conduit_end_sclk : out std_logic
        );
    end component soc_system;

begin
    soc_system_inst : component soc_system
    port map (
        clk_clk                    => FPGA_CLK1_50,
        reset_reset_n              => KEY_N(0),
        pwm_0_conduit_end_pwm      => SERVO_0,
        pwm_1_conduit_end_pwm      => SERVO_1,
        mcp3204_0_conduit_end_cs_n => J0_SPI_CS_n,
        mcp3204_0_conduit_end_mosi => J0_SPI_MOSI,
        mcp3204_0_conduit_end_miso => J0_SPI_MISO,
        mcp3204_0_conduit_end_sclk => J0_SPI_CLK
    );

end;
