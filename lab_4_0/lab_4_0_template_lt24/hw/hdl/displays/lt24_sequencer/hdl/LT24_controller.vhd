-------------------------------------------------------------------------------
-- Title      : LT24 streaming interface
-------------------------------------------------------------------------------
-- File       : LT24_controller.vhd
-- Author     : Sahand Kashani  <sahand.kashani@epfl.ch>
-- Created    : 2021-05-18
-- Last update: 2021-05-20
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: An Avalon-ST interface for the LT24 LCD display.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2016-03-10  1.0      S. Kashani      Created
-------------------------------------------------------------------------------
-- Register Memory Mapping
-- +-------+--------+-----+-----+-----+-----+----+-----------+
-- | Regno | Access | B31 | ... | B10 | ... | B1 | B0        |
-- +-------+--------+-----+-----+-----+-----+----+-----------+
-- | 0     | R/W    |                WRITE_CMD               |
-- +-------+--------+----------------------------------------+
-- | 1     | R/W    |               WRITE_DATA               |
-- +-------+--------+----------------------------------------+
-- | 2     | R/W    |                 LCD_ON                 |
-- +-------+--------+----------------------------------------+
-- | 3     | R/W    |           DATA_SRC_SELECT              |
-- +-------+--------+----------------------------------------+

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LT24_controller is
  port(
    clk    : in std_logic;
    nReset : in std_logic;

    -- Avalon Slave
    AS_address   : in  std_logic_vector(1 downto 0);
    AS_write     : in  std_logic;
    AS_writedata : in  std_logic_vector(31 downto 0);
    AS_read      : in  std_logic;
    AS_readdata  : out std_logic_vector(31 downto 0);

    -- Streaming input.
    pix_valid : in  std_logic;
    pix_data  : in  std_logic_vector(23 downto 0);
    pix_ready : out std_logic;

    -- Frame sync (to framebuffer manager).
    frame_sync : out std_logic;

    -- Lcd Output
    LCD_ON  : out std_logic;
    CS_N    : out std_logic;
    RESET_N : out std_logic;
    DATA    : out std_logic_vector(15 downto 0);
    RD_N    : out std_logic;
    WR_N    : out std_logic;
    -- low: Command, high: Data
    D_C_N   : out std_logic
  );
end LT24_controller;

