-------------------------------------------------------------------------------
-- Testbench for Automatic Washing Machine Controller
-- Digital System Design Lab Project
-- Group Members: Taha Muzaffar, Muhammad Umer Farooqui, Maham Faisal
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity tb_washing_machine is
end tb_washing_machine;

architecture test of tb_washing_machine is
    
    -- Component Declaration
    component washing_machine_controller
        Port ( 
            clk           : in  STD_LOGIC;
            rst_n         : in  STD_LOGIC;
            start         : in  STD_LOGIC;
            door_closed   : in  STD_LOGIC;
            water_full    : in  STD_LOGIC;
            wash_mode     : in  STD_LOGIC_VECTOR(1 downto 0);
            door_lock     : out STD_LOGIC;
            water_valve   : out STD_LOGIC;
            detergent     : out STD_LOGIC;
            motor_on      : out STD_LOGIC;
            motor_dir     : out STD_LOGIC;
            drain_valve   : out STD_LOGIC;
            heater        : out STD_LOGIC;
            buzzer        : out STD_LOGIC;
            display       : out STD_LOGIC_VECTOR(3 downto 0);
            done          : out STD_LOGIC
        );
    end component;
    
    -- Test signals
    signal clk           : STD_LOGIC := '0';
    signal rst_n         : STD_LOGIC := '0';
    signal start         : STD_LOGIC := '0';
    signal door_closed   : STD_LOGIC := '0';
    signal water_full    : STD_LOGIC := '0';
    signal wash_mode     : STD_LOGIC_VECTOR(1 downto 0) := "00";
    
    signal door_lock     : STD_LOGIC;
    signal water_valve   : STD_LOGIC;
    signal detergent     : STD_LOGIC;
    signal motor_on      : STD_LOGIC;
    signal motor_dir     : STD_LOGIC;
    signal drain_valve   : STD_LOGIC;
    signal heater        : STD_LOGIC;
    signal buzzer        : STD_LOGIC;
    signal display       : STD_LOGIC_VECTOR(3 downto 0);
    signal done          : STD_LOGIC;
    
    -- Clock period
    constant clk_period : time := 10 ns;  -- 100 MHz clock
    
    -- Water fill simulation
    signal water_fill_counter : integer := 0;
    
