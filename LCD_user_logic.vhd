library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity LCD_user_logic is
  generic (
    constant CntMax : integer := 83333
  );
  port (
    clk   : in std_logic;
    reset : in std_logic;
    --Clock     : IN     BOOLEAN;
    mode  : in std_logic_vector(2 downto 0); -- LDR, TEMP, POT, Clear
    oData : out std_logic_vector(7 downto 0)
  );
end LCD_user_logic;
architecture user_logic of LCD_user_logic is
  --signal ascii0, ascii1, ascii2, ascii3 : std_logic_vector(7 downto 0);
  type data2lcd is array (0 to 3, 0 to 8) of std_logic_vector(8 downto 0);
  constant lcd_chars : data2lcd := (
  -- LDR Mode, 76(L) 68(D) 82(R) - C0(next line) 67(C) 76(L) 79(O) 67(C) 75(K)
  ('1' & X"76", '1' & X"68", '1' & X"82", '0' & X"C0", '1' & X"67", '1' & X"76", '1' & X"79", '1' & X"67", '1' & X"75"),
  -- TEMP Mode, 84(T) 69(E) 77(M) 80(P) - C0(next line) 67(C) 76(L) 79(O) 75(K)
  ('1' & X"84", '1' & X"69", '1' & X"77", '1' & X"80", '0' & X"C0", '1' & X"67", '1' & X"76", '1' & X"79", '1' & X"75"),
  -- POT Mode, 76(L) 68(D) 82(R) - C0(next line) 67(C) 76(L) 79(O) 67(C) 75(K)
  ('1' & X"76", '1' & X"68", '1' & X"82", '0' & X"C0", '1' & X"67", '1' & X"76", '1' & X"79", '1' & X"67", '1' & X"75"),
  -- blank for analog 01 FOR CLEAR
  ('0' & X"01", '0' & X"01", '0' & X"01", '0' & X"01", '0' & X"01", '0' & X"01", '0' & X"01", '0' & X"01", '0' & X"01")
  );

  type state_type is (start, ready, data_valid, busy_high, repeat);
  signal state : state_type;

  signal pwm_disp : std_logic_vector(31 downto 0); -- Frequency to display
  signal reset_n  : std_logic;
  signal ena      : std_logic;
  signal data     : std_logic_vector(7 downto 0);
  signal RS       : std_logic;
  signal data_wr  : std_logic_vector(7 downto 0);
  signal RS_wr    : std_logic;
  signal busy     : std_logic;
  signal count    : UNSIGNED(27 downto 0) := X"00000FF";
  signal byteSel  : integer range 0 to 14 := 0;
  --SIGNAL ascii      : STD_LOGIC_VECTOR(32 DOWNTO 0);
  signal base_address : integer range 0 to 63 := 0;
  signal ascii_chars  : std_logic_vector(31 downto 0);
  signal mreset       : std_logic := '0';

  signal prev_mode   : std_logic_vector(2 downto 0) := "000"; -- Previous mode for comparison
  signal dataBuffer  : std_logic_vector(8 downto 0);
  signal data_nibble : std_logic;
  signal LCD_RS      : std_logic;
  signal LCD_EN      : std_logic;
  signal LCD_DATA    : std_logic_vector(7 downto 0);
  signal repeat_flag : std_logic := '0'; -- Tracks whether to repeat the current index
  -- component hex2ascii is
  --   port (
  --     hex_digit : in std_logic_vector(3 downto 0);
  --     ascii     : out std_logic_vector(7 downto 0)
  --   );
  -- end component;

  component LCD_manager is
    generic (
      constant CntMax : integer := 83333
    );
    port (
      clock    : in std_logic;
      iReset_n : in std_logic;
      iEna     : in std_logic;
      iData    : in std_logic_vector(7 downto 0);
      iRS      : in std_logic;
      oBusy    : out std_logic;
      LCD_RS   : out std_logic;
      LCD_EN   : out std_logic;
      LCD_DATA : out std_logic_vector(7 downto 0)
    );
  end component;

