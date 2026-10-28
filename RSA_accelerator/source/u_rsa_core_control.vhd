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
		C_BLOCK_SIZE          : integer := 256;
        C_NUM_CORES       :  integer := 2
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
		msgin_valid             : in std_logic; -- Note; distribute pairs of msgins to different exponentiation modules.
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
    signal encoders_msgin_valid : std_logic_vector(C_NUM_CORES-1 downto 0);
    signal encoders_msgin_ready : std_logic_vector(C_NUM_CORES-1 downto 0);
    signal encoders_msgout_ready : std_logic_vector(C_NUM_CORES-1 downto 0);
    signal encoders_msgout_valid : std_logic_vector(C_NUM_CORES-1 downto 0);
    signal encoders_msgout_last : std_logic_vector(C_NUM_CORES-1 downto 0);
    signal encoder_output_select :  natural range 0 to C_NUM_CORES - 1;
    signal encoder_input_select :  natural range 0 to C_NUM_CORES - 1;
    type block_array_t is array (0 to C_NUM_CORES-1)
    of std_logic_vector(C_BLOCK_SIZE-1 downto 0);

    signal encoders_msgout : block_array_t; -- Message out lines for each of the encoders.

    subtype queue_node_t is natural range 0 to C_NUM_CORES - 1;
    type queue_t is array (0 to C_NUM_CORES - 1) of queue_node_t; -- Linked list; one element points to the next.
    signal output_queue : queue_t; -- Queue that holds what order the outputs need to be sent in.
    signal last_queue_node : queue_node_t := 0; -- The last node we added, i.e. the one we need to send back the latest.
    signal current_queue_node : queue_node_t := 0; -- The current node we're waiting for the result of, to send to the output.

    signal any_ready : std_logic;
    begin
        
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
            output_select         => encoder_output_select,
            msgout_data           => msgout_data,
            key_e_d               => key_e_d,
            key_n                 => key_n
        );
        
        encoder_output_select <= current_queue_node; -- By default, the current_queue node should always be routed to the output (though msgout_valid will only be 1 when calculations are done)
        
        any_ready <= or encoders_msgin_ready; -- Check if any encoder is available
         find_available_encoder : process (encoders_msgin_ready) begin -- Finds the new encoder to be employed for calculations.
            encoder_input_select <= 0; -- Default val.
            for k in 0 to C_NUM_CORES - 1 loop
                if encoders_msgin_ready(k) = '1' then
                    encoder_input_select <= k;
                    exit;
                    end if;
                end loop;
        end process find_available_encoder;

        route_msgin : process (msgin_valid, any_ready, encoder_input_select) begin -- Ensures encoder with idx 'encoder_input_select' actually loads the msgin_data and msgin_last...
            encoders_msgin_valid <= (others => '0');
            msgin_ready <= any_ready;
            if any_ready = '1' then
                if msgin_valid = '1' then
                    msgin_ready <= '1';
                    encoders_msgin_valid(encoder_input_select) <= '1';
                    encoders_msgout_last(encoder_input_select) <= msgin_last;
                end if;
            end if;
        end process route_msgin;

        route_msgout : process (msgout_ready, encoders_msgout_valid, current_queue_node, encoders_msgout_last) begin -- Ensures current_queue_node actually is sent to the output if the output is ready, and the calculation is done.
            msgout_valid <= '0';
            encoders_msgout_ready <= (others => '0');
            msgout_last <= encoders_msgout_last(current_queue_node);
           if encoders_msgout_valid(current_queue_node) then
                msgout_valid <= '1';
                if msgout_ready then
                    encoders_msgout_ready(current_queue_node) <= '1'; -- Actually send the output. 
                    end if;
            end if;

            end process route_msgout;

        
        queue_update : process (clk, reset_n) begin -- Send the newly employed encoder to the end of the queue (since it has now read relevant data)
            if reset_n = '0' then
                last_queue_node <= 0;
                current_queue_node <= 0;
                output_queue <= (others => 0);
            elsif rising_edge(clk) then
                if msgin_valid = '1' then 
                    if any_ready = '1' then -- Move to the next element, so we can check for new available input to operate on.
                        output_queue(last_queue_node) <= encoder_input_select;
                        last_queue_node <= encoder_input_select; -- Have to wait to do this, since otherwise we would try to queue all in one clock cycle, which obv. is invalid
                        end if;
                    end if;

                if msgout_valid = '1' then
                    if msgout_ready = '1' then
                        if msgout_last = '0' then -- Only if next node exists.
                            current_queue_node <= output_queue(current_queue_node); -- Move on to the output of the next node
                            end if;
                        end if;
                    end if;

                end if;
            end process queue_update;
        

end rtl;