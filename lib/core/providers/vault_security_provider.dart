import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/vault_security_service.dart';

final vaultSecurityServiceProvider = Provider((ref) => VaultSecurityService());

class VaultSecurityNotifier extends Notifier<VaultSecuritySettings> {
  @override
  VaultSecuritySettings build() {
    _load();
    return const VaultSecuritySettings(
      pinEnabled: false,
      pin: '',
      biometricEnabled: false,
      preferFaceUnlock: false,
    );
  }

  Future<void> _load() async {
    final settings = await ref.read(vaultSecurityServiceProvider).loadSettings();
    state = settings;
  }

  Future<void> refresh() async {
    await _load();
  }

  Future<void> enrollPin(String pin) async {
    await ref.read(vaultSecurityServiceProvider).setPin(pin);
    state = state.copyWith(pin: pin, pinEnabled: true);
  }

  Future<void> setPinEnabled(bool enabled) async {
    await ref.read(vaultSecurityServiceProvider).setPinEnabled(enabled);
    state = state.copyWith(pinEnabled: enabled);
  }

  Future<void> clearPin() async {
    await ref.read(vaultSecurityServiceProvider).clearPin();
    state = state.copyWith(pin: '', pinEnabled: false);
  }

  Future<bool> verifyPin(String pin) {
    return ref.read(vaultSecurityServiceProvider).verifyPin(pin);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await ref.read(vaultSecurityServiceProvider).setBiometricEnabled(enabled);
    state = state.copyWith(biometricEnabled: enabled);
  }

  Future<void> setPreferFaceUnlock(bool preferFace) async {
    await ref.read(vaultSecurityServiceProvider).setPreferFaceUnlock(preferFace);
    state = state.copyWith(preferFaceUnlock: preferFace);
  }
}

final vaultSecurityProvider = NotifierProvider<VaultSecurityNotifier, VaultSecuritySettings>(
  VaultSecurityNotifier.new,
);
