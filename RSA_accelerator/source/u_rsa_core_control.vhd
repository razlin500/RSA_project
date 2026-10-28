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
entity rsa_core_control is
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
end rsa_core_control;

architecture rtl of rsa_core_control is

type fsm_state is (
		--fill inn with necesarry states
		AWAITING_INPUT, CALCULATING, HOLDING_OUTPUT, ERROR
	);    
        signal state_r, state_nxt : fsm_state;
        signal hold_input, hold_output, calc_done, msg_last_iter : std_logic;
       
begin
    u_rsa_core_datapath : entity work.rsa_core_datapath
        generic map (C_BLOCK_SIZE => C_BLOCK_SIZE)
        port map(
            clk => clk,
            reset_n => reset_n,
            hold_input => hold_input,
            hold_output => hold_output,
            calc_done => calc_done,
            msgin_data => msgin_data,
            msgout_data => msgout_data,
            key_e_d => key_e_d,
            key_n => key_n
        ); 
    rsa_status   <= (others => '0');

	main_fsm_process : process (state_r, calc_done, msgin_valid, msgout_ready, msgin_last)
    begin
        hold_input <= '0';
        state_nxt <= state_r;
        hold_output <= '0';
        msgout_valid <= '0';
        msgin_ready <= '0';
        msgout_last <= '0';
        case(state_r) is
            when AWAITING_INPUT =>
                msgin_ready <= '1';
                if (msgin_valid and msgin_ready) then 
                    msgout_last  <= msgin_last;
                    msgin_ready <= '0';
                    msg_last_iter <= msgin_last;
                    state_nxt <= CALCULATING;
                    hold_input <= '1';
                end if;
            when CALCULATING =>
                    hold_input <= '1';
                    if (calc_done) then
                        state_nxt <= HOLDING_OUTPUT;
                    end if;
            when HOLDING_OUTPUT =>
                hold_input <= '1';
                hold_output <= '1';
                msgout_valid <= '1';
                msgout_last <= msg_last_iter;
                if (msgout_ready) then
                    state_nxt <= AWAITING_INPUT;
                    msgin_ready <= '0';
                    end if;
            when others =>
                state_nxt <= ERROR;
        end case;


    end process main_fsm_process;

    update_state : process (clk, reset_n)
    begin
        if (reset_n = '0') then
            state_r <= AWAITING_INPUT;
        elsif (rising_edge(clk)) then
            state_r <= state_nxt;
        end if;
    end process update_state;



end rtl;
