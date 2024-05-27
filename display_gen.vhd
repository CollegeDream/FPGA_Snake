----------------------------------------------------------------
-- 
--              DEPRECIATED COMPONENT  
-- replaced with display hex component
-------------------------------------------------------------------
Library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity displaygen is
    generic(width: integer);
    port(address:       in STD_LOGIC_VECTOR(width - 19 downto 0);
        write_data:     in STD_LOGIC_VECTOR(width-1 downto 0);
        y:              out STD_LOGIC_VECTOR(width-1 downto 0) );
end;

architecture behave of displaygen is
    signal const_zero : STD_LOGIC_VECTOR(width-1 downto 0) := (others => '0');
begin
    process(address, write_data)
    begin
        y <= const_zero;
    end process;
end;