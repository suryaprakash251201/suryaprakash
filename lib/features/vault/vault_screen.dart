import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

import '../../core/models/models.dart';
import '../../core/providers/vault_security_provider.dart';
import '../../core/providers/vault_providers.dart';
import 'add_edit_vault_item_screen.dart';
import 'vault_security_screen.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptUnlock();
    });
  }

  Future<void> _attemptUnlock({bool forcePinFirst = false}) async {
    setState(() => _isAuthenticating = true);

    await ref.read(vaultSecurityProvider.notifier).refresh();
    final settings = ref.read(vaultSecurityProvider);
    if (!settings.hasAnyLock) {
      if (mounted) {
        setState(() {
          _isAuthenticated = true;
          _isAuthenticating = false;
        });
      }
      return;
    }

    bool unlocked = false;

    if (!forcePinFirst && settings.biometricEnabled) {
      unlocked = await _authenticateWithBiometric(preferFace: settings.preferFaceUnlock);
    }

    if (!unlocked && settings.pinEnabled && settings.hasPin) {
      unlocked = await _authenticateWithPin();
    }

    if (mounted) {
      setState(() {
        _isAuthenticated = unlocked;
        _isAuthenticating = false;
      });
    }
  }

  Future<bool> _authenticateWithBiometric({required bool preferFace}) async {
    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (!canCheckBiometrics && !isSupported) {
        return false;
      }

      if (preferFace) {
        final available = await _auth.getAvailableBiometrics();
        if (!available.contains(BiometricType.face)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Face unlock is not enrolled on this device.')),
            );
          }
          return false;
        }
      }

      return _auth.authenticate(
        localizedReason: preferFace
            ? 'Authenticate with face unlock to open Vault'
            : 'Authenticate to access the Vault',
        biometricOnly: true,
      );
    } on PlatformException {
      return false;
    }
  }

  Future<bool> _authenticateWithPin() async {
    final pinController = TextEditingController();
    var unlocked = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter Vault PIN'),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'PIN'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final isValid = await ref
                  .read(vaultSecurityProvider.notifier)
                  .verifyPin(pinController.text.trim());
              if (isValid) {
                unlocked = true;
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                return;
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect PIN.')),
                );
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );

    return unlocked;
  }

  void _openVaultSecuritySettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const VaultSecurityScreen()),
    ).then((_) => ref.read(vaultSecurityProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final security = ref.watch(vaultSecurityProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : theme.colorScheme.surface;

    if (_isAuthenticating) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text('Vault', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              onPressed: _openVaultSecuritySettings,
              icon: const Icon(Icons.shield),
              tooltip: 'Vault Security Settings',
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              const Text('Vault is locked', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Unlock using enrolled security method'),
              const SizedBox(height: 24),
              if (security.biometricEnabled)
                ElevatedButton.icon(
                  onPressed: () => _attemptUnlock(),
                  icon: Icon(security.preferFaceUnlock ? Icons.face : Icons.fingerprint),
                  label: Text(security.preferFaceUnlock ? 'Unlock with Face' : 'Unlock with Biometrics'),
                ),
              if (security.pinEnabled && security.hasPin) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _attemptUnlock(forcePinFirst: true),
                  icon: const Icon(Icons.pin),
                  label: const Text('Unlock with PIN'),
                ),
              ],
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _openVaultSecuritySettings,
                icon: const Icon(Icons.settings),
                label: const Text('Security Settings / Enroll'),
              ),
            ],
          ),
        ),
      );
    }

    final itemsAsync = ref.watch(vaultItemsProvider);
    final selectedCategory = ref.watch(selectedVaultCategoryProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Vault', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _openVaultSecuritySettings,
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Vault Security',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(theme, isDark, selectedCategory),
          const SizedBox(height: 16),
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return _buildEmptyState(theme, selectedCategory);
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 100),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _VaultItemCard(item: item, theme: theme, isDark: isDark);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: \$err')),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddEditVaultItemScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }

  Widget _buildCategoryFilter(ThemeData theme, bool isDark, String selectedCategory) {
    final categories = [
      {'id': 'all', 'label': 'All'},
      {'id': 'password', 'label': 'Passwords'},
      {'id': 'document', 'label': 'Documents'},
      {'id': 'id_card', 'label': 'ID Cards'},
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat['id'] == selectedCategory;
          
          return ChoiceChip(
            label: Text(cat['label']!),
            selected: isSelected,
            onSelected: (_) => ref.read(selectedVaultCategoryProvider.notifier).updateCategory(cat['id']!),
            selectedColor: theme.colorScheme.primaryContainer,
            labelStyle: TextStyle(
              color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : theme.colorScheme.surfaceContainer,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String category) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 48, color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            category == 'all' ? 'Vault is empty' : 'No items in this category',
            style: theme.textTheme.bodyLarge?.copyWith(
               color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _VaultItemCard extends ConsumerWidget {
  final VaultItem item;
  final ThemeData theme;
  final bool isDark;

  const _VaultItemCard({required this.item, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AddEditVaultItemScreen(existingItem: item)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getCategoryColor(item.category).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  IconData(item.iconCode, fontFamily: 'MaterialIcons'),
                  color: _getCategoryColor(item.category),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '••••••••••••', // Mask data in list view
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'password':
        return Colors.blue;
      case 'document':
        return Colors.orange;
      case 'id_card':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
