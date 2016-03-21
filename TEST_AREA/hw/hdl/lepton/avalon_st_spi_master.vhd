library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils.all;

entity avalon_st_spi_master is
  generic(
    INPUT_CLK_FREQ : integer   := 50000000;
    SPI_SCLK_FREQ  : integer   := 5000000;
    CPOL           : integer   := 1;
    CPHA           : integer   := 1
    );
  port(
    -- Input clock
    clk : in std_logic;

    -- Reset
    reset           : in  std_logic;
    spi_cs_n        : in  std_logic;
    -- Sink Avalon ST Interface
    mosi_sink_data  : in  std_logic_vector(7 downto 0);
    mosi_sink_valid : in  std_logic;
    mosi_sink_ready : out std_logic;

    -- Source Avalon ST Interface
    miso_src_data  : out std_logic_vector(7 downto 0);
    miso_src_valid : out std_logic;

    -- SPI Master signals
    SCLK : out std_logic;
    MISO : in  std_logic;
    MOSI : out std_logic;
    CS_n : out std_logic
    );
end avalon_st_spi_master;

architecture rtl of avalon_st_spi_master is
  constant SCLK_PRESCALER_MAX : integer := INPUT_CLK_FREQ / SPI_SCLK_FREQ / 2;
  signal   sclk_prescaler     : unsigned(bitlength(SCLK_PRESCALER_MAX) downto 0);
  signal   sclk_toggle        : std_logic;

  signal new_sink_buffer, cur_sink_buffer           : std_logic_vector(mosi_sink_data'range);
  signal new_sink_buffer_busy, cur_sink_buffer_busy : std_logic;


  signal miso_src_buffer : std_logic_vector(7 downto 0);

  signal spi_done, i_sclk : std_logic;
  signal spi_bit_index    : unsigned(2 downto 0);
begin

  CS_n <= spi_cs_n;

  p_sclk_prescaler : process (clk, reset) is
  begin
    if reset = '1' then
      sclk_prescaler <= to_unsigned(1, sclk_prescaler'length);
    elsif rising_edge(clk) then
      if sclk_prescaler = SCLK_PRESCALER_MAX then
        sclk_prescaler <= to_unsigned(1, sclk_prescaler'length);
      else
        sclk_prescaler <= sclk_prescaler + 1;
      end if;
    end if;
  end process p_sclk_prescaler;
  sclk_toggle <= '1' when sclk_prescaler = SCLK_PRESCALER_MAX else '0';

  p_avalon_st_sink : process (clk, reset) is
  begin
    if reset = '1' then
      new_sink_buffer_busy <= '0';
      new_sink_buffer      <= (others => '0');
    elsif rising_edge(clk) then
      if mosi_sink_valid = '1' then
        if new_sink_buffer_busy = '0' and cur_sink_buffer_busy = '1' then
          new_sink_buffer      <= mosi_sink_data;
          new_sink_buffer_busy <= '1';
        end if;
      elsif new_sink_buffer_busy = '1' and cur_sink_buffer_busy = '0' then
        new_sink_buffer_busy <= '0';
      end if;
    end if;
  end process p_avalon_st_sink;
  mosi_sink_ready <= not new_sink_buffer_busy;

  p_cur_buffer : process (clk, reset) is
  begin
    if reset = '1' then
      cur_sink_buffer      <= (others => '0');
      cur_sink_buffer_busy <= '0';
    elsif rising_edge(clk) then
      if mosi_sink_valid = '1' and cur_sink_buffer_busy = '0' then
        cur_sink_buffer      <= mosi_sink_data;
        cur_sink_buffer_busy <= '1';
      elsif cur_sink_buffer_busy = '0' and new_sink_buffer_busy = '1' then
        cur_sink_buffer      <= new_sink_buffer;
        cur_sink_buffer_busy <= '1';
      elsif cur_sink_buffer_busy = '1' and spi_done = '1' then
        cur_sink_buffer_busy <= '0';
      end if;
    end if;
  end process p_cur_buffer;

  p_spi : process (clk, reset) is
  begin
    if reset = '1' then
      spi_done        <= '0';
      i_sclk          <= to_unsigned(CPOL, 1)(0);
      spi_bit_index   <= "000";
      MOSI            <= '0';
      miso_src_data   <= (others => '0');
      miso_src_valid  <= '0';
      miso_src_buffer <= (others => '0');
      
    elsif rising_edge(clk) then
      spi_done       <= '0';
      miso_src_valid <= '0';
      if cur_sink_buffer_busy = '1' and sclk_toggle = '1' then

        if i_sclk /= to_unsigned(CPHA, 1)(0) then

          if spi_bit_index = "111" then
            spi_done       <= '1';
            spi_bit_index  <= "000";
            miso_src_valid <= '1';
            miso_src_data  <= miso_src_buffer(7 downto 1) & MISO;
          else
            MOSI                                           <= cur_sink_buffer(7 - to_integer(spi_bit_index));
            miso_src_buffer(7 - to_integer(spi_bit_index)) <= MISO;
            spi_bit_index                                  <= spi_bit_index + 1;

          end if;

        end if;

        i_sclk <= not i_sclk;
        
      end if;
    end if;
  end process p_spi;
  SCLK <= i_sclk;
  
end rtl;
