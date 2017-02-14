-- PWM Memory-Mapped Avalon Slave Interface
-- Author: Philémon Favrod (philemon.favrod@epfl.ch)
-- Revision: 1
--
-- The register map of the component is shown below:
-- +--------+------------+--------+---------------------------------------------------------------------------+
-- | Offset | Name       | Access | Description                                                               |
-- +--------+------------+--------+---------------------------------------------------------------------------+
-- | 0      | PERIOD     | R/W    | The clock divider. Reminder: clk is a 50-MHz clock.                       |
-- +--------+------------+--------+---------------------------------------------------------------------------+
-- | 1      | DUTY_CYCLE | R/W    | A value between 0 and CLOCK_DIV indicating the duty cycle of the clock.   |
-- +--------+------------+--------+---------------------------------------------------------------------------+
-- | 2      | CTRL       | W      | Writing 0 (resp. 1) to the register stops (resp. starts) the PWM.         |
-- +--------+------------+--------+---------------------------------------------------------------------------+

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pwm is
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

end pwm;

architecture rtl of pwm is
    constant REG_PERIOD_OFST     : std_logic_vector(address'range) := std_logic_vector(to_unsigned(0, address'length));
    constant REG_DUTY_CYCLE_OFST : std_logic_vector(address'range) := std_logic_vector(to_unsigned(1, address'length));
    constant REG_CTRL_OFST       : std_logic_vector(address'range) := std_logic_vector(to_unsigned(2, address'length));

begin

end architecture rtl;
