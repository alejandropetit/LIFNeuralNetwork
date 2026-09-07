
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.neuron_package.ALL;

entity UART_Tx is
    generic(
        oversample: positive := 16
    );
    port(
        clk: in STD_LOGIC;
        reset: in STD_LOGIC;
        tick: in STD_LOGIC;
        load: in STD_LOGIC;
        data_bus: in STD_LOGIC_VECTOR(7 downto 0);
        busy: out STD_LOGIC;
        tx_ready: out STD_LOGIC;
        Tx: out STD_LOGIC     
    );
end UART_Tx;

architecture Behavioral of UART_Tx is
    type stateType is (IDLE, START, DATA, STOP);
    signal state, nextstate: stateType;
    signal tick_counter: unsigned(clog2(oversample)-1 downto 0);
    signal load_pending: STD_LOGIC;
    signal TDR: STD_LOGIC_VECTOR(7 downto 0);
    signal TSR: STD_LOGIC_VECTOR(8 downto 0);
    
    
begin

    
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= IDLE;
                tick_counter <= (others => '0');
            else
                if tick = '1' then
                    if tick_counter = oversample - 1 then
                        tick_counter <= (others => '0');
                        state <= nextstate;
                    else
                        tick_counter <= tick_counter + 1;
                    end if;
                end if;
            end if;    
        end if;
    end process;
    
    
    
    process(all) begin
        case state is
            when IDLE =>
                if load_pending = '1' then 
                    nextstate <= START;
                else
                    nextstate <= IDLE;
                end if;
            when START =>
                nextstate <= DATA;   
            when DATA => 
                if unsigned(TSR) <= 3 then
                    nextstate <= STOP;
                else
                    nextstate <= DATA;
                end if;
            when STOP => 
                nextstate <= IDLE;
        end case;
    end process;
    
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                load_pending <= '0';
                TDR <= (others => '1');
            elsif load = '1' and load_pending = '0' then
                load_pending <= '1';
                TDR <= data_bus;
            elsif tick = '1' and tick_counter = oversample - 1 and state = START then
                load_pending <= '0';
            end if;        
        end if;
    end process;
        
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                TSR <= (others => '1');
            elsif tick = '1' then
                if tick_counter = oversample - 1 then
                    if state = IDLE then
                        TSR <= (others => '1');
                    elsif state = START then
                        TSR <= '1' & TDR;
                    else
                        TSR <= '0' & TSR(8 downto 1);
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    busy <= '0' when state = IDLE else '1';
    
    tx_ready <= not load_pending;
    
    with state select
        Tx <= '1'    when IDLE,
              '0'    when START,
              TSR(0) when DATA,
              '1'    when STOP;
end Behavioral;
