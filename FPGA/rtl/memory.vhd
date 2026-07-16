
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--use ieee.std_logic_textio.all;
use STD.TEXTIO.all;
use WORK.NEURON_PACKAGE.ALL;


entity memory is
generic (
    width     : integer;
    depth     : integer;
    init_addr : integer;
    in_size   : integer;
    mem_file  : string
);
Port (
    clk        : in  STD_LOGIC;
    reset      : in  STD_LOGIC;
    we         : in  STD_LOGIC_VECTOR(0 downto 0);
    read_addr  : in  STD_LOGIC_VECTOR(clog2(depth)-1 downto 0);
    write_addr : in  STD_LOGIC_VECTOR(clog2(depth)-1 downto 0);
    write_data : in  STD_LOGIC_VECTOR(width-1 downto 0);
    read_data  : out STD_LOGIC_VECTOR(width-1 downto 0));
end memory;

architecture inferred_sdpram of memory is
    type RamType is array (0 to depth-1) of std_logic_vector (width-1 downto 0);
    
    impure function InitRamFromFile (
        RamFileName : in string;
        in_size     : in integer;
        init_addr   : in integer
    ) return RamType is
        file RamFile : text is in RamFileName;
        variable RamFileLine : line;
        variable RAM         : RamType;
    begin
        for j in 0 to init_addr-1 loop
            readline(RamFile, RamFileLine);
        end loop;
        
        for i in 0 to in_size-1 loop
            if not endfile(RamFile) then
                readline(RamFile, RamFileLine);
                hread(RamFileLine, RAM(i));
            end if;
        end loop;
        return RAM;
    end function;

    signal RAM : RamType := InitRamFromFile("../memory/" & mem_file, in_size, init_addr);
    attribute ram_style : string;
    attribute ram_style of RAM : signal is "block";    
begin
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                read_data <= (others => '0');
 
            else
                read_data <= RAM(to_integer(unsigned(read_addr)));
            end if;   
            
            RAM(to_integer(unsigned(write_addr))) <= write_data when (and we) = '1';
        end if;
    end process;
end inferred_sdpram;


architecture inferred_sprom of memory is
    type RamType is array (0 to depth-1) of std_logic_vector (width-1 downto 0);
    
    impure function InitRamFromFile (
        RamFileName : in string;
        in_size     : in integer;
        init_addr   : in integer
    ) return RamType is
        file RamFile : text is in RamFileName;
        variable RamFileLine : line;
        variable RAM         : RamType;
    begin
        for j in 0 to init_addr-1 loop
            readline(RamFile, RamFileLine);
        end loop;
        
        for i in 0 to in_size-1 loop
            if not endfile(RamFile) then
                readline(RamFile, RamFileLine);
                hread(RamFileLine, RAM(i));
            end if;
        end loop;
        return RAM;
    end function;
    signal RAM : RamType := InitRamFromFile("../memory/" & mem_file, in_size, init_addr);
    attribute ram_style : string;
    attribute ram_style of RAM : signal is "block";
begin
    process(clk) begin
        if rising_edge(clk) then
            read_data <= RAM(to_integer(unsigned(read_addr)));
        end if;
    end process;
end  inferred_sprom;



