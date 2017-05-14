-------------------------------------------------------------------------------
-- Title      : Frame Buffer Manager
-- Project    : From FPGA to Linux: An embedded system exploration
-------------------------------------------------------------------------------
-- File       : framebuffer_manager.vhd
-- Author     : Philemon Orphee Favrod  <philemon.favrod@epfl.ch>
-- Company    : 
-- Created    : 2016-03-10
-- Last update: 2016-05-23
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: DMA-capable unit that manages reads to a framebuffer.
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2016-03-10  1.0      P. Favrod       Created
-- 2016-04-25  1.1      P. Favrod       Debuged
-- 2016-05-23  1.2      P. Favrod       Increased bandwidth + fifo sync @ VFP
-- 2016-05-29  1.3      P. Favrod       Added MSB to FIFO + removed wrfull
-------------------------------------------------------------------------------
-- Register Memory Mapping
-- +-------+--------+-----+-----+----+-----+----+------------+
-- | Regno | Access | B31 | ... | B5 | ... | B1 | B0         |
-- +-------+--------+-----+-----+----+-----+----+------------+
-- | 0     | R/W    |          FRAME_START_ADDRESS           |
-- +-------+--------+----------------------------------------+
-- | 1     | R/W    |         FRAME_PIXEL_PER_LINE           |
-- +-------+--------+----------------------------------------+
-- | 2     | R/W    |          FRAME_LINES_PER_FRAME         |
-- +-------+--------+----------------------------------------+
-- | 3     | R/W    |          FRAME_EOL_BYTE_OFFSET         |
-- +-------+--------+----------------------------------------+
-- | 4     | WO     |                           | FB_READ_EN |
-- +-------+--------+---------------------------+------------+
-- | 5     | R/W    |           |       FB_BURST_COUNT       |
-- +-------+--------+-----------+----------------------------+
-- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity framebuffer_manager is
  
  port(
    clk    : in std_logic;
    pixclk : in std_logic;
    reset  : in std_logic;

    -- Avalon-MM Slave Interface
    as_address   : in  std_logic_vector(3 downto 0);
    as_read      : in  std_logic;
    as_readdata  : out std_logic_vector(31 downto 0);
    as_write     : in  std_logic;
    as_writedata : in  std_logic_vector(31 downto 0);

    -- Avalon-MM Master Interface
    am_address       : out std_logic_vector(31 downto 0);
    am_waitrequest   : in  std_logic;
    am_burstcount    : out std_logic_vector(10 downto 0);
    am_read          : out std_logic;
    am_readdata      : in  std_logic_vector(63 downto 0);
    am_readdatavalid : in  std_logic;

    frame_sync : in std_logic;

    -- Interrupt Sender Interface
    irq : out std_logic;

    -- Avalon-ST Source Interface
    src_data  : out std_logic_vector(23 downto 0);
    src_valid : out std_logic;
    src_ready : in  std_logic);
end framebuffer_manager;

