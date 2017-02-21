library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity tw9912_stimulus is

    port (
        outclk  : out std_logic;
        outdata : out std_logic_vector(7 downto 0));

end tw9912_stimulus;

architecture stim of tw9912_stimulus is

    constant CLK_PERIOD : time := 37 ns;
    constant DELAY      : time := 2 ns;

begin

    process
        variable f, v, h : std_logic;
    begin

        loop
            outclk <= '0';
            for line_num in 1 to 625 loop
                for col_num in 1 to 1728 loop

                    wait for CLK_PERIOD / 2;
                    outclk <= '1';
                    wait for DELAY;

                    if col_num = 1 or col_num = 285 then
                        outdata <= X"FF";
                    elsif col_num = 2 or col_num = 3 or col_num = 286 or col_num = 287 then
                        outdata <= X"00";
                    elsif col_num > 4 and col_num < 285 then
                        if col_num mod 2 = 0 then
                            outdata <= X"80";
                        else
                            outdata <= X"10";
                        end if;

                    elsif col_num = 4 or col_num = 288 then

                        if line_num >= 1 and line_num <= 22 then
                            f := '0';
                            v := '1';
                        elsif line_num >= 23 and line_num <= 310 then
                            f := '0';
                            v := '0';
                        elsif line_num >= 311 and line_num <= 312 then
                            f := '0';
                            v := '1';
                        elsif line_num >= 313 and line_num <= 335 then
                            f := '1';
                            v := '1';
                        elsif line_num >= 336 and line_num <= 623 then
                            f := '1';
                            v := '0';
                        else
                            f := '1';
                            v := '1';
                        end if;

                        if col_num = 4 then
                            h := '1';
                        else
                            h := '0';
                        end if;

                        outdata(7) <= '1';
                        outdata(6) <= f;
                        outdata(5) <= v;
                        outdata(4) <= h;
                        outdata(3) <= v xor h;
                        outdata(2) <= f xor h;
                        outdata(1) <= f xor v;
                        outdata(0) <= f xor v xor h;
                    else
                        if (line_num >= 1 and line_num <= 22) or
                        (line_num >= 311 and line_num  <= 336) or
                        (line_num >= 624) then
                            outdata <= X"BB";
                        else
                            outdata <= X"DD";
                        end if;
                    end if;

                    wait for CLK_PERIOD / 2 - DELAY;
                    outclk <= '0';

                end loop;

            end loop;

        end loop;
    end process;

end architecture;  -- stim
