-- #############################################################################
-- pwm.vhd
-- =======
-- PWM memory-mapped Avalon slave interface.
--
-- Author        : Philémon Favrod (philemon.favrod@epfl.ch)
-- Modified by   : Sahand Kashani-Akhavan [sahand.kashani-akhavan@epfl.ch]
-- Revision      : 3
-- Last modified : 2018-02-28
-- #############################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pwm_constants.all;

entity pwm is
    port(
        -- Avalon Clock interface
        clk : in std_logic;

        -- Avalon Reset interface
        reset : in std_logic;

        -- Avalon-MM Slave interface
        address   : in  std_logic_vector(1 downto 0);
        read      : in  std_logic;
        write     : in  std_logic;
        readdata  : out std_logic_vector(31 downto 0);
        writedata : in  std_logic_vector(31 downto 0);

        -- Avalon Conduit interface
        pwm_out : out std_logic
    );
end pwm;

architecture rtl of pwm is

    constant ONE : unsigned(writedata'range) := to_unsigned(1, writedata'length);

    -- Avalon-MM slave registers
    -- The versions of the signals prefixed by 'new_' are used to avoid glitches
    -- in the PWM.
    signal period, new_period         : unsigned(writedata'range);
    signal duty_cycle, new_duty_cycle : unsigned(writedata'range);

    -- Internal registers
    signal counter : unsigned(31 downto 0);
    signal run     : std_logic;
    signal pwm     : std_logic;

begin

    pwm_out <= pwm;

    p_counter : process(clk, reset)
    begin
        if reset = '1' then
            counter <= ONE;
        elsif rising_edge(clk) then
            if counter = period then
                counter <= ONE;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process p_counter;

    p_pwm : process(clk, reset)
    begin
        if reset = '1' then
            pwm        <= '0';
            period     <= to_unsigned(DEFAULT_PERIOD, period'length);
            duty_cycle <= to_unsigned(DEFAULT_DUTY_CYCLE, duty_cycle'length);
        elsif rising_edge(clk) then
            if counter = period then
                -- Pulse is restarted only if PWM is still running.
                if run = '1' then
                    pwm        <= '1';
                    period     <= new_period;
                    duty_cycle <= new_duty_cycle;
                end if;
            elsif counter >= duty_cycle then
                pwm <= '0';
            end if;
        end if;
    end process p_pwm;

    p_avalon_write : process(clk, reset)
    begin
        if reset = '1' then
            new_period     <= to_unsigned(DEFAULT_PERIOD, new_period'length);
            new_duty_cycle <= to_unsigned(DEFAULT_DUTY_CYCLE, new_duty_cycle'length);
            run            <= '0';
        elsif rising_edge(clk) then
            if write = '1' then
                case address is
                    when REG_PERIOD_OFST =>
                        new_period <= unsigned(writedata);

                    when REG_DUTY_CYCLE_OFST =>
                        new_duty_cycle <= unsigned(writedata);

                    when REG_CTRL_OFST =>
                        run <= writedata(0);

                    when others => null;
                end case;
            end if;
        end if;
    end process p_avalon_write;

    p_avalon_read : process(clk, reset)
    begin
        if rising_edge(clk) then
            if read = '1' then
                case address is
                    when REG_PERIOD_OFST =>
                        readdata <= std_logic_vector(period);  -- should technically return new_period

                    when REG_DUTY_CYCLE_OFST =>
                        readdata <= std_logic_vector(duty_cycle);  -- should technically return new_duty_cycle

                    when others =>
                        readdata <= (others => '0');
                end case;
            end if;
        end if;
    end process p_avalon_read;

end architecture rtl;
