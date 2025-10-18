import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/tokens.dart';
import '../services/speech_service.dart';
import '../services/integration_service.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../generated/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  double _confidenceThreshold = 0.7;
  bool _hapticEnabled = true;
  bool _soundEnabled = true;
  @override
  void initState() {
    super.initState();
    _nameController.text = 'Simonas'; // Default for MVP
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView(
        children: [
          // Profile Section
          _buildSection(
            title: AppLocalizations.of(context)!.profile,
            children: [
              _buildListTile(
                leading: const Icon(Icons.person_outline),
                title: AppLocalizations.of(context)!.name,
                subtitle: AppLocalizations.of(context)!.enterYourName,
                trailing: SizedBox(
                  width: DesignTokens.inputWidthLg,
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.inputPadding,
                        vertical: DesignTokens.spacing2,
                      ),
                    ),
                    style: AppTypography.body,
                  ),
                ),
              ),
            ],
          ),
          
          
          // Preferences Section
          _buildSection(
            title: AppLocalizations.of(context)!.preferences,
            children: [
              _buildListTile(
                leading: const Icon(Icons.language),
                title: AppLocalizations.of(context)!.language,
                subtitle: AppLocalizations.of(context)!.chooseLanguage,
                trailing: Consumer(
                  builder: (context, ref, child) {
                    final languageState = ref.watch(languageProvider);
                    final languageNotifier = ref.read(languageProvider.notifier);
                    
                    return DropdownButton<Locale>(
                      value: languageState.locale,
                      onChanged: (Locale? newLocale) {
                        if (newLocale != null) {
                          languageNotifier.changeLanguage(newLocale);
                        }
                      },
                      items: languageNotifier.availableLanguages.map((lang) {
                        return DropdownMenuItem<Locale>(
                          value: Locale(lang['code']),
                          child: Text('${lang['flag']} ${lang['name']}'),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              _buildListTile(
                leading: const Icon(Icons.palette_outlined),
                title: AppLocalizations.of(context)!.theme,
                subtitle: AppLocalizations.of(context)!.chooseTheme,
                trailing: Consumer(
                  builder: (context, ref, child) {
                    final themeState = ref.watch(themeProvider);
                    final themeNotifier = ref.read(themeProvider.notifier);
                    
                    return DropdownButton<AppThemeMode>(
                      value: themeState.mode,
                      onChanged: (AppThemeMode? newMode) {
                        if (newMode != null) {
                          themeNotifier.changeThemeMode(newMode);
                        }
                      },
                      items: themeNotifier.availableModes.map((modeData) {
                        final mode = modeData['mode'] as AppThemeMode;
                        return DropdownMenuItem<AppThemeMode>(
                          value: mode,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                modeData['icon'] as IconData,
                                size: DesignTokens.iconSm,
                              ),
                              SizedBox(width: DesignTokens.spacing2),
                              Text(modeData['name'] as String),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              _buildListTile(
                leading: const Icon(Icons.psychology),
                title: AppLocalizations.of(context)!.speechRecognition,
                subtitle: AppLocalizations.of(context)!.chooseSpeechEngine,
                trailing: Consumer(
                  builder: (context, ref, child) {
                    final enginePreference = ref.watch(speechEngineProvider);
                    return DropdownButton<String>(
                      value: enginePreference,
                      onChanged: (String? newValue) {
                        ref.read(speechEngineProvider.notifier).setEngine(newValue!);
                      },
                      items: [
                        DropdownMenuItem(value: 'auto', child: Text(AppLocalizations.of(context)!.autoIosGemini)),
                        DropdownMenuItem(value: 'ios', child: Text(AppLocalizations.of(context)!.iosNative)),
                        DropdownMenuItem(value: 'gemini', child: Text(AppLocalizations.of(context)!.geminiPro)),
                      ],
                    );
                  },
                ),
              ),
              _buildListTile(
                leading: const Icon(Icons.analytics),
                title: AppLocalizations.of(context)!.confidenceThreshold,
                subtitle: AppLocalizations.of(context)!.confidenceThresholdDescription,
                trailing: SizedBox(
                  width: DesignTokens.inputWidthMd,
                  child: Text(AppLocalizations.of(context)!.confidencePercentage((_confidenceThreshold * 100).round())),
                ),
                onTap: () => _showConfidenceDialog(),
              ),
              _buildSwitchTile(
                leading: const Icon(Icons.vibration),
                title: AppLocalizations.of(context)!.hapticFeedback,
                subtitle: AppLocalizations.of(context)!.hapticFeedbackDescription,
                value: _hapticEnabled,
                onChanged: (value) {
                  setState(() {
                    _hapticEnabled = value;
                  });
                },
              ),
              _buildSwitchTile(
                leading: const Icon(Icons.volume_up),
                title: AppLocalizations.of(context)!.soundEffects,
                subtitle: AppLocalizations.of(context)!.soundEffectsDescription,
                value: _soundEnabled,
                onChanged: (value) {
                  setState(() {
                    _soundEnabled = value;
                  });
                },
              ),
            ],
          ),
          
          // Advanced Section
          _buildSection(
            title: AppLocalizations.of(context)!.advanced,
            children: [
              _buildListTile(
                leading: const Icon(Icons.info_outline),
                title: AppLocalizations.of(context)!.about,
                subtitle: '${AppLocalizations.of(context)!.version} 1.0.0',
                onTap: () => _showAboutDialog(),
              ),
              _buildListTile(
                leading: const Icon(Icons.help_outline),
                title: AppLocalizations.of(context)!.helpAndSupport,
                subtitle: AppLocalizations.of(context)!.getHelpUsingTheApp,
                onTap: () => _showHelpDialog(),
              ),
            ],
          ),
        ],
    );
  }
  
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
          DesignTokens.layoutPadding,
          DesignTokens.sectionSpacing,
          DesignTokens.layoutPadding,
          DesignTokens.spacing2,
        ),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.sectionHeader.copyWith(
              color: AppColors.getTextPrimaryColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
  
  Widget _buildListTile({
    required Widget leading,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: leading,
      title: Text(title, style: AppTypography.body),
      subtitle: subtitle != null 
          ? Text(subtitle, style: AppTypography.footnote)
          : null,
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: DesignTokens.componentPadding,
        vertical: DesignTokens.spacing1,
      ),
    );
  }
  
  Widget _buildSwitchTile({
    required Widget leading,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: leading,
      title: Text(title, style: AppTypography.body),
      subtitle: subtitle != null 
          ? Text(subtitle, style: AppTypography.footnote)
          : null,
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.symmetric(
        horizontal: DesignTokens.componentPadding,
        vertical: DesignTokens.spacing1,
      ),
    );
  }
  
  /*
  Widget _buildGoogleIntegrationTile({
    required bool isAuthenticated,
    String? userEmail,
    required Set<String> connectedServices,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        Icons.account_circle,
        color: isAuthenticated ? AppColors.primary : AppColors.getTextSecondaryColor(context),
        size: 28,
      ),
          title: Text(
            AppLocalizations.of(context)!.googleAccount,
            style: AppTypography.body.copyWith(
              color: AppColors.getTextPrimaryColor(context),
              fontWeight: isAuthenticated ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            isAuthenticated 
                ? _buildConnectedServicesText(userEmail, connectedServices)
                : AppLocalizations.of(context)!.connectToGoogle,
        style: AppTypography.footnote.copyWith(
          color: AppColors.getTextSecondaryColor(context),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAuthenticated ? Icons.check_circle : Icons.circle_outlined,
            color: isAuthenticated ? AppColors.success : AppColors.textTertiary,
            size: 20,
          ),
          const SizedBox(width: DesignTokens.iconSpacing),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
          onTap: () {
            // Use microtask to let ripple animation complete before heavy work
            Future.microtask(() => onTap());
          },
      contentPadding: EdgeInsets.symmetric(
        horizontal: DesignTokens.componentPadding,
        vertical: DesignTokens.spacing2,
      ),
    );
  }
  
  
  String _buildConnectedServicesText(String? userEmail, Set<String> connectedServices) {
    final List<String> serviceNames = [];
    
    if (connectedServices.contains('tasks')) serviceNames.add('Tasks');
    if (connectedServices.contains('calendar')) serviceNames.add('Calendar');
    if (connectedServices.contains('gmail')) serviceNames.add('Gmail');
    
    final servicesText = serviceNames.isEmpty 
        ? 'No services connected'
        : serviceNames.join(' • ');
    
    return 'Connected as: $userEmail\n$servicesText';
  }
  
  */

  Widget _buildServiceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isConnected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: AppTypography.body),
      subtitle: Text(subtitle, style: AppTypography.footnote),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.check_circle : Icons.circle_outlined,
            color: isConnected ? AppColors.success : AppColors.textTertiary,
            size: 20,
          ),
          const SizedBox(width: DesignTokens.iconSpacing),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: DesignTokens.componentPadding,
        vertical: DesignTokens.spacing1,
      ),
    );
  }
  
  
  
  void _showConfidenceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confidenceThreshold),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${(_confidenceThreshold * 100).round()}%'),
            Slider(
              value: _confidenceThreshold,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              onChanged: (value) {
                setState(() {
                  _confidenceThreshold = value;
                });
              },
            ),
            Text(AppLocalizations.of(context)!.confidenceThresholdDescription),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.done),
          ),
        ],
      ),
    );
  }
  
  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Finally Done',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.mic, size: 48),
      children: [
        const Text('AI-powered personal organization app that helps you capture and organize tasks, events, and notes through voice commands.'),
      ],
    );
  }
  
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text('For help and support, please contact us at support@finallydone.app'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
