-- MCP3204 Avalon Memory-Mapped Interface
-- Author: Philémon Favrod & Sahand Kashani
-- Revision: 1
--
-- The interface is quite simple. It is made of 4 read-only registers.
-- The register at offset i is continuously updated with the value of
-- the i-th channel.
--


library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;

entity mcp3204_mm_slave is
  port (
	-- Inputs
	clk: in std_logic;
	reset: in std_logic;
	address: in std_logic_vector(1 downto 0);
	read: in std_logic;

	-- Outputs
	readdata: out std_logic_vector(31 downto 0);

	CS_N    : out std_logic;
    MOSI    : out std_logic;
    MISO    : in  std_logic;
    SCLK	: out std_logic
  ) ;
end entity ; -- mcp3204_mm_slave

architecture arch of mcp3204_mm_slave is

	type data_array is array (3 downto 0) of std_logic_vector(31 downto 0);
	signal data_reg: data_array;

	component mcp3204_spi is
    port(
        -- 50 MHz
        clk        : in  std_logic;
        reset      : in  std_logic;
        busy       : out std_logic;
        start      : in  std_logic;
        channel    : in  std_logic_vector(1 downto 0);
        data_valid : out std_logic;
        data       : out std_logic_vector(11 downto 0);

        -- 1 MHz
        SCLK       : out std_logic;
        CS_N       : out std_logic;
        MOSI       : out std_logic;
        MISO       : in  std_logic
    );
	end component mcp3204_spi;

	signal spi_busy, spi_start, spi_datavalid : std_logic;
	signal spi_channel : std_logic_vector(1 downto 0);
	signal spi_data : std_logic_vector(11 downto 0);

	type state_t is (READY, INIT_READ_CHANNEL, WAIT_FOR_DATA);
	signal state : state_t;

	signal channel: unsigned(1 downto 0);
begin

	SPI: mcp3204_spi port map (
			clk => clk,
			reset => reset,
			busy => spi_busy,
			start => spi_start,
			channel => spi_channel,
			data_valid => spi_datavalid,
			data => spi_data,

			SCLK => SCLK,
			CS_N => CS_N,
			MOSI => MOSI,
			MISO => MISO
		);

	-- FSM that dictates which channel is being read.
	-- The state of the component should be thought as the pair (state, channel)
	p_fsm:  process (reset, clk)
	begin

		if reset = '1' then
			state <= READY;
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
					state <= READY;
					channel <= channel + 1;
				end if;

			end case;
		end if;

	end process p_fsm;

	-- Updates the internal registers when a new data is available
	p_data : process (reset, clk)
	begin

		if reset = '1' then
			for i in 0 to 3 loop
				data_reg(i) <= (others => '0');
			end loop ;
		elsif rising_edge(clk) then
			if state = WAIT_FOR_DATA and spi_datavalid = '1' then
				data_reg(to_integer(channel)) <= (31 downto 12 => '0') & spi_data;
			end if;
		end if ;
	end process p_data;

	spi_start <=  '1' when state = INIT_READ_CHANNEL else '0';
	spi_channel <= std_logic_vector(channel);

	-- Interface with the Avalon Switch Fabric
	p_avalon_read : process (clk)
	begin

		if rising_edge(clk) then
			if read = '1' then
				readdata <= data_reg(to_integer(unsigned(address)));
			end if ;
		end if;

	end process p_avalon_read;

end architecture;