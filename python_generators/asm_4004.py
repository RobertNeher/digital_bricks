import argparse
import sys
import re

# Intel 4004 Opcode Mapping for supported subset
# Patterns use format strings to inject register/data bits
INSTRUCTIONS = {
    "NOP": (0, lambda: 0x00),
    "FIM": (2, lambda p, d: [(0x20 | (int(p[1:]) << 1)), int(d, 0)]),
    "SRC": (1, lambda p: 0x21 | (int(p[1:]) << 1)),
    "LD":  (1, lambda r: 0xA0 | int(r[1:])),
    "XCH": (1, lambda r: 0xB0 | int(r[1:])),
    "LDM": (1, lambda d: 0xD0 | (int(d, 0) & 0xF)),
    "WRM": (0, lambda: 0xE0),
    "WMP": (0, lambda: 0xE1),
    "WRR": (0, lambda: 0xE2),
    "WPM": (0, lambda: 0xE3),
    "WR0": (0, lambda: 0xE4),
    "WR1": (0, lambda: 0xE5),
    "WR2": (0, lambda: 0xE6),
    "WR3": (0, lambda: 0xE7),
    "SBM": (0, lambda: 0xE8),
    "RDM": (0, lambda: 0xE9),
    "RDR": (0, lambda: 0xEA),
    "ADM": (0, lambda: 0xEB),
    "RD0": (0, lambda: 0xEC),
    "RD1": (0, lambda: 0xED),
    "RD2": (0, lambda: 0xEE),
    "RD3": (0, lambda: 0xEF),
    "KBP": (0, lambda: 0xFC),
}

def assemble(source_path, output_path):
    opcodes = []
    
    with open(source_path, 'r') as f:
        for line_num, line in enumerate(f, 1):
            line = line.split(';')[0].strip() # Remove comments
            if not line:
                continue
                
            parts = re.split(r'[,\s]+', line)
            mnemonic = parts[0].upper()
            args = parts[1:]
            
            if mnemonic not in INSTRUCTIONS:
                print(f"Error at line {line_num}: Unknown mnemonic '{mnemonic}'")
                sys.exit(1)
                
            expected_args, func = INSTRUCTIONS[mnemonic]
            if len(args) != expected_args:
                print(f"Error at line {line_num}: '{mnemonic}' expects {expected_args} arguments, got {len(args)}")
                sys.exit(1)
                
            try:
                res = func(*args)
                if isinstance(res, list):
                    opcodes.extend(res)
                else:
                    opcodes.append(res)
            except Exception as e:
                print(f"Error at line {line_num} processing '{mnemonic}': {e}")
                sys.exit(1)
                
    with open(output_path, 'w') as f:
        for op in opcodes:
            f.write(f"{op:02X}\n")
            
    print(f"Assembled {source_path} -> {output_path} ({len(opcodes)} bytes)")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Intel 4004 Assembler for digital_bricks")
    parser.add_argument("source", help="Path to .asm file")
    parser.add_argument("-o", "--output", default="output.hex", help="Path to output .hex file")
    
    args = parser.parse_args()
    assemble(args.source, args.output)
