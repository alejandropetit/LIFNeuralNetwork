
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
     valid_reg         : out STD_LOGIC_VECTOR(layer_size-1 downto 0);
     en_front          : out STD_LOGIC;
     en_back           : out STD_LOGIC;
     weights_done      : out STD_LOGIC; 
     ready             : out STD_LOGIC;
     out_valid         : out STD_LOGIC
  );
end network_control;

architecture Behavioral of network_control is
    signal valid_b       : STD_LOGIC;
begin
    en_back <= ready and valid;
    en_front <= output_state(0) and not ready;
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
    
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                valid_b <= '0';
            elsif en_back = '1' then
                valid_b <= '1';
            else
                valid_b <= '0';
            end if;
        end if;
    end process;
    
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                valid_reg <= (others => '0');
            elsif output_state(0) = '1' then
                valid_reg(0) <= valid_b;

                for i in 1 to layer_size-1 loop
                    valid_reg(i) <= valid_reg(i-1);
                end loop;
            end if;
        end if;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                out_valid <= '0';
    
            elsif output_state(0) = '1' then
                out_valid <= valid_reg(layer_size - 1);
    
            else
                out_valid <= '0';
            end if;
        end if;
    end process;
    
end Behavioral;
