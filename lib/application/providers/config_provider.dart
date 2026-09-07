import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/direccion.dart';

class ConfigEstado {
  final String valorConexionPorDefecto;
  final ThemeMode themeMode;
  final Direccion tipoConexionPorDefecto;

  const ConfigEstado({
    this.valorConexionPorDefecto = '1',
    this.themeMode = ThemeMode.system, // Default to System theme
    this.tipoConexionPorDefecto = Direccion.unidireccional,
  });

  ConfigEstado copyWith({
    String? valorConexionPorDefecto,
    ThemeMode? themeMode,
    Direccion? tipoConexionPorDefecto,
  }) {
    return ConfigEstado(
      valorConexionPorDefecto:
          valorConexionPorDefecto ?? this.valorConexionPorDefecto,
      themeMode: themeMode ?? this.themeMode,
      tipoConexionPorDefecto:
          tipoConexionPorDefecto ?? this.tipoConexionPorDefecto,
    );
  }

  static const initial = ConfigEstado();
}

class ConfigNotifier extends Notifier<ConfigEstado> {
  static const String _prefThemeKey = 'app_theme_mode';
  static const String _prefConnTypeKey = 'app_default_conn_type';

  @override
  ConfigEstado build() {
    _loadSavedConfig();
    return ConfigEstado.initial;
  }

  Future<void> _loadSavedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_prefThemeKey);
      ThemeMode mode = state.themeMode;
      if (savedTheme != null) {
        if (savedTheme == 'light') mode = ThemeMode.light;
        if (savedTheme == 'dark') mode = ThemeMode.dark;
        if (savedTheme == 'system') mode = ThemeMode.system;
      }

      final savedConnType = prefs.getString(_prefConnTypeKey);
      Direccion connType = state.tipoConexionPorDefecto;
      if (savedConnType != null) {
        if (savedConnType == 'ninguna') {
          connType = Direccion.ninguna;
        }
        if (savedConnType == 'unidireccional') {
          connType = Direccion.unidireccional;
        }
      }

      state = state.copyWith(themeMode: mode, tipoConexionPorDefecto: connType);
    } catch (_) {
      // Fallback cleanly if SharedPreferences is unavailable in preview/test environment
    }
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = mode == ThemeMode.light
          ? 'light'
          : (mode == ThemeMode.dark ? 'dark' : 'system');
      await prefs.setString(_prefThemeKey, str);
    } catch (_) {}
  }

  Future<void> _saveConnType(Direccion type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefConnTypeKey, type.name);
    } catch (_) {}
  }

  void setValorConexionPorDefecto(String val) {
    state = state.copyWith(valorConexionPorDefecto: val);
  }

  void setTipoConexionPorDefecto(Direccion type) {
    state = state.copyWith(tipoConexionPorDefecto: type);
    _saveConnType(type);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _saveTheme(mode);
  }

  void toggleTheme() {
    final next = state.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    state = state.copyWith(themeMode: next);
    _saveTheme(next);
  }
}

final configProvider = NotifierProvider<ConfigNotifier, ConfigEstado>(() {
  return ConfigNotifier();
});
