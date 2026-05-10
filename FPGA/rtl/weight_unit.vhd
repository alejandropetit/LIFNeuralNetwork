

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use WORK.NEURON_PACKAGE.ALL;
use STD.TEXTIO.all;

entity weight_unit is
    generic(depth : integer := 2;
            width : integer := 16); 
            
    Port (clk: in STD_LOGIC;
          we : in STD_LOGIC;
          addr : in STD_LOGIC_VECTOR(clog2(depth)-1 downto 0);
          din : in STD_LOGIC_VECTOR(width-1 downto 0);
          dout : out STD_LOGIC_VECTOR(width-1 downto 0));
end weight_unit;

architecture Behavioral of weight_unit is
   type RamType is array (depth-1 downto 0) of bit_vector(width-1 downto 0);
     
    impure function InitRamFromFile(RamFileName : in string) return RamType is    
        file RamFile : text is in RamFileName;
        variable RamFileLine : line;
        variable RAM : RamType;
    begin 
        for I in RamType'range loop
            readline(RamFile, RamFileLine);
            read(RamFileLine, RAM(I));
        end loop;
    return RAM;
    end function;

    signal weights : RamType := InitRamFromFile("init.txt");
begin
    process(clk) begin
        if rising_edge(clk) then 
            if we = '1' then
                weights(to_integer(unsigned(addr))) <= to_bitvector(din);
            end if;
            if to_integer(unsigned(addr)) < weights'length then
                dout <= to_stdlogicvector(weights(to_integer(unsigned(addr))));
            else
                dout <= (others => '0');
            end if;
        end if;
    end process;
end Behavioral;