architecture comp of LT24_controller is

  constant C_REG_WRITE_CMD_OFST   : std_logic_vector(AS_address'range) := "00";
  constant C_REG_WRITE_DATA_OFST  : std_logic_vector(AS_address'range) := "01";
  constant C_REG_LCD_ON_OFST      : std_logic_vector(AS_address'range) := "10";
  constant C_DATA_SRC_SELECT_OFST : std_logic_vector(AS_address'range) := "11";

  -- Slave registers
  signal reg_lcd_command        : std_logic_vector(7 downto 0);
  signal reg_lcd_data           : std_logic_vector(15 downto 0);
  signal reg_lcd_on             : std_logic;
  signal reg_en_pixel_data_mode : std_logic;

  -- Commands sent by the slave to the LCD FSM.
  signal reg_start_lcd_write_command : std_logic;
  signal reg_start_lcd_write_data    : std_logic;

  -- Internal counter used to sequence communication with LCD. 4 clock cycles at 50 MHz are needed
  -- to perform a transfer with the LCD.
  signal reg_lcd_wait_cnt : natural range 0 to 3;

  signal reg_frame_sync : std_logic;

  -- States of FSM
  type state_type is (STATE_IDLE, STATE_SEND_COMMAND_FROM_SLAVE, STATE_SEND_DATA_FROM_SLAVE, STATE_SEND_MEMORY_WRITE_COMMAND, STATE_WAIT_FIFO, STATE_WRITE_PIXEL);
  signal reg_state : state_type;

  -- Color signals decomosed from 24-bit input R8/G8/B8 signal.
  signal PIX_R : std_logic_vector(7 downto 0);
  signal PIX_G : std_logic_vector(7 downto 0);
  signal PIX_B : std_logic_vector(7 downto 0);

  -- Colors signals decomposed for LT24's 16-bit R5/G6/B5 color format.
  signal PIX_R_LT24 : std_logic_vector(4 downto 0);
  signal PIX_G_LT24 : std_logic_vector(5 downto 0);
  signal PIX_B_LT24 : std_logic_vector(4 downto 0);

  -- FIFO signals
  signal FIFO_aclr_in   : std_logic;
  signal FIFO_clock_in  : std_logic;
  signal FIFO_data_in   : std_logic_vector (15 downto 0);
  signal FIFO_rdreq_in  : std_logic;
  signal FIFO_wrreq_in  : std_logic;
  signal FIFO_empty_out : std_logic;
  signal FIFO_full_out  : std_logic;
  signal FIFO_q_out     : std_logic_vector (15 downto 0);

  -- Enough to count until 131072, which is more than the 320*240 = 76800 pixels we need to count
  -- until.
  constant C_NUM_PIXELS_IN_FRAME : positive := 320 * 240;
  signal reg_pix_cnt             : natural range 0 to C_NUM_PIXELS_IN_FRAME;

begin

  -- Original R8/G8/B8 colors from framebuffer_manager.
  PIX_R <= pix_data(23 downto 16);
  PIX_G <= pix_data(15 downto 8);
  PIX_B <= pix_data(7 downto 0);

  -- High-order bits of the corresponding pixels to get R5/G6/B5.
  PIX_R_LT24 <= PIX_R(7 downto 3);
  PIX_G_LT24 <= PIX_G(7 downto 2);
  PIX_B_LT24 <= PIX_B(7 downto 3);

  FIFO_inst : entity work.FIFO port map (
    aclr  => FIFO_aclr_in,
    clock => FIFO_clock_in,
    data  => FIFO_data_in,
    rdreq => FIFO_rdreq_in,
    wrreq => FIFO_wrreq_in,
    empty => FIFO_empty_out,
    full  => FIFO_full_out,
    q     => FIFO_q_out
  );
  -- FIFO input connections (FIFO_rdreq_in is driven by LCD FSM below).
  FIFO_aclr_in  <= not nReset;
  FIFO_clock_in <= clk;
  FIFO_data_in  <= PIX_R_LT24 & PIX_G_LT24 & PIX_B_LT24;
  FIFO_wrreq_in <= pix_valid;

  -- Avalon Slave write to registers
  process(clk, nReset)
  begin
    if nReset = '0' then
      reg_lcd_command             <= (others => '0');
      reg_lcd_data                <= (others => '0');
      reg_lcd_on                  <= '0';
      reg_en_pixel_data_mode      <= '0';
      reg_start_lcd_write_command <= '0';
      reg_start_lcd_write_data    <= '0';

    elsif rising_edge(clk) then
      -- Default value as these should be PULSES.
      reg_start_lcd_write_command <= '0';
      reg_start_lcd_write_data    <= '0';

      if AS_write = '1' then
        case AS_address is
          when C_REG_WRITE_CMD_OFST =>
            reg_lcd_command             <= AS_writedata(7 downto 0);
            reg_start_lcd_write_command <= '1';
          when C_REG_WRITE_DATA_OFST =>
            reg_lcd_data             <= AS_writedata(15 downto 0);
            reg_start_lcd_write_data <= '1';
          when C_REG_LCD_ON_OFST =>
            reg_lcd_on <= AS_writedata(0);
          when C_DATA_SRC_SELECT_OFST =>
            reg_en_pixel_data_mode <= AS_writedata(0);
          when others =>
            null;
        end case;
      end if;
    end if;
  end process;

  -- Avalon Slave read from registers
  process(clk, nReset)
  begin
    if nReset = '0' then
      AS_readdata <= (others => '0');

    elsif rising_edge(clk) then
      -- Default value.
      AS_readdata <= (others => '0');

      if AS_read = '1' then
        case AS_address is
          when C_REG_WRITE_CMD_OFST =>
            AS_readdata(reg_lcd_command'range) <= reg_lcd_command;
          when C_REG_WRITE_DATA_OFST =>
            AS_readdata(reg_lcd_data'range) <= reg_lcd_data;
          when C_REG_LCD_ON_OFST =>
            AS_readdata(0) <= reg_lcd_on;
          when C_DATA_SRC_SELECT_OFST =>
            AS_readdata(0) <= reg_en_pixel_data_mode;
          when others =>
            null;
        end case;
      end if;
    end if;
  end process;

  -- LCD controller FSM
  process(clk, nReset)
  begin
    if nReset = '0' then
      RESET_N <= '0';
      CS_N    <= '1';
      D_C_N   <= '1';
      -- Reset routine.
      WR_N    <= '1';
      RD_N    <= '1';
      DATA    <= (others => 'Z');

      reg_state        <= STATE_IDLE;
      reg_lcd_wait_cnt <= 0;
      reg_pix_cnt      <= 0;
      reg_frame_sync   <= '0';

    elsif rising_edge(clk) then
      case reg_state is
        when STATE_IDLE =>
          RESET_N <= '1';
          CS_N    <= '1';
          -- STATE_IDLE default state.
          D_C_N   <= '1';
          WR_N    <= '1';
          RD_N    <= '1';
          DATA    <= (others => 'Z');

          reg_lcd_wait_cnt <= 0;
          reg_pix_cnt      <= 0;
          reg_frame_sync   <= '0';

          if reg_en_pixel_data_mode = '0' then
            if reg_start_lcd_write_command = '1' then
              -- If a command has been sent to the AS by the processor.
              reg_state <= STATE_SEND_COMMAND_FROM_SLAVE;
            elsif reg_start_lcd_write_data = '1' then
              -- If a data has been sent to the AS by the processor.
              reg_state <= STATE_SEND_DATA_FROM_SLAVE;
            end if;

          else
            -- If there is no command/data and there are pixels to display in the FIFO.
            reg_state <= STATE_SEND_MEMORY_WRITE_COMMAND;
          end if;

        when STATE_SEND_COMMAND_FROM_SLAVE =>
          reg_lcd_wait_cnt <= reg_lcd_wait_cnt + 1;

          case reg_lcd_wait_cnt is
            when 0 =>
              CS_N              <= '0';
              WR_N              <= '0';
              D_C_N             <= '0';
              -- Set the data port with the command.
              DATA(15 downto 8) <= (others => '0');
              DATA(7 downto 0)  <= reg_lcd_command;
            when 1 =>
              -- Write command to LCD.
              WR_N <= '1';
            when 2 =>
              D_C_N <= '1';
              -- Negate the command on the data port.
              DATA  <= (others => 'Z');
            when others =>
              reg_state <= STATE_IDLE;
          end case;

        when STATE_SEND_DATA_FROM_SLAVE =>
          reg_lcd_wait_cnt <= reg_lcd_wait_cnt + 1;

          case reg_lcd_wait_cnt is
            when 0 =>
              CS_N  <= '0';
              WR_N  <= '0';
              D_C_N <= '1';
              DATA  <= reg_lcd_data;
            when 1 =>
              -- Write parameter to LCD.
              WR_N <= '1';
            when 2 =>
              -- Negate the data port.
              DATA <= (others => 'Z');
            when others =>
              reg_state <= STATE_IDLE;
          end case;

        when STATE_SEND_MEMORY_WRITE_COMMAND =>
          reg_lcd_wait_cnt <= reg_lcd_wait_cnt + 1;

          -- Send command 0x2c to instruct LT24 that new pixel data is arriving.
          case reg_lcd_wait_cnt is
            when 0 =>
              CS_N              <= '0';
              WR_N              <= '0';
              D_C_N             <= '0';
              -- Set the data port with the command.
              DATA(15 downto 8) <= (others => '0');
              DATA(7 downto 0)  <= X"2c";
            when 1 =>
              -- Write command to LCD.
              WR_N <= '1';
            when 2 =>
              D_C_N <= '1';
              -- Negate the command on the data port.
              DATA  <= (others => 'Z');
            when others =>
              reg_state        <= STATE_WAIT_FIFO;
              -- Reset lcd waiting counter for the next state.
              reg_lcd_wait_cnt <= 0;
          end case;

        when STATE_WAIT_FIFO =>
          if FIFO_empty_out = '0' then
            reg_state <= STATE_WRITE_PIXEL;
          end if;

        when STATE_WRITE_PIXEL =>
          reg_lcd_wait_cnt <= reg_lcd_wait_cnt + 1;

          -- Send pixel data.
          case reg_lcd_wait_cnt is
            when 0 =>
              -- Request read from the FIFO.
              FIFO_rdreq_in <= '1';
            when 1 =>
              CS_N          <= '0';
              WR_N          <= '0';
              D_C_N         <= '1';
              -- Read from FIFO.
              DATA          <= FIFO_q_out;
              FIFO_rdreq_in <= '0';
            when 2 =>
              -- Write to LCD.
              WR_N <= '1';
            when 3 =>
              DATA             <= (others => 'Z');
              -- Reset lcd waiting counter for the next pixel.
              reg_lcd_wait_cnt <= 0;
              -- Increment pixel counter.
              reg_pix_cnt      <= reg_pix_cnt + 1;

              if reg_pix_cnt = C_NUM_PIXELS_IN_FRAME - 1 then
                -- Generate frame_sync signal for synchronization with the framebuffer_manager.
                reg_frame_sync <= '1';
                reg_state      <= STATE_IDLE;

              elsif FIFO_empty_out = '1' then
                -- Must wait until the FIFO has at least one element inside as otherwise
                -- we will be popping an empty FIFO (unlikely due to the design of the
                -- framebuffer_manager, but this condition makes it more reliable).
                reg_state <= STATE_WAIT_FIFO;
              end if;
          end case;

        when others =>
          reg_state <= STATE_IDLE;

      end case;
    end if;
  end process;

  -- Top-level connections.
  pix_ready  <= not FIFO_full_out;
  LCD_ON     <= reg_lcd_on;
  frame_sync <= reg_frame_sync;

end comp;
