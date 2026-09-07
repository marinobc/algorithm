import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config_provider.dart';

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(configProvider).themeMode;
});
