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
  );
end topLevel;

architecture Behavioral of topLevel is
  -- Component declarations
  component Mode_ManagerP3 is
    port (
      clk     : in std_logic;
      reset   : out std_logic;
      btn     : in std_logic_vector(2 downto 0);
      MODE    : out std_logic_vector(2 downto 0);
      LED     : out std_logic_vector(3 downto 0);
      Clk_Gen : out std_logic
    );
  end component;
  component ADC_I2C_user_logic is
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
      SRAMdata     : in std_logic_vector(15 downto 0);
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
    port (
      clk : in std_logic;
      reset : in std_logic;
      MODE : in std_logic_vector(2 downto 0);
      scl : inout std_logic;
      sda : inout std_logic
    );
  end component;

  -- Signal declarations
  signal system_reset : std_logic := '0';
  signal ADC_data     : std_logic_vector(7 downto 0);
  signal MODE         : std_logic_vector(2 downto 0);
  signal Clk_gen_en   : std_logic;
begin
  -- Component instantiation
  Mode_ManagerP3_inst : Mode_ManagerP3
  port map
  (
    clk     => iCLK,
    reset   => system_reset,
    btn     => btn,
    MODE    => MODE,
    LED     => LED,
    Clk_Gen => Clk_gen_en
  );

  InstADCI2C : ADC_I2C_user_logic
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
    reset         => system_reset,
    digital_in    => ADC_data_clk,
    output_signal => Clk_Gen
  );

  LCD_I2C_user_logic_inst : LCD_I2C_user_logic
  port map (
    clk => iCLK,
    reset => system_reset,
    MODE => MODE,
    scl => LCDscl,
    sda => LCDsda
  );

  -- Process declarations
  process (clk)
  begin
    if Clk_gen_en = '1' then
      ADC_data_clk <= ADC_data;
    else
      ADC_data_clk <= '0';
    end if;
  end process;
end Behavioral;