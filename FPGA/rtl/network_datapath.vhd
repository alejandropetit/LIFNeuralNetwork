
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.NEURON_PACKAGE.ALL;

entity network_datapath is    
    generic(
        int_width     : natural;
        frac_width    : natural;
        decay_option  : decay_option_t;
        network_shape : int_array_t;
        beta          : real_array_t;
        Vth           : real_array_t
    );
    Port(
        clk               : in  STD_LOGIC;
        reset             : in  STD_LOGIC;
        en_front          : in  STD_LOGIC;
        en_back           : in  STD_LOGIC;
        weights_done      : in  STD_LOGIC;
        network_in        : in  STD_LOGIC_VECTOR(network_shape(network_shape'low)-1 downto 0);
        weight_accum_done : out STD_LOGIC_VECTOR(network_shape'length-2 downto 0);
        output_state      : out STD_LOGIC_VECTOR(network_shape'length-2 downto 0);
        network_out       : out STD_LOGIC_VECTOR(network_shape(network_shape'high)-1 downto 0)
     );
end network_datapath;

architecture Behavioral of network_datapath is
    constant num_layers : positive := network_shape'length - 1;
    constant max_neuron : integer := max_array(network_shape);
    type spike_bus_t is array (0 to num_layers) of std_logic_vector(max_neuron-1 downto 0);
    signal front_buffer : STD_LOGIC_VECTOR(network_shape(network_shape'low)-1 downto 0);
    signal back_buffer  : STD_LOGIC_VECTOR(network_shape(network_shape'low)-1 downto 0);
    signal spike_bus    : spike_bus_t := (others => (others => '0'));
begin

    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                back_buffer <= (others => '0');
            elsif en_front = '1' then
                back_buffer <= network_in;
            end if;            
        end if;
    end process;
    
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                front_buffer <= (others => '0');
            elsif en_back = '1' then
                front_buffer <= back_buffer;
            end if;            
        end if;    
    end process;
        
    spike_bus(0)(network_shape(network_shape'low)-1 downto 0) <= front_buffer;
    network_out <= spike_bus(num_layers)(network_shape(network_shape'high)-1 downto 0);
    
    layers: for i in 0 to num_layers-1 generate 
    begin
        -- layer instantiation
        layer_inst: entity work.lif_layer 
        generic map(
            int_width    => int_width,
            frac_width   => frac_width,
            in_size      => network_shape(i),
            num_neurons  => network_shape(i+1),
            decay_option => decay_option,
            beta         => beta(i),
            Vth          => Vth(i),
            mem_file     => mem_files(i)
        )
        port map(
            clk               => clk,
            reset             => reset,
            weights_done      => weights_done,
            weight_accum_done => weight_accum_done(i),
            output_state      => output_state(i),
            layer_in          => spike_bus(i)(network_shape(i)-1 downto 0),
            layer_out         => spike_bus(i+1)(network_shape(i+1)-1 downto 0)
        );
    end generate;                                         
                              
end Behavioral;