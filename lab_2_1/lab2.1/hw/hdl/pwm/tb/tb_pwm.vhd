library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_pwm is
end entity;

architecture rtl of tb_pwm is
    constant CLK_PERIOD : time      := 20 ns;
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '0';
    signal sim_finished : boolean   := false;

    -- pwm ------------------------------------------------------------    
    signal address     : std_logic_vector(1 downto 0)  := (others => '0');
    signal writedata   : std_logic_vector(31 downto 0) := (others => '0');
    signal read, write : std_logic                     := '0';
    signal readdata    : std_logic_vector(31 downto 0) := (others => '0');
    signal pwm_out     : std_logic                     := '0';

    constant REG_PERIOD_OFST     : std_logic_vector(address'range) := std_logic_vector(to_unsigned(0, address'length));
    constant REG_DUTY_CYCLE_OFST : std_logic_vector(address'range) := std_logic_vector(to_unsigned(1, address'length));
    constant REG_CTRL_OFST       : std_logic_vector(address'range) := std_logic_vector(to_unsigned(2, address'length));

begin
    duv : entity work.pwm
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

        procedure write_register(constant ofst : in std_logic_vector(address'range);
                                 constant val  : in natural) is
        begin
            wait until falling_edge(clk);
            address   <= ofst;
            write     <= '1';
            writedata <= std_logic_vector(to_unsigned(val, writedata'length));

            wait until falling_edge(clk);
            address   <= (others => '0');
            write     <= '0';
            writedata <= (others => '0');
        end procedure write_register;

        procedure read_register(constant ofst : in std_logic_vector(address'range)) is
        begin
            wait until falling_edge(clk);
            address <= ofst;
            read    <= '1';

            wait until falling_edge(clk);
            address <= (others => '0');
            read    <= '0';
        end procedure read_register;

    begin
        async_reset;

        write_register(REG_PERIOD_OFST, 100);
        write_register(REG_DUTY_CYCLE_OFST, 20);
        write_register(REG_CTRL_OFST, 1);

        read_register(REG_PERIOD_OFST);
        read_register(REG_DUTY_CYCLE_OFST);
        read_register(REG_CTRL_OFST);

        wait for 1 ms;
        sim_finished <= true;
        wait;
    end process sim;
end architecture rtl;

