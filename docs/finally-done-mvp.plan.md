# Finally Done MVP - Development Plan

## Project Overview
Cross-platform Flutter app to organize personal life (notes, events, tasks) with natural language voice commands.

## Target Users
- **Persona 1**: Google Calendar, Evernote, Google Tasks user
- **Persona 2**: Apple Alarms, Apple Notes, Google Tasks user

## Core Features

### 1. Voice Recording
- Lock screen widget for quick access
- Control Center shortcut
- In-app recording button
- Support for Lithuanian and English languages

### 2. Natural Language Processing (NLP)
- Process voice/text commands into structured entities
- Support for tasks, events, notes creation
- Hybrid approach: local processing + cloud fallback
- Rule-based parser for common commands

### 3. Mission Control
- Review executed commands
- Review pending commands requiring human input
- Undo/redo functionality
- Command history with status tracking

### 4. Connectors
- Google Tasks/Calendar integration
- Evernote integration
- Apple Notes integration
- Custom alarm system (iPhone-style)

### 5. Offline First
- RealmDB for local storage
- Sync when online
- Basic functionality works offline

### 6. Other features (to refine)
- quickly add to queue from the browser (eg after registration to Melga)

## Technical Architecture

### Frontend
- **Framework**: Flutter
- **Design**: iOS-native look and feel
- **State Management**: Riverpod
- **Local Storage**: RealmDB
- **Speech Recognition**: iOS SFSpeechRecognizer (on-device)

### Backend (Post-MVP)
- AWS AppSync, DynamoDB, API Gateway, Lambda
- Cloud NLP processing for complex commands
- User data synchronization

### Key Technical Decisions
1. **Speech Recognition**: iOS native (SFSpeechRecognizer) for on-device processing
2. **NLP**: Hybrid approach - local rules + cloud fallback
3. **App Size**: Keep under 150MB constraint
4. **Multilanguage**: Support Lithuanian and English
5. **Accessibility**: VoiceOver, Dynamic Type, contrast ratios

## MVP Screens

### 1. Home Screen
- Large voice recording button
- Text input option
- Camera button (future)
- Clean, distraction-free interface

### 2. Mission Control Screen
- **Executed Tab**: Successfully completed commands (collapsed by default)
- **Review Tab**: Commands needing human review
- Command cards showing:
  - Original input (voice/text)
  - Discovered actions
  - Confidence levels
  - Status and action buttons

### 3. Settings Screen
- User name configuration
- Connected services management
- Language preferences
- Custom alarm system toggle

## Development Phases

### Phase 1: Core App Structure ✅
- [x] Flutter project setup
- [x] Basic navigation (Home, Mission Control, Settings, Tasks)
- [x] Design system (colors, typography, spacing, tokens)
- [x] RealmDB models for commands and entities
- [x] State management with Riverpod StateNotifier

### Phase 2: Speech Recognition Testing ✅
- [x] Whisper testing (139MB - TOO LARGE for 150MB constraint)
- [x] iOS native SFSpeechRecognizer integration (on-device, no size impact)
- [x] Lithuanian language support testing (Whisper tiny 39MB)
- [x] English language support testing (iOS native)
- [x] Permission handling
- [x] Basic voice-to-text functionality
- [x] Hybrid approach working (iOS native + Whisper tiny)

### Phase 3: Localization & Theming ✅
- [x] Multi-language support (English, Lithuanian)
- [x] Instant language switching
- [x] Theme system (system/light/dark)
- [x] Design token system
- [x] Build validation for translations
- [x] CI/CD integration for translation checks

### Phase 4: Connector Architecture ✅
- [x] Base connector abstract class
- [x] Network service with retry logic
- [x] Connector manager for lifecycle
- [x] Integration manager for providers
- [x] Google Tasks connector implementation
- [x] Error handling and authentication refresh

### Phase 5: Google Integration ✅
- [x] Google Sign-In with OAuth2
- [x] Google Tasks API integration
- [x] Service-specific connection toggles
- [x] Token management and refresh
- [x] Error monitoring with Sentry

### Phase 6: Mission Control ✅
- [x] Command review interface
- [x] Status management (processing, completed, queued)
- [x] Command history with timestamps
- [x] Task management interface
- [x] Integration status indicators

### Phase 7: Polish & Testing ✅
- [x] UI/UX refinements
- [x] Performance optimization
- [x] Error handling improvements
- [x] App freezing fixes
- [x] Memory management improvements

### Phase 8: Future Connectors 🔄
- [ ] Google Calendar integration
- [ ] Google Gmail integration
- [ ] Apple Notes integration
- [ ] Evernote integration
- [ ] Custom alarm system

## Current Status
- ✅ Complete Flutter app structure with all core screens
- ✅ Design system with tokens and theming
- ✅ RealmDB models and data management
- ✅ Speech recognition working on iOS
- ✅ Multi-language localization system
- ✅ Connector architecture for scalable integrations
- ✅ Google Tasks integration fully functional
- ✅ Mission Control with command management
- ✅ Error monitoring and performance tracking
- ✅ UI/UX optimizations and bug fixes

## Next Steps
1. Complete Google Calendar and Gmail connectors
2. Implement Apple Notes connector
3. Add Evernote connector
4. Add iOS Lock Screen widget
5. Implement advanced offline queueing
6. Add photo + note → task feature

## Constraints
- App size must stay under 150MB
- Budget: €20-100 for tools
- Focus on iOS users initially
- Quality and speed prioritized
- Skip Figma for MVP, use Flutter design system

## Testing Strategy
- Test Lithuanian language support early
- Validate with both user personas
- Focus on voice command accuracy
- Test offline functionality
- Performance testing on older devices
