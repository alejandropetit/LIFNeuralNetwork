
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use STD.TEXTIO.all;



package neuron_package is
    type state_type is(
        INPUT,
        WEIGHT,
        DECAY,
        OUTPUT
    );
    
    
    type int_array_t is array (natural range <>) of integer;
    type file_array_t is array (natural range <>) of string(1 to 8);
    type RamType is array (0 to 511) of std_logic_vector (71 downto 0);
    
    function clog2(n : positive) return natural;
    function max_array(x : int_array_t) return integer;
    impure function InitRamFromFile(
        RamFileName : string;
        in_size     : integer;
        init_addr   : integer
    ) return RamType;
    
    constant MEM_FILES : file_array_t(0 to 1) := (
        "mem0.mem",
        "mem1.mem"
    );


end neuron_package;


package body neuron_package is
    function clog2(n : positive) return natural is 
    begin
        if n <= 1 then
            return 1;
        end if;
        return integer(ceil(log2(real(n))));
    end function;
    
    function max_array(x : int_array_t) return integer is
        variable m : integer;
    begin

        m := x(x'low);

        for i in x'range loop
            if x(i) > m then
                m := x(i);
            end if;
        end loop;

        return m;

    end function;
    
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
    
    
    
end package body;
