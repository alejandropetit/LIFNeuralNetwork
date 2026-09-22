
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.FIXED_PKG.ALL;
use work.neuron_package.all;


entity output_interface is
    generic(
        -- Rudder
        max_out_rudder    : integer := 45;
        min_out_rudder    : integer := -45;
        min_spikes_rudder : natural := 0;
        max_spikes_rudder : positive := 61;
        out_states_rudder : positive := 13;
    
        -- Sail
        max_out_sail      : integer := 90;
        min_out_sail      : integer := -90;
        min_spikes_sail   : natural := 0;
        max_spikes_sail   : positive := 56;
        out_states_sail   : positive := 15;
        N_TIMESTEPS       : positive := 500
    );
    port(
        clk: in STD_LOGIC;
        reset: in STD_LOGIC;
        spikes_rudder: in STD_LOGIC;
        valid_rudder:in STD_LOGIC;
        spikes_sail: in STD_LOGIC;
        valid_sail: in STD_LOGIC;
        
        action: out STD_LOGIC_VECTOR(31 downto 0);
        valid: out STD_LOGIC;
        ready: in STD_LOGIC
         
                
    );
end output_interface;

architecture Behavioral of output_interface is
    type statetype is (MONITOR_SPIKES, PROCESSING1, PROCESSING2, OUTPUT);
    signal state, nextstate: statetype;
    
    signal sum_rudder : UNSIGNED(clog2(max_spikes_rudder + 1)-1 downto 0) := (others => '0');
    signal sum_sail   : UNSIGNED(clog2(max_spikes_sail + 1)-1 downto 0) := (others => '0');
    
    signal action_rudder : SIGNED(15 downto 0) := (others => '0');
    signal action_sail   : SIGNED(15 downto 0) := (others => '0');   
    
    signal done_rudder: STD_LOGIC;
    signal done_sail: STD_LOGIC;
    signal count_rudder: UNSIGNED(clog2(N_TIMESTEPS)-1 downto 0);
    signal count_sail: UNSIGNED(clog2(N_TIMESTEPS)-1 downto 0);
    
function decode_sail(spikes : unsigned) return integer is
    variable x : natural;
begin

    x := to_integer(spikes);

    case x is

        when 0 to 5 =>
            return -84;

        when 6 to 8 =>
            return -72;

        when 9 to 12 =>
            return -60;

        when 13 to 15 =>
            return -48;

        when 16 to 19 =>
            return -36;

        when 20 to 22 =>
            return -24;

        when 23 to 26 =>
            return -12;

        when 27 to 29 =>
            return 0;

        when 30 to 33 =>
            return 12;

        when 34 to 36 =>
            return 24;

        when 37 to 40 =>
            return 36;

        when 41 to 43 =>
            return 48;

        when 44 to 47 =>
            return 60;

        when 48 to 50 =>
            return 72;

        when others =>
            return 84;

    end case;

end function;  

function decode_rudder(spikes : unsigned) return integer is
    variable x : natural;
begin

    x := to_integer(spikes);

    case x is

        when 0 to 6 =>
            return -42;

        when 7 to 10 =>
            return -35;

        when 11 to 15 =>
            return -28;

        when 16 to 19 =>
            return -21;

        when 20 to 23 =>
            return -14;

        when 24 to 28 =>
            return -7;

        when 29 to 32 =>
            return 0;

        when 33 to 37 =>
            return 6;

        when 38 to 41 =>
            return 13;

        when 42 to 45 =>
            return 20;

        when 46 to 50 =>
            return 27;

        when 51 to 54 =>
            return 34;

        when others =>
            return 41;

    end case;

end function;
begin
    action <= std_logic_vector(action_sail) & std_logic_vector(action_rudder);

    valid <= '1' when state = OUTPUT else '0';  
    
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= MONITOR_SPIKES;
            else
                state <= nextstate;
            end if;
        end if;
    end process;  
    
    process(all) begin
        case state is 
            when MONITOR_SPIKES =>
                if done_rudder = '1' and done_sail = '1' then
                    nextstate <= PROCESSING1;      
                else
                    nextstate <= MONITOR_SPIKES;
                end if;
            when PROCESSING1 =>
                nextstate <= PROCESSING2;
            when PROCESSING2 => 
                nextstate <= OUTPUT;
            when OUTPUT => 
                if ready = '1' then
                    nextstate <= MONITOR_SPIKES;
                else
                    nextstate <= OUTPUT;
                end if;
        end case;    
    end process;
    
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                sum_rudder <= (others => '0');
                sum_sail <= (others => '0');
                count_rudder <= (others => '0');
                count_sail   <= (others => '0');            
                done_rudder <= '0';
                done_sail   <= '0';
            elsif state = OUTPUT and ready = '1' then         
                sum_rudder <= (others => '0');
                sum_sail   <= (others => '0');
                count_rudder <= (others => '0');
                count_sail   <= (others => '0');
                done_rudder <= '0';
                done_sail   <= '0';          
            elsif state = MONITOR_SPIKES then
                if valid_rudder = '1' and done_rudder = '0' then
    
                    if spikes_rudder = '1' then
                        if sum_rudder < max_spikes_rudder then
                            sum_rudder <= sum_rudder + 1;
                        end if;
                    end if;
    
                    if count_rudder = N_TIMESTEPS - 1 then
                        done_rudder <= '1';
                    else
                        count_rudder <= count_rudder + 1;
                    end if;
    
                end if;
    
                if valid_sail = '1' and done_sail = '0' then
    
                    if spikes_sail = '1' then
                        if sum_sail < max_spikes_sail then
                            sum_sail <= sum_sail + 1;
                        end if;
                    end if;
    
                    if count_sail = N_TIMESTEPS - 1 then
                        done_sail <= '1';
                    else
                        count_sail <= count_sail + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    process(clk) 
        variable decoded : integer;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                action_rudder <= (others => '0');
                action_sail <= (others => '0');
            elsif state = PROCESSING1 then
                action_rudder <= to_signed(decode_rudder(sum_rudder),action_rudder'length);
            elsif state = PROCESSING2 then
                action_sail <= to_signed(decode_sail(sum_sail),action_sail'length);
            end if;
        end if;
    end process;
   

end Behavioral;