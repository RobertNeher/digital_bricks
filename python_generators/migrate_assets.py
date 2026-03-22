import json
import os

def migrate_component(comp):
    if 'blueprint' in comp:
        bp = comp['blueprint']
        comp['internalComponents'] = bp.get('components', [])
        comp['internalConnections'] = bp.get('connections', [])
        comp['name'] = bp.get('name', comp.get('name', 'IC'))
        del comp['blueprint']
        
        # Recursively migrate nested components
        for child in comp['internalComponents']:
            migrate_component(child)

def migrate_file(filepath):
    print(f"Migrating {filepath}...")
    with open(filepath, 'r', encoding='utf-8') as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError as e:
            print(f"Error decoding {filepath}: {e}")
            return

    # Check root level components
    if 'components' in data:
        for comp in data['components']:
            migrate_component(comp)
            
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)

def main():
    assets_dir = r"c:\Users\Robert\Documents\digital_bricks\assets"
    for filename in os.listdir(assets_dir):
        if filename.endswith(".json"):
            filepath = os.path.join(assets_dir, filename)
            # We already know which files have "blueprint" from rg, but let's process all for safety
            migrate_file(filepath)

if __name__ == "__main__":
    main()
