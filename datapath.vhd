library IEEE; 
use IEEE.STD_LOGIC_1164.all; 
use IEEE.NUMERIC_STD.all;
use IEEE.math_real.all;

entity datapath is  -- datapath
    generic(width: integer);
    port(   clk, reset:             in STD_LOGIC;
            instr:                  in STD_LOGIC_VECTOR((width-1) downto 0);
            regwrite:               in STD_LOGIC;
            mem_readdata:           in STD_LOGIC_VECTOR((width-1) downto 0);
            memWE:                   in STD_LOGIC_VECTOR(2 downto 0);
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
            writedata:             inout STD_LOGIC_VECTOR((width-1) downto 0);
            data_mem_we:           out STD_LOGIC;
            vga_mem_we:            out STD_LOGIC_VECTOR(1 downto 0);
            varDecl:               in STD_LOGIC;
            snake_read:            in STD_LOGIC_VECTOR((width-1) downto 0);
            kb_readdata:           in STD_LOGIC_VECTOR((width-1) downto 0)
            );
end;

architecture struct of datapath is

    -- alu component
    component alu generic(width: integer);
    port( a, b:     in STD_LOGIC_VECTOR((width-1) downto 0);
          f:        in STD_LOGIC_VECTOR(5 downto 0);
          y:        out STD_LOGIC_VECTOR((width-1) downto 0);
          zero:     out STD_LOGIC
    );
    end component;  
    -- register file component
    component regfile generic(width: integer);
    port( clk:                        in STD_LOGIC;
          write_enable:                in STD_LOGIC;
          reg_one, reg_two, reg_three: in STD_LOGIC_VECTOR(3 downto 0);
          write_data:                  in STD_LOGIC_VECTOR((width-1) downto 0);
          out_one, out_two, out_three: out STD_LOGIC_VECTOR((width-1) downto 0)   
    );
    end component;  
    --adder component
    component adder generic(width: integer);
    port( a,b: in STD_LOGIC_VECTOR((width-1) downto 0);
          y:   out STD_LOGIC_VECTOR((width-1) downto 0));
    end component;
    -- mux component for 2, 32 bit signals
    component mux2input generic(width: integer);
    port( d0, d1: in STD_LOGIC_VECTOR((width-1) downto 0);
          s:       in STD_LOGIC;
          y:       out STD_LOGIC_VECTOR((width-1) downto 0));
    end component;
    --mux component for 4, 32 bit signals  
    component mux4input generic(width: integer);
    port(d0, d1, d2, d3: in STD_LOGIC_VECTOR(width-1 downto 0);
        s:               in STD_LOGIC_VECTOR(1 downto 0);
        y:               out STD_LOGIC_VECTOR(width-1 downto 0));
    end component;  
    --mux component for 5, 1 bit signals
    component mux5inputSB generic(width: integer);
    port(   d0, d1, d2, d3, d4: in STD_LOGIC;
            s: in STD_LOGIC_VECTOR(2 downto 0);
            y: out STD_LOGIC
    );
    end component;
    --sign extender component
    component signext generic(width: integer);
    port(a:      in STD_LOGIC_VECTOR(width - 19 downto 0);
        y:       out STD_LOGIC_VECTOR(width-1 downto 0));
    end component;
    --sign extender component for variables specifically 
    component signextVar generic(width: integer);
    port(a:      in STD_LOGIC_VECTOR(7 downto 0);
         y:      out STD_LOGIC_VECTOR(width-1 downto 0));
    end component;
    -- flip flop component
    component flopr generic(width: integer);
    port(clk, reset: in STD_LOGIC;
         d:          in STD_LOGIC_VECTOR((width-1)downto 0);
         q:          out STD_LOGIC_VECTOR((width-1) downto 0));
    end component;
    -- keyboard memory component
    component keyio generic(width: integer);
    port(address:       in STD_LOGIC_VECTOR(width - 19 downto 0);
         write_data:    in STD_LOGIC_VECTOR(width-1 downto 0);
         y:             out STD_LOGIC_VECTOR(width-1 downto 0));
    end component;
    --shifter component
    component sl2 generic(width: integer);
      port( a: in STD_LOGIC_VECTOR((width-1) downto 0);
            y: out STD_LOGIC_VECTOR((width-1) downto 0)            
      );
    end component;
 
