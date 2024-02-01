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
done < pi_map.txt

# Function to kill the mpv process
kill_mpv() {
    local pi_ip=$1
    echo "Attempting to kill mpv on Raspberry Pi with IP: $pi_ip"
    # Kill the 'mpv' process
    local command="pkill -x mpv || killall mpv"
    sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "$command"
}

# Loop through each Raspberry Pi IP address and kill mpv on each
for pi_id in ${(on)${(k)PI_MAP}}; do
    pi_ip=${PI_MAP[$pi_id]}
    echo "Killing mpv on Raspberry Pi with IP: $pi_ip"
    kill_mpv "$pi_ip"
done

echo "✅ mpv kill process completed on all Raspberry Pis."


# Read Raspberry Pi IP addresses from the TXT file and kill mpv on each
# while IFS='=' read -r pi_id pi_ip; do
#     if [[ ! -z "$pi_ip" ]]; then
#         kill_mpv "$pi_ip"
#     fi
# done < "$PI_MAP_FILE"


# Function to kill the process using a specific port
kill_process_on_port() {
    local server_ip=$1
    local port=$2
    echo "Attempting to kill process on port $port on server $server_ip"
    # Find and kill the process using the specified port
    local command="lsof -t -i tcp:$port | xargs -r kill"
    sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$server_ip" "$command"
}

# Kill process running on port 5500
echo "–––––––––––––––––––––––––––"
echo "Killing syncplay server running on port $SYNCPLAY_SERVER_PORT on $SYNCPLAY_SERVER_IP"
kill_process_on_port "$SYNCPLAY_SERVER_IP" "$SYNCPLAY_SERVER_PORT"

echo "Syncplay server on port $SYNCPLAY_SERVER_PORT killed."