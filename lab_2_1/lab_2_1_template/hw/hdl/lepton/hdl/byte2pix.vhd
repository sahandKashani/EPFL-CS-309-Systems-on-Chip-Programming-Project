-------------------------------------------------------------------------------
-- Title      : Byte stream to pixel converter for the Lepton Camera
-- Project    : PrSoC
-------------------------------------------------------------------------------
-- File       : byte2pix.vhd
-- Author     : Philemon Orphee Favrod  <pofavrod@lappc5.epfl.ch>
-- Company    :
-- Created    : 2016-03-21
-- Last update: 2017-03-19
-- Platform   :
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Converts a byte stream to a 14-bit pixel stream.
-------------------------------------------------------------------------------
-- Copyright (c) 2016
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-03-21  1.0      pofavrod        Created
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity byte2pix is
    port(
        clk, reset : in  std_logic;
        byte_data  : in  std_logic_vector(7 downto 0);
        byte_valid : in  std_logic;
        byte_sof   : in  std_logic;
        byte_eof   : in  std_logic;
        pix_data   : out std_logic_vector(13 downto 0);
        pix_valid  : out std_logic;
        pix_sof    : out std_logic;
        pix_eof    : out std_logic);

end byte2pix;

architecture rtl of byte2pix is
    signal last_sof : std_logic;
    signal msb      : std_logic_vector(5 downto 0);
    signal cnt      : std_logic;  -- used to skip msb sampling every other time
begin
    process(clk, reset)
    begin
        if reset = '1' then
            msb      <= (others => '0');
            cnt      <= '0';
            last_sof <= '0';
        elsif rising_edge(clk) then
            if byte_valid = '1' then
                if cnt = '0' then
                    msb      <= byte_data(5 downto 0);
                    last_sof <= byte_sof;
                end if;
                cnt <= not cnt;
            end if;
        end if;
    end process;

    process(clk, reset)
    begin
        if reset = '1' then
            pix_data  <= (others => '0');
            pix_valid <= '0';
            pix_sof   <= '0';
            pix_eof   <= '0';
        elsif rising_edge(clk) then
            pix_data  <= (others => '0');
            pix_valid <= '0';
            pix_sof   <= '0';
            pix_eof   <= '0';

            if byte_valid = '1' then
                if cnt = '1' then
                    pix_data  <= msb & byte_data;
                    pix_valid <= '1';
                    pix_sof   <= last_sof;
                    pix_eof   <= byte_eof;
                end if;
            end if;
        end if;
    end process;

end architecture rtl;
