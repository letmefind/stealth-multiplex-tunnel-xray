#!/usr/bin/env python3

import re

# Read the file
with open('/Users/arash/Tunnel-iran-kharej/scripts/install_a.sh', 'r') as f:
    content = f.read()

# Find the problematic section and replace it
pattern = r'(\s+config=\$\(echo "\$config" \| jq \'\.inbounds \+= \[.*?\]\'\)\s+)(.*?)(\s+# Write configuration file)'

def replacement(match):
    before = match.group(1)
    after = match.group(3)
    return before + after

# Apply the replacement
new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)

# Write back to file
with open('/Users/arash/Tunnel-iran-kharej/scripts/install_a.sh', 'w') as f:
    f.write(new_content)

print("Configuration fixed!")
