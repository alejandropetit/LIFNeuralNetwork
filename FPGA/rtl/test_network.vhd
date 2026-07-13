
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.fixed_pkg.all;library IEEE;
use ieee.fixed_pkg.all;use IEEE.STD_LOGIC_1164.ALL;
use WORK.NEURON_PACKAGE.ALL;


entity test_network is
end test_network;

architecture Behavioral of test_network is
        -- Parámetros
    constant int_width  : integer := 9;
    constant frac_width : integer := 9;
    constant depth      : integer := 3;
    constant int_size   : integer := 8;
    constant frac_size  : integer := 8;
    constant in_size    : integer := 3;
    constant out_size   : integer := 1;
    constant layer_size : integer := 2;
    constant beta       : real    := 0.9900498337;
    constant Vth        : real    := 100.0;
    
    -- Señales DUT
    signal clk       : std_logic;
    signal reset     : std_logic := '1';
    signal spike_in  : std_logic_vector(in_size-1 downto 0);
    signal spike_out0 : std_logic_vector(0 downto 0);
    signal spike_out1 : std_logic_vector(0 downto 0);
    signal spike_out2 : std_logic_vector(0 downto 0);

    -- Clock period
    constant clk_period : time := 10 ns;
        
begin
    uut0: entity work.lif_network
        generic map (
            int_width => int_width,
            frac_width => frac_width,
            in_size => in_size,
            out_size => out_size,
            layer_size => layer_size,
            decay_option => DECAY_EVERY_STEP,
            beta => beta,
            Vth => Vth
        )
        port map (
            clk       => clk,
            reset     => reset,
            network_in  => spike_in,
            network_out => spike_out0
        );
    uut1: entity work.lif_network
        generic map (
            int_width => int_width,
            frac_width => frac_width,
            in_size => in_size,
            out_size => out_size,
            layer_size => layer_size,
            decay_option => DECAY_ACCUMULATE,
            beta => beta,
            Vth => Vth
        )
        port map (
            clk       => clk,
            reset     => reset,
            network_in  => spike_in,
            network_out => spike_out1
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
        spike_in <= (others => '0');

        -- Reset activo
        wait for 20 ns;
        reset <= '0';


        spike_in <= "111"; wait for 65 ns;
        spike_in <= "110"; wait for 50 ns;
        spike_in <= "000"; wait for 40 ns;
        spike_in <= "000"; wait for 40 ns;
        spike_in <= "000"; wait for 40 ns;
        spike_in <= "100"; wait for 40 ns;
        spike_in <= "100"; wait for 40 ns;
        spike_in <= "011"; wait for 60 ns;
        spike_in <= "001"; wait for 60 ns;
        spike_in <= "100"; wait for 60 ns;
        spike_in <= "111"; wait for 60 ns;
        spike_in <= "011"; wait for 60 ns;
        spike_in <= "110"; wait for 60 ns;
        spike_in <= "011"; wait for 60 ns;
        spike_in <= "101"; wait for 60 ns;
        spike_in <= "110"; wait for 60 ns;
        spike_in <= "101"; wait for 60 ns;
        spike_in <= "010"; wait for 60 ns; 
        spike_in <= "111"; wait for 60 ns;
        spike_in <= "010"; wait for 60 ns;
        spike_in <= "110"; wait for 60 ns;
        spike_in <= "101"; wait for 60 ns;
        spike_in <= "010"; wait for 60 ns;
        spike_in <= "111"; wait for 60 ns;
        spike_in <= "010"; wait for 60 ns;       
        wait;
    end process;

end Behavioral;
