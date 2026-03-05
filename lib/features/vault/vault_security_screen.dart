import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/providers/vault_security_provider.dart';

class VaultSecurityScreen extends ConsumerStatefulWidget {
  const VaultSecurityScreen({super.key});

  @override
  ConsumerState<VaultSecurityScreen> createState() => _VaultSecurityScreenState();
}

class _VaultSecurityScreenState extends ConsumerState<VaultSecurityScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _busy = false;
  List<BiometricType> _available = const [];

  @override
  void initState() {
    super.initState();
    _loadBiometrics();
  }

  Future<void> _loadBiometrics() async {
    try {
      final available = await _auth.getAvailableBiometrics();
      if (!mounted) return;
      setState(() => _available = available);
    } on PlatformException {
      if (!mounted) return;
      setState(() => _available = const []);
    }
  }

  Future<void> _setBiometricEnabled(bool value) async {
    setState(() => _busy = true);
    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      if (!canCheckBiometrics && !supported) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric authentication is not available on this device.')),
          );
        }
        await ref.read(vaultSecurityProvider.notifier).setBiometricEnabled(false);
      } else if (value) {
        final didAuthenticate = await _auth.authenticate(
          localizedReason: 'Authenticate to enable biometric lock for Vault',
          biometricOnly: true,
        );
        await ref.read(vaultSecurityProvider.notifier).setBiometricEnabled(didAuthenticate);
        if (!didAuthenticate && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric enrollment/authentication was not completed.')),
          );
        }
      } else {
        await ref.read(vaultSecurityProvider.notifier).setBiometricEnabled(false);
      }
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update biometric setting.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _showEnrollPinDialog() async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Vault PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'PIN (4-6 digits)'),
            ),
            TextField(
              controller: confirmController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'Confirm PIN'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final pin = pinController.text.trim();
              final confirm = confirmController.text.trim();
              final validLength = pin.length >= 4 && pin.length <= 6;
              final numeric = RegExp(r'^\d+$').hasMatch(pin);

              if (!validLength || !numeric) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN must be 4 to 6 digits.')),
                );
                return;
              }
              if (pin != confirm) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN confirmation does not match.')),
                );
                return;
              }

              await ref.read(vaultSecurityProvider.notifier).enrollPin(pin);
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vault PIN enrolled successfully.')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(vaultSecurityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Vault Security')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.pin),
            title: Text(settings.hasPin ? 'Change PIN' : 'Enroll PIN'),
            subtitle: Text(settings.hasPin ? 'PIN lock is configured' : 'Set a PIN to unlock Vault'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showEnrollPinDialog,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.lock),
            title: const Text('Enable PIN lock'),
            subtitle: const Text('Use PIN to unlock Vault'),
            value: settings.pinEnabled && settings.hasPin,
            onChanged: settings.hasPin
                ? (value) => ref.read(vaultSecurityProvider.notifier).setPinEnabled(value)
                : null,
          ),
          if (settings.hasPin)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove PIN', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await ref.read(vaultSecurityProvider.notifier).clearPin();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vault PIN removed.')),
                );
              },
            ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Enable biometric lock'),
            subtitle: const Text('Use fingerprint or face unlock to open Vault'),
            value: settings.biometricEnabled,
            onChanged: _busy ? null : _setBiometricEnabled,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.face),
            title: const Text('Prefer face unlock'),
            subtitle: const Text('Use face unlock when available'),
            value: settings.preferFaceUnlock,
            onChanged: settings.biometricEnabled
                ? (value) => ref.read(vaultSecurityProvider.notifier).setPreferFaceUnlock(value)
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text('Enrolled biometrics'),
            subtitle: Text(
              _available.isEmpty
                  ? 'No enrolled biometrics detected'
                  : _available.map((b) => _biometricLabel(b)).join(', '),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadBiometrics,
            ),
          ),
        ],
      ),
    );
  }

  String _biometricLabel(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.strong:
        return 'Strong';
      case BiometricType.weak:
        return 'Weak';
      default:
        return 'Biometric';
    }
  }
}
