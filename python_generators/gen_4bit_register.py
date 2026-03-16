import json
import uuid
import os

class DigitalCircuit:
    def __init__(self, name):
        self.name = name
        self.components, self.connections, self.input_ports, self.output_ports, self.input_labels, self.output_labels = [], [], [], [], [], []
        
    def add_input(self, x, y, label):
        cid = str(uuid.uuid4())
        c = {"id": cid, "type": 12, "position_dx": x, "position_dy": y, "inputs": [], "outputs": [{"id": f"{cid}-out-0", "componentId": cid, "type": 1, "label": None, "value": False}], "label": label}
        self.components.append(c); self.input_ports.append(f"{cid}-out-0"); self.input_labels.append(label)
        return f"{cid}-out-0"

    def add_output(self, x, y, label):
        cid = str(uuid.uuid4())
        c = {"id": cid, "type": 13, "position_dx": x, "position_dy": y, "inputs": [{"id": f"{cid}-in-0", "componentId": cid, "type": 0, "label": None, "value": False}], "outputs": [], "label": label}
        self.components.append(c); self.output_ports.append(f"{cid}-in-0"); self.output_labels.append(label)
        return f"{cid}-in-0"

    def add_gate(self, gate_type, x, y, input_count=2, label=None):
        type_map = {"and": 0, "nand": 1, "or": 2, "nor": 3, "xor": 4, "nxor": 5, "inv": 6, "dff": 17}
        t = type_map[gate_type]; cid = str(uuid.uuid4())
        c = {"id": cid, "type": t, "position_dx": x, "position_dy": y, "inputs": [], "outputs": [], "label": label}
        
        if gate_type == "dff":
            # DFlipFlop: 0:D, 1:CLK -> 0:Q, 1:/Q
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

def generate_register():
    circuit = DigitalCircuit("4-bit Register")
    X_IN, X_MUX, X_DFF, X_OUT = 0, 300, 600, 900
    
    # 1. Inputs
    d_inputs = [circuit.add_input(X_IN, 100 + i*200, f"D{i}") for i in range(4)]
    en = circuit.add_input(X_IN, 900, "EN")
    clk = circuit.add_input(X_IN, 1000, "CLK")
    
    inv_en = circuit.add_gate("inv", X_MUX - 100, 900)
    circuit.connect(en, inv_en["inputs"][0]["id"])
    
    for i in range(4):
        # MUX Logic: next_D = (D AND EN) OR (Q AND NOT_EN)
        and_d = circuit.add_gate("and", X_MUX, 100 + i*200)
        circuit.connect(d_inputs[i], and_d["inputs"][0]["id"])
        circuit.connect(en, and_d["inputs"][1]["id"])
        
        and_q = circuit.add_gate("and", X_MUX, 200 + i*200)
        # Port for Q feedback will be connected after DFF creation
        circuit.connect(inv_en["outputs"][0]["id"], and_q["inputs"][1]["id"])
        
        or_mux = circuit.add_gate("or", X_MUX + 150, 150 + i*200)
        circuit.connect(and_d["outputs"][0]["id"], or_mux["inputs"][0]["id"])
        circuit.connect(and_q["outputs"][0]["id"], or_mux["inputs"][1]["id"])
        
        # DFF
        dff = circuit.add_gate("dff", X_DFF, 150 + i*200)
        circuit.connect(or_mux["outputs"][0]["id"], dff["inputs"][0]["id"])
        circuit.connect(clk, dff["inputs"][1]["id"])
        
        # Q Feedback
        circuit.connect(dff["outputs"][0]["id"], and_q["inputs"][0]["id"])
        
        # Output
        circuit.add_output(X_OUT, 150 + i*200, f"Q{i}")
        circuit.connect(dff["outputs"][0]["id"], circuit.components[-1]["inputs"][0]["id"])
        
    return circuit.to_json()

if __name__ == "__main__":
    reg_json = generate_register()
    target = os.path.abspath(os.path.join(os.path.dirname(__file__), "../assets/4 bit Register.json"))
    with open(target, "w") as f: json.dump(reg_json, f, indent=2)
    print(f"Generated {target}")
