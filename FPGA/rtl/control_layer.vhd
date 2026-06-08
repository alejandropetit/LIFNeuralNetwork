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
           actual_weight :  out  STD_LOGIC_VECTOR(in_size-1 downto 0);
           addr          :  out  STD_LOGIC_VECTOR(clog2(in_size)-1 downto 0);
           cnt_step      :  out  STD_LOGIC_VECTOR( clog2(step_size)-1 downto 0 );
           state         :  out  state_type);
end control_layer;

architecture Behavioral of control_layer is
    signal next_state: state_type;
    signal cnt_weight : unsigned( clog2(in_size)-1  downto 0 );
    signal u_spikes, u1_spikes: STD_LOGIC_VECTOR(in_size-1 downto 0);
    signal actual_spike : STD_LOGIC_VECTOR(in_size-1 downto 0);
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
            if first_cycle ='1' then 
                cnt_step <= (others => '0');
            else        
                if unsigned(cnt_step) = step_size-1 then
                    cnt_step <= (others => '0');
                else
                    cnt_weight <= unsigned(cnt_step(clog2(in_size)-1  downto 0)); 
                    cnt_step <= std_logic_vector(unsigned(cnt_step) + 1);
                end if;  
           end if;
        end if;
    end process;
    
    
    process(all) begin 
        addr <= (others => '0');
        for i in 0 to in_size-1 loop
            if actual_spike(i) = '1' then
                addr <= std_logic_vector(to_unsigned(i, addr'length));
                exit;
            end if;
        end loop;
        
        if state = INPUT then 
            u_spikes <= spike_in; 
            actual_spike <= spike_in and std_logic_vector(unsigned(not spike_in) + 1);
        elsif state = WEIGHT then 
            u_spikes <= u1_spikes; 
            actual_spike <= u1_spikes and std_logic_vector(unsigned(not u1_spikes) + 1);
        else 
            u_spikes <= (others => '0'); 
            actual_spike <= (others => '0');
        end if; 
    end process; 
    
    process(clk) begin 
        if rising_edge(clk) then 
            u1_spikes <= u_spikes and not actual_spike;
            actual_weight <= actual_spike; 
        end if; 
    end process;
    
    w_ready <= '1' when unsigned(actual_spike) = 0  and state = WEIGHT else '0';
    

end Behavioral;
