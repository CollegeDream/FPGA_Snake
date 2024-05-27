------------------------------------------------------------------------------
-- Snake Queue Memory
------------------------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.all; 
use STD.TEXTIO.all;
use IEEE.STD_LOGIC_UNSIGNED.all;  
use IEEE.NUMERIC_STD.all;

entity snake_mem is -- data memory
  port(clk:                    in STD_LOGIC;
       write_data:             in STD_LOGIC_VECTOR(18 downto 0);
       vgaWe:                  in STD_LOGIC_VECTOR(1 downto 0);
       snake_read:             out STD_LOGIC_VECTOR(31 downto 0);
       reset:                  in STD_LOGIC);
end;

architecture behave of snake_mem is
  type ramtype is array (127 downto 0) of STD_LOGIC_VECTOR(11 downto 0);
  impure function InitRamFromFile ( RamFileName : in string ) return RamType is
    variable ch: character;
    variable index : integer;
    variable result: signed(11 downto 0);
    variable tmpResult: signed(23 downto 0);
    file mem_file: TEXT is in RamFileName;
    variable L: line;
    variable RAM : ramtype;
    begin
      -- initialize memory from a file
      for i in 0 to 127 loop -- set all contents low
        RAM(i) := std_logic_vector(to_unsigned(0, 12));
      end loop;
      index := 0;
      while not endfile(mem_file) loop
        -- read the next line from the file
        readline(mem_file, L);
        result := to_signed(0,12);
        for i in 1 to 2 loop
          -- read character from the line just read
          read(L, ch);
          --  convert character to a binary value from a hex value
          if '0' <= ch and ch <= '9' then
            tmpResult := result*16 + character'pos(ch) - character'pos('0') ;
            result := tmpResult(11 downto 0);
          elsif 'a' <= ch and ch <= 'f' then
            tmpResult := result*16 + character'pos(ch) - character'pos('a')+10 ;
            result := tmpResult(11 downto 0);
          else report "Format error on line " & integer'image(index)
            severity error;
          end if;
        end loop;
  
        -- set the width bit binary value in ram
        RAM(index) := std_logic_vector(result);
        index := index + 1;
      end loop;
      -- return the array of instructions loaded in RAM
      return RAM;
    end function;    
    
    -- use the impure function to read RAM from a file and store in the FPGA's ram memory
    signal mem: ramtype := InitRamFromFile("blank.dat");
    --used to reset the snake memory from previous state
    signal blank: ramtype := InitRamFromFile("blank.dat");
 
  begin
    process ( clk, vgaWE )
      begin
        if clk'event and clk = '1' then
          if (reset = '1') then -- if reset is pressed  
            mem <= blank; --clear the snake memory to default position 
          elsif (vgaWe = "01") then --if the WE signal is high
            mem(to_integer(unsigned(write_data(18 downto 12)))) <= write_data(11 downto 0); --updates the snake location in snake memory 
          end if;
        end if;
        --32 bit signal
    snake_read <= "00000000000000000000" & mem(to_integer(unsigned(write_data(6 downto 0)))); -- word aligned sign extended to fit in register size 
    end process;
end behave;