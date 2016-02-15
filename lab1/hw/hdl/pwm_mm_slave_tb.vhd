library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pwm_mm_slave_tb is
end entity;

architecture rtl of pwm_mm_slave_tb is
    component pwm_mm_slave
        port(clk         : in  std_logic;
             reset       : in  std_logic;
             address     : in  std_logic_vector(1 downto 0);
             writedata   : in  std_logic_vector(31 downto 0);
             read, write : in  std_logic;
             readdata    : out std_logic_vector(31 downto 0);
             pwm_out     : out std_logic);
    end component pwm_mm_slave;

    signal clk         : std_logic                     := '0';
    signal reset       : std_logic                     := '1';
    signal address     : std_logic_vector(1 downto 0)  := "00";
    signal writedata   : std_logic_vector(31 downto 0) := (others => '0');
    signal read, write : std_logic                     := '0';
    signal readdata    : std_logic_vector(31 downto 0);
    signal pwm_out     : std_logic;

    constant CLK_PERIOD : time    := 20 ns;
    signal running      : boolean := true;

    procedure WriteRegister(addr_in          : in  std_logic_vector(address'range);
                            data_in          : in  std_logic_vector(writedata'range);
                            signal write     : out std_logic;
                            signal writedata : out std_logic_vector(writedata'range);
                            signal address   : out std_logic_vector(address'range)) is
    begin
        write     <= '1';
        writedata <= data_in;
        address   <= addr_in;
        wait for CLK_PERIOD;
        write <= '0';
    end procedure WriteRegister;
begin
    UUT : pwm_mm_slave
        port map(
            clk       => clk,
            reset     => reset,
            address   => address,
            writedata => writedata,
            read      => read,
            write     => write,
            readdata  => readdata,
            pwm_out   => pwm_out
        );

    with running select clk <=
        not clk after CLK_PERIOD / 2 when TRUE,
        '0' when FALSE;

    reset <= '0' after 5 * CLK_PERIOD / 4;

    p_test : process
    begin
        wait for 9 * CLK_PERIOD / 4;

        ---- Write clock divider !
        --WriteRegister("00", X"00000004", write, writedata, address); -- divide the frequency by 4
        --WriteRegister("01", X"00000002", write, writedata, address); -- sets the duty cycle to 50%
        --WriteRegister("10", X"00000001", write, writedata, address); -- start the pwm

        --wait until rising_edge(pwm_out);
        --wait for CLK_PERIOD / 4;
        --for i in 0 to 15 loop
        --	if (i mod 4) < 2 then
        --		assert pwm_out = '1' report "Wrong value. Should be 1." severity error;
        --	else
        --		assert pwm_out = '0' report "Wrong value. Should be 0." severity error;
        --	end if;

        --	wait for CLK_PERIOD;
        --end loop;

        wait until falling_edge(clk);
        wait for CLK_PERIOD / 4;
        WriteRegister("00", std_logic_vector(to_unsigned(100, writedata'length)), write, writedata, address); -- divide the frequency by 10
        WriteRegister("01", std_logic_vector(to_unsigned(40, writedata'length)), write, writedata, address); -- sets the duty cycle to 40%
        WriteRegister("10", std_logic_vector(to_unsigned(1, writedata'length)), write, writedata, address); -- start the pwm

        wait until rising_edge(pwm_out);
        wait for CLK_PERIOD / 4;
        for i in 0 to 39 loop
            if (i mod 10) < 6 then
                assert pwm_out = '1' report "Wrong value. Should be 1." severity error;
            else
                assert pwm_out = '0' report "Wrong value. Should be 0." severity error;
            end if;

            wait for CLK_PERIOD;
        end loop;

    --running <= FALSE;
    --wait;
    end process p_test;
end architecture rtl;

