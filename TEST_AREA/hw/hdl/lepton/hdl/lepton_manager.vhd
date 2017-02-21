library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lepton_manager is
    generic(
        INPUT_CLK_FREQ : integer := 50000000);
    port(
        clk   : in std_logic := '0';
        reset : in std_logic := '0';

        -- Avalon ST Sink to receive SPI data
        spi_miso_sink_data  : in std_logic_vector(7 downto 0);
        spi_miso_sink_valid : in std_logic;

        -- Avalon ST Source to send SPI data
        spi_mosi_src_data  : out std_logic_vector(7 downto 0);
        spi_mosi_src_valid : out std_logic;
        spi_mosi_src_ready : in  std_logic := '0';

        -- Filtered output to retransmit cleaned data (without the discard packets, see Lepton Datasheet on page 31)
        -- lepton_out_data is valid on rising edge when lepton_src_valid = '1'
        lepton_out_data  : out std_logic_vector(7 downto 0);
        lepton_out_valid : out std_logic;
        lepton_out_sof   : out std_logic;
        lepton_out_eof   : out std_logic;

        -- Some status
        row_idx : out std_logic_vector(5 downto 0);
        error   : out std_logic;

        -- Avalon MM Slave interface for configuration
        start : in std_logic;

        -- The SPI Chip Select (Active low !)
        spi_cs_n : out std_logic := '0');
end entity lepton_manager;

architecture rtl of lepton_manager is
    type state_t is (Idle, CSn, ReadHeader, ReadPayload, DiscardPayload, WaitBeforeIdle);
    signal state, next_state : state_t;

    signal header_3_last_nibbles : std_logic_vector(11 downto 0);

    constant CLOCK_TICKS_PER_37_MS  : integer := 37 * (INPUT_CLK_FREQ / 1e3);  -- the timeout delay for a frame
    constant CLOCK_TICKS_PER_200_MS : integer := 200 * (INPUT_CLK_FREQ / 1e3);
    constant CLOCK_TICKS_PER_200_NS : integer := (200 * (INPUT_CLK_FREQ / 1e6)) / 1e3;
    constant BYTES_PER_HEADER       : integer := 4;
    constant BYTES_PER_PAYLOAD      : integer := 160;

    constant NUMBER_OF_LINES_PER_FRAME : positive := 60;
    signal counter, counter_max        : integer range 1 to CLOCK_TICKS_PER_200_MS;
    signal line_counter                : integer range 1 to NUMBER_OF_LINES_PER_FRAME;
    signal timeout_counter             : integer range 1 to CLOCK_TICKS_PER_37_MS;
    signal counter_enabled             : boolean;
    signal waited_long_enough          : boolean;
    signal header_end, payload_end     : boolean;
