library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tw9912_adapter is

    port (
        sysclk : in std_logic;
        reset  : in std_logic;

        -- Avalon-MM Slave to start capture
        avs_address   : in  std_logic_vector(2 downto 0);
        avs_write     : in  std_logic;
        avs_read      : in  std_logic;
        avs_writedata : in  std_logic_vector(31 downto 0);
        avs_readdata  : out std_logic_vector(31 downto 0);

        -- Avalon-ST Source to output data
        asrc_data  : out std_logic_vector(31 downto 0);
        asrc_valid : out std_logic;
        asrc_ready : in  std_logic;

        -- Signal coming from the TW9912
        pal_clk   : in std_logic;
        pal_vsync : in std_logic;
        pal_hsync : in std_logic;
        pal_vd    : in std_logic_vector(7 downto 0);

        debug_capturing : out std_logic);

end tw9912_adapter;

architecture rtl of tw9912_adapter is
    -- for synchronization chains between two clock domains
    -- the following naming convention is used:
    -- `signal_name`X is `signal_name` delayed by X cycles
    -- of the destination clock frequency

    signal start_capture_req  : std_logic;
    signal start_capture_req1 : std_logic;  -- for sync chain
    signal start_capture_req2 : std_logic;  -- for sync chain

    signal start_capture_ack  : std_logic;
    signal start_capture_ack1 : std_logic;  -- for sync chain
    signal start_capture_ack2 : std_logic;  -- for sync chain

    signal capture_done  : std_logic;
    signal capture_done1 : std_logic;
    signal capture_done2 : std_logic;

    signal fifo_clear  : std_logic;
    signal fifo_wrdata : std_logic_vector(7 downto 0);
    signal fifo_wrreq  : std_logic;
    signal fifo_empty  : std_logic;

    -- pix counter
    signal line_width         : integer;
    signal line_width1        : integer;
    signal line_width2        : integer;
    signal line_width_counted : boolean;

    -- line counter
    signal frame_height  : integer;
    signal frame_height1 : integer;
    signal frame_height2 : integer;

    -- error counter
    signal vd_counter : integer range 1 to 1440;

    signal longer_line_error : std_logic;

    -- shift register to store 3 previous VD
    signal vd_1st_byte      : std_logic_vector(pal_vd'range);
    signal vd_2cd_byte      : std_logic_vector(pal_vd'range);
    signal vd_3rd_byte      : std_logic_vector(pal_vd'range);
    signal vd_4th_byte      : std_logic_vector(pal_vd'range);
    signal eav_sav_f        : std_logic;
    signal eav_sav_v        : std_logic;
    signal eav_sav_h        : std_logic;
    signal eav_sav_crc      : std_logic;  -- = '1' when the 4 least significant bits of vd_4th_byte respects the EAV/SAV standard
    signal vd_sr_valid      : std_logic;  -- = '1' when the SHIFT REGISTER contains a valid code
    signal vd_sr_prot_error : std_logic;  -- = '1' when protocol error, i.e. no 0x00 0x00 in the EAV/SAV code
    signal vd_sr_crc_error  : std_logic;  -- = '1' when invalid CRC

    signal i_asrc_data : std_logic_vector(asrc_data'range);

    type state is (IDLE, WAIT_START_OF_BLANKING, WAIT_END_OF_BLANKING, CAPTURE_LINE, WAIT_SAV);
    signal current_state : state;

    constant CONTROL_REGNO      : std_logic_vector(avs_address'range) := std_logic_vector(to_unsigned(0, avs_address'length));
    constant LINE_WIDTH_REGNO   : std_logic_vector(avs_address'range) := std_logic_vector(to_unsigned(1, avs_address'length));  -- num clock per line, TODO find good name
    constant FRAME_HEIGHT_REGNO : std_logic_vector(avs_address'range) := std_logic_vector(to_unsigned(2, avs_address'length));

begin

    dc_pal_fifo_inst : entity work.dc_pal_fifo port map (
        aclr    => fifo_clear,
        data    => fifo_wrdata,
        rdclk   => sysclk,
        rdreq   => asrc_ready,
        wrclk   => pal_clk,
        wrreq   => fifo_wrreq,
        q       => i_asrc_data,
        rdempty => fifo_empty
    );

    -- If the FIFO isn't empty, the output data is valid
    asrc_valid <= not fifo_empty;

    -- Output MSB first
    asrc_data(7 downto 0)   <= i_asrc_data(31 downto 24);
    asrc_data(15 downto 8)  <= i_asrc_data(23 downto 16);
    asrc_data(23 downto 16) <= i_asrc_data(15 downto 8);
    asrc_data(31 downto 24) <= i_asrc_data(7 downto 0);

    -- purpose: Avalon-MM write
    process (reset, sysclk)
    begin
        if reset = '1' then
            start_capture_req <= '0';
        elsif rising_edge(sysclk) then
            if start_capture_ack2 = '1' then
                start_capture_req <= '0';
            end if;

            if avs_write = '1' then
                case avs_address is

                    when CONTROL_REGNO =>
                        start_capture_req <= '1';

                    when others => null;

                end case;
            end if;

        end if;
    end process;

    -- purpose: Avalon-MM read
    process (reset, sysclk)
    begin
        if reset = '1' then
            avs_readdata <= (others => '0');
        elsif rising_edge(sysclk) then
            avs_readdata <= (others => '0');
            if avs_read = '1' then
                case avs_address is

                    when CONTROL_REGNO =>
                        avs_readdata(0) <= capture_done2;

                    when LINE_WIDTH_REGNO =>
                        avs_readdata <= std_logic_vector(to_unsigned(line_width2, avs_readdata'length));

                    when FRAME_HEIGHT_REGNO =>
                        avs_readdata <= std_logic_vector(to_unsigned(frame_height2, avs_readdata'length));

                    when others => null;

                end case;
            end if;
        end if;
    end process;

    -- purpose: sysclk => pal_clk sync chain
    process (reset, pal_clk)
    begin
        if reset = '1' then
            start_capture_req1 <= '0';
            start_capture_req2 <= '0';
        elsif rising_edge(pal_clk) then
            start_capture_req2 <= start_capture_req1;
            start_capture_req1 <= start_capture_req;
        end if;
    end process;

    -- purpose: pal_clk => sysclk sync chain
    process (reset, pal_clk)
    begin
        if reset = '1' then
            start_capture_ack1 <= '0';
            start_capture_ack2 <= '0';
            capture_done1      <= '1';
            capture_done2      <= '1';
            line_width1        <= 0;
            line_width2        <= 0;
            frame_height1      <= 0;
            frame_height2      <= 0;
        elsif rising_edge(pal_clk) then
            start_capture_ack2 <= start_capture_ack1;
            start_capture_ack1 <= start_capture_ack;
            capture_done2      <= capture_done1;
            capture_done1      <= capture_done;
            line_width2        <= line_width1;
            line_width1        <= line_width;
            frame_height2      <= frame_height1;
            frame_height1      <= frame_height;
        end if;
    end process;

    -- purpose: VD shift register to remember 4 values
    vd_4th_byte <= pal_vd;
    process (reset, pal_clk)
    begin
        if reset = '1' then
            vd_1st_byte <= X"00";
            vd_2cd_byte <= X"00";
            vd_3rd_byte <= X"00";
        elsif rising_edge(pal_clk) then
            vd_1st_byte <= vd_2cd_byte;
            vd_2cd_byte <= vd_3rd_byte;
            vd_3rd_byte <= vd_4th_byte;
        end if;
    end process;

    -- purpose: FSM
    process (reset, pal_clk)
    begin

        if reset = '1' then

            current_state      <= IDLE;
            start_capture_ack  <= '0';
            fifo_clear         <= '0';
            fifo_wrreq         <= '0';
            fifo_wrdata        <= (others => '0');
            capture_done       <= '1';
            line_width         <= 1;
            frame_height       <= 1;
            line_width_counted <= false;
            longer_line_error  <= '0';

        elsif rising_edge(pal_clk) then
            start_capture_ack <= '0';
            fifo_clear        <= '0';
            fifo_wrreq        <= '0';
            fifo_wrdata       <= (others => '0');

            case current_state is

                -- When IDLE, the component wait for a capture to be triggered
                when IDLE =>
                    if start_capture_req2 = '1' then
                        capture_done       <= '0';
                        start_capture_ack  <= '1';
                        fifo_clear         <= '1';
                        line_width         <= 0;
                        frame_height       <= 1;
                        vd_counter         <= 1;
                        line_width_counted <= false;
                        longer_line_error  <= '0';
                        current_state      <= WAIT_START_OF_BLANKING;
                    end if;

                -- Synchronize with the vertical blanking
                when WAIT_START_OF_BLANKING =>

                    -- See TW9912 datasheet, page 9
                    if vd_sr_valid = '1' and eav_sav_v = '1' and eav_sav_h = '1' then
                        current_state <= WAIT_END_OF_BLANKING;
                    end if;


                -- Wait for the end of vertical blanking
                when WAIT_END_OF_BLANKING =>

                    -- See TW9912 datasheet, page 9
                    if vd_sr_valid = '1' and eav_sav_v = '0' and eav_sav_h = '0' then
                        current_state <= CAPTURE_LINE;
                    end if;

                when CAPTURE_LINE =>
                    fifo_wrdata <= pal_vd;

                    if vd_1st_byte /= X"FF" and
                    vd_2cd_byte /= X"FF" and
                    vd_3rd_byte /= X"FF" and
                    vd_4th_byte /= X"FF"
                    then
                        fifo_wrreq <= '1';

                        if not line_width_counted then
                            line_width <= line_width + 1;
                        end if;
                    end if;

                    -- See TW9912 datasheet, page 9
                    if vd_sr_valid = '1' and eav_sav_h = '1' then

                        current_state <= WAIT_SAV;

                        if eav_sav_v = '1' then  -- eof
                            current_state <= IDLE;
                            capture_done  <= '1';
                        end if;
                    end if;

                when WAIT_SAV =>
                    line_width_counted <= true;
                    if vd_sr_valid = '1' and eav_sav_h = '0' then
                        frame_height  <= frame_height + 1;
                        current_state <= CAPTURE_LINE;
                    end if;

            end case;
        end if;

    end process;

    debug_capturing <= fifo_wrreq;

    eav_sav_f   <= vd_4th_byte(6);
    eav_sav_v   <= vd_4th_byte(5);
    eav_sav_h   <= vd_4th_byte(4);
    eav_sav_crc <= '1' when (vd_4th_byte(3) = (eav_sav_v xor eav_sav_h)) and
    (vd_4th_byte(2) = (eav_sav_f xor eav_sav_h)) and
    (vd_4th_byte(1) = (eav_sav_f xor eav_sav_v)) and
    (vd_4th_byte(0) = (eav_sav_f xor eav_sav_v xor eav_sav_h))
    else '0';
    vd_sr_valid <= '1' when vd_1st_byte = X"FF" and vd_2cd_byte = X"00" and
    vd_3rd_byte = X"00" and vd_4th_byte(7) = '1' and
    eav_sav_crc = '1'
    else '0';

    vd_sr_prot_error <= '1' when (vd_1st_byte = X"FF" and (vd_3rd_byte /= X"00" or vd_2cd_byte /= X"00")) else '0';
    vd_sr_crc_error  <= '1' when (vd_1st_byte = X"FF" and eav_sav_crc = '0')                              else '0';

end architecture;  -- rtl
