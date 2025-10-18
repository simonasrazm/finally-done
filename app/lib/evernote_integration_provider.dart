import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'integration_provider.dart';

/// Evernote integration provider (placeholder)
class EvernoteIntegrationProvider extends IntegrationProvider {
  EvernoteIntegrationProvider() : super(
    id: 'evernote',
    displayName: 'Evernote',
    icon: 'evernote',
    description: 'Connect to Evernote for note and document management',
  );

  @override
  List<IntegrationService> get availableServices => [
    const IntegrationService(
      id: 'notes',
      name: 'Evernote Notes',
      description: 'Access and manage your Evernote notes',
      icon: 'notes',
    ),
    const IntegrationService(
      id: 'notebooks',
      name: 'Evernote Notebooks',
      description: 'Organize notes into notebooks',
      icon: 'folder',
    ),
  ];

  @override
  Future<bool> authenticate() async {
    // TODO: Implement Evernote authentication
    return false;
  }

  @override
  Future<bool> connectServices(List<String> serviceIds) async {
    // TODO: Implement Evernote service connection
    return false;
  }

  @override
  Future<bool> disconnectServices(List<String> serviceIds) async {
    // TODO: Implement Evernote service disconnection
    return false;
  }

  @override
  Future<bool> toggleService(String serviceId) async {
    // TODO: Implement Evernote service toggle
    return false;
  }

  @override
  Future<void> signOut() async {
    // TODO: Implement Evernote sign out
  }
}
