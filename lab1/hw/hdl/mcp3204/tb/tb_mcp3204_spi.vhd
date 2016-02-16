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
    signal busy       : std_logic                     := '0';
    signal start      : std_logic                     := '0';
    signal channel    : std_logic_vector(1 downto 0)  := (others => '0');
    signal data_valid : std_logic                     := '0';
    signal data       : std_logic_vector(11 downto 0) := (others => '0');
    signal SCLK       : std_logic                     := '0';
    signal CS_N       : std_logic                     := '1';
    signal MOSI       : std_logic                     := '0';
    signal MISO       : std_logic                     := '0';

begin
    duv : entity work.mcp3204_spi
        port map(
            clk        => clk,
            reset      => reset,
            busy       => busy,
            start      => start,
            channel    => channel,
            data_valid => data_valid,
            data       => data,
            SCLK       => SCLK,
            CS_N       => CS_N,
            MOSI       => MOSI,
            MISO       => MISO
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

        procedure spi_transfer(constant channel_number : natural range 0 to 3) is
        begin
            if busy = '1' then
                wait until busy = '0';

            else
                wait until falling_edge(clk);
                start   <= '1';
                channel <= std_logic_vector(to_unsigned(channel_number, channel'length));

                wait until falling_edge(clk);
                start   <= '0';
                channel <= (others => '0');

                wait until rising_edge(data_valid);
                wait until falling_edge(busy);
            end if;
        end procedure spi_transfer;

    begin
        async_reset;

        MISO <= '1';
        spi_transfer(0);

        MISO <= '0';
        spi_transfer(1);

        MISO <= '1';
        spi_transfer(2);

        MISO <= '0';
        spi_transfer(3);

        sim_finished <= true;
        wait;
    end process sim;
end architecture rtl;


