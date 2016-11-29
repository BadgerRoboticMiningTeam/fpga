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
use IEEE.NUMERIC_STD.ALL;

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
		io_init : in std_logic;
		rd_wr : in std_logic; -- 1 for read, 0 for write
		
		rd_data : out std_logic_vector(7 downto 0);
		rd_ack : in std_logic;
		rd_ack_sent : out std_logic;
		rd_ack_failed : out std_logic;
		
		wr_data : in std_logic_vector(7 downto 0);
		wr_acked : out std_logic;
		io_busy : out std_logic;
		
		-- these pins are iused to read and drive two open-drain lines
		scl_in : in std_logic;
		scl_out : out std_logic;
		sda_in : in std_logic;
		sda_out : out std_logic;
		
		busy : out std_logic;
		
		clk : in std_logic;
		rst : in std_logic);
end i2c_master;

architecture Behavioral of i2c_master is
	type i2c_state is (i2c_idle, i2c_transceive, i2c_stall, i2c_stop);
	
	signal state, state_next : i2c_state;
	
	
	signal scl_wr_reg, scl_wr_reg_next : std_logic;
	signal sda_wr_reg, sda_wr_reg_next : std_logic;
	signal scl_rd_reg, sda_rd_reg : std_logic;
	
	signal slave, slave_next : std_logic_vector(6 downto 0);
	
	signal i2c_clk_cntdown, i2c_clk_cntdown_next : std_logic_vector(15 downto 0);
	signal bit_cntdown, bit_cntdown_next : std_logic_vector(3 downto 0);
	signal byte_cntdown, byte_cntdown_next : std_logic_vector(3 downto 0);
	signal io_buff, io_buff_next : std_logic_vector(7 downto 0);
	signal addressing, addressing_next : std_logic;
	signal rd_wr_reg, rd_wr_reg_next : std_logic;
begin
	process (clk) begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				state <= i2c_idle;
				-- since SCL and SDA are open-drain, this leaves both lines undriven
				scl_wr_reg <= '1';
				sda_wr_reg <= '1';
				slave <= (others => '0');
				
				i2c_clk_cntdown <= std_logic_vector(to_unsigned(SYS_CLK/(2*I2C_CLK), 16));
				bit_cntdown <= (others => '1');
				io_buff <= (others => '0');
				addressing <= '0';
				rd_wr_reg <= '0';
			else
				state <= state_next;
				scl_wr_reg <= scl_wr_reg_next;
				sda_wr_reg <= sda_wr_reg_next;
				slave <= slave_next;
				
				i2c_clk_cntdown <= i2c_clk_cntdown_next;
				bit_cntdown <= bit_cntdown_next;
				io_buff <= io_buff_next;
				addressing <= addressing_next;
				rd_wr_reg <= rd_wr_reg_next;
			end if;
			
			scl_rd_reg <= scl_in;
			sda_rd_reg <= sda_in;
		end if;
	end process;
	
	posedge_scl <= '1' when (scl_rd_reg = '0' and scl_in = '1') else '0';
	negedge_scl <= '1' when (scl_rd_reg = '1' and scl_in = '0') else '0';
	-- I2C bits should be sampled when SCL is high, and changed when SCL is low. 
	-- For simplicity, we simply use the rising and falling edges of SCL instead of the midpoint
	-- between clock edges. 
	wr_trigger <=
		'1' when ((posedge_scl = '1') and ((rd_wr_reg = '0') or (addressing = '1'))) else
		'0';
	rd_trigger <=
		'1' when ((negedge_scl = '1') and ((rd_wr_reg = '1') and (addressing = '0'))) else
		'0';
	
	process (all) begin
		state_next <= state;
		scl_wr_reg_next <= scl_wr_reg;
		sda_wr_reg_next <= sda_wr_reg;
		slave_next <= slave;
		bit_cntdown_next <= bit_cntdown;
		io_buff_next <= io_buff;
		addressing_next <= addressing;
		rd_wr_reg_next <= rd_wr_reg;
		
		-- I2C clock counter, free running when not idle
		if ((unsigned(i2c_clk_cntdown) = 0) or (state = i2c_idle)) then
			i2c_clk_cntdown_next <= std_logic_vector(to_unsigned(SYS_CLK/(2*I2C_CLK), 16));
		elsif (state /= i2c_idle) then
			i2c_clk_cntdown_next <= std_logic_vector(unsigned(i2c_clk_cntdown) - 1);
		end if;
		
		-- I2C state machine
		case state is
			when i2c_idle =>
				-- TODO: 10-bit addressing
				if (io_init = '1') then
					state_next <= i2c_transceive;
					sda_wr_reg_next <= '0';
					slave_next <= slave_addr;
					addressing_next <= '1';
					bit_cntdown_next <= x"8";
					io_buff_next <= slave_addr & rd_wr;
					rd_wr_reg_next <= rd_wr;
				else
					-- since SCL and SDA are open-drain, this leaves both lines undriven
					scl_wr_reg_next <= '1';
					sda_wr_reg_next <= '1';
				end if;
			when i2c_transceive =>
				-- drive the SCL during this state only
				-- TODO: clock stretching
				if (unsigned(i2c_clk_cntdown) = 0) then
					scl_wr_reg_next <= not scl_wr_reg;
				end if;
				
				-- end condition, having written all bits
				if (posedge_scl = '1') then
					bit_cntdown_next <= std_logic_vector(unsigned(bit_cntdown) - 1);
				end if;
				if (unsigned(bit_cntdown) = 0) then
					state_next <= i2c_stall;
					byte_cntdown_next <= std_logic_vector(unsigned(byte_cntdown) - 1);
				end if;
				
				if (wr_trigger = '1') then
					sda_wr_reg_next <= io_buff(7);
				end if;
				if (rd_trigger = '1') then
					io_buff_next <= io_buff(6 downto 0) & sda_in;
				end if;
			when i2c_stall =>
			when i2c_stop =>
		end case;
	end process;
end Behavioral;
