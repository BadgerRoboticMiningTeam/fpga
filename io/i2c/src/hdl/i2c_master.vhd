----------------------------------------------------------------------------------
-- Company: Badger Robotic Mining Team
-- Engineer: Zuodian Hu
-- 
-- Create Date: 10/25/2016 09:47:33 AM
-- Design Name: I2C Master
-- Module Name: i2c_master - Behavioral
-- Project Name: Lunar Testbench
-- Target Devices: All
-- Tool Versions: Vivado WebPack 2016.3
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity i2c_master is
	generic (
		SYS_CLK : integer := 100000000;
		I2C_CLK : integer := 1000000);
	port (
		slave_addr : in std_logic_vector(6 downto 0);
		byte_cnt : in std_logic_vector(3 downto 0);
		io_en : in std_logic;
		rd_wr : in std_logic;
		
		rd_data : out std_logic_vector(7 downto 0);
		wr_data : in std_logic_vector(7 downto 0);
		io_busy : out std_logic;
		
		scl : inout std_logic;
		sda : inout std_logic;
		
		busy : out std_logic;
		
		clk : in std_logic;
		rst : in std_logic);
end i2c_master;

architecture Behavioral of i2c_master is
	type i2c_state is (idle, stall, address, transceive, stop);
	
	signal state, state_next : i2c_state;
	
	signal slave, slave_next : std_logic_vector(6 downto 0);
begin
	process (clk) begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				state <= idle;
				slave <= (others => '0');
			else
				state <= state_next;
				slave <= slave_next;
			end if;
		end if;
	end process;
	
	process (all) begin
		
		
		-- I2C state machine
		case state is
			when idle =>
				if (io_en = '1') then
					
				end if;
			when stall =>
			when address =>
			when transceive =>
			when stop =>
		end case;
	end process;
end Behavioral;
