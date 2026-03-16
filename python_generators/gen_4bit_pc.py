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

def generate_pc():
    circuit = DigitalCircuit("4-bit Program Counter")
    X_IN, X_INC, X_LOAD, X_CLR, X_DFF, X_OUT = 0, 300, 600, 850, 1100, 1400
    
    # 1. Inputs
    d_inputs = [circuit.add_input(X_IN, 100 + i*200, f"D{i}") for i in range(4)]
    inc = circuit.add_input(X_IN, 900, "INC")
    load = circuit.add_input(X_IN, 1000, "LOAD")
    clr = circuit.add_input(X_IN, 1100, "CLR")
    clk = circuit.add_input(X_IN, 1200, "CLK")
    
    # Pre-calculate NOT signals for MUXes
    inv_load = circuit.add_gate("inv", X_LOAD - 100, 1000)
    circuit.connect(load, inv_load["inputs"][0]["id"])
    
    inv_clr = circuit.add_gate("inv", X_CLR - 100, 1100)
    circuit.connect(clr, inv_clr["inputs"][0]["id"])
    
    carry = inc
    q_outputs = [] # To store Q pin IDs for feedback
    dffs = []
    
    for i in range(4):
        y = 100 + i*200
        
        # 2. Increment Logic: Qi_next = Qi ^ Carry; Carry_next = Qi & Carry
        xor_inc = circuit.add_gate("xor", X_INC, y)
        and_carry = circuit.add_gate("and", X_INC, y + 80)
        
        # We'll connect Qi feedback later
        circuit.connect(carry, xor_inc["inputs"][1]["id"])
        circuit.connect(carry, and_carry["inputs"][1]["id"])
        
        # 3. Load MUX: Bi_load = (Di & LOAD) | (Qi_next & !LOAD)
        and_di = circuit.add_gate("and", X_LOAD, y)
        circuit.connect(d_inputs[i], and_di["inputs"][0]["id"])
        circuit.connect(load, and_di["inputs"][1]["id"])
        
        and_ni = circuit.add_gate("and", X_LOAD, y + 80)
        circuit.connect(xor_inc["outputs"][0]["id"], and_ni["inputs"][0]["id"])
        circuit.connect(inv_load["outputs"][0]["id"], and_ni["inputs"][1]["id"])
        
        or_load = circuit.add_gate("or", X_LOAD + 100, y + 40)
        circuit.connect(and_di["outputs"][0]["id"], or_load["inputs"][0]["id"])
        circuit.connect(and_ni["outputs"][0]["id"], or_load["inputs"][1]["id"])
        
        # 4. Synchronous Clear: Bi_final = Bi_load & !CLR
        and_clr = circuit.add_gate("and", X_CLR, y + 40)
        circuit.connect(or_load["outputs"][0]["id"], and_clr["inputs"][0]["id"])
        circuit.connect(inv_clr["outputs"][0]["id"], and_clr["inputs"][1]["id"])
        
        # 5. DFF
        dff = circuit.add_gate("dff", X_DFF, y + 40)
        circuit.connect(and_clr["outputs"][0]["id"], dff["inputs"][0]["id"])
        circuit.connect(clk, dff["inputs"][1]["id"])
        
        # Qi Feedback to XOR and AND
        circuit.connect(dff["outputs"][0]["id"], xor_inc["inputs"][0]["id"])
        circuit.connect(dff["outputs"][0]["id"], and_carry["inputs"][0]["id"])
        
        # Carry propagation
        carry = and_carry["outputs"][0]["id"]
        
        # Output
        out_pin = circuit.add_output(X_OUT, y + 40, f"Q{i}")
        circuit.connect(dff["outputs"][0]["id"], out_pin)

    return circuit.to_json()

if __name__ == "__main__":
    pc_json = generate_pc()
    target = os.path.abspath(os.path.join(os.path.dirname(__file__), "../assets/4 bit Program Counter.json"))
    with open(target, "w") as f: json.dump(pc_json, f, indent=2)
    print(f"Generated {target}")
