
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.NEURON_PACKAGE.ALL;
use IEEE.FIXED_PKG.ALL;

entity datapath_neuron is
    generic( 
        width        : positive; -- total fixed-point width (integer + fractional bits)
        int_width    : natural; -- number of integer bits
        frac_width   : natural; -- number of fractional bits
        beta         : real; -- membrane decay factor
        Vth          : real; -- spike generation threshold
        decay_option : decay_option_t -- Selects how membrane decay is computed
    ); 
    Port ( 
        clk              :  in   STD_LOGIC; -- system clock
        reset            :  in   STD_LOGIC; -- active-high reset
        src_ctrl         :  in   STD_LOGIC; -- selects the 2:1 multiplexer input (weights or decay)         
        weight           :  in   STD_LOGIC_VECTOR(width-1 downto 0); -- synaptic weight corresponding to the current input spike
        decay_sig        :  in   SFIXED(int_width-1 downto -frac_width); -- accumulated membrane decay factor
        reset_out_spike  :  in   STD_LOGIC; -- reset for output spike register
        reset_out_u      :  in   STD_LOGIC; -- reset for output voltage register
        reset_acc        :  in   STD_LOGIC; -- reset for accumulate voltage register
        en_out_spike     :  in   STD_LOGIC; -- enable for output spike register
        en_out_u         :  in   STD_LOGIC; -- enable for output voltage register
        en_acc           :  in   STD_LOGIC; -- enable for accumulate voltage register
        zero             :  out  STD_LOGIC; -- asserted when the membrane voltage is zero
        y                :  out  STD_LOGIC; -- combinational output spike
        spike_out        :  out  STD_LOGIC  -- registered output spike
    );
end datapath_neuron;

architecture option1 of datapath_neuron is
    signal   u            :  SFIXED(int_width-1 downto -frac_width);
    signal   result       :  SFIXED(int_width-1 downto -frac_width);
    signal   accumulate   :  SFIXED(int_width-1 downto -frac_width);
    signal   decay_factor :  SFIXED(int_width-1 downto -frac_width);
    constant betasig      :  SFIXED(int_width-1 downto -frac_width) := to_sfixed(beta, int_width-1, -frac_width);
    constant Vthsig       :  SFIXED(int_width-1 downto -frac_width) := to_sfixed(Vth, int_width-1, -frac_width);
begin
--

decay_gen: if decay_option = DECAY_ACCUMULATE generate
    decay_factor <= decay_sig;
else generate
    decay_factor <= betasig;
end generate;

process(all) 
    variable decay  : SFIXED(int_width-1 downto -frac_width);
    variable src1   : SFIXED(int_width-1 downto -frac_width);
begin
    decay := resize(arg => u * decay_factor,
                    left_index => int_width-1,
                    right_index => -frac_width);
    src1 := decay when src_ctrl = '1' else to_sfixed(weight,int_width-1, -frac_width);
    result <= resize(arg => src1 + accumulate,left_index => int_width-1 ,right_index => -frac_width);
    y <= '1' when (accumulate >= Vthsig) else '0';
    zero <= '1' when (u = 0) else '0';
end process; 

--
--
process(clk) begin
    if rising_edge(clk) then
        if reset_acc='1' or reset= '1' then
            accumulate <= (others => '0');
        elsif en_acc = '1' then
            accumulate <= result;
        end if;
    end if;
end process;

process(clk) begin
    if rising_edge(clk) then
        if reset_out_spike = '1' or reset= '1' then
            spike_out <= '0';
        elsif en_out_spike = '1' then
            spike_out <= y;
        end if;
    end if;
end process;

process(clk) begin
    if rising_edge(clk) then
        if reset_out_u = '1' or reset= '1' then
            u <= (others => '0');
        elsif en_out_u = '1' then
            u <= accumulate;
        end if;
    end if;
end process;
--

end option1;

