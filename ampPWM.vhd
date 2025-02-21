library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;  -- This is the preferred library for arithmetic types

entity ampPWM is
  port (
    clk : in std_logic;
    rst : in std_logic;
    dynamic_bits : in integer := 8;  -- Input for dynamic bit width
    SRAMdata : in std_logic_vector(15 downto 0);
    PWMout : out std_logic
  );
end ampPWM;

architecture Behavioral of ampPWM is
    signal counter : integer := 0;  -- Counter with max possible size
    signal SRAMdatatrunk : std_logic_vector(15 downto 0);  -- SRAM data truncated to dynamic_bits width
    signal count_max : integer;
begin

    -- Dynamically truncate SRAM data based on input 'dynamic_bits'
    process(SRAMdata, dynamic_bits)
    begin
        case dynamic_bits is
				when 6 => 
                SRAMdatatrunk <= "0000000000" & SRAMdata(15 downto 10);
                count_max <= 2**6 - 1;
            when 7 => 
                SRAMdatatrunk <= "000000000" & SRAMdata(15 downto 9);
                count_max <= 2**7 - 1;
            when 8 => 
                SRAMdatatrunk <= "00000000" & SRAMdata(15 downto 8);
                count_max <= 2**8 - 1;
            when others => 
                SRAMdatatrunk <= SRAMdata(15 downto 0); -- default case for 16 bits
                count_max <= 2**16 - 1;
        end case;
    end process;

    -- Main clocked process to handle PWM logic
    process(clk, rst)
    begin
        if rst = '1' then
            counter <= 0;
            PWMout <= '0';  -- Initialize PWMout during reset
        elsif rising_edge(clk) then
            if counter >= count_max then
                counter <= 0;  -- Reset counter when it reaches count_max
            else
                counter <= counter + 1;
            end if;

            -- Compare counter with truncated SRAM data to generate PWM signal
            if (counter < to_integer(unsigned(SRAMdatatrunk))) then
                PWMout <= '1';
            else
                PWMout <= '0';
            end if;
        end if;
    end process;

end Behavioral;
