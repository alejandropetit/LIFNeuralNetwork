

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.neuron_package.ALL;

entity SNN_Controller is
    port(
        clk: in STD_LOGIC;
        reset: in STD_LOGIC;
        
        data : in STD_LOGIC_VECTOR(103 downto 0);
        data_valid: in STD_LOGIC;
        data_ready: out STD_LOGIC;
        
        action: out STD_LOGIC_VECTOR(31 downto 0);
        action_valid: out STD_LOGIC;
        action_ready: in STD_LOGIC
    );
end SNN_Controller;

architecture Behavioral of SNN_Controller is
        signal snn_ready: STD_LOGIC;
        signal rudder_ready: STD_LOGIC;
        signal sail_ready: STD_LOGIC;
        signal snn_valid : STD_LOGIC;
        signal network_in_rudder : STD_LOGIC_VECTOR(23 downto 0); 
        signal network_in_sail : STD_LOGIC_VECTOR(143 downto 0);  
        signal network_out_rudder: STD_LOGIC_VECTOR(0 downto 0);
        signal network_out_sail: STD_LOGIC_VECTOR(0 downto 0);
        signal rudder_out_valid, sail_out_valid: STD_LOGIC;
begin

    input: entity work.input_interface
    generic map(
        area1 => 120,
        area2 => 60,
        max_speed => 0.35,
        sensormax1 => 60,
        sensormax2 => 30,
        k1 => 12,
        k2 => 1,
        k3 =>36,
        output_cycles => 500
    )
    port map(
        clk => clk,
        reset => reset,
        ready => data_ready,
        valid => data_valid,
        data => data,
        ready_SNN => snn_ready,
        valid_SNN => snn_valid,
        spikes_rudder => network_in_rudder,
        spikes_sail => network_in_sail
    );
    
    snn_ready <= rudder_ready and sail_ready;
    
    rudder_SNN: entity work.lif_network
    generic map(
        int_width => 7,
        frac_width => 10,
        decay_option => DECAY_EVERY_STEP,
        network_shape => (24,1),
        beta => (0 => 0.9900498337),
        Vth => (0 => 13.0),
        mem_file => "mem_rudder"
    )
    port map(
        clk => clk,     
        reset => reset,  
        valid  => snn_valid, 
        network_in  =>  network_in_rudder,
        ready => rudder_ready,     
        network_out => network_out_rudder,
        out_valid => rudder_out_valid
    );
    
    sail_SNN: entity work.lif_network
    generic map(
        int_width => 7,
        frac_width => 12,
        decay_option => DECAY_EVERY_STEP,
        network_shape => (144,1),
        beta => (0 => 0.9900498337),
        Vth => (0 => 13.0),
        mem_file => "mem_sail"
    )
    port map(
        clk => clk,
        reset => reset,
        valid => snn_valid,
        network_in => network_in_sail,
        ready => sail_ready,
        network_out => network_out_sail,
        out_valid => sail_out_valid
    
    );
    
    output: entity work.output_interface
    generic map(
        max_out_rudder => 45,
        min_out_rudder => -45,
        max_spikes_rudder => 61,
        min_spikes_rudder => 0,
        out_states_rudder => 13,
        max_out_sail => 90,
        min_out_sail => -90,
        max_spikes_sail => 56,
        min_spikes_sail => 0,
        out_states_sail => 15       
    )
    port map(
        clk => clk,
        reset => reset,
        spikes_rudder => network_out_rudder(0),
        valid_rudder => rudder_out_valid,
        spikes_sail => network_out_sail(0),
        valid_sail => sail_out_valid,
        action => action,
        valid => action_valid,
        ready => action_ready
    );

end Behavioral;
