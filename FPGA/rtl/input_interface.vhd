

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.FIXED_PKG.ALL;
use IEEE.FIXED_FLOAT_TYPES.ALL;
use work.neuron_package.ALL;



entity input_interface is
    generic (
        area1: positive := 120;
        area2: positive := 60;
        tacking_angle1: integer := 70;
        tacking_angle2: integer := 45;
        max_speed: real := 0.35;
        sensormax1: positive := 60;
        sensormax2: positive := 30;
        k1: positive := 12;
        k2: positive := 1;
        k3: positive := 36;
        --clk_freq: positive:= 125_000_000;
        --time_period: real := 0.5;   --in_seconds
        
        output_cycles: positive := 500--integer(real(clk_freq) * time_period)
    );
    Port ( 
        clk: in STD_LOGIC;
        reset: in STD_LOGIC;
        
        ready: out STD_LOGIC;
        valid: in STD_LOGIC;
        data:  in STD_LOGIC_VECTOR(103 downto 0);
        
        ready_SNN: in STD_LOGIC; 
        valid_SNN: out STD_LOGIC;
        spikes_rudder: out STD_LOGIC_VECTOR(2*k1*k2-1 downto 0);
        spikes_sail: out STD_LOGIC_VECTOR(4*k3-1 downto 0)   
    );
end input_interface;

architecture Behavioral of input_interface is


   
    type statetype is (INPUT, PROC1,PROC1B, PROC2, PROC3, OUTPUT);
    signal state, nextstate: statetype;
    signal speed: SFIXED(1 downto -14);
    signal receive_pitch, yaw: SFIXED(8 downto -7);
    signal wind: SFIXED(8 downto -7); 
    signal aparent_wind, receive_desired_heading: SFIXED(8 downto -7);
    signal alpha, beta: SFIXED(8 downto -7);
    signal current_heading, real_wind_angle: SFIXED(8 downto -7);
    signal to_UW, to_TW: STD_LOGIC;
    signal obj_is_UW, obj_is_TW: STD_LOGIC;
    signal phase: SFIXED(8 downto -7);
    signal tack_direction: STD_LOGIC;
    signal tack_angle: SFIXED(8 downto -7);
    signal h: SFIXED(8 downto -7); 
    signal tack_angle_logic0, tack_angle_logic1: SFIXED(8 downto -7);
    signal L1: STD_LOGIC;
    signal L2: SFIXED(8 downto -7);
    signal L3: STD_LOGIC;
    signal tack_sign: STD_LOGIC;
    signal tack: STD_LOGIC;
    signal desired_heading: SFIXED(8 downto -7);
    signal err_ang: SFIXED(8 downto -7);
    signal waypoint2: STD_LOGIC;
    signal pitch: SFIXED(8 downto -7);
    signal sum_angle: SFIXED(8 downto -7);
    signal n1, n2: natural;
    signal ns1: natural;
    
    constant tack_angle_UW_1: SFIXED(8 downto -7) := to_sfixed(tacking_angle1, tack_angle'high, tack_angle'low); 
    constant tack_angle_UW_2: SFIXED(8 downto -7) := to_sfixed(-tacking_angle1, tack_angle'high, tack_angle'low);
    constant tack_angle_TW_1: SFIXED(8 downto -7) := to_sfixed(-tacking_angle2, tack_angle'high, tack_angle'low); 
    constant tack_angle_TW_2: SFIXED(8 downto -7) := to_sfixed(tacking_angle2, tack_angle'high, tack_angle'low);
    
    constant counter_max: positive := output_cycles;--integer(real(clk_freq) * time_period) ;
    constant angle_scale: positive := 2**7;

    signal counter: unsigned(clog2(counter_max)-1 downto 0);
    signal output_index_rudder: natural;
    signal output_index_sail: natural;
    signal valid_pulse : STD_LOGIC := '0';
    signal ready_SNN_d  : STD_LOGIC := '0';
    signal tack_angle_valid: STD_LOGIC;
    signal temp_desired_heading: SFIXED(8 downto -7);
    
    signal generated_spikes: STD_LOGIC_VECTOR(3 downto 0);
    
    
    subtype angle_t is SFIXED(10 downto -7);
    subtype angle_result_t is SFIXED(8 downto -7);
    
    function angle_wrap(angle : SFIXED) return angle_result_T is
        variable result : SFIXED(angle'high downto angle'low);
    begin
        result := angle;
        
        if result >= to_sfixed(180.0, angle'high, angle'low) then
            result := resize(result - to_sfixed(360.0, angle'high, angle'low), angle'high, angle'low);
        elsif result < to_sfixed(-180.0, angle'high, angle'low) then
            result := resize(result + to_sfixed(360.0, angle'high, angle'low), angle'high, angle'low);
        end if;
        
        return resize(result, 8, -7);
    end function;

    
