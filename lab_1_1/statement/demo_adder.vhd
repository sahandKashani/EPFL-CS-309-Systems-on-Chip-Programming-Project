-- #############################################################################
-- demo_adder.vhd
-- ==============
-- This component describes a simple adder with an Avalon-MM slave interface.
-- The operands can be written to register 0 and 1, and the result of the
-- addition can be read back from register 2.
--
-- Register map
-- +--------+------------+--------+------------------------------------+
-- | RegNo  | Name       | Access | Description                        |
-- +--------+------------+--------+------------------------------------+
-- | 0      | INPUT_1    | R/W    | First input of the addition.       |
-- +--------+------------+--------+------------------------------------+
-- | 1      | INPUT_2    | R/W    | Second input of the addition.      |
-- +--------+------------+--------+------------------------------------+
-- | 2      | RESULT     | RO     | Result of the addition. Writing to |
-- |        |            |        | this register has no effect.       |
-- +--------+------------+--------+------------------------------------+
--
-- Author : Sahand Kashani-Akhavan [sahand.kashani-akhavan@epfl.ch]
-- Revision : 2
-- Last updated : 2018-02-28
-- #############################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity demo_adder is
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
        writedata : in  std_logic_vector(31 downto 0)
    );
end demo_adder;

architecture rtl of demo_adder is

    constant REG_INPUT_1_OFST : std_logic_vector(1 downto 0) := "00";
    constant REG_INPUT_2_OFST : std_logic_vector(1 downto 0) := "01";
    constant REG_RESULT_OFST  : std_logic_vector(1 downto 0) := "10";

    signal reg_input_1 : unsigned(writedata'range);
    signal reg_input_2 : unsigned(writedata'range);

begin

    -- Avalon-MM slave write
    process(clk, reset)
    begin
        if reset = '1' then
            reg_input_1 <= (others => '0');
            reg_input_2 <= (others => '0');
        elsif rising_edge(clk) then
            if write = '1' then
                case address is
                    when REG_INPUT_1_OFST =>
                        reg_input_1 <= unsigned(writedata);

                    when REG_INPUT_2_OFST =>
                        reg_input_2 <= unsigned(writedata);

                    -- RESULT register is read-only
                    when REG_RESULT_OFST => null;

                    -- Remaining addresses in register map are unused.
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    -- Avalon-MM slave read
    process(clk, reset)
    begin
        if rising_edge(clk) then
            if read = '1' then
                case address is
                    when REG_INPUT_1_OFST =>
                        readdata <= std_logic_vector(reg_input_1);

                    when REG_INPUT_2_OFST =>
                        readdata <= std_logic_vector(reg_input_2);

                    when REG_RESULT_OFST =>
                        readdata <= std_logic_vector(reg_input_1 + reg_input_2);

                    -- Remaining addresses in register map are unmapped => return 0.
                    when others =>
                        readdata <= (others => '0');
                end case;
            end if;
        end if;
    end process;

end architecture rtl;
