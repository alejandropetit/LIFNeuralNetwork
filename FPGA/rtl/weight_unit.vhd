
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use WORK.NEURON_PACKAGE.ALL;

entity weight_unit is
    generic(
        width : integer := 16;
        init_addr: integer;
        in_size: integer;
        mem_file : string
    ); 
    Port (
        clk: in STD_LOGIC;
        reset: in STD_LOGIC;
        we : in STD_LOGIC;
        addr : in STD_LOGIC_VECTOR(8 downto 0);
        din : in STD_LOGIC_VECTOR(71 downto 0);
        dout : out STD_LOGIC_VECTOR(71 downto 0)
    );
end weight_unit;

architecture Behavioral of weight_unit is
begin

    memory_inst: entity work.memory(inferred_sprom)
    generic map(
        init_addr => init_addr,
        in_size => in_size,
        mem_file => mem_file)
    port map (
        clk => clk,
        reset => reset,
        we => (others => '0'),
        read_addr => addr,
        write_addr => (others => '0'),
        write_data => din,
        read_data => dout
    );
    
end behavioral;

