
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.NEURON_PACKAGE.ALL;


entity control_neuron is
    generic( depth       : positive := 3;
             step_size   : positive := depth + 3;
             refrac      : natural := 5 );
    Port ( clk             :  in   STD_LOGIC;
           reset           :  in   STD_LOGIC;
           spike_in        :  in   STD_LOGIC_VECTOR(depth-1 downto 0);
           spike           :  in   STD_LOGIC;
           spike_out       :  in   STD_LOGIC;
           reset_out_spike :  out  STD_LOGIC;
           reset_out_u     :  out  STD_LOGIC;
           reset_acc       :  out  STD_LOGIC;
           en_out_spike    :  out  STD_LOGIC;
           en_out_u        :  out  STD_LOGIC;
           en_acc          :  out  STD_LOGIC;  
           src_ctrl        :  out  STD_LOGIC;
           cnt_step_out    :  out  STD_LOGIC_VECTOR(clog2(step_size)-1 downto 0));
end control_neuron;

architecture Behavioral2 of control_neuron is
    type statetype is (INPUT, WEIGHT, DECAY, OUTPUT);
    signal cnt_weight : unsigned( clog2(depth)-1  downto 0 );
    signal cnt_refrac : unsigned( clog2(refrac)-1 downto 0 );
    signal cnt_step   : unsigned( clog2(step_size)-1 downto 0 );
    signal state, next_state: statetype;
    signal refractory_flag: STD_LOGIC;
begin

--State Machine
    process(all)
    begin
        case state is
            when INPUT =>
                if reset ='1' then
                    next_state <= INPUT;
                else
                    next_state <= WEIGHT;
                end if;
            when WEIGHT =>
                if cnt_weight = depth-1 then
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
        else
            if rising_edge(clk) then
                state <= next_state;
            end if;
        end if;
    end process;
--
    
--Counters  
 cnt_step_out <= STD_LOGIC_VECTOR(cnt_step);   
    
    process(clk) begin
        if rising_edge (clk) then
            if reset ='1' then 
                cnt_refrac <= (others => '0');
                cnt_step <= (others => '0');
            else         
                if cnt_step = step_size-1 then
                    cnt_step <= (others => '0');
                    if spike ='1' then
                        cnt_refrac <= to_unsigned(refrac, cnt_refrac'length);
                    elsif cnt_refrac > 0 then
                        cnt_refrac <= cnt_refrac - 1;
                    end if;
                else
                    cnt_weight <= cnt_step(clog2(depth)-1  downto 0); 
                    cnt_step <= cnt_step + 1;
                end if;  
           end if;
        end if;
    end process;
 --
 
 --Deecoder

    
    process(all) begin
        case state is
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
                en_acc <= spike_in(to_integer(cnt_weight)) when cnt_refrac = 0 else '0';  
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
end Behavioral2;
