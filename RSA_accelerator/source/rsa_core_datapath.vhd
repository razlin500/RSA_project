--------------------------------------------------------------------------------
-- Author       : Oystein Gjermundnes
-- Organization : Norwegian University of Science and Technology (NTNU)
--                Department of Electronic Systems
--                https://www.ntnu.edu/ies
-- Course       : TFE4141 Design of digital systems 1 (DDS1)
-- Year         : 2018-2019
-- Project      : RSA accelerator
-- License      : This is free and unencumbered software released into the
--                public domain (UNLICENSE)
--------------------------------------------------------------------------------
-- Purpose:
--   RSA encryption core template. This core currently computes
--   C = M xor key_n
--
--   Replace/change this module so that it implements the function
--   C = M**key_e mod key_n.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity rsa_core_datapath is
	generic (
		-- Users to add parameters here
		C_BLOCK_SIZE          : integer := 256;
        C_NUM_CORES       :  integer := 2
	);

	port (
		-----------------------------------------------------------------------------
		-- Clocks and reset
		-----------------------------------------------------------------------------
		clk                    :  in std_logic;
		reset_n                :  in std_logic;
        encoders_msgin_valid   : in std_logic_vector(C_NUM_CORES-1 downto 0);
        encoders_msgout_ready   : in std_logic_vector(C_NUM_CORES-1 downto 0);
        encoders_msgin_ready   : out std_logic_vector(C_NUM_CORES-1 downto 0);
        encoders_msgout_valid   : out std_logic_vector(C_NUM_CORES-1 downto 0);
        encoders_output_select                 : in natural range 0 to C_NUM_CORES - 1;

		-----------------------------------------------------------------------------
		-- Slave msgin interface
		-----------------------------------------------------------------------------
	
		-- Message that will be sent out of the rsa_msgin module
		msgin_data              :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);

		-----------------------------------------------------------------------------
		-- Master msgout interface
		-----------------------------------------------------------------------------

		-- Message that will be sent out of the rsa_msgin module
		msgout_data             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);

		-----------------------------------------------------------------------------
		-- Interface to the register block
		-----------------------------------------------------------------------------
        signal key_e_d : std_logic_vector(C_BLOCK_SIZE - 1 downto 0);
        signal key_n : std_logic_vector(C_BLOCK_SIZE - 1 downto 0);
		rsa_status              : out std_logic_vector(31 downto 0)

	);
end rsa_core_datapath;

architecture rtl of rsa_core_datapath is

    type block_array_t is array (0 to C_NUM_CORES-1)
    of std_logic_vector(C_BLOCK_SIZE-1 downto 0);

    signal encoders_msgout : block_array_t; -- Message out lines for each of the encoders.


    begin
        
        generate_encoders : for k in 0 to C_NUM_CORES - 1 generate
            u_encoder : entity work.exponentiation
            generic map (C_block_size => C_BLOCK_SIZE)
            port map (
                valid_in     => encoders_msgin_valid(k),
                ready_in         => encoders_msgin_ready(k),
                modulus      => key_n,
                message  => msgin_data,
                valid_out => encoders_msgout_valid(k),
                ready_out => encoders_msgout_ready(k),
                key => key_e_d,
                result => encoders_msgout(k),
                clk          => clk,
                reset_n      => reset_n
            );

        end generate generate_encoders;
        

     msgout_data <= encoders_msgout(encoders_output_select);


end rtl;