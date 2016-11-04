----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/27/2016 07:50:39 PM
-- Design Name: 
-- Module Name: pwm - Behavioral
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
--library UNISIM;
--use UNISIM.VComponents.all;

entity pwm is
	Port (
		pwm_signal: out std_logic;
		clock: in std_logic; 
		width: in std_logic_vector(15 downto 0);
		reset: in std_logic);
end pwm;

architecture Behavioral of pwm is
    signal counter, counter_next: std_logic_vector(15 downto 0);
    signal pwm_signal_next: std_logic;
begin
    process (clock) begin
		if (rising_edge(clock)) then
			if (reset = '1') then
				counter <=( others => '0');
				pwm_signal <= '0';
			else
				counter <= counter_next;
				pwm_signal <= pwm_signal_next;
			end if;
		end if ;
    end process;
	
	process (all) begin
		if (unsigned(counter) /= 0) then
			counter_next <= std_logic_vector(unsigned(counter) - 1);
			pwm_signal_next <= pwm_signal;
		else
		      if ( pwm_signal = '0')then 
			     counter_next <= width;
			     pwm_signal_next <= not pwm_signal;
              else
                  counter_next <= std_logic_vector(50 - unsigned(width));
                  pwm_signal_next <= not pwm_signal;
              end if;
		end if;
	end process;
end Behavioral;
