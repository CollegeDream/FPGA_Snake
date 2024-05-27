------------------------------------------------------------------------------
-- VGA Memory
------------------------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.all; 
use STD.TEXTIO.all;
use IEEE.STD_LOGIC_UNSIGNED.all;  
use IEEE.NUMERIC_STD.all;

entity vga_mem is -- vga memory
  port(clk:                    in STD_LOGIC;
       x_cord:                 in STD_LOGIC_VECTOR(6 downto 0);
       y_cord:                 in STD_LOGIC_VECTOR(4 downto 0);
       write_data:             in STD_LOGIC_VECTOR(12 downto 0);
       vgaWe:                  in STD_LOGIC_VECTOR(1 downto 0);
       read_data:              out STD_LOGIC_VECTOR(6 downto 0);
       reset:                  in STD_LOGIC);
end;

architecture behave of vga_mem is
  -- 2400 valid ascii positions across the screen display
  type ramtype is array (2399 downto 0) of STD_LOGIC_VECTOR(6 downto 0);
  -- function to initialize the vga memory memory from a data file
  impure function InitRamFromFile ( RamFileName : in string ) return RamType is
    variable ch: character; -- ascii character to be printed 
    variable index : integer; -- position in ram
    variable result: signed(6 downto 0); -- the generated ascii character
    variable tmpResult: signed(13 downto 0); -- used to create ascii character
    file mem_file: TEXT is in RamFileName; -- file being read from for initialization
    variable L: line; -- current line in the file 
    variable RAM : ramtype;
    begin
      -- initialize memory from a file
      for i in 0 to 2399 loop -- set all contents low
        RAM(i) := std_logic_vector(to_unsigned(0, 7));
      end loop;
      index := 0;
      while not endfile(mem_file) loop
        -- read the next line from the file
        readline(mem_file, L);
        result := to_signed(0,7);
        for i in 1 to 2 loop
          -- read character from the line just read
          read(L, ch);
          --  convert character to a binary value from a hex value
          if '0' <= ch and ch <= '9' then
            tmpResult := result*16 + character'pos(ch) - character'pos('0') ;
            result := tmpResult(6 downto 0);
          elsif 'a' <= ch and ch <= 'f' then
            tmpResult := result*16 + character'pos(ch) - character'pos('a')+10 ;
            result := tmpResult(6 downto 0);
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
    signal mem: ramtype := InitRamFromFile("main_screen.dat"); -- begin state with borders
    signal game_over_screen: ramtype := InitRamFromFile("gameover.dat"); -- display game over text
    signal main_screen: ramtype := InitRamFromFile("main_screen.dat"); -- hold for reseting the game back to original state
    signal game_over: std_logic := '0'; -- used to freeze vga screen writing
    signal prev_write_data: std_logic_vector(11 downto 0) := "000000000000"; -- used to verify that the current snake movement is valid 
 
  begin
    process ( clk, vgaWE, game_over )
      begin
        if clk'event and clk = '1' then
          -- the check to see if the game is still in a valid state; game_over is low, the previous write data is not equal to the new write data,
          -- the character being over-written is not a snake body character, and the character being over-written is not a border character 
          if((mem(to_integer(unsigned(write_data(11 downto 0)))) = "0010110" or mem(to_integer(unsigned(write_data(11 downto 0)))) = "0101010") 
          and prev_write_data /= write_data(11 downto 0) and vgaWE = "10" and write_data(11 downto 0) /= "0000100" and game_over /= '1')       then
            game_over <= '1'; -- set game_over to high 
            mem <= game_over_screen; -- print game over screen to vga display
          elsif (vgaWe = "10" and game_over /= '1' and write_data(12) /= '1') then --case to print the snake body character 
            mem(to_integer(unsigned(write_data(11 downto 0)))) <= "0010110"; --place character into memory
            prev_write_data <= write_data(11 downto 0); -- update previous write data
          elsif (vgaWe = "10" and game_over /= '1' and write_data(12) = '1') then -- print fruit case
            mem(to_integer(unsigned(write_data(11 downto 0)))) <= "0000100"; --place the fruit character into memory
          elsif (vgaWe = "11" and game_over /= '1' and mem(to_integer(unsigned(write_data(11 downto 0)))) /= "0000100") then -- case where fruit spawns on snake, don't delete fruit
            mem(to_integer(unsigned(write_data(11 downto 0)))) <= "0000000";  -- place a blank character into the screen; remakes the background
          elsif(reset = '1') then -- reset case
              game_over <= '0'; -- make game over low
              mem <= main_screen; -- reset all screen characters
              prev_write_data <= "000001010001"; -- offset the previous wirte data so the snake can begin moving 
          end if;
        end if;
    read_data <= mem( to_integer(unsigned(x_cord)) + (to_integer(unsigned(y_cord)) * 80)); -- word aligned; calculates the correct pixel position and outputs it
    end process;
end behave;