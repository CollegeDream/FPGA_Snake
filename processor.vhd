------------------------------------------------------------
-- processor declaration
------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.all;

entity processor is
 -- single cycle group processor
  generic(width: integer);
  port(clk, reset:        in  STD_LOGIC; --clk div signal
       pc:                inout STD_LOGIC_VECTOR((width-1) downto 0); -- pc counter signal
       instr:             in  STD_LOGIC_VECTOR((width-1) downto 0); -- instruction code signal
       data_memwrite:     out STD_LOGIC; -- high if declaring a variable
       vga_memwrite:      out STD_LOGIC_VECTOR(1 downto 0); --high if writing to vga memory
       aluout, writedata: inout STD_LOGIC_VECTOR((width-1) downto 0); -- data ouptut signals
       mem_readdata:      in  STD_LOGIC_VECTOR((width-1) downto 0);-- input from the data mem registers
       kb_readdata:       in STD_LOGIC_VECTOR((width-1) downto 0); --input from the keyboard
       snake_read:        in STD_LOGIC_VECTOR((width-1) downto 0) -- input from the snake memory
      );
end;

---------------------------------------------------------
-- Architecture Definitions
---------------------------------------------------------

architecture struct of processor is
  --controller component
  component controller
    port( op:                                in  STD_LOGIC_VECTOR(4 downto 0);
          zero:                              in  STD_LOGIC;
          aluout_top_bit:                     in  STD_LOGIC;
          blez, bgtz, eq, neq, blt:        out STD_LOGIC; 
          WE:                                out STD_LOGIC;
          SRCA_Select:                       out STD_LOGIC;
          branch:                            out STD_LOGIC;
          memWE:                             out STD_LOGIC_VECTOR(2 downto 0);
          readSelect:                        out STD_LOGIC_VECTOR(1 downto 0);
          ALUop:                             out STD_LOGIC_VECTOR(5 downto 0);
          link:                              out STD_LOGIC;
          branchCTRL:                        out STD_LOGIC_VECTOR(2 downto 0);
          jump:                              out STD_LOGIC;
          varDecl:                           out STD_LOGIC);
  end component;

 -- datapath component
  component datapath generic(width : integer );
  port(clk, reset:             in STD_LOGIC;
      instr:                  in STD_LOGIC_VECTOR((width-1) downto 0);
      regwrite:               in STD_LOGIC;
      mem_readdata:           in STD_LOGIC_VECTOR((width-1) downto 0);
      memWE:                  in STD_LOGIC_VECTOR(2 downto 0);
      zero:                   out STD_LOGIC;
      pc:                     inout STD_LOGIC_VECTOR((width-1) downto 0);
      aluout:                 inout STD_LOGIC_VECTOR((width-1) downto 0);
      branch:                 in STD_LOGIC;
      branchCTRL:             in STD_LOGIC_VECTOR(2 downto 0);
      blez, bgtz, neq, eq:    in STD_LOGIC;
      blt, link:              in STD_LOGIC;
      SRCA_Select:            in STD_LOGIC;
      ALUop:                  in STD_LOGIC_VECTOR(5 downto 0);
      readSelect:             in STD_LOGIC_VECTOR(1 downto 0);
      jump:                   in STD_LOGIC;
      writedata:              inout STD_LOGIC_VECTOR((width-1) downto 0);
      data_mem_we:            out STD_LOGIC;
      vga_mem_we:             out STD_LOGIC_VECTOR(1 downto 0);
      varDecl:                in STD_LOGIC;
      snake_read:             in STD_LOGIC_VECTOR((width-1) downto 0);
      kb_readdata:            in STD_LOGIC_VECTOR((width-1) downto 0)

      );
  end component;
  
  -- Signals to wire the datapath unit to the controller unit
  signal memtoreg, alusrc, regdst, regwrite, jump, pcsrc, blez, bgtz, shiftctrl, varDecl: STD_LOGIC;
  signal readSelect : STD_LOGIC_VECTOR (1 downto 0);
  signal memWE: STD_LOGIC_VECTOR(2 downto 0);
  signal zero, eq, neq, blt, WE, SRCA_Select, link, branch : STD_LOGIC;
  signal ALUop : STD_LOGIC_VECTOR(5 downto 0);
  signal alucontrol: STD_LOGIC_VECTOR(3 downto 0);
  signal branchCTRL: STD_LOGIC_VECTOR(2 downto 0);
  
begin	
--wiring up the controller and datapath signals		   
  control: controller port map(op => instr((width-1) downto 27), zero => zero, aluout_top_bit => aluout(width-1), blez => blez, bgtz => bgtz,
                               eq => eq, neq => neq, blt => blt, WE => WE, SRCA_Select => SRCA_Select, branch => branch, memWE => memWE,
                               readSelect => readSelect, ALUop => ALUop, link => link, branchCTRL => branchCTRL, jump =>jump, varDecl => varDecl);     

  dp: datapath generic map(width) port map(clk => clk, reset => reset, 
                                           instr=>instr, regwrite=>WE, mem_readdata => mem_readdata, memWE => memWE, 
                                            zero=>zero, pc => pc, aluout=>aluout, branch=>branch, branchCTRL => branchCTRL, blez => blez, bgtz => bgtz, neq => neq, eq => eq,
                                            blt => blt, link => link, SRCA_Select => SRCA_Select, ALUop => ALUop, readSelect => readSelect, jump => jump, writedata => writedata, 
                                            data_mem_we => data_memwrite, vga_mem_we => vga_memwrite, varDecl => varDecl, snake_read => snake_read, kb_readdata => kb_readdata);

end;