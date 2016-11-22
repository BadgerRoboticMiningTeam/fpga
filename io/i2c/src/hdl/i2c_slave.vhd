----------------------------------------------------------------------------------
-- Company: Badger Robotic Mining Team
-- Engineer: Zuodian Hu
-- 
-- Create Date: 11/18/2016 07:22:03 AM
-- Design Name: I2C Slave
-- Module Name: i2c_slave - Behavioral
-- Project Name: Lunar Test Bench
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

entity i2c_slave is
	generic (
		ADDR : std_logic_vector(6 downto 0) := "0101010");
	port (
		-- internally inferrs open-drain for these pins
		scl : inout std_logic;
		sda : inout std_logic;
		
		wr_data : in std_logic_vector(7 downto 0);
		wr_acked : out std_logic;
		rd_data : out std_logic_vector(7 downto 0);
		rd_valid : out std_logic;
		
		slave_selected : out std_logic;
		
		-- DEBUG
		-- break out state machine current and previous states
		--state_debug_breakout : out std_logic_vector(3 downto 0);
		--state_debug_breakout_prev_reg : out std_logic_vector(3 downto 0);
		
		clk : in std_logic;
		rst : in std_logic);
end i2c_slave;

architecture Behavioral of i2c_slave is
	type i2c_state is (
		idle,
		start,
		rd_addr,
		receiving,
		sending,
		send_stall,
		ack_req_rd,
		ack_req_wr,
		ack_rcv,
		get_ack
	);
	
	signal state, state_next : i2c_state;
	
	signal state_debug_breakout_prev : std_logic_vector(3 downto 0);
	
	signal scl_i_reg, scl_i : std_logic;
	signal sda_i_reg, sda_i : std_logic;
	signal scl_o_reg, scl_o_reg_next : std_logic;
	signal sda_o : std_logic;
	
	signal posedge_scl, negedge_scl : std_logic;
	signal posedge_sda, negedge_sda : std_logic;
	
	signal scl_wr_en, sda_wr_en : std_logic;
	
	signal acked, acked_next : std_logic;
	
	signal rd_data_next : std_logic_vector(7 downto 0);
	signal wr_data_buff, wr_data_buff_next : std_logic_vector(7 downto 0);
	
	signal bit_cntdwn, bit_cntdwn_next : std_logic_vector(3 downto 0);
