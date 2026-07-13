
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.NEURON_PACKAGE.ALL;
use IEEE.NUMERIC_STD.ALL;

entity network_control is
  generic(
    layer_size   : positive
  );
  Port (clk : in STD_LOGIC;
        reset: in STD_LOGIC;
        start:  in STD_LOGIC;
        weight_accum_done: in STD_LOGIC_VECTOR(layer_size-1 downto 0);
        weights_done: out STD_LOGIC; 
        ready:  out STD_LOGIC
  );
end network_control;

architecture Behavioral of network_control is
    
begin

    weights_done <= and(weight_accum_done);
end Behavioral;
