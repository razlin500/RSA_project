----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.10.2026 16:06:40
-- Design Name: 
-- Module Name: PISO - Behavioral
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
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity PISO is
    Port ( D : in STD_LOGIC_VECTOR (255 downto 0);
           Q : out STD_LOGIC;
           clk : in STD_LOGIC;
           enable : in STD_LOGIC);
end PISO;

architecture Behavioral of PISO is

signal D_reg : STD_LOGIC_VECTOR (255 downto 0);

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if enable = '1' then
                D_reg <= D;
                Q <= D_reg(255);
            end if;
            if enable = '0' then
                Q <= D_reg(255);
                D_reg <= shift_right(unsigned(D_reg), 1);
            end if;
        end if;
    end process;

end Behavioral;
