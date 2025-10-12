#!/bin/bash

# Finally Done App Runner - Test First Development
echo "🚀 Finally Done App Runner"
echo "=========================="

# Step 1: Run all tests first
echo "🧪 Running tests first..."
flutter test

# Check if tests passed
if [ $? -eq 0 ]; then
    echo "✅ All tests passed!"
    echo ""
    
    # Step 2: Run the app
    echo "📱 Starting app..."
    flutter run
else
    echo "❌ Tests failed! Fix tests before running app."
    exit 1
fi
