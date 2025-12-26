import base64
import os
import re

html_path = r"F:\AION-ZERO\design-output\AION_ZERO_PITCH_DECK.html"
img_dir = r"F:\AION-ZERO\design-output\img"

print(f"Reading {html_path}...")
with open(html_path, 'r', encoding='utf-8') as f:
    content = f.read()

def replace_img(match):
    filename = match.group(1)
    filepath = os.path.join(img_dir, filename)
    print(f"Embedding {filename}...")
    if os.path.exists(filepath):
        with open(filepath, "rb") as img_file:
            b64 = base64.b64encode(img_file.read()).decode('utf-8')
            return f'src="data:image/png;base64,{b64}"'
    else:
        print(f"Warning: {filename} not found at {filepath}")
    return match.group(0)

# Regex to find src="img/filename.png"
new_content = re.sub(r'src="img/([^"]+)"', replace_img, content)

with open(html_path, 'w', encoding='utf-8') as f:
    f.write(new_content)

print(f"Success! {html_path} is now a standalone file.")
