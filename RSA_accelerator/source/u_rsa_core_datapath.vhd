
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity rsa_core_datapath is
	generic (
		-- Users to add parameters here
		C_BLOCK_SIZE          : integer := 256
	);
	port (		
		clk                    :  in std_logic;
		reset_n                :  in std_logic;
        hold_input              : in std_logic;
        hold_output             : in std_logic;
        calc_done               : out std_logic;

		msgin_data              :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
	
		msgout_data             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
	
		key_e_d                 :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
        
		key_n                   :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0)

	);
end rsa_core_datapath;

architecture rtl of rsa_core_datapath is

        signal msgin_data_r, msgout_data_r, key_e_d_r, key_n_r              :  std_logic_vector(C_BLOCK_SIZE-1 downto 0);
        
begin
    encoder : entity work.exponentiation
        generic map (C_block_size => C_BLOCK_SIZE)
        port map (
            valid_in     => hold_input,
            ready_in         => open,
            modulus      => key_n_r,
            message  => msgin_data_r,
            valid_out => calc_done,
            ready_out => open,
            key => key_e_d_r,
            clk          => clk,
            reset_n      => reset_n,
        );

    update_data : process (clk, reset_n)
    begin
        if (reset_n = '0') then
            msgin_data_r   <= (others => '0');
            key_e_d_r <= (others => '0');
            key_n_r <= (others => '0');
        elsif (rising_edge(clk)) then
            if (not hold_input) then
                msgin_data_r <= msgin_data;
                key_e_d_r <= key_e_d;
                key_n_r <= key_n;
            elsif (not hold_output) then
                msgout_data_r <= msgout_data;
            end if;
        end if;
    end process update_data;



end rtl;
