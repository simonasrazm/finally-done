// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Finally Done';

  @override
  String get settings => 'Settings';

  @override
  String get home => 'Home';

  @override
  String get missionControl => 'Mission Control';

  @override
  String get tasks => 'Tasks';

  @override
  String get profile => 'Profile';

  @override
  String get name => 'Name';

  @override
  String get speechRecognition => 'Speech Recognition';

  @override
  String get engine => 'Engine';

  @override
  String get autoIosGemini => 'Auto (iOS + Gemini)';

  @override
  String get iosNative => 'iOS Native';

  @override
  String get geminiPro => 'Gemini Pro';

  @override
  String get confidenceThreshold => 'Confidence Threshold';

  @override
  String get confidenceThresholdDescription =>
      'Commands below this threshold will need manual review.';

  @override
  String get preferences => 'Preferences';

  @override
  String get hapticFeedback => 'Haptic Feedback';

  @override
  String get soundEffects => 'Sound Effects';

  @override
  String get connectedServices => 'Connected Services';

  @override
  String get googleAccount => 'Google Account';

  @override
  String get connectToGoogle => 'Connect to access Tasks, Calendar, and Gmail';

  @override
  String get openingGoogleSignIn => 'Opening Google Sign-In...';

  @override
  String signedInAs(String email) {
    return 'Signed in as: $email';
  }

  @override
  String get doYouWantToSignOut => 'Do you want to sign out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signedOutFromGoogle => 'Signed out from Google';

  @override
  String connectedAs(String email) {
    return 'Connected as: $email';
  }

  @override
  String get googleSignInFailed => 'Google Sign-In Failed';

  @override
  String get googleSignInNotConfigured =>
      'Google Sign-In is not configured properly. Please contact support or check your configuration.';

  @override
  String get ok => 'OK';

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String get pleaseConnectToGoogleFirst => 'Please connect to Google first';

  @override
  String disconnectService(String service) {
    return 'Disconnect $service?';
  }

  @override
  String disconnectServiceConfirmation(String service) {
    return 'Are you sure you want to disconnect from $service?';
  }

  @override
  String get disconnect => 'Disconnect';

  @override
  String serviceDisconnected(String service) {
    return '$service disconnected';
  }

  @override
  String serviceIntegration(String service) {
    return '$service Integration';
  }

  @override
  String connectToServiceDescription(String service) {
    return 'Connect to $service to sync your data.';
  }

  @override
  String get connect => 'Connect';

  @override
  String get done => 'Done';

  @override
  String get invalidCommandDeleted => 'Invalid command (deleted)';

  @override
  String get goToSettings => 'Go to Settings';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get googleTasks => 'Google Tasks';

  @override
  String get loadingTasks => 'Loading tasks...';

  @override
  String get processing => 'Processing';

  @override
  String get completed => 'Completed';

  @override
  String get review => 'Review';

  @override
  String get taskCompleted => 'Task completed!';

  @override
  String errorCompletingTask(String error) {
    return 'Error completing task: $error';
  }

  @override
  String get tryAgain => 'Try Again';

  @override
  String get refresh => 'Refresh';

  @override
  String get audioFileNotFound => 'Audio file not found';

  @override
  String get playingAudio => 'Playing audio...';

  @override
  String get audioPlaybackStarted => 'Audio playback started';

  @override
  String errorPlayingAudio(String error) {
    return 'Error playing audio: $error';
  }

  @override
  String get commandDeletedSuccessfully => 'Command deleted successfully';

  @override
  String errorDeletingCommand(String error) {
    return 'Error deleting command: $error';
  }

  @override
  String photoCounter(int current, int total) {
    return 'Photo $current of $total';
  }

  @override
  String get failedToLoadImage => 'Failed to load image';

  @override
  String confidencePercentage(int percentage) {
    return '$percentage%';
  }

  @override
  String errorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get appDescription =>
      'AI-powered personal organization app that helps you capture and organize tasks, events, and notes through voice commands.';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String get helpAndSupportMessage =>
      'For help and support, please contact us at support@finallydone.app';

  @override
  String get close => 'Close';

  @override
  String get customize => 'Customize';

  @override
  String get iconWillBeSetAsAppIcon => 'Icon will be set as app icon';

  @override
  String get customizationOptionsComingSoon =>
      'Customization options coming soon';

  @override
  String get chooseColorVariant => '1. Choose your preferred color variant';

  @override
  String get iconScalesAutomatically =>
      '2. The icon automatically scales to any size';

  @override
  String get worksOnAllPlatforms => '3. Works perfectly for iOS and Android';

  @override
  String get noExternalDependencies => '4. No external dependencies required';

  @override
  String get canBeCustomizedFurther => '5. Can be customized further if needed';

  @override
  String get blue => 'Blue';

  @override
  String get green => 'Green';

  @override
  String get purple => 'Purple';

  @override
  String get orange => 'Orange';

  @override
  String get size32px => '32px';

  @override
  String get size64px => '64px';

  @override
  String get size128px => '128px';

  @override
  String get size256px => '256px';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get chooseSpeechEngine =>
      'Choose your preferred speech recognition engine';

  @override
  String get hapticFeedbackDescription => 'Vibrate on button presses';

  @override
  String get soundEffectsDescription => 'Play success/error sounds';

  @override
  String get taskCreated => 'Task created successfully';

  @override
  String get errorCreatingTask => 'Error creating task';

  @override
  String get deleteTask => 'Delete Task';

  @override
  String get deleteTaskConfirmation =>
      'Are you sure you want to delete this task?';

  @override
  String get delete => 'Delete';

  @override
  String get taskDeleted => 'Task deleted successfully';

  @override
  String get errorDeletingTask => 'Error deleting task';

  @override
  String get selectTaskList => 'Select a task list';

  @override
  String get addNewTask => 'Add a new task...';

  @override
  String get add => 'Add';

  @override
  String get notConnectedToGoogle => 'Not Connected to Google';

  @override
  String get connectToGoogleToViewTasks =>
      'Connect to Google in Settings to view and manage your tasks';

  @override
  String get errorLoadingTasks => 'Error Loading Tasks';

  @override
  String get noTasksFound => 'No Tasks Found';

  @override
  String get addYourFirstTask => 'Add your first task using the input above';

  @override
  String get hideCompleted => 'Hide Completed';

  @override
  String get showCompleted => 'Show Completed';

  @override
  String get integrations => 'Integrations';

  @override
  String get connectYourServices => 'Connect Your Services';

  @override
  String get integrationsDescription =>
      'Connect to external services to enhance your productivity';

  @override
  String get manageServices => 'Manage Services';

  @override
  String get connecting => 'Connecting...';

  @override
  String get notConnected => 'Not Connected';

  @override
  String get connected => 'Connected';

  @override
  String successfullyConnected(String provider) {
    return 'Successfully connected to $provider';
  }

  @override
  String failedToConnect(String provider) {
    return 'Failed to connect to $provider';
  }

  @override
  String signedOut(String provider) {
    return 'Signed out from $provider';
  }

  @override
  String get language => 'Language';

  @override
  String get chooseLanguage => 'Choose your preferred language';

  @override
  String get readyToRecord => 'Ready to record';

  @override
  String get orTypeYourCommand => 'Or type your command...';

  @override
  String get items => 'items';

  @override
  String get queued => 'Queued';

  @override
  String get failed => 'Failed';

  @override
  String get scheduled => 'Scheduled';

  @override
  String get ago => 'ago';

  @override
  String get photos => 'Photos';

  @override
  String get noCompletedCommandsYet => 'No completed commands yet';

  @override
  String get completedCommandsWillAppearHere =>
      'Completed commands will appear here';

  @override
  String get advanced => 'Advanced';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get getHelpUsingTheApp => 'Get help using the app';

  @override
  String get processingTab => 'Processing';

  @override
  String get completedTab => 'Completed';

  @override
  String get reviewTab => 'Review';

  @override
  String processingItems(int count) {
    return 'Processing ($count items)';
  }

  @override
  String scheduledTime(String time) {
    return 'Scheduled: $time';
  }

  @override
  String photosCount(int count) {
    return 'Photos ($count)';
  }

  @override
  String get play => 'Play';

  @override
  String get recorded => 'Recorded';

  @override
  String get transcribing => 'Transcribing';

  @override
  String get unknown => 'Unknown';

  @override
  String get moreOptions => 'More options';

  @override
  String get edit => 'Edit';

  @override
  String get theme => 'Theme';

  @override
  String get chooseTheme => 'Choose your preferred theme';
}
