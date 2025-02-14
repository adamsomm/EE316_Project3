library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity LCDDataSelect is
  port (
    reset    : in std_logic;
    nextByte : in integer;
    mode     : in std_logic_vector(2 downto 0);
    data_out : out std_logic_vector(7 downto 0) := (others => '0')
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

  signal LCD_EN    : std_logic;
  signal LCD_RS    : std_logic;
  signal LCD_RW    : std_logic;
  signal LCD_BL    : std_logic;
  signal nibble    : std_logic := '1';
  signal firstZero : boolean                      := false;
  signal LCD_DATA  : std_logic_vector(3 downto 0) := (others => '0');
  signal Data_RS   : std_logic_vector(8 downto 0) := (others => '0');
  signal byteSel   : integer range 1 to 16        := 1;
begin

  LCD_RW <= '0';
  LCD_BL <= '1';
  LCD_RS <= Data_RS(8);
  data_out <= LCD_DATA & LCD_BL & LCD_EN & LCD_RW & LCD_RS;
  
  process (nextByte, reset)
  begin
    if (reset = '1') then
        firstZero <= false;
        byteSel <= 1;
        LCD_EN <= '0';
        LCD_DATA <= (others => '0');
    end if;
    -- LCD_EN logic
    if (nextByte = 1 or nextByte = 4) then
      LCD_EN <= '1';
    else
      LCD_EN <= '0';
    end if;

    if (nextByte < 3) then -- upper 4 bits
      nibble <= '1';
    else
      nibble <= '0';
    end if;

    -- Ensure byteSel increments only after the **second** occurrence of nextByte = 0
    if (nextByte = 0) then
      if firstZero = false then
        firstZero <= true; -- Set flag on first occurrence
      else
        if byteSel < 16 then
          byteSel <= byteSel + 1;
        else
          byteSel <= 1;
        end if;
      end if;
    end if;
  end process;
  
  process (byteSel, mode)
    variable mode_index : integer;
    begin
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
      when 1 =>
        Data_RS(7 downto 0) <= X"02";
        Data_RS(8)          <= '0'; -- 4 bit mode select
      when 2 =>
        Data_RS(7 downto 0) <= X"28";
        Data_RS(8)          <= '0'; -- initialize 4-bit mode
      when 3 =>
        Data_RS(7 downto 0) <= X"0C";
        Data_RS(8)          <= '0'; -- Display ON, cursor OFF command
      when 4 =>
        Data_RS(7 downto 0) <= X"06";
        Data_RS(8)          <= '0'; -- auto increment cursor
      when 5 =>
        Data_RS(7 downto 0) <= X"01";
        Data_RS(8)          <= '0'; -- Clear Display
      when 6 =>
        Data_RS(7 downto 0) <= X"80";
        Data_RS(8)          <= '0'; -- Cursor at Home position
        -- Display messages
      when 7 to 16 =>
        Data_RS(8)          <= lcd_chars(mode_index, byteSel - 7)(8);
        Data_RS(7 downto 0) <= lcd_chars(mode_index, byteSel - 7)(7 downto 0);
      when others =>
        Data_RS(7 downto 0) <= X"28";
        Data_RS(8)          <= '0'; -- Default command
    end case;
  end process;
  
  process(Data_RS)
  begin 
  -- LCD_DATA logic
    if (nibble = '1') then -- upper 4 bits
      LCD_DATA <= Data_RS(7 downto 4);
    else
      LCD_DATA <= Data_RS(3 downto 0);
    end if;
 end process;
    
end Behavioral;