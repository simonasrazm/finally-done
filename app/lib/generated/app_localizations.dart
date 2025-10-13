import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_lt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('lt')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Finally Done'**
  String get appTitle;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Home screen title
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Mission Control screen title
  ///
  /// In en, this message translates to:
  /// **'Mission Control'**
  String get missionControl;

  /// Tasks screen title
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// Profile section title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Speech Recognition section title
  ///
  /// In en, this message translates to:
  /// **'Speech Recognition'**
  String get speechRecognition;

  /// Engine selection label
  ///
  /// In en, this message translates to:
  /// **'Engine'**
  String get engine;

  /// Auto engine option combining iOS and Gemini
  ///
  /// In en, this message translates to:
  /// **'Auto (iOS + Gemini)'**
  String get autoIosGemini;

  /// iOS native engine option
  ///
  /// In en, this message translates to:
  /// **'iOS Native'**
  String get iosNative;

  /// Gemini Pro engine option
  ///
  /// In en, this message translates to:
  /// **'Gemini Pro'**
  String get geminiPro;

  /// Confidence threshold label
  ///
  /// In en, this message translates to:
  /// **'Confidence Threshold'**
  String get confidenceThreshold;

  /// Description for confidence threshold setting
  ///
  /// In en, this message translates to:
  /// **'Commands below this threshold will need manual review.'**
  String get confidenceThresholdDescription;

  /// Preferences section title
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// Haptic feedback setting label
  ///
  /// In en, this message translates to:
  /// **'Haptic Feedback'**
  String get hapticFeedback;

  /// Sound effects setting label
  ///
  /// In en, this message translates to:
  /// **'Sound Effects'**
  String get soundEffects;

  /// Connected Services section title
  ///
  /// In en, this message translates to:
  /// **'Connected Services'**
  String get connectedServices;

  /// Google Account integration title
  ///
  /// In en, this message translates to:
  /// **'Google Account'**
  String get googleAccount;

  /// Description for Google connection
  ///
  /// In en, this message translates to:
  /// **'Connect to access Tasks, Calendar, and Gmail'**
  String get connectToGoogle;

  /// Loading message for Google Sign-In
  ///
  /// In en, this message translates to:
  /// **'Opening Google Sign-In...'**
  String get openingGoogleSignIn;

  /// Signed in user message
  ///
  /// In en, this message translates to:
  /// **'Signed in as: {email}'**
  String signedInAs(String email);

  /// Sign out confirmation question
  ///
  /// In en, this message translates to:
  /// **'Do you want to sign out?'**
  String get doYouWantToSignOut;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Sign out button text
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Success message after signing out
  ///
  /// In en, this message translates to:
  /// **'Signed out from Google'**
  String get signedOutFromGoogle;

  /// Success message after connecting
  ///
  /// In en, this message translates to:
  /// **'Connected as: {email}'**
  String connectedAs(String email);

  /// Error title for Google Sign-In failure
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In Failed'**
  String get googleSignInFailed;

  /// Error message for Google Sign-In configuration issues
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In is not configured properly. Please contact support or check your configuration.'**
  String get googleSignInNotConfigured;

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String error(String message);

  /// Message when trying to use Google services without connection
  ///
  /// In en, this message translates to:
  /// **'Please connect to Google first'**
  String get pleaseConnectToGoogleFirst;

  /// Disconnect service confirmation title
  ///
  /// In en, this message translates to:
  /// **'Disconnect {service}?'**
  String disconnectService(String service);

  /// Disconnect service confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disconnect from {service}?'**
  String disconnectServiceConfirmation(String service);

  /// Disconnect button text
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// Success message after disconnecting service
  ///
  /// In en, this message translates to:
  /// **'{service} disconnected'**
  String serviceDisconnected(String service);

  /// Service integration dialog title
  ///
  /// In en, this message translates to:
  /// **'{service} Integration'**
  String serviceIntegration(String service);

  /// Service integration dialog description
  ///
  /// In en, this message translates to:
  /// **'Connect to {service} to sync your data.'**
  String connectToServiceDescription(String service);

  /// Connect button text
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// Done button text
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Message for invalid or deleted commands
  ///
  /// In en, this message translates to:
  /// **'Invalid command (deleted)'**
  String get invalidCommandDeleted;

  /// Button to navigate to settings
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get goToSettings;

  /// Placeholder for features not yet implemented
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// Google Tasks screen title
  ///
  /// In en, this message translates to:
  /// **'Google Tasks'**
  String get googleTasks;

  /// Loading message for tasks
  ///
  /// In en, this message translates to:
  /// **'Loading tasks...'**
  String get loadingTasks;

  /// Processing status
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// Completed status
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Review status
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// Success message when task is completed
  ///
  /// In en, this message translates to:
  /// **'Task completed!'**
  String get taskCompleted;

  /// Error message when task completion fails
  ///
  /// In en, this message translates to:
  /// **'Error completing task: {error}'**
  String errorCompletingTask(String error);

  /// Try again button text
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// Refresh button text
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Error when audio file is missing
  ///
  /// In en, this message translates to:
  /// **'Audio file not found'**
  String get audioFileNotFound;

  /// Status when starting audio playback
  ///
  /// In en, this message translates to:
  /// **'Playing audio...'**
  String get playingAudio;

  /// Confirmation when audio starts playing
  ///
  /// In en, this message translates to:
  /// **'Audio playback started'**
  String get audioPlaybackStarted;

  /// Error message when audio playback fails
  ///
  /// In en, this message translates to:
  /// **'Error playing audio: {error}'**
  String errorPlayingAudio(String error);

  /// Success message when command is deleted
  ///
  /// In en, this message translates to:
  /// **'Command deleted successfully'**
  String get commandDeletedSuccessfully;

  /// Error message when command deletion fails
  ///
  /// In en, this message translates to:
  /// **'Error deleting command: {error}'**
  String errorDeletingCommand(String error);

  /// Photo gallery counter
  ///
  /// In en, this message translates to:
  /// **'Photo {current} of {total}'**
  String photoCounter(int current, int total);

  /// Error when image fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get failedToLoadImage;

  /// Confidence threshold percentage display
  ///
  /// In en, this message translates to:
  /// **'{percentage}%'**
  String confidencePercentage(int percentage);

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorGeneric(String error);

  /// App description for about section
  ///
  /// In en, this message translates to:
  /// **'AI-powered personal organization app that helps you capture and organize tasks, events, and notes through voice commands.'**
  String get appDescription;

  /// Help and support dialog title
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// Help and support contact information
  ///
  /// In en, this message translates to:
  /// **'For help and support, please contact us at support@finallydone.app'**
  String get helpAndSupportMessage;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Customize button text
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get customize;

  /// Confirmation message for icon selection
  ///
  /// In en, this message translates to:
  /// **'Icon will be set as app icon'**
  String get iconWillBeSetAsAppIcon;

  /// Message for features not yet available
  ///
  /// In en, this message translates to:
  /// **'Customization options coming soon'**
  String get customizationOptionsComingSoon;

  /// Step 1 of icon customization instructions
  ///
  /// In en, this message translates to:
  /// **'1. Choose your preferred color variant'**
  String get chooseColorVariant;

  /// Step 2 of icon customization instructions
  ///
  /// In en, this message translates to:
  /// **'2. The icon automatically scales to any size'**
  String get iconScalesAutomatically;

  /// Step 3 of icon customization instructions
  ///
  /// In en, this message translates to:
  /// **'3. Works perfectly for iOS and Android'**
  String get worksOnAllPlatforms;

  /// Step 4 of icon customization instructions
  ///
  /// In en, this message translates to:
  /// **'4. No external dependencies required'**
  String get noExternalDependencies;

  /// Step 5 of icon customization instructions
  ///
  /// In en, this message translates to:
  /// **'5. Can be customized further if needed'**
  String get canBeCustomizedFurther;

  /// Blue color option
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get blue;

  /// Green color option
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get green;

  /// Purple color option
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get purple;

  /// Orange color option
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get orange;

  /// 32 pixel size label
  ///
  /// In en, this message translates to:
  /// **'32px'**
  String get size32px;

  /// 64 pixel size label
  ///
  /// In en, this message translates to:
  /// **'64px'**
  String get size64px;

  /// 128 pixel size label
  ///
  /// In en, this message translates to:
  /// **'128px'**
  String get size128px;

  /// 256 pixel size label
  ///
  /// In en, this message translates to:
  /// **'256px'**
  String get size256px;

  /// Name field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// Speech engine selection description
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred speech recognition engine'**
  String get chooseSpeechEngine;

  /// Haptic feedback setting description
  ///
  /// In en, this message translates to:
  /// **'Vibrate on button presses'**
  String get hapticFeedbackDescription;

  /// Sound effects setting description
  ///
  /// In en, this message translates to:
  /// **'Play success/error sounds'**
  String get soundEffectsDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'lt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'lt':
      return AppLocalizationsLt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
