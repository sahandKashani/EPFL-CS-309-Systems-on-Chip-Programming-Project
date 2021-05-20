-- #############################################################################
-- mcp3204.vhd
-- ===========
-- MCP3204 Avalon-MM slave interface.
--
-- Register map
-- +-------+-----------+--------+------------------------------------+
-- | RegNo | Name      | Access | Description                        |
-- +-------+-----------+--------+------------------------------------+
-- | 0     | CHANNEL_0 | RO     | 12-bit digital value of channel 0. |
-- +-------+-----------+--------+------------------------------------+
-- | 1     | CHANNEL_1 | RO     | 12-bit digital value of channel 1. |
-- +-------+-----------+--------+------------------------------------+
-- | 2     | CHANNEL_2 | RO     | 12-bit digital value of channel 2. |
-- +-------+-----------+--------+------------------------------------+
-- | 3     | CHANNEL_3 | RO     | 12-bit digital value of channel 3. |
-- +-------+-----------+--------+------------------------------------+
--
-- Author        : Philémon Favrod [philemon.favrod@epfl.ch]
-- Author        : Sahand Kashani-Akhavan [sahand.kashani-akhavan@epfl.ch]
-- Revision      : 2
-- Last modified : 2018-03-06
-- #############################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity mcp3204 is
    port(
        -- Avalon Clock interface
        clk : in std_logic;

        -- Avalon Reset interface
        reset : in std_logic;

        -- Avalon-MM Slave interface
        address  : in  std_logic_vector(1 downto 0);
        read     : in  std_logic;
        readdata : out std_logic_vector(31 downto 0);

        -- Avalon Conduit interface
        CS_N : out std_logic;
        MOSI : out std_logic;
        MISO : in  std_logic;
        SCLK : out std_logic
    );
end entity;

architecture arch of mcp3204 is
    constant NUM_CHANNELS  : positive := 4;
    constant CHANNEL_WIDTH : positive := integer(ceil(log2(real(NUM_CHANNELS))));

    type data_array is array (NUM_CHANNELS - 1 downto 0) of std_logic_vector(readdata'range);
    signal data_reg : data_array;

    signal spi_busy, spi_start, spi_datavalid : std_logic;
    signal spi_channel                        : std_logic_vector(1 downto 0);
    signal spi_data                           : std_logic_vector(11 downto 0);

    type state_t is (READY, INIT_READ_CHANNEL, WAIT_FOR_DATA);
    signal state : state_t;

    signal channel : unsigned(CHANNEL_WIDTH - 1 downto 0);

begin
    SPI : entity work.mcp3204_spi
    port map(
        clk        => clk,
        reset      => reset,
        busy       => spi_busy,
        start      => spi_start,
        channel    => spi_channel,
        data_valid => spi_datavalid,
        data       => spi_data,
        SCLK       => SCLK,
        CS_N       => CS_N,
        MOSI       => MOSI,
        MISO       => MISO
    );

    -- FSM that dictates which channel is being read. The state of the component
    -- should be thought as the pair (state, channel)
    p_fsm : process(reset, clk)
    begin
        if reset = '1' then
            state   <= READY;
            channel <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when READY =>
                    if spi_busy = '0' then
                        state <= INIT_READ_CHANNEL;
                    end if;

                when INIT_READ_CHANNEL =>
                    state <= WAIT_FOR_DATA;

                when WAIT_FOR_DATA =>
                    if spi_datavalid = '1' then
                        state   <= READY;
                        channel <= channel + 1;
                    end if;
            end case;
        end if;
    end process p_fsm;

    -- Updates the internal registers when a new data is available
    p_data : process(reset, clk)
    begin
        if reset = '1' then
            for i in 0 to NUM_CHANNELS - 1 loop
                data_reg(i) <= (others => '0');
            end loop;
        elsif rising_edge(clk) then
            if state = WAIT_FOR_DATA and spi_datavalid = '1' then
                data_reg(to_integer(channel)) <= (31 downto 12 => '0') & spi_data;
            end if;
        end if;
    end process p_data;

    spi_start   <= '1' when state = INIT_READ_CHANNEL else '0';
    spi_channel <= std_logic_vector(channel);

    -- Interface with the Avalon Switch Fabric
    p_avalon_read : process(reset, clk)
    begin
        if reset = '1' then
            readdata <= (others => '0');
        elsif rising_edge(clk) then
            if read = '1' then
                readdata <= data_reg(to_integer(unsigned(address)));
            end if;
        end if;
    end process p_avalon_read;

end architecture;
