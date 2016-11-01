entity motor_control is
	port (
		-- generated pwm signal
		pwm_out : out std_logic;
		-- input set by I2C parser
		pwm_duty_cycle : in std_logic_vector(15 downto 0);
		pwm_freq : in std_logic_vector(15 downto 0);
		
		-- quadrature inputs, read by internal quadrature reader
		quadrature_a : in std_logic;
		quadrature_b : in std_logic;
		
		-- control loop parameters set by I2C parser
		-- getting all three implemented is probably pretty ambitious
		kp : in std_logic_vector(15 downto 0);
		ki : in std_logic_vector(15 downto 0);
		kd : in std_logic_vector(15 downto 0);
		
		clk : in std_logic;
		rst : in std_logic);
end motor_control;
