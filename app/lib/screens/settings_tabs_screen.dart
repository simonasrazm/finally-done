import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design_system/tokens.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../generated/app_localizations.dart';
import '../utils/sentry_performance.dart';
import 'settings_screen.dart';
import 'integrations_settings_screen.dart';

class SettingsTabsScreen extends ConsumerStatefulWidget {
  const SettingsTabsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsTabsScreen> createState() => _SettingsTabsScreenState();
}

class _SettingsTabsScreenState extends ConsumerState<SettingsTabsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    
    // Track screen load performance
    sentryPerformance.monitorTransaction(
      PerformanceTransactions.screenSettings,
      PerformanceOps.screenLoad,
      () async {
        _tabController = TabController(length: 2, vsync: this);
      },
      data: {
        'screen': 'settings',
        'has_tab_controller': true,
        'tab_count': 2,
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: AppTypography.title1.copyWith(
            color: AppColors.getTextPrimaryColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.getBackgroundColor(context),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.getTextSecondaryColor(context),
          indicatorColor: AppColors.primary,
          labelStyle: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTypography.body,
          tabs: [
            Tab(
              icon: Icon(Icons.person_outline),
              text: AppLocalizations.of(context)!.profile,
            ),
            Tab(
              icon: Icon(Icons.integration_instructions),
              text: AppLocalizations.of(context)!.integrations,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Profile & Preferences Tab
          const SettingsScreen(),
          // Integrations Tab
          const IntegrationsSettingsScreen(),
        ],
      ),
    );
  }
}
