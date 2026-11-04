library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- RL-binary modular exponentiation: result = message^key mod modulus
--   P := M, C := 1
--   for each bit e_i of key, LSB first, until the remaining exponent is 0:
--       if e_i = 1 then C := C*P mod n
--       P := P*P mod n
-- Both modular multiplications run in parallel on the same (old) P.
-- Assumes message < modulus.
entity exponentiation is
    generic (
        C_BLOCK_SIZE : integer := 256
    );
    port (
        -- input control
        valid_in    : in  std_logic;
        ready_in    : out std_logic;

        -- input data
        message     : in  std_logic_vector(C_BLOCK_SIZE-1 downto 0);
        key         : in  std_logic_vector(C_BLOCK_SIZE-1 downto 0);

        -- output control
        ready_out   : in  std_logic;
        valid_out   : out std_logic;

        -- output data
        result      : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);

        -- modulus
        modulus     : in  std_logic_vector(C_BLOCK_SIZE-1 downto 0);

        -- utility
        clk         : in  std_logic;
        reset_n     : in  std_logic
    );
end exponentiation;

architecture expBehave of exponentiation is
    type state_t is (S_IDLE, S_START, S_WAIT, S_DONE);
    signal state     : state_t := S_IDLE;
    signal state_nxt : state_t := S_IDLE;

    signal P_r : unsigned(C_BLOCK_SIZE-1 downto 0) := (others => '0');
    signal C_r : unsigned(C_BLOCK_SIZE-1 downto 0) := (others => '0');
    signal e_r : unsigned(C_BLOCK_SIZE-1 downto 0) := (others => '0');
    signal n_r : std_logic_vector(C_BLOCK_SIZE-1 downto 0) := (others => '0');

    signal mult_start : std_logic;
    signal sq_result  : std_logic_vector(C_BLOCK_SIZE-1 downto 0);  -- P*P mod n
    signal prod_result: std_logic_vector(C_BLOCK_SIZE-1 downto 0);  -- C*P mod n
    signal sq_valid   : std_logic;
    signal prod_valid : std_logic;

    signal e_nxt : unsigned(C_BLOCK_SIZE-1 downto 0);
begin

    -- squares P
    i1_multiplication : entity work.multiplication
        generic map (C_BLOCK_SIZE => C_BLOCK_SIZE)
        port map (
            multiplicand_in         => std_logic_vector(P_r),
            multiplier_in         => std_logic_vector(P_r),
            modulus      => n_r,
            input_valid  => mult_start,
            clk          => clk,
            reset_n      => reset_n,
            result       => sq_result,
            result_valid => sq_valid
        );

    -- multiplies C by P
    i2_multiplication : entity work.multiplication
        generic map (C_BLOCK_SIZE => C_BLOCK_SIZE)
        port map (
            multiplicand_in         => std_logic_vector(P_r),
            multiplier_in         => std_logic_vector(C_r),
            modulus      => n_r,
            input_valid  => mult_start,
            clk          => clk,
            reset_n      => reset_n,
            result       => prod_result,
            result_valid => prod_valid
        );

    mult_start <= '1' when state_nxt = S_START else '0';
    e_nxt     <= shift_right(e_r, 1);

    ready_in  <= '1' when state_nxt = S_IDLE else '0';
    valid_out <= '1' when state_nxt = S_DONE else '0';
    result    <= std_logic_vector(C_r);

    process(clk)
    begin
        if rising_edge(clk) then
            state <= state_nxt;
            if reset_n = '0' then
                state_nxt <= S_IDLE;
            else
                case state is
                    when S_IDLE =>
                        if valid_in = '1' then
                            P_r <= unsigned(message);
                            e_r <= unsigned(key);
                            n_r <= modulus;
                            C_r <= to_unsigned(1, C_BLOCK_SIZE);
                            state_nxt <= S_START;
                        end if;

                    when S_START =>
                        -- multipliers latch their operands on this edge
                        state_nxt <= S_WAIT;

                    when S_WAIT =>
                        if sq_valid = '1' and prod_valid = '1' then
                            P_r <= unsigned(sq_result);
                            if e_r(0) = '1' then
                                C_r <= unsigned(prod_result);
                            end if;
                            e_r <= e_nxt;
                            if e_nxt = 0 then
                                state_nxt <= S_DONE;
                            else
                                state_nxt <= S_START;
                            end if;
                        end if;

                    when S_DONE =>
                        if ready_out = '1' then
                            state_nxt <= S_IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;

end expBehave;
