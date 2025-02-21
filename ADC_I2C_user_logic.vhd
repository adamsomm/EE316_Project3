library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity ADC_I2C_user_logic is
  port (
    clk      : in std_logic;
    reset    : in std_logic;
    MODE     : in std_logic_vector(2 downto 0);
    sda      : inout std_logic;
    scl      : inout std_logic;
    data_out : out std_logic_vector(7 downto 0)
  );
end ADC_I2C_user_logic;

architecture Behavioral of ADC_I2C_user_logic is

  component i2c_master is
    generic (
      input_clk : integer := 50_000_000; --input clock speed from user logic in Hz
      bus_clk   : integer := 50_000); --speed the i2c bus (scl) will run at in Hz
    -- ADC runs at 400,000, lcd at 100k max 
    port (
      clk       : in std_logic; --system clock
      reset_n   : in std_logic; --active low reset
      ena       : in std_logic; --latch in command
      addr      : in std_logic_vector(6 downto 0); --address of target slave
      rw        : in std_logic; --'0' is write, '1' is read
      data_wr   : in std_logic_vector(7 downto 0); --data to write to slave
      busy      : out std_logic; --indicates transaction in progress
      data_rd   : out std_logic_vector(7 downto 0); --data read from slave
      ack_error : buffer std_logic; --flag if improper acknowledge from slave
      sda       : inout std_logic; --serial data output of i2c bus
      scl       : inout std_logic); --serial clock output of i2c bus
  end component;
  -----------------------------------------------------------------------------------------------------------------------------------
  signal ControlByte : std_logic_vector(7 downto 0) := X"00";
  signal cont        : unsigned(27 downto 0)        := X"01FFFFF";
  signal ReadAddr    : std_logic_vector(6 downto 0) := "1001000";
  signal WriteAddr   : std_logic_vector(6 downto 0) := "1001000";
  signal i2c_data_rd : std_logic_vector(7 downto 0) := (others => '0');
  signal reset_n     : std_logic;
  signal rst         : std_logic := '1';
  signal i2c_ena     : std_logic := '0';
  signal i2c_rw      : std_logic := '0';
  signal busy        : std_logic;
  signal i2c_data_wr : std_logic_vector(7 downto 0) := (others => '0');
  signal i2c_addr    : std_logic_vector(6 downto 0) := (others => '0');
  signal prev_mode : std_logic_vector(2 downto 0) := "000"; -- Stores previous MODE

  type state_type is (start, write, read);
  signal state : state_type;

begin
  reset_n <= not reset and not rst;

  inst_i2cMaster : i2c_master
  generic map(
    input_clk => 50_000_000, --input clock speed from user logic in Hz
    bus_clk   => 50_000) --speed the i2c bus (scl) will run at in Hz
  port map
  (
    clk       => clk, --system clock
    reset_n   => reset_n, --active low reset
    ena       => i2c_ena, --latch in command
    addr      => i2c_addr, --address of target slave
    rw        => i2c_rw, --'0' is write, '1' is read (I am writing data ABCD)
    data_wr   => i2c_data_wr, --data to write to slave
    busy      => busy, --indicates transaction in progress
    data_rd   => i2c_data_rd, --data read from slave (e.g. a sensor)
    ack_error => open, --flag if improper acknowledge from slave
    sda       => sda, --serial data output of i2c bus
    scl       => scl
  );

  -----------------------------------------------------------------------------------------------------------------------------------
  process (mode)
--  variable ControlByte : std_logic_vector(1 downto 0) := X"02";
  begin
    case mode is
      when "000"  => ControlByte  <=  X"00"; -- LDR mode 
      when "001"  => ControlByte  <= X"01"; -- TEMP mode 
      when "010"  => ControlByte  <= X"03"; -- POT mode
      when "011"  => ControlByte  <= X"02"; -- PWM mode
      when others => ControlByte <= X"02";
    end case;
  end process;

  process (clk, reset)
  begin
    if reset = '1' then
      -- Reset logic
      i2c_ena  <= '0';
      i2c_rw   <= '0';
      state    <= start;
      cont     <= X"01FFFFF";
      i2c_addr    <= (others => '0');
      i2c_data_wr <= (others => '0');
      data_out <= (others => '0');
      prev_mode <= MODE;
    elsif rising_edge(clk) then
      -- Main logic
      if MODE /= prev_mode then
        cont <= X"01FFFFF";
        state <= start;
        rst <= '1';
        i2c_ena <= '0';
        prev_mode <= MODE;
      else
     case state is
      when start =>
      if (cont /= X"0000000") then
        cont    <= cont - 1;
        rst     <= '1';
        state   <= start;
        i2c_ena <= '0';
      else
        rst         <= '0';
        i2c_ena     <= '1';
        i2c_rw      <= '0';
        data_out <= (others => '0');
        i2c_addr    <= writeAddr;
        i2c_data_wr <= ControlByte;
        state       <= write;
      end if;
      when write =>
      if busy = '0' then
        i2c_addr    <= ReadAddr;
        i2c_data_wr <= (others => '0');
        i2c_rw      <= '1';
        state       <= read;
      end if;
      when read => 
        i2c_rw      <= '1';
        if busy = '0' then 
            data_out <= i2c_data_rd;
        end if;
      when others =>
      state <= start;
    end case;
    end if;
  end if;
end process;
end Behavioral;