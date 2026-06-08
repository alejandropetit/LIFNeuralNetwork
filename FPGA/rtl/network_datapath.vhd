

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.NEURON_PACKAGE.ALL;


entity network_datapath is
  generic(width:  integer;
          int_width: natural;
          frac_width: natural;
          in_size: positive;
          out_size: positive;
          layer_size: positive;
          neuron_size: int_array_t);
  Port (clk:   in STD_LOGIC;
        reset: in STD_LOGIC;
        beta      : std_logic_vector(width-1 downto 0);
        Vth       : std_logic_vector(width-1 downto 0);
        spike_in: in STD_LOGIC_VECTOR(in_size-1 downto 0);
        spike_out: out STD_LOGIC_VECTOR(out_size-1 downto 0));
end network_datapath;

architecture Behavioral of network_datapath is
    constant max_neuron :  integer := max_array(neuron_size);
    type spike_bus_t is array (0 to layer_size) of std_logic_vector(max_neuron-1 downto 0);
    signal spike_bus : spike_bus_t := (others => (others => '0'));
    signal weight_all: STD_LOGIC;
    signal w_ready: STD_LOGIC_VECTOR(layer_size-1 downto 0);
begin


    spike_bus(0)(neuron_size(0)-1 downto 0) <= spike_in;
    spike_out <= spike_bus(layer_size)(neuron_size(layer_size)-1 downto 0);
    
    layers: for i in 0 to layer_size-1 generate 
    begin
        layer_inst: entity work.lif_layer generic map(width => width,
                                                      int_width => int_width,
                                                      frac_width => frac_width,
                                                      in_size => neuron_size(i),
                                                      num_neurons => neuron_size(i+1))
                                          port map(clk => clk,
                                                   reset => reset,
                                                   weight_all => weight_all,
                                                   w_ready => w_ready(i),
                                                   beta => beta,
                                                   Vth => Vth,
                                                   spike_in => spike_bus(i)(neuron_size(i)-1 downto 0),
                                                   spike_out => spike_bus(i+1)(neuron_size(i+1)-1 downto 0) );
    
    end generate;                                        
   
    weight_all <= and(w_ready);
                                        
end Behavioral;