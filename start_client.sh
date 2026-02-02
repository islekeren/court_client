#!/bin/bash

# Court Client Startup Script
# This script sets up and starts the court client

set -e

echo "🏟️  Court Client Setup & Startup"
echo "================================"

# Check if client is already running - ensure single instance
EXISTING=$(pgrep -f "python.*court_client.py" 2>/dev/null || true)
if [ -n "$EXISTING" ]; then
    echo "⚠️  Court client is already running (PID: $EXISTING)"
    echo "   Use ./stop_client.sh to stop it first, or run with --restart"
    if [ "$1" = "--restart" ]; then
        echo "🔄 Restarting client..."
        ./stop_client.sh
        sleep 1
    else
        exit 1
    fi
fi

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

# Run the client directly (no auto-restart wrapper - single process)
echo "======================================" >> "$LOG_FILE"
echo "Starting client at $(date)" >> "$LOG_FILE"
echo "======================================" >> "$LOG_FILE"

# Start client in background
./venv/bin/python court_client.py >> "$LOG_FILE" 2>&1 &
CLIENT_PID=$!

# Save the actual Python process PID
echo $CLIENT_PID > "$PID_FILE"

echo "✅ Client started with PID $CLIENT_PID"
echo "📋 Tailing log file (Ctrl+C to stop viewing, client will keep running)..."
echo "   Use './stop_client.sh' to stop the client"
echo ""

# Tail the log file so user can see initial startup
tail -f "$LOG_FILE"
