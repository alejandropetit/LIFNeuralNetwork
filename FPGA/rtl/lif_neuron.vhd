library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.NEURON_PACKAGE.ALL;
use IEEE.FIXED_PKG.ALL;

entity lif_neuron is
    generic (
        width      : positive; -- total fixed-point width (integer + fractional bits)
        int_width  : natural; -- number of integer bits
        frac_width : natural; -- number of fractional bits 
        in_size    : positive; -- number of inputs to the layer
        step_size  : positive:= in_size + 3; -- duration of a step
        beta       : real; -- membrane decay factor 
        Vth        : real; -- spike generation threshold
        decay_option: decay_option_t -- Selects how membrane decay is computed
    );
    Port ( 
        clk            :  in  STD_LOGIC; -- system clock
        reset          :  in  STD_LOGIC; -- active-high reset
        weight         :  in  STD_LOGIC_VECTOR(width-1 downto 0); -- synaptic weight corresponding to the current input spike
        spike_in       :  in  STD_LOGIC_VECTOR(in_size-1 downto 0); -- input spike vector
        current_spike  :  in  STD_LOGIC_VECTOR(in_size-1 downto 0); -- spike currently being processed
        cnt_step       :  in  STD_LOGIC_VECTOR(clog2(step_size)-1 downto 0); -- step counter
        decay_sig      :  in  SFIXED(int_width-1 downto -frac_width); -- accumulated membrane decay factor
        state          :  in  state_type; --current layer FSM state  
        spike_out      :  out STD_LOGIC -- registered output spike
    );  
end lif_neuron;

architecture Behavioral of lif_neuron is
    signal src_ctrl, acc_ctrl, out_ctrl, spike, zero: std_logic;
    signal reset_out_spike , reset_out_u , reset_acc , en_out_spike , en_out_u , en_acc : std_logic; 
begin
    -- neuron datapath instantiation
    datapath: entity work.datapath_neuron
    generic map(
        width => width,
        int_width => int_width,
        frac_width => frac_width,
        beta => beta,
        Vth => Vth,
        decay_option => decay_option
    )
    port map( 
        clk => clk,
        reset => reset,
        src_ctrl => src_ctrl,
        reset_out_spike => reset_out_spike,
        reset_out_u => reset_out_u,
        reset_acc => reset_acc,
        en_out_spike => en_out_spike,
        en_out_u => en_out_u,
        en_acc => en_acc,  
        weight => weight,
        decay_sig => decay_sig,
        zero => zero,
        y => spike,
        spike_out => spike_out
    );
    -- neuron datapath instantiation
    
    -- neuron control instantiation                                                  
    controller: entity work.control_neuron 
    generic map(
        in_size => in_size,
        decay_option => decay_option
    ) 
    port map(
        clk => clk,
        reset => reset,
        spike_in =>spike_in,
        spike => spike,
        spike_out => spike_out,
        state => state,
        current_spike => current_spike,
        reset_out_spike => reset_out_spike,
        reset_out_u => reset_out_u,
        reset_acc => reset_acc,
        en_out_spike => en_out_spike,
        en_out_u => en_out_u,
        en_acc => en_acc,  
        src_ctrl => src_ctrl,
        zero => zero, 
        cnt_step => cnt_step
    ); 
end Behavioral;