begin
  -- setup concat for output
  -- top 4 bits 
  -- LCD_Data(3 downto 0)
  -- bottom 4 bits
  --(3)backlight
  --(2)EN
  --(1)RW
  --(0)RS
  oData <= LCD_DATA(3 downto 0) & '1' & LCD_EN & '0' & LCD_RS;
  --hex to ascii
  -- Inst_a0: hex2ascii
  --     Port Map(
  --         hex_digit   => iData(15 downto 12),
  --         ascii       => ascii0 
  --     );
  -- Inst_a1: hex2ascii
  --     Port Map(
  --         hex_digit   => iData(11 downto 8),
  --         ascii       => ascii1
  --     );
  -- Inst_a2: hex2ascii
  --     Port Map(
  --         hex_digit   => iData(7 downto 4),
  --         ascii       => ascii2 
  --     );
  -- Inst_a3: hex2ascii
  --     Port Map(
  --         hex_digit   => iData(3 downto 0),
  --         ascii       => ascii3  
  --     );
  --		  
  Inst_LCD_manager : LCD_manager
  generic map(
    CntMax => CntMax
  )
  port map
  (
    iReset_n => reset_n,
    clock    => clk,
    iEna     => ena,
    iData    => data_wr,
    iRS      => RS_wr,
    -- outputs        
    oBusy    => busy,
    LCD_RS   => LCD_RS,
    LCD_EN   => LCD_EN,
    LCD_DATA => LCD_DATA
  );

  process (byteSel, mode)
    variable mode_index : integer;
  begin
    -- Determine mode based on `mode` signal
    case mode is
      when "000"  => mode_index  := 0; -- LDR mode 
      when "001"  => mode_index  := 1; -- TEMP mode 
      when "010"  => mode_index  := 2; -- POT mode
      when "100"  => mode_index  := 3; -- CLEAR mode
      when others => mode_index := 0;
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
      when 6 to 14 =>
        dataBuffer <= lcd_chars(mode_index, byteSel - 15);
        RS         <= dataBuffer(8);
      when others =>
        data <= X"28";
        RS   <= '0'; -- Default command
    end case;
  end process;

  -- Timing and control process for the state machine
  process (clk, reset)
  begin
    if reset = '1' then
      state       <= start;
      prev_mode   <= "000";
      reset_n     <= '0';
      ena         <= '0';
      data_wr     <= (others => '0');
      RS_wr       <= '0';
      count       <= X"00000FF";
      byteSel     <= 0;
      data_nibble <= (others => '0');
    elsif (rising_edge(clk)) then
      -- mode change logic
      if mode /= prev_mode then
        byteSel     <= 0; -- Reset byteSel when mode changes
        prev_mode   <= mode;
        data_nibble <= '0'; -- Reset data_nibble when mode changes
        count       <= X"00000FF"; -- Reset count when mode changes
        repeat_flag <= '0'; -- Reset repeat_flag when mode changes
      end if;
      -- State machine for LCD control
      case state is
        when start =>
          if count > X"0000000" then
            count   <= count - 1;
            reset_n <= '0';
            state   <= start;
            ena     <= '0';
          else
            reset_n <= '1';
            state   <= ready;
            if data_nibble = '0' then
              data_wr <= X"0" & data(7 downto 4); -- Send high nibble
            else
              data_wr <= X"0" & data(3 downto 0); -- Send low nibble
            end if;
            ena <= '1';
            if data(8) = '1' then
              RS_wr <= '1'; -- Data for LCD display
            else
              RS_wr <= '0'; -- Command for LCD display
            end if;
          end if;
        when ready =>
          if busy = '0' then
            ena   <= '1';
            state <= data_valid;
          end if;
        when data_valid =>
          if busy = '1' then
            ena   <= '0';
            state <= busy_high;
          end if;
        when busy_high =>
          if busy = '0' then
            state <= repeat;
          end if;
        when repeat =>
          if repeat_flag = '0' then
            repeat_flag <= '1'; -- Stay on the same index
            data_nibble <= '1'; -- Send low nibble
          else
            repeat_flag <= '0';
            data_nibble <= '0'; -- Send high nibble
            if byteSel > 13 then
              byteSel <= 5;
            else
              byteSel <= byteSel + 1;
            end if;
          end if;
          count <= X"00000FF";
          state <= start;
        when others => null;
      end case;
    end if;
  end process;
end user_logic;
