
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.NEURON_PACKAGE.ALL;


entity lif_network is
    generic(width : integer := 16;
            int_width : natural;
            frac_width : natural;
            in_size: integer := 3;
            out_size: integer := 1;
            layer_size: integer := 2);
    Port (clk : in  STD_LOGIC;
          reset: in STD_LOGIC;
          beta: in STD_LOGIC_VECTOR(width-1 downto 0);
          Vth:  in STD_LOGIC_VECTOR(width-1 downto 0);
          spike_in: in STD_LOGIC_VECTOR(in_size-1 downto 0);
          spike_out: out STD_LOGIC_VECTOR(out_size-1 downto 0));
end lif_network;

architecture Behavioral of lif_network is
     constant neuron_size : int_array_t(0 to 2) := (3, 1, 1);
begin
    datapath: entity work.network_datapath generic map(width => width,
                                                       int_width => int_width,
                                                       frac_width => frac_width,
                                                       in_size => in_size,
                                                       out_size => out_size,
                                                       layer_size => layer_size, 
                                                       neuron_size => neuron_size)
                                           port map(clk => clk,
                                                    reset => reset,
                                                    beta => beta,
                                                    Vth => Vth,
                                                    spike_in => spike_in,
                                                    spike_out => spike_out);
    control: entity work.network_control port map(clk => clk,
                                                  reset => reset);

end Behavioral;
