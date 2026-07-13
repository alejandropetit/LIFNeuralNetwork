
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.NEURON_PACKAGE.ALL;


entity lif_network is
    generic(
        int_width   : natural := 9;
        frac_width  : natural := 9;
        in_size     : integer := 3;
        out_size    : integer := 1;
        layer_size  : integer := 2;
        decay_option: decay_option_t := DECAY_ACCUMULATE;
        beta        : real := 0.9900498337;
        Vth         : real := 100.0);
    Port (
        clk : in  STD_LOGIC;
        reset: in STD_LOGIC;
        --start       : in  STD_LOGIC;
        --ready       : out STD_LOGIC;
        network_in: in STD_LOGIC_VECTOR(in_size-1 downto 0);
        network_out: out STD_LOGIC_VECTOR(out_size-1 downto 0));
end lif_network;

architecture Behavioral of lif_network is
     constant neuron_size : int_array_t(0 to 2) := (3, 3, 1);
     signal weights_done:  STD_LOGIC;
     signal weight_accum_done : STD_LOGIC_VECTOR(layer_size-1 downto 0);
     signal start       :  STD_LOGIC;
     signal ready       :  STD_LOGIC;
begin
    datapath: entity work.network_datapath 
    generic map(
        int_width  => int_width,
        frac_width => frac_width,
        in_size => in_size,
        out_size => out_size,
        layer_size => layer_size, 
        neuron_size => neuron_size,
        decay_option => decay_option,
        beta => beta,
        Vth => Vth)
    port map(
        clk => clk,
        reset => reset,
        weights_done => weights_done,
        network_in => network_in,
        weight_accum_done => weight_accum_done,
        network_out => network_out);
    
    control: entity work.network_control 
    generic map(
        layer_size => layer_size)
    port map(
        clk => clk,
        reset => reset,
        start => start,
        weights_done => weights_done,
        weight_accum_done => weight_accum_done,
        ready => ready);

end Behavioral;
