-- PWM Memory-Mapped Avalon Slave Interface
-- Author: Philémon Favrod (philemon.favrod@epfl.ch)
-- Revision: 1
--
-- The register map of the component is shown below:
-- +--------+------------+--------+---------------------------------------------------------------------------+
-- | Offset | Name       | Access | Description                                                       		  |
-- +--------+------------+--------+---------------------------------------------------------------------------+
-- | 0      | PERIOD     | R/W    | The clock divider. Reminder: clk is a 50-MHz clock.               		  |
-- +--------+------------+--------+---------------------------------------------------------------------------+
-- | 1      | DUTY_CYCLE | R/W    | A value between 0 and CLOCK_DIV indicating the duty cycle of the clock.   |
-- +--------+------------+--------+---------------------------------------------------------------------------+
-- | 2      | CTRL		 | W	  | Writing 0 (resp. 1) to the register stops (resp. starts) the PWM. 		  |
-- +--------+------------+--------+---------------------------------------------------------------------------+

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pwm_mm_slave is
    port(
        -- Inputs
        clk         : in  std_logic;
        reset       : in  std_logic;
        address     : in  std_logic_vector(1 downto 0); -- 2 address bits are needed to address each register of the interface
        writedata   : in  std_logic_vector(31 downto 0);
        read, write : in  std_logic;

        -- Outputs
        readdata    : out std_logic_vector(31 downto 0);
        pwm_out     : out std_logic
    );

end pwm_mm_slave;

architecture rtl of pwm_mm_slave is
    constant ONE : unsigned(writedata'range) := to_unsigned(1, writedata'length);

    -- Registers
    -- The versions of the signals prefixed by 'next_' are used to avoid glitches in the PWM.
    signal period, new_period         : unsigned(31 downto 0);
    signal duty_cycle, new_duty_cycle : unsigned(31 downto 0);
    constant DEFAULT_PERIOD           : unsigned(period'range)     := to_unsigned(4, period'length);
    constant DEFAULT_DUTY_CYCLE       : unsigned(duty_cycle'range) := to_unsigned(2, duty_cycle'length);

    -- Internal signals
    signal counter : unsigned(31 downto 0);
    signal started : std_logic;
    signal pwm     : std_logic;
begin
    pwm_out <= pwm;

    p_clk_div : process(clk, reset)
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

    end process p_clk_div;

    p_pwm : process(clk, reset)
    begin
        if reset = '1' then
            pwm        <= '0';
            period     <= DEFAULT_PERIOD;
            duty_cycle <= DEFAULT_DUTY_CYCLE;
        elsif rising_edge(clk) then
            if started = '1' then
                if counter = period then
                    pwm        <= '1';
                    period     <= new_period;
                    duty_cycle <= new_duty_cycle;
                elsif counter >= duty_cycle then
                    pwm <= '0';
                end if;
            end if;
        end if;

    end process p_pwm;

    p_avalon_write : process(clk, reset)
    begin
        if reset = '1' then
            new_period     <= DEFAULT_PERIOD;
            new_duty_cycle <= DEFAULT_DUTY_CYCLE;
            started        <= '0';
        elsif rising_edge(clk) then
            if write = '1' then
                case address is
                    when "00" =>
                        new_period <= unsigned(writedata);
                    when "01" =>
                        new_duty_cycle <= unsigned(writedata);
                    when "10" =>
                        started <= writedata(0);
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
                    when "00" =>
                        readdata <= std_logic_vector(period);
                    when "01" =>
                        readdata <= std_logic_vector(duty_cycle);
                    when others => null;
                end case;
            end if;
        end if;
    end process p_avalon_read;

end architecture rtl;
