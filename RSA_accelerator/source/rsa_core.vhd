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
entity rsa_core is
	generic (
		-- Users to add parameters here
		C_BLOCK_SIZE          : integer := 256
	);
	port (
		-----------------------------------------------------------------------------
		-- Clocks and reset
		-----------------------------------------------------------------------------
		clk                    :  in std_logic;
		reset_n                :  in std_logic;

		-----------------------------------------------------------------------------
		-- Slave msgin interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		msgin_valid             : in std_logic;
		-- Slave ready to accept a new message
		msgin_ready             : out std_logic;
		-- Message that will be sent out of the rsa_msgin module
		msgin_data              :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- Indicates boundary of last packet
		msgin_last              :  in std_logic;

		-----------------------------------------------------------------------------
		-- Master msgout interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		msgout_valid            : out std_logic;
		-- Slave ready to accept a new message
		msgout_ready            :  in std_logic;
		-- Message that will be sent out of the rsa_msgin module
		msgout_data             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- Indicates boundary of last packet
		msgout_last             : out std_logic;

		-----------------------------------------------------------------------------
		-- Interface to the register block
		-----------------------------------------------------------------------------
		key_e_d                 :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		key_n                   :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		rsa_status              : out std_logic_vector(31 downto 0)

	);
end rsa_core;

architecture rtl of rsa_core is

constant C_NUM_CORES : natural := 2;
signal encoders_msgin_valid : std_logic_vector(C_NUM_CORES-1 downto 0) := (others => '0');
signal encoders_msgin_ready : std_logic_vector(C_NUM_CORES-1 downto 0) := (others => '0');
signal encoders_msgout_ready : std_logic_vector(C_NUM_CORES-1 downto 0) := (others => '0');
signal encoders_msgout_valid : std_logic_vector(C_NUM_CORES-1 downto 0) := (others => '0');
signal encoders_output_select :  natural range 0 to C_NUM_CORES - 1 := 0;
      
begin
	u_rsa_core_control : entity work.rsa_core_control
	generic map (
            C_BLOCK_SIZE => C_BLOCK_SIZE,
            C_NUM_CORES  => C_NUM_CORES
        )
        port map (
            clk                   => clk,
            reset_n               => reset_n,
			msgin_ready => msgin_ready,
			msgin_last => msgin_last,
			msgin_valid => msgin_valid,
			msgout_valid => msgout_valid,
			msgout_ready => msgout_ready,
			msgout_last => msgout_last,
            encoders_msgin_valid  => encoders_msgin_valid,
            encoders_msgin_ready  => encoders_msgin_ready,
            encoders_msgout_valid => encoders_msgout_valid,
            encoders_msgout_ready => encoders_msgout_ready,
            encoders_output_select => encoders_output_select,
			rsa_status => rsa_status
    
        );

	u_rsa_core_datapath : entity work.rsa_core_datapath
        generic map (
            C_BLOCK_SIZE => C_BLOCK_SIZE,
            C_NUM_CORES  => C_NUM_CORES
        )
        port map (
            clk                   => clk,
            reset_n               => reset_n,
            encoders_msgin_valid  => encoders_msgin_valid,
            encoders_msgin_ready  => encoders_msgin_ready,
            encoders_msgout_valid => encoders_msgout_valid,
            encoders_msgout_ready => encoders_msgout_ready,
            msgin_data            => msgin_data,
            encoders_output_select  => encoders_output_select,
            msgout_data           => msgout_data,
            key_e_d               => key_e_d,
            key_n                 => key_n
        );


	
end rtl;
