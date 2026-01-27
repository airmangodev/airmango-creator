import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';

import '../../core/theme/theme_provider.dart';
import '../../data/remote/appwrite_service.dart';
import '../auth/auth_view_model.dart';

import '../../data/repositories/media_repository.dart';

/// Provider to calculate storage usage
final storageUsageProvider = FutureProvider<String>((ref) async {
  final authState = ref.watch(authViewModelProvider);
  final userId = authState.valueOrNull?.id;
  
  if (userId == null) return "0 B used";

  try {
    final mediaRepo = ref.read(mediaRepositoryProvider);
    final allMedia = await mediaRepo.getAllUnassignedMedia(userId);
    
    // Get app documents directory for future use
    int totalBytes = 0;
    
    // Calculate total size of media files
    for (final media in allMedia) {
      final file = File(media.filePath);
      if (await file.exists()) {
        totalBytes += await file.length();
      }
    }
    
    // Also scan the app cache directory
    final cacheDir = await getTemporaryDirectory();
    if (await cacheDir.exists()) {
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          try {
            totalBytes += await entity.length();
          } catch (_) {}
        }
      }
    }
    
    // Format size
    if (totalBytes < 1024) {
      return '$totalBytes B used';
    } else if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB used';
    } else if (totalBytes < 1024 * 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB used';
    } else {
      return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB used';
    }
  } catch (e) {
    return 'Unknown';
  }
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeNotifierProvider);
    final storageUsage = ref.watch(storageUsageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgSecondary : AppTheme.bgSecondary,
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.surface,
        elevation: 0,
        foregroundColor: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Account", isDark),
            const Gap(12),
            _buildSettingsCard([
              _buildSettingsTile(
                icon: Icons.person_outline,
                label: "Profile",
                onTap: () => context.push('/profile'),
                isDark: isDark,
              ),
              _buildSettingsTile(
                icon: Icons.sync,
                label: "Sync Status",
                trailing: const Text("Connected", style: TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.bold)),
                isDark: isDark,
              ),
            ], isDark),
            
            const Gap(32),
            _buildSectionHeader("Preferences", isDark),
            const Gap(12),
            _buildSettingsCard([
              _buildSettingsTile(
                icon: Icons.dark_mode_outlined,
                label: "Dark Mode",
                trailing: Switch(
                  value: themeState.isDarkMode,
                  onChanged: (value) {
                    ref.read(themeNotifierProvider.notifier).setDarkMode(value);
                  },
                  activeTrackColor: AppTheme.primary,
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    return null;
                  }),
                ),
                isDark: isDark,
              ),
              _buildSettingsTile(
                icon: Icons.notifications_none,
                label: "Notifications",
                trailing: const Text("Daily Reminders ON", style: TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.bold)),
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Daily reminders are scheduled for 8:00 PM during active trips.')),
                  );
                },
                isDark: isDark,
              ),
            ], isDark),
            
            const Gap(32),
            _buildSectionHeader("Storage", isDark),
            const Gap(12),
            _buildSettingsCard([
              _buildSettingsTile(
                icon: Icons.cloud_outlined,
                label: "Cloud Storage",
                trailing: storageUsage.when(
                  data: (usage) => Text(usage, style: TextStyle(color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted, fontSize: 12)),
                  loading: () => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (_, __) => Text("Unknown", style: TextStyle(color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted, fontSize: 12)),
                ),
                isDark: isDark,
              ),
              _buildSettingsTile(
                icon: Icons.delete_outline,
                label: "Clear Cache",
                onTap: () => _confirmClearCache(context, ref),
                isDark: isDark,
              ),
            ], isDark),
            
            const Gap(48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleLogout(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withAlpha(25),
                  foregroundColor: Colors.red,
                  elevation: 0,
                  side: BorderSide(color: Colors.red.withAlpha(50)),
                ),
                child: const Text("Log Out", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const Gap(24),
            const Center(
              child: Text("Version 1.0.0 (342)", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> tiles, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppTheme.darkBorderColor : AppTheme.borderColor),
      ),
      child: Column(
        children: tiles,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 22),
            const Gap(16),
            Expanded(
              child: Text(label, style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 15,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              )),
            ),
            if (trailing != null) 
              trailing 
            else 
              Icon(Icons.chevron_right, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }


  void _confirmClearCache(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear Cache?"),
        content: const Text("This will remove local temporary files but your journey data in the cloud will remain safe."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearCache(context, ref);
            }, 
            child: const Text("Clear", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache(BuildContext context, WidgetRef ref) async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clearing cache...')),
      );

      // Clear temporary directory
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        int clearedBytes = 0;
        await for (final entity in cacheDir.list(recursive: true)) {
          if (entity is File) {
            try {
              clearedBytes += await entity.length();
              await entity.delete();
            } catch (_) {}
          }
        }
        
        // Refresh storage usage
        ref.invalidate(storageUsageProvider);
        
        // Show success
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cache cleared! Freed ${(clearedBytes / 1024 / 1024).toStringAsFixed(1)} MB'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear cache: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log Out?"),
        content: const Text("Are you sure you want to end your session? Your local data will remain on this device."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Log Out", style: TextStyle(color: Colors.red)),
          ),
        ],
      )
    );

    if (confirmed == true && context.mounted) {
      try {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logging out...')),
        );
        
        // Logout via ViewModel to update app state
        await ref.read(authViewModelProvider.notifier).logout();
        
        // Clear any cached providers
        ref.invalidate(storageUsageProvider);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged out successfully'),
              backgroundColor: AppTheme.success,
            ),
          );
          
          // Router will handle redirect based on auth state change
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }
}
