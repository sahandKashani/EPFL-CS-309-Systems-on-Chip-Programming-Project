------------------------------------------------------
-- i2c_core.vhd - I2C core V2 logic
------------------------------------------------------
-- Author  : Cédric Gaudin
-- Version : 0.4 alpha
-- History :
--           20-mar-2002 CG 0.1 initial alpha release
--           22-mar-2002 CG 0.2 complete rewrite
--           27-mar-2002 CG 0.3 minor corrections
--           02-apr-2002 CG 0.4 sync. of outputs
------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity i2c_core is
    port(
        -- I2C signals
        sda_in       : in  std_logic;
        scl_in       : in  std_logic;
        sda_out      : out std_logic;
        scl_out      : out std_logic;

        -- interface signals
        clk          : in  std_logic;
        rst          : in  std_logic;
        sclk         : in  std_logic;
        ack_in       : in  std_logic;
        ack_out      : out std_logic;
        data_in      : in  std_logic_vector(7 downto 0);
        data_out     : out std_logic_vector(7 downto 0);
        cmd_start    : in  std_logic;
        cmd_stop     : in  std_logic;
        cmd_read     : in  std_logic;
        cmd_write    : in  std_logic;
        cmd_done_ack : in  std_logic;
        cmd_done     : out std_logic;
        busy         : out std_logic

    -- debug signals
    --		state      : out std_logic_vector(5 downto 0)

    );
end i2c_core;

architecture behavorial of i2c_core is
    type state_type is (
        s_Reset, s_Idle, s_Done, s_DoneAck,
        s_Start_A, s_Start_B, s_Start_C, s_Start_D,
        s_Stop_A, s_Stop_B, s_Stop_C,
        s_Rd_A, s_Rd_B, s_Rd_C, s_Rd_D, s_Rd_E, s_Rd_F,
        s_RdAck_A, s_RdAck_B, s_RdAck_C, s_RdAck_D, s_RdAck_E,
        s_Wr_A, s_Wr_B, s_Wr_C, s_Wr_D, s_Wr_E,
        s_WrAck_A, s_WrAck_B, s_WrAck_C, s_WrAck_D
    );

    -- data output register
    signal i_dout_ld : std_logic;
    signal i_dout    : std_logic_vector(7 downto 0);

    -- ack output register
    signal i_ack_out_ld : std_logic;
    signal i_ack_out    : std_logic;

    -- data input bit
    signal i_data_in : std_logic;

    -- bit counter
    signal i_ctr      : unsigned(2 downto 0);
    signal i_ctr_incr : std_logic;
    signal i_ctr_clr  : std_logic;

    signal p_state : state_type;
    signal n_state : state_type;

    signal i_scl_out : std_logic;
    signal i_sda_out : std_logic;

    signal i_sclk_en : std_logic;

    signal i_cmd_done : std_logic;
    signal i_cmd_go   : std_logic;
    signal i_busy     : std_logic;

