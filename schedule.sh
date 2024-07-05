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
typeset -A PI_MAP

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

# Function to add cron jobs
# add_cron_jobs() {
#     local pi_ip=$1
#     local shutdown_time=$2
#     local wake_minutes=$3

#     echo "Configuring cron jobs for Raspberry Pi at $pi_ip..."

#     # Calculate wake alarm time in seconds
#     wake_seconds=$((wake_minutes * 60))

#     # Add cron jobs for wake alarm and shutdown
#     sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" << EOF
# echo '$PI_PASSWORD' | sudo -S bash -c "(sudo crontab -l 2>/dev/null | grep -v 'echo +.* | sudo tee /sys/class/rtc/rtc0/wakealarm' | grep -v 'sudo halt'; echo '$shutdown_time echo +$wake_seconds | sudo tee /sys/class/rtc/rtc0/wakealarm && sudo halt') | sudo crontab -"
# EOF
# }

# # Function to remove cron jobs
# remove_cron_jobs() {
#     local pi_ip=$1

#     echo "Removing cron jobs for Raspberry Pi at $pi_ip..."

#     # Remove specific cron jobs related to wake alarm and shutdown
#     sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" << EOF
# echo '$PI_PASSWORD' | sudo -S bash -c "(sudo crontab -l | grep -v 'echo +.* | sudo tee /sys/class/rtc/rtc0/wakealarm' | grep -v 'sudo halt') | sudo crontab -"
# EOF
# }

add_cron_jobs() {
    local pi_ip=$1
    local shutdown_time=$2
    local wake_minutes=$3

    echo "Configuring cron jobs for Raspberry Pi at $pi_ip..."

    # Calculate wake alarm time in seconds
    wake_seconds=$((wake_minutes * 60))

    # Add cron jobs for wake alarm and shutdown
    sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" << EOF
echo '$PI_PASSWORD' | sudo -S bash -c "(sudo crontab -l 2>/dev/null | grep -v 'echo 0 | sudo tee /sys/class/rtc/rtc0/wakealarm' | grep -v 'echo +.* | sudo tee /sys/class/rtc/rtc0/wakealarm' | grep -v 'sudo halt'; echo '$shutdown_time echo 0 | sudo tee /sys/class/rtc/rtc0/wakealarm && echo +$wake_seconds | sudo tee /sys/class/rtc/rtc0/wakealarm && sudo halt') | sudo crontab -"
EOF
}


remove_cron_jobs() {
    local pi_ip=$1

    echo "Removing cron jobs for Raspberry Pi at $pi_ip..."

    # Remove specific cron jobs related to wake alarm and shutdown
    sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" << EOF
echo '$PI_PASSWORD' | sudo -S bash -c "(sudo crontab -l | grep -v 'echo 0 | sudo tee /sys/class/rtc/rtc0/wakealarm' | grep -v 'echo +.* | sudo tee /sys/class/rtc/rtc0/wakealarm' | grep -v 'sudo halt') | sudo crontab -"
EOF
}


# Parse command-line arguments
disable_flag=0
shutdown_hour=""
shutdown_minute=""
wake_minutes=""
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -s|--shutdown-hour) shutdown_hour="$2"; shift ;;
        -m|--shutdown-minute) shutdown_minute="$2"; shift ;;
        -w|--wake-minutes) wake_minutes="$2"; shift ;;
        --disable) disable_flag=1 ;;
        *) echo "Usage: $0 [--disable] [-s|--shutdown-hour SHUTDOWN_HOUR] [-m|--shutdown-minute SHUTDOWN_MINUTE] [-w|--wake-minutes WAKE_MINUTES]"; exit 1 ;;
    esac
    shift
done

# Ensure all required arguments are provided unless disabling
if [ "$disable_flag" -eq 0 ] && { [ -z "$shutdown_hour" ] || [ -z "$shutdown_minute" ] || [ -z "$wake_minutes" ]; }; then
    echo "Usage: $0 [--disable] [-s|--shutdown-hour SHUTDOWN_HOUR] [-m|--shutdown-minute SHUTDOWN_MINUTE] [-w|--wake-minutes WAKE_MINUTES]"
    exit 1
fi

# Format cron times
shutdown_time="$shutdown_minute $shutdown_hour * * *"

# Add or remove cron jobs for each Raspberry Pi
for pi_id in "${(@k)PI_MAP}"; do
    pi_ip=${PI_MAP[$pi_id]}
    echo "Attempting to configure cron jobs for Raspberry Pi with IP: $pi_ip"
    
    if is_pi_online "$pi_ip"; then
        if [ "$disable_flag" -eq 1 ]; then
            echo "Disabling cron jobs for Raspberry Pi at $pi_ip..."
            remove_cron_jobs "$pi_ip"  
        else
            echo "Raspberry Pi at $pi_ip is online. Proceeding with configuration..."
            add_cron_jobs "$pi_ip" "$shutdown_time" "$wake_minutes"
        fi
    else
        echo "Raspberry Pi at $pi_ip is not online. Skipping configuration."
    fi
done

echo "✅ Cron job configuration process for all reachable Raspberry Pis initiated."

# Usage
# ./schedule.sh --disable
# ./schedule.sh --shutdown-hour 16 --shutdown-minute 28 --wake-minutes 2 (Minimum 1)

# on Raspberry Pi checkup
# sudo crontab -e
