import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode state
class ThemeState {
  final ThemeMode themeMode;
  final bool isInitialized;

  const ThemeState({
    this.themeMode = ThemeMode.light,
    this.isInitialized = false,
  });

  bool get isDarkMode => themeMode == ThemeMode.dark;

  ThemeState copyWith({
    ThemeMode? themeMode,
    bool? isInitialized,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

/// Theme notifier for managing app theme
class ThemeNotifier extends StateNotifier<ThemeState> {
  static const String _themeKey = 'app_theme_mode';
  
  ThemeNotifier() : super(const ThemeState()) {
    _loadTheme();
  }

  /// Load theme preference from SharedPreferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString(_themeKey);
      
      ThemeMode mode = ThemeMode.light;
      if (themeString == 'dark') {
        mode = ThemeMode.dark;
      } else if (themeString == 'system') {
        mode = ThemeMode.system;
      }
      
      state = state.copyWith(themeMode: mode, isInitialized: true);
    } catch (e) {
      // Default to light mode on error
      state = state.copyWith(themeMode: ThemeMode.light, isInitialized: true);
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleDarkMode() async {
    final newMode = state.isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeString;
      switch (mode) {
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        case ThemeMode.system:
          themeString = 'system';
          break;
        default:
          themeString = 'light';
      }
      await prefs.setString(_themeKey, themeString);
    } catch (e) {
      debugPrint('Failed to save theme preference: $e');
    }
  }

  /// Set dark mode directly
  Future<void> setDarkMode(bool isDark) async {
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}

/// Provider for theme state
final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});
