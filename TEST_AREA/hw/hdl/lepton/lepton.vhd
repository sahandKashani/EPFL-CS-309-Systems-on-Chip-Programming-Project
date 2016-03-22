library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lepton is
  port (
    clk       : in  std_logic;
    reset     : in  std_logic;
    address   : in  std_logic_vector(13 downto 0);
    readdata  : out std_logic_vector(15 downto 0);
    writedata : in  std_logic_vector(15 downto 0);
    read      : in  std_logic;
    write     : in  std_logic;

    SCLK : out std_logic;
    CSn  : out std_logic;
    MOSI : out std_logic;
    MISO : in  std_logic
    );

end lepton;

architecture rtl of lepton is

  component ram_writer
    port (
      clk, reset    : in  std_logic;
      pix_data      : in  std_logic_vector(13 downto 0);
      pix_valid     : in  std_logic;
      pix_sof       : in  std_logic;
      pix_eof       : in  std_logic;
      ram_data      : out std_logic_vector(15 downto 0);
      ram_wren      : out std_logic;
      ram_wraddress : out std_logic_vector(12 downto 0));
  end component;

  component dual_ported_ram
    port (
      clock     : in  std_logic := '1';
      data      : in  std_logic_vector (15 downto 0);
      rdaddress : in  std_logic_vector (12 downto 0);
      wraddress : in  std_logic_vector (12 downto 0);
      wren      : in  std_logic := '0';
      q         : out std_logic_vector (15 downto 0));
  end component;

  component byte2pix
    port (
      clk, reset : in  std_logic;
      byte_data  : in  std_logic_vector(7 downto 0);
      byte_valid : in  std_logic;
      byte_sof   : in  std_logic;
      byte_eof   : in  std_logic;
      pix_data   : out std_logic_vector(13 downto 0);
      pix_valid  : out std_logic;
      pix_sof    : out std_logic;
      pix_eof    : out std_logic);
  end component;

  component lepton_manager
    port (
      clk                 : in  std_logic := '0';
      reset               : in  std_logic := '0';
      spi_miso_sink_data  : in  std_logic_vector(7 downto 0);
      spi_miso_sink_valid : in  std_logic;
      spi_mosi_src_data   : out std_logic_vector(7 downto 0);
      spi_mosi_src_valid  : out std_logic;
      spi_mosi_src_ready  : in  std_logic := '0';
      lepton_out_data     : out std_logic_vector(7 downto 0);
      lepton_out_valid    : out std_logic;
      lepton_out_sof      : out std_logic;
      lepton_out_eof      : out std_logic;
      row_idx             : out std_logic_vector(5 downto 0);
      error               : out std_logic;
      start               : in  std_logic;
      spi_cs_n            : out std_logic := '0');
  end component;

  component avalon_st_spi_master
    port (
      clk             : in  std_logic;
      reset           : in  std_logic;
      spi_cs_n        : in  std_logic;
      mosi_sink_data  : in  std_logic_vector(7 downto 0);
      mosi_sink_valid : in  std_logic;
      mosi_sink_ready : out std_logic;
      miso_src_data   : out std_logic_vector(7 downto 0);
      miso_src_valid  : out std_logic;
      SCLK            : out std_logic;
      MISO            : in  std_logic;
      MOSI            : out std_logic;
      CS_n            : out std_logic);
  end component;

  component lepton_stats
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
  end component;

  component level_adjuster
    port (
      clk            : in  std_logic;
      raw_pixel      : in  std_logic_vector(13 downto 0);
      raw_max        : in  std_logic_vector(13 downto 0);
      raw_min        : in  std_logic_vector(13 downto 0);
      raw_sum        : in  std_logic_vector(26 downto 0);
      adjusted_pixel : out std_logic_vector(13 downto 0));
  end component;


  signal spi_cs_n             : std_logic;
  signal spi_mosi_data        : std_logic_vector(7 downto 0);
  signal spi_mosi_valid       : std_logic;
  signal spi_mosi_ready       : std_logic;
  signal spi_miso_data        : std_logic_vector(7 downto 0);
  signal spi_miso_valid       : std_logic;
  signal lepton_manager_start : std_logic;
  signal lepton_manager_error : std_logic;
  signal byte_data            : std_logic_vector(7 downto 0);
  signal byte_valid           : std_logic;
  signal byte_sof             : std_logic;
  signal byte_eof             : std_logic;
  signal pix_data             : std_logic_vector(13 downto 0);
  signal pix_valid            : std_logic;
  signal pix_sof              : std_logic;
  signal pix_eof              : std_logic;
  signal stat_min             : std_logic_vector(13 downto 0);
  signal stat_max             : std_logic_vector(13 downto 0);
  signal stat_sum             : std_logic_vector(26 downto 0);
  signal stat_valid           : std_logic;
  signal ram_data             : std_logic_vector(15 downto 0);
  signal ram_wren             : std_logic;
  signal ram_wraddress        : std_logic_vector(12 downto 0);
  signal ram_rdaddress        : std_logic_vector (12 downto 0);
  signal ram_q                : std_logic_vector (15 downto 0);
  signal row_idx              : std_logic_vector(5 downto 0);
  signal raw_pixel            : std_logic_vector(13 downto 0);
  signal raw_max              : std_logic_vector(13 downto 0);
  signal raw_min              : std_logic_vector(13 downto 0);
  signal raw_sum              : std_logic_vector(26 downto 0);
  signal adjusted_pixel       : std_logic_vector(13 downto 0);

  constant COMMAND_REG_OFFSET         : std_logic_vector(address'range) := "00000000000000";
  constant STATUS_REG_OFFSET          : std_logic_vector(address'range) := "00000000000001";
  constant MIN_REG_OFFSET             : std_logic_vector(address'range) := "00000000000010";
  constant MAX_REG_OFFSET             : std_logic_vector(address'range) := "00000000000011";
  constant SUM_MSB_REG_OFFSET         : std_logic_vector(address'range) := "00000000000100";
  constant SUM_LSB_REG_OFFSET         : std_logic_vector(address'range) := "00000000000101";
  constant ROW_IDX_REG_OFFSET         : std_logic_vector(address'range) := "00000000000110";
  constant BUFFER_REG_OFFSET          : unsigned(address'range)         := "00000000001000";
  constant ADJUSTED_BUFFER_REG_OFFSET : unsigned(address'range)         := "10000000000000";

  constant IMAGE_SIZE       : integer                 := 80*60;
  constant BUFFER_REG_LIMIT : unsigned(address'range) := unsigned(BUFFER_REG_OFFSET) + IMAGE_SIZE;

  constant ADJUSTED_BUFFER_LIMIT : unsigned(address'range) := unsigned(ADJUSTED_BUFFER_REG_OFFSET) + IMAGE_SIZE;

  signal max_reg   : std_logic_vector(stat_max'range);
  signal min_reg   : std_logic_vector(stat_min'range);
  signal sum_reg   : std_logic_vector(stat_sum'range);
  signal error_reg : std_logic;

begin

  spi_controller0 : avalon_st_spi_master
    port map (
      clk             => clk,
      reset           => reset,
      spi_cs_n        => spi_cs_n,
      mosi_sink_data  => spi_mosi_data,
      mosi_sink_valid => spi_mosi_valid,
      mosi_sink_ready => spi_mosi_ready,
      miso_src_data   => spi_miso_data,
      miso_src_valid  => spi_miso_valid,
      SCLK            => SCLK,
      MISO            => MISO,
      MOSI            => MOSI,
      CS_n            => CSn);

  lepton_manager0 : lepton_manager
    port map (
      clk                 => clk,
      reset               => reset,
      spi_miso_sink_data  => spi_miso_data,
      spi_miso_sink_valid => spi_miso_valid,
      spi_mosi_src_data   => spi_mosi_data,
      spi_mosi_src_valid  => spi_mosi_valid,
      spi_mosi_src_ready  => spi_mosi_ready,
      lepton_out_data     => byte_data,
      lepton_out_valid    => byte_valid,
      lepton_out_sof      => byte_sof,
      lepton_out_eof      => byte_eof,
      row_idx             => row_idx,
      error               => lepton_manager_error,
      start               => lepton_manager_start,
      spi_cs_n            => spi_cs_n);

  byte2pix0 : byte2pix
    port map (
      clk        => clk,
      reset      => reset,
      byte_data  => byte_data,
      byte_valid => byte_valid,
      byte_sof   => byte_sof,
      byte_eof   => byte_eof,
      pix_data   => pix_data,
      pix_valid  => pix_valid,
      pix_sof    => pix_sof,
      pix_eof    => pix_eof);

  lepton_stats0 : lepton_stats
    port map (
      reset      => reset,
      clk        => clk,
      pix_data   => pix_data,
      pix_valid  => pix_valid,
      pix_sof    => pix_sof,
      pix_eof    => pix_eof,
      stat_min   => stat_min,
      stat_max   => stat_max,
      stat_sum   => stat_sum,
      stat_valid => stat_valid);

  ram_writer0 : ram_writer
    port map (
      clk           => clk,
      reset         => reset,
      pix_data      => pix_data,
      pix_valid     => pix_valid,
      pix_sof       => pix_sof,
      pix_eof       => pix_eof,
      ram_data      => ram_data,
      ram_wren      => ram_wren,
      ram_wraddress => ram_wraddress);

  dual_ported_ram0 : dual_ported_ram
    port map (
      clock     => clk,
      data      => ram_data,
      rdaddress => ram_rdaddress,
      wraddress => ram_wraddress,
      wren      => ram_wren,
      q         => ram_q);

  level_adjuster0 : level_adjuster
    port map (
      clk            => clk,
      raw_pixel      => ram_q(13 downto 0),
      raw_max        => max_reg,
      raw_min        => min_reg,
      raw_sum        => sum_reg,
      adjusted_pixel => adjusted_pixel);

  p_lepton_start : process (clk, reset)
  begin
    if reset = '1' then
      lepton_manager_start <= '0';
      error_reg <= '0';
    elsif rising_edge(clk) then
      if write = '1' and address = COMMAND_REG_OFFSET then
        lepton_manager_start <= writedata(0);
        error_reg <= '0';
      elsif pix_eof = '1' then
        lepton_manager_start <= '0';
      elsif lepton_manager_error = '0' then
        error_reg <= '1';
      end if;
    end if;
  end process p_lepton_start;

  p_stat_reg : process (clk, reset)
  begin
    if reset = '1' then
      min_reg <= (others => '0');
      max_reg <= (others => '0');
      sum_reg <= (others => '0');
    elsif rising_edge(clk) then
      if stat_valid = '1' then
        min_reg <= stat_min;
        max_reg <= stat_max;
        sum_reg <= stat_sum;
      end if;
    end if;
  end process p_stat_reg;

  p_read : process (clk, reset)
  begin

    if reset = '1' then
      readdata      <= (others => '0');
      ram_rdaddress <= (others => '0');
    elsif rising_edge(clk) then
      readdata <= (others => '0');
      if read = '1' then
        case address is

          when STATUS_REG_OFFSET =>
            readdata(1) <= error_reg;
            readdata(0) <= lepton_manager_start;

          when MIN_REG_OFFSET =>
            readdata <= "00" & min_reg;

          when MAX_REG_OFFSET =>
            readdata <= "00" & max_reg;

          when SUM_MSB_REG_OFFSET =>
            readdata <= "00000" & sum_reg(26 downto 16);

          when SUM_LSB_REG_OFFSET =>
            readdata <= sum_reg(15 downto 0);

          when ROW_IDX_REG_OFFSET =>
            readdata(5 downto 0) <= row_idx;

          when others =>
            if unsigned(address) >= BUFFER_REG_OFFSET and unsigned(address) < BUFFER_REG_LIMIT then
              ram_rdaddress <= std_logic_vector(resize(unsigned(address) - BUFFER_REG_OFFSET, ram_rdaddress'length));
              readdata      <= ram_q;
            elsif unsigned(address) >= ADJUSTED_BUFFER_REG_OFFSET and unsigned(address) < ADJUSTED_BUFFER_LIMIT then
              ram_rdaddress <= std_logic_vector(resize(unsigned(address) - ADJUSTED_BUFFER_REG_OFFSET, ram_rdaddress'length));
              readdata      <= "00" & adjusted_pixel;
            end if;
        end case;
      end if;
    end if;
  end process p_read;

end rtl;
