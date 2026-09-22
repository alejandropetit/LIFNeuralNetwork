
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity SNN_system is
    port(
        clk: in STD_LOGIC;
        reset:in STD_LOGIC;
        Rx: in STD_LOGIC;
        Tx: out STD_LOGIC
    );
end SNN_system;

architecture Behavioral of SNN_system is
    signal data: STD_LOGIC_VECTOR(103 downto 0);
    signal action: STD_LOGIC_VECTOR(31 downto 0);
    signal data_valid: STD_LOGIC;
    signal data_ready: STD_LOGIC;
    signal action_valid: STD_LOGIC;
    signal action_ready: STD_LOGIC; 
    signal reset_system: STD_LOGIC;
    signal locked: STD_LOGIC;
    signal clk_20m: STD_LOGIC;
begin

controller: entity work.SNN_Controller
port map(
        clk => clk_20m,
        reset => reset_system,
        data => data,
        data_valid => data_valid,
        data_ready => data_ready,
        action => action,
        action_valid => action_valid,
        action_ready => action_ready
);

communicate: entity work.communication
port map(  
        clk => clk_20m,
        reset => reset_system,
        Rx => Rx,
        Tx => Tx,
        ready_a => data_ready,
        valid_a =>data_valid,
        data_a => data,
        ready_b => action_ready,
        valid_b => action_valid,
        data_b => action
); 


CLK_GEN : entity work.clk_wiz_0
port map (
    clk_in1  => clk,
    clk_out1 => clk_20m,
    reset    => reset,
    locked   => locked
);


reset_system <= reset or not locked;
end Behavioral;
