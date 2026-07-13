
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.NEURON_PACKAGE.ALL;
use IEEE.FIXED_PKG.ALL;


entity datapath_layer is
    generic(
        int_width   : natural;
        frac_width  : natural;
        width       : positive := int_width + frac_width;
        in_size     : positive;
        step_size   : positive := in_size + 3;
        num_neurons : positive;
        decay_option: decay_option_t;
        beta        : real;
        Vth         : real;
        mem_file    : string
    );    
    Port ( 
        clk            : in  STD_LOGIC;
        reset          : in  STD_LOGIC;
        layer_in       : in  STD_LOGIC_VECTOR(in_size-1 downto 0);
        current_spike  : in  STD_LOGIC_VECTOR(in_size-1 downto 0);
        weight_addr    : in  STD_LOGIC_VECTOR(clog2(in_size)-1 downto 0);
        cnt_step       : in  STD_LOGIC_VECTOR(clog2(step_size)-1 downto 0);
        state          : in  state_type;
        layer_out      : out STD_LOGIC_VECTOR (num_neurons-1 downto 0)
    );
end datapath_layer;

architecture Behavioral of datapath_layer is
    constant mem_depth : integer := 1024;
    constant neurons_per_mem : integer := 4;
    constant num_groups : integer :=  (num_neurons + neurons_per_mem -1)/neurons_per_mem;
    signal   mem_addr : STD_LOGIC_VECTOR(clog2(mem_depth)-1 downto 0);
    signal   decay_sig : SFIXED(int_width-1 downto -frac_width);
begin

    mem_addr <= std_logic_vector(resize(unsigned(weight_addr), mem_addr'length));         
       
    gen_group: for g in 0 to num_groups-1 generate 
        signal weight : std_logic_vector(width*neurons_per_mem-1 downto 0);
        constant init_addr : integer := g*in_size;
    begin     
        -- weight instantiation
        weight_inst: entity work.weight_unit 
        generic map(
            width => width*neurons_per_mem,
            depth => mem_depth,
            init_addr => init_addr,
            in_size => in_size,
            mem_file => mem_file
        )
        port map(
            clk => clk,
            reset => reset,
            we  => '0',
            din => (others => '0'),
            addr => mem_addr,
            dout => weight
        ); 
        gen_neurons: for i in 0 to neurons_per_mem-1 generate 
            constant neuron_idx : integer := g*neurons_per_mem+i;
        begin
            valid_neuron: if neuron_idx < num_neurons generate
            begin
                -- neuron instatiation
                neuron_inst: entity work.lif_neuron
                generic map(
                    width => width,
                    int_width => int_width,
                    frac_width => frac_width,
                    in_size => in_size,
                    beta => beta,
                    Vth => Vth,
                    decay_option => decay_option
                )
                port map(
                    clk => clk,
                    reset => reset,
                    state => state,
                    current_spike => current_spike,
                    weight => weight(width*(i+1)-1 downto width*i),
                    spike_in => layer_in,
                    spike_out => layer_out(neuron_idx),
                    cnt_step => cnt_step,
                    decay_sig => decay_sig
                );                  
            end generate;
        end generate;
    end generate;
    
    decay_inst: if decay_option = DECAY_ACCUMULATE generate
        signal former_spike :STD_LOGIC;
        constant beta_sig  :  SFIXED(int_width-1 downto -frac_width) := to_sfixed(beta, int_width-1, -frac_width);
        signal src_a, accumulate_sig: SFIXED(int_width-1 downto -frac_width); 
    begin      
        process(clk) begin
            if rising_edge(clk) then
                if reset = '1' then
                    former_spike <= '1';
                elsif state = OUTPUT then
                    former_spike <= or(layer_in);
                    if former_spike = '1' then
                        src_a <= beta_sig;
                    else
                        src_a <= accumulate_sig;
                    end if;
                end if;
            end if;
        end process;
        
        process(all) begin
            accumulate_sig <= resize(arg => src_a * beta_sig,left_index => int_width-1 ,right_index => -frac_width); 
            decay_sig <= beta_sig when former_spike='1' else accumulate_sig;  
        end process;    
    end generate;
        
end Behavioral;
