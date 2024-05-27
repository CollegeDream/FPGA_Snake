----------------------------------------------------------
-- VGA & Snake Memory implementations
---------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.all; 
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

entity vga_display is 
    port( 
        -- System Clock  
        fast_clk : in std_logic;
        -- passed in clk div signal
        slow_clk : in std_logic;

        -- writing values
        write_data: in STD_LOGIC_VECTOR(18 downto 0);
        vgaWE: in std_logic_vector (1 downto 0);
        pixel_x, pixel_y   : in std_logic_vector(9 downto 0);
        snake_read         : out std_logic_vector(31 downto 0);
        reset              : in std_logic;

        font_out           : out std_logic_vector(6 downto 0)
    );
end;

---------------------------------------------------------
-- Architecture Definitions
---------------------------------------------------------

architecture vga_display of vga_display is

    
    -- clk_div is a 29 bit counter provided by the display hex 
    -- use bits from this to provide a slowed clock
    signal clk_div  : std_logic_vector(28 downto 0);


    signal x_cord_inter         : std_logic_vector(9 downto 0);
    signal y_cord_inter         : std_logic_vector(9 downto 0);
                 
    begin        
        -- intermediate signals to handle vga position 
        x_cord_inter <= std_logic_vector(shift_right(unsigned(pixel_x), 3));
        y_cord_inter <= std_logic_vector(shift_right(unsigned(pixel_y), 4));
                                                       

        -- intializing the vga ram 
        vga_mem_unit:  entity work.vga_mem
            port map(
                clk => slow_clk,
                x_cord => x_cord_inter(6 downto 0),
                y_cord => y_cord_inter(4 downto 0),
                write_data => write_data(12 downto 0),
                vgaWE => vgaWE,
                read_data => font_out,
                reset => reset
            );
        -- initializing the snake memory entity to track the snakes position relative to vga dimensions
        snake_mem_unit: entity work.snake_mem
            port map(
                clk => slow_clk,
                write_data => write_data,
                vgaWe => vgaWe,
                snake_read => snake_read,
                reset => reset
            );
    end vga_display;
