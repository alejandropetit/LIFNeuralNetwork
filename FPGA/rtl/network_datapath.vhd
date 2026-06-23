library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.NEURON_PACKAGE.ALL;

entity network_datapath is    
    generic(
        int_width    : natural;
        frac_width   : natural;
        in_size      : positive;
        out_size     : positive;
        layer_size   : positive;
        neuron_size  : int_array_t;
        beta         : real;
        Vth          : real);
    Port(
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        network_in  : in  STD_LOGIC_VECTOR(in_size-1 downto 0);
        network_out : out STD_LOGIC_VECTOR(out_size-1 downto 0)
     );
end network_datapath;

architecture Behavioral of network_datapath is
    constant max_neuron :  integer := max_array(neuron_size);
    type spike_bus_t is array (0 to layer_size) of std_logic_vector(max_neuron-1 downto 0);
    signal spike_bus : spike_bus_t := (others => (others => '0'));
    signal weights_done: STD_LOGIC;
    signal weight_accum_done: STD_LOGIC_VECTOR(layer_size-1 downto 0);
begin

    spike_bus(0)(neuron_size(0)-1 downto 0) <= network_in;
    network_out <= spike_bus(layer_size)(neuron_size(layer_size)-1 downto 0);
    
    layers: for i in 0 to layer_size-1 generate 
    begin
        -- layer instantiation
        layer_inst: entity work.lif_layer 
        generic map(
            int_width => int_width,
            frac_width => frac_width,
            in_size => neuron_size(i),
            num_neurons => neuron_size(i+1),
            beta => beta,
            Vth => Vth,
            mem_file => mem_files(i))
        port map(
            clk => clk,
            reset => reset,
            weights_done => weights_done,
            weight_accum_done => weight_accum_done(i),
            layer_in => spike_bus(i)(neuron_size(i)-1 downto 0),
            layer_out => spike_bus(i+1)(neuron_size(i+1)-1 downto 0));
    end generate;                                         
   
    weights_done <= and(weight_accum_done);
                                        
end Behavioral;