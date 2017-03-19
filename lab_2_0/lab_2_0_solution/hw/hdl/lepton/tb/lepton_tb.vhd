library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity lepton_tb is
end lepton_tb;

architecture tb of lepton_tb is
    signal clk       : std_logic                     := '0';
    signal reset     : std_logic                     := '0';
    signal address   : std_logic_vector(13 downto 0) := (others => '0');
    signal readdata  : std_logic_vector(15 downto 0) := (others => '0');
    signal writedata : std_logic_vector(15 downto 0) := (others => '0');
    signal read      : std_logic                     := '0';
    signal write     : std_logic                     := '0';
    signal SCLK      : std_logic                     := '0';
    signal CSn       : std_logic                     := '0';
    signal MOSI      : std_logic                     := '0';
    signal MISO      : std_logic                     := '1';

    constant CLK_PERIOD : time := 20 ns;

    signal sim_ended : boolean := false;

begin
    dut : entity work.lepton
    port map(
        clk       => clk,
        reset     => reset,
        address   => address,
        readdata  => readdata,
        writedata => writedata,
        read      => read,
        write     => write,
        SCLK      => SCLK,
        CSn       => CSn,
        MOSI      => MOSI,
        MISO      => MISO
    );

    clk <= not clk after CLK_PERIOD / 2 when not sim_ended else '0';

    miso_gen : process
        variable seed1, seed2 : positive;
        variable rand         : real;
    begin
        if sim_ended then
            wait;
        else
            uniform(seed1, seed2, rand);
            wait until rising_edge(SCLK);
            MISO <= to_unsigned(integer(rand), 1)(0);

        end if;
    end process;

    stimuli : process
    begin
        reset <= '1';
        write <= '0';

        wait for 2 * CLK_PERIOD;
        reset <= '0';

        wait for CLK_PERIOD;
        write        <= '1';
        writedata(0) <= '1';
        wait for CLK_PERIOD;
        write        <= '0';

        wait for 17 ms;
        sim_ended <= true;
        wait;
    end process;

end tb;
