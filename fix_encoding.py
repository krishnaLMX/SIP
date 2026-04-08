import os
import glob

def fix_encoding():
    for root, _, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                try:
                    with open(path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    if 'â‚¹' in content:
                        print(f"Fixing {path}")
                        with open(path, 'w', encoding='utf-8') as f:
                            f.write(content.replace('â‚¹', '₹'))
                except Exception as e:
                    print(f"Error reading {path}: {e}")

if __name__ == '__main__':
    fix_encoding()
