#!/bin/zsh

# Determine the directory where the script is located
SCRIPT_DIR=$(dirname "$0")

# Configuration file
CONFIG_FILE="$SCRIPT_DIR/config.txt"

# Source the configuration file
source "$CONFIG_FILE"

# Path to the TXT file with Raspberry Pi IP addresses
PI_MAP_FILE="$SCRIPT_DIR/pi_map.txt"

# Initialize an associative array for the PI_MAP
declare -A PI_MAP

# Read the pi_map.txt file and populate the PI_MAP associative array
while IFS='=' read -r key value; do
    PI_MAP[$key]=$value
done < "$PI_MAP_FILE"

# Function to control mpv (pause/play) on the first Raspberry Pi
control_mpv() {
    local pi_ip=$1
    echo "Attempting to toggle pause/play on Raspberry Pi with IP: $pi_ip"
    local command="echo '{ \"command\": [\"cycle\", \"pause\"] }' | socat - /tmp/mpvsocket"
    sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "$command"
}


# Control mpv (pause/play) on the first Raspberry Pi
first_pi_ip=${PI_MAP[$(echo ${(k)PI_MAP} | awk '{print $1}')]}
echo "Controlling mpv on the first Raspberry Pi with IP: $first_pi_ip"
control_mpv "$first_pi_ip"

