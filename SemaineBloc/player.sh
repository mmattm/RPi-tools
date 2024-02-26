#!/bin/bash
# install 
# https://github.com/yoggy/sendosc
# https://github.com/ideoforms/AbletonOSC?tab=readme-ov-file#installation

# Define the target IP address and port for OSC messages.
TARGET_IP="127.0.0.1"
TARGET_PORT=11000

# Send an OSC message to play a specific track.
# Replace /play/track with the actual OSC address that triggers playing the track in your setup.
# The integer after i specifies the track number or ID.
# Adjust these values based on how you've configured OSC in Ableton Live.
sendosc $TARGET_IP $TARGET_PORT /live/song/start_playing
osascript -e 'tell application "System Events" to tell process "mpv" to click menu item "Previous File" of menu "Playback" of menu bar 1'
osascript -e 'tell application "System Events" to tell process "mpv" to click menu item "Toggle Pause" of menu "Playback" of menu bar 1'
