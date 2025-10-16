#!/bin/bash

# Complete release workflow: Git operations + Sentry release
# Usage: ./scripts/create_release.sh [version] [commit_message]
# Examples: 
#   ./scripts/create_release.sh 1.0.1 "Add agentic architecture documentation"
#   ./scripts/create_release.sh auto "Fix task list animations"

# Function to get current version from pubspec.yaml
get_current_version() {
    cd app
    grep "^version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//'
    cd ..
}

# Function to bump version
bump_version() {
    local current_version=$1
    local version_parts=($(echo $current_version | tr '.' ' '))
    local major=${version_parts[0]}
    local minor=${version_parts[1]}
    local patch=${version_parts[2]}
    
    # Auto-increment patch version
    patch=$((patch + 1))
    echo "$major.$minor.$patch"
}

# Parse arguments
VERSION=""
COMMIT_MSG=""
AUTO_VERSION=false

if [ $# -eq 0 ]; then
    echo "Usage: $0 [version] [commit_message]"
    echo ""
    echo "Examples:"
    echo "  $0 1.0.1 \"Add agentic architecture documentation\""
    echo "  $0 auto \"Fix task list animations\""
    echo "  $0 \"Quick bugfix\"  # Auto version + custom message"
    echo ""
    echo "Options:"
    echo "  version         - Version number (e.g., 1.0.1) or 'auto' for auto-increment"
    echo "  commit_message  - Git commit message (optional if version provided)"
    exit 1
fi

# Handle different argument patterns
if [ "$1" = "auto" ]; then
    AUTO_VERSION=true
    VERSION=$(bump_version $(get_current_version))
    COMMIT_MSG="${2:-Release $VERSION}"
elif [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    VERSION=$1
    COMMIT_MSG="${2:-Release $VERSION}"
else
    # First argument is commit message, auto version
    AUTO_VERSION=true
    VERSION=$(bump_version $(get_current_version))
    COMMIT_MSG="$1"
fi

echo "🚀 Release Workflow"
echo "=================="
echo "Version: $VERSION"
echo "Commit: $COMMIT_MSG"
echo ""

# 1. Run tests first
echo "🧪 Running tests..."
cd app
flutter test

if [ $? -ne 0 ]; then
    echo "❌ Tests failed! Not proceeding with release."
    exit 1
fi

# 2. Update version in pubspec.yaml if auto versioning
if [ "$AUTO_VERSION" = true ]; then
    echo "📝 Updating version in pubspec.yaml to $VERSION..."
    sed -i.bak "s/^version: .*/version: $VERSION+1/" pubspec.yaml
    rm pubspec.yaml.bak
fi

# 3. Go back to root and add all changes
cd ..
echo "📝 Adding changes to Git..."
git add .

# 4. Commit with message
echo "💾 Committing: $COMMIT_MSG"
git commit -m "$COMMIT_MSG"

# 5. Push to GitHub
echo "📤 Pushing to GitHub..."
git push origin main

# 6. Create Sentry release
echo "🔍 Creating Sentry release: $VERSION"
sentry-cli releases new --org simonas-personal --project finally-done $VERSION

# 7. Connect to Git commits
echo "🔗 Connecting release to Git commits..."
sentry-cli releases set-commits --org simonas-personal --project finally-done $VERSION --auto

# 8. Finalize the release
echo "✅ Finalizing Sentry release..."
sentry-cli releases finalize --org simonas-personal --project finally-done $VERSION

echo ""
echo "🎉 Release $VERSION completed successfully!"
echo "📊 Sentry: https://sentry.io/organizations/simonas-personal/projects/finally-done/releases/$VERSION/"
echo "📱 Ready for TestFlight or production deployment!"
