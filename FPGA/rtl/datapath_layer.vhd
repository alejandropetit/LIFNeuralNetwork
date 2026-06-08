
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.NEURON_PACKAGE.ALL;


entity datapath_layer is
    generic(width       : positive;
            int_width   : natural;
            frac_width  : natural;
            in_size     : positive;
            step_size   : positive := in_size + 3;
            num_neurons : positive);    
    Port ( clk            : in  STD_LOGIC;
           reset          : in  STD_LOGIC;
           first_cycle    : in  STD_LOGIC;
           beta           : in  STD_LOGIC_VECTOR(width-1 downto 0);
           Vth            : in  STD_LOGIC_VECTOR(width-1 downto 0);
           spike_in       : in  STD_LOGIC_VECTOR(in_size-1 downto 0);
           actual_weight  : in  STD_LOGIC_VECTOR(in_size-1 downto 0);
           addr           : in  STD_LOGIC_VECTOR(clog2(in_size)-1 downto 0);
           cnt_step       : in  STD_LOGIC_VECTOR(clog2(step_size)-1 downto 0);
           state          : in  state_type;
           spike_out      : out STD_LOGIC_VECTOR (num_neurons-1 downto 0));
end datapath_layer;

architecture Behavioral of datapath_layer is
    signal addr_1 : STD_LOGIC_VECTOR(8 downto 0);
    signal size: integer := 0;
    constant neurons_per_mem : integer := 4;
    constant num_groups : integer :=  (num_neurons + neurons_per_mem -1)/neurons_per_mem;
begin

    addr_1 <= std_logic_vector(resize(unsigned(addr), addr_1'length));         
    

        gen_group: for g in 0 to num_groups-1 generate 
            signal weight : std_logic_vector(71 downto 0);
        begin     
            weight_inst: entity work.weight_unit generic map(width => width)
                                                 port map(clk => clk,
                                                          reset => reset,
                                                          we  => '0',
                                                          din => (others => '0'),
                                                          addr => addr_1,
                                                          dout => weight);   
            gen_neurons: for i in 0 to neurons_per_mem-1 generate 
                constant neuron_idx : integer := g*neurons_per_mem+i;
            begin
            
                valid_neuron: if neuron_idx < num_neurons generate
                begin
                    neuron_inst: entity work.lif_neuron generic map(width => width,
                                                                    in_size => in_size,
                                                                    int_width => int_width,
                                                                    frac_width => frac_width)
                                                        port map(clk => clk,
                                                                 reset => reset,
                                                                 beta => beta,
                                                                 Vth => Vth,
                                                                 state => state,
                                                                 actual_weight => actual_weight,
                                                                 weight => weight(width*(i+1)-1 downto width*i),
                                                                 spike_in => spike_in,
                                                                 spike_out => spike_out(neuron_idx),
                                                                 cnt_step => cnt_step);                  
                
                end generate;
            end generate;
        end generate;
    
end Behavioral;
