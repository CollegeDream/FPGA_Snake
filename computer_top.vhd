----------------------------------------------------------
-- mips computer wired to hexadecimal display and reset 
-- button
---------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.all; 
use IEEE.STD_LOGIC_UNSIGNED.all;

entity computer_top is -- top-level design for testing
  port( 
       CLK100MHZ    : in STD_LOGIC; -- standard clock signal
       PS2Clk       : in STD_LOGIC; -- keybaord clock signal
       PS2Data      : in STD_LOGIC; -- keyboard input data
       seg          : out STD_LOGIC_VECTOR(6 downto 0); --used for 7 seg displays opcode
       an           : out STD_LOGIC_VECTOR(3 downto 0); --used for 7-seg
       dp           : out STD_LOGIC; --display port
       LED          : out  STD_LOGIC_VECTOR(15 downto 0); --driven by keyboard input signal
       btnC         : in STD_LOGIC; -- drives reset signal to components 
       btnD         : in STD_LOGIC;
       Hsync, Vsync : out std_logic; -- Horizontal and Vertical Synch
       vgaRed       : out std_logic_vector(3 downto 0); -- Red bits
       vgaGreen     : out std_logic_vector(3 downto 0); -- Green bits
       vgaBlue      : out std_logic_vector(3 downto 0)
	   );
end;

---------------------------------------------------------
-- Architecture Definitions
---------------------------------------------------------

architecture computer_top of computer_top is
-- display component for basic I/O drives hex and LEDS
  component display_hex
    port (
        CLKM : in STD_LOGIC;
        x : in STD_LOGIC_VECTOR(15 downto 0);
        seg : out STD_LOGIC_VECTOR(6 downto 0);
        an : out STD_LOGIC_VECTOR(3 downto 0);
        dp : out STD_LOGIC;
        clk_div: out STD_LOGIC_VECTOR(28 downto 0)	
    );
  end component;
-- top level component for the processor component 
  component processor_top  -- top-level design for testing
    port( 
         clk : in STD_LOGIC; --clk divider signal
         fast_clk: in STD_LOGIC; -- 100MHZ clk
         ps2data            : in std_logic_vector(31 downto 0); --keyboard data
         reset: in STD_LOGIC; --reset
         out_port_1 : out STD_LOGIC_VECTOR(15 downto 0); --display to 7-seg
         pixel_x, pixel_y   : in std_logic_vector(9 downto 0); -- used for vga coordinates
         font_out: out std_logic_vector(6 downto 0) -- asci code siganl
         );
  end component;

  -- this is a slowed signal clock provided to the mips_top
  -- set it from a lower bit on clk_div for a faster clock
  signal clk : STD_LOGIC := '0';

  signal fast_clk : STD_LOGIC := '0';
  
  -- clk_div is a 29 bit counter provided by the display hex 
  -- use bits from this to provide a slowed clock
  signal clk_div : STD_LOGIC_VECTOR(28 downto 0);

  -- this data bus will hold a value for display by the 
  -- hex display  
  signal display_bus: STD_LOGIC_VECTOR(15 downto 0); 

  --keyboard signals
  signal ps2_code_new: STD_LOGIC;
  signal kb_ascii_out: STD_LOGIC_VECTOR(31 downto 0);
  -- vga signals
  signal video_on: STD_LOGIC;
  signal pixel_x, pixel_y: STD_LOGIC_VECTOR(9 downto 0);
  signal pixel_tick: STD_LOGIC; 
  signal key_buffer: STD_LOGIC_VECTOR(31 downto 0);
  -- signal snake_read: STD_LOGIC_VECTOR(31 downto 0);
  signal font_out: STD_LOGIC_VECTOR(6 downto 0);
  signal rgb_text, rgb_reg: STD_LOGIC_VECTOR(2 downto 0);
  
  begin
      -- wire up slow clock 
      clk <= clk_div(17); -- use a lower bit for a faster clock
      -- vga sync entity
      -- used to calculate and update the pixel position for vga display
      vga_sync_unit : entity work.vga_sync
      port map(
          clk => CLK100MHZ, reset => btnC, hsync => Hsync,
          vsync => Vsync, video_on => video_on,
          pixel_x => pixel_x, pixel_y => pixel_y,
          p_tick => pixel_tick
      );
      -- entity used to convert ps2 to an ascii code
      kb_to_ascii_unit : entity work.keyboard_to_ascii
      port map(
        clk   => clk_div(1),   --50 mhz clock to keyboard
        ps2_clk  => PS2Clk,   --clock signal from PS2 keyboard
        ps2_data  => PS2Data, --data signal from PS2 keyboard
        ascii_new => ps2_code_new,  --flag that new PS/2 code is available on ps2_code bus
        ascii_code => kb_ascii_out
      );
      -- creating a buffer register to hold the most recent key pressed
      -- currently used to keep the LED dispaly constant 
     process (ps2_code_new, kb_ascii_out, CLK100MHZ)
        variable ps2_code_new_last : std_logic := '0';
        variable key_buf: std_logic_vector (15 downto 0) := (others => '0');
     begin
        if rising_edge(clk100MHZ) then
          if (ps2_code_new_last = '0' and ps2_code_new = '1') then
                key_buf := key_buf(7 downto 0) & '0' & kb_ascii_out(6 downto 0);
          end if;
          ps2_code_new_last := ps2_code_new;
        end if;
        key_buffer <= "0000000000000000" & key_buf;
      end process;
      --driving LED display
      LED <= kb_ascii_out(15 downto 0); 
	  -- wire up the processor and memories
	  processor1: processor_top port map( clk => clk,  fast_clk => CLK100MHZ, reset => btnC, out_port_1 => display_bus,
                                       pixel_x => pixel_x, pixel_y => pixel_y, ps2data => kb_ascii_out, font_out => font_out);
	  -- wire up the display component signals                                     
	  display: display_hex port map( CLKM  => CLK100MHZ,  x => display_bus, 
	           seg => seg,  an => an,  dp => dp, clk_div => clk_div );                                      

    -- instantiate font ROM control character to look up 
    font_gen_unit : entity work.font_test_gen
      port map(
          clk => CLK100MHZ, video_on => video_on,
          char_num => font_out,
          pixel_x => pixel_x, pixel_y => pixel_y,
          rgb_text => rgb_text, 
          reset => btnC
      );

     -- rgb buffer
     process (CLK100MHZ)
     begin
         if rising_edge(CLK100MHZ) then
             if (pixel_tick = '1') then
                 rgb_reg <= rgb_text;
             end if;
         end if;
     end process;

     -- build the RGB colors from the rgb_reg
    vgaRed <= rgb_reg(2) & rgb_reg(2) & rgb_reg(2) & rgb_reg(2);
    vgaGreen <= rgb_reg(1) & rgb_reg(1) & rgb_reg(1) & rgb_reg(1);
    vgaBlue <= rgb_reg(0) & rgb_reg(0) & rgb_reg(0) & rgb_reg(0);

  end computer_top;