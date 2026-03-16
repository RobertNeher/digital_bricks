import json
import uuid
import os

def gen_comp(name, c_type, x, y, labels=None, input_count=0, output_count=0):
    cid = str(uuid.uuid4())
    comp = {
        "id": cid,
        "name": name,
        "type": c_type,
        "position_dx": float(x),
        "position_dy": float(y),
        "inputs": [],
        "outputs": []
    }
    
    for i in range(input_count):
        comp["inputs"].append({
            "id": f"{cid}-in-{i}",
            "componentId": cid,
            "type": 0,
            "value": False
        })
        
    for i in range(output_count):
        comp["outputs"].append({
            "id": f"{cid}-out-{i}",
            "componentId": cid,
            "type": 1,
            "value": False
        })
        
    if input_count >= 2 and c_type in [0, 1, 2, 3, 4, 5]: # Gates
        comp["inputCount"] = input_count
        
    if labels:
        comp["label"] = labels
        
    return comp

components = []
connections = []

def add_conn(src_comp, src_out_idx, tgt_comp, tgt_in_idx):
    connections.append({
        "id": str(uuid.uuid4()),
        "sourcePinId": src_comp["outputs"][src_out_idx]["id"],
        "targetPinId": tgt_comp["inputs"][tgt_in_idx]["id"]
    })

# Define Instructions
# Format: (Mnemonic, Pattern, Description)
# Pattern: 8-char string of '0', '1', or 'X' (don't care)
instructions = [
    ("NOP", "00000000", "No operation"),
    ("FIM", "0010XXX0", "Fetch immediate (RRR0, bit 0 is 0)"),
    ("SRC", "0010XXX1", "Send register address (RRR1, bit 0 is 1)"),
    ("LD",  "1010XXXX", "Load to accumulator"),
    ("XCH", "1011XXXX", "Exchange index and acc"),
    ("LDM", "1101XXXX", "Load immediate to acc"),
    ("WRM", "11100000", "Write RAM character"),
    ("WMP", "11100001", "Write RAM output port"),
    ("WRR", "11100010", "Write ROM port"),
    ("WPM", "11100011", "Write program memory"),
    ("WR0", "11100100", "Write RAM status 0"),
    ("WR1", "11100101", "Write RAM status 1"),
    ("WR2", "11100110", "Write RAM status 2"),
    ("WR3", "11100111", "Write RAM status 3"),
    ("SBM", "11101000", "Subtract RAM from acc"),
    ("RDM", "11101001", "Read RAM character"),
    ("RDR", "11101010", "Read ROM input port"),
    ("ADM", "11101011", "Add RAM to acc"),
    ("RD0", "11101100", "Read RAM status 0"),
    ("RD1", "11101101", "Read RAM status 1"),
    ("RD2", "11101110", "Read RAM status 2"),
    ("RD3", "11101111", "Read RAM status 3"),
    ("KBP", "11111100", "Keyboard process"),
]

# Create Inputs (8 bits: I7 to I0)
inputs = []
nots = []
for i in range(8):
    bit_idx = 7 - i
    inp = gen_comp(f"I{bit_idx}", 12, 100, 100 + i*150, labels=f"I{bit_idx}", input_count=0, output_count=1)
    inv = gen_comp(f"NOT_I{bit_idx}", 6, 250, 100 + i*150, input_count=1, output_count=1)
    components.extend([inp, inv])
    inputs.append(inp)
    nots.append(inv)
    add_conn(inp, 0, inv, 0)

# Decoding Logic
# For FIM/SRC: Mask bits 1-3 (RRR)
# For FIM: Pattern 0010 XXX0
# For SRC: Pattern 0010 XXX1

def get_masked_pattern(pattern):
    # Returns list of (bit_idx, value) where value is 0 or 1
    bits = []
    for i, char in enumerate(pattern):
        if char == '0' or char == '1':
            bits.append((i, int(char)))
    return bits

for idx, (name, pattern, desc) in enumerate(instructions):
    active_bits = get_masked_pattern(pattern)
    
    # Create Decoder AND gate
    dec_gate = gen_comp(f"DEC_{name}", 0, 500, 50 + idx*120, input_count=len(active_bits), output_count=1)
    out_comp = gen_comp(f"OUT_{name}", 13, 750, 50 + idx*120, labels=name, input_count=1, output_count=0)
    
    components.extend([dec_gate, out_comp])
    
    for i, (bit_idx, val) in enumerate(active_bits):
        src = inputs[bit_idx] if val == 1 else nots[bit_idx]
        add_conn(src, 0, dec_gate, i)
        
    add_conn(dec_gate, 0, out_comp, 0)

output_data = {
    "components": components,
    "connections": connections
}

# Ensure directory exists
output_path = os.path.join("assets", "i4004_command_decoder.json")

with open(output_path, "w", encoding="utf-8") as f:
    json.dump(output_data, f, indent=2)

print(f"Generated {output_path} successfully with {len(instructions)} commands.")
