----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/09/2016 09:35:38 PM
-- Design Name: 
-- Module Name: async_multi - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity async_multi is
	Port (
		TxD_start : in std_logic;
		TxD_bytes : in std_logic_vector (3 downto 0);
		TxD_data : in std_logic_vector (63 downto 0);
		TxD : out std_logic;
		busy : out std_logic;
		clk : in std_logic;
		rst : in std_logic);
end async_multi;

architecture Behavioral of async_multi is
	type ctrl_state is (idle, writing);
	signal state, state_next : ctrl_state;
	signal byte_cnt, byte_cnt_next : std_logic_vector (3 downto 0);
	signal data, data_next : std_logic_vector (55 downto 0);
	-- uart transmitter signals
	signal async_TxD_start, async_TxD_start_next : std_logic;
	signal async_TxD_busy : std_logic;
	signal async_TxD_data, async_TxD_data_next : std_logic_vector (7 downto 0);

	component async_transmitter
		port (
			clk : in std_logic;
			TxD_start : in std_logic;
			TxD_data : in std_logic_vector (7 downto 0);
			TxD : out std_logic;
			TxD_busy : out std_logic);
	end component;
	
    component async_receiver
		port (
			clk : in std_logic;
			RxD : in std_logic;
			RxD_data_ready : out std_logic;
			RxD_data : out std_logic_vector(7 downto 0);
			-- rest are unused
			RxD_idle : out std_logic;
			RxD_endofpacket : out std_logic);
    end component;
begin
	busy <= '1' when (state = writing) or (async_TxD_busy = '1') else '0';

	transmitter : async_transmitter
	port map (
		clk => clk,
		TxD_start => async_TxD_start,
		TxD_data => async_TxD_data,
		TxD => TxD,
		TxD_busy => async_TxD_busy
	);
	
	process (clk) begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				state <= idle;
				byte_cnt <= (others => '0');
				data <= (others => '0');
				async_TxD_start <= '0';
				async_TxD_data <= (others => '0');
			else
				state <= state_next;
				byte_cnt <= byte_cnt_next;
				data <= data_next;
				async_TxD_start <= async_TxD_start_next;
				async_TxD_data <= async_TxD_data_next;
			end if;
		end if;
	end process;
	
	process (all) begin
		state_next <= state;
		byte_cnt_next <= byte_cnt;
		data_next <= data;
		async_TxD_start_next <= '0';
		async_TxD_data_next <= async_TxD_data;
	
		case state is
			when idle =>
				if (TxD_start = '1') and (async_TxD_busy = '0') then
					state_next <= writing;
					byte_cnt_next <= TxD_bytes;
					data_next <= TxD_data (55 downto 0);
					async_TxD_start_next <= '1';
					async_TxD_data_next <= TxD_data (63 downto 56);
				end if;
			when writing =>
				if (async_TxD_busy = '0') then
					if (async_TxD_start = '0') then
						data_next <= data sll 8;
						async_TxD_data_next <= data (55 downto 48);
						async_TxD_start_next <= '1';
						byte_cnt_next <= std_logic_vector(unsigned(byte_cnt) - 1);
					end if;
					
					if (byte_cnt = "0000") then
						state_next <= idle;
					end if;
				end if;
		end case;
	end process;
end Behavioral;
