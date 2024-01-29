#!/bin/zsh

# Configuration file
CONFIG_FILE="config.txt"

# Source the configuration file
source "$CONFIG_FILE"

# Path to the TXT file with Raspberry Pi IP addresses
PI_MAP_FILE="pi_map.txt"

# Function to reboot a Raspberry Pi
reboot_pi() {
    local pi_ip=$1
    # Reboot the Raspberry Pi
    local command="sudo reboot"
    sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "$command"
}

# Read Raspberry Pi IP addresses from the TXT file and reboot each
while IFS='=' read -r pi_id pi_ip; do
    echo "Rebooting Raspberry Pi with IP: $pi_ip"
    reboot_pi "$pi_ip"
done < "$PI_MAP_FILE"

echo "Reboot process for all Raspberry Pis initiated."