begin
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= INPUT;
            else
                state <= nextstate;
            end if;
        end if;
    end process;
    
    process(all) begin
        case state is
            when INPUT =>
                if ready = '1' and valid = '1' then
                    nextstate <= PROC1;
                else
                    nextstate <= INPUT;
                end if;
            when PROC1 =>
                nextstate <= PROC1B;
            when PROC1B => 
                nextstate <= PROC2;
            when PROC2 =>
                nextstate <= PROC3;
            when PROC3 =>
                nextstate <= OUTPUT;
            when OUTPUT =>
                if valid_SNN = '1' and ready_SNN = '1' and  counter = counter_max - 1 then
                    nextstate <= INPUT;
                else
                    nextstate <= OUTPUT;
                end if;         
        end case;
    end process;
    
    process(clk) 
        variable next_tack_direction: STD_LOGIC;
        variable temp_err_ang: SFIXED(8 downto -7);
        variable next_tack_sign: STD_LOGIC;
        variable temp_tack_angle: SFIXED(8 downto -7);
        variable err_raw: integer; 
        variable pitch_raw: integer;
        variable sum_raw: integer;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                tack_angle_logic0 <= (others => '0');
                tack_angle_valid <= '0';
                tack_direction <= '1';
                tack <= '0';
                tack_sign <= '0';
                receive_pitch <= (others => '0');
                yaw <= (others => '0');
                wind <= (others => '0');
                aparent_wind <= (others => '0');
                receive_desired_heading <= (others => '0');
                speed <= (others => '0');
                waypoint2 <= '0';                 
            	counter <= (others => '0');
            	temp_desired_heading <= (others => '0');
                desired_heading      <= (others => '0');
	    else
                case state is
                    when INPUT => 
                        if ready = '1' and valid = '1' then
                            receive_pitch <= to_sfixed(data(15 downto 0), receive_pitch'high, receive_pitch'low);
                            yaw <= to_sfixed(data(31 downto 16), yaw'high, yaw'low);
                            wind <= to_sfixed(data(47 downto 32), wind'high, wind'low);
                            receive_desired_heading <= to_sfixed(data(63 downto 48), receive_desired_heading'high, receive_desired_heading'low);
                            aparent_wind <= to_sfixed(data(79 downto 64), aparent_wind'high, aparent_wind'low);
                            speed <= to_sfixed(data(95 downto 80),speed'high,speed'low);
                            waypoint2 <= data(96);
                        end if;
                    when PROC1 => 
                        next_tack_direction := tack_direction;
                        next_tack_sign      := tack_sign;
                        
                        if (to_UW = '1' and obj_is_UW = '1') or (to_TW = '1' and obj_is_TW = '1') then
                            
                            tack_angle_valid <= '1';
                            
                            if L1 = '1' and tack_angle_valid = '1' then
                                next_tack_sign := '1';
                            end if;
                            
                            if tack = '0' then
                                next_tack_direction := h(h'high);  
                                next_tack_sign := L3;
                            elsif speed > max_speed and L2 < (tack_angle + to_sfixed(30, tack_angle'high, tack_angle'low))  and L2 > (tack_angle - to_sfixed(30, tack_angle'high, tack_angle'low)) and next_tack_sign = '1' then
                                next_tack_direction := not tack_direction;
                                next_tack_sign := '0';
                            end if;
                             
                                                        
                            if to_UW = '1' and obj_is_UW = '1' then
                            
                                if next_tack_direction = '1' then
                                    temp_tack_angle := tack_angle_UW_1; -- +area1
                                else
                                    temp_tack_angle := tack_angle_UW_2; -- -area1
                                end if;
                            
                            elsif to_TW = '1' and obj_is_TW = '1' then
                            
                                if next_tack_direction = '1' then
                                    temp_tack_angle := tack_angle_TW_1; -- -area2
                                else
                                    temp_tack_angle := tack_angle_TW_2; -- +area2
                                end if;
                            
                            end if;
                            
                            tack_angle_logic0 <= tack_angle_logic1;
                            temp_desired_heading <= angle_wrap(resize(temp_tack_angle, 10, -7) + resize(real_wind_angle, 10, -7) + resize(phase, 10, -7));
                            tack_direction <= next_tack_direction;
                            tack_sign <= next_tack_sign;
                            tack <= '1';       
                        else
                            tack <= '0';
                            tack_angle_valid <= '0';
                            temp_desired_heading <= receive_desired_heading;
                        end if;
                        
                    when PROC1B =>   
                        if waypoint2 = '1' then
                            desired_heading <= angle_wrap(
                                resize(temp_desired_heading, 10, -7) +
                                to_sfixed(180, 10, -7)
                            );
                        else
                            desired_heading <= temp_desired_heading;
                        end if;
                    /* 
                        if temp_desired_heading /= to_sfixed(0, temp_desired_heading'high, temp_desired_heading'low ) and waypoint2 = '1' then
                            if temp_desired_heading(temp_desired_heading'high) = '1' then
                                desired_heading <= angle_wrap(resize(temp_desired_heading, 10, -7) + to_sfixed(180, 10, -7));
                            else
                                desired_heading <= angle_wrap(resize(temp_desired_heading, 10, -7) - to_sfixed(180, 10, -7));
                            end if;
                        elsif temp_desired_heading = to_sfixed(0, temp_desired_heading'high, temp_desired_heading'low ) then
                            desired_heading <= to_sfixed(180, desired_heading'high, desired_heading'low);
                        else
                            desired_heading <= temp_desired_heading;
                        end if;*/
                    when PROC2 =>
                        temp_err_ang := angle_wrap( resize(desired_heading, 10, -7) - resize(current_heading, 10, -7));
                        
                        if waypoint2 = '1' then
                            temp_err_ang := resize(-temp_err_ang,temp_err_ang'high,temp_err_ang'low);
                        end if;
                        
                        if temp_err_ang >= sensormax1 or temp_err_ang <= -sensormax1 then
                            if temp_err_ang(temp_err_ang'high) = '1' then
                                err_ang <= to_sfixed(-(sensormax1 -1), err_ang'high, err_ang'low);    
                            else
                                err_ang <= to_sfixed((sensormax1 -1), err_ang'high, err_ang'low); 
                            end if;
                        else
                            err_ang <= temp_err_ang;
                        end if;   
                        
                        if receive_pitch >= sensormax2 or receive_pitch <= -sensormax2 then
                            if receive_pitch(receive_pitch'high) = '1' then
                                pitch <= to_sfixed(-(sensormax2 -1), pitch'high, pitch'low);    
                            else
                                pitch <= to_sfixed((sensormax2 -1), pitch'high, pitch'low); 
                            end if;
                        else
                            pitch <= receive_pitch;
                        end if;
                    when PROC3 =>
                        err_raw := to_integer(signed(to_slv(err_ang)));
                        
                        pitch_raw := to_integer(signed(to_slv(pitch)));
                        
                        sum_raw := to_integer(signed(to_slv(sum_angle)));
                        
                        n1 <= ((err_raw + sensormax1*angle_scale) * k1) /(2*sensormax1*angle_scale);
                        n2 <= ((pitch_raw + sensormax2*angle_Scale) * k2) / (2*sensormax2*angle_scale);
                        ns1 <= ((sum_raw + 180*angle_scale) * k3) / (360*angle_scale);
                    when OUTPUT => 
                        if valid_SNN = '1' and ready_SNN = '1' then
                            if counter = counter_max - 1 then
                                counter <= (others => '0');
                            else
                                counter <= counter + 1;       
                            end if;
                        end if; 
                end case;
            end if;
        end if;           
    end process;
    
    process(all) begin
        if to_UW = '1' and obj_is_UW = '1'  then
            phase <= to_sfixed(180, phase'high, phase'low);
            tack_angle <= tack_angle_UW_1 when tack_direction = '1' else tack_angle_UW_2;
            tack_angle_logic1 <= angle_wrap(resize(receive_desired_heading, 10, -7) - resize(real_wind_angle, 10, -7));
        elsif to_TW = '1' and obj_is_TW = '1' then
            phase <= to_sfixed(0, phase'high, phase'low);
            tack_angle <= tack_angle_TW_1 when tack_direction = '1' else tack_angle_TW_2;
            tack_angle_logic1 <= angle_wrap(resize(receive_desired_heading, 10, -7) - resize(real_wind_angle, 10, -7));
        else
            phase <= to_sfixed(0, phase'high, phase'low);
            tack_angle <= to_sfixed(0, tack_angle'high, tack_angle'low);
            tack_angle_logic1 <= (others => '0');
        end if;
    end process;
    
    
    
    
    
    current_heading <= yaw;
    real_wind_angle <= angle_wrap(resize(wind, 10, -7) + resize(current_heading, 10, -7));
    h <= angle_wrap(resize(current_heading, 10, -7) - resize(real_wind_angle, 10, -7));
    L1 <= '1' when (tack_angle_logic1 > 0 and tack_angle_logic0 <= 0) or (tack_angle_logic1 < 0 and tack_angle_logic0 >= 0) else '0'; 
    L2 <= angle_wrap(resize(h, 10, -7) + resize(phase, 10, -7));
    L3 <= '1' when (L2 >= 0 and tack_angle_logic1 >= 0) or (L2 <0 and tack_angle_logic1 < 0) else '0';      
    sum_angle <= angle_wrap(resize(aparent_wind, 10, -7) + resize(current_heading, 10, -7));
    
---------    
    alpha <= resize(-wind, 8, -7);
    beta <= angle_wrap(resize(receive_desired_heading, 10, -7) - resize(real_wind_angle, 10, -7));
---------

---------
    to_UW <= '1' when (180.0 - real(area1) * 0.5) < alpha or (0.5*real(area1)-180.0) > alpha else '0';
    obj_is_UW <= '1' when 180.0 - real(area1) * 0.5 < beta or 0.5*real(area1)-180.0 > beta else '0';
    to_TW <= '1' when alpha < real(area2) * 0.5 and alpha > -real(area2) * 0.5 else '0';
    obj_is_TW <= '1' when beta < real(area2) * 0.5 and beta > -real(area2) * 0.5 else '0';
---------    

    output_index_rudder <= 2*(k1*n2+n1);
    output_index_sail <= 2*(k3 + ns1) when waypoint2 = '1' else 2*ns1; 
    ready <= '1' when state = INPUT else '0';
    
            

    encoder_inst: entity work.encoder
    generic map(
        width => 4,
        depth => 500,
        mem_file => "poisson.mem"
    )
    port map(
        clk => clk, 
        reset => reset,
        en => valid_pulse,
        spikes => generated_spikes
    );
    
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                ready_SNN_d <= '0';
                valid_pulse <= '0';
    
            elsif state = OUTPUT then
                ready_SNN_d <= ready_SNN;
                valid_pulse <= ready_SNN and not ready_SNN_d;
    
            else
                ready_SNN_d <= '0';
                valid_pulse <= '0';
            end if;
        end if;
    end process;
    
    valid_SNN <= valid_pulse;
    
   
    process(all)
    begin
        spikes_rudder <= (others => '0');
    
        for i in 0 to k1*k2-1 loop
            if 2*i = output_index_rudder then
                spikes_rudder(2*i+1 downto 2*i) <=
                    generated_spikes(1 downto 0);
            end if;
        end loop;
    end process;
        
    process(all)
    begin
        spikes_sail <= (others => '0');
    
        for i in 0 to 2*k3-1 loop
            if 2*i = output_index_sail then
                spikes_sail(2*i+1 downto 2*i) <=
                    generated_spikes(3 downto 2);
            end if;
        end loop; 
    end process;

end Behavioral;
