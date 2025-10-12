#!/bin/bash

# Development workflow script
# Usage: ./scripts/dev_workflow.sh "commit message" [--no-run-app]
# Example: ./scripts/dev_workflow.sh "Fix Realm deletion error"

if [ $# -eq 0 ]; then
    echo "Usage: $0 \"commit message\" [--no-run-app]"
    echo "Example: $0 \"Fix Realm deletion error\""
    echo ""
    echo "Options:"
    echo "  --no-run-app    Skip running the app after successful tests"
    exit 1
fi

COMMIT_MSG=$1
RUN_APP=true

# Check if --no-run-app flag is provided
if [ "$2" = "--no-run-app" ]; then
    RUN_APP=false
fi

echo "🚀 Development Workflow"
echo "======================"

# 1. Run tests FIRST
echo "🧪 Running tests first..."
cd app
flutter test

if [ $? -ne 0 ]; then
    echo "❌ Tests failed! Not committing or pushing broken code."
    exit 1
fi

# 2. Go back to root and add all changes
cd ..
echo "📝 Adding changes to Git..."
git add .

# 3. Commit with message
echo "💾 Committing: $COMMIT_MSG"
git commit -m "$COMMIT_MSG"

# 4. Push to GitHub
echo "📤 Pushing to GitHub..."
git push origin main

echo "✅ Tests passed and code pushed to GitHub!"
echo ""

if [ "$RUN_APP" = true ]; then
    echo "📱 Starting app automatically..."
    cd app
    flutter run
else
    echo "📱 Ready to test on phone!"
    echo "💡 Run: flutter run"
    echo "💡 Or use: ./scripts/dev_workflow.sh \"$COMMIT_MSG\""
fi