begin

    -- syncronize output signals
    output_sync : process(clk, rst)
    begin
        if (rst = '1') then
            scl_out  <= '1';
            sda_out  <= '1';
            data_out <= (others => '0');
            ack_out  <= '0';
            busy     <= '0';
            cmd_done <= '0';
        elsif (rising_edge(clk)) then
            scl_out  <= i_scl_out;
            sda_out  <= i_sda_out;
            data_out <= i_dout;
            ack_out  <= i_ack_out;
            busy     <= i_busy;
            cmd_done <= i_cmd_done;
        end if;
    end process output_sync;

    -- select current bit
    data_input_selector : process(i_ctr, data_in)
    begin
        case i_ctr is
            when "000"  => i_data_in <= data_in(7);
            when "001"  => i_data_in <= data_in(6);
            when "010"  => i_data_in <= data_in(5);
            when "011"  => i_data_in <= data_in(4);
            when "100"  => i_data_in <= data_in(3);
            when "101"  => i_data_in <= data_in(2);
            when "110"  => i_data_in <= data_in(1);
            when "111"  => i_data_in <= data_in(0);
            when others => null;
        end case;
    end process data_input_selector;

    -- indicate start of command
    i_cmd_go <= (cmd_read OR cmd_write) AND NOT i_busy;

    -- i2c bit counter
    counter : process(clk, rst)
    begin
        if (rst = '1') then
            i_ctr <= (others => '0');
        elsif (rising_edge(clk)) then
            if (i_ctr_clr = '1') then
                i_ctr <= (others => '0');
            elsif (i_ctr_incr = '1') then
                i_ctr <= i_ctr + 1;
            end if;
        end if;
    end process counter;

    -- data output register
    dout_reg : process(clk, rst)
    begin
        if (rst = '1') then
            i_dout <= (others => '0');
        elsif (rising_edge(clk)) then
            if (i_dout_ld = '1') then
                case i_ctr is
                    when "000"  => i_dout(7) <= sda_in;
                    when "001"  => i_dout(6) <= sda_in;
                    when "010"  => i_dout(5) <= sda_in;
                    when "011"  => i_dout(4) <= sda_in;
                    when "100"  => i_dout(3) <= sda_in;
                    when "101"  => i_dout(2) <= sda_in;
                    when "110"  => i_dout(1) <= sda_in;
                    when "111"  => i_dout(0) <= sda_in;
                    when others => null;
                end case;
            end if;
        end if;
    end process dout_reg;

    -- ack bit output register
    ack_out_reg : process(clk, rst)
    begin
        if (rst = '1') then
            i_ack_out <= '0';
        elsif (rising_edge(clk)) then
            if (i_ack_out_ld = '1') then
                i_ack_out <= sda_in;
            end if;
        end if;
    end process ack_out_reg;

    -- i2c send / receive byte
    i2c_sync : process(rst, clk)
    begin
        if (rst = '1') then
            p_state <= s_Reset;
        elsif (rising_edge(clk)) then
            if ((sclk = '1' and i_sclk_en = '1') or i_sclk_en = '0') then
                p_state <= n_state;
            end if;
        end if;
    end process i2c_sync;

    i2c_comb : process(p_state, sda_in, scl_in, i_cmd_go, i_ctr, ack_in, i_data_in, cmd_start, cmd_stop, cmd_write, cmd_read, cmd_done_ack)
    begin
        n_state    <= p_state;
        --n_state      <= p_state;
        i_sclk_en  <= '0';
        i_busy     <= '0';
        i_ctr_clr  <= '0';
        i_ctr_incr <= '0';
        i_cmd_done <= '0';
        --i_dout_ld    <= '0';
        --i_ack_out_ld <= '0';
        i_sda_out  <= sda_in;
        i_scl_out  <= scl_in;
        --state        <= "111111";

        case p_state is
            when s_Reset =>
                --state        <= "000000";
                i_sclk_en    <= '0';
                i_busy       <= '0';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= '1';
                i_scl_out    <= '1';
                n_state      <= s_Idle;

            when s_Idle =>
                --state        <= "000001";
                i_sclk_en    <= '0';
                i_busy       <= '0';
                i_ctr_clr    <= '1';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= sda_in;
                i_scl_out    <= scl_in;

                if (i_cmd_go = '1') then
                    if (cmd_start = '1') then

                        -- do a START
                        n_state <= s_Start_A;
                    elsif (cmd_write = '1') then

                        -- do a WRITE
                        n_state <= s_Wr_A;
                    elsif (cmd_read = '1') then

                        -- do a READ
                        n_state <= s_Rd_A;
                    end if;
                end if;

            when s_Start_A =>
                --state        <= "001000";
                i_sclk_en    <= '1';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= '1';
                i_scl_out    <= scl_in;

                n_state <= s_Start_B;

            when s_Start_B =>
                --state        <= "001001";
                i_sclk_en    <= '1';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= '1';
                i_scl_out    <= '1';

                n_state <= s_Start_C;

            when s_Start_C =>
                --state        <= "001010";
                i_sclk_en    <= '1';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= '0';
                i_scl_out    <= '1';

                n_state <= s_Start_D;

            when s_Start_D =>
                --state        <= "001011";
                i_sclk_en    <= '1';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= '0';
                i_scl_out    <= '0';

                if (cmd_write = '1') then
                    -- do a WRITE
                    n_state <= s_Wr_A;
                elsif (cmd_read = '1') then
                    -- do a READ
                    n_state <= s_Rd_A;
                end if;

            when s_Rd_A =>
                --state        <= "010000";
                i_sclk_en    <= '1';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= '1';
                i_scl_out    <= '0';

                n_state <= s_Rd_B;

            when s_Rd_B =>
                --state        <= "010001";
                i_sclk_en    <= '1';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= '1';
                i_scl_out    <= '1';

                n_state <= s_Rd_C;

            when s_Rd_C =>
                --state        <= "010010";
                i_sclk_en    <= '0';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '1';
                i_ack_out_ld <= '0';
                i_sda_out    <= '1';
                i_scl_out    <= '1';

                n_state <= s_Rd_D;

            when s_Rd_D =>
                --state        <= "010011";
                i_sclk_en    <= '1';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= '1';
                i_scl_out    <= '1';

                n_state <= s_Rd_E;

            when s_Rd_E =>
                --state        <= "010100";
                i_sclk_en    <= '1';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= '1';
                i_scl_out    <= '0';

                if (i_ctr = 7) then
                    -- do ACKOUT
                    n_state <= s_WrAck_A;
                else
                    -- increment bit counter
                    n_state <= s_Rd_F;
                end if;

            when s_Rd_F =>
                --state        <= "010101";
                i_sclk_en    <= '0';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '1';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= '1';
                i_scl_out    <= '0';

                n_state <= s_Rd_A;

            when s_WrAck_A =>
                --state        <= "011000";
                i_sclk_en    <= '1';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= ack_in;
                i_scl_out    <= '0';

                n_state <= s_WrAck_B;

            when s_WrAck_B =>
                --state        <= "011001";
                i_sclk_en    <= '1';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= ack_in;
                i_scl_out    <= '1';

                n_state <= s_WrAck_C;

            when s_WrAck_C =>
                --state        <= "011010";
                i_sclk_en    <= '1';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= ack_in;
                i_scl_out    <= '1';

                n_state <= s_WrAck_D;

            when s_WrAck_D =>
                --state        <= "011011";
                i_sclk_en    <= '1';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= ack_in;
                i_scl_out    <= '0';

                -- do a STOP ?
                if (cmd_stop = '1') then
                    n_state <= s_Stop_A;
                else
                    -- we are DONE
                    n_state <= s_Done;
                end if;

            when s_Wr_A =>
                --state        <= "100000";
                i_sclk_en    <= '1';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= i_data_in;
                i_scl_out    <= '0';

                n_state <= s_Wr_B;

            when s_Wr_B =>
                --state        <= "100001";
                i_sclk_en    <= '1';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= i_data_in;
                i_scl_out    <= '1';

                n_state <= s_Wr_C;

            when s_Wr_C =>
                --state        <= "100010";
                i_sclk_en    <= '1';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= i_data_in;
                i_scl_out    <= '1';

                n_state <= s_Wr_D;

            when s_Wr_D =>
                --state        <= "100011";
                i_sclk_en    <= '1';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= i_data_in;
                i_scl_out    <= '0';

                if (i_ctr = 7) then
                    -- do ACKIN
                    n_state <= s_RdAck_A;
                else
                    -- increment bit counter
                    n_state <= s_Wr_E;
                end if;

            when s_Wr_E =>
                --state        <= "100100";
                i_sclk_en    <= '0';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '1';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= i_data_in;
                i_scl_out    <= '0';

                n_state <= s_Wr_A;

            when s_RdAck_A =>
                --state        <= "101000";
                i_sclk_en    <= '1';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= '1';
                i_scl_out    <= '0';

                n_state <= s_RdAck_B;

            when s_RdAck_B =>
                --state        <= "101001";
                i_sclk_en    <= '1';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= '1';
                i_scl_out    <= '1';

                n_state <= s_RdAck_C;

            when s_RdAck_C =>
                --state        <= "101010";
                i_sclk_en    <= '0';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '1';
                i_sda_out    <= '1';
                i_scl_out    <= '1';

                n_state <= s_RdAck_D;

            when s_RdAck_D =>
                --state        <= "101011";
                i_sclk_en    <= '1';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= '1';
                i_scl_out    <= '1';

                n_state <= s_RdAck_E;

            when s_RdAck_E =>
                --state        <= "101100";
                i_sclk_en    <= '1';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= '1';
                i_scl_out    <= '0';

                if (cmd_stop = '1') then
                    -- do a STOP
                    n_state <= s_Stop_A;
                else
                    -- we are DONE
                    n_state <= s_Done;
                end if;

            when s_Stop_A =>
                --state        <= "111000";
                i_sclk_en    <= '1';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= '0';
                i_scl_out    <= '0';

                n_state <= s_Stop_B;

            when s_Stop_B =>
                --state        <= "111001";
                i_sclk_en    <= '1';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= '0';
                i_scl_out    <= '1';

                n_state <= s_Stop_C;

            when s_Stop_C =>
                --state     <= "111010";
                i_sclk_en    <= '1';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '0';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= '1';
                i_scl_out    <= '1';

                n_state <= s_Done;

            when s_Done =>
                --state        <= "000010";
                i_sclk_en    <= '0';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '1';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= sda_in;
                i_scl_out    <= scl_in;

                n_state <= s_DoneAck;

            when s_DoneAck =>
                --state  	     <= "000011";
                i_sclk_en    <= '0';
                i_busy       <= '1';
                i_ctr_clr    <= '0';
                i_ctr_incr   <= '0';
                i_cmd_done   <= '1';
                i_dout_ld    <= '0';
                i_ack_out_ld <= '0';
                i_sda_out    <= sda_in;
                i_scl_out    <= scl_in;

                if (cmd_done_ack = '1') then
                    n_state <= s_Idle;
                end if;

        end case;

    end process i2c_comb;

end behavorial;
