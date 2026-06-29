-------------------------------------------------------------------------------
-- Automatic Washing Machine Controller
-- Digital System Design Lab Project
-- Group Members: Taha Muzaffar, Muhammad Umer Farooqui, Maham Faisal
-- Course: CEL-442 (BCE 7A)
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity washing_machine_controller is
    Port ( 
        clk           : in  STD_LOGIC;                      -- System clock
        rst_n         : in  STD_LOGIC;                      -- Active low reset
        start         : in  STD_LOGIC;                      -- Start button
        door_closed   : in  STD_LOGIC;                      -- Door sensor (1=closed)
        water_full    : in  STD_LOGIC;                      -- Water level sensor
        wash_mode     : in  STD_LOGIC_VECTOR(1 downto 0);   -- 00=Normal, 01=Heavy, 10=Delicate, 11=Quick
        
        -- Outputs
        door_lock     : out STD_LOGIC;                      -- Door lock control
        water_valve   : out STD_LOGIC;                      -- Water inlet valve
        detergent     : out STD_LOGIC;                      -- Detergent dispenser
        motor_on      : out STD_LOGIC;                      -- Motor power
        motor_dir     : out STD_LOGIC;                      -- Motor direction (1=CW, 0=CCW)
        drain_valve   : out STD_LOGIC;                      -- Water drain valve
        heater        : out STD_LOGIC;                      -- Water heater
        buzzer        : out STD_LOGIC;                      -- Completion buzzer
        display       : out STD_LOGIC_VECTOR(3 downto 0);   -- State display (for LEDs/7-seg)
        done          : out STD_LOGIC                       -- Wash cycle complete
    );
end washing_machine_controller;

architecture Behavioral of washing_machine_controller is
    
    -- FSM State Definition
    type state_type is (
        IDLE,           -- Waiting for start
        DOOR_CHECK,     -- Check if door is closed
        FILL_WATER,     -- Fill water tank
        HEAT_WATER,     -- Heat water (if needed)
        ADD_DETERGENT,  -- Add detergent
        WASH,           -- Washing cycle
        RINSE_DRAIN,    -- Drain water before rinse
        RINSE_FILL,     -- Fill water for rinse
        RINSE,          -- Rinse cycle
        SPIN_DRAIN,     -- Final drain
        SPIN,           -- Spin dry
        COMPLETE        -- Wash complete
    );
    
    signal current_state, next_state : state_type;
    
    -- Timer signals
    signal timer_counter   : STD_LOGIC_VECTOR(27 downto 0) := (others => '0');
    signal clk_1s_enable   : STD_LOGIC := '0';
    signal delay_counter   : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal timer_done      : STD_LOGIC := '0';
    signal timer_target    : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    
    -- Wash mode timing parameters
    signal wash_time       : STD_LOGIC_VECTOR(7 downto 0);
    signal rinse_time      : STD_LOGIC_VECTOR(7 downto 0);
    signal spin_time       : STD_LOGIC_VECTOR(7 downto 0);
    signal heat_enable     : STD_LOGIC;
    
