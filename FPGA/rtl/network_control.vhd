
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
     valid_reg         : out STD_LOGIC;
     en_front          : out STD_LOGIC;
     en_back           : out STD_LOGIC;
     weights_done      : out STD_LOGIC; 
     ready             : out STD_LOGIC;
     out_valid         : out STD_LOGIC
  );
end network_control;

architecture Behavioral of network_control is
    signal ready_internal: STD_LOGIC;
    signal valid_b       : STD_LOGIC;
begin
    ready <= ready_internal and not valid_reg and not out_valid;
    en_back <= ready and valid;
    en_front <= output_state(0) and not ready_internal;
    weights_done <= and(weight_accum_done);
    valid_b <= not ready_internal;
    
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                ready_internal <= '1';
            elsif en_back = '1' then
                ready_internal <= '0';
            elsif en_front = '1' then
                ready_internal <= '1';
            end if;            
        end if;    
    end process;
    
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                valid_reg <= '0';
            elsif output_state(0) = '1' then
                valid_reg <= valid_b;
            end if;
        end if;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                out_valid <= '0';
            elsif output_state(0) = '1' and valid_reg = '1' then
                out_valid <= '1';
            else
                out_valid <= '0';
            end if;
        end if;
    end process;
    
end Behavioral;
