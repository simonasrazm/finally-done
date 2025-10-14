# Makefile for Finally Done app
# Ensures build fails if translations are missing

.PHONY: check-translations gen-l10n build clean

# Check for untranslated messages and fail if any are found
check-translations:
	@echo "🔍 Checking translations..."
	@flutter gen-l10n
	@dart scripts/check_translations.dart

# Generate localization files
gen-l10n:
	@echo "🌐 Generating localization files..."
	@flutter gen-l10n

# Build the app (includes translation check)
build: check-translations
	@echo "🏗️  Building app..."
	@flutter build ios --release

# Build for development (includes translation check)
build-dev: check-translations
	@echo "🏗️  Building app for development..."
	@flutter build ios --debug

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@flutter clean
	@rm -f untranslated_messages.json

# Run the app (includes translation check)
run: check-translations
	@echo "🚀 Running app..."
	@flutter run

# CI/CD build (strict mode - fails on any issues)
ci-build: check-translations
	@echo "🤖 CI/CD build..."
	@flutter build ios --release --no-codesign
