
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.neuron_package.ALL;

entity UART_Rx is
    generic(
        oversample: positive := 16 
    );
    port(
        clk: in STD_LOGIC;
        reset: in STD_LOGIC;
        tick: in STD_LOGIC;
        Rx:  in STD_LOGIC ; 
        done: out STD_LOGIC;
        RDR: out STD_LOGIC_VECTOR(7 downto 0)
    );
end UART_Rx;

architecture Behavioral of UART_Rx is
    constant center_constant: positive := oversample/2;
    type statetype is (IDLE, START, DATA, STOP);
    signal state, nextstate: statetype;
    signal RxFF: STD_LOGIC_VECTOR(1 downto 0);
    signal RSR: STD_LOGIC_VECTOR(8 downto 0);
    signal center, dne: STD_LOGIC;
    signal start_count: STD_LOGIC;
    signal stop_valid: STD_LOGIC;
    signal counter: unsigned(clog2(oversample)-1 downto 0);
begin
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= IDLE;
            elsif tick = '1' then
                state <= nextstate;              
            end if;
        end if;
    end process;
    
    process(all) begin
        case state is
            when IDLE =>
                if RxFF(1) = '0' then
                    nextstate <= START;
                else 
                    nextstate <= IDLE;
                end if;
            when START =>
                if center = '1' and RxFF(1) /= '0' then
                    nextstate <= IDLE;
                elsif dne = '1' then
                    nextstate <= DATA;
                else
                    nextstate <= START; 
                end if;
            when DATA =>
                if dne = '1' and RSR(0) = '1' then
                    nextstate <= STOP;
                else
                    nextstate <= DATA;
                end if;
            when STOP =>
                if dne = '1' then
                    nextstate <= IDLE;
                else
                    nextstate <= STOP;
                end if;      
        end case;
    
    end process;
    
    process(clk) begin
        if rising_edge (clk) then
            if reset = '1' then
                RxFF <= (others => '1');    
            else
                RxFF(0) <= Rx;
                RxFF(1) <= RxFF(0);
            end if;
        end if;
    end process;
    
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                RDR <= (others => '0');
                RSR <= (others => '0');
                start_count <= '0';
                stop_valid <= '0';
                done <= '0';
            else
                done <= '0';
                if tick = '1' then
                    if state = IDLE then
                        if RxFF(1) = '0' then 
                            start_count <= '1';
                        else
                            start_count <= '0';
                        end if;    
                    elsif state = START then
                        RSR <= (8 => '1', others => '0');
                    elsif state = DATA then
                        if center = '1' then
                            RSR <= RxFF(1) & RSR(8 downto 1);    
                        end if;
                    elsif state = STOP then
                        if center = '1' then
                            stop_valid <= RxFF(1);
                        end if;
                        
                        if dne = '1' then
                            if stop_valid = '1' then
                                RDR <= RSR(8 downto 1);
                                stop_valid <= '0';
                                done <= '1';
                            end if;
                        end if;
                    end if;
                end if;
            end if;    
        end if;
    end process;
    
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                counter <= (others => '0');
            elsif tick = '1' then
                if state = IDLE then
                    counter <= (others => '0');
                elsif counter = oversample - 1 then
                    counter <= (others => '0');
                elsif start_count = '1' then
                    counter <= counter + 1;
                end if;
            end if;
        end if;
    end process;
    center <= '1' when counter = center_constant else '0';
    dne <= '1' when counter = oversample - 1 else '0';
    
end Behavioral;
