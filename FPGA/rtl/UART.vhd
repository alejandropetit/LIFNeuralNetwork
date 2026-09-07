
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity UART is
    generic(
        oversample: positive := 16;
        clk_freq: positive := 50000000;
        baud_rate: positive := 115200;
        tx_fifo_depth: positive := 16;
        rx_fifo_depth: positive := 16
    );
    port(
        clk : in STD_LOGIC;
        reset: in STD_LOGIC;
        Rx: in STD_LOGIC;
        Tx: out STD_LOGIC;
        
        reg_addr: in STD_LOGIC_VECTOR(1 downto 0);
        reg_wdata: in STD_LOGIC_VECTOR(7 downto 0);
        reg_rdata: out STD_LOGIC_VECTOR(7 downto 0);
        reg_we: in STD_LOGIC;
        reg_re: in STD_LOGIC;
        reg_status: out STD_LOGIC_VECTOR(5 downto 0)
        
    );
end UART;

architecture Behavioral of UART is
    constant tick_rate: positive := baud_rate * oversample;
    constant ADDR_TX_DATA: STD_LOGIC_VECTOR(1 downto 0) := "00";
    constant ADDR_RX_DATA: STD_LOGIC_VECTOR(1 downto 0) := "01";
    --constant ADDR_STATUS : STD_LOGIC_VECTOR(1 downto 0) := "10";
    signal tick: STD_LOGIC;
    signal tx_load, tx_busy, tx_ready: STD_LOGIC;
    signal tx_data_bus: STD_LOGIC_VECTOR(7 downto 0);
    signal tx_wr_en, tx_rd_en: STD_LOGIC; 
    signal tx_wr_data, tx_rd_data: STD_LOGIC_VECTOR(7 downto 0);
    signal tx_full, tx_empty: STD_LOGIC;
    signal rx_done: STD_LOGIC;
    signal rx_data: STD_LOGIC_VECTOR(7 downto 0);
    signal rx_wr_en, rx_rd_en: STD_LOGIC; 
    signal rx_wr_data, rx_rd_data: STD_LOGIC_VECTOR(7 downto 0);
    signal rx_full, rx_empty: STD_LOGIC;   
    signal rx_overrun: STD_LOGIC; 

begin

    baud_gen: entity work.Frequency_divider
    generic map(
        freq_in => clk_freq,
        tick_rate => tick_rate
    )
    port map(
        clk => clk,
        reset => reset,
        tick => tick  
    ); 

    U_TX: entity work.UART_Tx
    generic map(
        oversample => oversample
    )
    port map(
        clk => clk,
        reset => reset,
        tick => tick,
        load => tx_load,
        data_bus => tx_data_bus,
        busy => tx_busy,
        tx_ready => tx_ready,
        Tx => Tx
    );
    
    TX_FIFO: entity work.byte_FIFO
    generic map (
        depth => tx_fifo_depth
    )
    port map(
        clk => clk,
        reset => reset,
        wr_en => tx_wr_en,
        wr_data => tx_wr_data,
        rd_en => tx_rd_en,
        rd_data => tx_rd_data,
        full => tx_full,
        empty => tx_empty
    );
    tx_wr_en <= '1' when (reg_we = '1' and reg_addr = ADDR_TX_DATA and tx_full = '0') else '0';--
    tx_wr_data <= reg_wdata;--
    tx_rd_en <= '1' when tx_empty = '0' and tx_ready = '1' else '0';
    tx_load <= tx_rd_en;
    tx_data_bus <= tx_rd_data;
    
    U_RX: entity work.UART_Rx
    generic map(
        oversample => oversample
    )
    port map(
        clk => clk,
        reset => reset,
        tick => tick,
        Rx => Rx,       
        done => rx_done,
        RDR => rx_data      
    );
    
    RX_FIFO: entity work.byte_FIFO
    generic map (
        depth => rx_fifo_depth
    )
    port map(
        clk => clk,
        reset => reset,
        wr_en => rx_wr_en,
        wr_data => rx_wr_data,
        rd_en => rx_rd_en,
        rd_data => rx_rd_data,
        full => rx_full,
        empty => rx_empty
    );
    
    rx_wr_en <= '1' when rx_done = '1' and rx_full = '0' else '0' ;
    rx_wr_data <= rx_data;
    rx_rd_en <='1' when (reg_re = '1' and reg_addr = ADDR_RX_DATA and rx_empty = '0') else '0' ;--

    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                rx_overrun <= '0';
            elsif rx_done = '1' and rx_full = '1' then
                rx_overrun <= '1';
            end if;
        end if;
    end process;
 

    process(all) begin
        case reg_addr is
            when ADDR_RX_DATA =>
                reg_rdata <= rx_rd_data;
            when others =>
                reg_rdata <= (others => '0');
        end case;
    end process;
    


    reg_status <= (
        0 => tx_full,
        1 => tx_empty,
        2 => rx_full,
        3 => rx_empty,
        4 => tx_busy,
        5 => rx_overrun
        --others => '0'
    );

end Behavioral;
