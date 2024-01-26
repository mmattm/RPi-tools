#!/bin/zsh

# Directory on your Mac containing the videos
SOURCE_DIR="/Users/matthieu.minguet/Desktop/Samples/Test"

# Directory on Raspberry Pi where videos will be copied
DEST_DIR="/home/ecal/Videos"

# Raspberry Pi user and password
PI_USER="ecal"
PI_PASSWORD="ecal"


declare -A PI_MAP
while IFS='=' read -r key value; do
    PI_MAP[$key]=$value
done < pi_map.txt

# Loop through each video file in the source directory
for video_file in "$SOURCE_DIR"/*.mp4; do
    file_id=${video_file:t:r} # Extract the file ID from the filename

    # Check if there is a mapping for this file ID
    if [[ -n ${PI_MAP[$file_id]} ]]; then
        pi_ip=${PI_MAP[$file_id]}
        echo "Uploading $video_file to Raspberry Pi ID $file_id at $pi_ip"

        # Using 'sshpass' to handle password-based authentication
        sshpass -p "$PI_PASSWORD" scp "$video_file" "$PI_USER@$pi_ip:$DEST_DIR"

          # Verify the upload
        if sshpass -p "$PI_PASSWORD" ssh "$PI_USER@$pi_ip" "test -f \"$DEST_DIR/$file_name\" && echo \"File $file_name exists on $pi_ip\" || echo \"Upload of $file_name to $pi_ip failed\""
        then
            echo "Verification successful: $file_name has been uploaded to $pi_ip."
        else
            echo "Verification failed: $file_name was not uploaded correctly to $pi_ip."
        fi
    else
        echo "No mapping found for file ID $file_id"
    fi
done

echo "Video uploading complete."