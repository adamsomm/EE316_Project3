library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity topLevel is
  port (
    iCLK    : in std_logic;
    btn     : in std_logic_vector(2 downto 0);
    LED     : out std_logic_vector(3 downto 0);
    LCDSDA  : inout std_logic;
    LCDSCL  : inout std_logic;
    ADCSDA  : inout std_logic;
    ADCSCL  : inout std_logic;
    PWMout  : out std_logic;
    Clk_Gen : out std_logic;
    data_out: out std_logic_vector(7 downto 0)
  );
end topLevel;

architecture Behavioral of topLevel is
  -- Component declarations
  component Mode_ManagerP3 is
    port (
      clk     : in std_logic;
      reset   : out std_logic;
      ibtn     : in std_logic_vector(2 downto 0);
      MODE    : out std_logic_vector(2 downto 0);
      LEDc     : out std_logic_vector(3 downto 0);
      Clk_Geno : out std_logic
    );
  end component;
  component ADC_I2C_user_logic is
  generic (
      input_clk : integer := 125_000_000; --input clock speed from user logic in Hz
      bus_clk   : integer := 100_000); --speed the i2c bus (scl) will run at in Hz
    port (
      clk      : in std_logic;
      reset    : in std_logic;
      MODE     : in std_logic_vector(2 downto 0);
      sda      : inout std_logic;
      scl      : inout std_logic;
      data_out : out std_logic_vector(7 downto 0)
    );
  end component;
  component ampPWM is
    port (
      clk          : in std_logic;
      rst          : in std_logic;
      dynamic_bits : in integer;
      SRAMdata     : in std_logic_vector(7 downto 0);
      PWMout       : out std_logic
    );
  end component;
  component DigitalCLKcreator is 
    generic (
      Cnt_Max : integer;
      Cnt_Min : integer;
      numBit  : integer
    );
    port (
      clk           : in std_logic;
      reset         : in std_logic;
      digital_in    : in std_logic_vector(7 downto 0);
      output_signal : out std_logic
    );
  end component;
  component LCD_I2C_user_logic is
  generic (
      input_clk : integer := 125_000_000; --input clock speed from user logic in Hz
      bus_clk   : integer := 100_000);
    port (
      clk : in std_logic;
      reset : in std_logic;
      MODE : in std_logic_vector(2 downto 0);
      scl : inout std_logic;
      sda : inout std_logic
    );
  end component;
  component Reset_Delay is
    port (
      iCLK : in std_logic;
      oRESET : out std_logic
    );
  end component;
  component btn_debounce_toggle is
    generic (
      CNTR_MAX : std_logic_vector(15 downto 0) := X"FFFF"
    );
    port (
      BTN_I : in STD_LOGIC;
      CLK : in STD_LOGIC;
      BTN_O : out STD_LOGIC;
      TOGGLE_O : out STD_LOGIC;
      PULSE_O : out STD_LOGIC
    );
  end component;

  -- Signal declarations
  signal system_reset : std_logic := '0';
  signal ADC_data     : std_logic_vector(7 downto 0);
  signal MODE         : std_logic_vector(2 downto 0);
  signal Clk_gen_en   : std_logic;
  signal btn_reset    : std_logic;
  signal clock_reset : std_logic;
  signal reset_d      : std_logic;
  signal btndb        : std_logic_vector(2 downto 0);
begin
  system_reset <= btn_reset or reset_d;
  clock_reset <= system_reset or not MODE(2);
  btndb(0) <= btn(0);
  data_out <= ADC_data;
  -- Component instantiation
  Mode_ManagerP3_inst : Mode_ManagerP3
  port map
  (
    clk     => iCLK,
    reset   => btn_reset,
    ibtn     => btndb,
    MODE    => MODE,
    LEDc     => LED,
    Clk_Geno => Clk_gen_en
  );

  InstADCI2C : ADC_I2C_user_logic
  generic map(
      input_clk => 125_000_000, --input clock speed from user logic in Hz
      bus_clk   => 100_000) --speed the i2c bus (scl) will run at in Hz
  port map
  (
    clk      => iCLK,
    reset    => system_reset,
    MODE     => MODE,
    sda      => ADCSDA,
    scl      => ADCSCL,
    data_out => ADC_data
  );
  ampPWM_inst : ampPWM
  port map
  (
    clk          => iCLK,
    rst          => system_reset,
    dynamic_bits => 8,
    SRAMdata     => ADC_data,
    PWMout       => PWMout
  );
  DigitalCLKcreator_inst : DigitalCLKcreator
  generic map(
    Cnt_Max => 99999,
    Cnt_Min => 33332,
    numBit  => 8
  )
  port map
  (
    clk           => iCLK,
    reset         => clock_reset,
    digital_in    => ADC_data,
    output_signal => Clk_Gen
  );

  LCD_I2C_user_logic_inst : LCD_I2C_user_logic
  generic map(
      input_clk => 125_000_000, --input clock speed from user logic in Hz
      bus_clk   => 100_000)
  port map (
    clk => iCLK,
    reset => system_reset,
    MODE => MODE,
    scl => LCDscl,
    sda => LCDsda
  );

--  btn_debounce_toggle_inst0 : btn_debounce_toggle
--  generic map (
--    CNTR_MAX => X"FFFF"
--  )
--  port map (
--    BTN_I => btn(0),
--    CLK => iCLK,
--    BTN_O => btndb(0),
--    TOGGLE_O => open,
--    PULSE_O => open
--  );
  btn_debounce_toggle_inst1 : btn_debounce_toggle
  generic map (
    CNTR_MAX => X"FFFF"
  )
  port map (
    BTN_I => btn(1),
    CLK => iCLK,
    BTN_O => open,
    TOGGLE_O => open,
    PULSE_O => btndb(1)
  );
  btn_debounce_toggle_inst2 : btn_debounce_toggle
  generic map (
    CNTR_MAX => X"FFFF"
  )
  port map (
    BTN_I => btn(2),
    CLK => iCLK,
    BTN_O => open,
    TOGGLE_O => btndb(2),
    PULSE_O => open
  );
  Reset_Delay_inst : Reset_Delay
  port map (
    iCLK => iCLK,
    oRESET => reset_d
  );


  -- Process declarations
 end Behavioral;