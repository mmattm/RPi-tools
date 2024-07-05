#!/bin/zsh
# Kill any process using port 3000
PORT=3000
PID=$(lsof -ti tcp:$PORT)
if [ -n "$PID" ]; then
    echo "Killing process $PID using port $PORT"
    kill -9 $PID
fi


# Start the Node.js application
#/opt/homebrew/bin/node /Users/expo/Desktop/RPi-tools/syncscreen-app/backend/index.js &
/opt/homebrew/bin/node /Users/matthieu.minguet/Code/ECAL/Workshops/JOVaud/syncscreen-app/backend/index.js &

sleep 2

# Open Safari to the specific URL
osascript <<EOF
tell application "Safari"
    activate
    open location "http://localhost:3000"
    delay 2
    do JavaScript "
        document.body.style.overflow = 'auto';  // Ensure the body is scrollable
        document.documentElement.style.overflow = 'auto';  // Ensure the HTML element is scrollable
        if (document.body.requestFullscreen) {
            document.body.requestFullscreen();
        } else if (document.body.webkitRequestFullscreen) { // Safari
            document.body.webkitRequestFullscreen();
        } else if (document.body.mozRequestFullScreen) { // Firefox
            document.body.mozRequestFullScreen();
        } else if (document.body.msRequestFullscreen) { // IE/Edge
            document.body.msRequestFullscreen();
        }
        // Add event listener for scrolling
        window.addEventListener('scroll', function() {
            console.log('scrolling');
        });
    " in document 1
end tell
EOF