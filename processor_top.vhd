---------------------------------------------------------
-- top level processor component definition
---------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.all; 
use IEEE.STD_LOGIC_UNSIGNED.all;

entity processor_top is -- top-level design for testing
  port( 
       clk        : in STD_LOGIC; --clk for clk div
       ps2data    : in STD_LOGIC_VECTOR(31 downto 0); --keyboard data
       fast_clk   : in STD_LOGIC; --100MHZ clock
       reset      : in STD_LOGIC; --reset signal
       out_port_1 : out STD_LOGIC_VECTOR(15 downto 0); --displays the top 4 bytes of the instruction
       pixel_x, pixel_y:        in std_logic_vector(9 downto 0); --vga coordinates
      font_out:                 out std_logic_vector(6 downto 0) --used for font gen in vga 
      );
end;

---------------------------------------------------------
-- Architecture Definitions
---------------------------------------------------------

architecture processor_top of processor_top is

  --instruction memory component
  component imem generic(width: integer);
    port(address:  in  STD_LOGIC_VECTOR(8 downto 0);
         read_data: out STD_LOGIC_VECTOR((width-1) downto 0));
  end component;
  --data memory component
  component data_mem generic(width: integer);
    port(clk, write_enable_mem:  in STD_LOGIC;
       address:                 in STD_LOGIC_VECTOR( 13 downto 0);
       write_data:              in STD_LOGIC_VECTOR((width-1) downto 0);
       read_data:               out STD_LOGIC_VECTOR((width-1) downto 0));
  end component;
  -- processor component
  component processor generic(width: integer);
    port(clk, reset:      in  STD_LOGIC;
       pc:                inout STD_LOGIC_VECTOR((width-1) downto 0);
       instr:             in  STD_LOGIC_VECTOR((width-1) downto 0);
       data_memwrite:     out STD_LOGIC;
       vga_memwrite:      out STD_LOGIC_VECTOR(1 downto 0);
       aluout, writedata: inout STD_LOGIC_VECTOR((width-1) downto 0);
       mem_readdata:      in  STD_LOGIC_VECTOR((width-1) downto 0);   
       kb_readdata:       in STD_LOGIC_VECTOR((width-1) downto 0);
       snake_read:        in STD_LOGIC_VECTOR(width-1 downto 0));

  end component;
  --vga component
  component vga_display
    port(fast_clk: in std_logic;
    slow_clk: in std_logic;
    write_data   :  in std_logic_vector(18 downto 0);
    vgaWE        :  in std_logic_vector(1 downto 0);
    pixel_x, pixel_y   : in std_logic_vector(9 downto 0);
    snake_read         : out std_logic_vector(31 downto 0);
    reset              : in std_logic;
    font_out           : out std_logic_vector(6 downto 0));
  end component; 


  -- signals to wire the instruction memory, data memory and mips processor together
  signal mem_readdata: STD_LOGIC_VECTOR(31 downto 0);
  signal instr: STD_LOGIC_VECTOR(31 downto 0);
  signal writedata: STD_LOGIC_VECTOR(31 downto 0);
  signal dataadr: STD_LOGIC_VECTOR(31 downto 0);
  signal data_memwrite: STD_LOGIC;
  signal vga_memwrite: STD_LOGIC_VECTOR(1 downto 0);
  signal pc: STD_LOGIC_VECTOR(31 downto 0); 
  signal dummy_sig: STD_LOGIC_VECTOR(9 downto 0);
  signal snake_read: STD_LOGIC_VECTOR(31 downto 0);
  signal ascii_code: STD_LOGIC_VECTOR(31 downto 0);
  signal ascii_new: STD_LOGIC;
         
  
  begin     
      -- wire output port signal to top 4 bytes of instruction
      out_port_1 <= instr(31 downto 16);

	  -- wire up the processor and memories
	  processor1: processor generic map(32) port map(clk => clk, reset => reset, pc => pc, 
	                                       instr => instr, data_memwrite => data_memwrite, vga_memwrite => vga_memwrite, aluout => dataadr, 
	                                       writedata => writedata, mem_readdata => mem_readdata, snake_read => snake_read, kb_readdata => ps2data );
                                         
	  imem1: imem generic map(32) port map(address => pc(10 downto 2), read_data => instr);
    
	  dmem1: data_mem generic map(32) port map( clk => clk, write_enable_mem => data_memwrite, address => instr(13 downto 0), 
	                                        write_data => writedata, read_data => mem_readdata);

    -- wire up the vga display
    vga_disp: vga_display port map(slow_clk => clk, fast_clk => fast_clk, write_data => dataadr(18 downto 0), vgaWE => vga_memwrite, 
                                    pixel_x => pixel_x, pixel_y => pixel_y, snake_read => snake_read, reset => reset, font_out => font_out);
                                  
  end processor_top;