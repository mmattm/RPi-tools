#!/bin/zsh

# Configuration file
CONFIG_FILE="config.txt"

# Source the configuration file
source "$CONFIG_FILE"


# Assuming the TXT file is named pi_map.txt
declare -A PI_MAP
while IFS='=' read -r key value; do
    PI_MAP[$key]=$value
done < pi_map.txt


kill_process_on_port() {
    local server_ip=$1
    local port=$2
    # Find and kill the process using the specified port
    local command="lsof -t -i tcp:$port | xargs -r kill"
    sshpass -p "$PI_PASSWORD" ssh "$PI_USER@$server_ip" "$command"
}

echo "\n❌ ––––––––––––––––––––––––––– \n"

# Kill process running on port 5500
echo "Killing server running on port $SYNCPLAY_SERVER_PORT on $SYNCPLAY_SERVER_IP"
kill_process_on_port $SYNCPLAY_SERVER_IP $SYNCPLAY_SERVER_PORT

echo "Server on port $SYNCPLAY_SERVER_PORT killed."

echo "\n🚀 ––––––––––––––––––––––––––– \n"

echo "Starting Syncplay server on $SYNCPLAY_SERVER_IP"
sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$SYNCPLAY_SERVER_IP" "nohup syncplay-server --port $SYNCPLAY_SERVER_PORT > /dev/null 2>&1 &"


# Loop through each Raspberry Pi IP address and run Syncplay client
for pi_id in ${(k)PI_MAP}; do
    pi_ip=${PI_MAP[$pi_id]}
    video_file="$VIDEO_PATH/$pi_id.mp4"

    echo "\n🤖 ––––––––––––––––––––––––––– \n"

    echo "Checking if Raspberry Pi at $pi_ip is reachable..."

    # Check if the Raspberry Pi IP address is reachable
    if ping -c 1 "$pi_ip" &>/dev/null; then
        echo "Raspberry Pi at $pi_ip is reachable. Checking if video file $video_file exists."

        # Check if the video file exists
        if sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "[ -f \"$video_file\" ]"; then
            echo "Video file exists. Running Syncplay client on Raspberry Pi at $pi_ip with video $video_file"

            # Kill existing Syncplay process on the Raspberry Pi
            kill_mpv $pi_ip

            # Construct and execute the Syncplay client command via SSH
            sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "DISPLAY=:0 syncplay --no-gui --player /usr/bin/mpv --room \"$SYNCPLAY_ROOM\" --host \"$SYNCPLAY_SERVER_IP:$SYNCPLAY_SERVER_PORT\" --name \"rp$pi_ip\" \"$video_file\" >/dev/null 2>&1 &"

            echo "\n✅ ––––––––––––––––––––––––––– \n"
            #sshpass -p "$PI_PASSWORD" ssh "$PI_USER@$pi_ip" "DISPLAY=:0 mpv --no-border --fullscreen  \"$video_file\""
            
          
        else
            echo "Video file does not exist on Raspberry Pi at $pi_ip. Skipping..."
            echo "\n❌ ––––––––––––––––––––––––––– \n"

        fi
    else
        echo "😴 Raspberry Pi at $pi_ip is not reachable. Skipping..."
        echo "\n ––––––––––––––––––––––––––– \n"

    fi
done


echo "Syncplay setup completed."

# Function to kill Syncplay process
kill_mpv() {
    local pi_ip=$1
    # Kill the 'mpv' process
    local command="pkill -x mpv || killall mpv"
    sshpass -p "$PI_PASSWORD" ssh "$PI_USER@$pi_ip" "$command"
}