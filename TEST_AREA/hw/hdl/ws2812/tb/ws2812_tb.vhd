-- Author: Florian Depraz <florian.depraz@epfl.ch>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ws2812_tb is
end ws2812_tb;

architecture RTL of ws2812_tb is

	constant CLK_PERIOD             : time := 50 ns;
        constant CLK_HIGH_PERIOD        : time := 25 ns;
        constant CLK_LOW_PERIOD         : time := 25 ns;

	constant ADDR_SIZE              : integer := 3;
        constant DATA_SIZE              : integer := 32;

	constant REG_INTENSITY_ADDR     : std_logic_vector(ADDR_SIZE-1 downto 0) := "000";
        constant REG_CONFIG_ADDR        : std_logic_vector(ADDR_SIZE-1 downto 0) := "001";
        constant REG_LED_ADDR_1         : std_logic_vector(ADDR_SIZE-1 downto 0) := "010";
        constant REG_LED_ADDR_2         : std_logic_vector(ADDR_SIZE-1 downto 0) := "011";
        constant REG_LED_ADDR_3         : std_logic_vector(ADDR_SIZE-1 downto 0) := "100";
        constant REG_LED_ADDR_4         : std_logic_vector(ADDR_SIZE-1 downto 0) := "101";

        constant REG_LED_VALUE_1        : std_logic_vector(DATA_SIZE-1 downto 0) := X"00ff00ff";
        constant REG_LED_VALUE_2        : std_logic_vector(DATA_SIZE-1 downto 0) := X"ffffffff";


        signal clk                      : std_logic := '0';
        signal reset_n                  : std_logic := '1';

        signal sim_finished             : boolean := false;

        

        signal wrdata_module    : std_logic_vector(DATA_SIZE-1 downto 0) := (others => '0');
        signal write_module     : std_logic                              := '0';
        signal addr_module      : std_logic_vector(ADDR_SIZE-1 downto 0) := (others => '0');
        signal read_module      : std_logic                              := '0';
        signal rddata_module    : std_logic_vector(DATA_SIZE-1 downto 0) := (others => '0');

        signal LED_BGR          : std_logic;

        -- converts a std_logic_vector into a hex string.
        function hstr(slv : std_logic_vector) return string is
                variable hexlen  : integer;
                variable longslv : std_logic_vector(67 downto 0) := (others => '0');
                variable hex     : string(1 to 16);
                variable fourbit : std_logic_vector(3 downto 0);
        begin
                hexlen := (slv'left + 1) / 4;
                if (slv'left + 1) mod 4 /= 0 then
                        hexlen := hexlen + 1;
                end if;
                longslv(slv'left downto 0) := slv;
                for i in (hexlen - 1) downto 0 loop
                        fourbit := longslv(((i * 4) + 3) downto (i * 4));
                        case fourbit is
                                when "0000" => hex(hexlen - I) := '0';
                                when "0001" => hex(hexlen - I) := '1';
                                when "0010" => hex(hexlen - I) := '2';
                                when "0011" => hex(hexlen - I) := '3';
                                when "0100" => hex(hexlen - I) := '4';
                                when "0101" => hex(hexlen - I) := '5';
                                when "0110" => hex(hexlen - I) := '6';
                                when "0111" => hex(hexlen - I) := '7';
                                when "1000" => hex(hexlen - I) := '8';
                                when "1001" => hex(hexlen - I) := '9';
                                when "1010" => hex(hexlen - I) := 'A';
                                when "1011" => hex(hexlen - I) := 'B';
                                when "1100" => hex(hexlen - I) := 'C';
                                when "1101" => hex(hexlen - I) := 'D';
                                when "1110" => hex(hexlen - I) := 'E';
                                when "1111" => hex(hexlen - I) := 'F';
                                when "ZZZZ" => hex(hexlen - I) := 'z';
                                when "UUUU" => hex(hexlen - I) := 'u';
                                when "XXXX" => hex(hexlen - I) := 'x';
                                when others => hex(hexlen - I) := '?';
                        end case;
                end loop;
                return hex(1 to hexlen);
        end hstr;

        procedure write_avalon( constant addr            : in  std_logic_vector(ADDR_SIZE-1 downto 0);
                                constant value           : in  std_logic_vector(DATA_SIZE-1 downto 0);
                                signal addr_controller   : out std_logic_vector(ADDR_SIZE-1 downto 0);
                                signal read_controller   : out std_logic;
                                signal write_controller  : out std_logic;
                                signal wrdata_controller : out std_logic_vector(DATA_SIZE-1 downto 0)) is
        begin
                addr_controller   <= addr;
                read_controller   <= '0';
                write_controller  <= '1';
                wrdata_controller <= value;

                wait until rising_edge(clk);
                wait for 1 * CLK_PERIOD;

                write_controller <= '0';

        end procedure write_avalon;


        procedure read_avalon(  constant addr           : in  std_logic_vector(ADDR_SIZE-1 downto 0);
                                signal addr_controller  : out std_logic_vector(ADDR_SIZE-1 downto 0);
                                signal read_controller  : out std_logic;
                                signal write_controller : out std_logic) is
        begin
                addr_controller  <= addr;
                read_controller  <= '1';
                write_controller <= '0';

                wait until rising_edge(clk);
                wait for 1 * CLK_PERIOD;

        end procedure read_avalon;



        component ws2812 IS
                GENERIC(
                        NUMBER_LEDS : positive := 4;
			LUMINOSITY : positive := 2;
                        -- !!! Must be equal to log2(NUMBER_LEDS)
                        ADDR_WIDTH : positive := ADDR_SIZE
                );
                PORT(
                        as_addr                 : IN  std_logic_vector (ADDR_WIDTH - 1 DOWNTO 0);
                        as_write                : IN  std_logic;
                        as_read                 : IN  std_logic;
                        as_wrdata               : IN  std_logic_vector (31 DOWNTO 0);
                        as_rddata               : OUT std_logic_vector (31 DOWNTO 0);
                        LED_BGR                 : OUT std_logic;

                        clk                     : IN  std_logic;
                        nReset                  : IN  std_logic
           );
        end component ws2812;



begin

        ws2812_led: ws2812 port map(
                -- Avalon interfaces signals
                as_addr                 => addr_module,
                as_write                => write_module,
                as_read                 => read_module,
                as_wrdata               => wrdata_module,
                as_rddata               => rddata_module,
                LED_BGR                 => LED_BGR,

                clk                     => clk,
                nReset                  => reset_n

        );




        clk_generation: process
        begin
                if not sim_finished then
                        clk <= '1';
                        wait for CLK_HIGH_PERIOD;
                        clk <= '0';
                        wait for CLK_LOW_PERIOD;
                else
                        wait;
                end if;
        end process;

        sim: process
        begin

                -- ---------------------------------------------------------------------
                -- reset_n  system --------------------------------------------------------
                -- ---------------------------------------------------------------------
                report "reset_n ";
                reset_n  <= '0';
                wait until rising_edge(clk);
                wait for 0.1 * CLK_PERIOD;
                reset_n  <= '1';
                wait until rising_edge(clk);
                report "reset_n  is done";

                -- ---------------------------------------------------------------------
                -- Write        --------------------------------------------------------
                -- ---------------------------------------------------------------------
                report "Writing into registers";
                report "Init LED1 " & hstr(REG_LED_ADDR_1) & " to 0x" & hstr(REG_LED_VALUE_1);
                write_avalon(REG_LED_ADDR_1, REG_LED_VALUE_1, addr_module, read_module, write_module, wrdata_module);
		report "Init LED4 " & hstr(REG_LED_ADDR_4) & " to 0x" & hstr(REG_LED_VALUE_1);
                write_avalon(REG_LED_ADDR_4, REG_LED_VALUE_1, addr_module, read_module, write_module, wrdata_module);

                wait until rising_edge(clk);

                wait for 10 ms;

                report "Init LED1 " & hstr(REG_LED_ADDR_1) & " to 0x" & hstr(REG_LED_VALUE_2);
                write_avalon(REG_LED_ADDR_1, REG_LED_VALUE_2, addr_module, read_module, write_module, wrdata_module);
                report "Init LED4 " & hstr(REG_LED_ADDR_4) & " to 0x" & hstr(REG_LED_VALUE_2);
                write_avalon(REG_LED_ADDR_4, REG_LED_VALUE_2, addr_module, read_module, write_module, wrdata_module);
                wait for 10 ms;

                sim_finished <= true;
                wait;
        end process;

end architecture RTL;
