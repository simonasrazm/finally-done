#!/bin/bash

# Finally Done Test Runner
echo "🧪 Finally Done Test Runner"
echo "==========================="

# Run all tests
echo "Running all tests..."
flutter test

# Check result
if [ $? -eq 0 ]; then
    echo "✅ All tests passed!"
else
    echo "❌ Some tests failed!"
    exit 1
fi
