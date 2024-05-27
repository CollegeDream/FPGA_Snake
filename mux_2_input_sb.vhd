--------------------------
-- 2 input mux
--- used for 1 bit signals
---------------------------
Library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity mux2inputSB is
    generic(width: integer);
    port(d0, d1: in STD_LOGIC;
        s:      in STD_LOGIC;
        y:      out STD_LOGIC);
end;

architecture behave of mux2sb is
begin 
    y<= d0 when s = '0' else d1;
end;