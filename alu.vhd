----------------------------------------------------------------
-- Module Name: alu - group designed modified from mips 1 group
----------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;
use IEEE.math_real.all;

entity alu is
    generic ( width : integer );
    port (  -- the alu connections to external circuitry:
      a, b :          in STD_LOGIC_VECTOR( width-1 downto 0 );
	    f :             in STD_LOGIC_VECTOR( 5 downto 0 );
	    y :             out STD_LOGIC_VECTOR( width-1 downto 0 );
      zero:           out STD_LOGIC
    );-- operation result
end alu;

architecture behavioral of alu is
  signal equality, aband : STD_LOGIC_VECTOR( width-1 downto 0 );
  signal bout, sum            : STD_LOGIC_VECTOR(width downto 0);
  signal prod            : STD_LOGIC_VECTOR( 2*width -1 downto 0);
  signal const_zero      : STD_LOGIC_VECTOR((width-1) downto 0) := (others => '0');
  signal out_inter       : STD_LOGIC_VECTOR((width-1) downto 0);
begin
  bout <= '0' & b when ( f(5) = '0' ) else '1' & (not b);
  sum <= (('0' & a) + bout) + f(5);  -- 2's complement depends on f(5)
  
  equality <= ((width-1 downto 1 => '0') & '1') when (a = b) else (width-1 downto 0 => '0'); --are a and be equal
  aband <= (a and bout(width-1 downto 0)); --designated signal for logical oppeartion and
  
  prod <= std_logic_vector((unsigned(a) * unsigned(bout(width-1 downto 0)))); --designated signal for arithmetic multiplication 

  process ( a, bout, sum, f(1 downto 0), equality(0), aband )
  begin 
      case f(4 downto 0) is 
          when "00000" => out_inter <= aband; -- AND
          when "00001" => out_inter <= a or bout(width-1 downto 0); -- OR
          when "00010" => out_inter <= not (aband); -- NAND
          when "00011" => out_inter <= not (a or bout(width-1 downto 0)); -- NOR
          when "00100" => out_inter <= (not a and b) or (aband); -- XOR (Only valid when f(4) = 1)
          when "00101" => out_inter <= sum(width-1 downto 0); -- ADDITION
          when "00110" => out_inter <= (width-1 downto 1 => '0') & sum(width); -- slt
          when "00111" => out_inter <= ((width-1 downto 1 => '0') & sum(width)) or equality; -- sleq
          when "01000" => out_inter <= ((width-1 downto 1 => '0') & not sum(width)); -- sgeq
          when "01001" => out_inter <= (((width-1 downto 1 => '0') & not sum(width))) and (not equality); -- sgt
          -- when "01010" => out_inter <= equality; -- EQUALITY
          when "01011" => out_inter <= prod(2*width -1 downto width); -- MULTIPLICATION HIGH
          when "01100" => out_inter <= prod(width-1 downto 0); -- MULTIPLICATION LOW
          when "01101" => out_inter <= std_logic_vector(shift_left(unsigned(a), to_integer(unsigned(bout((width-1) downto 0))))); -- BIT SHIFT LEFT
          when "01110" => out_inter <= std_logic_vector(shift_right(unsigned(a), to_integer(unsigned(bout((width-1) downto 0))))); -- BIT SHIFT RIGHT
          when others => out_inter <= (others => 'X');
      end case;
      
      end process;
      y <= out_inter; -- drives output signal
      -- set the zero flag if result is 0
      zero <= '1' when out_inter = const_zero else '0';

end behavioral;