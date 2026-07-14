
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.NEURON_PACKAGE.ALL;


entity lif_network is
    generic(
        int_width    : natural := 9;
        frac_width   : natural := 9;
        in_size      : integer := 3;
        out_size     : integer := 1;
        layer_size   : integer := 2;
        decay_option : decay_option_t := DECAY_ACCUMULATE;
        beta         : real := 0.9900498337;
        Vth          : real := 100.0);
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        valid       : in  STD_LOGIC;
        network_in  : in  STD_LOGIC_VECTOR(in_size-1 downto 0);
        ready       : out STD_LOGIC;
        network_out : out STD_LOGIC_VECTOR(out_size-1 downto 0));
end lif_network;

architecture Behavioral of lif_network is
     constant neuron_size : int_array_t(0 to 2) := (3, 3, 1);
     signal weights_done:  STD_LOGIC;
     signal weight_accum_done : STD_LOGIC_VECTOR(layer_size-1 downto 0);
     signal output_state : STD_LOGIC_VECTOR(layer_size-1 downto 0);
     signal en_front    :  STD_LOGIC;
     signal en_back     :  STD_LOGIC;
begin
    datapath: entity work.network_datapath 
    generic map(
        int_width    => int_width,
        frac_width   => frac_width,
        in_size      => in_size,
        out_size     => out_size,
        layer_size   => layer_size, 
        neuron_size  => neuron_size,
        decay_option => decay_option,
        beta         => beta,
        Vth          => Vth
    )
    port map(
        clk               => clk,
        reset             => reset,
        en_front          => en_front,
        en_back           => en_back,
        weights_done      => weights_done,
        network_in        => network_in,
        weight_accum_done => weight_accum_done,
        output_state      => output_state,
        network_out       => network_out
    );
    
    control: entity work.network_control 
    generic map(
        layer_size => layer_size
    )
    port map(
        clk               => clk,
        reset             => reset,
        valid             => valid,
        weights_done      => weights_done,
        en_front          => en_front,
        en_back           => en_back,
        weight_accum_done => weight_accum_done,
        output_state      => output_state,
        ready             => ready
    );

end Behavioral;
