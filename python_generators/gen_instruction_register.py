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

def generate_instruction_register():
    circuit = DigitalCircuit("Instruction Register (8-bit)")
    X_IN, X_MUX, X_RST, X_DFF, X_OUT = 100, 400, 700, 900, 1200
    
    # Inputs
    d_inputs = [circuit.add_input(X_IN, 100 + i*150, f"D{i}") for i in range(8)]
    lir = circuit.add_input(X_IN, 1300, "LIR") # Load Instruction Register
    rst = circuit.add_input(X_IN, 1400, "RESET")
    clk = circuit.add_input(X_IN, 1500, "CLK")
    
    # Inverters for MUX and Reset
    inv_lir = circuit.add_gate("inv", X_MUX - 100, 1300)
    circuit.connect(lir, inv_lir["inputs"][0]["id"])
    
    inv_rst = circuit.add_gate("inv", X_RST - 100, 1400)
    circuit.connect(rst, inv_rst["inputs"][0]["id"])
    
    for i in range(8):
        y = 100 + i*150
        
        # MUX Logic: next_val = (D_IN & LIR) | (Q & !LIR)
        and_new = circuit.add_gate("and", X_MUX, y)
        circuit.connect(d_inputs[i], and_new["inputs"][0]["id"])
        circuit.connect(lir, and_new["inputs"][1]["id"])
        
        and_old = circuit.add_gate("and", X_MUX, y + 60)
        # Port for Q feedback will be connected after DFF creation
        circuit.connect(inv_lir["outputs"][0]["id"], and_old["inputs"][1]["id"])
        
        or_mux = circuit.add_gate("or", X_MUX + 120, y + 30)
        circuit.connect(and_new["outputs"][0]["id"], or_mux["inputs"][0]["id"])
        circuit.connect(and_old["outputs"][0]["id"], or_mux["inputs"][1]["id"])
        
        # RESET Logic: final_D = or_mux & !RESET
        and_reset = circuit.add_gate("and", X_RST, y + 30)
        circuit.connect(or_mux["outputs"][0]["id"], and_reset["inputs"][0]["id"])
        circuit.connect(inv_rst["outputs"][0]["id"], and_reset["inputs"][1]["id"])
        
        # DFF
        dff = circuit.add_gate("dff", X_DFF, y + 30)
        circuit.connect(and_reset["outputs"][0]["id"], dff["inputs"][0]["id"])
        circuit.connect(clk, dff["inputs"][1]["id"])
        
        # Feedback
        circuit.connect(dff["outputs"][0]["id"], and_old["inputs"][0]["id"])
        
        # Output
        out_pin = circuit.add_output(X_OUT, y + 30, f"INSTR{i}")
        circuit.connect(dff["outputs"][0]["id"], out_pin)
        
    return circuit.to_json()

if __name__ == "__main__":
    ir_json = generate_instruction_register()
    target = os.path.abspath(os.path.join(os.path.dirname(__file__), "../assets/Instruction Register.json"))
    with open(target, "w") as f: json.dump(ir_json, f, indent=2)
    print(f"Generated {target}")
