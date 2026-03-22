import json
import uuid
import os

class DigitalCircuit:
    def __init__(self, name):
        self.name = name
        self.components = []
        self.connections = []
        self.input_ports = []
        self.output_ports = []
        self.input_labels = []
        self.output_labels = []
        
    def add_input(self, x, y, label):
        cid = str(uuid.uuid4())
        c = {
            "id": cid, 
            "type": 12, 
            "position_dx": int(x), 
            "position_dy": int(y), 
            "inputs": [], 
            "outputs": [{"id": f"{cid}-out-0", "componentId": cid, "type": 1, "label": None, "value": False}], 
            "label": label
        }
        self.components.append(c)
        self.input_ports.append(f"{cid}-out-0")
        self.input_labels.append(label)
        return f"{cid}-out-0"

    def add_output(self, x, y, label):
        cid = str(uuid.uuid4())
        c = {
            "id": cid, 
            "type": 13, 
            "position_dx": int(x), 
            "position_dy": int(y), 
            "inputs": [{"id": f"{cid}-in-0", "componentId": cid, "type": 0, "label": None, "value": False}], 
            "outputs": [], 
            "label": label
        }
        self.components.append(c)
        self.output_ports.append(f"{cid}-in-0")
        self.output_labels.append(label)
        return f"{cid}-in-0"

    def add_gate(self, gate_type, x, y, input_count=2, label=None):
        type_map = {"and": 0, "nand": 1, "or": 2, "nor": 3, "xor": 4, "xnor": 5, "inv": 6, "dff": 17}
        t = type_map[gate_type]
        cid = str(uuid.uuid4())
        c = {
            "id": cid, 
            "type": t, 
            "position_dx": int(x), 
            "position_dy": int(y), 
            "inputs": [], 
            "outputs": [], 
            "label": label
        }
        
        if gate_type == "dff":
            c["inputs"] = [
                {"id": f"{cid}-in-0", "componentId": cid, "type": 0, "label": "D", "value": False},
                {"id": f"{cid}-in-1", "componentId": cid, "type": 0, "label": ">", "value": False}
            ]
            c["outputs"] = [
                {"id": f"{cid}-out-0", "componentId": cid, "type": 1, "label": "Q", "value": False},
                {"id": f"{cid}-out-1", "componentId": cid, "type": 1, "label": "Q\u0305", "value": True}
            ]
        elif gate_type == "inv":
            c["inputs"] = [{"id": f"{cid}-in-0", "componentId": cid, "type": 0, "label": None, "value": False}]
            c["outputs"] = [{"id": f"{cid}-out-0", "componentId": cid, "type": 1, "label": None, "value": True}]
        else:
            if gate_type not in ["inv", "dff"]:
                c["inputCount"] = input_count
            for i in range(input_count):
                c["inputs"].append({"id": f"{cid}-in-{i}", "componentId": cid, "type": 0, "label": None, "value": False})
            c["outputs"] = [{"id": f"{cid}-out-0", "componentId": cid, "type": 1, "label": None, "value": False}]
            
        self.components.append(c)
        return c

    def connect(self, src, tgt):
        self.connections.append({
            "id": str(uuid.uuid4()), 
            "sourcePinId": src, 
            "targetPinId": tgt
        })

    def to_json(self):
        return {
            "components": self.components, 
            "connections": self.connections, 
            "inputPorts": self.input_ports, 
            "outputPorts": self.output_ports, 
            "inputLabels": self.input_labels, 
            "outputLabels": self.output_labels
        }

def add_mux2to1(circuit, d0, d1, s, x, y):
    # (d0 & !s) | (d1 & s)
    inv_s = circuit.add_gate("inv", x, y)
    circuit.connect(s, inv_s["inputs"][0]["id"])
    
    and0 = circuit.add_gate("and", x + 100, y - 50)
    if d0: circuit.connect(d0, and0["inputs"][0]["id"])
    circuit.connect(inv_s["outputs"][0]["id"], and0["inputs"][1]["id"])
    
    and1 = circuit.add_gate("and", x + 100, y + 50)
    if d1: circuit.connect(d1, and1["inputs"][0]["id"])
    circuit.connect(s, and1["inputs"][1]["id"])
    
    or_gate = circuit.add_gate("or", x + 200, y)
    circuit.connect(and0["outputs"][0]["id"], or_gate["inputs"][0]["id"])
    circuit.connect(and1["outputs"][0]["id"], or_gate["inputs"][1]["id"])
    
    return or_gate["outputs"][0]["id"], and0["inputs"][0]["id"] # Return both output and the "hold" input

