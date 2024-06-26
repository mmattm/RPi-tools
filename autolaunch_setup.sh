#!/bin/bash
# Configuration file
CONFIG_FILE="config.txt"

# Source the configuration file
source "$CONFIG_FILE"

# Path to the TXT file with Raspberry Pi IP addresses
PI_MAP_FILE="pi_map.txt"

declare -A PI_MAP
while IFS='=' read -r key value; do
    PI_MAP[$key]=$value
done < "$PI_MAP_FILE"

# Function to create and distribute the autolaunch script
create_and_distribute_script() {
    local pi_ip=$1
    local pi_number=$2

     # Kill first any existing Syncplay server and client processes
    local autolaunch_script='
    #!/bin/bash

    # activate do not disturb mode
    gsettings set org.gnome.desktop.notifications show-banners false

    # Function to continuously ping the target IP address
    check_connection() {
        successful_pings=0
        while true; do
            if ping -c 1 10.0.1.2 &> /dev/null; then
                successful_pings=$((successful_pings + 1))
                echo "Ping successful ($successful_pings/3)"
                if [ "$successful_pings" -ge 3 ]; then
                    return 0
                fi
            else
                echo "Ping failed, resetting interface..."
                #sudo ip link set eth0 down
                sudo ifconfig eth0 down
                sleep 5
                #sudo ip link set eth0 up
                sudo ifconfig eth0 up
                sleep 5
                successful_pings=0
            fi
            sleep 5
        done
    }

    MARKER_FILE="/var/tmp/clean_shutdown_marker"

    if [ -f "$MARKER_FILE" ]; then
        echo "System last shutdown cleanly."
        # Remove the marker file for the next run
        sudo /bin/rm "$MARKER_FILE"
    else
        echo "System did not shutdown cleanly (power loss detected)."
        sleep 15
        sudo reboot
    fi

    # Check the connection and reset the Ethernet interface if needed
    check_connection

    echo "Connection established successfully."

    echo "Now killing existing Syncplay server and client processes..."

    # Kill existing Syncplay server and client processes
    killall syncplay-server
    killall syncplay
    killall mpv
    '

    # If the IP is the same as SYNCPLAY_SERVER_IP, add the server command
    if [ "$pi_ip" == "$SYNCPLAY_SERVER_IP" ]; then
        autolaunch_script+="
        # Start Syncplay server
        echo 'Starting Syncplay server on $SYNCPLAY_SERVER_IP'
        nohup syncplay-server --port $SYNCPLAY_SERVER_PORT > /dev/null 2>&1 &
        "
    fi

    # Check the connection to SYNCPLAY_SERVER_IP if the current IP is not SYNCPLAY_SERVER_IP
    if [ "$pi_ip" != "$SYNCPLAY_SERVER_IP" ]; then
        autolaunch_script+="
    while ! nc -z $SYNCPLAY_SERVER_IP $SYNCPLAY_SERVER_PORT; do
        echo \"Cannot reach Syncplay server at $SYNCPLAY_SERVER_IP on port $SYNCPLAY_SERVER_PORT. Retrying in 5 seconds...\"
        sleep 5
    done
    echo \"Successfully connected to Syncplay server at $SYNCPLAY_SERVER_IP on port $SYNCPLAY_SERVER_PORT\"
    "
    fi

    # Add the client command with specific video file
    local video_file="$VIDEO_PATH/$pi_number.mp4"
    autolaunch_script+="
    # Start Syncplay client
    echo 'Starting video player in 10 seconds...'
    sleep 10
    # echo 'Starting Syncplay client on Raspberry Pi with IP: $pi_ip'
    nohup syncplay --no-gui --player '/usr/bin/mpv' --room \"$SYNCPLAY_ROOM\" --host \"$SYNCPLAY_SERVER_IP:$SYNCPLAY_SERVER_PORT\" --name \"rp$pi_ip\" \"$video_file\" -- --input-ipc-server=/tmp/mpvsocket >/dev/null 2>&1 &
    "

    # Add ydotool click command after a delay
    autolaunch_script+="
    # Load uinput module and set permissions
    sudo modprobe uinput
    sudo chmod 666 /dev/uinput
    sleep 2  # Waits 2 seconds
    sudo ydotool mousemove 100 200
    sudo ydotool click 0
    "

     # If pi_number is 1, send the pause toggle command to mpv
    if [ "$pi_ip" == "$SYNCPLAY_SERVER_IP" ]; then
        autolaunch_script+="
    # Send the pause toggle command to mpv
    sleep 2
    echo '{ \"command\": [\"cycle\", \"pause\"] }' | socat - /tmp/mpvsocket
    "
    fi

    # Copy the autolaunch script to the Raspberry Pi
    echo "$autolaunch_script" | sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "cat > /home/$PI_USER/syncplay_autolaunch.sh"

    # Make the autolaunch script executable
    sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "chmod +x /home/$PI_USER/syncplay_autolaunch.sh"

    echo "📦 Syncplay autolaunch script created and copied to Raspberry Pi with IP: $pi_ip"


    if [ "$enable_autostart" == "enable" ]; then
            # Create the .desktop file content
            local desktop_entry="[Desktop Entry]
            Type=Application
            Exec=gnome-terminal -- /bin/bash /home/$PI_USER/syncplay_autolaunch.sh
            Terminal=true
            Hidden=false
            NoDisplay=false
            X-GNOME-Autostart-enabled=true
            Name=Syncplay AutoLaunch
            Comment=Launch Syncplay at startup
            "

            # Copy the .desktop file to the Raspberry Pi
            echo "$desktop_entry" | sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "mkdir -p /home/$PI_USER/.config/autostart && cat > /home/$PI_USER/.config/autostart/syncplay_autolaunch.desktop"

            echo "✅ Autostart entry added for Raspberry Pi with IP: $pi_ip"
        else
            # Remove the .desktop file if it exists
            sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "rm -f /home/$PI_USER/.config/autostart/syncplay_autolaunch.desktop"

            echo "❌ Autostart entry removed for Raspberry Pi with IP: $pi_ip"
        fi
}


# Determine whether to enable or disable the autostart entry
if [ "$1" == "--enable" ]; then
    enable_autostart="enable"
elif [ "$1" == "--disable" ]; then
    enable_autostart="disable"
else
    echo "Invalid argument: $1"
    echo "Usage: $0 --enable|--disable"
    exit 1
fi


# Loop through each Raspberry Pi IP address and create & distribute the autolaunch script
for pi_id in "${!PI_MAP[@]}"; do
    pi_ip=${PI_MAP[$pi_id]}
    echo "Setting up Syncplay autolaunch on Raspberry Pi with IP: $pi_ip"
    create_and_distribute_script "$pi_ip" "$pi_id"
done

echo "✅ Syncplay autolaunch setup completed on all Raspberry Pis."