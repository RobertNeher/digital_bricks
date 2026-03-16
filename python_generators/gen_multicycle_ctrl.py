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

def generate_multicycle_ctrl():
    circuit = DigitalCircuit("Multi-cycle Controller")
    X_IN, X_LOGIC, X_RST, X_DFF, X_OUT = 100, 400, 700, 900, 1200
    
    # Inputs
    is_2byte = circuit.add_input(X_IN, 200, "IS_2BYTE")
    t3 = circuit.add_input(X_IN, 350, "T3")
    rst = circuit.add_input(X_IN, 500, "RESET")
    clk = circuit.add_input(X_IN, 650, "CLK")
    
    # Inverters
    inv_t3 = circuit.add_gate("inv", X_LOGIC - 100, 350)
    circuit.connect(t3, inv_t3["inputs"][0]["id"])
    
    inv_rst = circuit.add_gate("inv", X_RST - 100, 500)
    circuit.connect(rst, inv_rst["inputs"][0]["id"])
    
    # State Logic: D = (IS_2BYTE & !C2 & T3) | (C2 & !T3)
    # Part 1: Start Cycle 2
    and_start = circuit.add_gate("and", X_LOGIC, 200, input_count=3)
    circuit.connect(is_2byte, and_start["inputs"][0]["id"])
    circuit.connect(t3, and_start["inputs"][2]["id"])
    
    # Part 2: Sustain Cycle 2
    and_stay = circuit.add_gate("and", X_LOGIC, 400)
    circuit.connect(inv_t3["outputs"][0]["id"], and_stay["inputs"][1]["id"])
    
    # Combined State
    or_state = circuit.add_gate("or", X_LOGIC + 150, 300)
    circuit.connect(and_start["outputs"][0]["id"], or_state["inputs"][0]["id"])
    circuit.connect(and_stay["outputs"][0]["id"], or_state["inputs"][1]["id"])
    
    # Reset Gate
    and_reset = circuit.add_gate("and", X_RST, 300)
    circuit.connect(or_state["outputs"][0]["id"], and_reset["inputs"][0]["id"])
    circuit.connect(inv_rst["outputs"][0]["id"], and_reset["inputs"][1]["id"])
    
    # DFF (State C2)
    dff = circuit.add_gate("dff", X_DFF, 300, label="C2")
    circuit.connect(and_reset["outputs"][0]["id"], dff["inputs"][0]["id"])
    circuit.connect(clk, dff["inputs"][1]["id"])
    
    # Feedback for Logic
    inv_c2 = circuit.add_gate("inv", X_LOGIC - 100, 250)
    circuit.connect(dff["outputs"][0]["id"], inv_c2["inputs"][0]["id"])
    circuit.connect(inv_c2["outputs"][0]["id"], and_start["inputs"][1]["id"])
    circuit.connect(dff["outputs"][0]["id"], and_stay["inputs"][0]["id"])
    
    # Output
    c2_out = circuit.add_output(X_OUT, 300, "C2")
    circuit.connect(dff["outputs"][0]["id"], c2_out)
    
    return circuit.to_json()

if __name__ == "__main__":
    mc_json = generate_multicycle_ctrl()
    target = os.path.abspath(os.path.join(os.path.dirname(__file__), "../assets/Multi-cycle Controller.json"))
    with open(target, "w") as f: json.dump(mc_json, f, indent=2)
    print(f"Generated {target}")
