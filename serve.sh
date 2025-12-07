#!/bin/bash
# Host the personal website locally

PORT=${1:-8000}

echo "Starting local server on port $PORT..."
echo "Access the website at: http://localhost:$PORT"
echo "Press Ctrl+C to stop the server"
echo ""

uv run python -m http.server "$PORT"
