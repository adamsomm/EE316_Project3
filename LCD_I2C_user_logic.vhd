
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;

ENTITY I2C_user_logic IS
  PORT(
	 clk			: IN STD_LOGIC;
	 reset		: IN STD_LOGIC;
	 iData  		: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
	 scl			: INOUT STD_LOGIC;
	 sda			: INOUT STD_LOGIC
	
);             
END I2C_user_logic;

-- -----------------------------------------------------------------------------------------------------------------------------------

architecture user_logic of I2C_user_logic is

component i2c_master IS
  GENERIC(
    input_clk : INTEGER := 50_000_000; --input clock speed from user logic in Hz
    bus_clk   : INTEGER := 100_000);   --speed the i2c bus (scl) will run at in Hz
	-- ADC runs at 400,000, lcd at 100k max 
  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
    ena       : IN     STD_LOGIC;                    --latch in command
    addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
    rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
    data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
    busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
    data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
    ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
    sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
    scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
END component;
-- -----------------------------------------------------------------------------------------------------------------------------------

signal cont 		: unsigned(27 downto 0) := X"00000FF"; 
signal slave_addr: std_logic_vector(6 downto 0):=X"27";--LCD start address
--signal i2c_addr: std_logic_vector(6 downto 0);
signal data_wr: std_logic_vector(7 downto 0);
--signal newdata: std_logic_vector(15 downto 0);
--signal reset_n, i2c_ena, busy, i2c_rw, oldBusy :std_logic;
--signal byteSel: integer range 0 to 12;
--signal i2c_data_wr : std_LOGIC_VECTOR(7 downto 0);
type state is (start, addr_s, data_s, repeat);
signal state : state_type;
signal rst: std_logic := '0';
signal i2c_ena: std_logic := '0';
signal busyCNT: std_logic := '0';
signal oldBusy: std_logic := '0'; 
signal RealBusy: std_logic:= '0';
-- -----------------------------------------------------------------------------------------------------------------------------------
begin
	reset_n <= not reset or rst;

inst_i2cMaster: i2c_master
generic map(
	input_clk => 50_000_000, --input clock speed from user logic in Hz
	bus_clk 	 => 100_000) 	 --speed the i2c bus (scl) will run at in Hz
port map(
	 clk       =>clk,                   --system clock
    reset_n   =>reset_n,			 --active low reset
    ena       =>i2c_ena,			 --latch in command
    addr      =>i2c_addr, --address of target slave
    rw        => i2c_rw	,				--'0' is write, '1' is read (I am writing data ABCD)
    data_wr   => i2c_data_wr, --data to write to slave
    busy      => busy,--indicates transaction in progress
    data_rd   => open,--data read from slave (e.g. a sensor)
    ack_error => open,--flag if improper acknowledge from slave
    sda       => sda,--serial data output of i2c bus
    scl       => scl

);

process(clk)
begin 
	if reset = '1' then
		rst <= '0';
		count <= X"00000FF";
		addr <= X"00";
		oldBusy <= '0';
		i2c_ena <= '0';
		state <= start;
	end if; 
if (rising_edge(Clk)) then 
	oldBusy <= busy;
	if (oldBusy = '0' AND busy = '1') then 
		RealBusy <= '1';
	else 
		RealBusy <= '0';
	end if;
	case state_type is 
		when start => -- add clock enable 
			if (cont /= X"0000000") then 
				cont <= cont - 1;
				rst <= '0';
				state <= start;
				i2c_ena <= '0';
			else 
				rst <= '1';
				i2c_ena <= '1';
				i2c_addr <= slave_addr;
				state <= addr_s;
			end if;
		when addr_s =>
			if (RealBusy = '1') then 
				i2c_rw <= '0';
				i2c_data_wr <= iData;
				state <= data_s; -- load data 
			end if;
		when data_s =>
			if (RealBusy = '1') then 
				data_wr <= iData;
				state <= repeat;
			end if;
		when repeat =>
			data_wr <= iData;
			state <= data_s;

	end case;
end if;	
end process;

end user_logic;	
