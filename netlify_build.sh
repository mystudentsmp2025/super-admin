#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "--------------------------------------------"
echo "  Setting up Flutter Environment "
echo "--------------------------------------------"

FLUTTER_CHANNEL="stable"

# Check if flutter is already downloaded to avoid re-cloning if caching is used (optional optimization)
if [ ! -d "flutter" ]; then
    echo "Downloading Flutter SDK ($FLUTTER_CHANNEL)..."
    git clone https://github.com/flutter/flutter.git -b $FLUTTER_CHANNEL
else
    echo "Flutter directory already exists."
fi

# Add flutter to path
export PATH="$PATH:`pwd`/flutter/bin"

echo "Flutter version:"
flutter --version

echo "--------------------------------------------"
echo "  Building Flutter Web App "
echo "--------------------------------------------"

flutter build web --release --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

echo "Build complete!"
