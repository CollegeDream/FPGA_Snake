-------------------------------------------------------
-- register file component definition
--- implementation taken from previous mips assignments
--------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.all; 
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;
use IEEE.math_real.all;

entity regfile is
    generic(width: integer);
    port(clk:                               in STD_LOGIC;
         write_enable:                      in STD_LOGIC;
         reg_one, reg_two, reg_three:       in STD_LOGIC_VECTOR(3 downto 0);
         write_data:                        in STD_LOGIC_VECTOR((width-1) downto 0);
         out_one, out_two, out_three:       out STD_LOGIC_VECTOR((width-1) downto 0));

end;

architecture behave of regfile is
    type ramtype is array (15 downto 0) of STD_LOGIC_VECTOR((width-1) downto 0);
    signal mem: ramtype;

begin
    -- three-ported register file
  
  -- write to the first port on rising edge of clock
  -- write address is in reg_one
    process(clk, write_enable, reg_one, write_data) begin
        if rising_edge(clk) then
            if write_enable = '1' then
                mem(to_integer(unsigned(reg_one))) <= write_data;
            end if;
        end if;
    end process;

    -- read mem from three ports
    -- addresses are reg_one, reg_two, reg_three
    process(reg_one, reg_two, reg_three, mem) begin
        if ( to_integer(unsigned(reg_one)) = 0) then 
		    out_one <= (others => '0'); -- register 0 holds 0
        else 
            out_one <= mem(to_integer(unsigned(reg_one)));
        end if;
        
        if ( to_integer(unsigned(reg_two)) = 0) then 
            out_two <= (others => '0'); -- register 0 holds 0
        else 
            out_two <= mem(to_integer( unsigned(reg_two)));
        end if;

        if ( to_integer(unsigned(reg_three)) = 0) then 
            out_three <= (others => '0'); -- register 0 holds 0
        else 
            out_three <= mem(to_integer( unsigned(reg_three)));
        end if;
    end process;
end;

