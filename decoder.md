| **Instruction** | **Op[4:0]** | **WE**       | **SRCA_Select** | **Branch** | **MemWE[1:0]** | **ReadSelect[1:0]** | **ALUOp[4:0]** | **link** | **branchctrl[2:0]** | **JUMP** |
| --------------- | ----------- | ------------ | --------------- | ---------- | -------------- | ------------------- | -------------  | ---------| --------------------|--------- |
| add             | 00000       | 1            | 1               | 0          | 000            |  11                 | 000101         | 0        | XXX                 | 0        |
| sub             | 00001       | 1            | 1               | 0          | 000            |  11                 | 100101         | 0        | XXX                 | 0        |
| multh           | 00010       | 1            | 1               | 0          | 000            |  11                 | 001011         | 0        | XXX                 | 0        |
| multl           | 10011       | 1            | 1               | 0          | 000            |  11                 | 001100         | 0        | XXX                 | 0        |
| slr             | 00011       | 1            | 1               | 0          | 000            |  11                 | 001110         | 0        | XXX                 | 0        |
| xor             | 00100       | 1            | 1               | 0          | 000            |  11                 | 100100         | 0        | XXX                 | 0        |
| and             | 00101       | 1            | 1               | 0          | 000            |  11                 | 000000         | 0        | XXX                 | 0        |
| or              | 00110       | 1            | 1               | 0          | 000            |  11                 | 000001         | 0        | XXX                 | 0        |
| nor             | 00111       | 1            | 1               | 0          | 000            |  11                 | 000011         | 0        | XXX                 | 0        |
| nand            | 01000       | 1            | 1               | 0          | 000            |  11                 | 000010         | 0        | XXX                 | 0        |
| slt             | 01001       | 1            | 1               | 0          | 000            |  11                 | 100110         | 0        | XXX                 | 0        |
| lw              | 01010       | 1            | 1               | 0          | 000            |  01                 | 000101         | 0        | XXX                 | 0        |
| sw              | 01011       | 0            | 0               | 0          | 001            |  XX                 | 000101         | 0        | XXX                 | 0        |
| jump            | 01100       | 0            | 0               | 0          | 000            |  11                 | 100101         | 1        | 011                 | 1        |
| jal             | 01101       | 0            | 0               | 0          | 000            |  11                 | 100101         | 1        | 011                 | 1        |
| blez            | 01110       | 0            | 0               | 1          | 000            |  11                 | 100101         | 0        | 010                 | 0        |
| bgtz            | 01111       | 0            | 0               | 1          | 000            |  11                 | 100101         | 0        | 011                 | 0        |
| beq             | 10000       | 0            | 0               | 1          | 000            |  11                 | 100101         | 0        | 000                 | 0        |
| bne             | 10001       | 0            | 0               | 1          | 000            |  11                 | 100101         | 0        | 001                 | 0        |
| blt             | 10010       | 0            | 0               | 1          | 000            |  11                 | 100101         | 0        | 100                 | 0        |
| sll             | 10100       | 1            | 1               | 0          | 000            |  11                 | 001101         | 0        | XXX                 | 0        |
| wsb             | 10101       | 0            | 0               | 0          | 100            |  11                 | 100101         | 0        | XXX                 | 0        |
| dst             | 10110       | 0            | 0               | 0          | 110            |  11                 | 100101         | 0        | XXX                 | 0        |
| sh              | 10111       | 0            | 0               | 0          | 010            |  11                 | 100101         | 0        | XXX                 | 0        |
| lt              | 11000       | 1            | 1               | 0          | 000            |  00                 | 100101         | 0        | XXX                 | 0        |
| lascii          | 11001       | 1            | 1               | 0          | 000            |  01                 | 000101         | 0        | XXX                 | 0        |
