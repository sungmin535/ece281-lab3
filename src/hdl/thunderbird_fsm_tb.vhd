library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity thunderbird_fsm_tb is
end thunderbird_fsm_tb;

architecture test_bench of thunderbird_fsm_tb is 

    -- Component Declaration for the Unit Under Test (UUT)
    component thunderbird_fsm is 
      port(
        i_clk     : in  std_logic;
        i_reset   : in  std_logic;
        i_left    : in  std_logic;
        i_right   : in  std_logic;
        o_lights_L: out std_logic_vector(2 downto 0);
        o_lights_R: out std_logic_vector(2 downto 0)
      );
    end component;

    -- Testbench signals
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

    -- Clock Process: Generate a 10 ns clock.
    clk_proc: process
    begin
        w_clk <= '0';
        wait for k_clk_period/2;
        w_clk <= '1';
        wait for k_clk_period/2;
    end process clk_proc;
    -----------------------------------------------------

    -- Simulation Process: Apply test stimuli.
    sim_proc: process
    begin
        -- Test 1: Synchronous Reset Test
        report "Test 1: Applying synchronous reset";
        w_reset <= '1';
        wait for k_clk_period;
        w_reset <= '0';
        wait for k_clk_period*2;
        -- After reset, outputs should be "000"
        assert (w_lights_L = "000" and w_lights_R = "000")
            report "Reset test failed: Outputs not OFF" severity failure;
        
        -- Test 2: Right Turn Sequence Test
        report "Test 2: Right turn sequence test";
        w_left  <= '0';
        w_right <= '1'; -- Activate right turn signal
        wait for k_clk_period*8;
        w_right <= '0';
        wait for k_clk_period*4;
        assert (w_lights_R = "000")
            report "Right turn sequence test failed: Right lights did not return to OFF" severity failure;
        
        -- Test 3: Left Turn Sequence Test
        report "Test 3: Left turn sequence test";
        w_left  <= '1'; -- Activate left turn signal
        w_right <= '0';
        wait for k_clk_period*8;
        w_left  <= '0';
        wait for k_clk_period*4;
        assert (w_lights_L = "000")
            report "Left turn sequence test failed: Left lights did not return to OFF" severity failure;
        
        -- Test 4: Hazard Condition Test
        report "Test 4: Hazard condition test";
        w_left  <= '1';
        w_right <= '1';
        wait for k_clk_period*6;
        assert (w_lights_L = "111" and w_lights_R = "111")
            report "Hazard test failed: Lights are not all ON" severity failure;
        
        -- Test 5: Mid-Sequence Change Test
        report "Test 5: Mid-sequence change test";
        w_left  <= '0';
        w_right <= '1';  -- Start right sequence
        wait for k_clk_period*3;
        w_left  <= '1';   -- Now force hazard by activating left
        wait for k_clk_period*3;
        assert (w_lights_L = "111" and w_lights_R = "111")
            report "Mid-sequence change test failed: FSM did not enter hazard state" severity failure;
        w_left  <= '0';
        w_right <= '0';
        wait for k_clk_period*4;
        
        report "Testbench simulation complete" severity note;
        wait;
    end process sim_proc;
    -----------------------------------------------------

end test_bench;

-- Configuration block to bind the component instance
configuration tb_cfg of thunderbird_fsm_tb is
   for test_bench
      for uut: thunderbird_fsm use entity work.thunderbird_fsm(thunderbird_fsm_arch);
      end for;
   end for;
end tb_cfg;