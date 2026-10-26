----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.10.2026 13:39:25
-- Design Name: 
-- Module Name: D_FlipFlop - Behavioral
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

entity D_FlipFlop is
generic (
    C_block_size : integer := 256
);
    Port ( D : in STD_LOGIC (C_block_size-1 downto 0);
           clk : in STD_LOGIC;
           Q : out STD_LOGIC (C_block_size-1 downto 0) );
end D_FlipFlop;

architecture Behavioral of D_FlipFlop is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            Q <= D;
        end if;
    end process;

end Behavioral;
