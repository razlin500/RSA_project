----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.10.2026 17:00:20
-- Design Name: 
-- Module Name: multiplication - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity multiplication is
	generic (
		C_block_size_m : integer := 256
	);
    Port ( A_in : in STD_LOGIC_VECTOR(C_block_size_m-1 downto 0);
           B_in : in STD_LOGIC_VECTOR(C_block_size_m-1 downto 0);
           modulus : in STD_LOGIC_VECTOR(C_block_size_m-1 downto 0);
           Input_valid : in STD_LOGIC;
           result : out STD_LOGIC_VECTOR(C_block_size_m-1 downto 0);
           result_valid : out STD_LOGIC 
           );
end multiplication;

architecture Behavioral of multiplication is
signal A, B, P : STD_LOGIC_VECTOR(C_block_size_m-1 downto 0);
begin
    A <= A_in when (Input_valid = '1') else A;
    B <= B_in when (Input_valid = '1') else B;

    F <= A and B;


end Behavioral;
