library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity DigitalCLKcreator is
  generic (
    Cnt_Max : integer := 33332;
    Cnt_Min : integer := 100000;
    numBit  : integer := 8);
  port (
    clk           : in std_logic;
    reset         : in std_logic;
    digital_in    : in std_logic;
    output_signal : out std_logic
  );
end DigitalCLKcreator;

architecture Behavioral of DigitalCLKcreator is
  signal Cnt_Threshold : integer := 0;
  signal Cnt           : integer := 0;
  signal numBit        : integer := 8;
begin
  process (clk, reset)
  begin
    if reset = '1' then
      output_signal <= '0';
    elsif rising_edge(clk) then
      -- Add your clock generation logic here
      Cnt_Threshold <= Cnt_Max - (digital_in * (Cnt_Max - Cnt_Min) / numBit);
      if Cnt        <= Cnt_Threshold then
        Cnt           <= Cnt + 1;
      else
        Cnt           <= 0;
        output_signal <= not output_signal;
      end if;
    end process;
  end Behavioral;