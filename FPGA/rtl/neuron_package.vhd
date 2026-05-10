
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;



package neuron_package is
    function clog2(n : positive) return natural;
end neuron_package;


package body neuron_package is
    function clog2(n : positive) return natural is 
    begin
        if n <= 1 then
            return 1;
        end if;
        return integer(ceil(log2(real(n))));
    end function;
end package body;
