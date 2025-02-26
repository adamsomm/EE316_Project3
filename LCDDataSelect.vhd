library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity LCDDataSelect is
  port (
    clk      : in std_logic;
    reset    : in std_logic;
    nextByte : in integer := 0;
    mode     : in std_logic_vector(2 downto 0) := "100";
    data_out : out std_logic_vector(7 downto 0) := (others => '0')
  );
end LCDDataSelect;

architecture Behavioral of LCDDataSelect is

  type data2lcd is array (0 to 7, 0 to 10) of std_logic_vector(8 downto 0);
  constant lcd_chars : data2lcd := (
  ('1' & X"4C", '1' & X"44", '1' & X"52", '1' & X"20",'1' & X"20", '0' & X"C0", '1' & X"43", '1' & X"4C", '1' & X"4F", '1' & X"43", '1' & X"4B"),--ldr clock
  ('1' & X"4C", '1' & X"44", '1' & X"52", '1' & X"20",'1' & X"20", '0' & X"C0", '1' & X"20", '1' & X"20", '1' & X"20", '1' & X"20", '1' & X"20"), -- ldr
  ('1' & X"54", '1' & X"45", '1' & X"4D", '1' & X"50",'1' & X"20", '0' & X"C0", '1' & X"43", '1' & X"4C", '1' & X"4F", '1' & X"43", '1' & X"4B"),-- temp clock
  ('1' & X"54", '1' & X"45", '1' & X"4D", '1' & X"50",'1' & X"20", '0' & X"C0", '1' & X"20", '1' & X"20", '1' & X"20", '1' & X"20", '1' & X"20"), -- temp
  ('1' & X"50", '1' & X"4F", '1' & X"54", '1' & X"20",'1' & X"20", '0' & X"C0", '1' & X"43", '1' & X"4C", '1' & X"4F", '1' & X"43", '1' & X"4B"),-- pot clock
  ('1' & X"50", '1' & X"4F", '1' & X"54", '1' & X"20",'1' & X"20", '0' & X"C0", '1' & X"20", '1' & X"20", '1' & X"20", '1' & X"20", '1' & X"20"), -- pot 
  ('1' & X"50", '1' & X"57", '1' & X"4D", '1' & X"20",'1' & X"20", '0' & X"C0", '1' & X"20", '1' & X"20", '1' & X"20", '1' & X"20", '1' & X"20"),--pwm
  ('0' & X"01", '1' & X"20", '1' & X"20", '1' & X"20",'1' & X"20", '1' & X"20", '1' & X"20", '1' & X"20", '1' & X"20", '1' & X"20", '1' & X"20")--clear
  );

  signal LCD_EN      : std_logic := '0';
  signal LCD_RS      : std_logic := '0';
  signal RS          : std_logic := '0';
  signal LCD_RW      : std_logic := '0';
  signal LCD_BL      : std_logic := '1';
  signal nibble      : std_logic := '0';
  signal currentByte : integer   := 0;
  signal counter     : integer   := 0;
  --  signal firstZero   : std_logic                    := '0';
  signal data     : std_logic_vector(7 downto 0) := (others => '0');
  signal LCD_DATA : std_logic_vector(3 downto 0) := (X"3");
  signal byteSel  : integer range 1 to 23        := 1;

begin

  LCD_RW   <= '0';
  LCD_BL   <= '1';
  data_out <= LCD_DATA & LCD_BL & LCD_EN & LCD_RW & RS;
  
  process(clk, reset)
  begin
  if (reset = '1') then
    currentByte <= 0;
    byteSel <= 1;
  elsif rising_edge(clk) then
      currentByte <= nextByte;
      if nextByte = 0 then
        if nextByte /= currentByte then
          if byteSel < 20 then
            byteSel <= byteSel + 1;
          else
            byteSel <= 9;--9
          end if;
        end if;
      end if;
    end if;
  end process;

  process (data, currentByte)
  begin
--    if reset = '1' then
--      --      firstZero <= '0';
--      byteSel <= 1;
--    end if;

    --    if rising_edge(clk) then
    LCD_RS <= RS;
    -- LCD_EN logic
    if (nextByte = 1 or nextByte = 4) then
      LCD_EN <= '1';
    else
      LCD_EN <= '0';
    end if;

    if (nextByte < 3) then -- upper 4 bits
      --        nibble <= '0';
      LCD_DATA <= data(7 downto 4);
    else
      --        nibble <= '1';
      LCD_DATA <= data(3 downto 0);
    end if;
    --    end if;
    -- Ensure byteSel increments only after the **second** occurrence of nextByte = 0
    --      if (nextByte = 0) then
    --        if firstZero = '0' then
    --          firstZero <= '1'; -- Set flag on first occurrence
    --        else
--    if rising_edge(clk) then
--      currentByte <= nextByte;
--      if nextByte = 0 then
--        if nextByte /= currentByte then
--          if byteSel < 16 then
--            byteSel <= byteSel + 1;
--          else
--            byteSel <= 1;
--          end if;
--        end if;
--      end if;
--    end if;
  end process;

  process (mode, byteSel, nibble, nextByte)
    variable mode_index : integer := 0;
  begin

    -- Mode changing logic 
    case mode is
      when "000"  => mode_index  := 1; -- LDR mode 
      when "100"  => mode_index  := 0; -- LDR clock mode
      when "001"  => mode_index  := 3; -- TEMP  mode 
      when "101"  => mode_index  := 2; -- TEMP clock mode 
      when "011"  => mode_index  := 5; -- POT mode
      when "111"  => mode_index  := 4; -- POT clock mode
      when "010"  => mode_index  := 6; -- PWM mode
      when others => mode_index := 7;
    end case;

    case byteSel is
        -- Initialization commands
      when 1 to 3   =>
        data <= X"30";
        RS   <= '0'; -- 4 bit mode select
      when 4  =>
        data <= X"20";
        RS   <= '0'; -- initialize 4-bit mode
      when  5 =>
        data <= X"28";
        RS   <= '0';     
      when 6 =>
        data <= X"0C";
        RS   <= '0'; -- Display ON, cursor OFF command
      when 7 =>
        data <= X"06";
        RS   <= '0'; -- auto increment cursor
      when 8 =>
        data <= X"01";
        RS   <= '0'; -- Clear Display
      when 9 =>
        data <= X"80";
        RS   <= '0'; -- Cursor at Home position
        -- Display messages
      when 10 to 20 =>
        RS   <= lcd_chars(mode_index, byteSel - 10)(8);
        data <= lcd_chars(mode_index, byteSel - 10)(7 downto 0);
      when others =>
        data <= X"28";
        RS   <= '0'; -- Default command
    end case;

    --         if nibble = '0' then
    --              LCD_DATA <= data(7 downto 4);
    --         else
    --              LCD_DATA <= data(3 downto 0);
    --        end if;
  end process;
end Behavioral;