architecture rtl of framebuffer_manager is

  constant MAX_BURST_COUNT : integer := 1024;

  constant FRAME_START_ADDRESS_REGNO   : std_logic_vector(as_address'range) := std_logic_vector(to_unsigned(0, as_address'length));
  constant FRAME_PIXEL_PER_LINE_REGNO  : std_logic_vector(as_address'range) := std_logic_vector(to_unsigned(1, as_address'length));
  constant FRAME_LINES_PER_FRAME_REGNO : std_logic_vector(as_address'range) := std_logic_vector(to_unsigned(2, as_address'length));
  constant FRAME_EOL_BYTE_OFFSET_REGNO : std_logic_vector(as_address'range) := std_logic_vector(to_unsigned(3, as_address'length));
  constant FB_COMMAND_REGNO            : std_logic_vector(as_address'range) := std_logic_vector(to_unsigned(4, as_address'length));
  constant FB_BURST_COUNT_REGNO        : std_logic_vector(as_address'range) := std_logic_vector(to_unsigned(5, as_address'length));

  signal start_address                         : integer;
  signal current_address                       : integer;
  signal pix_per_line, pix_per_line_copy       : integer;
  signal num_lines, num_lines_copy             : integer;
  signal eol_byte_offset, eol_byte_offset_copy : integer;
  signal enabled                               : boolean;
  signal burst_count, burst_count_copy         : integer;
  signal irq_enabled                           : boolean;
  signal irq_acknowledged                      : boolean;

  signal burst_counter : integer range 1 to MAX_BURST_COUNT;
  signal pix_counter   : integer;
  signal line_counter  : integer;

  type   state is (IDLE, MEMSTARTREAD, MEMRESTARTREAD, MEMREAD, FLUSHBURST, WAITSYNC);
  signal current_state : state;

  constant INTERNAL_FIFO_DEPTH : integer := 256;
  signal   fifo_clr            : std_logic;
  signal   fifo_data_in        : std_logic_vector(47 downto 0);
  signal   fifo_data_out       : std_logic_vector(23 downto 0);
  signal   fifo_read           : std_logic;
  signal   fifo_write          : std_logic;
  signal   fifo_usedw          : std_logic_vector(8 downto 0);
  signal   fifo_freew          : integer range 0 to INTERNAL_FIFO_DEPTH;
  signal   fifo_empty          : std_logic;
  signal   fifo_large_enough   : boolean;
