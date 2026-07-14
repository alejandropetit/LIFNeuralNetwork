library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.NEURON_PACKAGE.ALL;
use IEEE.NUMERIC_STD.ALL;

entity control_layer is
    generic(
        in_size   : positive; -- number of inputs to the layer
        step_size : positive := in_size + 3 -- duration of a step
    );
    Port ( 
        clk               :  in   STD_LOGIC; --system clock
        reset             :  in   STD_LOGIC; --active-high reset
        weights_done      :  in   STD_LOGIC; --all layers weight additions complete
        layer_in          :  in   STD_LOGIC_VECTOR(in_size-1 downto 0); --input spike vector
        weight_accum_done :  out  STD_LOGIC; --layer weight additions complete
        output_state      :  out  STD_LOGIC; --asserted when the layer FSM is in OUTPUT
        current_spike     :  out  STD_LOGIC_VECTOR(in_size-1 downto 0); --spike currently being processed
        weight_addr       :  out  STD_LOGIC_VECTOR(clog2(in_size)-1 downto 0); -- weight memory address   
        cnt_step          :  out  STD_LOGIC_VECTOR(clog2(step_size)-1 downto 0); --step duration counter
        state             :  out  state_type  --current layer FSM state                                     
    );
end control_layer;

architecture Behavioral of control_layer is
    signal next_state: state_type;
    signal first_cycle: STD_LOGIC; --asserted during the first cycle after reset
    signal selected_spikes, remaining_spikes: STD_LOGIC_VECTOR(in_size-1 downto 0);
    signal aux_current_spike : STD_LOGIC_VECTOR(in_size-1 downto 0);
begin

    -- Next-state logic for the layer controller FSM.
    process(all)
    begin
        case state is
            when INPUT =>
                if first_cycle ='1' then
                    next_state <= INPUT;
                else
                    next_state <= WEIGHT;
                end if;
            when WEIGHT =>
                if weights_done = '1' then
                    next_state <= DECAY;
                else
                    next_state <= WEIGHT;
                end if;
            when DECAY =>
                next_state <= OUTPUT;
            when OUTPUT =>
                next_state <= INPUT;
        end case;
    end process;
    
    --FSM state register and generation of the startup flag.
    process(clk, reset)
    begin
        if reset = '1' then
            state <= INPUT;
            first_cycle <= '1';
        else
            if rising_edge(clk) then
                state <= next_state;
                first_cycle <= '0'; 
            end if;
        end if;
    end process;
     
    -- Counts cycles within a step.
    -- Resets on startup and when the step duration is reached.
    process(clk) begin 
        if rising_edge (clk) then
            if first_cycle ='1' or unsigned(cnt_step) = step_size-1 then 
                cnt_step <= (others => '0');
            else
                cnt_step <= std_logic_vector(unsigned(cnt_step) + 1);
            end if;  
        end if;
    end process;
    
    
    -- Priority encoder that converts the current one-hot spike.
    -- into the corresponding weight memory address.
    process(all) begin 
        weight_addr <= (others => '0');
        for i in 0 to in_size-1 loop
            if current_spike(i) = '1' then
                weight_addr <= std_logic_vector(to_unsigned(i, weight_addr'length));
                exit;
            end if;
        end loop;
    end process; 
    
    
    selected_spikes <=  layer_in         when state = INPUT  else 
                        remaining_spikes when state = WEIGHT else
                        (others => '0');
    
    
    -- Extract the least-significant active spike from the pending spike vector.
    -- Implements: x & (-x).               
    aux_current_spike <= selected_spikes and std_logic_vector(unsigned(not selected_spikes) + 1);
    
    -- Remove the selected spike from the pending set and
    -- register the spike to be processed during the next cycle.
    process(clk) begin
        if rising_edge(clk) then
            remaining_spikes <= selected_spikes and not aux_current_spike;
            current_spike <= aux_current_spike; 
        end if;
    end process;

    -- Assert when all spikes have been processed during the WEIGHT state.
    weight_accum_done <= '1' when unsigned(aux_current_spike) = 0 and state = WEIGHT else '0';
    output_state <= '1' when state = OUTPUT else '0';
    
end Behavioral;
