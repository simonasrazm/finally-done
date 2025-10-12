#!/bin/bash

# Test runner script for Finally Done app
echo "🧪 Running Finally Done Tests..."

# Run all tests
echo "📋 Running all tests..."
flutter test

# Run specific test categories
echo "🗄️ Running database tests..."
flutter test test/database/

echo "🔧 Running service tests..."
flutter test test/services/

echo "📱 Running widget tests..."
flutter test test/widget_test.dart

echo "✅ All tests completed!"
