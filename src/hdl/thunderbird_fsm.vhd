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
--| FILENAME      : thunderbird_fsm.vhd
--| AUTHOR(S)     : Capt Phillip Warner, Capt Dan Johnson
--| CREATED       : 03/2017 Last modified 06/25/2020
--| DESCRIPTION   : This file implements the ECE 281 Lab 2 Thunderbird tail lights
--|					FSM using enumerated types.  This was used to create the
--|					erroneous sim for GR1
--|
--|					Inputs:  i_clk 	 --> 100 MHz clock from FPGA
--|                          i_left  --> left turn signal
--|                          i_right --> right turn signal
--|                          i_reset --> FSM reset
--|
--|					Outputs:  o_lights_L (2:0) --> 3-bit left turn signal lights
--|					          o_lights_R (2:0) --> 3-bit right turn signal lights
--|
--|					Upon reset, the FSM by defaults has all lights off.
--|					Left ON - pattern of increasing lights to left
--|						(OFF, LA, LA/LB, LA/LB/LC, repeat)
--|					Right ON - pattern of increasing lights to right
--|						(OFF, RA, RA/RB, RA/RB/RC, repeat)
--|					L and R ON - hazard lights (OFF, ALL ON, repeat)
--|					A is LSB of lights output and C is MSB.
--|					Once a pattern starts, it finishes back at OFF before it 
--|					can be changed by the inputs
--|					
--|
--|                 xxx State Encoding key
--|                 --------------------
--|                  State | Encoding
--|                 --------------------
--|                  OFF   | 
--|                  ON    | 
--|                  R1    | 
--|                  R2    | 
--|                  R3    | 
--|                  L1    | 
--|                  L2    | 
--|                  L3    | 
--|                 --------------------
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : None
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

-----------------------
--| One-Hot State Encoding key
--| -------------------
--| State | Encoding
--| -------------------
--| OFF   | 10000000
--| ON    | 01000000
--| R1    | 00100000
--| R2    | 00010000
--| R3    | 00001000
--| L1    | 00000100
--| L2    | 00000010
--| L3    | 00000001
--| --------------------
------------------------  

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
 
entity thunderbird_fsm is 
  port(
        i_clk, i_reset  : in    std_logic;
        i_left, i_right : in    std_logic;
        o_lights_L      : out   std_logic_vector(2 downto 0);
        o_lights_R      : out   std_logic_vector(2 downto 0)
	
  );
end thunderbird_fsm;

architecture thunderbird_fsm_arch of thunderbird_fsm is 

-- CONSTANTS ------------------------------------------------------------------
    constant OFF_STATE : std_logic_vector(7 downto 0) := "10000000";
    constant ON_STATE  : std_logic_vector(7 downto 0) := "01000000";
    constant R1_STATE  : std_logic_vector(7 downto 0) := "00100000";
    constant R2_STATE  : std_logic_vector(7 downto 0) := "00010000";
    constant R3_STATE  : std_logic_vector(7 downto 0) := "00001000";
    constant L1_STATE  : std_logic_vector(7 downto 0) := "00000100";
    constant L2_STATE  : std_logic_vector(7 downto 0) := "00000010";
    constant L3_STATE  : std_logic_vector(7 downto 0) := "00000001";

    signal current_state : std_logic_vector(7 downto 0) := OFF_STATE;
    signal next_state : std_logic_vector(7 downto 0);
    signal hazard : std_logic;

    
begin

	-- CONCURRENT STATEMENTS --------------------------------------------------------	
	
    ---------------------------------------------------------------------------------
	
	-- PROCESSES --------------------------------------------------------------------
    process(current_state, i_left, i_right)
    begin
        hazard <= i_left and i_right;
        next_state <= current_state;
        
        if current_state = OFF_STATE then
            if (i_left = '0' and i_right = '0') then next_state <= OFF_STATE;--stays in OFF
            elsif (i_left = '0' and i_right = '1') then next_state <= R1_STATE; --right turn signal
            elsif (i_left = '1' and i_right = '0') then next_state <= L1_STATE; --left turn signal
            else next_state <= ON_STATE; --Hazard
            end if;
            
        elsif current_state = ON_STATE then
            if hazard = '1' then next_state <= ON_STATE; --stay in hazard state if both signals are still high
            else next_state <= OFF_STATE; --Otherwise go to OFF
            end if;
            
        elsif current_state = R1_STATE then
            if hazard = '1' then next_state <= ON_STATE; --go to hazard if needed
            else next_state <= R2_STATE; --continue right sequence
            end if;
            
        elsif current_state = R2_STATE then
            if hazard = '1' then next_state <= ON_STATE;
            else next_state <= R3_STATE;
            end if;
            
        elsif current_state = R3_STATE then
            if hazard = '1' then next_state <= ON_STATE;
            else next_state <= OFF_STATE;  --end of right sequence returns to OFF
            end if;
            
        elsif current_state = L1_STATE then
            if hazard = '1' then next_state <= ON_STATE;
            else next_state <= L2_STATE;   --continue left sequence
            end if;
            
        elsif current_state = L2_STATE then
            if hazard = '1' then next_state <= ON_STATE;
            else next_state <= L3_STATE;
            end if;
            
        elsif current_state = L3_STATE then
            if hazard = '1' then next_state <= ON_STATE;
            else next_state <= OFF_STATE; --end of left sequence returns to OFF
            end if;
            
        else
            next_state <= OFF_STATE;
            
        end if;
    end process;

    process(i_clk, i_reset)
    begin
        if i_reset = '1' then current_state <= OFF_STATE;  --reset to OFF state
        elsif rising_edge(i_clk) then current_state <= next_state;
        end if;
    end process;

    process(current_state)
    begin
        case current_state is
            when OFF_STATE =>
                o_lights_L <= "000"; --all left lights off
                o_lights_R <= "000"; --all right lights off
            when ON_STATE =>
                o_lights_L <= "111"; --all left lights on (hazard)
                o_lights_R <= "111"; --all right lights on (hazard)
            when R1_STATE =>
                o_lights_L <= "000"; --left lights off
                o_lights_R <= "001";--Only RA on
            when R2_STATE =>
                o_lights_L <= "000";
                o_lights_R <= "011"; --RA and RB on
            when R3_STATE =>
                o_lights_L <= "000";
                o_lights_R <= "111"; --RA, RB, and RC on
            when L1_STATE =>
                o_lights_L <= "001"; --Only LA on
                o_lights_R <= "000";
            when L2_STATE =>
                o_lights_L <= "011"; --LA and LB on
                o_lights_R <= "000";
            when L3_STATE =>
                o_lights_L <= "111"; --LA, LB, and LC on
                o_lights_R <= "000";
            when others =>
                o_lights_L <= "000";
                o_lights_R <= "000";
        end case;
    end process;

	-----------------------------------------------------					   
				  
end thunderbird_fsm_arch;