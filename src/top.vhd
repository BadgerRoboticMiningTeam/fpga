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
        sw : in std_logic_vector(0 downto 0);
        
        led0_b : out std_logic;
        led0_g : out std_logic;
        led0_r : out std_logic;
        
        led1_b : out std_logic;
        led1_g : out std_logic;
        led1_r : out std_logic;
        
        led2_b : out std_logic;
        led2_g : out std_logic;
        led2_r : out std_logic;
        
        led3_b : out std_logic;
        led3_g : out std_logic;
        led3_r : out std_logic;
        
        led : out std_logic_vector(3 downto 0);
        btn: in std_logic_vector (3 downto 0);
        ck_io: inout std_logic_vector (2 downto 0);
        ck_scl : inout std_logic;
        ck_sda : inout std_logic;
        
        uart_rxd_out : out std_logic;
        uart_txd_in : in std_logic);
end top;

architecture Behavioral of top is
    signal rst : std_logic;
    
    -- LEDs
    signal led_next : std_logic_vector(3 downto 0);
	
	--signal state_debug_breakout, state_debug_breakout_prev_reg : std_logic_vector(3 downto 0);
    
    -- PWM demo signals
    signal incr : std_logic;
    signal decr : std_logic;
    signal wid, wid_next : std_logic_vector(31 downto 0);
    signal incr_reg, decr_reg: std_logic_vector(1 downto 0); 
    signal pwm_signal : std_logic;
    
    -- I2C signals
    signal scl, sda : std_logic;
    signal i2c_busy, i2c_tx_done, i2c_rx_data_rdy : std_logic;
    signal i2c_rx_data : std_logic_vector(7 downto 0);
    signal i2c_tx_data, i2c_tx_data_next : std_logic_vector(7 downto 0);
	
	-- quadrature encoder signals
	signal motor0_encode_a, motor0_encode_b : std_logic;
	signal quadr0_rd_en, quadr0_rd_valid : std_logic;
	signal quadr0_rd_data : std_logic_vector(63 downto 0);
	signal counter, counter_next : std_logic_vector(63 downto 0);
	
	signal uart_txd_start : std_logic;
	
    component pwm is
    port (
		pwm_signal: out std_logic;
		period : in std_logic_vector(31 downto 0);
		duty: in std_logic_vector(31 downto 0); 
		clk: in std_logic;
		rst: in std_logic);
    end component;
    
    -- component i2c_slave_fsm is
        -- generic (
            -- SLAVE_ADDR : std_logic_vector(6 downto 0));
        -- port (
            -- scl : inout std_logic;
            -- sda : inout std_logic;
            -- in_progress : out std_logic;
            -- tx_done : out std_logic;
            -- tx_byte : in std_logic_vector(7 downto 0);
            -- rx_byte : out std_logic_vector(7 downto 0);
            -- rx_data_rdy : out std_logic;
            -- clk : in std_logic);
    -- end component;
	
	component i2c_slave is
		generic (
			ADDR : std_logic_vector(6 downto 0) := "0101010");
		port (
			scl : inout std_logic;
			sda : inout std_logic;
			
			--state_debug_breakout : out std_logic_vector(3 downto 0);
			--state_debug_breakout_prev_reg : out std_logic_vector(3 downto 0);
			
			wr_data : in std_logic_vector(7 downto 0);
			wr_acked : out std_logic;
			rd_data : out std_logic_vector(7 downto 0);
			rd_valid : out std_logic;
			
			slave_selected : out std_logic;
			
			clk : in std_logic;
			rst : in std_logic);
	end component;
	
	component quadrature_reader is
		port (
			encode_a : in std_logic;
			encode_b : in std_logic;
			read_en : in std_logic;
			data_valid : out std_logic;
			data_out : out std_logic_vector(63 downto 0);
			clk : in std_logic;
			rst : in std_logic);
	end component;
	
	component async_transmitter is
		port (
			TxD_start : in std_logic;
			TxD_data : in std_logic_vector(7 downto 0);
			TxD : out std_logic;
			TxD_busy : out std_logic;
			clk : in std_logic);
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
    obuf_pwm : obuf
    port map (
        i => pwm_signal,
        o => ck_io(0));
	ibuf_quad0a : ibuf
	port map (
		i => ck_io(1),
		o => motor0_encode_a);
	ibuf_quad0b : ibuf
	port map (
		i => ck_io(2),
		o => motor0_encode_b);
	
	ck_scl <= scl;
	ck_sda <= sda;
	
	led0_r <= rst or pwm_signal;
	led0_g <= pwm_signal;
	--led0_b <= '1' when scl = '1' else '0';
	
	--led1_r <= state_debug_breakout(1);
	--led1_g <= state_debug_breakout_prev_reg(1);
    --led1_b <= '1' when sda = '1' else '0';
	
	--led2_r <= state_debug_breakout(2);
	--led2_g <= state_debug_breakout_prev_reg(2);
    --led2_b <= '1' when sda = '1' else '0';
	
	--led3_r <= state_debug_breakout(3);
	--led3_g <= state_debug_breakout_prev_reg(3);
    --led3_b <= '1' when sda = '1' else '0';
	
    generator : pwm
    port map (
        pwm_signal => pwm_signal,
        period => std_logic_vector(to_unsigned(200000, 32)),
        duty => wid,
        clk => CLK100MHZ,
        rst => rst
	);
	
	quadr_rd_0 : quadrature_reader
	port map (
		encode_a => motor0_encode_a,
		encode_b => motor0_encode_b,
		read_en => quadr0_rd_en,
		data_valid => quadr0_rd_valid,
		data_out => quadr0_rd_data,
		clk => CLK100MHZ,
		rst => rst
	);
	
	-- i2c : i2c_slave_fsm
	-- generic map (
	    -- SLAVE_ADDR => "0101010")
	-- port map (
        -- scl => scl,
        -- sda => sda,
        -- in_progress => led2_r,
        -- tx_done => led2_g,
        -- tx_byte => i2c_tx_data,
        -- rx_byte => i2c_rx_data,
        -- rx_data_rdy => i2c_rx_data_rdy,
        -- clk => CLK100MHZ
	-- );
	-- led2_b <= i2c_rx_data_rdy;
	
	i2c : i2c_slave
	generic map (
		ADDR => "0101010")
	port map (
		scl => scl,
		sda => sda,
		--state_debug_breakout => state_debug_breakout,
		--state_debug_breakout_prev_reg => state_debug_breakout_prev_reg,
		wr_data => i2c_tx_data,
		wr_acked => open,
		rd_data => i2c_rx_data,
		rd_valid => i2c_rx_data_rdy,
		slave_selected => open,
		clk => CLK100MHZ,
		rst => rst
	);
	
	uart_tx : async_transmitter
	port map (
		TxD_start => uart_txd_start,
		TxD_data => quadr0_rd_data(7 downto 0),
		TxD => uart_rxd_out,
		TxD_busy => open,
		clk => CLK100MHZ
	);
	
	process (CLK100MHZ) begin
		if (rising_edge(CLK100MHZ)) then
			if (rst = '1') then
				wid <= std_logic_vector(to_unsigned(150000, 32));
				led <= (others => '1');
				i2c_tx_data <= x"F0";
				counter <= std_logic_vector(to_unsigned(100000000, 64));
			else
				wid <= wid_next;
			    led <= led_next;
			    i2c_tx_data <= i2c_tx_data_next;
				counter <= counter_next;
			end if;
			
			incr_reg(0) <= incr;
			decr_reg(0) <= decr;
			incr_reg(1) <= incr_reg(0);
			decr_reg(1) <= decr_reg(0);
		end if ;
    end process;
	
    process (all) begin
        wid_next <= wid;
        led_next <= led;
        i2c_tx_data_next <= i2c_tx_data;
		
		if (unsigned(counter) = 0) then
			counter_next <= std_logic_vector(to_unsigned(100000000, 64));
			quadr0_rd_en <= '1';
		else
			counter_next <= std_logic_vector(unsigned(counter) - 1);
			quadr0_rd_en <= '0';
		end if;
        
		-- PWM buttons demo
        if (incr_reg(1) = '0' and incr_reg(0) = '1') then
            wid_next <= std_logic_vector(unsigned(wid) + 1000) ;
        elsif (decr_reg(1) = '0' and decr_reg(0) = '1') then
            wid_next <= std_logic_vector(unsigned(wid) - 1000);
        end if ;
        
		-- I2C LED demo
        if (i2c_rx_data_rdy = '1') then
            case (i2c_rx_data) is
                when x"BE" =>
                    led_next <= not led;
                when x"EF" =>
                    led_next(0) <= not led(0);
                when x"DE" =>
                    led_next(1) <= not led(1);
                when x"AD" =>
                    led_next(2) <= not led(2);
                when x"FE" =>
                    led_next(3) <= not led(3);
                when others =>
            end case;
        end if;
		
		-- Quadrature demo
		if (quadr0_rd_valid = '1') then
			uart_txd_start <= '1';
		else
			uart_txd_start <= '0';
		end if;
    end process;
end Behavioral;
