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

for pi_id in ${(on)${(k)PI_MAP}}; do
    pi_ip=${PI_MAP[$pi_id]}
    echo "Attempting to reboot Raspberry Pi with IP: $pi_ip"
    reboot_pi "$pi_ip"
done

echo "✅ Reboot process for all reachable Raspberry Pis initiated."
