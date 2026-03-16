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

def generate_timing_generator():
    circuit = DigitalCircuit("Timing Generator (4-Phase)")
    
    # Inputs
    clk = circuit.add_input(100, 200, "CLK")
    rst = circuit.add_input(100, 400, "RESET")
    
    # 2-bit Counter Logic
    # DFF0 (LSB)
    dff0 = circuit.add_gate("dff", 400, 200, label="Q0")
    inv0 = circuit.add_gate("inv", 400, 100)
    circuit.connect(dff0["outputs"][0]["id"], inv0["inputs"][0]["id"])
    
    # RESET logic for Q0: next_Q0 = (NOT Q0) AND (NOT RESET)
    and0_rst = circuit.add_gate("and", 300, 200)
    inv_rst = circuit.add_gate("inv", 250, 400)
    circuit.connect(rst, inv_rst["inputs"][0]["id"])
    circuit.connect(inv0["outputs"][0]["id"], and0_rst["inputs"][0]["id"])
    circuit.connect(inv_rst["outputs"][0]["id"], and0_rst["inputs"][1]["id"])
    circuit.connect(and0_rst["outputs"][0]["id"], dff0["inputs"][0]["id"])
    circuit.connect(clk, dff0["inputs"][1]["id"])
    
    # DFF1 (MSB)
    dff1 = circuit.add_gate("dff", 700, 200, label="Q1")
    # XOR for counting: next_Q1 = (Q1 XOR Q0)
    xor1 = circuit.add_gate("xor", 600, 200)
    circuit.connect(dff1["outputs"][0]["id"], xor1["inputs"][0]["id"])
    circuit.connect(dff0["outputs"][0]["id"], xor1["inputs"][1]["id"])
    
    # RESET logic for Q1: next_Q1 = (Q1 XOR Q0) AND (NOT RESET)
    and1_rst = circuit.add_gate("and", 650, 200)
    circuit.connect(xor1["outputs"][0]["id"], and1_rst["inputs"][0]["id"])
    circuit.connect(inv_rst["outputs"][0]["id"], and1_rst["inputs"][1]["id"])
    circuit.connect(and1_rst["outputs"][0]["id"], dff1["inputs"][0]["id"])
    circuit.connect(clk, dff1["inputs"][1]["id"])
    
    # 2-to-4 Decoder
    q0 = dff0["outputs"][0]["id"]
    q1 = dff1["outputs"][0]["id"]
    not_q0_comp = circuit.add_gate("inv", 500, 350)
    circuit.connect(q0, not_q0_comp["inputs"][0]["id"])
    not_q0 = not_q0_comp["outputs"][0]["id"]
    
    not_q1_comp = circuit.add_gate("inv", 800, 350)
    circuit.connect(q1, not_q1_comp["inputs"][0]["id"])
    not_q1 = not_q1_comp["outputs"][0]["id"]
    
    # T0 = NOT Q1 AND NOT Q0
    t0_gate = circuit.add_gate("and", 1000, 100)
    circuit.connect(not_q1, t0_gate["inputs"][0]["id"])
    circuit.connect(not_q0, t0_gate["inputs"][1]["id"])
    t0_out = circuit.add_output(1200, 100, "T0")
    circuit.connect(t0_gate["outputs"][0]["id"], t0_out)
    
    # T1 = NOT Q1 AND Q0
    t1_gate = circuit.add_gate("and", 1000, 250)
    circuit.connect(not_q1, t1_gate["inputs"][0]["id"])
    circuit.connect(q0, t1_gate["inputs"][1]["id"])
    t1_out = circuit.add_output(1200, 250, "T1")
    circuit.connect(t1_gate["outputs"][0]["id"], t1_out)
    
    # T2 = Q1 AND NOT Q0
    t2_gate = circuit.add_gate("and", 1000, 400)
    circuit.connect(q1, t2_gate["inputs"][0]["id"])
    circuit.connect(not_q0, t2_gate["inputs"][1]["id"])
    t2_out = circuit.add_output(1200, 400, "T2")
    circuit.connect(t2_gate["outputs"][0]["id"], t2_out)
    
    # T3 = Q1 AND Q0
    t3_gate = circuit.add_gate("and", 1000, 550)
    circuit.connect(q1, t3_gate["inputs"][0]["id"])
    circuit.connect(q0, t3_gate["inputs"][1]["id"])
    t3_out = circuit.add_output(1200, 550, "T3")
    circuit.connect(t3_gate["outputs"][0]["id"], t3_out)
    
    return circuit.to_json()

if __name__ == "__main__":
    timing_json = generate_timing_generator()
    target = os.path.abspath(os.path.join(os.path.dirname(__file__), "../assets/Timing Generator.json"))
    with open(target, "w") as f: json.dump(timing_json, f, indent=2)
    print(f"Generated {target}")
