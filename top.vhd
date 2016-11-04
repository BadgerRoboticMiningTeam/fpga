----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/03/2016 08:07:06 PM
-- Design Name: 
-- Module Name: top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity top is
    Port (
        CLK100MHZ :in std_logic;
        sw: in std_logic_vector(0 downto 0);
        btn: in std_logic_vector (0 to 1);
        ck_io: out std_logic_vector (0 downto 0));
end top;

architecture Behavioral of top is
    signal rst : std_logic;
    signal incr : std_logic;
    signal decr : std_logic;
    signal wid, wid_next : std_logic_vector(15 downto 0);
    signal incr_reg, decr_reg: std_logic; 
    component pwm is
    Port (
            pwm_signal: out std_logic;
            clock: in std_logic; 
            width: in std_logic_vector(15 downto 0);
            reset: in std_logic);
    end component;
begin
    ibuf_sw : ibuf
    port map (
        i => sw(0),
        o => rst);
    ibuf_btn : ibuf
     port map (
        i => btn(0),
        o => incr);
    ibuf_bnt1 : ibuf
    port map (
        i => btn(1),
        o => decr);
    generator : pwm
     port map (
         pwm_signal => ck_io(0),
        clock => CLK100MHZ,
        width => wid,
        reset => sw(0));
process (CLK100MHZ) begin
                if (rising_edge(CLK100MHZ)) then
                    if (rst = '1') then
                        wid <= (others => '0');
                    else
                        wid <= wid_next;
                    end if;
                end if ;
            end process;
            
    process (all) begin
        wid_next <= wid;
        
        if (incr_reg /= incr and incr = '1' ) then 
            wid_next <= std_logic_vector( unsigned(wid) + 1) ;
        elsif (decr_reg /= decr and decr = '1') then
            wid_next <= std_logic_vector(unsigned(wid) - 1);
        end if ;
    end process;

end Behavioral;
