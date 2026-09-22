

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity communication is
    generic(
        oversample: positive := 16;
        clk_freq: positive := 20_000_000;
        baud_rate: positive := 9600;
        tx_fifo_depth: positive := 16;
        rx_fifo_depth: positive := 16
    );
    Port ( 
        clk: in STD_LOGIC;
        reset: in STD_LOGIC;
        
        Rx: in STD_LOGIC;
        Tx: out STD_LOGIC;
        
        ready_a: in STD_LOGIC;
        valid_a: out STD_LOGIC;
        data_a: out STD_LOGIC_VECTOR(103 downto 0);
        
        ready_b: out STD_LOGIC;
        valid_b: in STD_LOGIC;
        data_b: in STD_LOGIC_VECTOR(31 downto 0)

    );
end communication;

architecture Behavioral of communication is
        signal reg_addr: STD_LOGIC_VECTOR(1 downto 0);
        signal reg_wdata: STD_LOGIC_VECTOR(7 downto 0);
        signal reg_rdata: STD_LOGIC_VECTOR(7 downto 0);
        signal reg_status:  STD_LOGIC_VECTOR(5 downto 0);
        signal reg_we: STD_LOGIC; 
        signal reg_re: STD_LOGIC; 
begin
    
        U_UART: entity work.UART
        generic map(
            oversample => oversample,
            clk_freq => clk_freq,
            baud_rate => baud_rate,
            tx_fifo_depth => tx_fifo_depth,
            rx_fifo_depth => rx_fifo_depth
        )
        port map(
            clk => clk,
            reset => reset,
            Rx => Rx,
            Tx => Tx,
            reg_addr => reg_addr,
            reg_wdata => reg_wdata,
            reg_rdata => reg_rdata,
            reg_we => reg_we,
            reg_re => reg_re,
            reg_status => reg_status
   
        );
        
        inst_pro: entity work.protocol
        Port map (
            clk => clk,
            reset => reset,
            
            ready_a => ready_a,
            valid_a => valid_a,
            data_a => data_a,
            
            ready_b => ready_b,
            valid_b => valid_b,
            data_b => data_b,
            
            reg_addr => reg_addr,
            reg_wdata => reg_wdata,
            reg_rdata => reg_rdata,
            reg_status => reg_status,
            reg_we => reg_we,
            reg_re => reg_re 
        );

end Behavioral;
