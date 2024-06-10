#!/bin/bash

# Configurations
PI_USER="ecal"
PI_PASSWORD="ecal"
SYNCPLAY_SERVER_IP="10.0.1.101"
SYNCPLAY_SERVER_PORT="5500"
SYNCPLAY_ROOM="ecal"
VIDEO_PATH="/home/ecal/Videos"
PICTURE_PATH="/home/ecal/Pictures"
START_SERVER=true  # Set this to false if you don't want to start the server

# Start Syncplay server if START_SERVER is true
if [ "$START_SERVER" = true ]; then
    echo "Starting Syncplay server on $SYNCPLAY_SERVER_IP"
    nohup syncplay-server --port $SYNCPLAY_SERVER_PORT > /dev/null 2>&1 &
    # Wait for the server to start
    sleep 5
fi

# Construct and execute the Syncplay client command
syncplay --no-gui --player '/usr/bin/mpv' --room "$SYNCPLAY_ROOM" --host "$SYNCPLAY_SERVER_IP:$SYNCPLAY_SERVER_PORT" --name "rp$(hostname -I)" "$VIDEO_PATH" -- --input-ipc-server=/tmp/mpvsocket >/dev/null 2>&1 &
