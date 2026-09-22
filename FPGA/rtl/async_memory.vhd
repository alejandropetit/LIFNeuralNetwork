
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.neuron_package.ALL;
use STD.TEXTIO.all;
use ieee.std_logic_textio.all;



entity async_memory is
	generic
	(
	    width: positive;
	    depth: positive;
		mem_file: string
	);
    port
    (
        clk : in STD_LOGIC;
        we  : in STD_LOGIC;
        read_addr : in STD_LOGIC_VECTOR(clog2(depth)-1 downto 0);
        write_addr : in STD_LOGIC_VECTOR(clog2(depth)-1 downto 0);
        write_data: in STD_LOGIC_VECTOR(width-1 downto 0);
        read_data:  out STD_LOGIC_VECTOR(width-1 downto 0)
    );
end async_memory;

architecture Behavioral of async_memory is
    type RamType is array (0 to depth-1) of std_logic_vector (width - 1 downto 0);  
    impure function InitRamFromFile (
        RamFileName : in string

    ) return RamType is
        file RamFile : text is in RamFileName;
        variable RamFileLine : line;
        variable RAM         : RamType;
    begin
        for i in 0 to RAM'length - 1 loop
            readline(RamFile, RamFileLine);
            bread(RamFileLine, RAM(i));
        end loop;
        return RAM;
    end function;
    
    signal RAM: RamType := InitRamFromFile("../memory/" & mem_file);
    
begin
    process(clk) begin
        if rising_edge(clk) then
           if we = '1' then 
                RAM(to_integer(unsigned(write_addr))) <= write_data;          
           end if;        
        end if;
    end process;
    
    read_data <= RAM(to_integer(unsigned(read_addr)));
end Behavioral;
