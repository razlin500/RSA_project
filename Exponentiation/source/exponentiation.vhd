library ieee;
use ieee.std_logic_1164.all;

entity exponentiation is
	generic (
		C_block_size : integer := 256
	);
	port (
		--input controll
		valid_in	: in STD_LOGIC;
		ready_in	: out STD_LOGIC;

		--input data
		message 	: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
		key 		: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );

		--ouput controll
		ready_out	: in STD_LOGIC;
		valid_out	: out STD_LOGIC;

		--output data
		result 		: out STD_LOGIC_VECTOR(C_block_size-1 downto 0);

		--modulus
		modulus 	: in STD_LOGIC_VECTOR(C_block_size-1 downto 0);

		--utility
		clk 		: in STD_LOGIC;
		reset_n 	: in STD_LOGIC
	);
end exponentiation;


architecture expBehave of exponentiation is
    signal C : STD_LOGIC_VECTOR(C_block_size-1 downto 0);
    signal P : STD_LOGIC_VECTOR(C_block_size-1 downto 0);
    signal counter : integer;
    signal mult1_enable : STD_LOGIC;
    signal mult1_valid : STD_LOGIC;
    signal mult2_enable : STD_LOGIC;
    signal mult2_valid : STD_LOGIC;
begin
    i1_multiplication : entity work.multiplication
        generic map (
        C_block_size_m => C_block_size
        )
        port map (
           A_in => P,
           B_in => P,
		   modulus => modulus,
           Input_valid => mult1_enable,
           result => A,
           result_valid => mult1_valid
        );
	
	i2_multiplication : entity work.multiplication
		generic map (
		C_block_size_m => C_block_size
		)
		port map (
		   A_in => A,
		   B_in => B,
		   modulus => modulus,
		   Input_valid => mult2_enable,
		   result => A,
		   result_valid => mult2_valid
		);
        
    A <= message when (valid_in='0') else A;
    result <= A;
	result <= message xor modulus;
	ready_in <= ready_out;
	valid_out <= valid_in;
end expBehave;
