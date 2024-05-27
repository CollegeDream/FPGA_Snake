##################################################################################
# non-vital utility 
# this was used to create vga screens quickly instead of writing 00 to 2000+ lines
###################################################################################
out_file = open("main_screen.dat", "w")

game_over_list = []

game_over_index = 0
for i in range(2399):
    if i % 80 == 0 or i % 80 == 79 or i < 80 or i > 2319:
        out_file.write("2a\n")
    else:
        out_file.write("00\n")
out_file.close()