-- The signals to wire the datapath components together
signal const_zero:          STD_LOGIC_VECTOR((width - 1) downto 0) := (others => '0');
signal four:                STD_LOGIC_VECTOR((width-1) downto 0);
signal reg_out_one:         STD_LOGIC_VECTOR((width-1) downto 0);
signal reg_out_two:         STD_LOGIC_VECTOR((width-1) downto 0);
signal reg_out_three:       STD_LOGIC_VECTOR((width-1) downto 0);
signal srca, srcb:          STD_LOGIC_VECTOR((width-1) downto 0);
signal result:              STD_LOGIC_VECTOR((width - 1) downto 0);


signal pcCTRL, pcinter:              STD_LOGIC;
signal pcnext, pcplus4, pcbranch, pcjump, pcnextbr: STD_LOGIC_VECTOR((width - 1) downto 0);
signal signimmsh: STD_LOGIC_VECTOR((width-1) downto 0);
signal signimm: STD_LOGIC_VECTOR((width-1) downto 0);
signal signimmVar: STD_LOGIC_VECTOR((width-1) downto 0);
signal signimmBin: STD_LOGIC_VECTOR((width-1) downto 0);
signal link_mux_out: STD_LOGIC_VECTOR((width-1) downto 0);
signal keyboard_readdata: STD_LOGIC_VECTOR((width-1) downto 0);

begin
      -- regfile logic wiring
      rf: regfile generic map(width) port map(  clk => clk, 
                                                write_enable => regwrite,
                                                reg_one => instr(25 downto 22),
                                                reg_two => instr(21 downto 18),
                                                reg_three => instr(17 downto 14),
                                                write_data => link_mux_out,
                                                out_one => reg_out_one,
                                                out_two => reg_out_two,
                                                out_three =>  reg_out_three
                                                );

      ---------------------------
      -- PROGRAM COUNTER LOGIC --
      ---------------------------
      -- Constant value 4 for pcadd1
      four <= const_zero((width-1) downto 4) & X"4";
      pcjump <= pcplus4((width-1) downto (width-4)) & instr((width-7) downto 0) & "00";
      pcreg: flopr generic map(width) port map(clk => clk, reset => reset, d => pcnext, q => pc);
      pcbrmux:  mux2input generic map(width) port map(d0 => pcplus4, d1 => signimmsh, s => pcCTRL, y => pcnextbr);
      pcmux: mux2input generic map(width) port map(d0 => pcnextbr, d1 => pcjump, s => jump, y => pcnext);
      immsh: sl2 generic map(width) port map(a => signimm, y => signimmsh);
      pcadd1: adder generic map(width) port map(a => pc, b => four, y => pcplus4);
      se: signext generic map(width) port map ( a => instr(13 downto 0), y => signimm);
      seVar: signextVar generic map(width) port map( a => instr(7 downto 0), y => signimmVar);
      --------------------
      -- ALU COMPONENTS --
      --------------------
      signimmSelect: mux2input generic map(width) port map( d0 => signimm, d1 => signimmVar, s =>varDecl, y => signimmBin);
      srcamux: mux2input generic map(width) port map( d0 => reg_out_one, d1 => reg_out_two, s => SRCA_Select, y => srca); 
      srcbmux: mux2input generic map(width) port map( d0 => reg_out_three, d1 => signimmBin, s => instr(26), y => srcb);
      mainalu: alu generic map(width) port map(a => srca, b => srcb, f => ALUop, y => aluout, zero => zero);

      ------------------
      -- BRANCH LOGIC --
      ------------------
      pcCTRL <= branch and pcinter;
      branchmux: mux5inputSB generic map (width) port map (d0 => eq, d1 => neq, d2 => blez, d3 => bgtz, d4 => blt, s => branchCTRL, y => pcinter);

      -----------------------
      -- DATA MEMORY / I/O --
      -----------------------
      data_mem_we <= memWE(0);
      vga_mem_we <= memWE(2 downto 1);
      readdata_mux: mux4input generic map(width) port map(d0 => snake_read, d1 => kb_readdata, d2 => mem_readdata, d3 => aluout, s=> readSelect, y => result);
      writedata <= aluout;
      link_mux: mux2input generic map(width) port map(d0 => result, d1 => pcplus4, s => link,  y => link_mux_out);
end;