begin

    -- purpose: register for state
    p_fsm : process(clk, reset)
    begin
        if reset = '1' then
            state <= Idle;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process p_fsm;

    -- purpose: compute the next state
    p_nsl : process(header_3_last_nibbles, header_end, payload_end, start, spi_miso_sink_valid, state, waited_long_enough, line_counter)
    begin
        next_state <= state;

        case state is
            when Idle =>
                if waited_long_enough and start = '1' then
                    next_state <= CSn;
                end if;

            when CSn =>
                if waited_long_enough then
                    next_state <= ReadHeader;
                end if;

            when ReadHeader =>
                if header_end then
                    if header_3_last_nibbles(11 downto 8) = X"F" then
                        next_state <= DiscardPayload;
                    else
                        next_state <= ReadPayload;
                    end if;
                end if;

            when DiscardPayload | ReadPayload =>
                if payload_end then
                    next_state <= ReadHeader;

                    if line_counter = NUMBER_OF_LINES_PER_FRAME then
                        next_state <= WaitBeforeIdle;
                    end if;
                end if;

            when WaitBeforeIdle =>
                if spi_miso_sink_valid = '1' then
                    next_state <= Idle;
                end if;

        end case;
    end process p_nsl;

    p_counter : process(clk, reset)
    begin
        if reset = '1' then
            counter      <= 1;
            line_counter <= 1;
        elsif rising_edge(clk) then
            if counter = counter_max and counter_enabled then
                counter <= 1;

                if state = ReadPayload then
                    if line_counter = NUMBER_OF_LINES_PER_FRAME then
                        line_counter <= 1;
                    else
                        line_counter <= line_counter + 1;
                    end if;
                end if;

            elsif counter_enabled then
                counter <= counter + 1;
            end if;
        end if;
    end process p_counter;

    p_error : process(clk, reset)
    begin
        if reset = '1' then
            error           <= '0';
            timeout_counter <= 1;
        elsif rising_edge(clk) then
            if state /= ReadHeader and state /= ReadPayload and state /= ReadHeader then
                timeout_counter <= 1;
                error           <= '0';
            else
                if timeout_counter = CLOCK_TICKS_PER_37_MS then
                    error <= '1';
                else
                    timeout_counter <= timeout_counter + 1;
                end if;
            end if;
            if state = ReadPayload and header_3_last_nibbles /= std_logic_vector(to_unsigned(line_counter - 1, header_3_last_nibbles'length)) then
                error <= '1';
            end if;
        end if;
    end process p_error;

    -- purpose: wire the datapath
    p_datapath : process(counter, counter_enabled, counter_max, line_counter, spi_miso_sink_data, spi_miso_sink_valid, spi_mosi_src_ready, state)
        variable counter_ended : boolean;

    begin
        counter_max        <= 1;
        counter_enabled    <= true;
        waited_long_enough <= false;
        lepton_out_data    <= (others => '0');
        lepton_out_valid   <= '0';
        lepton_out_sof     <= '0';
        lepton_out_eof     <= '0';
        spi_mosi_src_valid <= '0';
        spi_mosi_src_data  <= (others => '0');
        spi_cs_n           <= '0';
        header_end         <= false;
        payload_end        <= false;

        counter_ended := (counter = counter_max and counter_enabled);

        case state is
            when Idle =>
                counter_max        <= CLOCK_TICKS_PER_200_MS;
                waited_long_enough <= counter_ended;
                spi_cs_n           <= '1';

            when CSn =>
                counter_max        <= CLOCK_TICKS_PER_200_NS;
                waited_long_enough <= counter_ended;

            when ReadHeader =>
                counter_max        <= BYTES_PER_HEADER;
                counter_enabled    <= spi_miso_sink_valid = '1';
                header_end         <= counter_ended;
                spi_mosi_src_valid <= spi_mosi_src_ready;

            when ReadPayload =>
                counter_max        <= BYTES_PER_PAYLOAD;
                counter_enabled    <= spi_miso_sink_valid = '1';
                lepton_out_data    <= spi_miso_sink_data;
                lepton_out_valid   <= spi_miso_sink_valid;
                payload_end        <= counter_ended;
                spi_mosi_src_valid <= spi_mosi_src_ready;
                if spi_miso_sink_valid = '1' then
                    if counter = 1 and counter_enabled and line_counter = 1 then
                        lepton_out_sof <= '1';
                    elsif counter_ended and line_counter = NUMBER_OF_LINES_PER_FRAME then
                        lepton_out_eof <= '1';
                    end if;
                end if;

            when DiscardPayload =>
                counter_max        <= BYTES_PER_PAYLOAD;
                counter_enabled    <= spi_miso_sink_valid = '1';
                payload_end        <= counter_ended;
                spi_mosi_src_valid <= spi_mosi_src_ready;

            when others => null;
        end case;
    end process p_datapath;

    p_capture_header : process(clk, reset)
    begin
        if reset = '1' then
            header_3_last_nibbles <= X"000";
        elsif rising_edge(clk) then
            if state = ReadHeader and spi_miso_sink_valid = '1' then
                if counter = 1 then
                    header_3_last_nibbles(11 downto 8) <= spi_miso_sink_data(3 downto 0);
                elsif counter = 2 then
                    header_3_last_nibbles(7 downto 0) <= spi_miso_sink_data;
                end if;
            end if;
        end if;
    end process p_capture_header;

    row_idx <= std_logic_vector(to_unsigned(line_counter, row_idx'length));

end architecture rtl;
