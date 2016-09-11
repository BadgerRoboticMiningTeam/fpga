----------------------------------------------------------------------------------
-- Company: Badger Robotic Mining
-- Engineer: Zuodian Hu
-- 
-- Create Date: 09/07/2016 04:43:37 PM
-- Design Name: Quadrature Intepreter
-- Module Name: quadrature_reader - Behavioral
-- Project Name: FPGA Controls
-- Target Devices: General
-- Tool Versions: 2016.2
-- Description: Quadrature encoder reader module
-- 
-- Dependencies: None
-- 
-- Revision: 0.01
-- Revision 0.01 - File Created
-- Additional Comments: reading the output clears the internal quadrature count
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

----------------------------------------------------
-- Need to develop quadrature, and get PWM output --
----------------------------------------------------
entity quadrature_reader is
    Port (
        encode_a : in std_logic;
        encode_b : in std_logic;
        read_en : in std_logic;
		data_valid : out std_logic;
        data_out : out std_logic_vector (63 downto 0);
        clk : in std_logic;
		rst : in std_logic);
end quadrature_reader;

architecture Behavioral of quadrature_reader is
	-- data reading related signals
	signal data_valid_next : std_logic;
	signal data_out_reg, data_out_reg_next : std_logic_vector (63 downto 0);
    -- registers to keep count of encoder channel signal edges
	signal encode_a_reg, encode_b_reg : std_logic;
    signal displacement, displacement_next : std_logic_vector (63 downto 0);
	-- convenience signals to enable using case statements in the process (all) block
	signal enc_curr, enc_next : std_logic_vector (1 downto 0);
begin
	enc_curr (1) <= encode_a_reg;
	enc_curr (0) <= encode_b_reg;
	enc_next (1) <= encode_a;
	enc_next (0) <= encode_b;
	data_out <= data_out_reg;
	
	process (clk) begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				data_valid <= '0';
				data_out_reg <= (others => '0');
				encode_a_reg <= '0';
				encode_b_reg <= '0';
				displacement <= (others => '0');
			else
				data_valid <= data_valid_next;
				data_out_reg <= data_out_reg_next;
				encode_a_reg <= encode_a;
				encode_b_reg <= encode_b;
				displacement <= displacement_next;
			end if;
		end if;
	end process;
	
	process (all) begin
		data_valid_next <= '0';
		data_out_reg_next <= (others => '0');
		displacement_next <= displacement;
		
		-- increment or decrement displacement based on current and past encoder output
		case (enc_curr) is
			when "00" =>
				case (enc_next) is
					when "01" =>
						displacement_next <= std_logic_vector(signed(displacement) - 1);
					when "10" =>
						displacement_next <= std_logic_vector(signed(displacement) + 1);
					when others =>
						if (data_valid = '1') then
							data_valid_next <= '0';
						elsif (read_en = '1') then
							data_valid_next <= '1';
							data_out_reg_next <= displacement;
							displacement_next <= (others => '0');
						end if;
				end case;
			when "01" =>
				case (enc_next) is
					when "00" =>
						displacement_next <= std_logic_vector(signed(displacement) + 1);
					when "11" =>
						displacement_next <= std_logic_vector(signed(displacement) - 1);
					when others =>
						if (data_valid = '1') then
							data_valid_next <= '0';
						elsif (read_en = '1') then
							data_valid_next <= '1';
							data_out_reg_next <= displacement;
							displacement_next <= (others => '0');
						end if;
				end case;
			when "10" =>
				case (enc_next) is
					when "00" =>
						displacement_next <= std_logic_vector(signed(displacement) - 1);
					when "11" =>
						displacement_next <= std_logic_vector(signed(displacement) + 1);
					when others =>
						if (data_valid = '1') then
							data_valid_next <= '0';
						elsif (read_en = '1') then
							data_valid_next <= '1';
							data_out_reg_next <= displacement;
							displacement_next <= (others => '0');
						end if;
				end case;
			when "11" =>
				case (enc_next) is
					when "01" =>
						displacement_next <= std_logic_vector(signed(displacement) + 1);
					when "10" =>
						displacement_next <= std_logic_vector(signed(displacement) - 1);
					when others =>
						if (data_valid = '1') then
							data_valid_next <= '0';
						elsif (read_en = '1') then
							data_valid_next <= '1';
							data_out_reg_next <= displacement;
							displacement_next <= (others => '0');
						end if;
				end case;
            when others =>
                -- nothing
		end case;
	end process;
end Behavioral;