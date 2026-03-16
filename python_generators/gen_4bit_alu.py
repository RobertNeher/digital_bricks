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
        type_map = {"and": 0, "nand": 1, "or": 2, "nor": 3, "xor": 4, "nxor": 5, "inv": 6}
        t = type_map[gate_type]; cid = str(uuid.uuid4())
        c = {"id": cid, "type": t, "position_dx": x, "position_dy": y, "inputs": [], "outputs": [{"id": f"{cid}-out-0", "componentId": cid, "type": 1, "label": None, "value": False}], "label": label}
        if gate_type != "inv":
            c["inputCount"] = input_count
            for i in range(input_count): c["inputs"].append({"id": f"{cid}-in-{i}", "componentId": cid, "type": 0, "label": None, "value": False})
        else:
            c["inputs"].append({"id": f"{cid}-in-0", "componentId": cid, "type": 0, "label": None, "value": False})
        self.components.append(c)
        return c

    def connect(self, src, tgt): self.connections.append({"id": str(uuid.uuid4()), "sourcePinId": src, "targetPinId": tgt})

    def to_json(self): return {"components": self.components, "connections": self.connections, "inputPorts": self.input_ports, "outputPorts": self.output_ports, "inputLabels": self.input_labels, "outputLabels": self.output_labels}

