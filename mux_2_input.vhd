--------------------------
-- 2 input mux
--- used for 32 bit signals
---------------------------

Library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity mux2input is
    generic(width: integer);
    port(d0, d1: in STD_LOGIC_VECTOR(width-1 downto 0);
        s:      in STD_LOGIC;
        y:      out STD_LOGIC_VECTOR(width-1 downto 0));

end;

architecture behave of mux2input is
begin 
    y<= d0 when s = '0' else d1;
end;