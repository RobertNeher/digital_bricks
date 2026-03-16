import json
import uuid

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

# Inputs (Top to bottom: 8, 4, 2, 1)
weights = ["8", "4", "2", "1"]
inputs = []
nots = []
for i in range(4):
    l = weights[i]
    inp = gen_comp(f"IN_{l}", 12, 100, 200 + i*200, labels=l, input_count=0, output_count=1)
    inv = gen_comp(f"NOT_{l}", 6, 250, 200 + i*200, input_count=1, output_count=1)
    components.extend([inp, inv])
    inputs.append(inp)
    nots.append(inv)
    add_conn(inp, 0, inv, 0)

# Minterms
minterms = []
for m in range(16):
    m_gate = gen_comp(f"M_{m}", 0, 450, 50 + m*75, input_count=4, output_count=1)
    components.append(m_gate)
    minterms.append(m_gate)
    
    # bit 3 (wt 8) is index 0
    for bit in range(4):
        val = (m >> (3 - bit)) & 1
        src = inputs[bit] if val else nots[bit]
        add_conn(src, 0, m_gate, bit)

# Segment ORs and Outputs
hex_patterns = [
    (1,1,1,1,1,1,0), # 0
    (0,1,1,0,0,0,0), # 1
    (1,1,0,1,1,0,1), # 2
    (1,1,1,1,0,0,1), # 3
    (0,1,1,0,0,1,1), # 4
    (1,0,1,1,0,1,1), # 5
    (1,0,1,1,1,1,1), # 6
    (1,1,1,0,0,0,0), # 7
    (1,1,1,1,1,1,1), # 8
    (1,1,1,1,0,1,1), # 9
    (1,1,1,0,1,1,1), # A
    (0,0,1,1,1,1,1), # b
    (1,0,0,1,1,1,0), # C
    (0,1,1,1,1,0,1), # d
    (1,0,0,1,1,1,1), # E
    (1,0,0,0,1,1,1)  # F
]

seg_names = ["A", "B", "C", "D", "E", "F", "G"]
for s in range(7):
    # active minterms
    active_m = [m for m in range(16) if hex_patterns[m][s] == 1]
    
    c_or = gen_comp(f"OR_{seg_names[s]}", 2, 700, 150 + s*150, input_count=len(active_m), output_count=1)
    c_out = gen_comp(f"OUT_{seg_names[s]}", 13, 850, 150 + s*150, labels=seg_names[s], input_count=1, output_count=0)
    components.extend([c_or, c_out])
    
    for i, m in enumerate(active_m):
        add_conn(minterms[m], 0, c_or, i)
        
    add_conn(c_or, 0, c_out, 0)
    
output_data = {
    "components": components,
    "connections": connections
}

# Output to target path
with open("assets/4 bit to 7 segment decoder.json", "w", encoding="utf-8") as f:
    json.dump(output_data, f, indent=2)

print("Generated assets/4 bit to 7 segment decoder.json successfully")
