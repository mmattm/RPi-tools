#!/bin/zsh
# Configuration file
CONFIG_FILE="config.txt"

# Source the configuration file
source "$CONFIG_FILE"

# Default directory
DEFAULT_DIR="/Users/matthieu.minguet/Desktop/Samples/Test"

# Use the first command line argument if provided, otherwise use the default directory
SOURCE_DIR="${1:-$DEFAULT_DIR}"

# Load mappings from pi_map.txt
typeset -A PI_MAP
while IFS='=' read -r key value; do
    PI_MAP[$key]=$value
done < pi_map.txt

# Loop through each mapping in PI_MAP
for file_id in ${(k)PI_MAP}; do
    pi_ip=${PI_MAP[$file_id]}
    video_file="${SOURCE_DIR}/${file_id}.mp4"

    echo "––––––––––––––––––––––––––––"
    # Check if the Raspberry Pi is reachable
    echo "Checking if Raspberry Pi at $pi_ip is reachable..."
    if ping -c 1 "$pi_ip" &> /dev/null; then
        echo "Raspberry Pi at $pi_ip is reachable."

        # Check if the video file exists
        if [[ -f "$video_file" ]]; then
            echo "⤴️ Uploading $video_file to Raspberry Pi ID $file_id at $pi_ip ..."

            # Using 'sshpass' to handle password-based authentication
            sshpass -p "$PI_PASSWORD" scp "$video_file" "$PI_USER@$pi_ip:$VIDEO_PATH/${file_id}.mp4"

            # Verify the upload
            if sshpass -p "$PI_PASSWORD" ssh "$PI_USER@$pi_ip" "test -f \"$VIDEO_PATH/${file_id}.mp4\""; then
                echo "✅ Verification successful: ${file_id}.mp4 exists on $pi_ip."
            else
                echo "❌ Verification failed: ${file_id}.mp4 was not uploaded correctly to $pi_ip."
            fi
        else
            echo "❌ Video file ${file_id}.mp4 not found for Raspberry Pi ID $file_id at $pi_ip"
        fi
    else
        echo "😴 Raspberry Pi at $pi_ip is not reachable. Skipping..."
    fi
done
echo "\n✅ Video uploading complete."
