import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'dart:ui' show PlatformDispatcher;
// import 'package:realm/realm.dart';  // TODO: Add back when implementing local storage

import 'design_system/colors.dart';
import 'design_system/typography.dart';
import 'models/command.dart';
import 'screens/home_screen.dart';
import 'screens/mission_control_screen.dart';
import 'screens/settings_screen.dart';
import 'services/queue_service.dart';

void main() async {
  print('🚀 App starting...');
  
  print('📄 Loading environment variables first...');
  await dotenv.load(fileName: ".env");
  print('✅ Environment variables loaded');
  
  final sentryDsn = dotenv.env['SENTRY_DSN'];
  print('🔍 Sentry DSN found: ${sentryDsn != null ? "YES" : "NO"}');
  if (sentryDsn != null) {
    print('🔍 Sentry DSN: ${sentryDsn.substring(0, 20)}...');
  }
  
  print('🔧 Starting Sentry initialization...');
  final stopwatch = Stopwatch()..start();
  
  try {
    await SentryFlutter.init(
    (options) {
      print('🔧 Configuring Sentry options...');
      options.dsn = sentryDsn; // Use loaded DSN
      options.tracesSampleRate = 1.0; // Capture 100% of transactions for debugging
      options.debug = true; // Enable debug mode
      options.enableAutoPerformanceTracing = false; // Disable profiling to fix C++ compilation
      options.enableAutoSessionTracking = true; // Enable session tracking
      options.attachStacktrace = true; // Include stack traces
      options.sendDefaultPii = false; // Don't send personal info
      
      // Session Replay Configuration
      options.replay.sessionSampleRate = 1.0; // Capture 100% during testing
      options.replay.onErrorSampleRate = 1.0; // Always capture on errors
      // Note: maskAllText and maskAllImages are not available in current Flutter version
      
      // Release tracking
      options.release = 'finally-done@1.0.0+1'; // App version for tracking
      options.dist = '1'; // Build number
      print('✅ Sentry options configured');
    },
    appRunner: () async {
      stopwatch.stop();
      print('⏱️ Sentry initialization took: ${stopwatch.elapsedMilliseconds}ms');
      
      print('📱 Flutter binding initialized');
      WidgetsFlutterBinding.ensureInitialized();
      
      // Set up global error handling
      FlutterError.onError = (FlutterErrorDetails details) {
        print('🚨 Flutter Error: ${details.exception}');
        Sentry.captureException(details.exception, stackTrace: details.stack);
      };
      
      // Set up global zone error handling for async errors
      PlatformDispatcher.instance.onError = (error, stack) {
        print('🚨 Platform Error: $error');
        Sentry.captureException(error, stackTrace: stack);
        return true;
      };
      
      
      print('🔄 Setting device orientation...');
      // Disable auto-rotate for better UX
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
                 print('✅ Device orientation set');

                 print('🎨 Starting app...');
                 runApp(
                   SentryWidget(
                     child: const ProviderScope(
                       child: FinallyDoneApp(),
                     ),
                   ),
                 );
                 print('✅ App started');
    },
  );
  
  print('🏁 Sentry initialization completed');
  } catch (e, stackTrace) {
    stopwatch.stop();
    print('❌ Sentry initialization failed after ${stopwatch.elapsedMilliseconds}ms: $e');
    print('📄 Stack trace: $stackTrace');
    
    // Continue without Sentry
    print('🔄 Continuing without Sentry...');
    WidgetsFlutterBinding.ensureInitialized();
    
    print('🔄 Setting device orientation...');
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    print('✅ Device orientation set');

    print('🎨 Starting app...');
    runApp(
      const ProviderScope(
        child: FinallyDoneApp(),
      ),
    );
    print('✅ App started without Sentry');
  }
}

class FinallyDoneApp extends StatelessWidget {
  const FinallyDoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finally Done',
      debugShowCheckedModeBanner: false,
      
      // Localization
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('lt', 'LT'),
      ],
      
      // Theme
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      
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
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const MissionControlScreen(),
    const SettingsScreen(),
  ];
  
  int _getPendingCount() {
    // Get actual count of failed commands from Mission Control data
    // This will be updated when the provider changes
    return 0; // Will be updated by Consumer widget
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
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Consumer(
              builder: (context, ref, child) {
                final failedCommands = ref.watch(failedCommandsProvider);
                return _buildNotificationIcon(Icons.control_camera_outlined, failedCommands.length);
              },
            ),
            activeIcon: Consumer(
              builder: (context, ref, child) {
                final failedCommands = ref.watch(failedCommandsProvider);
                return _buildNotificationIcon(Icons.control_camera, failedCommands.length);
              },
            ),
            label: 'Mission Control',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}