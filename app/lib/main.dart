import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'generated/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'dart:ui' show PlatformDispatcher;
import 'package:finally_done/utils/retry_mechanism.dart';
import 'package:newrelic_mobile/newrelic_mobile.dart';
import 'package:newrelic_mobile/newrelic_navigation_observer.dart';
import 'package:newrelic_mobile/config.dart';

import 'design_system/colors.dart';
import 'design_system/typography.dart';
import 'screens/home_screen.dart';
import 'screens/mission_control_screen.dart';
import 'screens/settings_tabs_screen.dart';
import 'screens/tasks_screen.dart';
import 'core/commands/queue_service.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'utils/sentry_performance.dart';

void main() async {
  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // Continue with defaults
  }

  // Initialize New Relic (official setup)
  var appToken = '';
  final newRelicToken = dotenv.env['NEW_RELIC_TOKEN'];

  if (newRelicToken != null && newRelicToken.isNotEmpty) {
    appToken = newRelicToken;
  } else {
    return; // Exit early if no token
  }

  final Config config = Config(
    accessToken: appToken,
    analyticsEventEnabled: true,
    networkErrorRequestEnabled: true,
    networkRequestEnabled: true,
    crashReportingEnabled: true,
    interactionTracingEnabled: true,
    httpResponseBodyCaptureEnabled: true,
    loggingEnabled: false, // Disable verbose logging in release mode
    webViewInstrumentation: true,
    printStatementAsEventsEnabled: false, // Disable print statements as events
    httpInstrumentationEnabled: true,
  );

  await NewrelicMobile.instance.startAgent(config);

  final sentryDsn = dotenv.env['SENTRY_DSN'];

  try {
    // Initialize Sentry
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 1.0;
        options.debug = true; // Keep debug mode to see Sentry activity
        options.enableAutoPerformanceTracing = false;
        options.enableAutoSessionTracking = true;
        options.attachStacktrace = true;
        options.sendDefaultPii = false;

        // Session Replay Configuration
        options.replay.sessionSampleRate = 1.0;
        options.replay.onErrorSampleRate = 1.0;

        // Release tracking
        options.release = 'finally-done@1.0.0+1';
        options.dist = '1';
      },
      appRunner: () async {
        // Start Sentry transaction for app startup performance (now that Sentry is ready)
        sentryPerformance.startTransaction(
          'app.startup',
          'app.lifecycle',
        );

        // New Relic will automatically track app startup

        WidgetsFlutterBinding.ensureInitialized();

        // Set up global error handling
        FlutterError.onError = (FlutterErrorDetails details) {
          Sentry.captureException(details.exception, stackTrace: details.stack);
        };

        // Set up global zone error handling for async errors
        PlatformDispatcher.instance.onError = (error, stack) {
          Sentry.captureException(error, stackTrace: stack);
          return true;
        };

        // Device orientation setup
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);

        // App launch
        runApp(
          SentryWidget(
            child: const ProviderScope(
              child: FinallyDoneApp(),
            ),
          ),
        );

        // Finish the main startup transaction
        sentryPerformance.finishTransaction('app.startup');

        // New Relic automatically tracks app startup completion
      },
    );

    // Use retry mechanism to flush queued errors from Swift
    const errorQueueChannel = MethodChannel('error_queue');

    await RetryMechanism.execute(
      () async {
        final result = await errorQueueChannel.invokeMethod('flushQueue');
        final flushedCount = result['count'] as int;

        if (flushedCount == 0) {
          throw Exception(
              'No errors were flushed - SentrySDK may not be ready');
        }
      },
    );
  } catch (e) {
    // Continue without Sentry
    WidgetsFlutterBinding.ensureInitialized();

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    runApp(
      const ProviderScope(
        child: FinallyDoneApp(),
      ),
    );
  }
}

class FinallyDoneApp extends ConsumerWidget {
  const FinallyDoneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(currentLocaleProvider);
    final currentThemeMode = ref.watch(currentFlutterThemeModeProvider);

    return MaterialApp(
      title: 'Finally Done',
      debugShowCheckedModeBanner: false,

      // New Relic Navigation Tracking
      navigatorObservers: [NewRelicNavigationObserver()],

      // Localization
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: currentLocale,

      // Theme
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: currentThemeMode,

      // Home
      home: const MainScreen(),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.backgroundSecondary,
        background: AppColors.background,
        error: AppColors.error,
      ),
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundSecondary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.largeTitle,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundSecondary,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: AppColors.backgroundSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.darkBackgroundSecondary,
        background: AppColors.darkBackground,
        error: AppColors.error,
      ),
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackgroundSecondary,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.largeTitle,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkBackgroundSecondary,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkTextTertiary,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkBackgroundSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  TextTheme _buildTextTheme(Brightness brightness) {
    final textColor = brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final secondaryColor = brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return TextTheme(
      displayLarge: AppTypography.largeTitle.copyWith(color: textColor),
      displayMedium: AppTypography.title1.copyWith(color: textColor),
      displaySmall: AppTypography.title2.copyWith(color: textColor),
      headlineLarge: AppTypography.title3.copyWith(color: textColor),
      headlineMedium: AppTypography.headline.copyWith(color: textColor),
      headlineSmall: AppTypography.headline.copyWith(color: textColor),
      titleLarge: AppTypography.headline.copyWith(color: textColor),
      titleMedium: AppTypography.callout.copyWith(color: textColor),
      titleSmall: AppTypography.subhead.copyWith(color: textColor),
      bodyLarge: AppTypography.body.copyWith(color: textColor),
      bodyMedium: AppTypography.body.copyWith(color: textColor),
      bodySmall: AppTypography.footnote.copyWith(color: secondaryColor),
      labelLarge: AppTypography.button.copyWith(color: textColor),
      labelMedium: AppTypography.caption1.copyWith(color: secondaryColor),
      labelSmall: AppTypography.caption2.copyWith(color: secondaryColor),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const MissionControlScreen(),
      TasksScreen(onNavigateToSettings: () {
        setState(() {
          _currentIndex = 3; // Settings tab
        });
      }),
      const SettingsTabsScreen(),
    ];
  }

  Widget _buildNotificationIcon(IconData icon, int count) {
    return Stack(
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Track screen navigation performance
          final screenNames = ['home', 'mission_control', 'tasks', 'settings'];
          final screenName = screenNames[index];

          sentryPerformance.monitorTransaction(
            'screen.navigation',
            PerformanceOps.screenNavigation,
            () async {
              setState(() {
                _currentIndex = index;
              });
            },
            data: {
              'from_screen': screenNames[_currentIndex],
              'to_screen': screenName,
              'navigation_type': 'bottom_nav',
            },
          );
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: AppLocalizations.of(context)!.home,
          ),
          BottomNavigationBarItem(
            icon: Consumer(
              builder: (context, ref, child) {
                final reviewCommands = ref.watch(reviewCommandsProvider);
                return _buildNotificationIcon(
                    Icons.control_camera_outlined, reviewCommands.length);
              },
            ),
            activeIcon: Consumer(
              builder: (context, ref, child) {
                final reviewCommands = ref.watch(reviewCommandsProvider);
                return _buildNotificationIcon(
                    Icons.control_camera, reviewCommands.length);
              },
            ),
            label: AppLocalizations.of(context)!.missionControl,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.task_alt_outlined),
            activeIcon: const Icon(Icons.task_alt),
            label: AppLocalizations.of(context)!.tasks,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: AppLocalizations.of(context)!.settings,
          ),
        ],
      ),
    );
  }
}
