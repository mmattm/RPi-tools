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

# Function to get the internal clock hour of the Raspberry Pi
get_clock_hour() {
    local pi_ip=$1
    local clock_timestamp=$(sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "date +%s" 2>/dev/null)
    if [ -n "$clock_timestamp" ]; then
        echo "\"clock\": $clock_timestamp"
    else
        echo "\"clock\": false"
    fi
}

# Function to check if Syncplay process is running on the Raspberry Pi
check_syncplay() {
    local pi_ip=$1
    local syncplay_status=$(sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "pgrep -x mpv > /dev/null && echo true || echo false" 2>/dev/null)
    if [ -n "$syncplay_status" ]; then
        echo "\"syncplay\": $syncplay_status"
    else
        echo "\"syncplay\": false"
    fi
}

# Function to check if Syncplay server process is running on the Raspberry Pi
check_syncplay_server() {
    local pi_ip=$1
    local syncplay_status=$(sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "pgrep -x syncplay-server > /dev/null && echo true || echo false" 2>/dev/null)
    if [ -n "$syncplay_status" ]; then
        echo "\"syncplay-server\": $syncplay_status"
    else
        echo "\"syncplay-server\": false"
    fi
}

# Function to check if a cron schedule is active and get the hours
check_cron_schedule() {
    local pi_ip=$1
    local cron_job=$(sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "sudo crontab -l | grep 'sudo tee /sys/class/rtc/rtc0/wakealarm'")
    if [[ -n "$cron_job" ]]; then
        # Remove everything after the first '|' character
        cron_job=${cron_job%%|*}
        local cron_hour=$(echo "$cron_job" | awk '{print $2}')
        local cron_minute=$(echo "$cron_job" | awk '{print $1}')
        local sleep_time=$(echo "$cron_job" | awk '{print $7}' | cut -d'+' -f2)
        if [[ -n "$sleep_time" && "$sleep_time" =~ ^[0-9]+$ ]]; then
            local sleep_minutes=$((sleep_time / 60))
            echo "\"cron\": {\"hour\": \"$cron_hour\", \"minute\": \"$cron_minute\", \"sleep_minutes\": \"$sleep_minutes\"}"
        else
            echo "\"cron\": {\"active\": true, \"hour\": \"$cron_hour\", \"minute\": \"$cron_minute\", \"sleep_minutes\": \"$sleep_time\}"
        fi
    else
        echo "\"cron\": false"
    fi
}



# Function to get both the clock hour and Syncplay status
get_infos() {
    local pi_ip=$1
    echo "{\"$pi_ip\": {"
    if ping -c 1 "$pi_ip" &>/dev/null; then
        echo "    $(get_clock_hour "$pi_ip"),"
        echo "    $(check_syncplay "$pi_ip"),"
        echo "    $(check_syncplay_server "$pi_ip"),"
        echo "    $(check_cron_schedule "$pi_ip")"
    else
        echo "    \"clock\": false,"
        echo "    \"syncplay\": false,"
        echo "    \"syncplay-server\": false,"
        echo "    \"cron\": false"
    fi
    echo "}}"
}

# Main script logic
if [[ -n "$1" ]]; then
    # If an argument is provided, get the infos for the specific Raspberry Pi by ID
    pi_id=$1
    pi_ip=${PI_MAP[$pi_id]}
    if [[ -n "$pi_ip" ]]; then
        get_infos "$pi_ip"
    else
        echo "{\"error\": \"Invalid Raspberry Pi ID: $pi_id\"}"
    fi
else
    # If no argument is provided, get the infos for all Raspberry Pis
    echo "["
    first=true
    for pi_id in ${(on)${(k)PI_MAP}}; do
        pi_ip=${PI_MAP[$pi_id]}
        if [[ -n "$pi_ip" ]]; then
            if [ "$first" = true ]; then
                first=false
            else
                echo ","
            fi
            echo "    $(get_infos "$pi_ip")"
        fi
    done
    echo "]"
fi
