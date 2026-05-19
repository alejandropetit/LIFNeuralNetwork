
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.NEURON_PACKAGE.ALL;


entity datapath_layer is
    generic(width: integer := 16;
            depth: integer:= 3;
            step_size   : positive := depth + 3);    
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           first_cycle: in STD_LOGIC;
           state  : in state_type;
           spike_in : in STD_LOGIC_VECTOR (clog2(depth) downto 0);
           beta      : std_logic_vector(width-1 downto 0);
           Vth       : std_logic_vector(width-1 downto 0);
           actual_weight   :  in   STD_LOGIC_VECTOR(depth-1 downto 0);
           cnt_step : in STD_LOGIC_VECTOR(clog2(step_size)-1 downto 0);
           addr :  in STD_LOGIC_VECTOR(clog2(depth)-1 downto 0);
           spike_out : out STD_LOGIC_VECTOR (1 downto 0));
end datapath_layer;

architecture Behavioral of datapath_layer is

begin
    neuron1: entity work.lif_neuron generic map(width => width,
                                                depth => depth)
                                    port map(clk => clk,
                                             reset => reset,
                                             first_cycle => first_cycle,
                                             beta => beta,
                                             Vth => Vth,
                                             state => state,
                                             actual_weight => actual_weight,
                                             spike_in => spike_in,
                                             spike_out => spike_out(1),
                                             cnt_step => cnt_step,
                                             addr => addr);
    
    neuron2: entity work.lif_neuron generic map(width => width,
                                                depth => depth)
                                    port map(clk => clk,
                                             reset => reset,
                                             first_cycle => first_cycle,
                                             beta => beta,
                                             Vth => Vth,
                                             state => state,
                                             actual_weight => actual_weight,
                                             spike_in => spike_in,
                                             spike_out => spike_out(0),                                            
                                             cnt_step => cnt_step,
                                             addr => addr);
end Behavioral;
