library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pwm_constants.all;

entity tb_pwm is
end entity;

architecture rtl of tb_pwm is

    -- 50 MHz clock
    constant CLK_PERIOD : time := 20 ns;

    -- Signal used to end simulator when we finished submitting our test cases
    signal sim_finished : boolean := false;

    -- PWM PORTS
    signal clk       : std_logic;
    signal reset     : std_logic;
    signal address   : std_logic_vector(1 downto 0);
    signal read      : std_logic;
    signal write     : std_logic;
    signal readdata  : std_logic_vector(31 downto 0);
    signal writedata : std_logic_vector(31 downto 0);
    signal pwm_out   : std_logic;

    -- Values of registers we are going to use to configure the PWM unit
    constant CONFIG_PERIOD     : natural := 100;
    constant CONFIG_DUTY_CYCLE : natural := 20;
    constant CONFIG_CTRL_START : natural := 1;
    constant CONFIG_CTRL_STOP  : natural := 0;

begin

    -- Instantiate DUT
    dut : entity work.pwm
    port map(
        clk       => clk,
        reset     => reset,
        address   => address,
        read      => read,
        write     => write,
        readdata  => readdata,
        writedata => writedata,
        pwm_out   => pwm_out
    );

    -- Generate clk signal
    clk_generation : process
    begin
        if not sim_finished then
            clk <= '1';
            wait for CLK_PERIOD / 2;
            clk <= '0';
            wait for CLK_PERIOD / 2;
        else
            wait;
        end if;
    end process clk_generation;

    -- Test PWM
    simulation : process

        procedure async_reset is
        begin
            wait until rising_edge(clk);
            wait for CLK_PERIOD / 4;

            reset <= '1';
            wait for CLK_PERIOD / 2;

            reset <= '0';
            wait for CLK_PERIOD / 4;
        end procedure async_reset;

        procedure write_register(constant ofst : in natural;
                                 constant val  : in natural) is
        begin
            wait until rising_edge(clk);

            address   <= std_logic_vector(to_unsigned(ofst, address'length));
            write     <= '1';
            writedata <= std_logic_vector(to_unsigned(val, writedata'length));
            wait until rising_edge(clk);

            address   <= (others => '0');
            write     <= '0';
            writedata <= (others => '0');
            wait until rising_edge(clk);
        end procedure write_register;

        procedure read_register(constant ofst : in natural) is
        begin
            wait until rising_edge(clk);

            address <= std_logic_vector(to_unsigned(ofst, address'length));
            read    <= '1';
            wait until rising_edge(clk);

            address <= (others => '0');
            read    <= '0';
            wait until rising_edge(clk);
        end procedure read_register;

        procedure read_register_check(constant ofst         : in natural;
                                      constant expected_val : in natural) is
        begin
            read_register(ofst);

            case ofst is
                when REG_PERIOD_OFST =>
                    assert to_integer(unsigned(readdata)) = expected_val
                    report "Unexpected PERIOD: " &
                    "PERIOD = " & integer'image(to_integer(unsigned(readdata))) & "; " &
                    "PERIOD_expected = " & integer'image(expected_val)
                    severity error;

                when REG_DUTY_CYCLE_OFST =>
                    assert to_integer(unsigned(readdata)) = expected_val
                    report "Unexpected DUTY_CYCLE: " &
                    "DUTY_CYCLE = " & integer'image(to_integer(unsigned(readdata))) & "; " &
                    "DUTY_CYCLE_expected = " & integer'image(expected_val)
                    severity error;

                when REG_CTRL_OFST =>
                    assert to_integer(unsigned(readdata)) = expected_val
                    report "Unexpected CTRL: " &
                    "CTRL = " & integer'image(to_integer(unsigned(readdata))) & "; " &
                    "CTRL_expected = " & integer'image(expected_val)
                    severity error;

                when others =>
                    null;
            end case;
        end procedure read_register_check;

    begin

        -- Default values
        reset     <= '0';
        address   <= (others => '0');
        read      <= '0';
        write     <= '0';
        writedata <= (others => '0');
        wait until rising_edge(clk);

        -- Reset the circuit
        async_reset;

        -- Write desired configuration to PWM Avalon-MM slave.
        write_register(REG_PERIOD_OFST, CONFIG_PERIOD);
        write_register(REG_DUTY_CYCLE_OFST, CONFIG_DUTY_CYCLE);

        -- Read back configuration from PWM Avalon-MM slave. Note that we have
        -- not started the PWM unit yet, so the new configuration must not be
        -- read back at this point (as per the register map).
        read_register_check(REG_PERIOD_OFST, DEFAULT_PERIOD);
        read_register_check(REG_DUTY_CYCLE_OFST, DEFAULT_DUTY_CYCLE);
        read_register_check(REG_CTRL_OFST, 0);

        -- Start PWM
        write_register(REG_CTRL_OFST, CONFIG_CTRL_START);

        -- Wait until PWM pulses for the first time after we sent START.
        wait until rising_edge(pwm_out);

        -- Read back configuration from PWM Avalon-MM slave. Now that we have
        -- started the PWM unit, we should be able to read back the
        -- configuration we wrote (as per the register map).
        read_register_check(REG_PERIOD_OFST, CONFIG_PERIOD);
        read_register_check(REG_DUTY_CYCLE_OFST, CONFIG_DUTY_CYCLE);
        read_register_check(REG_CTRL_OFST, 0);

        -- Wait for 2 PWM periods to finish
        wait for 2 * CLK_PERIOD * CONFIG_PERIOD;

        -- Stop PWM.
        write_register(REG_CTRL_OFST, CONFIG_CTRL_STOP);

        -- Wait for PWM period to finish
        wait for 1 * CLK_PERIOD * CONFIG_PERIOD;

        -- Instruct "clk_generation" process to halt execution.
        sim_finished <= true;

        -- Make this process wait indefinitely (it will never re-execute from
        -- its beginning again).
        wait;
    end process simulation;
end architecture rtl;

