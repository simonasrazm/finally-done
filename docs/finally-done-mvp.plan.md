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
- [x] Basic navigation (Home, Mission Control, Settings)
- [x] Design system (colors, typography)
- [x] RealmDB models for commands and entities

### Phase 2: Speech Recognition Testing ✅
- [x] Whisper testing (139MB - TOO LARGE for 150MB constraint)
- [x] iOS native SFSpeechRecognizer integration (on-device, no size impact)
- [x] Lithuanian language support testing (Whisper tiny 39MB)
- [x] English language support testing (iOS native)
- [x] Permission handling
- [x] Basic voice-to-text functionality
- [x] Hybrid approach working (iOS native + Whisper tiny)

### Phase 3: NLP Processing
- [ ] Rule-based command parser
- [ ] Entity extraction (tasks, events, notes)
- [ ] Command interpretation logic
- [ ] Confidence scoring

### Phase 4: Mission Control
- [ ] Command review interface
- [ ] Status management
- [ ] Undo/redo functionality
- [ ] Command history

### Phase 5: Connectors
- [ ] Google Tasks/Calendar integration
- [ ] Apple Notes integration
- [ ] Custom alarm system
- [ ] Evernote integration (future)

### Phase 6: Polish & Testing
- [ ] UI/UX refinements
- [ ] Accessibility features
- [ ] Performance optimization
- [ ] User testing with target personas

## Current Status
- ✅ Basic Flutter app structure created
- ✅ Design system implemented
- ✅ RealmDB models defined
- 🔄 Speech recognition testing in progress
- ❌ Got sidetracked with technical debugging

## Next Steps
1. Complete speech recognition testing on physical iPhone
2. Implement basic NLP command processing
3. Build Mission Control interface
4. Add connector integrations

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
