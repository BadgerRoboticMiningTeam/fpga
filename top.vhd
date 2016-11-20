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
        led : out std_logic_vector(3 downto 0);
        btn: in std_logic_vector (0 to 1);
        ck_io: out std_logic_vector (0 downto 0);
        ck_scl : inout std_logic;
        ck_sda : inout std_logic);
end top;

architecture Behavioral of top is
    signal rst : std_logic;
    
    -- LEDs
    signal led_next : std_logic_vector(3 downto 0);
    
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
	
    component pwm is
    port (
		pwm_signal: out std_logic;
		period : in std_logic_vector(31 downto 0);
		duty: in std_logic_vector(31 downto 0); 
		clk: in std_logic;
		rst: in std_logic);
    end component;
    
    component i2c_slave_fsm is
        generic (
            SLAVE_ADDR : std_logic_vector(6 downto 0));
        port (
            scl : inout std_logic;
            sda : inout std_logic;
            in_progress : out std_logic;
            tx_done : out std_logic;
            tx_byte : in std_logic_vector(7 downto 0);
            rx_byte : out std_logic_vector(7 downto 0);
            rx_data_rdy : out std_logic;
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
	
	-- obuft_scl : obuft
	-- port map (
		-- o => ck_io(1),
		-- i => scl,
		-- t => '0');
	-- obuft_sda : obuft
	-- port map (
		-- o => ck_io(2),
		-- i => sda,
		-- t => '0');
	ck_scl <= scl;
	ck_sda <= sda;
	
    generator : pwm
    port map (
        pwm_signal => pwm_signal,
        period => std_logic_vector(to_unsigned(200000, 32)),
        duty => wid,
        clk => CLK100MHZ,
        rst => rst);
	
	i2c : i2c_slave_fsm
	generic map (
	    SLAVE_ADDR => "0101010")
	port map (
        scl => scl,
        sda => sda,
        in_progress => open,
        tx_done => open,
        tx_byte => i2c_tx_data,
        rx_byte => i2c_rx_data,
        rx_data_rdy => i2c_rx_data_rdy,
        clk => CLK100MHZ);
	
	process (CLK100MHZ) begin
		if (rising_edge(CLK100MHZ)) then
			if (rst = '1') then
				wid <= std_logic_vector(to_unsigned(150000, 32));
				led <= (others => '1');
				i2c_tx_data <= (others => '0');
			else
				wid <= wid_next;
			    led <= led_next;
			    i2c_tx_data <= i2c_tx_data_next;
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
        
        if (incr_reg(1) = '0' and incr_reg(0) = '1') then
            wid_next <= std_logic_vector(unsigned(wid) + 1000) ;
        elsif (decr_reg(1) = '0' and decr_reg(0) = '1') then
            wid_next <= std_logic_vector(unsigned(wid) - 1000);
        end if ;
        
        if (i2c_rx_data_rdy = '1') then
            i2c_tx_data_next <= i2c_rx_data;
            
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
    end process;
end Behavioral;
