library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mcp3204_spi is
    port(
        -- Inputs
        clk         : in  std_logic;
        reset       : in  std_logic;
        busy : out std_logic;
        start : in std_logic;
        done : out std_logic;
        data : out std_logic_vector(11 downto 0);
        CS : out  std_logic;
        MOSI   : out  std_logic;
        MISO     : in  std_logic
    );
end mcp3204_spi;

architecture rtl of mcp3204_spi is
    type state is (STATE_CS_HIGH, STATE_CS_LOW, STATE_START, STATE_SGL, STATE_D2, STATE_D1, STATE_D0, STATE_SAMPLE, STATE_NULL, STATE_D_IN);

    signal reg_state, next_reg_state : state := STATE_CS_HIGH;
begin

    process(clk, reset)
    begin
        if reset = '1' then
            reg_state <= STATE_CS_HIGH;
        elsif rising_edge(clk) then
            reg_state <= next_reg_state;
        end if;
    end process;

    process(reg_state)
    begin
        next_reg_state <= reg_state;

        case reg_state is
            when STATE_CS_HIGH =>
                if start = '1' then
                    next_reg_state <= STATE_CS_LOW;
                end if;

            when STATE_CS_LOW =>
                next_reg_state <= STATE_START;

            when STATE_START =>
                next_reg_state <= STATE_SGL;

            when STATE_SGL =>
                next_reg_state <= STATE_D2;

            when STATE_D2 =>
                next_reg_state <= STATE_D1;

            when STATE_D1 =>
                next_reg_state <= STATE_D0;

            when STATE_D0 =>
                next_reg_state <= STATE_SGL;

            when STATE_SAMPLE =>
                next_reg_state <= STATE_SGL;

            when STATE_NULL =>
                next_reg_state <= STATE_SGL;

            when STATE_D_IN =>
                next_reg_state <= STATE_SGL;

        end case;
    end process;

end architecture rtl;
