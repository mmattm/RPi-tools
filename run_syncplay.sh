#!/bin/zsh

# Configuration file
CONFIG_FILE="config.txt"

# Source the configuration file
source "$CONFIG_FILE"

# Set the VIDEO_FILE to default VIDEO_PATH
VIDEO_FILE="$VIDEO_PATH"

# Check if an additional subfolder argument is provided
if [[ -n "$1" ]]; then
    # Concatenate the additional subfolder to VIDEO_PATH
    VIDEO_FILE="${VIDEO_FILE}/$1"
fi

# Assuming the TXT file is named pi_map.txt
declare -A PI_MAP
while IFS='=' read -r key value; do
    PI_MAP[$key]=$value
done < pi_map.txt

# Function to kill Syncplay process
kill_mpv() {
    local pi_ip=$1
    # Kill the 'mpv' process
    local command="pkill -x mpv || killall mpv"
    sshpass -p "$PI_PASSWORD" ssh "$PI_USER@$pi_ip" "$command"
}

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
for pi_id in ${(on)${(k)PI_MAP}}; do
    pi_ip=${PI_MAP[$pi_id]}
    #video_file="$VIDEO_PATH/$pi_id.mp4"
    video_file="$VIDEO_FILE/$pi_id.mp4"


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
            echo "Syncplay process killed. Starting new Syncplay process on Raspberry Pi at $pi_ip"

            # Construct and execute the Syncplay client command via SSH
            sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "syncplay --no-gui --player '/usr/bin/mpv' --room \"$SYNCPLAY_ROOM\" --host \"$SYNCPLAY_SERVER_IP:$SYNCPLAY_SERVER_PORT\" --name \"rp$pi_ip\"  \"$video_file\" -- --input-ipc-server=/tmp/mpvsocket >/dev/null 2>&1 &"
            
            sleep 2  # Waits 2 seconds
            # check if mpv is running on the Raspberry Pi
            if sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "pgrep -x mpv >/dev/null 2>&1"; then
                echo "✅ Syncplay client running on Raspberry Pi at $pi_ip, now playing mpv"

                sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "sudo ydotool click 0"

                if [ "$pi_id" -eq 1 ]; then
                    sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "echo '{ \"command\": [\"cycle\", \"pause\"] }' | socat - /tmp/mpvsocket"
                fi

            else
                echo "❌ Syncplay client failed to start on Raspberry Pi at $pi_ip"
            fi

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