begin
    
    -- Instantiate the Unit Under Test (UUT)
    uut: washing_machine_controller
        Port map (
            clk         => clk,
            rst_n       => rst_n,
            start       => start,
            door_closed => door_closed,
            water_full  => water_full,
            wash_mode   => wash_mode,
            door_lock   => door_lock,
            water_valve => water_valve,
            detergent   => detergent,
            motor_on    => motor_on,
            motor_dir   => motor_dir,
            drain_valve => drain_valve,
            heater      => heater,
            buzzer      => buzzer,
            display     => display,
            done        => done
        );
    
    -- Clock generation process
    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;
    
    -- Water fill simulation process
    water_sim_process: process(clk, rst_n)
    begin
        if rst_n = '0' then
            water_full <= '0';
            water_fill_counter <= 0;
        elsif rising_edge(clk) then
            if water_valve = '1' then
                -- Simulate water filling (takes about 500 clock cycles)
                if water_fill_counter < 500 then
                    water_fill_counter <= water_fill_counter + 1;
                    water_full <= '0';
                else
                    water_full <= '1';
                end if;
            elsif drain_valve = '1' then
                -- Water drains
                water_full <= '0';
                water_fill_counter <= 0;
            end if;
        end if;
    end process;
    
    -- Stimulus process
    stimulus_process: process
    begin
        
        -- Initialize
        report "========================================";
        report "Starting Washing Machine Test";
        report "========================================";
        
        -- Reset
        rst_n <= '0';
        start <= '0';
        door_closed <= '0';
        wash_mode <= "00";  -- Normal wash mode
        wait for 100 ns;
        rst_n <= '1';
        wait for 100 ns;
        
        report "Test 1: Normal Wash Cycle";
        report "----------------------------------------";
        
        -- Close door
        report "Closing door...";
        door_closed <= '1';
        wait for 200 ns;
        
        -- Start washing machine
        report "Pressing START button...";
        start <= '1';
        wait for 100 ns;
        start <= '0';
        
        -- Let the machine run through complete cycle
        report "Running complete wash cycle...";
        wait for 50 us;  -- Enough time for complete cycle
        
        -- Test 2: Heavy Duty Mode
        report " ";
        report "Test 2: Heavy Duty Wash";
        report "----------------------------------------";
        
        wait for 500 ns;
        wash_mode <= "01";  -- Heavy duty
        door_closed <= '1';
        start <= '1';
        wait for 100 ns;
        start <= '0';
        wait for 60 us;
        
        -- Test 3: Delicate Mode
        report " ";
        report "Test 3: Delicate Wash";
        report "----------------------------------------";
        
        wait for 500 ns;
        wash_mode <= "10";  -- Delicate
        door_closed <= '1';
        start <= '1';
        wait for 100 ns;
        start <= '0';
        wait for 40 us;
        
        -- Test 4: Quick Wash
        report " ";
        report "Test 4: Quick Wash";
        report "----------------------------------------";
        
        wait for 500 ns;
        wash_mode <= "11";  -- Quick wash
        door_closed <= '1';
        start <= '1';
        wait for 100 ns;
        start <= '0';
        wait for 30 us;
        
        -- Test 5: Door open during idle
        report " ";
        report "Test 5: Door Open Test";
        report "----------------------------------------";
        
        wait for 500 ns;
        door_closed <= '0';  -- Door open
        wash_mode <= "00";
        start <= '1';
        wait for 100 ns;
        start <= '0';
        wait for 2 us;  -- Should wait for door to close
        
        door_closed <= '1';  -- Close door now
        report "Door closed - continuing...";
        wait for 30 us;
        
        -- Test 6: Emergency stop (reset during operation)
        report " ";
        report "Test 6: Emergency Stop (Reset)";
        report "----------------------------------------";
        
        wait for 500 ns;
        wash_mode <= "00";
        door_closed <= '1';
        start <= '1';
        wait for 100 ns;
        start <= '0';
        wait for 5 us;  -- Let it run for a bit
        
        report "Emergency RESET activated!";
        rst_n <= '0';  -- Emergency stop
        wait for 200 ns;
        rst_n <= '1';
        report "System reset complete - back to IDLE";
        
        wait for 1 us;
        
        -- End simulation
        report " ";
        report "========================================";
        report "All Tests Completed Successfully!";
        report "========================================";
        
        wait;
        
    end process;
    
    -- Monitor process to display state changes
    monitor_process: process(clk)
        variable last_display : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    begin
        if rising_edge(clk) then
            if display /= last_display then
                last_display := display;
                
                case display is
                    when "0000" =>
                        report "STATE: IDLE - Waiting for start";
                    when "0001" =>
                        report "STATE: DOOR_CHECK - Checking door status";
                    when "0010" =>
                        report "STATE: FILL_WATER - Filling water tank";
                    when "0011" =>
                        report "STATE: HEAT_WATER - Heating water";
                    when "0100" =>
                        report "STATE: ADD_DETERGENT - Adding detergent";
                    when "0101" =>
                        report "STATE: WASH - Washing in progress";
                    when "0110" =>
                        report "STATE: RINSE_DRAIN - Draining wash water";
                    when "0111" =>
                        report "STATE: RINSE_FILL - Filling rinse water";
                    when "1000" =>
                        report "STATE: RINSE - Rinsing in progress";
                    when "1001" =>
                        report "STATE: SPIN_DRAIN - Draining rinse water";
                    when "1010" =>
                        report "STATE: SPIN - Spin drying";
                    when "1111" =>
                        report "STATE: COMPLETE - Wash cycle complete!";
                    when others =>
                        report "STATE: UNKNOWN";
                end case;
            end if;
            
            -- Report important events
            if door_lock = '1' and door_lock'event then
                report "  -> Door LOCKED";
            end if;
            
            if buzzer = '1' and buzzer'event then
                report "  -> BUZZER activated - Cycle complete!";
            end if;
            
            if done = '1' and done'event then
                report "  -> DONE signal HIGH";
            end if;
            
        end if;
    end process;
    
end test;