begin
  dc_video_fifo_inst : entity work.dc_video_fifo port map (
    aclr    => fifo_clr,
    data    => fifo_data_in,
    rdclk   => pixclk,
    rdreq   => fifo_read,
    wrclk   => clk,
    wrreq   => fifo_write,
    q       => fifo_data_out,
    rdempty => fifo_empty,
    wrusedw => fifo_usedw);

  fifo_write        <= am_readdatavalid and not fifo_clr when current_state = MEMREAD else '0';
  fifo_read         <= src_ready and not fifo_empty;
  fifo_clr          <= '1'                               when current_state = IDLE    else '0';
  fifo_freew        <= INTERNAL_FIFO_DEPTH - to_integer(unsigned(fifo_usedw));
  fifo_large_enough <= fifo_freew >= burst_count_copy;
  fifo_data_in      <= am_readdata(55 downto 32) & am_readdata(23 downto 0);

  src_data  <= fifo_data_out when fifo_empty = '0' else X"ff0000";
  src_valid <= not fifo_empty;

  p_as_write : process (clk, reset)
  begin
    if reset = '1' then
      start_address    <= 0;
      pix_per_line     <= 0;
      num_lines        <= 0;
      eol_byte_offset  <= 0;
      burst_count      <= 4;
      enabled          <= false;
      irq_enabled      <= false;
      irq_acknowledged <= false;

    elsif rising_edge(clk) then
      
      irq_acknowledged <= false;

      if as_write = '1' then
        case as_address is
          when FRAME_START_ADDRESS_REGNO =>
            start_address <= to_integer(unsigned(as_writedata));

          when FRAME_PIXEL_PER_LINE_REGNO =>
            pix_per_line <= to_integer(unsigned(as_writedata));

          when FRAME_LINES_PER_FRAME_REGNO =>
            num_lines <= to_integer(unsigned(as_writedata));

          when FRAME_EOL_BYTE_OFFSET_REGNO =>
            eol_byte_offset <= to_integer(unsigned(as_writedata));

          when FB_COMMAND_REGNO =>
            if as_writedata(0) = '1' then
              enabled <= true;
            end if;

            if as_writedata(1) = '1' then
              enabled <= false;
            end if;

            if as_writedata(2) = '1' then
              irq_enabled <= true;
            end if;

            if as_writedata(3) = '1' then
              irq_enabled <= false;
            end if;

            if as_writedata(4) = '1' then
              irq_acknowledged <= true;
            end if;

          when FB_BURST_COUNT_REGNO =>
            if unsigned(as_writedata) > MAX_BURST_COUNT then
              burst_count <= MAX_BURST_COUNT;
            else
              burst_count <= to_integer(unsigned(as_writedata));
            end if;
            
          when others => null;
        end case;
      end if;

    end if;
  end process p_as_write;

  -- TODO: read process


  p_fsm : process (clk, reset)
  begin
    if reset = '1' then

      current_address      <= 0;
      pix_per_line_copy    <= 0;
      num_lines_copy       <= 0;
      eol_byte_offset_copy <= 0;
      burst_count_copy     <= 0;

      burst_counter <= 1;
      pix_counter   <= 0;
      line_counter  <= 0;

      current_state <= IDLE;
      
    elsif rising_edge(clk) then
      -- If the interrupts have been disabled or acknowledged
      -- we deassert the interrupt request line.
      if not irq_enabled or irq_acknowledged then
        irq <= '0';
      end if;

      case current_state is
        when IDLE =>
          -- In IDLE state, wait for enabled to be high Then, save a copy of registers 
          -- in shadow registers and start reading memory.
          if enabled then
            current_address      <= start_address;
            pix_per_line_copy    <= pix_per_line;
            num_lines_copy       <= num_lines;
            eol_byte_offset_copy <= eol_byte_offset;
            burst_count_copy     <= burst_count;
            current_state        <= MEMSTARTREAD;

            pix_counter  <= 2 * burst_count;  -- so that when pix_counter =
                                              -- pix_per_line_copy we are done
            line_counter <= 1;
          end if;

        -- wait state for the DC fifo signal to be updated
	when MEMRESTARTREAD =>
          current_state <= MEMSTARTREAD;

        when MEMSTARTREAD =>
          -- If there is room for a full burst in the FIFO and
          -- no wait request on the bus, we start reading!
          if fifo_large_enough and am_waitrequest = '0' then
            burst_counter <= 1;
            current_state <= MEMREAD;
          end if;
          
        when MEMREAD =>
          -- If a valid data is received
          if am_readdatavalid = '1' then

            -- If in the middle of a burst, increment the burst counter
            if burst_counter < burst_count_copy then
              burst_counter <= burst_counter + 1;
            else

              -- If in the middle of a line, increment the pixel counter and the
              -- address accordingly
              if pix_counter < pix_per_line_copy then
                pix_counter     <= pix_counter + 2 * burst_count_copy;
                current_address <= current_address + 8 * burst_count_copy;
                current_state   <= MEMRESTARTREAD;

                -- If at the end of a line, increment the line counter and the
                -- address accordingly. Reset pix_counter too!
              elsif line_counter < num_lines_copy then
                line_counter    <= line_counter + 1;
                pix_counter     <= 2 * burst_count_copy;
                current_address <= current_address + 8 * burst_count_copy + eol_byte_offset_copy;
                current_state   <= MEMRESTARTREAD;

                -- If at the end of a frame, go back to WAITSYNC until blanking
              else
                current_state <= WAITSYNC;

                -- End of frame => IRQ!
                if irq_enabled then
                  irq <= '1';
                end if;

              end if;


            end if;
            
          end if;

          if frame_sync = '1' then
            current_state <= FLUSHBURST;
          end if;

        when FLUSHBURST =>
          if burst_counter = burst_count_copy then
            current_state <= IDLE;
            
          elsif am_readdatavalid = '1' then
            burst_counter <= burst_counter + 1;
          end if;

        when WAITSYNC =>
          -- Wait for vertical blanking to occur to avoid filling the FIFO
          -- just before it is cleared!
          if frame_sync = '1' then
            current_state <= IDLE;
          end if;
          
        when others => null;
      end case;
    end if;
  end process p_fsm;

  as_readdata   <= (others => '0');
  am_address    <= std_logic_vector(to_unsigned(current_address, am_address'length));
  am_read       <= '1' when fifo_large_enough and current_state = MEMSTARTREAD else '0';
  am_burstcount <= std_logic_vector(to_unsigned(burst_count_copy, am_burstcount'length));
end architecture;
