library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.NEURON_PACKAGE.ALL;

entity lif_neuron is
    generic ( width     : positive;
              in_size   : positive;
              int_width : natural;
              frac_width: natural; 
              step_size  : positive:= in_size + 3);
    Port ( clk            :  in  STD_LOGIC;
           reset          :  in  STD_LOGIC;
           beta           :  in  STD_LOGIC_VECTOR(width-1 downto 0);
           Vth            :  in  STD_LOGIC_VECTOR(width-1 downto 0);
           weight         :  in  STD_LOGIC_VECTOR(width-1 downto 0);
           spike_in       :  in  STD_LOGIC_VECTOR(in_size-1 downto 0);
           actual_weight  :  in  STD_LOGIC_VECTOR(in_size-1 downto 0);
           cnt_step       :  in  STD_LOGIC_VECTOR(clog2(step_size)-1 downto 0);
           state          :  in  state_type;
           spike_out      :  out STD_LOGIC );
end lif_neuron;

architecture Behavioral of lif_neuron is
    signal src_ctrl, acc_ctrl, out_ctrl, spike, zero: std_logic;
    signal reset_out_spike , reset_out_u , reset_acc , en_out_spike , en_out_u , en_acc : std_logic; 
begin

    datapath:   entity work.datapath_neuron generic map(width => width,
                                                        int_width => int_width,
                                                        frac_width => frac_width)
                                            port map( clk => clk,
                                                      reset => reset,
                                                      src_ctrl => src_ctrl,
                                                      reset_out_spike => reset_out_spike,
                                                      reset_out_u => reset_out_u,
                                                      reset_acc => reset_acc,
                                                      en_out_spike => en_out_spike,
                                                      en_out_u => en_out_u,
                                                      en_acc => en_acc,  
                                                      beta => beta,
                                                      weight => weight,
                                                      Vth => Vth,
                                                      zero => zero,
                                                      y => spike,
                                                      spike_out => spike_out);
    controller: entity work.control_neuron generic map(in_size => in_size) 
                                              port map( clk => clk,
                                                        reset => reset,
                                                        spike_in =>spike_in,
                                                        spike => spike,
                                                        spike_out => spike_out,
                                                        state => state,
                                                        actual_weight => actual_weight,
                                                        reset_out_spike => reset_out_spike,
                                                        reset_out_u => reset_out_u,
                                                        reset_acc => reset_acc,
                                                        en_out_spike => en_out_spike,
                                                        en_out_u => en_out_u,
                                                        en_acc => en_acc,  
                                                        src_ctrl => src_ctrl,
                                                        zero => zero, 
                                                        cnt_step => cnt_step); 
end Behavioral;
