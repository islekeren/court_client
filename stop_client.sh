#!/bin/bash

# Court Client Stop Script
# This script stops the running court client

set -e

echo "🛑 Stopping Court Client..."

PID_FILE="logs/client.pid"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    
    # Check if process is running
    if ps -p $PID > /dev/null 2>&1; then
        echo "   Found client process with PID $PID"
        echo "   Sending termination signal..."
        kill $PID
        
        # Wait for process to stop
        sleep 2
        
        # Check if it's still running
        if ps -p $PID > /dev/null 2>&1; then
            echo "   Process still running, forcing termination..."
            kill -9 $PID
        fi
        
        echo "✅ Client stopped successfully"
    else
        echo "⚠️  No running process found with PID $PID"
    fi
    
    # Clean up PID file
    rm -f "$PID_FILE"
else
    echo "⚠️  No PID file found at $PID_FILE"
    echo "   Client may not be running or was started manually"
fi
