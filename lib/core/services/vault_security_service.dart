import 'package:shared_preferences/shared_preferences.dart';

class VaultSecuritySettings {
  final bool pinEnabled;
  final String pin;
  final bool biometricEnabled;
  final bool preferFaceUnlock;

  const VaultSecuritySettings({
    required this.pinEnabled,
    required this.pin,
    required this.biometricEnabled,
    required this.preferFaceUnlock,
  });

  bool get hasPin => pin.isNotEmpty;
  bool get hasAnyLock => (pinEnabled && hasPin) || biometricEnabled;

  VaultSecuritySettings copyWith({
    bool? pinEnabled,
    String? pin,
    bool? biometricEnabled,
    bool? preferFaceUnlock,
  }) {
    return VaultSecuritySettings(
      pinEnabled: pinEnabled ?? this.pinEnabled,
      pin: pin ?? this.pin,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      preferFaceUnlock: preferFaceUnlock ?? this.preferFaceUnlock,
    );
  }
}

class VaultSecurityService {
  static const _pinKey = 'vault_lock_pin';
  static const _pinEnabledKey = 'vault_lock_pin_enabled';
  static const _biometricEnabledKey = 'vault_lock_biometric_enabled';
  static const _preferFaceKey = 'vault_lock_prefer_face';

  Future<VaultSecuritySettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return VaultSecuritySettings(
      pinEnabled: prefs.getBool(_pinEnabledKey) ?? false,
      pin: prefs.getString(_pinKey) ?? '',
      biometricEnabled: prefs.getBool(_biometricEnabledKey) ?? false,
      preferFaceUnlock: prefs.getBool(_preferFaceKey) ?? false,
    );
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
    await prefs.setBool(_pinEnabledKey, true);
  }

  Future<void> setPinEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinEnabledKey, enabled);
  }

  Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.setBool(_pinEnabledKey, false);
  }

  Future<bool> verifyPin(String input) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(_pinKey) ?? '';
    return savedPin.isNotEmpty && input == savedPin;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  Future<void> setPreferFaceUnlock(bool preferFace) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_preferFaceKey, preferFace);
  }
}
