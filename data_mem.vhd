------------------------------------------------------------------------------
-- Data Memory
------------------------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.all; 
use STD.TEXTIO.all;
use IEEE.STD_LOGIC_UNSIGNED.all;  
use IEEE.NUMERIC_STD.all;

entity data_mem is -- data memory
  generic(width: integer);
  port(clk, write_enable_mem:  in STD_LOGIC; --control signals
       address:                in STD_LOGIC_VECTOR(13 downto 0); --variable location in the data memory
       write_data:             in STD_LOGIC_VECTOR((width-1) downto 0); --what is being written
       read_data:              out STD_LOGIC_VECTOR((width-1) downto 0)); -- what is being pulled from the data memory
end;
--creates a ram for storing upto 64 32bit variables 
architecture behave of data_mem is
  type ramtype is array (63 downto 0) of STD_LOGIC_VECTOR((width-1) downto 0);
  signal mem: ramtype; 
begin
  process ( clk, address, write_enable_mem, write_data, mem ) is
  begin
    if clk'event and clk = '1' then
        if (write_enable_mem = '1') then -- if this signal is high then a instruction is trying to write to data memory 
			    mem( to_integer(unsigned(address(5 downto 0))) ) <= write_data; --writing the data to a specified address in the ram
        end if;
    end if;
    read_data <= mem( to_integer(unsigned(address(5 downto 0))) ); -- word aligned output signal
  end process;
end;