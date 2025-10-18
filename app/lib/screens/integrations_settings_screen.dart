import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../integration_manager.dart';
import '../integration_provider.dart';
import '../design_system/tokens.dart';
import '../generated/app_localizations.dart';

class IntegrationsSettingsScreen extends ConsumerWidget {
  const IntegrationsSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final integrationStates = ref.watch(integrationManagerProvider);
    final manager = ref.watch(integrationManagerProvider.notifier);

    return ListView(
        padding: EdgeInsets.all(DesignTokens.layoutPadding),
        children: [
          // Header
          Text(
            AppLocalizations.of(context)!.connectYourServices,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: DesignTokens.spacing2),
          Text(
            AppLocalizations.of(context)!.integrationsDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: DesignTokens.sectionSpacing),

          // Integration Providers (connected first)
          ...() {
            final providers = manager.availableProviders.toList();
            providers.sort((a, b) {
              final aConnected = integrationStates[a.id]?.isAuthenticated ?? false;
              final bConnected = integrationStates[b.id]?.isAuthenticated ?? false;
              if (aConnected && !bConnected) return -1;
              if (!aConnected && bConnected) return 1;
              return 0;
            });
            return providers.map((provider) {
        final state = integrationStates[provider.id];
        return _buildProviderCard(context, ref, provider, state);
            }).toList();
          }(),

          SizedBox(height: DesignTokens.sectionSpacing),
        ],
    );
  }

  Widget _buildProviderCard(BuildContext context, WidgetRef ref, IntegrationProvider provider, IntegrationProviderState? state) {
    final isAuthenticated = state?.isAuthenticated ?? false;
    final isConnecting = state?.isConnecting ?? false;
    final isSyncing = state?.isSyncing ?? false;
    print('🔵 INTEGRATIONS UI: Provider ${provider.id} - isAuthenticated: $isAuthenticated, state: $state');

    return Card(
      margin: EdgeInsets.only(bottom: DesignTokens.componentPadding),
      child: InkWell(
        onTap: (isConnecting || isSyncing) ? null : () {
          if (isAuthenticated) {
            _showServiceManagementDialog(context, ref, provider);
          } else {
            _connectProvider(context, ref, provider);
          }
        },
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.componentPadding),
          child: Row(
            children: [
              // Provider Icon
              Container(
                width: DesignTokens.iconLg,
                height: DesignTokens.iconLg,
                decoration: BoxDecoration(
                  color: _getProviderColor(provider.id),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: Icon(
                  _getProviderIcon(provider.id),
                  color: Colors.white,
                  size: DesignTokens.iconMd,
                ),
              ),
              SizedBox(width: DesignTokens.iconSpacing),
              
              // Provider Name
              Text(
                provider.displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(width: DesignTokens.spacing2),
              
              // Service Icons (always show, but with different states)
              Expanded(
                child: _buildInlineServiceIcons(context, provider, state),
              ),

              // Configure Icon (if authenticated)
              if (isAuthenticated) ...[
                IconButton(
                  onPressed: (isConnecting || isSyncing) ? null : () => _showServiceManagementDialog(context, ref, provider),
                  icon: Icon(Icons.settings, size: DesignTokens.iconSm),
                  tooltip: AppLocalizations.of(context)!.manageServices,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
                SizedBox(width: DesignTokens.spacing1),
              ],

              // Status Indicator
              if (isConnecting) ...[
                Container(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ] else if (isSyncing) ...[
                Container(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ),
              ] else if (isAuthenticated) ...[
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ] else ...[
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }


  void _showServiceManagementDialog(BuildContext context, WidgetRef ref, IntegrationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _ServiceManagementDialog(provider: provider),
    );
  }

  Future<void> _connectProvider(BuildContext context, WidgetRef ref, IntegrationProvider provider) async {
    final manager = ref.read(integrationManagerProvider.notifier);
    final success = await manager.authenticateProvider(provider.id);
    
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.successfullyConnected(provider.displayName)),
          backgroundColor: Colors.green,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToConnect(provider.displayName)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signOutProvider(BuildContext context, WidgetRef ref, IntegrationProvider provider) async {
    final manager = ref.read(integrationManagerProvider.notifier);
    await manager.signOutProvider(provider.id);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.signedOut(provider.displayName)),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Color _getProviderColor(String providerId) {
    switch (providerId) {
      case 'google':
        return Colors.blue;
      case 'apple_notes':
        return Colors.black;
      case 'evernote':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getProviderIcon(String providerId) {
    switch (providerId) {
      case 'google':
        return Icons.g_mobiledata; // Google's G icon from Material Icons
      case 'apple_notes':
        return Icons.apple;
      case 'evernote':
        return Icons.note_alt;
      default:
        return Icons.link;
    }
  }

  IconData _getServiceIcon(String serviceIcon) {
    switch (serviceIcon) {
      case 'tasks':
        return Icons.task_alt;
      case 'calendar':
        return Icons.calendar_today;
      case 'gmail':
        return Icons.email;
      case 'notes':
        return Icons.note;
      case 'notebooks':
        return Icons.folder;
      default:
        return Icons.link;
    }
  }

  String _formatLastSync(String lastSyncTime) {
    try {
      final syncTime = DateTime.parse(lastSyncTime);
      final now = DateTime.now();
      final difference = now.difference(syncTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildInlineServiceIcons(BuildContext context, IntegrationProvider provider, IntegrationProviderState? state) {
    final isAuthenticated = state?.isAuthenticated ?? false;
    
    return Row(
      children: provider.availableServices.map((service) {
        final isConnected = state?.isServiceConnected(service.id) ?? false;
        
        // Show different visual states based on authentication and connection
        Color backgroundColor;
        Color borderColor;
        Color iconColor;
        
        if (!isAuthenticated) {
          // Not authenticated - show greyed out
          backgroundColor = Colors.grey[100]!;
          borderColor = Colors.grey[300]!;
          iconColor = Colors.grey[400]!;
        } else if (isConnected) {
          // Authenticated and connected - show green
          backgroundColor = Colors.green[100]!;
          borderColor = Colors.green[300]!;
          iconColor = Colors.green[700]!;
        } else {
          // Authenticated but not connected - show grey
          backgroundColor = Colors.grey[100]!;
          borderColor = Colors.grey[300]!;
          iconColor = Colors.grey[400]!;
        }
        
        return Container(
          margin: EdgeInsets.only(right: DesignTokens.spacing1),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Icon(
            _getServiceIcon(service.icon),
            size: 14,
            color: iconColor,
          ),
        );
      }).toList(),
    );
  }
}

class _ServiceManagementDialog extends ConsumerWidget {
  final IntegrationProvider provider;

  const _ServiceManagementDialog({required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerStateProvider(provider.id));
    final manager = ref.watch(integrationManagerProvider.notifier);

    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.manageServices),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: provider.availableServices.map((service) {
            final isConnected = state?.isServiceConnected(service.id) ?? false;
            final isSyncing = state?.isSyncing ?? false;

            return SwitchListTile(
              title: Text(service.name),
              subtitle: Text(service.description),
              value: isConnected,
              onChanged: isSyncing ? null : (value) async {
                await manager.toggleService(provider.id, service.id);
              },
              secondary: Icon(_getServiceIcon(service.icon)),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.done),
        ),
      ],
    );
  }

  IconData _getServiceIcon(String serviceIcon) {
    switch (serviceIcon) {
      case 'tasks':
        return Icons.task_alt;
      case 'calendar':
        return Icons.calendar_today;
      case 'gmail':
        return Icons.email;
      case 'notes':
        return Icons.note;
      case 'notebooks':
        return Icons.folder;
      default:
        return Icons.link;
    }
  }
}
