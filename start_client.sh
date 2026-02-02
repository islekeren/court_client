#!/bin/bash

# Court Client Startup Script
# This script sets up and starts the court client

set -e

echo "🏟️  Court Client Setup & Startup"
echo "================================"

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed"
    exit 1
fi

# Check if ffmpeg is available
if ! command -v ffmpeg &> /dev/null; then
    echo "❌ FFmpeg is required but not installed"
    echo "   Please install FFmpeg: https://ffmpeg.org/download.html"
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating Python virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Upgrade pip in venv to ensure it's available
./venv/bin/python -m pip install --upgrade pip > /dev/null 2>&1

# Install dependencies
echo "📥 Installing Python dependencies..."
./venv/bin/python -m pip install -r requirements.txt

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "⚠️  No .env file found"
    if [ -f ".env.example" ]; then
        echo "📋 Copying .env.example to .env"
        cp .env.example .env
        echo "✏️  Please edit .env file with your configuration before running again"
        exit 1
    else
        echo "❌ No .env.example file found"
        exit 1
    fi
fi

# Load environment variables
echo "🔧 Loading environment configuration..."
export $(cat .env | grep -v '^#' | xargs)

# Validate required environment variables
required_vars=("COURT_ID" "AUTH_TOKEN" "RTSP_URL")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Required environment variable $var is not set"
        echo "   Please check your .env file"
        exit 1
    fi
done

echo "✅ All checks passed"
echo ""

# Create logs directory if it doesn't exist
if [ ! -d "logs" ]; then
    echo "📁 Creating logs directory..."
    mkdir -p logs
fi

# Generate log filename with timestamp
LOG_FILE="logs/client_$(date +%Y%m%d_%H%M%S).log"
PID_FILE="logs/client.pid"

echo "🚀 Starting Court Client in background..."
echo "   Court ID: $COURT_ID"
echo "   Server: $SERVER_HOST:$SERVER_PORT"
echo "   RTSP URL: $RTSP_URL"
echo "   Log file: $LOG_FILE"
echo ""
echo "   The client will run in the background and auto-restart if it crashes."
echo "   Use 'tail -f $LOG_FILE' to view logs in real-time"
echo "   Use 'kill \$(cat $PID_FILE)' to stop the client"
echo ""

# Auto-restart loop - runs in background
(
    while true; do
        echo "======================================" >> "$LOG_FILE"
        echo "Starting client at $(date)" >> "$LOG_FILE"
        echo "======================================" >> "$LOG_FILE"
        
        # Run the client and capture its PID
        ./venv/bin/python court_client.py >> "$LOG_FILE" 2>&1
        EXIT_CODE=$?
        
        echo "" >> "$LOG_FILE"
        echo "======================================" >> "$LOG_FILE"
        echo "Client stopped at $(date) with exit code $EXIT_CODE" >> "$LOG_FILE"
        echo "Restarting in 5 seconds..." >> "$LOG_FILE"
        echo "======================================" >> "$LOG_FILE"
        echo "" >> "$LOG_FILE"
        
        # Wait before restarting to prevent rapid restart loops
        sleep 5
    done
) & 

# Save the PID of the background loop
echo $! > "$PID_FILE"

echo "✅ Client started with PID $(cat $PID_FILE)"
echo "📋 Tailing log file (Ctrl+C to stop viewing, client will keep running)..."
echo ""

# Tail the log file so user can see initial startup
tail -f "$LOG_FILE"
