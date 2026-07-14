
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.NEURON_PACKAGE.ALL;

entity lif_layer is
    generic(
        int_width    : natural;
        frac_width   : natural;
        in_size      : positive;
        step_size    : positive := in_size + 3;
        num_neurons  : positive;
        decay_option : decay_option_t;
        beta         : real; 
        Vth          : real;
        mem_file     : string
    );
    Port ( 
        clk               : in  STD_LOGIC;
        reset             : in  STD_LOGIC;
        weights_done      : in  STD_LOGIC;
        layer_in          : in  STD_LOGIC_VECTOR (in_size-1 downto 0);
        weight_accum_done : out STD_LOGIC;
        output_state      : out STD_LOGIC;
        layer_out         : out STD_LOGIC_VECTOR (num_neurons-1 downto 0)
    );
end lif_layer;

architecture Behavioral of lif_layer is
    signal state: state_type;
    signal cnt_step: STD_LOGIC_VECTOR(clog2(step_size)-1 downto 0);
    signal weight_addr :   STD_LOGIC_VECTOR(clog2(in_size)-1 downto 0);
    signal current_spike   :  STD_LOGIC_VECTOR(in_size-1 downto 0);
begin

    --layer instantiation
    layer_datapath: entity work.datapath_layer     
    generic map(
        int_width    => int_width,
        frac_width   => frac_width,
        in_size      => in_size,
        num_neurons  => num_neurons,
        decay_option => decay_option,
        beta         => beta,
        Vth          => Vth,
        mem_file     => mem_file
    )
    port map(
        clk           => clk,
        reset         => reset,
        state         => state,
        current_spike => current_spike,
        layer_in      => layer_in,
        layer_out     => layer_out,
        cnt_step      => cnt_step,
        weight_addr   => weight_addr);
    --layer instantiation
    
    --control instantiation
    layer_control: entity work.control_layer 
    generic map(
        in_size => in_size
    )
    port map(
        clk               => clk,
        reset             => reset,
        weights_done      => weights_done,
        weight_accum_done => weight_accum_done,
        output_state      => output_state,
        current_spike     => current_spike,
        state             => state,
        layer_in          => layer_in,
        cnt_step          => cnt_step,
        weight_addr       => weight_addr
    );
    --control instantiation
end Behavioral;
