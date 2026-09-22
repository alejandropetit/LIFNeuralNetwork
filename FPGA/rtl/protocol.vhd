

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.neuron_package.ALL;


entity protocol is
    Port (
        clk:in STD_LOGIC;
        reset: in STD_LOGIC;
        
        ready_a: in STD_LOGIC;
        valid_a: out STD_LOGIC;
        data_a: out STD_LOGIC_VECTOR(103 downto 0);
        
        ready_b: out STD_LOGIC;
        valid_b: in STD_LOGIC;
        data_b: in STD_LOGIC_VECTOR(31 downto 0);
        
        reg_addr: out STD_LOGIC_VECTOR(1 downto 0);
        reg_wdata: out STD_LOGIC_VECTOR(7 downto 0);
        reg_rdata: in STD_LOGIC_VECTOR(7 downto 0);
        reg_status: in STD_LOGIC_VECTOR(5 downto 0);
        reg_we: out STD_LOGIC; 
        reg_re: out STD_LOGIC 
    );
end protocol;

architecture Behavioral of protocol is
    constant ADDR_TX_DATA: STD_LOGIC_VECTOR(1 downto 0) := "00";
    constant ADDR_RX_DATA: STD_LOGIC_VECTOR(1 downto 0) := "01";
    
    constant N_DATA1: natural := 13;
    constant N_SEND: natural := 6;
 
    constant BIT_TX_FULL  : natural := 0;
    constant BIT_RX_EMPTY : natural := 3;
    type statetype is (S_HEAD, S_MTYPE, S_DATA1, SNN_SEND, SNN_RECEIVE, SEND);
    signal state, nextstate: statetype;
    signal Header, Message_type: STD_LOGIC_VECTOR(7 downto 0);
    signal N: natural;
    
    
    signal DATA1: STD_LOGIC_VECTOR(103 downto 0);
    signal message: STD_LOGIC_VECTOR(47 downto 0);

begin
    
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= S_HEAD;
            else
                state <= nextstate;
            end if; 
        end if;
    end process;
    
    
    process(all) begin
        nextstate <= state;   
        case state is
            when S_HEAD =>
                if reg_status(BIT_RX_EMPTY) = '0' then
                    if reg_rdata = X"AA" then
                        nextstate <= S_MTYPE;
                    end if;
                end if;
            when S_MTYPE =>
                if reg_status(BIT_RX_EMPTY) = '0' then
                    if reg_rdata = X"01" then
                        nextstate <= S_DATA1;
                    else
                        nextstate <= S_HEAD;
                    end if;
                end if;
            when S_DATA1 =>
                if reg_status(BIT_RX_EMPTY) = '0' then
                    if N = N_DATA1 - 1 then
                        nextstate <= SNN_SEND;
                    end if;
                end if;
            when SNN_SEND =>  
                if ready_a = '1' and valid_a = '1' then
                    nextstate <= SNN_RECEIVE;
                end if;
            when SNN_RECEIVE => 
                if ready_b = '1' and valid_b = '1' then
                    nextstate <= SEND;
                end if;    
            when SEND =>
                if reg_status(BIT_TX_FULL) = '0' then
                    if N = N_SEND - 1 then
                        nextstate <= S_HEAD;
                    end if;
                end if;
        end case;
    end process;
    
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                HEADER <= (others => '0');
                Message_type <= (others => '0');
                DATA1 <= (others => '0');
                message <= (others => '0');
            else
                case state is
                    when S_HEAD => 
                        if reg_status(BIT_RX_EMPTY) = '0' then
                            HEADER <= reg_rdata;
                        end if;
                    when S_MTYPE => 
                         if reg_status(BIT_RX_EMPTY) = '0' then
                            Message_type <= reg_rdata;
                         end if;    
                    when S_DATA1 =>
                         if reg_status(BIT_RX_EMPTY) = '0' then 
                            DATA1((N+1)*8-1 downto N*8) <= reg_rdata;                                
                         end if;    
                    when SNN_RECEIVE =>
                         message <= data_b & x"02AA";
                    when others => 
                        null;              
                end case;
            end if;
        end if;    
    end process;
    
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                N <= 0;
            else
                if state = S_DATA1 then
                    if reg_status(BIT_RX_EMPTY) = '0' then
                        if N = N_DATA1 - 1 then
                            N <= 0;
                        else 
                            N <= N + 1;
                        end if;
                    end if;
                elsif state = SEND then  
                    if reg_status(BIT_TX_FULL) = '0' then 
                        if N = N_SEND - 1 then
                            N <= 0;
                        else 
                            N <= N + 1;
                        end if; 
                    end if;  
                else
                    N <= 0;
                end if;
            end if;
        end if;
    end process;

    reg_addr <= ADDR_RX_DATA when (state = S_HEAD or state = S_MTYPE or state = S_DATA1) else
                ADDR_TX_DATA when state = SEND else
                (others => '0');

    reg_re <= '1' when (state = S_HEAD or state = S_MTYPE or state = S_DATA1)
                    and reg_status(BIT_RX_EMPTY) = '0' else '0';
    
    reg_we <= '1' when state = SEND and reg_status(BIT_TX_FULL) = '0' else '0';
    
    reg_wdata <= message((N+1)*8-1 downto N*8) when state = SEND else (others => '0');
    
    valid_a <= '1' when state = SNN_SEND  else '0';

    ready_b <= '1' when state = SNN_RECEIVE else '0';
    
    data_a <= DATA1;
    

end Behavioral;
