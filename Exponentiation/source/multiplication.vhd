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
        C_BLOCK_SIZE : integer := 256
    );
    port (
        multiplicand_in         : in  std_logic_vector(C_BLOCK_SIZE-1 downto 0);
        multiplier_in         : in  std_logic_vector(C_BLOCK_SIZE-1 downto 0);
        modulus      : in  std_logic_vector(C_BLOCK_SIZE-1 downto 0);
        input_valid  : in  std_logic;
        clk          : in  std_logic;
        reset_n      : in  std_logic;
        result       : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
        result_valid : out std_logic
    );
end multiplication;

architecture rtl of multiplication is
    signal multiplicand_r, multiplier_r : unsigned(C_BLOCK_SIZE-1 downto 0) := (others => '0');
    signal product_r            : unsigned(C_BLOCK_SIZE-1 downto 0) := (others => '0');
    signal counter_r      : integer range 0 to C_BLOCK_SIZE := C_BLOCK_SIZE;
    signal done_r         : std_logic := '0';

    -- C+3 bits: top bit acts as sign/borrow flag after subtraction
    signal addend, t, t1, t2 : unsigned(C_BLOCK_SIZE+2 downto 0);
    signal n1, n2            : unsigned(C_BLOCK_SIZE+2 downto 0);
begin
    n1 <= resize(unsigned(modulus), C_BLOCK_SIZE+3);
    n2 <= shift_left(n1, 1);

    addend <= resize(multiplicand_r, C_BLOCK_SIZE+3) when multiplier_r(C_BLOCK_SIZE-1) = '1' else (others => '0');

    t  <= shift_left(resize(product_r, C_BLOCK_SIZE+3), 1) + addend;   -- 2P + b_i*A
    t1 <= t - n1;
    t2 <= t - n2;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                counter_r <= C_BLOCK_SIZE;
                done_r    <= '0';
            elsif input_valid = '1' then
                multiplicand_r   <= unsigned(multiplicand_in);
                multiplier_r   <= unsigned(multiplier_in);
                product_r       <= (others => '0');
                counter_r <= 0;
                done_r    <= '0';
            elsif counter_r < C_BLOCK_SIZE then
                multiplier_r   <= shift_left(multiplier_r, 1);
                counter_r <= counter_r + 1;
                if counter_r = C_BLOCK_SIZE-1 then
                    done_r <= '1';
                end if;
                if t2(C_BLOCK_SIZE+2) = '0' then          -- t >= 2n
                    product_r <= t2(C_BLOCK_SIZE-1 downto 0);
                elsif t1(C_BLOCK_SIZE+2) = '0' then       -- t >= n
                    product_r <= t1(C_BLOCK_SIZE-1 downto 0);
                else
                    product_r <= t(C_BLOCK_SIZE-1 downto 0);
                end if;
            end if;
        end if;
    end process;

    result       <= std_logic_vector(product_r);
    result_valid <= done_r;
end rtl;