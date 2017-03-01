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

begin

end architecture rtl;
