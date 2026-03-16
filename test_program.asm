; Sample 4004 program
NOP
LDM 5       ; Load 5 to ACC
XCH R0      ; R0 = 5
LDM 3       ; ACC = 3
ADM         ; ACC = ACC + RAM
WRM         ; Write to RAM
FIM P0, 0x12 ; Load 12 to R0R1
SRC P0      ; Select RAM address from P0
KBP         ; Keyboard process
