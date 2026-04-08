#!/bin/bash
set -e

echo "📦 Resolving Dependencies..."
swift package resolve

echo "------------------------------------------------"
echo "🛠️  Building Project (Hummingbird + SQLite)..."
echo "------------------------------------------------"

# We build the 'App' product specifically.
# This ensures it works even if the directory name changes.
swift build --product App --jobs 2

echo "------------------------------------------------"
echo "✅ Project Built Successfully!"
echo "   - Run './run.sh' to start the server"
echo "------------------------------------------------"