def add_mux4to1(circuit, d0, d1, d2, d3, s, x, y):
    # s is [s0, s1] (LSB first)
    m01_out, _ = add_mux2to1(circuit, d0, d1, s[0], x, y - 100)
    m23_out, _ = add_mux2to1(circuit, d2, d3, s[0], x, y + 100)
    m_final_out, _ = add_mux2to1(circuit, m01_out, m23_out, s[1], x + 300, y)
    return m_final_out

def add_counter3bit(circuit, en, clk, x, y):
    q = []
    dffs = []
    for i in range(3):
        dff = circuit.add_gate("dff", x + 400, y + i * 200)
        dffs.append(dff)
        q.append(dff["outputs"][0]["id"])
        circuit.connect(clk, dff["inputs"][1]["id"])
        
    xor0 = circuit.add_gate("xor", x, y)
    circuit.connect(en, xor0["inputs"][0]["id"])
    circuit.connect(q[0], xor0["inputs"][1]["id"])
    circuit.connect(xor0["outputs"][0]["id"], dffs[0]["inputs"][0]["id"])
    
    and1 = circuit.add_gate("and", x, y + 150)
    circuit.connect(en, and1["inputs"][0]["id"])
    circuit.connect(q[0], and1["inputs"][1]["id"])
    xor1 = circuit.add_gate("xor", x + 150, y + 200)
    circuit.connect(and1["outputs"][0]["id"], xor1["inputs"][0]["id"])
    circuit.connect(q[1], xor1["inputs"][1]["id"])
    circuit.connect(xor1["outputs"][0]["id"], dffs[1]["inputs"][0]["id"])
    
    and2 = circuit.add_gate("and", x + 150, y + 350)
    circuit.connect(and1["outputs"][0]["id"], and2["inputs"][0]["id"])
    circuit.connect(q[1], and2["inputs"][1]["id"])
    xor2 = circuit.add_gate("xor", x + 300, y + 400)
    circuit.connect(and2["outputs"][0]["id"], xor2["inputs"][0]["id"])
    circuit.connect(q[2], xor2["inputs"][1]["id"])
    circuit.connect(xor2["outputs"][0]["id"], dffs[2]["inputs"][0]["id"])
    
    return q

