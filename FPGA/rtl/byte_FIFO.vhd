

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.neuron_package.ALL;

entity byte_FIFO is
    generic(
        depth : positive := 16
    );
    port(
        clk: in STD_LOGIC;
        reset: in STD_LOGIC;
        wr_en: in STD_LOGIC;
        wr_data: in STD_LOGIC_VECTOR(7 downto 0);
        rd_en: in STD_LOGIC;
        rd_data: out STD_LOGIC_VECTOR(7 downto 0);
        full: out STD_LOGIC; 
        empty: out STD_LOGIC
        
    );
end byte_FIFO;

architecture Behavioral of byte_FIFO is
    type mem_array is array (0 to depth -1) of STD_LOGIC_VECTOR(7 downto 0);
    signal mem: mem_array;
    signal wr_accept, rd_accept: STD_LOGIC;
    signal full_i, empty_i: STD_LOGIC;
    signal wr_ptr, rd_ptr: natural range 0 to depth - 1 ;
    signal fifo_count: unsigned(clog2(depth+1)-1 downto 0);
begin
    wr_accept <= '1' when wr_en = '1' and full_i = '0' else '0';
    rd_accept <= '1' when rd_en = '1' and empty_i = '0' else '0';
    full_i <= '1' when fifo_count = depth else '0';
    empty_i <= '1' when fifo_count = 0 else '0'; 
    full <= full_i;
    empty <= empty_i;
    
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                fifo_count <= (others => '0');
                rd_ptr <= 0;
                wr_ptr <= 0;
            else
                if wr_accept = '1' then
                    mem(wr_ptr) <= wr_data;
                    if wr_ptr = depth - 1 then
                        wr_ptr <= 0;
                    else
                        wr_ptr <= wr_ptr + 1;
                    end if;
                end if;
                
                if rd_accept = '1' then
                    if rd_ptr = depth - 1 then
                        rd_ptr <= 0;
                    else
                        rd_ptr <= rd_ptr + 1;
                    end if;                    
                end if;
                
                if wr_accept = '1' and rd_accept = '0' then
                    fifo_count <= fifo_count + 1;
                end if;
                
                if wr_accept = '0' and rd_accept = '1' then
                    fifo_count <= fifo_count - 1;
                end if;                
                
            end if;
        end if;
    end process;
    
    rd_data <= mem(rd_ptr);

end Behavioral;
