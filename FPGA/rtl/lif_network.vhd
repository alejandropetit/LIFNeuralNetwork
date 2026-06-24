
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.NEURON_PACKAGE.ALL;


entity lif_network is
    generic(
        int_width   : natural := 8;
        frac_width  : natural := 8;
        in_size     : integer := 7;
        out_size    : integer := 1;
        layer_size  : integer := 2;
        decay_option: integer := 0;
        beta        : real := 0.9900498337;
        Vth         : real := 100.0);
    Port (
        clk : in  STD_LOGIC;
        reset: in STD_LOGIC;
        network_in: in STD_LOGIC_VECTOR(in_size-1 downto 0);
        network_out: out STD_LOGIC_VECTOR(out_size-1 downto 0));
end lif_network;

architecture Behavioral of lif_network is
     constant neuron_size : int_array_t(0 to 2) := (3, 3, 1);
begin
    datapath: entity work.network_datapath 
    generic map(
        int_width => int_width,
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
        network_in => network_in,
        network_out => network_out);
    
    control: entity work.network_control 
    port map(
        clk => clk,
        reset => reset);

end Behavioral;
