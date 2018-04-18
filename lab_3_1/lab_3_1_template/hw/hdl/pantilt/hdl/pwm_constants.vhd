-- #############################################################################
-- pwm_constants.vhd
-- =================
-- This package contains constants used in the PWM design files.
--
-- Author        : Sahand Kashani-Akhavan [sahand.kashani-akhavan@epfl.ch]
-- Revision      : 2
-- Last modified : 2018-02-28
-- #############################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pwm_constants is
    -- Register map
    -- +--------+------------+--------+------------------------------------------------------------------------------+
    -- | RegNo  | Name       | Access | Description                                                                  |
    -- +--------+------------+--------+------------------------------------------------------------------------------+
    -- | 0      | PERIOD     | R/W    | Period in clock cycles [2 <= period <= (2**32) - 1].                         |
    -- |        |            |        |                                                                              |
    -- |        |            |        | This value can be read/written while the unit is in the middle of an ongoing |
    -- |        |            |        | PWM pulse. To allow safe behaviour, one cannot modify the period of an       |
    -- |        |            |        | ongoing pulse, so we adopt the following semantics for this register:        |
    -- |        |            |        |                                                                              |
    -- |        |            |        | >> WRITING a value in this register indicates the NEW period to apply to the |
    -- |        |            |        |    next pulse.                                                               |
    -- |        |            |        |                                                                              |
    -- |        |            |        | >> READING a value from this register indicates the CURRENT period of the    |
    -- |        |            |        |    ongoing pulse.                                                            |
    -- +--------+------------+--------+------------------------------------------------------------------------------+
    -- | 1      | DUTY_CYCLE | R/W    | Duty cycle of the PWM [1 <= duty cycle <= period]                            |
    -- |        |            |        |                                                                              |
    -- |        |            |        | This value can be read/written while the unit is in the middle of an ongoing |
    -- |        |            |        | PWM pulse. To allow safe behaviour, one cannot modify the duty cycle of an   |
    -- |        |            |        | ongoing pulse, so we adopt the following semantics for this register:        |
    -- |        |            |        |                                                                              |
    -- |        |            |        | >> WRITING a value in this register indicates the NEW duty cycle to apply to |
    -- |        |            |        |    the next pulse.                                                           |
    -- |        |            |        |                                                                              |
    -- |        |            |        | >> READING a value from this register indicates the CURRENT duty cycle of    |
    -- |        |            |        |    the ongoing pulse.                                                        |
    -- +--------+------------+--------+------------------------------------------------------------------------------+
    -- | 2      | CTRL       | WO     | >> Writing 0 to this register stops the PWM once the ongoing pulse has ended.|
    -- |        |            |        |    Writing 1 to this register starts the PWM.                                |
    -- |        |            |        |                                                                              |
    -- |        |            |        | >> Reading this register always returns 0.                                   |
    -- +--------+------------+--------+------------------------------------------------------------------------------+
    constant REG_PERIOD_OFST     : std_logic_vector(1 downto 0) := "00";
    constant REG_DUTY_CYCLE_OFST : std_logic_vector(1 downto 0) := "01";
    constant REG_CTRL_OFST       : std_logic_vector(1 downto 0) := "10";

    -- Default values of registers after reset (BEFORE writing START to the CTRL
    -- register with a new configuration)
    constant DEFAULT_PERIOD     : natural := 4;
    constant DEFAULT_DUTY_CYCLE : natural := 2;
end package pwm_constants;

package body pwm_constants is

end package body pwm_constants;
