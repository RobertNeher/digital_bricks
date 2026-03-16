import json
import uuid
import os
import argparse

class DigitalCircuit:
    def __init__(self, name):
        self.name = name
        self.components, self.connections, self.input_ports, self.output_ports, self.input_labels, self.output_labels = [], [], [], [], [], []
        
    def add_input(self, x, y, label):
        cid = str(uuid.uuid4())
        c = {"id": cid, "type": 12, "position_dx": float(x), "position_dy": float(y), "inputs": [], "outputs": [{"id": f"{cid}-out-0", "componentId": cid, "type": 1, "label": None, "value": False}], "label": label}
        self.components.append(c); self.input_ports.append(f"{cid}-out-0"); self.input_labels.append(label)
        return f"{cid}-out-0"

    def add_output(self, x, y, label):
        cid = str(uuid.uuid4())
        c = {"id": cid, "type": 13, "position_dx": float(x), "position_dy": float(y), "inputs": [{"id": f"{cid}-in-0", "componentId": cid, "type": 0, "label": None, "value": False}], "outputs": [], "label": label}
        self.components.append(c); self.output_ports.append(f"{cid}-in-0"); self.output_labels.append(label)
        return f"{cid}-in-0"

    def add_gate(self, gate_type, x, y, input_count=2, label=None):
        type_map = {"and": 0, "nand": 1, "or": 2, "nor": 3, "xor": 4, "nxor": 5, "inv": 6, "dff": 17}
        t = type_map[gate_type]; cid = str(uuid.uuid4())
        c = {"id": cid, "type": t, "position_dx": float(x), "position_dy": float(y), "inputs": [], "outputs": [], "label": label}
        
        if gate_type == "dff":
            c["inputs"] = [{"id": f"{cid}-in-0", "componentId": cid, "type": 0, "label": "D", "value": False},
                           {"id": f"{cid}-in-1", "componentId": cid, "type": 0, "label": ">", "value": False}]
            c["outputs"] = [{"id": f"{cid}-out-0", "componentId": cid, "type": 1, "label": "Q", "value": False},
                            {"id": f"{cid}-out-1", "componentId": cid, "type": 1, "label": "Q̅", "value": True}]
        elif gate_type == "inv":
            c["inputs"] = [{"id": f"{cid}-in-0", "componentId": cid, "type": 0, "label": None, "value": False}]
            c["outputs"] = [{"id": f"{cid}-out-0", "componentId": cid, "type": 1, "label": None, "value": True}]
        else:
            c["inputCount"] = input_count
            for i in range(input_count): c["inputs"].append({"id": f"{cid}-in-{i}", "componentId": cid, "type": 0, "label": None, "value": False})
            c["outputs"] = [{"id": f"{cid}-out-0", "componentId": cid, "type": 1, "label": None, "value": False}]
            
        self.components.append(c)
        return c

    def connect(self, src, tgt): self.connections.append({"id": str(uuid.uuid4()), "sourcePinId": src, "targetPinId": tgt})

    def to_json(self): return {"components": self.components, "connections": self.connections, "inputPorts": self.input_ports, "outputPorts": self.output_ports, "inputLabels": self.input_labels, "outputLabels": self.output_labels}

