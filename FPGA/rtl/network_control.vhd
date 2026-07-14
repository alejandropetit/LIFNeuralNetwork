
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.NEURON_PACKAGE.ALL;
use IEEE.NUMERIC_STD.ALL;

entity network_control is
  generic(
     layer_size : positive
  );
  Port (
     clk               : in  STD_LOGIC;
     reset             : in  STD_LOGIC;
     valid             : in  STD_LOGIC;
     weight_accum_done : in  STD_LOGIC_VECTOR(layer_size-1 downto 0);
     output_state      : in  STD_LOGIC_VECTOR(layer_size-1 downto 0);
     en_front          : out STD_LOGIC;
     en_back           : out STD_LOGIC;
     weights_done      : out STD_LOGIC; 
     ready             : out STD_LOGIC
  );
end network_control;

architecture Behavioral of network_control is
begin
    en_back <= '1' when ready = '1' and valid = '1' else '0';
    en_front <= '1' when output_state(0) = '1' and ready = '0' else '0';
    weights_done <= and(weight_accum_done);
    
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                ready <= '1';
            elsif en_back = '1' then
                ready <= '0';
            elsif en_front = '1' then
                ready <= '1';
            end if;            
        end if;    
    end process;
    
end Behavioral;