begin
	process (clk) begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				state <= idle;
				scl_o_reg <= '1';
				acked <= '0';
				rd_data <= (others => '0');
				wr_data_buff <= (others => '0');
				bit_cntdwn <= (others => '1');
			else
				state <= state_next;
				scl_o_reg <= scl_o_reg_next;
				acked <= acked_next;
				rd_data <= rd_data_next;
				wr_data_buff <= wr_data_buff_next;
				bit_cntdwn <= bit_cntdwn_next;
			end if;
			
			-- DEBUG
			-- store state machine previous state, assigned on state change
			--state_debug_breakout_prev_reg <= state_debug_breakout_prev;
			
			-- SIMULATION
			-- resolve weak '1' in sumulation
			-- if (scl /= '0') then
				-- scl_i <= '1';
			-- else
				-- scl_i <= '0';
			-- end if;
			-- if (sda /= '0') then
				-- sda_i <= '1';
			-- else
				-- sda_i <= '0';
			-- end if;
			
			-- latch SCL and SDA line values
			scl_i <= scl;
			sda_i <= sda;
			scl_i_reg <= scl_i;
			sda_i_reg <= sda_i;
		end if;
	end process;
	
	-- infer open-drain I/O
	scl <= 'Z' when scl_o_reg = '1' or scl_wr_en = '0' else '0';
	sda <= 'Z' when sda_o = '1' or sda_wr_en = '0' else '0';
	
	-- convenience signals
	posedge_scl <= '1' when scl_i_reg = '0' and scl_i = '1' else '0';
	negedge_scl <= '1' when scl_i_reg = '1' and scl_i = '0' else '0';
	posedge_sda <= '1' when sda_i_reg = '0' and sda_i = '1' else '0';
	negedge_sda <= '1' when sda_i_reg = '1' and sda_i = '0' else '0';
	
	-- enables for data and clock output
	-- TODO: clock stretching
	scl_wr_en <= '0';
	sda_wr_en <=
		'1' when state = sending or state = ack_rcv or state = ack_req_rd or state = ack_req_wr else
		'0';
	
	-- status outputs
	slave_selected <= '1' when (state /= idle and state /= start) else '0';
	wr_acked <= '1' when (state = get_ack and posedge_scl = '1' and sda_i = '0') else '0';
	rd_valid <= '1' when (state = receiving and state_next = ack_rcv) else '0';
	
	-- I2C state machine
	process (all) begin
		state_next <= state;
		scl_o_reg_next <= scl_o_reg;
		acked_next <= acked;
		rd_data_next <= rd_data;
		wr_data_buff_next <= wr_data_buff;
		bit_cntdwn_next <= bit_cntdwn;
		
		-- DEBUG
		-- break out state machine state
		--state_debug_breakout_prev <= state_debug_breakout_prev_reg;
		
		case (state) is
			when idle =>
				--state_debug_breakout <= x"A";
				
				sda_o <= '1';
				if (negedge_sda = '1' and scl_i_reg = '1') then
					state_next <= start;
					--state_debug_breakout_prev <= x"A";
				end if;
			when start =>
				--state_debug_breakout <= x"1";
				
				sda_o <= '1';
				if (posedge_sda = '1') then
					-- bad starting condition
					state_next <= idle;
					--state_debug_breakout_prev <= x"1";
				elsif (negedge_scl) = '1' then
					state_next <= rd_addr;
					--state_debug_breakout_prev <= x"1";
					bit_cntdwn_next <= x"8";
				end if;
			when rd_addr =>
				--state_debug_breakout <= x"2";
				
				sda_o <= '1';
				if (negedge_scl = '1' and unsigned(bit_cntdwn) = 0) then
					if (rd_data(7 downto 1) /= ADDR) then
						state_next <= idle;
						--state_debug_breakout_prev <= x"2";
					elsif (rd_data(0) = '1') then
						state_next <= ack_req_rd;
						--state_debug_breakout_prev <= x"2";
					else
						state_next <= ack_req_wr;
						--state_debug_breakout_prev <= x"2";
					end if;
				elsif (posedge_scl = '1') then
					rd_data_next <= rd_data(6 downto 0) & sda_i_reg;
					bit_cntdwn_next <= std_logic_vector(unsigned(bit_cntdwn) - 1);
				end if;
			when ack_req_rd =>
				--state_debug_breakout <= x"3";
				
				sda_o <= '0';
				if (negedge_scl = '1') then
					state_next <= sending;
					--state_debug_breakout_prev <= x"3";
					bit_cntdwn_next <= x"8";
				end if;
			when ack_req_wr =>
				--state_debug_breakout <= x"4";
				
				sda_o <= '0';
				if (negedge_scl = '1') then
					state_next <= receiving;
					--state_debug_breakout_prev <= x"4";
					bit_cntdwn_next <= x"8";
				end if;
			when sending =>
				--state_debug_breakout <= x"5";
				
				sda_o <= wr_data_buff(to_integer(unsigned(bit_cntdwn) - 1));
				if (negedge_scl = '1') then
					if (unsigned(bit_cntdwn) = 1) then
						state_next <= get_ack;
						--state_debug_breakout_prev <= x"5";
						acked_next <= '0';
					end if;
					bit_cntdwn_next <= std_logic_vector(unsigned(bit_cntdwn) - 1);
				end if;
				
				-- end condition
				if (scl_i_reg = '1' and scl_i = '1' and posedge_sda = '1') then
					state_next <= idle;
					--state_debug_breakout_prev <= x"5";
				end if;
			when receiving =>
				--state_debug_breakout <= x"6";
				
				sda_o <= '1';
				if (posedge_scl = '1') then
					rd_data_next <= rd_data(6 downto 0) & sda_i_reg;
					bit_cntdwn_next <= std_logic_vector(unsigned(bit_cntdwn) - 1);
				end if;
				if (negedge_scl = '1' and unsigned(bit_cntdwn) = 0) then
					state_next <= ack_rcv;
					--state_debug_breakout_prev <= x"6";
				end if;
				
				-- end condition
				if (scl_i_reg = '1' and scl_i = '1' and posedge_sda = '1') then
					state_next <= idle;
					--state_debug_breakout_prev <= x"6";
				end if;
			when get_ack =>
				--state_debug_breakout <= x"7";
				
				sda_o <= '1';
				if (posedge_scl = '1') then
					if (sda_i_reg = '0') then
						acked_next <= '1';
					end if;
					
					state_next <= send_stall;
					--state_debug_breakout_prev <= x"7";
				end if;
			when send_stall =>
				--state_debug_breakout <= x"8";
				
				sda_o <= '1';
				-- TODO: clean up logic in this state
				if (negedge_scl = '1') then
					if (acked = '1') then
						state_next <= sending;
						bit_cntdwn_next <= x"8";
						wr_data_buff_next <= wr_data;
					else
						state_next <= idle;
					end if;
					
					--state_debug_breakout_prev <= x"8";
				end if;
			when ack_rcv =>
				--state_debug_breakout <= x"9";
				
				sda_o <= '0';
				if (negedge_scl = '1') then
					state_next <= receiving;
					bit_cntdwn_next <= x"8";
					--state_debug_breakout_prev <= x"9";
				end if;
		end case;
	end process;
end Behavioral;
