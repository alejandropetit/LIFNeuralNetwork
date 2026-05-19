
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.fixed_pkg.all;


entity test_layer is
end test_layer;

architecture Behavioral of test_layer is
        -- Parámetros
    constant width      : integer := 16;
    constant depth      : integer := 3;
    constant int_size:    integer := 8;
    constant frac_size:   integer := 8;

    -- Señales DUT
    signal clk       : std_logic;
    signal reset     : std_logic := '1';
    signal beta      : std_logic_vector(width-1 downto 0);
    signal Vth       : std_logic_vector(width-1 downto 0);
    signal spike_in  : std_logic_vector(depth-1 downto 0);
    signal spike_out : std_logic_vector(1 downto 0);

    -- Clock period
    constant clk_period : time := 10 ns;

begin
    uut: entity work.lif_layer
        generic map (
            width => width,
            depth => depth
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
