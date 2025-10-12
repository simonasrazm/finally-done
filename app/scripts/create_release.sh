#!/bin/bash

# Create a new Sentry release and connect it to Git
# Usage: ./scripts/create_release.sh <version>
# Example: ./scripts/create_release.sh 1.0.1

if [ $# -eq 0 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.1"
    exit 1
fi

VERSION=$1
echo "🚀 Creating Sentry release: $VERSION"

# Create the release
sentry-cli releases new --org simonas-personal --project finally-done $VERSION

# Connect to Git commits
sentry-cli releases set-commits --org simonas-personal --project finally-done $VERSION --auto

# Finalize the release
sentry-cli releases finalize --org simonas-personal --project finally-done $VERSION

echo "✅ Release $VERSION created and connected to Git!"
echo "📊 View at: https://sentry.io/organizations/simonas-personal/projects/finally-done/releases/$VERSION/"
