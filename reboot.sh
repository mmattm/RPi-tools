#!/bin/zsh

# Configuration file
CONFIG_FILE="config.txt"

# Source the configuration file
source "$CONFIG_FILE"

# Path to the TXT file with Raspberry Pi IP addresses
PI_MAP_FILE="pi_map.txt"

declare -A PI_MAP
while IFS='=' read -r key value; do
    PI_MAP[$key]=$value
done < "$PI_MAP_FILE"

# Function to check if Raspberry Pi is online
is_pi_online() {
    local pi_ip=$1
    # Ping the Raspberry Pi to check connectivity
    ping -c 1 $pi_ip &> /dev/null
    return $?
}

# Function to reboot a Raspberry Pi
reboot_pi() {
    local pi_ip=$1
    # Check if Raspberry Pi is online
    if is_pi_online "$pi_ip"; then
        echo "Raspberry Pi at $pi_ip is online. Proceeding with reboot..."
        local command="sudo reboot"
        sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "echo '$PI_PASSWORD' | sudo -S reboot"
    else
        echo "😴 Raspberry Pi at $pi_ip is not online. Skipping reboot."
    fi
}

for pi_id in ${(on)${(k)PI_MAP}}; do
    pi_ip=${PI_MAP[$pi_id]}
    echo "Attempting to reboot Raspberry Pi with IP: $pi_ip"
    reboot_pi "$pi_ip"
done

echo "✅ Reboot process for all reachable Raspberry Pis initiated."