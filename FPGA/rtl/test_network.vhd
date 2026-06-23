
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.fixed_pkg.all;library IEEE;
use ieee.fixed_pkg.all;use IEEE.STD_LOGIC_1164.ALL;


entity test_network is
end test_network;

architecture Behavioral of test_network is
        -- Parámetros
    constant int_width  : integer := 8;
    constant frac_width : integer := 8;
    constant depth      : integer := 3;
    constant int_size   : integer := 8;
    constant frac_size  : integer := 8;
    constant in_size    : integer := 7;
    constant out_size   : integer := 1;
    constant layer_size : integer := 2;
    constant beta       : real    := 0.9900498337;
    constant Vth        : real    := 100.0;
    
    -- Señales DUT
    signal clk       : std_logic;
    signal reset     : std_logic := '1';
    signal spike_in  : std_logic_vector(in_size-1 downto 0);
    signal spike_out : std_logic_vector(0 downto 0);

    -- Clock period
    constant clk_period : time := 10 ns;

begin
    uut: entity work.lif_network
        generic map (
            int_width => int_width,
            frac_width => frac_width,
            in_size => in_size,
            out_size => out_size,
            layer_size => layer_size,
            beta => beta,
            Vth => Vth
        )
        port map (
            clk       => clk,
            reset     => reset,
            network_in  => spike_in,
            network_out => spike_out
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


        spike_in <= "1111110"; wait for 65 ns;
        spike_in <= "1101101"; wait for 60 ns;
        spike_in <= "1011010"; wait for 60 ns;
        spike_in <= "1111111"; wait for 60 ns;
        spike_in <= "1101100"; wait for 60 ns;
        spike_in <= "1001000"; wait for 60 ns;
        spike_in <= "1001001"; wait for 60 ns;
        spike_in <= "0110110"; wait for 60 ns;
        spike_in <= "0010011"; wait for 60 ns;
        spike_in <= "1001000"; wait for 60 ns;
        spike_in <= "1111111"; wait for 60 ns;
        spike_in <= "0110111"; wait for 60 ns;
        spike_in <= "1101101"; wait for 60 ns;
        spike_in <= "0110111"; wait for 60 ns;
        spike_in <= "1011011"; wait for 60 ns;
        spike_in <= "1101100"; wait for 60 ns;
        spike_in <= "1011010"; wait for 60 ns;
        spike_in <= "0100101"; wait for 60 ns; 
        spike_in <= "1111111"; wait for 60 ns;
        spike_in <= "0100100"; wait for 60 ns;
        spike_in <= "1101100"; wait for 60 ns;
        spike_in <= "1011010"; wait for 60 ns;
        spike_in <= "0100100"; wait for 60 ns;
        spike_in <= "1111111"; wait for 60 ns;
        spike_in <= "0100101"; wait for 60 ns;    
        wait;
    end process;

end Behavioral;
