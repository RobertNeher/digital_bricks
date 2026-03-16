import argparse
import sys
import re

INSTRUCTIONS = {
    "NOP": (0, lambda: 0x00),
    "FIM": (2, lambda p, d: [(0x20 | (int(p[1:]) << 1)), int(d, 0)]),
    "SRC": (1, lambda p: 0x21 | (int(p[1:]) << 1)),
    "LD":  (1, lambda r: 0xA0 | int(r[1:])),
    "XCH": (1, lambda r: 0xB0 | int(r[1:])),
    "LDM": (1, lambda d: 0xD0 | (int(d, 0) & 0xF)),
    "WRM": (0, lambda: 0xE0), "WMP": (0, lambda: 0xE1), "WRR": (0, lambda: 0xE2), "WPM": (0, lambda: 0xE3),
    "WR0": (0, lambda: 0xE4), "WR1": (0, lambda: 0xE5), "WR2": (0, lambda: 0xE6), "WR3": (0, lambda: 0xE7),
    "SBM": (0, lambda: 0xE8), "RDM": (0, lambda: 0xE9), "RDR": (0, lambda: 0xEA), "ADM": (0, lambda: 0xEB),
    "RD0": (0, lambda: 0xEC), "RD1": (0, lambda: 0xED), "RD2": (0, lambda: 0xEE), "RD3": (0, lambda: 0xEF),
    "KBP": (0, lambda: 0xFC),
}

def assemble(source_path, output_path):
    opcodes = []
    with open(source_path, 'r') as f:
        for line_num, line in enumerate(f, 1):
            line = line.split(';')[0].strip()
            if not line: continue
            parts = re.split(r'[,\s]+', line)
            mnemonic = parts[0].upper(); args = parts[1:]
            if mnemonic not in INSTRUCTIONS: print(f"Error {line_num}: {mnemonic}"); sys.exit(1)
            num_args, func = INSTRUCTIONS[mnemonic]
            if len(args) != num_args: print(f"Error {line_num}"); sys.exit(1)
            res = func(*args)
            opcodes.extend(res if isinstance(res, list) else [res])
    with open(output_path, 'w') as f:
        for op in opcodes: f.write(f"{op:02X}\n")
    print(f"Assembled {source_path} -> {output_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(); parser.add_argument("source"); parser.add_argument("-o", "--output", default="output.hex")
    args = parser.parse_args(); assemble(args.source, args.output)
