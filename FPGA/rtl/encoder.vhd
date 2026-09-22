
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--use work.io_package.all;
use work.neuron_package.all;

entity encoder is
    generic(
        width : positive;
        depth : positive;
        mem_file: string
    );
    port(
        clk: in STD_LOGIC;
        reset: in STD_LOGIC;
        en: in STD_LOGIC;
        spikes: out STD_LOGIC_VECTOR(width-1 downto 0)       
    );
end encoder;   

architecture Behavioral of encoder is
    signal addr: STD_LOGIC_VECTOR(clog2(depth)-1 downto 0);
begin
    poisson_memory: entity work.async_memory
    generic map(
        width => width,
        depth => depth,
        mem_file => mem_file
    )
    port map(
        clk => clk,
        we => '0',
        write_addr => (others => '0'),
        write_data => (others => '0'),
        read_addr => addr,
        read_data => spikes
    );
    
    process(clk) begin
        if rising_edge(Clk) then
            if reset = '1' then 
                addr <= (others => '0');
            elsif en = '1' then
                if unsigned(addr) = depth - 1 then 
                    addr <= (others => '0');
                else
                    addr <= std_logic_vector(unsigned(addr) + 1);
                end if;
            end if;
        end if;
    end process;
end Behavioral; 
    