def generate_ram(addr_bits, word_bits, output_name):
    num_words = 2**addr_bits
    circuit = DigitalCircuit(f"{num_words}x{word_bits} RAM")
    
    # Layout constants
    X_ADDR, X_INV, X_DEC = 100, 300, 500
    X_DATA_IN = 100
    X_WE_CLK = 100
    X_CELL = 800
    X_READ = 2500
    X_OUT = 3500
    
    # row_pitch determines vertical spacing between bits/rows
    row_pitch = 1500 if num_words <= 32 else 2000
    
    # 1. Address Inputs & Inverters
    addr_pins = [circuit.add_input(X_ADDR, 100 + i*150, f"A{i}") for i in range(addr_bits)]
    not_addr = []
    for i in range(addr_bits):
        inv = circuit.add_gate("inv", X_INV, 100 + i*150)
        circuit.connect(addr_pins[i], inv["inputs"][0]["id"])
        not_addr.append(inv["outputs"][0]["id"])
        
    # 2. Decoder
    row_select = []
    for i in range(num_words):
        and_dec = circuit.add_gate("and", X_DEC, i*100, input_count=addr_bits)
        for bit in range(addr_bits):
            val = (i >> bit) & 1
            src = addr_pins[bit] if val == 1 else not_addr[bit]
            circuit.connect(src, and_dec["inputs"][bit]["id"])
        row_select.append(and_dec["outputs"][0]["id"])
        
    # 3. Control Inputs
    we = circuit.add_input(X_WE_CLK, 1000, "WE")
    clk = circuit.add_input(X_WE_CLK, 1150, "CLK")
    
    # Data Inputs
    data_in_pins = [circuit.add_input(X_DATA_IN, 1300 + i*150, f"D_IN{i}") for i in range(word_bits)]
    
    # 4. Storage Matrix
    byte_q_outputs = [[] for _ in range(word_bits)]
    
    for row in range(num_words):
        row_y = row * row_pitch
        
        # Load Enable for this row
        load_gate = circuit.add_gate("and", X_CELL - 100, row_y + 1000)
        circuit.connect(row_select[row], load_gate["inputs"][0]["id"])
        circuit.connect(we, load_gate["inputs"][1]["id"])
        load_en = load_gate["outputs"][0]["id"]
        
        not_load_gate = circuit.add_gate("inv", X_CELL - 100, row_y + 1100)
        circuit.connect(load_en, not_load_gate["inputs"][0]["id"])
        not_load = not_load_gate["outputs"][0]["id"]
        
        for bit in range(word_bits):
            cell_x = X_CELL + bit * 200
            cell_y = row_y + bit * 150
            
            # cell logic
            and_new = circuit.add_gate("and", cell_x, cell_y)
            circuit.connect(data_in_pins[bit], and_new["inputs"][0]["id"])
            circuit.connect(load_en, and_new["inputs"][1]["id"])
            
            and_old = circuit.add_gate("and", cell_x, cell_y + 50)
            circuit.connect(not_load, and_old["inputs"][1]["id"])
            
            or_mux = circuit.add_gate("or", cell_x + 80, cell_y + 25)
            circuit.connect(and_new["outputs"][0]["id"], or_mux["inputs"][0]["id"])
            circuit.connect(and_old["outputs"][0]["id"], or_mux["inputs"][1]["id"])
            
            dff = circuit.add_gate("dff", cell_x + 160, cell_y + 25)
            circuit.connect(or_mux["outputs"][0]["id"], dff["inputs"][0]["id"])
            circuit.connect(clk, dff["inputs"][1]["id"])
            circuit.connect(dff["outputs"][0]["id"], and_old["inputs"][0]["id"])
            
            # read logic
            read_and = circuit.add_gate("and", X_READ + bit*200, row_y + bit*40)
            circuit.connect(dff["outputs"][0]["id"], read_and["inputs"][0]["id"])
            circuit.connect(row_select[row], read_and["inputs"][1]["id"])
            byte_q_outputs[bit].append(read_and["outputs"][0]["id"])
            
    # 5. Output Muxing
    for bit in range(word_bits):
        final_or = circuit.add_gate("or", X_OUT - 200, bit * 400, input_count=num_words)
        for row in range(num_words):
            circuit.connect(byte_q_outputs[bit][row], final_or["inputs"][row]["id"])
            
        data_out = circuit.add_output(X_OUT, bit * 400, f"D_OUT{bit}")
        circuit.connect(final_or["outputs"][0]["id"], data_out)
        
    with open(output_name, "w", encoding="utf-8") as f:
        json.dump(circuit.to_json(), f, indent=2)
    print(f"Generated RAM asset: {output_name} ({num_words}x{word_bits})")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate a RAM IC asset for digital_bricks")
    parser.add_argument("--addr", type=int, default=4, help="Number of address bits (e.g. 5 for 32 words)")
    parser.add_argument("--word", type=int, default=4, help="Bit width of each word (e.g. 8 for 1 byte)")
    parser.add_argument("--out", type=str, default="assets/ram.json", help="Output JSON path")
    
    args = parser.parse_args()
    generate_ram(args.addr, args.word, args.out)
