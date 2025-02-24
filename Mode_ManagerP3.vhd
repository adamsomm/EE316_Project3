library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Mode_ManagerP3 is
    Port (
        clk : in STD_LOGIC;
        reset : out STD_LOGIC;
        ibtn : in std_logic_vector(2 downto 0);
        MODE : out std_logic_vector(2 downto 0) := "000";
        LEDc : out std_logic_vector(3 downto 0) := "0000";
        Clk_Geno : out std_logic
        -- Add other ports here
    );
end Mode_ManagerP3;

architecture Behavioral of Mode_ManagerP3 is
    type state_type is (Resets, LDR, TEMP, POT, PWM);
    signal state   : state_type;
    -- Declare internal signals here
begin
    process(clk, ibtn)
    begin
        if ibtn(0) = '1' then
            state <= Resets;
        elsif rising_edge(clk) then
            if ibtn(2) = '1' then
                Clk_Geno <= '1';
                LEDc(1) <= '1';
            else
                Clk_Geno <= '0';
                LEDc(1) <= '0';
            end if;
            case state is
                when Resets =>
                    reset <= '1';
                    LEDc(0) <= '0';
                    if ibtn(0) = '0' then
                        reset <= '0';
                        LEDc <= (others => '0');
                        state <= LDR;
                    end if;
                when LDR =>
                    LEDc(3 downto 2) <= "00";
                    if ibtn(1) = '1' then
                        state <= TEMP;
                    end if;
                when TEMP =>
                    LEDc(3 downto 2) <= "01";
                    if ibtn(1) = '1' then
                        state <= PWM;
                    end if;
                when PWM =>
                    LEDc(3 downto 2) <= "10";
                    if ibtn(1) = '1' then
                        state <= POT;
                    end if;
                when POT =>
                    LEDc(3 downto 2) <= "11";
                    if ibtn(1) = '1' then
                        state <= LDR;
                    end if;
                when others =>
                    state <= LDR;
                end case;
        end if;
end process;
    with state select
  MODE <= "000" when LDR,
            "001" when TEMP,
            "010" when PWM,
            "011" when POT, 
            "000" when others;  -- Default value for unexpected states
end Behavioral;