library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.NEURON_PACKAGE.ALL;

entity control_neuron is
    generic( in_size     : positive;
             step_size   : positive := in_size + 3;
             refrac      : natural:=4);
    Port ( clk             :  in   STD_LOGIC;
           reset           :  in   STD_LOGIC;
           zero            :  in   STD_LOGIC;
           spike           :  in   STD_LOGIC;
           spike_out       :  in   STD_LOGIC;
           spike_in        :  in   STD_LOGIC_VECTOR(in_size-1 downto 0);
           cnt_step        :  in   STD_LOGIC_VECTOR(clog2(step_size)-1 downto 0);
           actual_weight   :  in   STD_LOGIC_VECTOR(in_size-1 downto 0);
           state           :  in   state_type;
           reset_out_spike :  out  STD_LOGIC;
           reset_out_u     :  out  STD_LOGIC;
           reset_acc       :  out  STD_LOGIC;
           en_out_spike    :  out  STD_LOGIC;
           en_out_u        :  out  STD_LOGIC;
           en_acc          :  out  STD_LOGIC;  
           src_ctrl        :  out  STD_LOGIC);
end control_neuron;

architecture Behavioral2 of control_neuron is
    signal cnt_refrac : unsigned( clog2(refrac)-1 downto 0 ) := (others => '0');
    signal ctrl_state : STD_LOGIC;
    signal neuron_state : state_type;
begin

    
    process(all) begin
        ctrl_state <= '1' when (zero='1' and unsigned(spike_in)=0) or (spike_out='0' and cnt_refrac /= 0) or (zero = '0' and unsigned(spike_in) = 0 and state = WEIGHT) else '0';
        neuron_state <= state when ctrl_state = '0' else INPUT; 
    end process;

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
end Behavioral2;
