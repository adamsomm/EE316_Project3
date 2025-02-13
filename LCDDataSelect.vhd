library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity LCDDataSelect is
  port (
    reset    : in std_logic;
    nextByte : in integer;
    mode     : in std_logic_vector(2 downto 0);
    data_out : out std_logic_vector(7 downto 0)
  );
end LCDDataSelect;

architecture Behavioral of LCDDataSelect is

  type data2lcd is array (0 to 4, 0 to 9) of std_logic_vector(8 downto 0);
  constant lcd_chars : data2lcd := (
  -- LDR Mode(000), 4C(L) 44(D) 52(R) - C0(next line) 43(C) 4C(L) 4F(O) 43(C) 4B(K)
  ('1' & X"4C", '1' & X"44", '1' & X"52", '1' & X"20", '0' & X"C0", '1' & X"43", '1' & X"4C", '1' & X"4F", '1' & X"43", '1' & X"4B"),
  -- TEMP Mode(001), 54(T) 45(E) 4D(M) 50(P) - C0(next line) 43(C) 4C(L) 4F(O) 43(C) 4B(K)
  ('1' & X"54", '1' & X"45", '1' & X"4D", '1' & X"50", '0' & X"C0", '1' & X"43", '1' & X"4C", '1' & X"4F", '1' & X"43", '1' & X"4B"),
  -- POT Mode(010), 50(P) 4F(O) 54(T) - C0(next line) 43(C) 4C(L) 4F(O) 43(C) 4B(K)
  ('1' & X"50", '1' & X"4F", '1' & X"54", '1' & X"20", '0' & X"C0", '1' & X"43", '1' & X"4C", '1' & X"4F", '1' & X"43", '1' & X"4B"),
  -- PWM Mode(011), 50(P) 57(W) 4D(M) - C0(next line) 43(C) 4C(L) 4F(O) 43(C) 4B(K)
  ('1' & X"50", '1' & X"4F", '1' & X"54", '1' & X"20", '0' & X"C0", '1' & X"43", '1' & X"4C", '1' & X"4F", '1' & X"43", '1' & X"4B"),
  -- CLEAR(100)
  ('0' & X"01", '1' & X"20", '1' & X"20", '1' & X"20", '1' & X"20", '1' & X"20", '1' & X"20", '1' & X"20", '1' & X"20", '1' & X"20")
  );

  signal LCD_EN   : std_logic;
  signal LCD_RS   : std_logic;
  signal LCD_RW   : std_logic;
  signal LCD_BL   : std_logic;
  signal LCD_DATA : std_logic_vector(3 downto 0);
  signal Data_RS  : STS_LOGIC_VECTOR(8 downto 0);
  signal byteSel  : integer range 0 to 15 := 0;
begin

  LCD_RW   <= '0';
  LCD_BL   <= '1';
  LCD_RS   <= Data_RS(8);
  data_out <= LCD_DATA & LCD_BL & LCD_EN & LCD_RW & LCD_RS;

  process (byteSel, mode, reset)
  begin
    if reset = '1' then
      data_out <= (others => '0');
    end if;

    -- Mode changing logic 
    case mode is
      when "000"  => mode_index  := 0; -- LDR mode 
      when "001"  => mode_index  := 1; -- TEMP mode 
      when "010"  => mode_index  := 2; -- POT mode
      when "011"  => mode_index  := 3; -- PWM mode
      when "100"  => mode_index  := 4; -- Clear mode
      when others => mode_index := 4;
    end case;

    case byteSel is
        -- Initialization commands
      when 0 =>
        data <= X"02";
        RS   <= '0'; -- 4 bit mode select
      when 1 =>
        data <= X"28";
        RS   <= '0'; -- initialize 4-bit mode
      when 2 =>
        data <= X"0C";
        RS   <= '0'; -- Display ON, cursor OFF command
      when 3 =>
        data <= X"06";
        RS   <= '0'; -- auto increment cursor
      when 4 =>
        data <= X"01";
        RS   <= '0'; -- Clear Display
      when 5 =>
        data <= X"80";
        RS   <= '0'; -- Cursor at Home position
        -- Display messages
      when 6 to 15 =>
        Data_RS(8)          <= lcd_chars(mode_index, byteSel - 6)(8);
        Data_RS(7 downto 0) <= lcd_chars(mode_index, byteSel - 6)(7 downto 0);
      when others =>
        data <= X"28";
        RS   <= '0'; -- Default command
    end case;

    -- LCD signal logic ----------------

    -- LCD_DATA logic
    if (nextByte < 3) then -- upper 4 bits
      LCD_DATA <= Data_RS(7 downto 4);
    else
      LCD_DATA <= Data_RS(3 downto 0);
    end if;
  end case;
end process;

process (nextByte)
begin
  -- LCD_EN logic
  if (nextByte = 1 or nextByte = 4) then
    LCD_EN <= '1';
  else
    LCD_EN <= '0';
  end if;

  if (nextBytr = 0) then
    byteSel <= byteSel + 1;
  end if;
end process;
end Behavioral;