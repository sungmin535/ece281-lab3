--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm_tb.vhd (TEST BENCH)
--| AUTHOR(S)     : Capt Phillip Warner
--| CREATED       : 03/2017
--| DESCRIPTION   : This file tests the thunderbird_fsm modules.
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : thunderbird_fsm_enumerated.vhd, thunderbird_fsm_binary.vhd, 
--|				   or thunderbird_fsm_onehot.vhd
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  
entity thunderbird_fsm_tb is
end thunderbird_fsm_tb;

architecture test_bench of thunderbird_fsm_tb is 

	component thunderbird_fsm is 
	  port(
            i_clk     : in  std_logic;
            i_reset   : in  std_logic;
            i_left    : in  std_logic;
            i_right   : in  std_logic;
            o_lights_L: out std_logic_vector(2 downto 0);
            o_lights_R: out std_logic_vector(2 downto 0)
	  );
	end component thunderbird_fsm;

    signal w_clk       : std_logic := '0';
    signal w_reset     : std_logic := '0';
    signal w_left      : std_logic := '0';
    signal w_right     : std_logic := '0';
    signal w_lights_L  : std_logic_vector(2 downto 0) := "000";
    signal w_lights_R  : std_logic_vector(2 downto 0) := "000";

    constant k_clk_period : time := 10 ns;

	
	
begin
	-- PORT MAPS ----------------------------------------
    uut: thunderbird_fsm port map (
          i_clk      => w_clk,
          i_reset    => w_reset,
          i_left     => w_left,
          i_right    => w_right,
          o_lights_L => w_lights_L,
          o_lights_R => w_lights_R
        );
	-----------------------------------------------------
	
	-- PROCESSES ----------------------------------------	
    -- Clock process ------------------------------------
    clk_proc: process
    begin
        while True loop
            w_clk <= '0';
            wait for k_clk_period/2;
            w_clk <= '1';
            wait for k_clk_period/2;
        end loop;
    end process clk_proc;
	-----------------------------------------------------
	
	-- Test Plan Process --------------------------------
    test_proc: process
    begin
        ----------------------------------------------------------------------------
        -- 1) Apply Reset
        ----------------------------------------------------------------------------
        -- Bring reset high to ensure FSM is in known OFF state.
        w_reset <= '1';
        wait for k_clk_period*2;  -- Wait a few cycles
        w_reset <= '0';
        wait for k_clk_period*2;
        
        -- Check that outputs are OFF after reset
        assert (w_lights_L = "000" and w_lights_R = "000") 
            report "Reset test failed: FSM outputs not OFF after reset."
            severity failure;

        ----------------------------------------------------------------------------
        -- 2) Right Turn Signal Test
        ----------------------------------------------------------------------------
        -- Drive i_right='1' for enough cycles to pass through R1->R2->R3->OFF
        w_left  <= '0';
        w_right <= '1';
        
        -- Wait enough cycles so we can see R1->R2->R3->OFF pattern
        -- (Number of cycles depends on your FSM delays; ensure it completes)
        wait for k_clk_period*8;  
        
        -- Turn off i_right
        w_right <= '0';
        wait for k_clk_period*4;  -- Wait a few cycles to confirm final OFF
        
        assert (w_lights_R = "000") 
            report "Right turn sequence test failed: Right lights not returned to OFF."
            severity failure;

        ----------------------------------------------------------------------------
        -- 3) Left Turn Signal Test
        ----------------------------------------------------------------------------
        -- Drive i_left='1' for enough cycles to pass through L1->L2->L3->OFF
        w_left  <= '1';
        wait for k_clk_period*8;
        
        -- Turn off i_left
        w_left  <= '0';
        wait for k_clk_period*4;
        
        assert (w_lights_L = "000") 
            report "Left turn sequence test failed: Left lights not returned to OFF."
            severity failure;

        ----------------------------------------------------------------------------
        -- 4) Hazard Test (Both Signals)
        ----------------------------------------------------------------------------
        -- Drive both i_left and i_right high for hazard mode (OFF <-> ON).
        w_left  <= '1';
        w_right <= '1';
        wait for k_clk_period*6;  -- Observe hazard pattern toggles

        -- Check that lights are ON at some point in hazard mode
        assert (w_lights_L = "111" and w_lights_R = "111")
            report "Hazard test failed: Lights not all ON during hazard."
            severity failure;

        ----------------------------------------------------------------------------
        -- 5) Mid-Sequence Input Change
        ----------------------------------------------------------------------------
        -- Example: switch from hazard to right turn in the middle,
        -- then quickly back to hazard. This checks if the FSM can 
        -- properly handle 'immediate' changes. 
        w_left <= '0';        -- Turn off left, still right='1'
        wait for k_clk_period*3;  -- Let the FSM progress some
        w_left <= '1';        -- Turn left back on -> hazard
        wait for k_clk_period*3;

        -- We expect hazard state again
        assert (w_lights_L = "111" and w_lights_R = "111")
            report "Midsequence change test failed: FSM did not return to hazard."
            severity failure;

        -- Turn off both signals
        w_left  <= '0';
        w_right <= '0';
        wait for k_clk_period*4;

        ----------------------------------------------------------------------------
        -- End of Test
        ----------------------------------------------------------------------------
        report "All tests completed successfully." severity note;
        wait;  -- Stop simulation
    end process test_proc;

end test_bench;
