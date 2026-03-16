import json
import os
import glob

def fix_assets():
    assets_dir = 'assets'
    files = glob.glob(os.path.join(assets_dir, '*.json'))
    
    for file_path in files:
        print(f"Checking {file_path}...")
        try:
            with open(file_path, 'r') as f:
                data = json.load(f)
        except Exception as e:
            print(f"  Error reading {file_path}: {e}")
            continue

        if 'components' not in data:
            continue

        changed = False
        
        # Step 1: Fix component types and gather port candidates
        inputs_found = [] # (y_pos, pin_id, label)
        outputs_found = [] # (y_pos, pin_id, label)

        def process_components(components):
            nonlocal changed
            for comp in components:
                old_type = comp.get('type')
                # Apply heuristics similar to fix_assets.dart
                new_type = old_type
                
                # Heuristics
                if 'text' in comp:
                    new_type = 15
                elif 'blueprint' in comp or 'internalComponents' in comp:
                    new_type = 16
                elif 'frequency' in comp:
                    new_type = 7
                elif 'storedValue' in comp:
                    # Determine FF type
                    name = str(comp.get('name', '')).lower()
                    if 'jk' in name: new_type = 18
                    elif 'rs' in name: new_type = 19
                    else: new_type = 17 # Default to D
                
                # Labels/Name heuristics
                name = str(comp.get('name', '')).lower()
                label = str(comp.get('label', '')).lower()
                
                # Check for input/output candidates
                comp_inputs = comp.get('inputs', [])
                comp_outputs = comp.get('outputs', [])
                
                if len(comp_inputs) == 0 and len(comp_outputs) == 1:
                    if old_type == 12 or 'input' in name or 'input' in label or 'fan' in name:
                        new_type = 12
                elif len(comp_inputs) == 1 and len(comp_outputs) == 0:
                    if old_type == 13 or 'output' in name or 'output' in label or 'fan' in name:
                        new_type = 13
                
                if new_type != old_type:
                    comp['type'] = new_type
                    changed = True
                
                # Track for port list rebuilding
                if new_type == 12:
                    y = comp.get('position_dy', 0)
                    pin_id = comp_outputs[0]['id'] if comp_outputs else f"{comp['id']}-out-0"
                    lbl = comp.get('label') or f"In {len(inputs_found)}"
                    inputs_found.append((y, pin_id, lbl))
                elif new_type == 13:
                    y = comp.get('position_dy', 0)
                    pin_id = comp_inputs[0]['id'] if comp_inputs else f"{comp['id']}-in-0"
                    lbl = comp.get('label') or f"Out {len(outputs_found)}"
                    outputs_found.append((y, pin_id, lbl))
                
                # Recursively process blueprints
                if 'blueprint' in comp:
                    if process_components(comp['blueprint'].get('components', [])):
                        changed = True

        process_components(data['components'])

        # Step 2: Rebuild inputPorts / outputPorts if missing or mismatched
        # Sort by vertical position
        inputs_found.sort()
        outputs_found.sort()

        new_input_ports = [x[1] for x in inputs_found]
        new_output_ports = [x[1] for x in outputs_found]
        new_input_labels = [x[2] for x in inputs_found]
        new_output_labels = [x[2] for x in outputs_found]

        if data.get('inputPorts') != new_input_ports:
            data['inputPorts'] = new_input_ports
            data['inputLabels'] = new_input_labels
            changed = True
        if data.get('outputPorts') != new_output_ports:
            data['outputPorts'] = new_output_ports
            data['outputLabels'] = new_output_labels
            changed = True

        if changed:
            with open(file_path, 'w') as f:
                json.dump(data, f, indent=2)
            print(f"  Fixed {file_path}")
        else:
            print(f"  No changes for {file_path}")

if __name__ == "__main__":
    fix_assets()
