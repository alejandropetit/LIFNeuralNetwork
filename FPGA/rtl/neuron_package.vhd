
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;



package neuron_package is
    type state_type is(
        INPUT,
        WEIGHT,
        DECAY,
        OUTPUT
    );
    
    
    type int_array_t is array (natural range <>) of integer;
    
    function clog2(n : positive) return natural;
    function max_array(x : int_array_t) return integer;
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
end package body;
