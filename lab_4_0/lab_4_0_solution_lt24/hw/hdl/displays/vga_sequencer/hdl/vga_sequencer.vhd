
--+--------+------------+-------------------------------------------------------------------+
--| Offset |  Name      |                            Description                            |
--+--------+------------+-------------------------------------------------------------------+
--| 0x0    | CSR        |  [0] Enable/Disable                                               |
--| 0x1    | HBP        |  [15..0] Horizontal Back Porch (in DCLK)                          |
--| 0x2    | HFP        |  [15..0] Horizontal Front Porch (in DCLK)                         |
--| 0x3    | VBP        |  [15..0] Vertical Back Porch (in # lines)                         |
--| 0x4    | VFP        |  [15..0] Vertical Front Porch (in # lines)                        |
--| 0x5    | HDATA      |  [15..0] Horizontal data (in DCLK)                                |
--| 0x6    | VDATA      |  [15..0] [15..0] Vertical data (in # lines)                       |
--| 0x7    | HSync      |  [15..0] HSync width (in DCLK)                                    |
--| 0x8    | Vsync      |  [15..0] VSync width (in # lines)                                 |
--+--------+------------+-------------------------------------------------------------------+
--
-- As usual, the horizontal timings are specified in number of data clock
-- cycles, and the vertical timings are specified in number of lines.
--
-- For naming conventions, please refer to the following diagram:
--   +----------------------------------------------------------------------------------------------+-----
--   | A |    B     |                             C                                    |     D      | ...
--   +----------------------------------------------------------------------------------------------+-----
-- --+   +------------------------------------------------------------------------------------------+   +-
--   |   |                                                                                          |   |
--   +---+                                                                                          +---+
-- 
--   A is the pulse width
--   B is the back porch
--   C is the valid data
--   D is the front porch

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_sequencer is
    generic (
        HBP_DEFAULT   : positive := 12;
        HFP_DEFAULT   : positive := 18;
        VBP_DEFAULT   : positive := 8;
        VFP_DEFAULT   : positive := 20;
        HDATA_DEFAULT : positive := 240;
        VDATA_DEFAULT : positive := 320;
        HSYNC_DEFAULT : positive := 2;
        VSYNC_DEFAULT : positive := 7);
    port (
        pixclk : in std_logic;          -- A copy of the pixclk from the PLL
        clk    : in std_logic;          -- The clock of the bus
        reset  : in std_logic;

        -- Avalon-MM CSR Interface
        address     : in  std_logic_vector(4 downto 0);
        read, write : in  std_logic;
        readdata    : out std_logic_vector(31 downto 0);
        writedata   : in  std_logic_vector(31 downto 0);

        -- Avalon-ST sink Interface
        sink_data  : in  std_logic_vector(23 downto 0);
        sink_valid : in  std_logic;
        sink_ready : out std_logic;

        -- TFT Interface
        r     : out std_logic_vector(7 downto 0);
        g     : out std_logic_vector(7 downto 0);
        b     : out std_logic_vector(7 downto 0);
        hsync : out std_logic;
        vsync : out std_logic;
        de    : out std_logic;

        -- Indicates when we enter the front porch of the vertical sync.
        -- Used to flush the FIFO and restart reading the frame in memory.
        frame_sync : out std_logic);
end entity vga_sequencer;

architecture rtl of vga_sequencer is

    -- Both counters should be able to count up to the addition of any four 16-bit numbers.
    signal horizontal_counter, horizontal_max : unsigned(19 downto 0);
    constant HORIZONTAL_COUNTER_RESET         : unsigned(horizontal_counter'range) := to_unsigned(1, horizontal_counter'length);
    signal vertical_counter, vertical_max     : unsigned(19 downto 0);
    constant VERTICAL_COUNTER_RESET           : unsigned(horizontal_counter'range) := to_unsigned(1, horizontal_counter'length);

    -- Registers
    signal hbp, hfp, vbp, vfp, hdata_width, vdata_width, hsync_width, vsync_width : unsigned(15 downto 0);

    signal enabled : boolean;

    -- Output registers
    signal i_r     : std_logic_vector(7 downto 0);
    signal i_g     : std_logic_vector(7 downto 0);
    signal i_b     : std_logic_vector(7 downto 0);
    signal i_hsync : std_logic;
    signal i_vsync : std_logic;
    signal i_de    : std_logic;

    -- couting becomes true whenever enabled is true and sink_valid='1'
    signal counting : boolean;

    constant CSR_REG_OFST   : unsigned(address'range) := to_unsigned(0, address'length);
    constant HBP_REG_OFST   : unsigned(address'range) := to_unsigned(1, address'length);
    constant HFP_REG_OFST   : unsigned(address'range) := to_unsigned(2, address'length);
    constant VBP_REG_OFST   : unsigned(address'range) := to_unsigned(3, address'length);
    constant VFP_REG_OFST   : unsigned(address'range) := to_unsigned(4, address'length);
    constant HDATA_REG_OFST : unsigned(address'range) := to_unsigned(5, address'length);
    constant VDATA_REG_OFST : unsigned(address'range) := to_unsigned(6, address'length);
    constant HSYNC_REG_OFST : unsigned(address'range) := to_unsigned(7, address'length);
    constant VSYNC_REG_OFST : unsigned(address'range) := to_unsigned(8, address'length);
begin

    p_csr_write : process (clk, reset)
    begin
        if reset = '1' then
            enabled     <= false;
            hbp         <= to_unsigned(HBP_DEFAULT, hbp'length);
            hfp         <= to_unsigned(HFP_DEFAULT, hfp'length);
            vbp         <= to_unsigned(VBP_DEFAULT, vbp'length);
            vfp         <= to_unsigned(VFP_DEFAULT, vfp'length);
            hdata_width <= to_unsigned(HDATA_DEFAULT, hdata_width'length);
            vdata_width <= to_unsigned(VDATA_DEFAULT, vdata_width'length);
            hsync_width <= to_unsigned(HSYNC_DEFAULT, hsync_width'length);
            vsync_width <= to_unsigned(VSYNC_DEFAULT, vsync_width'length);

        elsif rising_edge(clk) then
            if write = '1' then
                case unsigned(address) is
                    -- Status
                    when CSR_REG_OFST =>
                        if writedata(0) = '1' then
                            enabled <= true;
                        else
                            enabled <= false;
                        end if;

                    -- HBP
                    when HBP_REG_OFST =>
                        hbp <= unsigned(writedata(15 downto 0));

                    -- HFP
                    when HFP_REG_OFST =>
                        hfp <= unsigned(writedata(15 downto 0));

                    -- VBP
                    when VBP_REG_OFST =>
                        vbp <= unsigned(writedata(15 downto 0));

                    -- VFP
                    when VFP_REG_OFST =>
                        vfp <= unsigned(writedata(15 downto 0));

                    -- HDATA  
                    when HDATA_REG_OFST =>
                        hdata_width <= unsigned(writedata(15 downto 0));

                    -- VDATA
                    when VDATA_REG_OFST =>
                        vdata_width <= unsigned(writedata(15 downto 0));

                    -- HSYNC
                    when HSYNC_REG_OFST =>
                        hsync_width <= unsigned(writedata(15 downto 0));

                    -- VSYNC
                    when VSYNC_REG_OFST =>
                        vsync_width <= unsigned(writedata(15 downto 0));


                    when others => null;
                end case;
            end if;
        end if;
    end process p_csr_write;

    p_csr_read : process (clk, reset)
    begin
        if reset = '1' then
            readdata <= (others => '0');
        elsif rising_edge(clk) then
            readdata <= (others => '0');
            if read = '1' then
                case unsigned(address) is
                    -- Status
                    when CSR_REG_OFST =>
                        readdata <= (others => '0');
                        if enabled then
                            readdata(0) <= '1';
                        end if;

                    -- HBP
                    when HBP_REG_OFST =>
                        readdata(15 downto 0) <= std_logic_vector(hbp);

                    -- HFP
                    when HFP_REG_OFST =>
                        readdata(15 downto 0) <= std_logic_vector(hfp);

                    -- VBP
                    when VBP_REG_OFST =>
                        readdata(15 downto 0) <= std_logic_vector(vbp);

                    -- VFP
                    when VFP_REG_OFST =>
                        readdata(15 downto 0) <= std_logic_vector(vfp);

                    -- HDATA  
                    when HDATA_REG_OFST =>
                        readdata(15 downto 0) <= std_logic_vector(hdata_width);

                    -- VDATA
                    when VDATA_REG_OFST =>
                        readdata(15 downto 0) <= std_logic_vector(vdata_width);

                    -- HSYNC
                    when HSYNC_REG_OFST =>
                        readdata(15 downto 0) <= std_logic_vector(hsync_width);

                    -- VSYNC
                    when VSYNC_REG_OFST =>
                        readdata(15 downto 0) <= std_logic_vector(vsync_width);

                    when others => null;
                end case;
            end if;
        end if;
    end process p_csr_read;

    horizontal_max <=
    resize(hsync_width, horizontal_max 'length) +
    resize(hbp, horizontal_max'length) +
    resize(hdata_width, horizontal_max'length) +
    resize(hfp, horizontal_max'length);

    vertical_max <=
    resize(vsync_width, horizontal_max 'length) +
    resize(vbp, horizontal_max'length) +
    resize(vdata_width, horizontal_max'length) +
    resize(vfp, horizontal_max'length);

    p_cnt_trigger : process (pixclk, reset)
    begin
        if reset = '1' then
            counting <= false;
        elsif rising_edge(pixclk) then

            if enabled and sink_valid = '1' then
                counting <= true;

            elsif not enabled then
                counting <= false;
            end if;

        end if;
    end process p_cnt_trigger;

    p_horizontal_count : process (pixclk, reset)
    begin
        if reset = '1' then
            horizontal_counter <= HORIZONTAL_COUNTER_RESET;
        elsif rising_edge(pixclk) then
            horizontal_counter <= HORIZONTAL_COUNTER_RESET;
            if counting and horizontal_counter < horizontal_max then
                horizontal_counter <= horizontal_counter + 1;
            end if;
        end if;
    end process p_horizontal_count;

    p_vertical_count : process (pixclk, reset)
    begin
        if reset = '1' then
            vertical_counter <= VERTICAL_COUNTER_RESET;
        elsif rising_edge(pixclk) then
            if counting then
                if horizontal_counter = horizontal_max then
                    if vertical_counter < vertical_max then
                        vertical_counter <= vertical_counter + 1;
                    else
                        vertical_counter <= VERTICAL_COUNTER_RESET;
                    end if;
                end if;
            else
                vertical_counter <= VERTICAL_COUNTER_RESET;
            end if;
        end if;
    end process p_vertical_count;

    p_hsync_vsync_gen : process (counting, horizontal_counter, hsync_width,
                                 vertical_counter, vsync_width)
    begin
        -- HSYNC generation
        i_hsync               <= '1';
        if horizontal_counter <= hsync_width then
            i_hsync <= '0';
        end if;

        -- VSYNC generation
        i_vsync             <= '1';
        if vertical_counter <= vsync_width then
            i_vsync <= '0';
        end if;

        if not counting then
            i_vsync <= '1';
            i_hsync <= '1';
        end if;

    end process p_hsync_vsync_gen;

    p_rgb_out : process (hbp, hdata_width, horizontal_counter, hsync_width,
                         sink_data, vbp, vdata_width, vertical_counter,
                         vsync_width)
    begin
        i_r        <= (others => '0');
        i_g        <= (others => '0');
        i_b        <= (others => '0');
        i_de       <= '0';
        sink_ready <= '0';
        frame_sync <= '0';

        if
        vertical_counter > (resize(vsync_width, vertical_counter'length) + resize(vbp, vertical_counter'length)) and
        vertical_counter   <= (resize(vsync_width, vertical_counter'length) + resize(vbp, vertical_counter'length) + resize(vdata_width, vertical_counter'length)) and
        horizontal_counter > (resize(hsync_width, horizontal_counter'length) + resize(hbp, horizontal_counter'length)) and
        horizontal_counter <= (resize(hsync_width, horizontal_counter'length) + resize(hbp, horizontal_counter'length) + resize(hdata_width, horizontal_counter'length))
        then
            i_de       <= '1';
            i_r        <= sink_data(23 downto 16);
            i_g        <= sink_data(15 downto 8);
            i_b        <= sink_data(7 downto 0);
            sink_ready <= '1';
        end if;

        if
        vertical_counter > (resize(vsync_width, vertical_counter'length) + resize(vbp, vertical_counter'length) + resize(vdata_width, vertical_counter'length))
        then
            frame_sync <= '1';
        end if;

    end process p_rgb_out;

    p_output_reg : process (pixclk, reset)
    begin
        if reset = '1' then
            r     <= (others => '0');
            g     <= (others => '0');
            b     <= (others => '0');
            de    <= '0';
            hsync <= '1';
            vsync <= '1';
        elsif rising_edge(pixclk) then
            de    <= i_de;
            r     <= i_r;
            g     <= i_g;
            b     <= i_b;
            vsync <= i_vsync;
            hsync <= i_hsync;
        end if;
    end process;

end architecture rtl;
