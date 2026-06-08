
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.NEURON_PACKAGE.ALL;


entity lif_layer is
    generic(width       : positive;
            int_width   : natural;
            frac_width  : natural;
            in_size     : positive;
            step_size   : positive := in_size + 3;
            num_neurons : positive );
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           weight_all : in STD_LOGIC;
           beta      : std_logic_vector(width-1 downto 0);
           Vth       : std_logic_vector(width-1 downto 0);
           spike_in : in STD_LOGIC_VECTOR (in_size-1 downto 0);
           w_ready  : out STD_LOGIC;
           spike_out : out STD_LOGIC_VECTOR (num_neurons-1 downto 0));
end lif_layer;

architecture Behavioral of lif_layer is
    signal state: state_type;
    signal cnt_step: STD_LOGIC_VECTOR(clog2(step_size)-1 downto 0);
    signal addr :   STD_LOGIC_VECTOR(clog2(in_size)-1 downto 0);
    signal actual_weight   :  STD_LOGIC_VECTOR(in_size-1 downto 0);
    signal first_cycle : STD_LOGIC;
begin

layer_datapath: entity work.datapath_layer generic map(width => width,
                                                        int_width => int_width,
                                                        frac_width => frac_width,
                                                        in_size => in_size,
                                                        num_neurons => num_neurons)
                                           port map(clk => clk,
                                                    reset => reset,
                                                    first_cycle => first_cycle,
                                                    state => state,
                                                    beta => beta,
                                                    Vth => Vth,
                                                    actual_weight => actual_weight,
                                                    spike_in => spike_in,
                                                    spike_out => spike_out,
                                                    cnt_step => cnt_step,
                                                    addr => addr);


layer_control: entity work.control_layer generic map(in_size => in_size)
                                         port map(clk=>clk,
                                                  reset=>reset,
                                                  weight_all => weight_all,
                                                  w_ready => w_ready,
                                                  first_cycle => first_cycle,
                                                  actual_weight => actual_weight,
                                                  state => state,
                                                  spike_in => spike_in,
                                                  cnt_step => cnt_step,
                                                  addr => addr);


end Behavioral;
