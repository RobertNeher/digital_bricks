import json
import uuid
<<<<<<< HEAD
import os
=======
>>>>>>> ram-concept
import argparse

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
<<<<<<< HEAD
    
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

def add_conn(connections, src_comp, src_out_idx, tgt_comp, tgt_in_idx):
    connections.append({
        "id": str(uuid.uuid4()),
        "sourcePinId": src_comp["outputs"][src_out_idx]["id"],
        "targetPinId": tgt_comp["inputs"][tgt_in_idx]["id"]
    })

def generate_rom(data, addr_bits, word_bits, output_name):
    components = []
    connections = []
    
    # 1. Inputs (Address bits A[n-1] to A0)
    addr_inputs = []
    addr_nots = []
    for i in range(addr_bits):
        bit_idx = addr_bits - 1 - i
        inp = gen_comp(f"ADDR_{bit_idx}", 12, 100, 100 + i*150, labels=f"A{bit_idx}", input_count=0, output_count=1)
        inv = gen_comp(f"NOT_A{bit_idx}", 6, 250, 100 + i*150, input_count=1, output_count=1)
        components.extend([inp, inv])
        addr_inputs.append(inp)
        addr_nots.append(inv)
        add_conn(connections, inp, 0, inv, 0)

    # 2. Address Decoder (Minterms)
    # Each word in memory gets a row (AND gate)
=======
    for i in range(input_count):
        comp["inputs"].append({"id": f"{cid}-in-{i}", "componentId": cid, "type": 0, "value": False})
    for i in range(output_count):
        comp["outputs"].append({"id": f"{cid}-out-{i}", "componentId": cid, "type": 1, "value": False})
    if input_count >= 2 and c_type in [0, 1, 2, 3, 4, 5]: comp["inputCount"] = input_count
    if labels: comp["label"] = labels
    return comp

def add_conn(connections, src_comp, src_out_idx, tgt_comp, tgt_in_idx):
    connections.append({"id": str(uuid.uuid4()), "sourcePinId": src_comp["outputs"][src_out_idx]["id"], "targetPinId": tgt_comp["inputs"][tgt_in_idx]["id"]})

def generate_rom(data, addr_bits, word_bits, output_name):
    components, connections = [], []
    addr_inputs, addr_nots = [], []
    for i in range(addr_bits):
        bit_idx = addr_bits - 1 - i
        inp = gen_comp(f"ADDR_{bit_idx}", 12, 100, 100 + i*150, labels=f"A{bit_idx}", output_count=1)
        inv = gen_comp(f"NOT_A{bit_idx}", 6, 250, 100 + i*150, input_count=1, output_count=1)
        components.extend([inp, inv]); addr_inputs.append(inp); addr_nots.append(inv)
        add_conn(connections, inp, 0, inv, 0)
>>>>>>> ram-concept
    num_words = 2**addr_bits
    word_select_lines = []
    for m in range(num_words):
        m_gate = gen_comp(f"WORD_{m}", 0, 500, 50 + m*80, input_count=addr_bits, output_count=1)
<<<<<<< HEAD
        components.append(m_gate)
        word_select_lines.append(m_gate)
        
        for bit in range(addr_bits):
            # bit 0 is MSB in our loop above (index 0)
            val = (m >> (addr_bits - 1 - bit)) & 1
            src = addr_inputs[bit] if val else addr_nots[bit]
            add_conn(connections, src, 0, m_gate, bit)

    # 3. Data Matrix (OR gates for each output bit)
    data_outputs = []
    for b in range(word_bits):
        bit_idx = word_bits - 1 - b
        # Find which words have this bit set to 1
        active_words = [m for m in range(min(num_words, len(data))) if (data[m] >> bit_idx) & 1]
        
        if not active_words:
            # Bit is always 0? We still need an output. 
            # In a real circuit we'd tie to ground, here we just create a dummy source or empty OR
            c_or = gen_comp(f"DATA_OR_{bit_idx}", 2, 800, 100 + b*200, input_count=1, output_count=1)
            # tied to nothing (False)
        else:
            c_or = gen_comp(f"DATA_OR_{bit_idx}", 2, 800, 100 + b*200, input_count=len(active_words), output_count=1)
            for i, m_idx in enumerate(active_words):
                add_conn(connections, word_select_lines[m_idx], 0, c_or, i)
        
        c_out = gen_comp(f"OUT_D{bit_idx}", 13, 1000, 100 + b*200, labels=f"D{bit_idx}", input_count=1, output_count=0)
        components.extend([c_or, c_out])
        add_conn(connections, c_or, 0, c_out, 0)

    output_data = {
        "components": components,
        "connections": connections
    }
    
    with open(output_name, "w", encoding="utf-8") as f:
        json.dump(output_data, f, indent=2)
    print(f"Generated ROM asset: {output_name}")

if __name__ == "__main__":
    # Example usage:
    # py gen_rom.py --addr 4 --word 4 --data 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15 --out assets/sample_rom.json
    
    parser = argparse.ArgumentParser(description="Generate a ROM IC asset for digital_bricks")
    parser.add_argument("--addr", type=int, default=4, help="Number of address bits")
    parser.add_argument("--word", type=int, default=4, help="Bit width of each word")
    parser.add_argument("--data", type=str, help="Comma-separated list of values (e.g. 1,2,4,8)")
    parser.add_argument("--file", type=str, help="Path to a file containing hex values (one per line)")
    parser.add_argument("--out", type=str, default="assets/generated_rom.json", help="Output JSON path")
    
    args = parser.parse_args()
    
=======
        components.append(m_gate); word_select_lines.append(m_gate)
        for bit in range(addr_bits):
            val = (m >> (addr_bits - 1 - bit)) & 1
            src = addr_inputs[bit] if val else addr_nots[bit]
            add_conn(connections, src, 0, m_gate, bit)
    for b in range(word_bits):
        bit_idx = word_bits - 1 - b
        active_words = [m for m in range(min(num_words, len(data))) if (data[m] >> bit_idx) & 1]
        c_or = gen_comp(f"DATA_OR_{bit_idx}", 2, 800, 100 + b*200, input_count=max(1, len(active_words)), output_count=1)
        for i, m_idx in enumerate(active_words): add_conn(connections, word_select_lines[m_idx], 0, c_or, i)
        c_out = gen_comp(f"OUT_D{bit_idx}", 13, 1000, 100 + b*200, labels=f"D{bit_idx}", input_count=1)
        components.extend([c_or, c_out]); add_conn(connections, c_or, 0, c_out, 0)
    with open(output_name, "w") as f: json.dump({"components": components, "connections": connections}, f, indent=2)
    print(f"Generated ROM asset: {output_name}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--addr", type=int, default=4); parser.add_argument("--word", type=int, default=4)
    parser.add_argument("--data", type=str); parser.add_argument("--file", type=str)
    parser.add_argument("--out", type=str, default="assets/rom.json")
    args = parser.parse_args()
>>>>>>> ram-concept
    rom_data = []
    if args.file:
        with open(args.file, 'r') as f:
            for line in f:
<<<<<<< HEAD
                line = line.strip()
                if line:
                    rom_data.append(int(line, 16))
    elif args.data:
        rom_data = [int(v.strip()) for v in args.data.split(',')]
    else:
        # Default sample: identity mapping
        rom_data = list(range(2**args.addr))
        
=======
                if line.strip(): rom_data.append(int(line.strip(), 16))
    elif args.data: rom_data = [int(v.strip()) for v in args.data.split(',')]
    else: rom_data = list(range(2**args.addr))
>>>>>>> ram-concept
    generate_rom(rom_data, args.addr, args.word, args.out)
