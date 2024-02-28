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

# Loop through each Raspberry Pi IP address and execute SSH requests in parallel
for pi_id in ${(on)${(k)PI_MAP}}; do
    pi_ip=${PI_MAP[$pi_id]}
    (
        echo "–––––––––––––––––––––––––––"
        echo "Listing folders in $VIDEO_PATH on Raspberry Pi with IP: $pi_ip"
        sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "ls -d $VIDEO_PATH/*/ | xargs -n 1 basename"
    ) 
    # ) & replace by ; to run in parallel
done
