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
        led : out std_logic_vector(0 downto 0);
        btn: in std_logic_vector (0 to 1);
        ck_io: out std_logic_vector (0 downto 0));
end top;

architecture Behavioral of top is
    signal rst : std_logic;
    signal incr : std_logic;
    signal decr : std_logic;
    signal wid, wid_next : std_logic_vector(31 downto 0);
    signal incr_reg, decr_reg: std_logic_vector(1 downto 0); 
    signal pwm_signal : std_logic;
	
    component pwm is
    port (
		pwm_signal: out std_logic;
		period : in std_logic_vector(31 downto 0);
		duty: in std_logic_vector(31 downto 0); 
		clk: in std_logic;
		rst: in std_logic);
    end component;
begin
	rst <= sw(0);
	led(0) <= rst;
	
    ibuf_btn : ibuf
    port map (
        i => btn(0),
        o => incr);
    ibuf_bnt1 : ibuf
    port map (
        i => btn(1),
        o => decr);
    obuf_pwm : obuf
    port map (
        i => pwm_signal,
        o => ck_io(0));
    
    generator : pwm
    port map (
        pwm_signal => pwm_signal,
        period => std_logic_vector(to_unsigned(200000, 32)),
        duty => wid,
        clk => CLK100MHZ,
        rst => rst);
	
	process (CLK100MHZ) begin
		if (rising_edge(CLK100MHZ)) then
			if (rst = '1') then
				wid <= std_logic_vector(to_unsigned(150000, 32));
			else
				wid <= wid_next;
			end if;
			incr_reg(0) <= incr;
			decr_reg(0) <= decr;
			incr_reg(1) <= incr_reg(0);
			decr_reg(1) <= decr_reg(0);
		end if ;
    end process;
            
    process (all) begin
        wid_next <= wid;
        
        if (incr_reg(1) = '0' and incr_reg(0) = '1') then
            wid_next <= std_logic_vector(unsigned(wid) + 1000) ;
        elsif (decr_reg(1) = '0' and decr_reg(0) = '1') then
            wid_next <= std_logic_vector(unsigned(wid) - 1000);
        end if ;
    end process;
end Behavioral;
