
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use WORK.NEURON_PACKAGE.ALL;
use IEEE.FIXED_PKG.ALL;

entity datapath_neuron is
    generic( width      : integer := 16;
             int_width  : integer := 8;
             frac_width : integer := 8;
             depth      : integer := 2);
    Port ( clk              :  in   STD_LOGIC;
           reset            :  in   STD_LOGIC;
           reset_out_spike  :  in   STD_LOGIC;
           reset_out_u      :  in   STD_LOGIC;
           reset_acc        :  in   STD_LOGIC;
           en_out_spike     :  in   STD_LOGIC;
           en_out_u         :  in   STD_LOGIC;
           en_acc           :  in   STD_LOGIC; 
           src_ctrl         :  in   STD_LOGIC;          
           Vth              :  in   STD_LOGIC_VECTOR(width-1 downto 0);
           beta             :  in   STD_LOGIC_VECTOR(width-1 downto 0);
           weight           :  in   STD_LOGIC_VECTOR(width-1 downto 0);
           y                :  out  STD_LOGIC;
           spike_out        :  out  STD_LOGIC);
end datapath_neuron;

architecture Behavioral of datapath_neuron is
    signal   u           :  SFIXED(int_width-1 downto -frac_width);
    signal   result      :  SFIXED(int_width-1 downto -frac_width);
    signal   accumulate  :  SFIXED(int_width-1 downto -frac_width);
    signal   decay_out   :  SFIXED(int_width-1 downto -frac_width);
    signal   src1_out    :  SFIXED(int_width-1 downto -frac_width);
    signal   a : integer;
begin

--
process(all) 
    variable decay  : SFIXED(int_width-1 downto -frac_width);
    variable   src1 : SFIXED(int_width-1 downto -frac_width);
begin
    decay := resize(arg => u * to_sfixed(beta, int_width-1, -frac_width),
                    left_index => int_width-1,
                    right_index => -frac_width);
    src1 := decay when src_ctrl = '1' else to_sfixed(weight,int_width-1, -frac_width);
    result <= resize(arg => src1 + accumulate,left_index => int_width-1 ,right_index => -frac_width);
    y <= '1' when (accumulate >= to_sfixed(Vth, int_width-1, -frac_width)) else '0';
    decay_out <= decay;
    src1_out <= src1;
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


end Behavioral;
