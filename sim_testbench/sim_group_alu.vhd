library IEEE; 
use IEEE.STD_LOGIC_1164.all; 
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

entity processor_testbench is
end;

architecture processor_testbench of processor_testbench is

    component processor_top is -- top-level design for testing
      port( 
           clk : in STD_LOGIC;
           --ps2clk     : in STD_LOGIC;
           ps2data    : in STD_LOGIC_VECTOR(31 downto 0);
           reset: in STD_LOGIC;
           fast_clk: in STD_LOGIC;
           out_port_1 : out STD_LOGIC_VECTOR(15 downto 0);
           pixel_x, pixel_y: in std_logic_vector(9 downto 0);
           font_out: out std_logic_vector(6 downto 0)
           );
    end component;

    signal clk : STD_LOGIC;
    signal fast_clk: STD_LOGIC;

    signal ps2data: STD_LOGIC_VECTOR(31 downto 0);
    signal reset : STD_LOGIC;
    signal out_port_1 : STD_LOGIC_VECTOR(15 downto 0);
    signal pixel_x : STD_LOGIC_VECTOR(9 downto 0);
    signal pixel_y : STD_LOGIC_VECTOR(9 downto 0);
    signal fount_out: STD_LOGIC_VECTOR(6 downto 0);
    
begin
  pixel_x <= "0000000001";
  pixel_y <= "0000000001";
  --ps2data <= '0';
  -- Generate simulated mips clock with 10 ns period
  clkproc: process begin
    clk <= '1';
    fast_clk <= '1';
    --ps2clk <= '1';

    wait for 10 ns; 
    clk <= '0';
    fast_clk <= '0';
    --ps2clk <= '0';
    wait for 10 ns;
  end process;
  
  -- Generate reset for first few clock cycles
  reproc: process begin
    reset <= '1';
    wait for 22 ns;
    reset <= '0';
    wait;
  end process;
  
  -- instantiate device to be tested
  dut: processor_top port map( 
       clk => clk, 

       ps2data => ps2data,
       fast_clk => fast_clk,
       reset => reset,
       out_port_1 => out_port_1,
       pixel_x => pixel_x,
       pixel_y => pixel_y,
       font_out => fount_out );

end processor_testbench;