library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity decoder is
    port(   op:            in STD_LOGIC_VECTOR(4 downto 0);
            WE:            out STD_LOGIC;
            SRCA_Select:   out STD_LOGIC;
            branch:        out STD_LOGIC;
            jump:           out STD_LOGIC;
            memWE:         out STD_LOGIC_VECTOR(2 downto 0);
            readSelect:    out STD_LOGIC_VECTOR(1 downto 0);
            ALUop:         out STD_LOGIC_VECTOR(5 downto 0);
            link:          out STD_LOGIC;
            branchCTRL:    out STD_LOGIC_VECTOR(2 downto 0);
            varDecl:       out STD_LOGIC);
end;

architecture behave of decoder is
    signal controls: STD_LOGIC_VECTOR(19 downto 0); --change vector amount
begin 
    process(op) begin
        case op is 
            when "00000" => controls <= "00XXX000010111000011"; -- add
            when "00001" => controls <= "00XXX010010111000011"; -- sub 
            when "00010" => controls <= "00XXX000101111000011"; -- multh
            when "10011" => controls <= "00XXX000110011000011"; -- multl
            when "00011" => controls <= "00XXX000111011000011"; -- slr
            when "00100" => controls <= "00XXX010010011000011"; -- xor
            when "00101" => controls <= "00XXX000000011000011"; -- and
            when "00110" => controls <= "00XXX000000111000011"; -- or
            when "00111" => controls <= "00XXX000001111000011"; -- nor
            when "01000" => controls <= "00XXX000001011000011"; -- nand
            when "01001" => controls <= "00XXX010011011000011"; -- slt
            when "01010" => controls <= "00XXX000010110000011"; -- lw
            when "01011" => controls <= "00XXX0000101XX001000"; -- sw
            when "01100" => controls <= "01000010010111000100"; -- jump
            when "01101" => controls <= "01000110010111000101"; -- jal
            when "01110" => controls <= "00010010010111000100"; -- blez
            when "01111" => controls <= "00011010010111000100"; -- bgtz
            when "10000" => controls <= "00000010010111000100"; -- beq 
            when "10001" => controls <= "00001010010111000100"; -- bne
            when "10010" => controls <= "00100010010111000100"; -- blt
            when "10100" => controls <= "00XXX000110111000011"; -- sll
            when "10101" => controls <= "00XXX010010111100000"; -- wsb
            when "10110" => controls <= "00XXX010010111110000"; -- dst
            when "10111" => controls <= "00XXX010010111010000"; -- sh
            when "11000" => controls <= "00XXX010010100000011"; -- lt
            when "11001" => controls <= "00XXX000010101000011"; -- lascii
            when "11111" => controls <= "10XXX0000101XX001000"; -- variable declarations
            when others  => controls <= "--------------------"; -- illegal op 
        end case;
    end process;
    
    varDecl     <= controls(19);  -- used to declare variables
    jump        <= controls(18); -- set high if an instrcution is branching
    branchCTRL  <= controls(17 downto 15); -- branch mux select signal
    link        <= controls(14); -- set high if an instruction is using a link
    ALUop       <= controls(13 downto 8); -- all op code
    readSelect  <= controls(7 downto 6); -- read select from all memories
    memWE       <= controls(5 downto 3); -- external memory write enable
    branch      <= controls(2); -- set high if an instruction branches
    SRCA_Select <= controls(1); --srca mux select
    WE          <= controls(0); --register file write enable
end;

