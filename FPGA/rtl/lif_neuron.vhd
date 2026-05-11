

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.NEURON_PACKAGE.ALL;

entity lif_neuron is
    generic ( width: positive := 16;
              depth: positive := 3;
              int_width: natural := 8;
              frac_width: natural := 8; 
              num_inputs : positive := 3;
              step_size  : positive:= depth + 3);
    Port ( clk:       in  STD_LOGIC;
           reset:     in  STD_LOGIC;
           beta:      in  STD_LOGIC_VECTOR(width-1 downto 0);
           Vth:       in  STD_LOGIC_VECTOR(width-1 downto 0);
           spike_in:  in  std_logic_vector(num_inputs-1 downto 0);
           spike_out: out STD_LOGIC );
end lif_neuron;

architecture Behavioral of lif_neuron is
    signal addr: std_logic_vector(clog2(depth)-1 downto 0);
    signal weight : std_logic_vector(width-1 downto 0);
    signal cnt_step : std_logic_vector(clog2(step_size)-1 downto 0);
    signal src_ctrl, acc_ctrl, out_ctrl, spike: std_logic;
    signal reset_out_spike , reset_out_u , reset_acc , en_out_spike , en_out_u , en_acc : std_logic; 
begin

--addr <= cnt_step(clog2(depth)-1 downto 0);

    datapath:   entity work.datapath_neuron port map( clk => clk,
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
                                                      y => spike,
                                                      spike_out => spike_out);
    controller: entity work.control_neuron generic map(depth => depth) 
                                              port map( clk => clk,
                                                        reset => reset,
                                                        spike_in =>spike_in,
                                                        spike => spike,
                                                        spike_out => spike_out,
                                                        reset_out_spike => reset_out_spike,
                                                        reset_out_u => reset_out_u,
                                                        reset_acc => reset_acc,
                                                        en_out_spike => en_out_spike,
                                                        en_out_u => en_out_u,
                                                        en_acc => en_acc,  
                                                        src_ctrl => src_ctrl,
                                                        addr => addr); 
    weights:    entity work.weight_unit generic map(depth => depth,
                                                    width => width)
                                           port map(clk => clk, 
                                                     we => '0',
                                                    din => (others => '0'),
                                                    addr => addr,
                                                    dout => weight);
end Behavioral;
