-- #############################################################################
-- DE0_Nano_SoC_top_level.vhd
--
-- BOARD         : DE0-Nano-SoC from Terasic
-- Author        : Philemon Favrod (based on Sahand Kashani-Akhavan´s work
-- Revision      : 1.0
-- Creation date : 4/06/2016
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

entity DE0_Nano_SoC_prsoc_top_level is
    port(
        -- CLOCK
        FPGA_CLK1_50     : in    std_logic;
		  
		  -- VIDEO
		  VIDEO_CLK        : out std_logic;
		  VIDEO_HSYNC      : out std_logic;
		  VIDEO_VSYNC      : out std_logic;
		  VIDEO_R          : out std_logic_vector(7 downto 0);
		  VIDEO_G          : out std_logic_vector(7 downto 0);
		  VIDEO_B          : out std_logic_vector(7 downto 0);
		  
		  -- LCD
		  LCD_DISPLAY_EN   : out std_logic;
		  LCD_DE           : out std_logic;

        -- HPS
        HPS_DDR3_ADDR    : out   std_logic_vector(14 downto 0);
        HPS_DDR3_BA      : out   std_logic_vector(2 downto 0);
        HPS_DDR3_CAS_N   : out   std_logic;
        HPS_DDR3_CK_N    : out   std_logic;
        HPS_DDR3_CK_P    : out   std_logic;
        HPS_DDR3_CKE     : out   std_logic;
        HPS_DDR3_CS_N    : out   std_logic;
        HPS_DDR3_DM      : out   std_logic_vector(3 downto 0);
        HPS_DDR3_DQ      : inout std_logic_vector(31 downto 0);
        HPS_DDR3_DQS_N   : inout std_logic_vector(3 downto 0);
        HPS_DDR3_DQS_P   : inout std_logic_vector(3 downto 0);
        HPS_DDR3_ODT     : out   std_logic;
        HPS_DDR3_RAS_N   : out   std_logic;
        HPS_DDR3_RESET_N : out   std_logic;
        HPS_DDR3_RZQ     : in    std_logic;
        HPS_DDR3_WE_N    : out   std_logic;
        HPS_ENET_GTX_CLK : out   std_logic;
        HPS_ENET_INT_N   : inout std_logic;
        HPS_ENET_MDC     : out   std_logic;
        HPS_ENET_MDIO    : inout std_logic;
        HPS_ENET_RX_CLK  : in    std_logic;
        HPS_ENET_RX_DATA : in    std_logic_vector(3 downto 0);
        HPS_ENET_RX_DV   : in    std_logic;
        HPS_ENET_TX_DATA : out   std_logic_vector(3 downto 0);
        HPS_ENET_TX_EN   : out   std_logic;
        HPS_SD_CLK       : out   std_logic;
        HPS_SD_CMD       : inout std_logic;
        HPS_SD_DATA      : inout std_logic_vector(3 downto 0);
        HPS_UART_RX      : in    std_logic;
        HPS_UART_TX      : out   std_logic
    );
end entity DE0_Nano_SoC_prsoc_top_level;

architecture rtl of DE0_Nano_SoC_prsoc_top_level is
	component soc_system is
		port (
			clk_clk                           : in    std_logic                     := 'X';             -- clk
			hps_0_ddr_mem_a                   : out   std_logic_vector(14 downto 0);                    -- mem_a
			hps_0_ddr_mem_ba                  : out   std_logic_vector(2 downto 0);                     -- mem_ba
			hps_0_ddr_mem_ck                  : out   std_logic;                                        -- mem_ck
			hps_0_ddr_mem_ck_n                : out   std_logic;                                        -- mem_ck_n
			hps_0_ddr_mem_cke                 : out   std_logic;                                        -- mem_cke
			hps_0_ddr_mem_cs_n                : out   std_logic;                                        -- mem_cs_n
			hps_0_ddr_mem_ras_n               : out   std_logic;                                        -- mem_ras_n
			hps_0_ddr_mem_cas_n               : out   std_logic;                                        -- mem_cas_n
			hps_0_ddr_mem_we_n                : out   std_logic;                                        -- mem_we_n
			hps_0_ddr_mem_reset_n             : out   std_logic;                                        -- mem_reset_n
			hps_0_ddr_mem_dq                  : inout std_logic_vector(31 downto 0) := (others => 'X'); -- mem_dq
			hps_0_ddr_mem_dqs                 : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs
			hps_0_ddr_mem_dqs_n               : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs_n
			hps_0_ddr_mem_odt                 : out   std_logic;                                        -- mem_odt
			hps_0_ddr_mem_dm                  : out   std_logic_vector(3 downto 0);                     -- mem_dm
			hps_0_ddr_oct_rzqin               : in    std_logic                     := 'X';             -- oct_rzqin
			hps_0_io_hps_io_emac1_inst_TX_CLK : out   std_logic;                                        -- hps_io_emac1_inst_TX_CLK
			hps_0_io_hps_io_emac1_inst_TXD0   : out   std_logic;                                        -- hps_io_emac1_inst_TXD0
			hps_0_io_hps_io_emac1_inst_TXD1   : out   std_logic;                                        -- hps_io_emac1_inst_TXD1
			hps_0_io_hps_io_emac1_inst_TXD2   : out   std_logic;                                        -- hps_io_emac1_inst_TXD2
			hps_0_io_hps_io_emac1_inst_TXD3   : out   std_logic;                                        -- hps_io_emac1_inst_TXD3
			hps_0_io_hps_io_emac1_inst_RXD0   : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD0
			hps_0_io_hps_io_emac1_inst_MDIO   : inout std_logic                     := 'X';             -- hps_io_emac1_inst_MDIO
			hps_0_io_hps_io_emac1_inst_MDC    : out   std_logic;                                        -- hps_io_emac1_inst_MDC
			hps_0_io_hps_io_emac1_inst_RX_CTL : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RX_CTL
			hps_0_io_hps_io_emac1_inst_TX_CTL : out   std_logic;                                        -- hps_io_emac1_inst_TX_CTL
			hps_0_io_hps_io_emac1_inst_RX_CLK : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RX_CLK
			hps_0_io_hps_io_emac1_inst_RXD1   : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD1
			hps_0_io_hps_io_emac1_inst_RXD2   : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD2
			hps_0_io_hps_io_emac1_inst_RXD3   : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD3
			hps_0_io_hps_io_sdio_inst_CMD     : inout std_logic                     := 'X';             -- hps_io_sdio_inst_CMD
			hps_0_io_hps_io_sdio_inst_D0      : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D0
			hps_0_io_hps_io_sdio_inst_D1      : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D1
			hps_0_io_hps_io_sdio_inst_CLK     : out   std_logic;                                        -- hps_io_sdio_inst_CLK
			hps_0_io_hps_io_sdio_inst_D2      : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D2
			hps_0_io_hps_io_sdio_inst_D3      : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D3
			hps_0_io_hps_io_uart0_inst_RX     : in    std_logic                     := 'X';             -- hps_io_uart0_inst_RX
			hps_0_io_hps_io_uart0_inst_TX     : out   std_logic;                                        -- hps_io_uart0_inst_TX
			hps_0_io_hps_io_gpio_inst_GPIO35  : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO35
			reset_reset_n                     : in    std_logic                     := 'X';             -- reset_n
			vga_hsync                         : out   std_logic;                                        -- hsync
			vga_g                             : out   std_logic_vector(7 downto 0);                     -- g
			vga_b                             : out   std_logic_vector(7 downto 0);                     -- b
			vga_de                            : out   std_logic;                                        -- de
			vga_vsync                         : out   std_logic;                                        -- vsync
			vga_r                             : out   std_logic_vector(7 downto 0);                     -- r
			pixclk_clk                        : out   std_logic                                         -- clk
		);
	end component soc_system;
begin
	u0 : component soc_system
		port map (
			clk_clk                           => FPGA_CLK1_50,
			hps_0_ddr_mem_a                   => HPS_DDR3_ADDR,                   -- hps_0_ddr.mem_a
			hps_0_ddr_mem_ba                  => HPS_DDR3_BA,                  --          .mem_ba
			hps_0_ddr_mem_ck                  => HPS_DDR3_CK_P,                  --          .mem_ck
			hps_0_ddr_mem_ck_n                => HPS_DDR3_CK_N,                --          .mem_ck_n
			hps_0_ddr_mem_cke                 => HPS_DDR3_CKE,                 --          .mem_cke
			hps_0_ddr_mem_cs_n                => HPS_DDR3_CS_N,                --          .mem_cs_n
			hps_0_ddr_mem_ras_n               => HPS_DDR3_RAS_N,               --          .mem_ras_n
			hps_0_ddr_mem_cas_n               => HPS_DDR3_CAS_N,               --          .mem_cas_n
			hps_0_ddr_mem_we_n                => HPS_DDR3_WE_N,                --          .mem_we_n
			hps_0_ddr_mem_reset_n             => HPS_DDR3_RESET_N,             --          .mem_reset_n
			hps_0_ddr_mem_dq                  => HPS_DDR3_DQ,                  --          .mem_dq
			hps_0_ddr_mem_dqs                 => HPS_DDR3_DQS_P,                 --          .mem_dqs
			hps_0_ddr_mem_dqs_n               => HPS_DDR3_DQS_N,               --          .mem_dqs_n
			hps_0_ddr_mem_odt                 => HPS_DDR3_ODT,                 --          .mem_odt
			hps_0_ddr_mem_dm                  => HPS_DDR3_DM,                  --          .mem_dm
			hps_0_ddr_oct_rzqin               => HPS_DDR3_RZQ,               --          .oct_rzqin
			hps_0_io_hps_io_emac1_inst_TX_CLK => HPS_ENET_GTX_CLK, --  hps_0_io.hps_io_emac1_inst_TX_CLK
			hps_0_io_hps_io_emac1_inst_TXD0   => HPS_ENET_TX_DATA(0),   --          .hps_io_emac1_inst_TXD0
			hps_0_io_hps_io_emac1_inst_TXD1   => HPS_ENET_TX_DATA(1),   --          .hps_io_emac1_inst_TXD1
			hps_0_io_hps_io_emac1_inst_TXD2   => HPS_ENET_TX_DATA(2),   --          .hps_io_emac1_inst_TXD2
			hps_0_io_hps_io_emac1_inst_TXD3   => HPS_ENET_TX_DATA(3),   --          .hps_io_emac1_inst_TXD3
			hps_0_io_hps_io_emac1_inst_RXD0   => HPS_ENET_RX_DATA(0),                            --          .hps_io_emac1_inst_RXD0
			hps_0_io_hps_io_emac1_inst_MDIO   => HPS_ENET_MDIO,                                  --          .hps_io_emac1_inst_MDIO
			hps_0_io_hps_io_emac1_inst_MDC    => HPS_ENET_MDC,                                   --          .hps_io_emac1_inst_MDC
			hps_0_io_hps_io_emac1_inst_RX_CTL => HPS_ENET_RX_DV,                                 --          .hps_io_emac1_inst_RX_CTL
			hps_0_io_hps_io_emac1_inst_TX_CTL => HPS_ENET_TX_EN,                                 --          .hps_io_emac1_inst_TX_CTL
			hps_0_io_hps_io_emac1_inst_RX_CLK => HPS_ENET_RX_CLK,                                --          .hps_io_emac1_inst_RX_CLK
			hps_0_io_hps_io_emac1_inst_RXD1   => HPS_ENET_RX_DATA(1),                            --          .hps_io_emac1_inst_RXD1
			hps_0_io_hps_io_emac1_inst_RXD2   => HPS_ENET_RX_DATA(2),                            --          .hps_io_emac1_inst_RXD2
			hps_0_io_hps_io_emac1_inst_RXD3   => HPS_ENET_RX_DATA(3),                            --          .hps_io_emac1_inst_RXD3
			hps_0_io_hps_io_sdio_inst_CMD     => HPS_SD_CMD,     --          .hps_io_sdio_inst_CMD
			hps_0_io_hps_io_sdio_inst_D0      => HPS_SD_DATA(0),      --          .hps_io_sdio_inst_D0
			hps_0_io_hps_io_sdio_inst_D1      => HPS_SD_DATA(1),      --          .hps_io_sdio_inst_D1
			hps_0_io_hps_io_sdio_inst_CLK     => HPS_SD_CLK,     --          .hps_io_sdio_inst_CLK
			hps_0_io_hps_io_sdio_inst_D2      => HPS_SD_DATA(2),      --          .hps_io_sdio_inst_D2
			hps_0_io_hps_io_sdio_inst_D3      => HPS_SD_DATA(3),      --          .hps_io_sdio_inst_D3
			hps_0_io_hps_io_uart0_inst_RX     => HPS_UART_RX,     --          .hps_io_uart0_inst_RX
			hps_0_io_hps_io_uart0_inst_TX     => HPS_UART_TX,     --          .hps_io_uart0_inst_TX
			hps_0_io_hps_io_gpio_inst_GPIO35  => HPS_ENET_INT_N,
			reset_reset_n                     => '1',                     --     reset.reset_n
			pixclk_clk                        => VIDEO_CLK,
			vga_hsync                         => VIDEO_HSYNC,                         --       vga.hsync
			vga_g                             => VIDEO_G,                             --          .g
			vga_b                             => VIDEO_B,                             --          .b
			vga_de                            => LCD_DE,                            --          .de
			vga_vsync                         => VIDEO_VSYNC,                         --          .vsync
			vga_r                             => VIDEO_R                              --          .r
		);
		
		LCD_DISPLAY_EN <= '1'; 
end;
