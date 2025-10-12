#!/bin/bash

# Business Logic Test Runner
echo "🧠 Running Business Logic Tests..."

echo "📊 Status Transition Tests..."
flutter test test/business_logic/status_transition_test.dart

echo "✅ Command Validation Tests..."
flutter test test/business_logic/command_validation_test.dart

echo "🔄 Migration Logic Tests..."
flutter test test/business_logic/migration_logic_test.dart

echo "📋 Queue Operations Tests..."
flutter test test/business_logic/queue_operations_test.dart

echo "🎯 All Business Logic Tests Completed!"
