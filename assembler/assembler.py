import re

class Assembler(object):
    # class to manage assembling duties
    def __init__(self):
        self.write_file = "..\\memfile_test.dat" # name of file to write to
        self.read_file = "test.txt" # name of file to read from
        # opcodes for operations involving three registers
        #   reg1 is being written to, reg2 and reg3 involved in operation
        self.triple_reg_opcodes = {
            "add": "00000",
            "sub": "00001",
            "multh": "00010",
            "multl": "10011",
            "slr": "00011",
            "sll": "10100",
            "xor": "00100",
            "and": "00101",
            "or": "00110",
            "nor": "00111",
            "nand": "01000",
            "slt": "01001",
        }
        # opcodes for operations involving one register
        self.memory_manipulation_opcodes = {
            "lw": "01010", # adding reg2 (0) to reg3(0) in ALU
            "sw": "01011" # adding reg1 to reg3 (0) in ALU
        }
        #opcodes for operations involving jumps

        self.jump_opcodes = {
            "jump": "01100", # adding reg1 (0) to reg 3 (0) in alu
            "jal": "01101" # adding reg 1 (link reg value) to reg 3 (0) in alu
        }
        #opcodes for operations involving branches using a single register
        #   subtracting reg3 (0) from reg1
        self.branch_single_reg_opcodes = {
            "blez": "01110",
            "bgtz": "01111",
        }

        self.single_reg_vga_opcodes ={
            "wsb": "10101",
            "dst": "10110",
            "sh": "10111",
        }
        self.double_reg_vga_opcodes = {
            "lt": "11000",
        }

        self.keyboard_single_reg_opcodes = {
            "lascii":"11001",
        }
        #opcodes for operations involving branches using 2 registers
        #   subtracting reg3 (second argument) from reg1
        self.branch_double_reg_opcodes = {
            "beq": "10000",
            "bne": "10001",
            "blt": "10010"
        }
        self.file_contents = [] # list to hold contents of read file
        self.data_seg_contents = [] # list to hold contents of the data segment
        self.code_seg_contents = [] # list to hold contents of the code segment
        self.write_list = [] # list to hold hex codes to be written to the output file
        self.target_lines = {}
        self.variable_lines = {}

    # clear the output file
    def clear_output(self):
        write_f = open(self.write_file, "w")
        write_f.close()

    # retrieve contents of the read file into file_contents
    def get_file_contents(self):
        read_f = open(self.read_file, "r")
        self.file_contents = read_f.read()
        read_f.close()

    # parse through all file contents
    def parse(self):
        # make file_contents into listing with each line the next element in the list
        file_content_list = self.file_contents.split("\n")
        # remove empty lines
        while("" in file_content_list):
            file_content_list.remove("")
        found_data_seg = False # to track if the data segment keyword (.data) has been found in file contents
        found_code_seg = False # to track if the code segment keyword (.code) has been found in file contents
        r_comment = re.compile('^#') # regex for commented lines
        in_data_seg = True # to track if we are currently looking at the data segment
        # iterate through all of file contents and sort each line into data or code segment lines
        cur_line_code_seg = 0
        r_target = re.compile('(@[a-zA-Z]+)$')
        for content in file_content_list:
            if r_comment.match(content) is None:
                if content.strip() == ".data":
                    # if we have already found the data segment keyword, then there are two data segments (not allowed)
                    if(found_data_seg):
                        print("Error: More than one data segment found")
                        return
                    found_data_seg = True # mark that data segment has been found
                elif content.strip() == ".code":
                    # if we have already found the code segment keyword, then there are two code segments (not allowed)
                    if(found_code_seg):
                        print("Error: More than one code segment found")
                        return
                    found_code_seg = True # mark that code segment has been found
                    in_data_seg = False # mark that we are no longer in the data segment
                else:
                    if(not found_data_seg):
                        print("Error: Data segment not at top of file")
                        return
                    # add each line to either the data segment contents or code segment contents based on value of in_data_seg
                    
                    if(in_data_seg):
                        self.data_seg_contents.append(content)
                    else:
                        if(r_target.match(content)):
                            label_name = content.replace('@', '')
                            self.target_lines[label_name] = cur_line_code_seg
                            # print(self.target_lines[label_name])
                        else:
                            self.code_seg_contents.append(content)
                            cur_line_code_seg += 1
        # case where there is no code segment
        if (in_data_seg):
            print("Error: No .code segment found")
            return
        if self.parse_data_segment() == -1:
            return -1 # report error
        if self.parse_code_segment() == -1:
            return -1 # report error
    
    # get hex form of variable references
    # mem_loc -> location in memory to store the variable value 
    # value_str -> the value associated with the variable upon declaration
    def get_hex_var(self, mem_loc, value_str):
        opcode = "1" * 6 # opcode for declaring variables in memory is 111111 
        reg_bits = "0" * 12 # registers not used, all register references are 0000
        num_mem_bits = 6 # number of bits to associate with memory location of variable
        immediate_value = f'{mem_loc:0{num_mem_bits}b}' + value_str # construct immediate binary value with memory location for six bits followed by value binary
        machine_code_binary = opcode + reg_bits + immediate_value # construct full machine code binary
        machine_code_hex = self.convert_binary_to_hex(machine_code_binary) # convert to hex
        return machine_code_hex

    # parse through data segment list collected from initial analysis of input file
    def parse_data_segment(self):
        r_target = re.compile(r'[a-zA-Z0-9]*[ ]*\.dword[ ]*[0-9]{1,5}([ #].)*') #match with [var name] .word [value]
        num_bits_in_dword = 32
        cur_mem_index = 0 # to track where next variable should be added in memory
        # iterate through all data segment contents and output correct variable initializations
        variable_added_instructions = []
        for content in self.data_seg_contents:
            if r_target.match(content) is None:
                print("Error: invalid variable declaration.")
                return -1
            content_list_no_space = content.split() #splitting on every space
            variable_name = content_list_no_space[0] # grab variable name to store in dictionary
            variable_size = content_list_no_space[1] # grab variable size (how many bytes should be created in memory)
            variable_value = int(content_list_no_space[2]) # grab value associated with variable
            self.variable_lines[variable_name] = cur_mem_index
            if variable_size == ".dword":
                if variable_value < 0 or variable_value > 4294967295: # bigger than 32 bit value
                    print("Error: Value for variable '" + variable_name + "' not in range 0-4294967295.")
                    return -1
                binary_value = f'{variable_value:0{num_bits_in_dword}b}' # construct binary for variable's value
                bit_group_one = binary_value[0:14]
                bit_group_two = binary_value[14:28]
                bit_group_three = binary_value[28:32]

                bit_group_one_int = int(bit_group_one, 2)
                bit_group_two_int = int(bit_group_two, 2)
                bit_group_three_int = int(bit_group_three, 2)
                variable_added_instructions.append("add $g0, $z0, " + str(bit_group_one_int))
                variable_added_instructions.append("sll $g0, $g0, 14") # shift left 14 to make room for next bit group
                variable_added_instructions.append("add $g0, $g0, " + str(bit_group_two_int))
                variable_added_instructions.append("sll $g0, $g0, 4") # shift left 4 to make room for next bit group
                variable_added_instructions.append("add $g0, $g0, " + str(bit_group_three_int))
                variable_added_instructions.append("sw $g0, " + variable_name)
                variable_added_instructions.append("add $g0, $z0, $z0") # clear out $g0

                # variable_value_bin = f'{variable_value:0{num_bits_in_word}b}' # construct binary for variable's value
                # # store word into most significant and least significant bytes
                # lsb = variable_value_bin[8:16]
                # msb = variable_value_bin[0:8]
                # lsb_machine_code = self.get_hex_var(cur_mem_index, lsb)
                # cur_mem_index += 1 # increment memory to next byte
                # msb_machine_code = self.get_hex_var(cur_mem_index, msb)
                # cur_mem_index += 1 # increment memory to next byte
                # # append hex codes to writing lsit
                # self.write_list.append(lsb_machine_code.lower() + '\n')
                # self.write_list.append(msb_machine_code.lower() + '\n')
        num_instructions_added = len(variable_added_instructions)
        for name in self.target_lines:
            self.target_lines[name] = self.target_lines[name] + num_instructions_added
        variable_added_instructions.extend(self.code_seg_contents)
        self.code_seg_contents = variable_added_instructions.copy()
        print(self.code_seg_contents)
        return 0
    
    # construct patterns for various instruction types
    # num_arguments - # of arguments in instruction
    # jump_or_branch - is this a jump/branch instruction?
    # memory_manipulation - does this manipulate memory? (important for tracking variable names)
    def get_pattern(self, num_arguments, jump_or_branch, memory_manipulation):
        # num_arguments must be between 2 and 4 (exception: jump commands can have only 2 arguments), also cannot be both jump/branch and memory manipulation
        if num_arguments < 2 or num_arguments > 4 or (jump_or_branch and memory_manipulation):
            print("Error - Illegal call to get_hex")
            return -1

        # setting up parts of regex patterns
        instruction_name_ptrn = r".+[ ]+"
        register_only_ptrn = r"\$[a-zA-z]+[0-9]+,[ ]*"
        register_or_imm_ptrn = r"(\$[a-zA-Z])*[0-9]+"
        target_and_var_ptrn = r"[a-zA-Z]+"
        comment_ptrn = r"([ #].)*"
        pattern = r""

        # construct regex pattern from parts based on inputs
        pattern += instruction_name_ptrn
        pattern += register_only_ptrn * (num_arguments - 2) 
        # if jump or branch, last argument must be a target, otherwise last argument is a register or immediate
        if jump_or_branch or memory_manipulation:
            pattern += target_and_var_ptrn
        else:
            pattern += register_or_imm_ptrn
        pattern += comment_ptrn # all instructions can end with a comment
        # check if line matches the reg_ex pattern
        return pattern
    
    #converts binary value in binary_str to hex
    def convert_binary_to_hex(self, binary_str):
        hex_no_lz = hex(int(binary_str, base= 2)) # construct hex machine code (with no leading zeros)
        hex_value = f'{int(hex_no_lz, base= 16):08X}' # format hex to include leading zeros where needed
        return hex_value
    
    # retrieve binary for each register referenced 
    def get_reg_code(self, reg_letter, reg_value, item_no_comma_list, idx):
        # constant Zero register case (z register)
        if reg_letter == "z": 
            try:
                reg_code = int(reg_value)
            except Exception as e:
                print("Error: " + str(reg_value) + " in " + str(item_no_comma_list[idx]) + " is not a numerical value.")
                return -1
            if reg_code != 0: # should only ever occupy register 0 
                print("Error: " + str(reg_code) + " is not in valid register value range for register z")
                return -1
            if idx == 1:
                print("Error: Cannot write to register $z0.")
                return -1
        # case for general purpose registers (g registers)
        elif reg_letter == "g": 
            try:
                reg_code = int(reg_value) + 1
            except Exception as e:
                print("Error: " + str(reg_value) + " in " + str(item_no_comma_list[idx]) + " is not a numerical value.")
                return -1
            # should only ever occupy registers 1 through 6
            if reg_code < 1 or reg_code > 7: 
                print("Error: " + str(reg_code) + " is not in valid register range for register g")
                return -1  
        # case for stack pointer register
        elif reg_letter == 's':
            try:
                reg_code = int(reg_value) + 8
            except Exception as e:
                print("Error: " + str(reg_value) + " in " + str(item_no_comma_list[idx]) + " is not a numerical value.")
                return -1
            # should only ever occupy register 0
            if reg_code != 8:
                print("Error: " + str(reg_code) + " is not in valid register value range for register s")
                return -1
        # case for link register (l register)
        elif reg_letter == 'l':
            try: 
                reg_code = int(reg_value) + 9
            except Exception as e:
                print("Error: " + str(reg_value) + " in " + str(item_no_comma_list[idx]) + " is not a numerical value.")
                return -1
            # should only ever occupy register 9
            if reg_code != 9:
                print("Error: " + str(reg_code) + " is not in valid register value range for register l")
                return -1
            # if idx == 1:
            #     print("Error: Cannot write to register $l0.")
            #     return -1
        # case for procedure register (p register)
        elif reg_letter == "p":
            try:
                reg_code = int(reg_value) + 10
            except Exception as e:
                print("Error: " + str(reg_value) + " in " + str(item_no_comma_list[idx]) + " is not a numerical value.")
                return -1
            # should only ever occupy register 10
            if reg_code != 10:
                print("Error: " + str(reg_code) + " is not in valid register value range for register p")
                return -1
        # case for pixel update registers (p registers)
        elif reg_letter == 'u':
            try:
                reg_code =int(reg_value) + 11
            except Exception as e:
                print("Error: " + str(reg_value) + " in " + str(item_no_comma_list[idx]) + " is not a numerical value.")
                return -1
            # should only ever occupy registers 11 through 15
            if reg_code < 11 or reg_code > 15:
                print("Error: " + str(reg_code) + " is not in valid register value range for register u")
                return -1
        else:
            print("Error: " + item_no_comma_list[idx] + " is not a valid register.")
            return -1
        return reg_code

    # get string representing the binary value associated with registers that are being used
    # item_no_comma_list - list of content (instruction parts) without commas
    # num_arguments - # of arguments in the instruction
    # jump_or_branch - is this a jump/branch instruction?
    # memory_manipulation - does this manipulate memory? (important for tracking variable names)
    def get_register_str(self, item_no_comma_list, num_arguments, jump_or_branch, memory_manipulation):
        register_str = "" # to construct the register binary string
        immediate_str = "" # to construct the immediate value string
        immediate_bit = 0 # will be appended to opcode to signify immediate or non immediate instruction type
        reg_bits_to_set = 12 # to track the number of register bits that still need to be set 
        immediate_bits_to_set = 14 # to track the number of immediate bits that need to be set

        for i in range(num_arguments - 1):
            idx = i + 1
            if idx != num_arguments - 1 or (not jump_or_branch and item_no_comma_list[idx][0] == '$'): # not looking at last argument or last argument isn't immediate
                reg_letter = item_no_comma_list[idx][1].lower() # retrieve letter for the register
                reg_value = item_no_comma_list[idx][2].lower() # retrieve value for the register
                reg_code = self.get_reg_code(reg_letter, reg_value, item_no_comma_list, idx)
                if reg_code == -1:
                    return -1
                
                reg_code_binary = f'{reg_code:04b}'
                register_str += reg_code_binary # add the register binary to the register string
                reg_bits_to_set -= 4     

                if idx == num_arguments - 1:
                    register_str += f'{0:0{reg_bits_to_set + immediate_bits_to_set}b}' # if last argument for instruction is a register, fill the rest of the instruction with zeros

            else: # we are looking at last element which is an immediate value
                # if(num_arguments == 5):
                #     print(reg_bits_to_set)
                #     print(register_str)
                if reg_bits_to_set != 0:
                    register_str += f'{0:0{reg_bits_to_set}}' # fill remaining register bits with zeros
                # if(num_arguments == 5):
                #     print(register_str)
                if not (jump_or_branch or memory_manipulation):
                    immediate_bit = 1 # argument must be an immediate value
                if jump_or_branch:
                    target = item_no_comma_list[idx] # fetch target
                    # get target address
                    try:
                        target_address = self.target_lines[target] # will throw exception if target doesn't exist
                    except Exception as e:
                        print("Error: '" + target + "' is not a valid target.")
                        return -1
                    immediate_str += f'{target_address:0{immediate_bits_to_set}b}' # buffer the immediate value with bits_to_set zeros
                elif memory_manipulation:
                    variable_name = item_no_comma_list[idx]
                    # get variable memory address
                    try:
                        memory_address = self.variable_lines[variable_name]
                    except Exception as e:
                        print("Error: '" + variable_name + "' is not a valid variable name.")
                        return -1
                    immediate_str = f'{memory_address:0{immediate_bits_to_set}b}'
                else:
                    # get binary value for the immediate value
                    immediate_value = int(item_no_comma_list[idx])
                    immediate_str += f'{immediate_value:0{immediate_bits_to_set}b}'
                register_str += immediate_str # add the immediate value to the register string
        final_register_str = str(immediate_bit) + register_str
        return final_register_str

    # retrieve hex code based on input values
    #   content - string content of line of file
    #   opcode - 5 digit binary opcode corresponding to instruction
    #   num_arguments - integer number of arguments (including instruction name)
    #   jump_or_branch - true if instruction is a jump or a branch, false otherwise
    def get_hex(self, content, opcode, num_arguments, jump_or_branch, memory_manipulation, operation_name): #need to be functionalized 
        pattern = self.get_pattern(num_arguments, jump_or_branch, memory_manipulation)    
        reg_ex = re.compile(pattern)
        if reg_ex.match(content) is None:
            print("Error: Syntax Error in line '" + content + "'.")
            return -1

        content_list_no_space = content.split() #splitting on every space
        item_no_comma_list = []
        for item in content_list_no_space:
            item_no_comma_list.append(item.replace(",","")) #removing all commas

        # edge cases
        if operation_name == "jal":
            item_no_comma_list.insert(1, "$l0")
            num_arguments += 1
        elif operation_name in self.branch_double_reg_opcodes:
            item_no_comma_list.insert(2, "$z0")
            num_arguments += 1

        register_str = self.get_register_str(item_no_comma_list, num_arguments, jump_or_branch, memory_manipulation)
        if register_str == -1:
            return -1
        
        machine_code_binary = opcode + register_str # construct final binary machine code
        machine_code_hex = self.convert_binary_to_hex(machine_code_binary)
        return machine_code_hex

    # parse the code segment of the assembly file
    def parse_code_segment(self):
        first_iter = True # special behavior occurs after first iteration, this is used to track the first iteration
        # iterate through the contents of the code segment and retrieve instruction hex codes
        for content in self.code_seg_contents:
            # need to output every loop after the first iteration
            if not first_iter:
                self.write_list[-1] += "\n"
            content_list_no_space = content.split() # splitting on every space
            operation = content_list_no_space[0].lower() # grab the operation keyword
            # check the type of opcode and call the respective function to get the hex code
            if operation in self.memory_manipulation_opcodes:
                machine_code_hex = self.get_hex(content, self.memory_manipulation_opcodes[operation], 3, False, True, operation)
            elif operation in self.triple_reg_opcodes:
                machine_code_hex = self.get_hex(content, self.triple_reg_opcodes[operation], 4, False, False, operation)
            elif operation in self.branch_double_reg_opcodes:
                machine_code_hex = self.get_hex(content, self.branch_double_reg_opcodes[operation], 4, True, False, operation)
            elif operation in self.branch_single_reg_opcodes:
                machine_code_hex = self.get_hex(content, self.branch_single_reg_opcodes[operation], 3, True, False, operation)
            elif operation in self.jump_opcodes:
                machine_code_hex = self.get_hex(content, self.jump_opcodes[operation], 2, True, False, operation)
            elif operation in self.single_reg_vga_opcodes:
                machine_code_hex = self.get_hex(content, self.single_reg_vga_opcodes[operation], 2, False, False, operation)
            elif operation in self.double_reg_vga_opcodes:
                machine_code_hex = self.get_hex(content, self.double_reg_vga_opcodes[operation], 3, False, False, operation)
            elif operation in self.keyboard_single_reg_opcodes:
                machine_code_hex = self.get_hex(content, self.keyboard_single_reg_opcodes[operation], 2, False, False, operation)
            else:
                # case for unrecognized operation
                print("Error: " + operation + " not recognized as a valid operation")
                return -1
            # case for failure to convert instruction to hex
            if machine_code_hex == -1:
                return -1
            self.write_list.append(machine_code_hex.lower()) # append the machine code to the list to write to file
            first_iter = False
        return 0

    # write contents of write list to output file
    def write_to_file(self):
        write_f = open(self.write_file, "a")
        for line in self.write_list:
            write_f.write(line)
        write_f.close()

if __name__ == '__main__':
    compiler = Assembler() # create an assembler object
    compiler.get_file_contents() # retrieve contents of read file
    if compiler.parse() != -1: # parse the contents of the read file
        compiler.clear_output() # clear out the output file
        compiler.write_to_file() # write machine code to output file