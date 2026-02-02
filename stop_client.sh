#!/bin/bash

# Court Client Stop Script
# This script stops the running court client

echo "🛑 Stopping Court Client..."

# Find and kill any running court_client.py processes
PIDS=$(pgrep -f "python.*court_client.py" 2>/dev/null || true)

if [ -n "$PIDS" ]; then
    echo "   Found court client process(es): $PIDS"
    echo "   Sending termination signal..."
    
    # Send SIGTERM first for graceful shutdown
    pkill -f "python.*court_client.py" 2>/dev/null || true
    
    # Wait for processes to stop
    sleep 2
    
    # Check if any are still running and force kill
    REMAINING=$(pgrep -f "python.*court_client.py" 2>/dev/null || true)
    if [ -n "$REMAINING" ]; then
        echo "   Process(es) still running, forcing termination..."
        pkill -9 -f "python.*court_client.py" 2>/dev/null || true
        sleep 1
    fi
    
    # Final check
    FINAL=$(pgrep -f "python.*court_client.py" 2>/dev/null || true)
    if [ -z "$FINAL" ]; then
        echo "✅ Client stopped successfully"
    else
        echo "❌ Failed to stop some processes: $FINAL"
        exit 1
    fi
else
    echo "⚠️  No running court client found"
fi

# Clean up PID file if it exists
rm -f "logs/client.pid" 2>/dev/null || true
