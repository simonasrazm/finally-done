#!/bin/bash

# Development workflow script
# Usage: ./scripts/dev_workflow.sh "commit message"

if [ $# -eq 0 ]; then
    echo "Usage: $0 \"commit message\""
    echo "Example: $0 \"Fix Realm deletion error with defensive programming\""
    exit 1
fi

COMMIT_MSG=$1
echo "🚀 Development Workflow"
echo "======================"

# 1. Add all changes
echo "📝 Adding changes to Git..."
git add .

# 2. Commit with message
echo "💾 Committing: $COMMIT_MSG"
git commit -m "$COMMIT_MSG"

# 3. Push to GitHub
echo "📤 Pushing to GitHub..."
git push origin main

# 4. Run tests
echo "🧪 Running tests..."
cd app
flutter test

if [ $? -eq 0 ]; then
    echo "✅ Tests passed!"
    echo ""
    echo "📱 Ready to test on phone!"
    echo "💡 Run: flutter run"
else
    echo "❌ Tests failed! Fix issues before testing on phone."
    exit 1
fi
