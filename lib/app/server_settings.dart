import 'package:flutter/material.dart';

import 'server_address.dart';

/// Validates a dotted-quad IPv4 address without `dart:io`, so this file
/// also compiles for the web target.
bool isValidIPv4(String value) {
  final parts = value.split('.');
  if (parts.length != 4) return false;

  for (final part in parts) {
    if (part.isEmpty || part.length > 3) return false;
    if (part.length > 1 && part.startsWith('0')) return false;
    final octet = int.tryParse(part);
    if (octet == null || octet < 0 || octet > 255) return false;
    if (!RegExp(r'^[0-9]+$').hasMatch(part)) return false;
  }
  return true;
}

class AppSettings extends ChangeNotifier {
  AppSettings({String? initialHost})
    : _host = initialHost ?? (_envHost.isEmpty ? '127.0.0.1' : _envHost);

  /// Set with `--dart-define=SERVER_HOST=…` to skip typing the IP.
  static const String _envHost = String.fromEnvironment('SERVER_HOST');

  static const int serverPort = 8080;

  String _host;

  String get host => _host;

  ServerAddress get serverAddress =>
      ServerAddress(host: _host, port: serverPort);

  void setHost(String value) {
    final nextHost = value.trim();
    if (_host == nextHost) return;

    _host = nextHost;
    notifyListeners();
  }
}

class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    required AppSettings settings,
    required super.child,
    super.key,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>();

    assert(scope != null, 'AppSettingsScope not found in widget tree.');
    return scope!.notifier!;
  }

  static AppSettings read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppSettingsScope>();

    assert(scope != null, 'AppSettingsScope not found in widget tree.');
    return scope!.notifier!;
  }
}

class ServerSettingsAction extends StatelessWidget {
  const ServerSettingsAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Server IP settings',
      icon: const Icon(Icons.settings_ethernet),
      onPressed: () => _showSettingsDialog(context),
    );
  }

  Future<void> _showSettingsDialog(BuildContext context) async {
    final settings = AppSettingsScope.read(context);
    final controller = TextEditingController(text: settings.host);
    final formKey = GlobalKey<FormState>();

    final host = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Server configuration'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Server IP address',
                hintText: 'e.g. 192.168.1.20',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (!isValidIPv4(value?.trim() ?? '')) {
                  return 'Enter a valid IPv4 address';
                }
                return null;
              },
              onFieldSubmitted: (_) {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (host != null) {
      settings.setHost(host);
    }
  }
}
