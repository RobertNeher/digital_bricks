import json
import uuid

def generate_bcd_to_7seg_json():
    components = []
    connections = []

    def add_comp(name, ctype, x, y, input_count=2, label=None):
        comp_id = str(uuid.uuid4())
        comp = {
            "id": comp_id,
            "name": name,
            "type": ctype,
            "position_dx": float(x),
            "position_dy": float(y),
            "inputs": [],
            "outputs": []
        }
        
        # Corrected Mapping from logic_component.dart:
        # 0: and, 2: or, 6: inverter, 12: circuitInput, 13: circuitOutput
        
        if ctype == 12: # circuitInput
            comp["label"] = label or "IN"
            comp["outputs"].append({"id": f"{comp_id}-out-0", "componentId": comp_id, "type": 1, "value": False})
        elif ctype == 13: # circuitOutput
            comp["label"] = label or "OUT"
            comp["inputs"].append({"id": f"{comp_id}-in-0", "componentId": comp_id, "type": 0, "value": False})
        elif ctype == 6: # inverter
            comp["inputs"].append({"id": f"{comp_id}-in-0", "componentId": comp_id, "type": 0, "value": False})
            comp["outputs"].append({"id": f"{comp_id}-out-0", "componentId": comp_id, "type": 1, "value": False})
        else: # multi-input gates (AND=0, OR=2)
            comp["inputCount"] = input_count
            for i in range(input_count):
                comp["inputs"].append({"id": f"{comp_id}-in-{i}", "componentId": comp_id, "type": 0, "value": False})
            comp["outputs"].append({"id": f"{comp_id}-out-0", "componentId": comp_id, "type": 1, "value": False})
            
        components.append(comp)
        return comp

    def connect(src_comp, target_comp, target_pin_idx=0):
        conn_id = str(uuid.uuid4())
        connections.append({
            "id": conn_id,
            "sourcePinId": src_comp["outputs"][0]["id"],
            "targetPinId": target_comp["inputs"][target_pin_idx]["id"]
        })

    # 1. Inputs (A=MSB/Bit3, B=Bit2, C=Bit1, D=LSB/Bit0)
    in_a = add_comp("IN_A", 12, 100, 100, label="A")
    in_b = add_comp("IN_B", 12, 100, 250, label="B")
    in_c = add_comp("IN_C", 12, 100, 400, label="C")
    in_d = add_comp("IN_D", 12, 100, 550, label="D")

    # 2. Inverters
    not_b = add_comp("NOT_B", 6, 250, 270)
    connect(in_b, not_b)
    not_c = add_comp("NOT_C", 6, 250, 420)
    connect(in_c, not_c)
    not_d = add_comp("NOT_D", 6, 250, 570)
    connect(in_d, not_d)

    # 3. Intermediate Gates for Outputs
    # OUT_A = A | C | (B & D) | (~B & ~D)
    and_bd = add_comp("AND_BD", 0, 400, 50)
    connect(in_b, and_bd, 0)
    connect(in_d, and_bd, 1)
    
    and_nbnd = add_comp("AND_NBND", 0, 400, 120)
    connect(not_b, and_nbnd, 0)
    connect(not_d, and_nbnd, 1)
    
    or_a = add_comp("OR_A", 2, 600, 80, input_count=4)
    connect(in_a, or_a, 0)
    connect(in_c, or_a, 1)
    connect(and_bd, or_a, 2)
    connect(and_nbnd, or_a, 3)

    # OUT_B = ~B | (~C & ~D) | (C & D)
    and_ncnd = add_comp("AND_NCND", 0, 400, 200)
    connect(not_c, and_ncnd, 0)
    connect(not_d, and_ncnd, 1)
    
    and_cd = add_comp("AND_CD", 0, 400, 270)
    connect(in_c, and_cd, 0)
    connect(in_d, and_cd, 1)
    
    or_b = add_comp("OR_B", 2, 600, 230, input_count=3)
    connect(not_b, or_b, 0)
    connect(and_ncnd, or_b, 1)
    connect(and_cd, or_b, 2)

    # OUT_C = B | ~C | D
    or_c = add_comp("OR_C", 2, 600, 350, input_count=3)
    connect(in_b, or_c, 0)
    connect(not_c, or_c, 1)
    connect(in_d, or_c, 2)

    # OUT_D = A | (~B & ~D) | (~B & C) | (C & ~D) | (B & ~C & D)
    and_nbnd_d = add_comp("AND_NBND_D", 0, 400, 400)
    connect(not_b, and_nbnd_d, 0)
    connect(not_d, and_nbnd_d, 1)
    
    and_nbc = add_comp("AND_NBC", 0, 400, 470)
    connect(not_b, and_nbc, 0)
    connect(in_c, and_nbc, 1)
    
    and_cnd = add_comp("AND_CND", 0, 400, 540)
    connect(in_c, and_cnd, 0)
    connect(not_d, and_cnd, 1)
    
    and_bncd = add_comp("AND_BNCD", 0, 400, 610, input_count=3)
    connect(in_b, and_bncd, 0)
    connect(not_c, and_bncd, 1)
    connect(in_d, and_bncd, 2)
    
    or_d = add_comp("OR_D", 2, 600, 480, input_count=5)
    connect(in_a, or_d, 0)
    connect(and_nbnd_d, or_d, 1)
    connect(and_nbc, or_d, 2)
    connect(and_cnd, or_d, 3)
    connect(and_bncd, or_d, 4)

    # OUT_E = (~B & ~D) | (C & ~D)
    and_nbnd_e = add_comp("AND_NBND_E", 0, 400, 700)
    connect(not_b, and_nbnd_e, 0)
    connect(not_d, and_nbnd_e, 1)
    
    and_cnd_e = add_comp("AND_CND_E", 0, 400, 770)
    connect(in_c, and_cnd_e, 0)
    connect(not_d, and_cnd_e, 1)
    
    or_e = add_comp("OR_E", 2, 600, 730, input_count=2)
    connect(and_nbnd_e, or_e, 0)
    connect(and_cnd_e, or_e, 1)

    # OUT_F = A | (~C & ~D) | (B & ~C) | (B & ~D)
    and_ncnd_f = add_comp("AND_NCND_F", 0, 400, 850)
    connect(not_c, and_ncnd_f, 0)
    connect(not_d, and_ncnd_f, 1)
    
    and_bnc = add_comp("AND_BNC", 0, 400, 920)
    connect(in_b, and_bnc, 0)
    connect(not_c, and_bnc, 1)
    
    and_bnd = add_comp("AND_BND", 0, 400, 990)
    connect(in_b, and_bnd, 0)
    connect(not_d, and_bnd, 1)
    
    or_f = add_comp("OR_F", 2, 600, 920, input_count=4)
    connect(in_a, or_f, 0)
    connect(and_ncnd_f, or_f, 1)
    connect(and_bnc, or_f, 2)
    connect(and_bnd, or_f, 3)

    # OUT_G = A | (B & ~C) | (~B & C) | (C & ~D)
    and_bnc_g = add_comp("AND_BNC_G", 0, 400, 1100)
    connect(in_b, and_bnc_g, 0)
    connect(not_c, and_bnc_g, 1)
    
    and_nbc_g = add_comp("AND_NBC_G", 0, 400, 1170)
    connect(not_b, and_nbc_g, 0)
    connect(in_c, and_nbc_g, 1)
    
    and_cnd_g = add_comp("AND_CND_G", 0, 400, 1240)
    connect(in_c, and_cnd_g, 0)
    connect(not_d, and_cnd_g, 1)
    
    or_g = add_comp("OR_G", 2, 600, 1170, input_count=4)
    connect(in_a, or_g, 0)
    connect(and_bnc_g, or_g, 1)
    connect(and_nbc_g, or_g, 2)
    connect(and_cnd_g, or_g, 3)

    # 4. Outputs
    out_a = add_comp("OUT_A", 13, 850, 80, label="OUT_A")
    connect(or_a, out_a)
    out_b = add_comp("OUT_B", 13, 850, 230, label="OUT_B")
    connect(or_b, out_b)
    out_c = add_comp("OUT_C", 13, 850, 350, label="OUT_C")
    connect(or_c, out_c)
    out_d = add_comp("OUT_D", 13, 850, 480, label="OUT_D")
    connect(or_d, out_d)
    out_e = add_comp("OUT_E", 13, 850, 730, label="OUT_E")
    connect(or_e, out_e)
    out_f = add_comp("OUT_F", 13, 850, 920, label="OUT_F")
    connect(or_f, out_f)
    out_g = add_comp("OUT_G", 13, 850, 1170, label="OUT_G")
    connect(or_g, out_g)

    # Root Structure (Blueprint style)
    blueprint = {
        "components": components,
        "connections": connections
    }

    print(json.dumps(blueprint, indent=2))

if __name__ == "__main__":
    generate_bcd_to_7seg_json()