begin
    
    -- Wash Mode Configuration Process
    process(wash_mode)
    begin
        case wash_mode is
            when "00" =>  -- Normal wash
                wash_time <= x"0A";      -- 10 seconds (scaled for simulation)
                rinse_time <= x"05";     -- 5 seconds
                spin_time <= x"03";      -- 3 seconds
                heat_enable <= '1';
                
            when "01" =>  -- Heavy duty
                wash_time <= x"0F";      -- 15 seconds
                rinse_time <= x"08";     -- 8 seconds
                spin_time <= x"05";      -- 5 seconds
                heat_enable <= '1';
                
            when "10" =>  -- Delicate
                wash_time <= x"06";      -- 6 seconds
                rinse_time <= x"04";     -- 4 seconds
                spin_time <= x"02";      -- 2 seconds
                heat_enable <= '0';
                
            when "11" =>  -- Quick wash
                wash_time <= x"04";      -- 4 seconds
                rinse_time <= x"02";     -- 2 seconds
                spin_time <= x"02";      -- 2 seconds
                heat_enable <= '0';
                
            when others =>
                wash_time <= x"0A";
                rinse_time <= x"05";
                spin_time <= x"03";
                heat_enable <= '0';
        end case;
    end process;
    
    -- State Register Process (Sequential Logic)
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            current_state <= IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;
    
    -- Next State Logic and Output Logic (Combinational)
    process(current_state, start, door_closed, water_full, timer_done, heat_enable)
    begin
        -- Default outputs
        door_lock <= '0';
        water_valve <= '0';
        detergent <= '0';
        motor_on <= '0';
        motor_dir <= '0';
        drain_valve <= '0';
        heater <= '0';
        buzzer <= '0';
        done <= '0';
        timer_target <= x"00";
        
        case current_state is
            
            when IDLE =>
                display <= "0000";  -- 0
                done <= '0';
                if start = '1' then
                    next_state <= DOOR_CHECK;
                else
                    next_state <= IDLE;
                end if;
                
            when DOOR_CHECK =>
                display <= "0001";  -- 1
                if door_closed = '1' then
                    door_lock <= '1';
                    next_state <= FILL_WATER;
                else
                    next_state <= DOOR_CHECK;
                end if;
                
            when FILL_WATER =>
                display <= "0010";  -- 2
                door_lock <= '1';
                water_valve <= '1';  -- Open water inlet
                if water_full = '1' then
                    next_state <= HEAT_WATER;
                else
                    next_state <= FILL_WATER;
                end if;
                
            when HEAT_WATER =>
                display <= "0011";  -- 3
                door_lock <= '1';
                timer_target <= x"03";  -- 3 seconds heating
                if heat_enable = '1' then
                    heater <= '1';
                    if timer_done = '1' then
                        next_state <= ADD_DETERGENT;
                    else
                        next_state <= HEAT_WATER;
                    end if;
                else
                    next_state <= ADD_DETERGENT;  -- Skip heating
                end if;
                
            when ADD_DETERGENT =>
                display <= "0100";  -- 4
                door_lock <= '1';
                detergent <= '1';
                timer_target <= x"02";  -- 2 seconds for detergent
                if timer_done = '1' then
                    next_state <= WASH;
                else
                    next_state <= ADD_DETERGENT;
                end if;
                
            when WASH =>
                display <= "0101";  -- 5
                door_lock <= '1';
                motor_on <= '1';
                motor_dir <= clk_1s_enable;  -- Alternate direction every second
                timer_target <= wash_time;
                if timer_done = '1' then
                    next_state <= RINSE_DRAIN;
                else
                    next_state <= WASH;
                end if;
                
            when RINSE_DRAIN =>
                display <= "0110";  -- 6
                door_lock <= '1';
                drain_valve <= '1';  -- Open drain
                timer_target <= x"03";  -- 3 seconds to drain
                if timer_done = '1' then
                    next_state <= RINSE_FILL;
                else
                    next_state <= RINSE_DRAIN;
                end if;
                
            when RINSE_FILL =>
                display <= "0111";  -- 7
                door_lock <= '1';
                water_valve <= '1';
                if water_full = '1' then
                    next_state <= RINSE;
                else
                    next_state <= RINSE_FILL;
                end if;
                
            when RINSE =>
                display <= "1000";  -- 8
                door_lock <= '1';
                motor_on <= '1';
                motor_dir <= clk_1s_enable;  -- Alternate direction
                timer_target <= rinse_time;
                if timer_done = '1' then
                    next_state <= SPIN_DRAIN;
                else
                    next_state <= RINSE;
                end if;
                
            when SPIN_DRAIN =>
                display <= "1001";  -- 9
                door_lock <= '1';
                drain_valve <= '1';
                timer_target <= x"03";  -- 3 seconds to drain
                if timer_done = '1' then
                    next_state <= SPIN;
                else
                    next_state <= SPIN_DRAIN;
                end if;
                
            when SPIN =>
                display <= "1010";  -- 10 (A)
                door_lock <= '1';
                motor_on <= '1';
                motor_dir <= '1';  -- High speed spin in one direction
                timer_target <= spin_time;
                if timer_done = '1' then
                    next_state <= COMPLETE;
                else
                    next_state <= SPIN;
                end if;
                
            when COMPLETE =>
                display <= "1111";  -- 15 (F)
                buzzer <= '1';
                done <= '1';
                timer_target <= x"03";  -- 3 seconds buzzer
                if timer_done = '1' then
                    next_state <= IDLE;
                else
                    next_state <= COMPLETE;
                end if;
                
            when others =>
                next_state <= IDLE;
                
        end case;
    end process;
    
    -- Timer Process (1 second clock enable generator)
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            timer_counter <= (others => '0');
            clk_1s_enable <= '0';
        elsif rising_edge(clk) then
            timer_counter <= timer_counter + 1;
            -- For simulation: trigger every 100 clocks
            -- For FPGA @ 50MHz: change to x"2FAF080" (50 million)
            if timer_counter >= x"0000064" then  -- 100 clock cycles for simulation
                timer_counter <= (others => '0');
                clk_1s_enable <= '1';
            else
                clk_1s_enable <= '0';
            end if;
        end if;
    end process;
    
    -- Delay Counter Process
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            delay_counter <= (others => '0');
            timer_done <= '0';
        elsif rising_edge(clk) then
            if clk_1s_enable = '1' then
                if delay_counter >= timer_target and timer_target /= x"00" then
                    timer_done <= '1';
                    delay_counter <= (others => '0');
                elsif timer_target /= x"00" then
                    delay_counter <= delay_counter + 1;
                    timer_done <= '0';
                else
                    delay_counter <= (others => '0');
                    timer_done <= '0';
                end if;
            else
                timer_done <= '0';
            end if;
        end if;
    end process;
    
end Behavioral;