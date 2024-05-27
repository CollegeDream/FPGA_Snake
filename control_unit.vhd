library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.all;
--used to handle the control signals
entity controller is -- single cycle control decoder
  port( op:             in  STD_LOGIC_VECTOR(4 downto 0); --input for the instruction opcode
        zero:           in  STD_LOGIC; -- input for determining equality and branch logic
        aluout_top_bit: in  STD_LOGIC; --input for determing various branch logic
        blez:           out STD_LOGIC; -- output for the blez signal logic
        bgtz:           out STD_LOGIC; -- output for the bgtz signal logic
        eq:             out STD_LOGIC; -- output for the eq signal logic
        neq:            out STD_LOGIC; -- output for the neq signal logic
        blt:            out STD_LOGIC; -- output for the blt signal logic
        WE:             out STD_LOGIC; -- output for the reg file write enable signal
        SRCA_Select:    out STD_LOGIC; -- output for controlling the srca mux 
        branch:         out STD_LOGIC; -- output that feeds into the branch mux 
        memWE:          out STD_LOGIC_VECTOR(2 downto 0); -- output for controlling which external memory is being written to
        readSelect:     out STD_LOGIC_VECTOR(1 downto 0); -- output for controlling what is being read into the reg file
        ALUop:          out STD_LOGIC_VECTOR(5 downto 0); -- output for determing the correct alu operation to be performed 
        link:           out STD_LOGIC; -- output for controlling the link mux
        branchCTRL:     out STD_LOGIC_VECTOR(2 downto 0); --output for controlling the branch mux
        jump:           out STD_LOGIC; --output for controlling the jump mux
        varDecl:        out STD_LOGIC); --output for declaring a variable 
end;

architecture struct of controller is 
    --component for the instruction decoder 
    --this will determine the values for the signals mentioned above
    component decoder
        port(op:            in STD_LOGIC_VECTOR(4 downto 0);
            WE:            out STD_LOGIC; 
            SRCA_Select:   out STD_LOGIC;
            branch:        out STD_LOGIC;
            jump:          out STD_LOGIC;
            memWE:         out STD_LOGIC_VECTOR(2 downto 0);
            readSelect:    out STD_LOGIC_VECTOR(1 downto 0);
            ALUop:         out STD_LOGIC_VECTOR(5 downto 0);
            link:          out STD_LOGIC;
            branchCTRL:    out STD_LOGIC_VECTOR(2 downto 0);
            varDecl:       out STD_LOGIC);
    end component;
begin 
    --component statement  for the decoder 
    dec: decoder port map(op => op, WE => WE, SRCA_Select => SRCA_Select, branch => branch, jump => jump, memWE => memWE, 
                          readSelect => readSelect, ALUop => ALUop, link => link, branchCTRL => branchCTRL, varDecl => varDecl);
    
    blez <= zero or aluout_top_bit; -- logic for creating our blez output signal
    bgtz <= not (zero or aluout_top_bit); -- bgtz is the inverse of blez
    eq <= zero; --is the alu operation perfomed zero 
    neq <= not zero;
    blt <= aluout_top_bit;
end;