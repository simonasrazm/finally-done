# Finally Done - AI-Powered Personal Organization App

Finally Done is an iOS app that helps you organize your personal life by capturing tasks, events, and notes through voice commands. It uses AI to understand your commands and route them to the appropriate services.

## Features

- **Voice Recording**: Record commands in Lithuanian or English using iOS native speech recognition
- **AI Processing**: Intelligent command interpretation using cloud-based LLM
- **Mission Control**: Review and manage all your commands in one place
- **Service Integration**: Connect to Google Tasks, Google Calendar, Evernote, and Apple Notes
- **Offline-First**: Record commands offline, process when online
- **Dark Mode**: Full support for iOS dark mode

## Architecture

- **Framework**: Flutter 3.35.6 with native iOS extensions
- **Speech Recognition**: iOS SFSpeechRecognizer (on-device, zero app size cost)
- **AI Processing**: Cloud-based LLM with laptop Ollama fallback for development
- **Local Storage**: RealmDB for offline-first data storage
- **State Management**: Flutter Riverpod

## Setup Instructions

1. **Prerequisites**:
   - Flutter 3.35.6+
   - Xcode 15+
   - iOS 13+ device or simulator

2. **Install Dependencies**:
   ```bash
   cd finally_done
   flutter pub get
   ```

3. **Run on iOS**:
   ```bash
   flutter run
   ```

4. **Grant Permissions**:
   - Microphone access
   - Speech recognition access

## Testing

Before building the full app, test Lithuanian speech recognition:

1. **Run the test app**:
   ```bash
   cd ../speech_test
   flutter run
   ```

2. **Test Lithuanian phrases**:
   - "Nupirk pieno rytoj" (Buy milk tomorrow)
   - "Susitikimas pirmadienį pusę trijų" (Meeting Monday half past two)
   - "Pastaba: slaptažodis yra vienas du trys" (Note: password is one two three)

3. **If accuracy is good (>80%)**: Use iOS SFSpeechRecognizer
4. **If accuracy is poor (<80%)**: Consider Whisper Tiny fallback

## Development Status

- ✅ Project setup with Flutter 3.35.6
- ✅ Design system (colors, typography)
- ✅ Realm data models
- ✅ Speech recognition service (iOS native)
- ✅ NLP service (cloud LLM + rule-based fallback)
- ✅ Main screens (Home, Mission Control, Settings)
- ✅ iOS native speech recognition plugin
- 🔄 Testing Lithuanian speech recognition
- ⏳ Connector implementations
- ⏳ iOS widgets (Lock Screen, Control Center)
- ⏳ Realm database integration

## Next Steps

1. Test Lithuanian speech recognition accuracy
2. Implement connector services (Google Tasks, Calendar, etc.)
3. Add iOS Lock Screen widget
4. Integrate Realm database
5. Add photo + note → task feature
6. Implement offline queueing system

## App Size

Current estimated size: ~45 MB
- Flutter framework: ~30 MB
- Assets: ~10 MB
- RealmDB: ~5 MB
- Speech recognition: 0 MB (uses iOS system)

## License

Private project - All rights reserved