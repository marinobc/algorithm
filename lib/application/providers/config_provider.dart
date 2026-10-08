import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/direccion.dart';
import '../../domain/models/modo_tipo_nodo.dart';

class ConfigEstado {
  final ThemeMode themeMode;
  final Direccion tipoConexionPorDefecto;
  final ModoTipoNodo modoTipoNodo;
  final bool mostrarBotonesDebug;

  const ConfigEstado({
    this.themeMode = ThemeMode.light,
    this.tipoConexionPorDefecto = Direccion.unidireccional,
    this.modoTipoNodo = ModoTipoNodo.declarado,
    this.mostrarBotonesDebug = false,
  });

  ConfigEstado copyWith({
    ThemeMode? themeMode,
    Direccion? tipoConexionPorDefecto,
    ModoTipoNodo? modoTipoNodo,
    bool? mostrarBotonesDebug,
  }) {
    return ConfigEstado(
      themeMode: themeMode ?? this.themeMode,
      tipoConexionPorDefecto:
          tipoConexionPorDefecto ?? this.tipoConexionPorDefecto,
      modoTipoNodo: modoTipoNodo ?? this.modoTipoNodo,
      mostrarBotonesDebug: mostrarBotonesDebug ?? this.mostrarBotonesDebug,
    );
  }

  static const initial = ConfigEstado();
}

class ConfigNotifier extends Notifier<ConfigEstado> {
  static const String _prefThemeKey = 'app_theme_mode';
  static const String _prefConnTypeKey = 'app_default_conn_type';
  static const String _prefNodeTypeModeKey = 'app_node_type_mode';
  static const String _prefDebugFabsKey = 'app_mostrar_debug_fabs';

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

      final savedNodeTypeMode = prefs.getString(_prefNodeTypeModeKey);
      ModoTipoNodo nodeTypeMode = state.modoTipoNodo;
      if (savedNodeTypeMode != null) {
        if (savedNodeTypeMode == ModoTipoNodo.detectado.name) {
          nodeTypeMode = ModoTipoNodo.detectado;
        } else if (savedNodeTypeMode == ModoTipoNodo.declarado.name) {
          nodeTypeMode = ModoTipoNodo.declarado;
        }
      }

      final debugFabs = prefs.getBool(_prefDebugFabsKey) ?? false;

      state = state.copyWith(
        themeMode: mode,
        tipoConexionPorDefecto: connType,
        modoTipoNodo: nodeTypeMode,
        mostrarBotonesDebug: debugFabs,
      );
    } catch (_) {}
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

  Future<void> _saveNodeTypeMode(ModoTipoNodo mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefNodeTypeModeKey, mode.name);
    } catch (_) {}
  }

  void setTipoConexionPorDefecto(Direccion type) {
    state = state.copyWith(tipoConexionPorDefecto: type);
    _saveConnType(type);
  }

  void setModoTipoNodo(ModoTipoNodo mode) {
    state = state.copyWith(modoTipoNodo: mode);
    _saveNodeTypeMode(mode);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _saveTheme(mode);
  }

  void setMostrarBotonesDebug(bool value) {
    state = state.copyWith(mostrarBotonesDebug: value);
    _saveDebugFabs(value);
  }

  Future<void> _saveDebugFabs(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefDebugFabsKey, value);
    } catch (_) {}
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
