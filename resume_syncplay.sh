# Configuration file
CONFIG_FILE="config.txt"

# Source the configuration file
source "$CONFIG_FILE"

# Path to the TXT file with Raspberry Pi IP addresses
PI_MAP_FILE="pi_map.txt"

# Function to kill the mpv process
kill_mpv() {
    local pi_ip=$1
    # Kill the 'mpv' process
    local command="pkill -x mpv || killall mpv"
    sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "$command"
}

# Read Raspberry Pi IP addresses from the TXT file and kill mpv on each
while IFS='=' read -r pi_id pi_ip; do
    echo "Killing mpv on Raspberry Pi with IP: $pi_ip"
    kill_mpv "$pi_ip"
done < "$PI_MAP_FILE"

echo "mpv kill process completed."


# Function to kill the process using a specific port
kill_process_on_port() {
    local server_ip=$1
    local port=$2
    # Find and kill the process using the specified port
    local command="lsof -t -i tcp:$port | xargs -r kill"
    sshpass -p "$PI_PASSWORD" ssh "$PI_USER@$server_ip" "$command"
}

# Kill process running on port 5500
echo "Killing process running on port $SYNCPLAY_SERVER_PORT on $SYNCPLAY_SERVER_IP"
kill_process_on_port $SYNCPLAY_SERVER_IP $SYNCPLAY_SERVER_PORT

echo "Process on port $SYNCPLAY_SERVER_PORT killed."