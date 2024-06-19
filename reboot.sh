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

# Function to check if Raspberry Pi is online
is_pi_online() {
    local pi_ip=$1
    # Ping the Raspberry Pi to check connectivity
    ping -c 1 $pi_ip &> /dev/null
    return $?
}

# Function to get the current date and time in a format suitable for the `date` command
get_current_time() {
    date +"%Y-%m-%d %H:%M:%S"
}

current_time=$(get_current_time)

# Function to set the clock of a Raspberry Pi
set_clock() {
    local pi_ip=$1
    echo "Setting clock for Raspberry Pi at $pi_ip to $current_time..."
    sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "echo '$PI_PASSWORD' | sudo -S date -s '$current_time'"
}

# Function to disable update-manager notifications on a Raspberry Pi
disable_update_notifications() {
    local pi_ip=$1
    echo "Disabling update-manager notifications for Raspberry Pi at $pi_ip..."
    sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "dconf write /org/gnome/desktop/notifications/application/update-manager/enable false"
}

# Function to reboot a Raspberry Pi
reboot_pi() {
    local pi_ip=$1
    # Check if Raspberry Pi is online
    if is_pi_online "$pi_ip"; then
        echo "Raspberry Pi at $pi_ip is online. ⏰ Proceeding with clock sync and reboot..."
        set_clock "$pi_ip"
        disable_update_notifications "$pi_ip"
        sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "echo '$PI_PASSWORD' | sudo -S reboot"
    else
        echo "😴 Raspberry Pi at $pi_ip is not online. Skipping reboot."
    fi
}

# Main script logic
if [[ -n "$1" ]]; then
    # If an argument is provided, reboot the specific Raspberry Pi by ID
    pi_id=$1
    pi_ip=${PI_MAP[$pi_id]}
    if [[ -n "$pi_ip" ]]; then
        echo "Attempting to reboot Raspberry Pi with ID: $pi_id and IP: $pi_ip"
        reboot_pi "$pi_ip"
    else
        echo "❌ Invalid Raspberry Pi ID: $pi_id"
    fi
else
    # If no argument is provided, reboot all Raspberry Pis
    for pi_id in ${(on)${(k)PI_MAP}}; do
        pi_ip=${PI_MAP[$pi_id]}
        echo "Attempting to reboot Raspberry Pi with IP: $pi_ip"
        reboot_pi "$pi_ip"
    done
fi

echo "✅ Reboot process initiated."

