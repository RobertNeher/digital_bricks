import json
import uuid
import os

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

def generate_register_file():
    circuit = DigitalCircuit("Register File (16x4-bit)")
    
    # Layout constants
    X_ADDR, X_INV, X_DEC = 100, 300, 500
    X_DATA_IN = 100
    X_WE_CLK = 100
    X_ROW = 800
    X_MUX = 2500
    X_OUT = 3500
    
    # 1. Address Inputs & Inverters
    addr_pins = [circuit.add_input(X_ADDR, 100 + i*150, f"A{i}") for i in range(4)]
    not_addr = []
    for i in range(4):
        inv = circuit.add_gate("inv", X_INV, 100 + i*150)
        circuit.connect(addr_pins[i], inv["inputs"][0]["id"])
        not_addr.append(inv["outputs"][0]["id"])
        
    # 2. Control & Data Inputs
    we = circuit.add_input(X_WE_CLK, 800, "WE")
    clk = circuit.add_input(X_WE_CLK, 950, "CLK")
    rst = circuit.add_input(X_WE_CLK, 1100, "RESET")
    inv_rst = circuit.add_gate("inv", X_WE_CLK + 150, 1100)
    circuit.connect(rst, inv_rst["inputs"][0]["id"])
    
    data_in_pins = [circuit.add_input(X_DATA_IN, 1300 + i*150, f"D_IN{i}") for i in range(4)]
    
    # 3. 4-to-16 Decoder
    row_select = []
    for i in range(16):
        # row_select[i] = (decoded addr i) AND WE
        and_dec = circuit.add_gate("and", X_DEC, i*100, input_count=4)
        for bit in range(4):
            val = (i >> bit) & 1
            src = addr_pins[bit] if val == 1 else not_addr[bit]
            circuit.connect(src, and_dec["inputs"][bit]["id"])
            
        load_gate = circuit.add_gate("and", X_DEC + 150, i*100)
        circuit.connect(and_dec["outputs"][0]["id"], load_gate["inputs"][0]["id"])
        circuit.connect(we, load_gate["inputs"][1]["id"])
        row_select.append((and_dec["outputs"][0]["id"], load_gate["outputs"][0]["id"])) # (addr_match, load_en)

    # 4. Storage Matrix
    bit_q_outputs = [[] for _ in range(4)]
    
    for row in range(16):
        addr_match, load_en = row_select[row]
        not_load_gate = circuit.add_gate("inv", X_ROW - 100, row*1000 + 100)
        circuit.connect(load_en, not_load_gate["inputs"][0]["id"])
        not_load = not_load_gate["outputs"][0]["id"]
        
        for bit in range(4):
            cell_x = X_ROW + bit * 250
            cell_y = row * 1000 + bit * 200
            
            # MUX: (D_IN & load_en) | (Q & !load_en)
            and_new = circuit.add_gate("and", cell_x, cell_y)
            circuit.connect(data_in_pins[bit], and_new["inputs"][0]["id"])
            circuit.connect(load_en, and_new["inputs"][1]["id"])
            
            and_old = circuit.add_gate("and", cell_x, cell_y + 60)
            circuit.connect(not_load, and_old["inputs"][1]["id"])
            
            or_mux = circuit.add_gate("or", cell_x + 120, cell_y + 30)
            circuit.connect(and_new["outputs"][0]["id"], or_mux["inputs"][0]["id"])
            circuit.connect(and_old["outputs"][0]["id"], or_mux["inputs"][1]["id"])
            
            # Sync Clear: D_final = or_mux & !RESET
            and_rst = circuit.add_gate("and", cell_x + 220, cell_y + 30)
            circuit.connect(or_mux["outputs"][0]["id"], and_rst["inputs"][0]["id"])
            circuit.connect(inv_rst["outputs"][0]["id"], and_rst["inputs"][1]["id"])
            
            # DFF
            dff = circuit.add_gate("dff", cell_x + 320, cell_y + 30)
            circuit.connect(and_rst["outputs"][0]["id"], dff["inputs"][0]["id"])
            circuit.connect(clk, dff["inputs"][1]["id"])
            
            # Feedback
            circuit.connect(dff["outputs"][0]["id"], and_old["inputs"][0]["id"])
            
            # Read Logic: Q & addr_match
            read_and = circuit.add_gate("and", X_MUX + bit*300, row*50 + bit*12)
            circuit.connect(dff["outputs"][0]["id"], read_and["inputs"][0]["id"])
            circuit.connect(addr_match, read_and["inputs"][1]["id"])
            bit_q_outputs[bit].append(read_and["outputs"][0]["id"])
            
    # 5. Output Multiplexers
    for bit in range(4):
        final_or = circuit.add_gate("or", X_OUT - 200, bit * 400, input_count=16)
        for row in range(16):
            circuit.connect(bit_q_outputs[bit][row], final_or["inputs"][row]["id"])
            
        data_out = circuit.add_output(X_OUT, bit * 400, f"D_OUT{bit}")
        circuit.connect(final_or["outputs"][0]["id"], data_out)
        
    return circuit.to_json()

if __name__ == "__main__":
    reg_json = generate_register_file()
    target = os.path.abspath(os.path.join(os.path.dirname(__file__), "../assets/Register File (16x4).json"))
    with open(target, "w") as f: json.dump(reg_json, f, indent=2)
    print(f"Generated {target}")
