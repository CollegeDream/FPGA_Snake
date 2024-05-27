--------------------------
-- 5 input mux
--- used for 32 bit signals
---------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.all;

entity mux5inputSB is -- five input single bit multiplexer
  generic(width: integer);
  port(d0, d1, d2, d3, d4: in  STD_LOGIC;
       s:      in  STD_LOGIC_VECTOR(2 downto 0);
       y:      out STD_LOGIC);
end;

architecture behave of mux5inputSB is
begin
    with s(2 downto 0) select y <=
        d0 when "000",
        d1 when "001",
        d2 when "010",
        d3 when "011",
        d4 when others;
end;