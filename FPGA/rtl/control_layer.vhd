library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.NEURON_PACKAGE.ALL;
use IEEE.NUMERIC_STD.ALL;

entity control_layer is
    generic(in_size   : positive;
            step_size : positive := in_size + 3);
    Port ( clk           :  in   STD_LOGIC;
           reset         :  in   STD_LOGIC;
           weight_all    :  in   STD_LOGIC;
           spike_in      :  in   STD_LOGIC_VECTOR(in_size-1 downto 0);
           first_cycle   :  out  STD_LOGIC;
           w_ready       :  out  STD_LOGIC; 
           current_spike :  out  STD_LOGIC_VECTOR(in_size-1 downto 0);
           addr          :  out  STD_LOGIC_VECTOR(clog2(in_size)-1 downto 0);     
           cnt_step      :  out  STD_LOGIC_VECTOR( clog2(step_size)-1 downto 0 ); --counter for the duration of the step 
           state         :  out  state_type                                       
    );
end control_layer;

architecture Behavioral of control_layer is
    signal next_state: state_type;
    signal selected_spikes, remaining_spikes: STD_LOGIC_VECTOR(in_size-1 downto 0);
    signal aux_current_spike : STD_LOGIC_VECTOR(in_size-1 downto 0);
begin
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
                if weight_all = '1' then
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
    
    process(clk) begin 
        if rising_edge (clk) then
            if first_cycle ='1' or unsigned(cnt_step) = step_size-1 then 
                cnt_step <= (others => '0');
            else
                cnt_step <= std_logic_vector(unsigned(cnt_step) + 1);
            end if;  
        end if;
    end process;
    
    
    process(all) begin 
        addr <= (others => '0');
        for i in 0 to in_size-1 loop
            if current_spike(i) = '1' then
                addr <= std_logic_vector(to_unsigned(i, addr'length));
                exit;
            end if;
        end loop;
    end process; 
    
    
    selected_spikes <=  spike_in         when state = INPUT  else 
                        remaining_spikes when state = WEIGHT else
                        (others => '0');
                        
    aux_current_spike <= selected_spikes and std_logic_vector(unsigned(not selected_spikes) + 1);
    
    process(clk) begin
        if rising_edge(clk) then
            remaining_spikes <= selected_spikes and not aux_current_spike;
            current_spike <= aux_current_spike; 
        end if;
    end process;

    w_ready <= '1' when unsigned(aux_current_spike) = 0 and state = WEIGHT else '0';
    
end Behavioral;
