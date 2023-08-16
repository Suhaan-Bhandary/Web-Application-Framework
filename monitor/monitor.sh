#!/bin/bash

server_output=$(jq -r '.outputFileName' .monitor)
serverStartCommand=$(jq -r '.scripts.run' .monitor)
buildCommand=$(jq -r '.scripts.build' .monitor)

# Defining colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


# Helper function to change global variables,
# this is done as we cannot modify global variable inside a child shell
# Usage read_value path_to_tmp_file
function read_value {
    cat "${1}"
}

# Usage: set_value path_to_tmp_file the_value
function set_value {
    echo "${2}" > "${1}"
}

# Create the temp file
# Note that target_pid_temp_file is available everywhere
target_pid_temp_file=$(mktemp)
#----


# Function to run when Ctrl+C is pressed
cleanup() {
    echo $'\n'
    echo -e "${RED}Ctrl+C detected. Cleaning up...${NC}"
    
    target_pid=$(read_value "${target_pid_temp_file}")
    
    if [ -n "$target_pid" ]; then
        kill -9 "$target_pid"
    fi
    
    exit 1
}

# Set up the trap to call the cleanup function on Ctrl+C
trap cleanup SIGINT

function createServer(){
    # Check the exit status
    $buildCommand
    
    # Run the C++ executable in the background without stopping the main script
    $serverStartCommand &
    target_pid=$!
    
    set_value "${target_pid_temp_file}" "${target_pid}"
    
    echo -e "${GREEN}Server Created!! [PID $target_pid]${NC}"
}

function restartServer(){
    target_pid=$(read_value "${target_pid_temp_file}")
    
    # Check if already the server is running
    if ps -p "$target_pid" > /dev/null; then
        echo -e "${BLUE}Process is running. Terminating...${NC}"
        kill -9 "$target_pid"
        
        # Build the project and start
        echo $'\n'
        createServer
        echo $'\n'
    else
        echo -e "${RED}Process {"$(basename "$target_pid")"} Not Found!!${NC}"
        exit 1;
    fi
}

# Function monitors the changes
function monitor() {
    echo -e "${BLUE}Monitoring Started${NC}"
    
    echo $'\n'
    createServer
    echo $'\n'
    
    
    WATCH_DIR="."
    EVENT_THRESHOLD=1  # Throttle to 1 event per second
    
    lastEventRunTime=0
    
    # Listening to the changes in the WATCH_DIR for events (modify,move,create,delete)
    inotifywait -r -m "$WATCH_DIR" -e modify,move,create,delete --exclude "/(\.|build|monitor|$server_output|.git|.vscode)" -q |
    while read -r directory events filename; do
        currentEventTime=$(date +%s.%N)
        timeSinceLastEventRunSeconds=$(echo "$currentEventTime - $lastEventRunTime" | bc)
        
        if (( $(echo "$timeSinceLastEventRunSeconds >= $EVENT_THRESHOLD" | bc -l) )); then
            echo $'\n'
            echo -e "${BLUE}$directory $events $filename${NC}"
            restartServer
            lastEventRunTime=$currentEventTime
        fi
    done
}

# Calling the function
monitor
