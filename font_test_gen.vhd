-------------------------------------------------------------------------------
-- Listing 13.2
-- Code modified from https://academic.csuohio.edu/chu_p/rtl/fpga_vhdl.html
-- Updated 12/2/2020 by Kent Jones
-- implementation taken from in class example
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity font_test_gen is
  port (
    clk              : in std_logic;
    video_on         : in std_logic;
    char_num         : in std_logic_vector(6 downto 0);
    pixel_x, pixel_y : in std_logic_vector(9 downto 0);
    rgb_text         : out std_logic_vector(2 downto 0);
    reset            : in std_logic
  );
end font_test_gen;

architecture arch of font_test_gen is
  signal rom_addr  : std_logic_vector(10 downto 0);
  signal row_addr  : std_logic_vector(3 downto 0);
  signal bit_addr  : std_logic_vector(2 downto 0);
  signal font_word : std_logic_vector(7 downto 0);
  signal font_bit  : std_logic;
begin

  -- compute the address in rom for character number char_num
  row_addr <= pixel_y(3 downto 0);
  rom_addr <= char_num & row_addr;

  -- lookup the 8 bit font_word from the font rom
  font_unit : entity work.font_rom
    port map(clk => clk, addr => rom_addr, data => font_word, reset => reset);

  bit_addr <= not ( pixel_x(2 downto 0) );
  font_bit <= font_word(to_integer(unsigned(bit_addr)));

  -- rgb multiplexing circuit
  process ( video_on, font_bit )
  begin
    if video_on = '0' then
      rgb_text <= "000"; --blank
    else
      if font_bit = '1' then
        rgb_text <= "010"; -- green
      else
        rgb_text <= "000"; -- black
      end if;
    end if;
  end process;
end arch;