def generate_fifo():
    circuit = DigitalCircuit("4-bit FIFO")
    
    X_IN = 50
    d_in = [circuit.add_input(X_IN, 100 + i*150, f"D_IN{i}") for i in range(4)]
    wr = circuit.add_input(X_IN, 800, "WR")
    rd = circuit.add_input(X_IN, 950, "RD")
    clk = circuit.add_input(X_IN, 1100, "CLK")
    
    X_POINTERS = 400
    X_STATUS = 900
    X_STORAGE = 1600
    X_OUT = 4500
    
    # Allow logic
    wr_allow_and = circuit.add_gate("and", X_POINTERS - 150, 800)
    circuit.connect(wr, wr_allow_and["inputs"][0]["id"])
    rd_allow_and = circuit.add_gate("and", X_POINTERS - 150, 1000)
    circuit.connect(rd, rd_allow_and["inputs"][0]["id"])
    
    qWP = add_counter3bit(circuit, wr_allow_and["outputs"][0]["id"], clk, X_POINTERS, 100)
    qRP = add_counter3bit(circuit, rd_allow_and["outputs"][0]["id"], clk, X_POINTERS, 800)
    
    # Comparisons for FULL/EMPTY
    xnors = []
    for i in range(3):
        xn = circuit.add_gate("xnor", X_STATUS, 100 + i*100)
        circuit.connect(qWP[i], xn["inputs"][0]["id"])
        circuit.connect(qRP[i], xn["inputs"][1]["id"])
        xnors.append(xn["outputs"][0]["id"])
    
    empty_and = circuit.add_gate("and", X_STATUS + 150, 200, input_count=3)
    for i in range(3): circuit.connect(xnors[i], empty_and["inputs"][i]["id"])
    circuit.connect(empty_and["outputs"][0]["id"], circuit.add_output(X_STATUS + 300, 200, "EMPTY"))
    
    xor2 = circuit.add_gate("xor", X_STATUS, 500)
    circuit.connect(qWP[2], xor2["inputs"][0]["id"])
    circuit.connect(qRP[2], xor2["inputs"][1]["id"])
    full_and = circuit.add_gate("and", X_STATUS + 150, 500, input_count=3)
    circuit.connect(xor2["outputs"][0]["id"], full_and["inputs"][0]["id"])
    circuit.connect(xnors[0], full_and["inputs"][1]["id"])
    circuit.connect(xnors[1], full_and["inputs"][2]["id"])
    circuit.connect(full_and["outputs"][0]["id"], circuit.add_output(X_STATUS + 300, 500, "FULL"))
    
    # Feedback to allow signals
    full_inv = circuit.add_gate("inv", X_POINTERS - 250, 850)
    circuit.connect(full_and["outputs"][0]["id"], full_inv["inputs"][0]["id"])
    circuit.connect(full_inv["outputs"][0]["id"], wr_allow_and["inputs"][1]["id"])
    empty_inv = circuit.add_gate("inv", X_POINTERS - 250, 1050)
    circuit.connect(empty_and["outputs"][0]["id"], empty_inv["inputs"][0]["id"])
    circuit.connect(empty_inv["outputs"][0]["id"], rd_allow_and["inputs"][1]["id"])
    
    # Storage
    w_inv = [circuit.add_gate("inv", X_STORAGE - 300, 100 + i*100) for i in range(2)]
    circuit.connect(qWP[0], w_inv[0]["inputs"][0]["id"])
    circuit.connect(qWP[1], w_inv[1]["inputs"][0]["id"])
    
    storage_q = [[None for _ in range(4)] for _ in range(4)]
    for word in range(4):
        w_en_and = circuit.add_gate("and", X_STORAGE - 150, 100 + word*150, input_count=3)
        circuit.connect(wr_allow_and["outputs"][0]["id"], w_en_and["inputs"][0]["id"])
        circuit.connect(qWP[0] if (word & 1) else w_inv[0]["outputs"][0]["id"], w_en_and["inputs"][1]["id"])
        circuit.connect(qWP[1] if (word & 2) else w_inv[1]["outputs"][0]["id"], w_en_and["inputs"][2]["id"])
        
        for bit in range(4):
            x, y = X_STORAGE + word*600, 100 + word*700 + bit*150
            # Mux for write/hold
            mux_out, hold_in = add_mux2to1(circuit, None, d_in[bit], w_en_and["outputs"][0]["id"], x, y)
            dff = circuit.add_gate("dff", x + 350, y)
            circuit.connect(mux_out, dff["inputs"][0]["id"])
            circuit.connect(clk, dff["inputs"][1]["id"])
            circuit.connect(dff["outputs"][0]["id"], hold_in)
            storage_q[word][bit] = dff["outputs"][0]["id"]
            
    # Output
    for bit in range(4):
        q_val = add_mux4to1(circuit, 
                           storage_q[0][bit], storage_q[1][bit], 
                           storage_q[2][bit], storage_q[3][bit], 
                           [qRP[0], qRP[1]], X_OUT, 100 + bit*500)
        circuit.connect(q_val, circuit.add_output(X_OUT + 600, 100 + bit*500, f"D_OUT{bit}"))
        
    return circuit.to_json()

if __name__ == "__main__":
    data = generate_fifo()
    target = os.path.abspath(os.path.join(os.path.dirname(__file__), "../assets/4-bit FIFO.json"))
    with open(target, "w") as f:
        json.dump(data, f, indent=2)
    print(f"Generated {target} with {len(data['components'])} components and {len(data['connections'])} connections.")
