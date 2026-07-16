
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.fixed_pkg.all;library IEEE;
use ieee.fixed_pkg.all;use IEEE.STD_LOGIC_1164.ALL;
use WORK.NEURON_PACKAGE.ALL;


entity test_network is
end test_network;

architecture Behavioral of test_network is
        -- Parámetros
    constant int_width  : integer := 1;
    constant frac_width : integer := 1;
    constant neuron_size: int_array_t := (3,1);
    constant beta       : real_array_t    := (0.9900498337, 0.9900498337);
    constant Vth        : real_array_t    := (100.0, 100.0);
    
    -- Señales DUT
    signal clk       : std_logic;
    signal reset     : std_logic := '1';
    signal valid     : std_logic;
    signal ready     : std_logic;
    signal spike_in  : std_logic_vector(neuron_size(neuron_size'low)-1 downto 0);
    signal spike_out0 : std_logic_vector(0 downto 0);
    signal spike_out1 : std_logic_vector(0 downto 0);
    signal spike_out2 : std_logic_vector(0 downto 0);
    
    procedure send_sample(
        signal clk      : in std_logic;
        signal ready    : in std_logic;
        signal valid    : out std_logic;
        signal spike_in : out std_logic_vector(neuron_size(neuron_size'low)-1 downto 0);
        constant data   : std_logic_vector(neuron_size(neuron_size'low)-1 downto 0);
        constant idle   : time := 0 ns
    ) is
    begin
        spike_in <= data;
        valid <= '1';
    
        wait until rising_edge(clk) and ready = '1';
    
        valid <= '0';
    
        wait for idle;
    end procedure;
    
    
    -- Clock period
    constant clk_period : time := 10 ns;
        
begin
    uut0: entity work.lif_network
        generic map (
            int_width => int_width,
            frac_width => frac_width,
            network_shape => neuron_size,
            decay_option => DECAY_EVERY_STEP,
            beta => beta,
            Vth => Vth
        )
        port map (
            clk       => clk,
            reset     => reset,
            valid => valid,
            ready => ready,
            network_in  => spike_in,
            network_out => spike_out0
        );
    uut1: entity work.lif_network
        generic map (
            int_width => int_width,
            frac_width => frac_width,
            network_shape => neuron_size,
            decay_option => DECAY_ACCUMULATE,
            beta => beta,
            Vth => Vth
        )
        port map (
            clk       => clk,
            reset     => reset,
            valid => valid,
            ready => ready,
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
        

        send_sample(clk, ready, valid, spike_in, "111", 65 ns);
        send_sample(clk, ready, valid, spike_in, "110", 50 ns);
        send_sample(clk, ready, valid, spike_in, "000", 40 ns);
        send_sample(clk, ready, valid, spike_in, "000", 40 ns);
        send_sample(clk, ready, valid, spike_in, "000", 40 ns);
        send_sample(clk, ready, valid, spike_in, "100", 40 ns);
        send_sample(clk, ready, valid, spike_in, "100", 40 ns);
        send_sample(clk, ready, valid, spike_in, "011", 60 ns);
        send_sample(clk, ready, valid, spike_in, "001", 60 ns);
        send_sample(clk, ready, valid, spike_in, "100", 60 ns);
        send_sample(clk, ready, valid, spike_in, "111", 60 ns);
        send_sample(clk, ready, valid, spike_in, "011", 60 ns);
        send_sample(clk, ready, valid, spike_in, "110", 60 ns);
        send_sample(clk, ready, valid, spike_in, "011", 60 ns);
        send_sample(clk, ready, valid, spike_in, "101", 60 ns);
        send_sample(clk, ready, valid, spike_in, "110", 60 ns);
        send_sample(clk, ready, valid, spike_in, "101", 60 ns);
        send_sample(clk, ready, valid, spike_in, "010", 60 ns);
        send_sample(clk, ready, valid, spike_in, "111", 60 ns);
        send_sample(clk, ready, valid, spike_in, "010", 60 ns);
        send_sample(clk, ready, valid, spike_in, "110", 60 ns);
        send_sample(clk, ready, valid, spike_in, "101", 60 ns);
        send_sample(clk, ready, valid, spike_in, "010", 60 ns);
        send_sample(clk, ready, valid, spike_in, "111", 60 ns);
        send_sample(clk, ready, valid, spike_in, "010", 60 ns);      
        wait;
    end process;

end Behavioral;
