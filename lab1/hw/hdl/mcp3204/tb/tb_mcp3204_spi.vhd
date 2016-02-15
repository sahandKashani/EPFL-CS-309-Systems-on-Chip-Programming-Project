library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_mcp3204_spi is
end entity;

architecture rtl of tb_mcp3204_spi is
    constant CLK_PERIOD : time      := 20 ns;
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '0';
    signal sim_finished : boolean   := false;

    -- mcp3204_spi ------------------------------------------------------------
    signal busy  : std_logic                     := '0';
    signal start : std_logic                     := '0';
    signal done  : std_logic                     := '0';
    signal data  : std_logic_vector(11 downto 0) := (others => '0');
    signal CS_N  : std_logic                     := '1';
    signal MOSI  : std_logic                     := '0';
    signal MISO  : std_logic                     := '0';

begin
    duv : entity work.mcp3204_spi
        port map(
            clk   => clk,
            reset => reset,
            busy  => busy,
            start => start,
            done  => done,
            data  => data,
            CS_N  => CS_N,
            MOSI  => MOSI,
            MISO  => MISO
        );

    clk <= not clk after CLK_PERIOD / 2 when not sim_finished;

    sim : process
        procedure async_reset is
        begin
            wait until rising_edge(clk);
            wait for CLK_PERIOD / 4;
            reset <= '1';

            wait for CLK_PERIOD / 2;
            reset <= '0';
        end procedure async_reset;

    begin
        async_reset;

        sim_finished <= true;
        wait;
    end process sim;
end architecture rtl;


