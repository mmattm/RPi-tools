#!/bin/bash

# Function to continuously ping the target IP address
check_connection() {
    successful_pings=0
    while true; do
        if ping -c 1 10.0.1.2 &> /dev/null; then
            successful_pings=$((successful_pings + 1))
            echo "Ping successful ($successful_pings/3)"
            if [ $successful_pings -ge 3 ]; then
                return 0
            fi
        else
            echo "Ping failed, resetting interface..."
            sudo ip link set eth0 down
            sleep 5
            sudo ip link set eth0 up
            sleep 5
            successful_pings=0
        fi
        sleep 5
    done
}

# Check the connection and reset the Ethernet interface if needed
check_connection

echo "Connection established successfully. Proceeding with the script."


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

# Kill existing Syncplay server and client processes
killall syncplay-server
killall syncplay
killall mpv

echo "Starting video player in 20 seconds…"
# Start Syncplay client
sleep 20  # Waits 10 seconds
# echo 'Starting Syncplay client on Raspberry Pi with IP: 10.0.1.114'
nohup syncplay --no-gui --player '/usr/bin/mpv' --room "ecal" --host "10.0.1.101:5500" --name "rp10.0.1.114" "/home/ecal/Videos/14.mp4" -- --input-ipc-server=/tmp/mpvsocket >/dev/null 2>&1 &

# Load uinput module and set permissions
sudo modprobe uinput
sudo chmod 666 /dev/uinput
sleep 2  # Waits 2 seconds
sudo ydotool click 0