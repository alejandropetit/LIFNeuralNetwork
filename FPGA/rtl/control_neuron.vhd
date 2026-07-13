library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.NEURON_PACKAGE.ALL;

entity control_neuron is
generic( 
    in_size     : positive; -- number of inputs to the layer
    step_size   : positive := in_size + 3; -- duration of a step
    decay_option: decay_option_t; -- selects the accumulation decay type
    refrac      : natural:=4  -- duration of the refractory period
);
Port ( 
    clk             :  in   STD_LOGIC; -- system clock
    reset           :  in   STD_LOGIC; -- active-high reset
    zero            :  in   STD_LOGIC; -- asserted when the membrane voltage is zero
    spike           :  in   STD_LOGIC; -- Spike will be generated on the next clock cycle
    spike_out       :  in   STD_LOGIC; -- Current output spike 
    spike_in        :  in   STD_LOGIC_VECTOR(in_size-1 downto 0); -- input spike vector
    cnt_step        :  in   STD_LOGIC_VECTOR(clog2(step_size)-1 downto 0); -- step counter
    current_spike   :  in   STD_LOGIC_VECTOR(in_size-1 downto 0); -- spike currently being processed
    state           :  in   state_type; -- current layer state
    reset_out_spike :  out  STD_LOGIC; -- reset for output spike register
    reset_out_u     :  out  STD_LOGIC; -- reset for output voltage register
    reset_acc       :  out  STD_LOGIC; -- reset for accumulate voltage register
    en_out_spike    :  out  STD_LOGIC; -- enable for output spike register
    en_out_u        :  out  STD_LOGIC; -- enable for output voltage register
    en_acc          :  out  STD_LOGIC; -- enable for accumulate voltage register  
    src_ctrl        :  out  STD_LOGIC  -- Selects the 2:1 multiplexer input (weights or decay)
);
end control_neuron;

architecture Behavioral of control_neuron is
    signal cnt_refrac : unsigned( clog2(refrac)-1 downto 0 ) := (others => '0');
    signal ctrl_state : STD_LOGIC;
    signal control : STD_LOGIC_VECTOR(6 downto 0);
    signal no_input_voltage_zero : boolean;
    signal refractory_active : boolean;
    signal no_input_weight_state : boolean;
    signal no_input : boolean;
    signal neuron_state : state_type;
    constant CTRL_INPUT : STD_LOGIC_VECTOR(6 downto 0) := "0010000";
    constant CTRL_DECAY : STD_LOGIC_VECTOR(6 downto 0) := "0000011";
begin
    
    
    no_input <= spike_in = (spike_in'range => '0');
    
    no_input_voltage_zero <= (zero = '1') and no_input;
    refractory_active     <= (spike_out = '0') and (cnt_refrac /= 0);
    no_input_weight_state <= (zero = '0') and no_input and (state = WEIGHT);
    
    decay_gen: if decay_option = DECAY_ACCUMULATE generate
        ctrl_state <= '1' when no_input_voltage_zero or refractory_active or no_input_weight_state or no_input else '0';
    else generate
        ctrl_state <= '1' when no_input_voltage_zero or refractory_active or no_input_weight_state else '0';
    end generate;
    
    
    neuron_state <= state when ctrl_state = '0' else INPUT; 

--Counters   
    process(clk) begin
        if rising_edge(clk) then
            if unsigned(cnt_step) = step_size-1 then
                if spike = '1' then
                    cnt_refrac <= to_unsigned(refrac, cnt_refrac'length);
                elsif cnt_refrac > 0 then
                    cnt_refrac <= cnt_refrac - 1;
                end if;
            end if;
        end if;
    end process;
 --
 
 --Deecoder  
    process(all) begin
        case neuron_state is
            when INPUT =>
                reset_out_spike <= '0';
                reset_out_u <= '0';
                reset_acc <= '1';
                en_out_spike <= '0';
                en_out_u <= '0';
                en_acc <= '0';    
                src_ctrl <= '0';           
            when WEIGHT =>
                reset_out_spike <= '0';
                reset_out_u <= '0';
                reset_acc <= '0';
                en_out_spike <= '0';
                en_out_u <= '0';
                en_acc <= or actual_weight when cnt_refrac = 0 else '0';  
                src_ctrl <= '0'; 
            when DECAY =>
                reset_out_spike <= '0';
                reset_out_u <= '0';
                reset_acc <= '0';
                en_out_spike <= '0';
                en_out_u <= '0';
                en_acc <= '1';
                src_ctrl <= '1'; 
            when OUTPUT =>
                if spike_out = '1' then
                    reset_out_spike <= '1';
                else
                    reset_out_spike <= '0';
                end if;
                
                if spike='1' then
                    reset_out_u <= '1';
                    reset_acc <= '1';
                else
                    reset_out_u <= '0';
                    reset_acc <= '0';
                end if;
                en_out_spike <= '1';
                en_out_u <= '1';
                en_acc <= '0';  
                src_ctrl <= '0';
        end case;  
    end process;
 --
end Behavioral;
