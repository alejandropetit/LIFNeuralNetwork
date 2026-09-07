
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.neuron_package.ALL;

entity Frequency_divider is
    generic(
        freq_in: positive := 50_000_000;
        tick_rate: positive := 115200
    );
    port(
        clk: in STD_LOGIC;
        reset: in STD_LOGIC;
        tick: out STD_LOGIC
    );
end Frequency_divider;

architecture Behavioral of Frequency_divider is
    constant DIVISOR : positive := freq_in / tick_rate;
    signal counter : unsigned(clog2(DIVISOR) - 1 downto 0);
begin
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                counter <= (others => '0');
                tick <= '0';
            elsif counter = DIVISOR - 1 then 
                counter <= (others => '0');
                tick <= '1';
            else  
                counter <= counter + 1;
                tick <= '0';
            end if; 
        end if;
    end process;
end Behavioral;
