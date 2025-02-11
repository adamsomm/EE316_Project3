library IEEE; -- poop
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity LCD_manager is 
    Generic (Constant CntMax : integer := 83333); -- (125 MHz/250 KHz) - 1
    Port(
        clock      : in std_logic;
        iReset_n   : in std_logic;
        iEna       : in std_logic;
        iData      : in std_logic_vector(7 downto 0);
        iRS        : in std_logic;
        oBusy      : out std_logic;
        LCD_RS     : out std_logic;
        LCD_EN     : out std_logic;
        LCD_DATA   : out std_logic_vector(7 downto 0)
    );
end LCD_manager;

architecture state_machine of LCD_manager is
    type stateType is (Ready, Enable, Write);
    signal state    : stateType := Ready;
    signal cnt      : integer range 0 to CntMax := 0; 
    signal clock_en : std_logic := '0';
    
    attribute mark_debug : string;
attribute mark_debug of clock_en : signal is "TRUE";

begin

Clock_Enable:
process(clock, iReset_n)
begin
    if iReset_n = '0' then
        cnt <= 0;
        clock_en <= '0';
    elsif rising_edge(clock) then
        if cnt = CntMax then
            clock_en <= '1';
            cnt <= 0;
        else
            clock_en <= '0';
            cnt <= cnt + 1;
        end if;
    end if;
end process;


LCD_state_machine:
process(clock, iReset_n)
begin
    if iReset_n = '0' then
        oBusy    <= '0';
        state    <= Ready;
    elsif rising_edge(clock) then
        if clock_en = '1' then
            case state is
                when Write =>
                    if iEna = '0' then
                        state <= Write;
                    else
                        oBusy <= '1';
                        LCD_DATA <= iData; 
                        LCD_RS   <= iRS;
                        state <= Enable;
                    end if;
                when Enable =>
                    oBusy <= '0';
                    LCD_EN   <= '1';
                    state    <= Ready;
                when Ready =>
                    LCD_EN <= '0';
                    oBusy  <= '0';
                    state  <= Write;
                when others =>
                    state <= Ready;
            end case;
        end if;
    end if;
end process;

end state_machine;
