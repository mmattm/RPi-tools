#!/bin/zsh
# Configuration file
CONFIG_FILE="config.txt"

# Source the configuration file
source "$CONFIG_FILE"

# Check if the first command line argument is provided
if [[ -z "$1" ]]; then
    echo "Error: No source directory provided."
    echo "Usage: $0 <source-directory>"
    exit 1
fi

# Use the first command line argument as the source directory
SOURCE_DIR="$1"
# Use the second command line argument as the destination subfolder if provided, else default to an empty string
DESTINATION_SUBFOLDER="${2:-}"

# Concatenate the destination subfolder to VIDEO_PATH
DESTINATION_FOLDER="${VIDEO_PATH}/${DESTINATION_SUBFOLDER}"


# Load mappings from pi_map.txt
typeset -A PI_MAP
while IFS='=' read -r key value; do
    PI_MAP[$key]=$value
done < pi_map.txt

# Loop through each mapping in PI_MAP
for file_id in ${(on)${(k)PI_MAP}}; do
    pi_ip=${PI_MAP[$file_id]}
    video_file="${SOURCE_DIR}/${file_id}.mp4"

    echo "––––––––––––––––––––––––––––"
    # Check if the Raspberry Pi is reachable
    echo "Checking if Raspberry Pi at $pi_ip is reachable..."
    if ping -c 1 "$pi_ip" &> /dev/null; then
        echo "Raspberry Pi at $pi_ip is reachable."

        # Check if the destination folder exists on the remote Raspberry Pi
        echo "Checking if destination folder $DESTINATION_FOLDER exists on $pi_ip..."
        if ! sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "test -d \"$DESTINATION_FOLDER\""; then
            echo "Destination folder $DESTINATION_FOLDER does not exist on $pi_ip. Creating it..."
            sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "mkdir -p \"$DESTINATION_FOLDER\""
        fi

        # Check if the video file exists
        if [[ -f "$video_file" ]]; then
            echo "⤴️ Uploading $video_file to Raspberry Pi ID $file_id at $pi_ip ..."

            # Using 'sshpass' to handle password-based authentication
            sshpass -p "$PI_PASSWORD" scp -o StrictHostKeyChecking=no "$video_file" "$PI_USER@$pi_ip:$DESTINATION_FOLDER/${file_id}.mp4"

            # Verify the upload
            if sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "test -f \"$DESTINATION_FOLDER/${file_id}.mp4\""; then
                echo "✅ Verification successful: ${file_id}.mp4 exists in $DESTINATION_FOLDER on $pi_ip."
            else
                echo "❌ Verification failed: ${file_id}.mp4 was not uploaded correctly to $pi_ip:$DESTINATION_FOLDER."
            fi
        else
            echo "❌ Video file ${file_id}.mp4 not found for Raspberry Pi ID $file_id at $pi_ip"
        fi
    else
        echo "😴 Raspberry Pi at $pi_ip is not reachable. Skipping..."
    fi
done
echo "\n✅ Video uploading complete."
