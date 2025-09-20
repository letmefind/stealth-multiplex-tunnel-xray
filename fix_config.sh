#!/bin/bash

# Fix Server A configuration - replace the old outbound section
sed -i '/# Add outbound based on protocol and security/,/# Write configuration file/c\
    # Write configuration file\
    echo "$config" | jq '"'"'.'"'"' > "$config_file"\
    chmod 644 "$config_file"\
    \
    log_success "Xray configuration created: $config_file"\
}' /Users/arash/Tunnel-iran-kharej/scripts/install_a.sh

echo "Configuration fixed!"
