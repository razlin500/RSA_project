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
use IEEE.NUMERIC_STD.ALL;

-- Bit-serial (MSB-first) interleaved modular multiplication:
--   result = A_in * B_in mod modulus, one bit of B per clock cycle.
-- Assumes A_in, B_in < modulus, and modulus held stable during the operation.
-- Input_valid is a start pulse: operands are latched on the clock edge where it is '1'.
-- result_valid is cleared on start/reset and set when the result is ready (stays set).
entity multiplication is
    generic (
        C_block_size_m : integer := 256
    );
    port (
        A_in         : in  std_logic_vector(C_block_size_m-1 downto 0);
        B_in         : in  std_logic_vector(C_block_size_m-1 downto 0);
        modulus      : in  std_logic_vector(C_block_size_m-1 downto 0);
        Input_valid  : in  std_logic;
        clk          : in  std_logic;
        reset_n      : in  std_logic;
        result       : out std_logic_vector(C_block_size_m-1 downto 0);
        result_valid : out std_logic
    );
end multiplication;

architecture rtl of multiplication is
    constant C : integer := C_block_size_m;

    signal A_reg, B_reg : unsigned(C-1 downto 0) := (others => '0');
    signal P            : unsigned(C-1 downto 0) := (others => '0');
    signal counter      : integer range 0 to C := C;
    signal done         : std_logic := '0';

    -- C+3 bits: top bit acts as sign/borrow flag after subtraction
    signal addend, t, t1, t2 : unsigned(C+2 downto 0);
    signal n1, n2            : unsigned(C+2 downto 0);
begin
    n1 <= resize(unsigned(modulus), C+3);
    n2 <= shift_left(n1, 1);

    addend <= resize(A_reg, C+3) when B_reg(C-1) = '1' else (others => '0');

    t  <= shift_left(resize(P, C+3), 1) + addend;   -- 2P + b_i*A
    t1 <= t - n1;
    t2 <= t - n2;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                counter <= C;
                done    <= '0';
            elsif Input_valid = '1' then
                A_reg   <= unsigned(A_in);
                B_reg   <= unsigned(B_in);
                P       <= (others => '0');
                counter <= 0;
                done    <= '0';
            elsif counter < C then
                B_reg   <= shift_left(B_reg, 1);
                counter <= counter + 1;
                if counter = C-1 then
                    done <= '1';
                end if;
                if t2(C+2) = '0' then          -- t >= 2n
                    P <= t2(C-1 downto 0);
                elsif t1(C+2) = '0' then       -- t >= n
                    P <= t1(C-1 downto 0);
                else
                    P <= t(C-1 downto 0);
                end if;
            end if;
        end if;
    end process;

    result       <= std_logic_vector(P);
    result_valid <= done;
end rtl;