library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package utils is
    function bitlength(number : integer) return integer;

end package utils;

package body utils is

    -- purpose: returns the minimum # of bits needed to represent the input number
    function bitlength(number : integer) return integer is
        variable acc : integer := 1;
        variable i   : integer := 0;
    begin
        loop
            if acc > number then
                return i;
            end if;

            acc := acc * 2;
            i   := i + 1;
        end loop;

    end function bitlength;

end package body utils;
