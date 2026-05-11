
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.NEURON_PACKAGE.ALL;
use ieee.fixed_pkg.all;


entity test_neuron is
end test_neuron;

architecture Behavioral of test_neuron is

    -- Parámetros
    constant width      : integer := 16;
    constant depth      : integer := 3;
    constant num_inputs : integer := 3;
    constant int_size:    integer := 8;
    constant frac_size:   integer := 8;

    -- Señales DUT
    signal clk       : std_logic;
    signal reset     : std_logic := '1';
    signal beta      : std_logic_vector(width-1 downto 0);
    signal Vth       : std_logic_vector(width-1 downto 0);
    signal spike_in  : std_logic_vector(num_inputs-1 downto 0);
    signal spike_out : std_logic;

    -- Clock period
    constant clk_period : time := 10 ns;

begin

    -- Instancia del DUT
    uut: entity work.lif_neuron
        generic map (
            width => width,
            depth => depth,
            num_inputs => num_inputs
        )
        port map (
            clk       => clk,
            reset     => reset,
            beta      => beta,
            Vth       => Vth,
            spike_in  => spike_in,
            spike_out => spike_out
        );

    -- Generador de clock
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
    end process;

    -- Estímulos
    stim_proc: process
    begin
        -- Inicialización
        beta <= std_logic_vector(to_sfixed(0.9900498337, int_size-1, -frac_size));
        Vth <= std_logic_vector(to_sfixed(100.0, int_size-1, -frac_size));
        spike_in <= (others => '0');

        -- Reset activo
        wait for 20 ns;
        reset <= '0';


        spike_in <= "100"; wait for 65 ns;
        spike_in <= "011"; wait for 60 ns;
        spike_in <= "001"; wait for 60 ns;
        spike_in <= "000"; wait for 60 ns;
        spike_in <= "011"; wait for 60 ns;
        spike_in <= "100"; wait for 60 ns;
        spike_in <= "100"; wait for 60 ns;
        spike_in <= "011"; wait for 60 ns;
        spike_in <= "001"; wait for 60 ns;
        spike_in <= "100"; wait for 60 ns;
        spike_in <= "010"; wait for 60 ns;
        spike_in <= "001"; wait for 60 ns;
        spike_in <= "100"; wait for 60 ns;
        spike_in <= "011"; wait for 60 ns;
        spike_in <= "010"; wait for 60 ns;     
        wait;
    end process;
end Behavioral;