def generate_alu():
    circuit = DigitalCircuit("4-bit ALU")
    X_IN, X_TERM, X_CLA, X_BIT, X_SHIFT, X_BCD, X_MODES, X_FLAGS, X_OUT = 0, 300, 600, 900, 1200, 1500, 1800, 2100, 2400
    
    # 1. Inputs
    a = [circuit.add_input(X_IN, 100 + i*150, f"A{i}") for i in range(4)]
    b = [circuit.add_input(X_IN, 750 + i*150, f"B{i}") for i in range(4)]
    s = [circuit.add_input(X_IN, 1400 + i*150, f"S{i}") for i in range(4)]
    m = [circuit.add_input(X_IN, 2000 + i*150, f"M{i}") for i in range(3)] # M0:Arith/Log, M1:ALU/Shift, M2:Bin/BCD
    ci = circuit.add_input(X_IN, 2500, "Ci")
    
    # 2. SN74181 Core
    g_terms, p_terms = [], []
    for i in range(4):
        inv_bi = circuit.add_gate("inv", X_TERM-100, 100+i*400)
        circuit.connect(b[i], inv_bi["inputs"][0]["id"])
        y1 = circuit.add_gate("and", X_TERM, 100+i*400, input_count=3); [circuit.connect(src, y1["inputs"][idx]["id"]) for idx, src in enumerate([a[i], b[i], s[0]])]
        y2 = circuit.add_gate("and", X_TERM, 200+i*400, input_count=3); [circuit.connect(src, y2["inputs"][idx]["id"]) for idx, src in enumerate([a[i], inv_bi["outputs"][0]["id"], s[1]])]
        og = circuit.add_gate("or", X_TERM+100, 150+i*400); circuit.connect(y1["outputs"][0]["id"], og["inputs"][0]["id"]); circuit.connect(y2["outputs"][0]["id"], og["inputs"][1]["id"]); g_terms.append(og["outputs"][0]["id"])
        y3 = circuit.add_gate("and", X_TERM, 300+i*400, input_count=2); circuit.connect(inv_bi["outputs"][0]["id"], y3["inputs"][0]["id"]); circuit.connect(s[2], y3["inputs"][1]["id"])
        y4 = circuit.add_gate("and", X_TERM, 400+i*400, input_count=2); circuit.connect(b[i], y4["inputs"][0]["id"]); circuit.connect(s[3], y4["inputs"][1]["id"])
        np = circuit.add_gate("nor", X_TERM+100, 350+i*400, input_count=3); [circuit.connect(src, np["inputs"][idx]["id"]) for idx, src in enumerate([y3["outputs"][0]["id"], y4["outputs"][0]["id"], a[i]])]; p_terms.append(np["outputs"][0]["id"])

    # 3. CLA
    carries = [ci]
    for i in range(4):
        cands = [g_terms[i]]
        for j in range(i):
            ca = circuit.add_gate("and", X_CLA, 100+i*500+j*100, input_count=i-j+1); circuit.connect(p_terms[i], ca["inputs"][0]["id"])
            for k in range(j+1, i): circuit.connect(p_terms[k], ca["inputs"][k-j]["id"])
            circuit.connect(g_terms[j], ca["inputs"][i-j]["id"]); cands.append(ca["outputs"][0]["id"])
        cci = circuit.add_gate("and", X_CLA, 200+i*500, input_count=i+2); circuit.connect(ci, cci["inputs"][0]["id"])
        for k in range(i+1): circuit.connect(p_terms[k], cci["inputs"][k+1]["id"])
        cands.append(cci["outputs"][0]["id"])
        ocl = circuit.add_gate("or", X_CLA+100, 150+i*500, input_count=len(cands))
        for idx, src in enumerate(cands): circuit.connect(src, ocl["inputs"][idx]["id"])
        carries.append(ocl["outputs"][0]["id"])

    # 4. ALU Result Basic
    alu_bin = []
    im0_d = circuit.add_gate("inv", X_BIT-50, 100); circuit.connect(m[0], im0_d["inputs"][0]["id"])
    for i in range(4):
        x1 = circuit.add_gate("xor", X_BIT, 100+i*300); circuit.connect(p_terms[i], x1["inputs"][0]["id"]); circuit.connect(g_terms[i], x1["inputs"][1]["id"])
        am = circuit.add_gate("and", X_BIT+50, 250+i*300); circuit.connect(carries[i], am["inputs"][0]["id"]); circuit.connect(im0_d["outputs"][0]["id"], am["inputs"][1]["id"])
        x2 = circuit.add_gate("xor", X_BIT+100, 200+i*300); circuit.connect(x1["outputs"][0]["id"], x2["inputs"][0]["id"]); circuit.connect(am["outputs"][0]["id"], x2["inputs"][1]["id"]); alu_bin.append(x2["outputs"][0]["id"])

    # 5. BCD Correction Logic
    gt9a = circuit.add_gate("and", X_BCD, 100); circuit.connect(alu_bin[3], gt9a["inputs"][0]["id"]); circuit.connect(alu_bin[2], gt9a["inputs"][1]["id"])
    gt9b = circuit.add_gate("and", X_BCD, 200); circuit.connect(alu_bin[3], gt9b["inputs"][0]["id"]); circuit.connect(alu_bin[1], gt9b["inputs"][1]["id"])
    bdet = circuit.add_gate("or", X_BCD+100, 150, input_count=3); circuit.connect(gt9a["outputs"][0]["id"], bdet["inputs"][0]["id"]); circuit.connect(gt9b["outputs"][0]["id"], bdet["inputs"][1]["id"]); circuit.connect(carries[4], bdet["inputs"][2]["id"])
    bcc = bdet["outputs"][0]["id"]
    bcd_f = [alu_bin[0]]
    x1b = circuit.add_gate("xor", X_BCD+200, 100); circuit.connect(alu_bin[1], x1b["inputs"][0]["id"]); circuit.connect(bcc, x1b["inputs"][1]["id"]); bcd_f.append(x1b["outputs"][0]["id"])
    c1b = circuit.add_gate("and", X_BCD+200, 200); circuit.connect(alu_bin[1], c1b["inputs"][0]["id"]); circuit.connect(bcc, c1b["inputs"][1]["id"])
    x2b = circuit.add_gate("xor", X_BCD+250, 150, input_count=3); circuit.connect(alu_bin[2], x2b["inputs"][0]["id"]); circuit.connect(bcc, x2b["inputs"][1]["id"]); circuit.connect(c1b["outputs"][0]["id"], x2b["inputs"][2]["id"]); bcd_f.append(x2b["outputs"][0]["id"])
    a2b = circuit.add_gate("or", X_BCD+300, 200, input_count=2)
    t1 = circuit.add_gate("and", X_BCD+250, 250); circuit.connect(alu_bin[2], t1["inputs"][0]["id"]); circuit.connect(bcc, t1["inputs"][1]["id"])
    t2 = circuit.add_gate("and", X_BCD+250, 300); circuit.connect(alu_bin[2], t2["inputs"][0]["id"]); circuit.connect(c1b["outputs"][0]["id"], t2["inputs"][1]["id"])
    circuit.connect(t1["outputs"][0]["id"], a2b["inputs"][0]["id"]); circuit.connect(t2["outputs"][0]["id"], a2b["inputs"][1]["id"])
    x3b = circuit.add_gate("xor", X_BCD+350, 250); circuit.connect(alu_bin[3], x3b["inputs"][0]["id"]); circuit.connect(a2b["outputs"][0]["id"], x3b["inputs"][1]["id"]); bcd_f.append(x3b["outputs"][0]["id"])

    # 6. ALU Core Mux (Bin vs BCD) via M2
    alu_res = []
    im2_d = circuit.add_gate("inv", X_BCD+400, 2000); circuit.connect(m[2], im2_d["inputs"][0]["id"])
    for i in range(4):
        bf = circuit.add_gate("and", X_BCD+450, 100+i*150); circuit.connect(alu_bin[i], bf["inputs"][0]["id"]); circuit.connect(im2_d["outputs"][0]["id"], bf["inputs"][1]["id"])
        cf = circuit.add_gate("and", X_BCD+450, 200+i*150); circuit.connect(bcd_f[i], cf["inputs"][0]["id"]); circuit.connect(m[2], cf["inputs"][1]["id"])
        rf = circuit.add_gate("or", X_BCD+500, 150+i*150); circuit.connect(bf["outputs"][0]["id"], rf["inputs"][0]["id"]); circuit.connect(cf["outputs"][0]["id"], rf["inputs"][1]["id"]); alu_res.append(rf["outputs"][0]["id"])

    # 7. Shifter
    shift_res = []
    for i in range(4):
        sm = circuit.add_gate("or", X_SHIFT, 100+i*400, input_count=4)
        ops = [(s[0], i-1, None), (s[1], i+1, None), (s[2], i+1, a[3]), (s[3], i+1, a[0])]
        for o_idx, (sel, b_idx, d) in enumerate(ops):
            sd = circuit.add_gate("and", X_SHIFT-100, (o_idx+1)*100+i*400); circuit.connect(sel, sd["inputs"][0]["id"])
            if 0 <= b_idx < 4: circuit.connect(a[b_idx], sd["inputs"][1]["id"])
            elif d and i == 3: circuit.connect(d, sd["inputs"][1]["id"])
            circuit.connect(sd["outputs"][0]["id"], sm["inputs"][o_idx]["id"])
        shift_res.append(sm["outputs"][0]["id"])

    # 8. Final Mode Mux (ALU vs Shift) via M1
    final_f = []
    im1_d = circuit.add_gate("inv", X_MODES, 2000); circuit.connect(m[1], im1_d["inputs"][0]["id"])
    for i in range(4):
        af = circuit.add_gate("and", X_MODES+100, 100+i*150); circuit.connect(alu_res[i], af["inputs"][0]["id"]); circuit.connect(im1_d["outputs"][0]["id"], af["inputs"][1]["id"])
        sf = circuit.add_gate("and", X_MODES+100, 200+i*150); circuit.connect(shift_res[i], sf["inputs"][0]["id"]); circuit.connect(m[1], sf["inputs"][1]["id"])
        rf = circuit.add_gate("or", X_MODES+200, 150+i*150); circuit.connect(af["outputs"][0]["id"], rf["inputs"][0]["id"]); circuit.connect(sf["outputs"][0]["id"], rf["inputs"][1]["id"]); final_f.append(rf["outputs"][0]["id"])
    
    # 9. Outputs & Flags
    for i in range(4): circuit.connect(final_f[i], circuit.add_output(X_OUT, 100+i*150, f"F{i}"))
    circuit.connect(carries[4], circuit.add_output(X_OUT, 700, "Co"))
    nz = circuit.add_gate("nor", X_FLAGS, 100, input_count=4); [circuit.connect(final_f[i], nz["inputs"][i]["id"]) for i in range(4)]
    circuit.connect(nz["outputs"][0]["id"], circuit.add_output(X_OUT, 800, "Z"))
    circuit.connect(final_f[3], circuit.add_output(X_OUT, 900, "N"))
    xv = circuit.add_gate("xor", X_FLAGS, 300); circuit.connect(carries[3], xv["inputs"][0]["id"]); circuit.connect(carries[4], xv["inputs"][1]["id"]); circuit.connect(xv["outputs"][0]["id"], circuit.add_output(X_OUT, 1000, "V"))
    circuit.connect(bcc, circuit.add_output(X_OUT, 1100, "C_BCD"))
    return circuit.to_json()

if __name__ == "__main__":
    alu_json = generate_alu()
    target = os.path.abspath(os.path.join(os.path.dirname(__file__), "../assets/4 bit ALU.json"))
    with open(target, "w") as f: json.dump(alu_json, f, indent=2)
    print(f"Generated {target}")
