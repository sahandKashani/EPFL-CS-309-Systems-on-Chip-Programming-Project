library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library osvvm;
use osvvm.RandomPkg.all;

entity tb_mcp3204 is
end entity;

architecture rtl of tb_mcp3204 is
    constant CLK_PERIOD : time      := 20 ns;
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '0';
    signal sim_finished : boolean   := false;

    -- mcp3204 -----------------------------------------------------------------
    signal address  : std_logic_vector(1 downto 0)  := (others => '0');
    signal read     : std_logic                     := '0';
    signal readdata : std_logic_vector(31 downto 0) := (others => '0');
    signal CS_N     : std_logic                     := '0';
    signal MOSI     : std_logic                     := '0';
    signal MISO     : std_logic                     := '0';
    signal SCLK     : std_logic                     := '0';

begin
    duv : entity work.mcp3204
        port map(
            clk      => clk,
            reset    => reset,
            address  => address,
            read     => read,
            readdata => readdata,
            CS_N     => CS_N,
            MOSI     => MOSI,
            MISO     => MISO,
            SCLK     => SCLK
        );

    clk <= not clk after CLK_PERIOD / 2 when not sim_finished;

    MISO_generation : process
        variable rand_gen : RandomPType;
        variable rint     : integer;
    begin
        rand_gen.InitSeed(rand_gen'instance_name);
        rand_gen.SetRandomParm(UNIFORM);

        while true loop
            if not sim_finished then
                wait until falling_edge(SCLK);
                rint := rand_gen.RandInt(0, 1);

                if rint = 0 then
                    MISO <= '0';
                else
                    MISO <= '1';
                end if;
            else
                wait;
            end if;
        end loop;

    end process MISO_generation;

    sim : process
        procedure async_reset is
        begin
            wait until rising_edge(clk);
            wait for CLK_PERIOD / 4;
            reset <= '1';

            wait for CLK_PERIOD / 2;
            reset <= '0';
        end procedure async_reset;

        procedure read_register(constant channel_number : natural range 0 to 3) is
        begin
            wait until falling_edge(clk);
            address <= std_logic_vector(to_unsigned(channel_number, address'length));
            read    <= '1';

            wait until falling_edge(clk);
            address <= (others => '0');
            read    <= '0';

            wait until falling_edge(clk);
        end procedure;

    begin
        async_reset;

        wait for 10000 * CLK_PERIOD;

        for i in 0 to 3 loop
            read_register(i);
        end loop;

        sim_finished <= true;
        wait;
    end process sim;
end architecture rtl;



