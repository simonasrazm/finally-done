import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../services/speech_service.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.getBackgroundColor(context),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Profile Section
          _buildSection(
            title: 'Profile',
            children: [
              _buildListTile(
                leading: const Icon(Icons.person_outline),
                title: 'Name',
                subtitle: 'Enter your name',
                trailing: SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: AppTypography.body,
                  ),
                ),
              ),
            ],
          ),
          
          // Connected Services Section
          _buildSection(
            title: 'Connected Services',
            children: [
              _buildServiceTile(
                icon: Icons.task_alt,
                title: 'Google Tasks',
                subtitle: 'Manage your tasks',
                isConnected: true,
                onTap: () => _showServiceDialog('Google Tasks'),
              ),
              _buildServiceTile(
                icon: Icons.calendar_today,
                title: 'Google Calendar',
                subtitle: 'Schedule your events',
                isConnected: true,
                onTap: () => _showServiceDialog('Google Calendar'),
              ),
              _buildServiceTile(
                icon: Icons.note_alt,
                title: 'Evernote',
                subtitle: 'Store your notes',
                isConnected: false,
                onTap: () => _showServiceDialog('Evernote'),
              ),
              _buildServiceTile(
                icon: Icons.notes,
                title: 'Apple Notes',
                subtitle: 'Local note storage',
                isConnected: true,
                onTap: () => _showServiceDialog('Apple Notes'),
              ),
              _buildServiceTile(
                icon: Icons.alarm,
                title: 'Custom Alarms',
                subtitle: 'Works like iPhone Clock app',
                isConnected: false,
                onTap: () => _showServiceDialog('Custom Alarms'),
              ),
            ],
          ),
          
          // Preferences Section
          _buildSection(
            title: 'Preferences',
            children: [
              _buildListTile(
                leading: const Icon(Icons.psychology),
                title: 'Speech Engine',
                subtitle: 'Choose your preferred speech recognition engine',
                trailing: Consumer(
                  builder: (context, ref, child) {
                    final enginePreference = ref.watch(speechEngineProvider);
                    return DropdownButton<String>(
                      value: enginePreference,
                      onChanged: (String? newValue) {
                        ref.read(speechEngineProvider.notifier).setEngine(newValue!);
                      },
                      items: const [
                        DropdownMenuItem(value: 'auto', child: Text('Auto (iOS + Gemini)')),
                        DropdownMenuItem(value: 'ios', child: Text('iOS Native')),
                        DropdownMenuItem(value: 'gemini', child: Text('Gemini Pro')),
                      ],
                    );
                  },
                ),
              ),
              _buildListTile(
                leading: const Icon(Icons.analytics),
                title: 'Confidence Threshold',
                subtitle: 'Commands below this threshold need review',
                trailing: SizedBox(
                  width: 100,
                  child: Text('${(_confidenceThreshold * 100).round()}%'),
                ),
                onTap: () => _showConfidenceDialog(),
              ),
              _buildSwitchTile(
                leading: const Icon(Icons.vibration),
                title: 'Haptic Feedback',
                subtitle: 'Vibrate on button presses',
                value: _hapticEnabled,
                onChanged: (value) {
                  setState(() {
                    _hapticEnabled = value;
                  });
                },
              ),
              _buildSwitchTile(
                leading: const Icon(Icons.volume_up),
                title: 'Sounds',
                subtitle: 'Play success/error sounds',
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
            title: 'Advanced',
            children: [
              _buildListTile(
                leading: const Icon(Icons.info_outline),
                title: 'About',
                subtitle: 'Version 1.0.0',
                onTap: () => _showAboutDialog(),
              ),
              _buildListTile(
                leading: const Icon(Icons.help_outline),
                title: 'Help & Support',
                subtitle: 'Get help using the app',
                onTap: () => _showHelpDialog(),
              ),
            ],
          ),
        ],
      ),
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
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.sectionHeader.copyWith(
              color: AppColors.getTextSecondaryColor(context),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
  
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
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
  
  void _showServiceDialog(String service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$service Integration'),
        content: Text('Connect to $service to sync your data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement service connection
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
  
  void _showConfidenceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confidence Threshold'),
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
            const Text('Commands below this threshold will need manual review.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
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
