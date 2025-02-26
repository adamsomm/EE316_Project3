library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use  IEEE.numeric_std.all;

entity DigitalCLKcreator is
  generic (
    Cnt_Max : integer := 99999;
    Cnt_Min : integer := 33332;
    numBit  : integer := 8);
  port (
    clk           : in std_logic;
    reset         : in std_logic;
    digital_in    : in std_logic_vector(7 downto 0) := "00000000";
    output_signal : out std_logic := '0'
  );
end DigitalCLKcreator;

architecture Behavioral of DigitalCLKcreator is
  signal Cnt_Threshold : integer := 99999;
  signal Cnt           : integer := 0;
  signal output_buffer : std_logic := '0';
begin
  process (clk, reset)
  begin
    if reset = '1' then
      output_buffer <= '0';
    elsif rising_edge(clk) then
      -- Add your clock generation logic here
      Cnt_Threshold <= Cnt_Max - ((to_integer(unsigned(digital_in))) * ((Cnt_Max - Cnt_Min) / 255));
      if (Cnt >= (Cnt_Threshold/2)) then
        Cnt <= 0;
        output_buffer <= not output_buffer;
      else
        Cnt <= Cnt + 1;
      end if;
     end if;
    end process;
    output_signal <= output_buffer;
  end Behavioral;