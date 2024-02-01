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

# Load mappings from pi_map.txt
typeset -A PI_MAP
while IFS='=' read -r key value; do
    PI_MAP[$key]=$value
done < pi_map.txt

# Loop through each mapping in PI_MAP
for file_id in ${(k)PI_MAP}; do
    pi_ip=${PI_MAP[$file_id]}
    image_file="${SOURCE_DIR}/${file_id}.jpg"

    echo "––––––––––––––––––––––––––––"
    # Check if the Raspberry Pi is reachable
    echo "Checking if Raspberry Pi at $pi_ip is reachable..."
    if ping -c 1 "$pi_ip" &> /dev/null; then
        echo "Raspberry Pi at $pi_ip is reachable."

        # Check if the image file exists
        if [[ -f "$image_file" ]]; then
            echo "⤴️ Uploading $image_file to Raspberry Pi ID $file_id at $pi_ip ..."

            # Using 'sshpass' to handle password-based authentication
            sshpass -p "$PI_PASSWORD" scp -o StrictHostKeyChecking=no "$image_file" "$PI_USER@$pi_ip:$PICTURE_PATH/${file_id}.jpg"

            # Verify the upload
            if sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "test -f \"$PICTURE_PATH/${file_id}.jpg\""; then
                echo "✅ Verification successful: ${file_id}.jpg exists on $pi_ip."

                # Set the image as the desktop background
                sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "gsettings set org.gnome.desktop.background picture-uri 'file://$PICTURE_PATH/${file_id}.jpg'"
                echo "🖼️ Desktop background set on $pi_ip."
            else
                echo "❌ Verification failed: ${file_id}.jpg was not uploaded correctly to $pi_ip."
            fi
        else
            echo "❌ Image file ${file_id}.jpg not found for Raspberry Pi ID $file_id at $pi_ip"
        fi
    else
        echo "😴 Raspberry Pi at $pi_ip is not reachable. Skipping..."
    fi
done
echo "\n✅ Background images uploading complete."
