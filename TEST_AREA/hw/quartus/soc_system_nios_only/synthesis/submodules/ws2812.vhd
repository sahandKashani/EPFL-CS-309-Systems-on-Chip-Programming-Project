-- Author: Florian Depraz <florian.depraz@epfl.ch>
-- 32-bit interface
-- ADDR 0: Pulse
-- ADDR 1: LED values RGB

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;



ENTITY ws2812 IS
	GENERIC(
	        NUMBER_LEDS : positive := 1;
	        LUMINOSITY : positive := 2;
	        -- !!! Must be equal to log2(NUMBER_LEDS)
	        ADDR_WIDTH : positive := 1
	);
	PORT(
	  	  -- Avalon interfaces signals
		as_addr  		: IN  std_logic_vector (ADDR_WIDTH - 1 DOWNTO 0);
		as_write		: IN  std_logic;
		as_read			: IN  std_logic;
    	as_wrdata  		: IN  std_logic_vector (31 DOWNTO 0);
		as_rddata	  	: OUT std_logic_vector (31 DOWNTO 0);

    	LED_BGR			: OUT std_logic;

    	clk   			: IN  std_logic;
		nReset  		: IN  std_logic


   );
End ws2812;

ARCHITECTURE RTL OF ws2812 IS
		-- 8 bit for Red, 8 bit for Green, 8 bit for Blue
		constant SIZE_PIXEL : integer := 24;

		-- Number of registers needed depending on the number of LEDs
		type LED_array is array (NUMBER_LEDS DOWNTO 1) of std_logic_vector(SIZE_PIXEL-1 downto 0);
		signal LED_values: LED_array;


		TYPE state_t IS (PARSE_BIT, SEND_BIT, BREAK);
		signal state 			: state_t;

		--LED Selection bit
		signal current_bit 		: integer range 0  to  SIZE_PIXEL - 1 := SIZE_PIXEL - 1;
		-- Need to go to +1 for the range because of the if statement checking the index
		-- Or remove the range check
		signal current_led 		: integer range 1  to  LED_array'length + 1 := 1;

		-- Clock counter 0 to 1300 ns at 50MHz
		signal count			: integer range 0  to  64 := 0;

		-- Period of 1300ns counter
		signal count_period		: integer range 0  to  50  := 0;

		-- Pulse counter
		SIGNAL enable_out		: std_logic := '1';

		-- Do a break of 65000ns if break='1'
		SIGNAL break_signal		: std_logic := '1';

		signal pulse_count		: integer;
		signal bit_low_pulse  	: positive;
		signal bit_high_pulse 	: positive;
		signal break_pulse	  	: positive;
		signal clock_divider  	: positive;

		signal luminosity_value	: integer;
		signal luminosity_current	: integer;

BEGIN

  	-- Process write to registers
	as_write_process: process(clk, nReset)
	variable as_addr_int : integer;
	begin
		if nReset = '0' then
			for i in 1 to LED_array'length loop
				LED_values(i) <= (others => '1');
			end loop;

			bit_low_pulse  <= 21;
			bit_high_pulse <= 36;
			break_pulse	   <= 50;
			clock_divider  	<= 64;

			luminosity_value  <= LUMINOSITY;

		elsif rising_edge(clk) then

			if as_write = '1' then    -- Write cycle
				as_addr_int  := to_integer(unsigned(as_addr));

				case as_addr_int is
				when 0 =>
					luminosity_value  <= to_integer(unsigned(as_wrdata(7 downto 0)));
				when 1 =>
					bit_low_pulse  <= to_integer(unsigned(as_wrdata(7 downto 0)));
					bit_high_pulse <= to_integer(unsigned(as_wrdata(15 downto 8)));
					break_pulse	   <= to_integer(unsigned(as_wrdata(23 downto 16)));
					clock_divider  <= to_integer(unsigned(as_wrdata(31 downto 24)));
				when others =>
					as_addr_int := as_addr_int - 1;
					if(as_addr_int >= 1 and as_addr_int <= LED_array'length) then
						LED_values(as_addr_int) <= as_wrdata(LED_values(as_addr_int)'length - 1 downto 0);
					end if;

				end case;

			end if;
		end if;
	end process as_write_process;


  	-- Process read registers
	as_read_process: process(clk)
	variable as_addr_int : integer;
	begin
	if rising_edge(clk) then
		as_rddata <= (others => '0');  				--   default value
		if as_read = '1' then						--   Read cycle
			as_addr_int  := to_integer(unsigned(as_addr));
			if(as_addr_int >= 1 and as_addr_int <= LED_array'length) then
				as_rddata(LED_values(as_addr_int)'range) <= LED_values(as_addr_int);
			else
				as_rddata(7 downto 0) 	<= std_logic_vector(to_unsigned(bit_low_pulse , 8));
				as_rddata(15 downto 8) 	<= std_logic_vector(to_unsigned(bit_high_pulse, 8));
				as_rddata(23 downto 16) <= std_logic_vector(to_unsigned(break_pulse   , 8));
				as_rddata(31 downto 24) <= std_logic_vector(to_unsigned(clock_divider , 8));
			end if;
		end if;
	end if;
	end process as_read_process;


	fsm: process(clk, nReset)
	begin
		if nReset = '0' then
			state 		<= BREAK;       -- Input by default
			current_bit <= SIZE_PIXEL - 1;
			current_led	<= 1;
			LED_BGR		<= '0';
			break_signal <= '0';
			count_period <= 0;
			pulse_count <= bit_low_pulse;
			luminosity_current <= 0;
		elsif rising_edge(clk) then
			case state is

				when PARSE_BIT =>
					if (current_bit = 0) then
						current_led 	 <= current_led + 1;
						current_bit 	 <= SIZE_PIXEL - 1;

						if (current_led = LED_array'length) then
							break_signal <= '1';
						end if;
					else
						current_bit <= current_bit-1;
					end if;

					state <= SEND_BIT;
					if (LED_values(current_led)(current_bit) = '0' or luminosity_current /= 0) then
						pulse_count <= bit_low_pulse;
					elsif (LED_values(current_led)(current_bit) = '1') then
						pulse_count <= bit_high_pulse;
					end if;

					LED_BGR <= '0';

				when SEND_BIT =>
					if (enable_out = '1') then
						if break_signal = '1' then
							current_bit <= SIZE_PIXEL - 1;
							current_led <= 1;
							state <= BREAK;
						else
							state <= PARSE_BIT;
						end if;
					end if;

					LED_BGR <= '0';
					if (count <= pulse_count AND enable_out='0') then
						LED_BGR <= '1';
					end if;

				when BREAK =>
					if (enable_out = '1') then
							count_period <= count_period + 1;
					end if;

					if (count_period = break_pulse) then
						count_period <= 0;
						break_signal <= '0';
						state <= PARSE_BIT;

						if(luminosity_current = 0) then
							luminosity_current <= luminosity_value;
						else
							luminosity_current <= luminosity_current -1;
						end if;

					end if;

					LED_BGR <= '0';

				when others =>
					null;

				end case;
		end if;
	end process fsm;


	clock_divider_process : process(clk, nReset)
	BEGIN
		IF nReset = '0' then
			count <= 0;
		elsif rising_edge (clk) THEN
			IF count = clock_divider THEN	-- for 1300 ns at 50MHz
				count <= 0;
				enable_out <= '1';
			else
				count <= count + 1;
				enable_out<= '0';
			END IF;
		END IF;
	end process clock_divider_process;

end ARCHITECTURE RTL;
