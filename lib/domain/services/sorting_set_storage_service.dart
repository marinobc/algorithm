import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SavedSortingSet {
  final String id;
  final String name;
  final List<int> values;
  final DateTime savedAt;

  SavedSortingSet({
    required this.id,
    required this.name,
    required List<int> values,
    required this.savedAt,
  }) : values = List<int>.unmodifiable(values);

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'values': values,
    'savedAt': savedAt.toIso8601String(),
  };

  factory SavedSortingSet.fromJson(Map<String, dynamic> json) =>
      SavedSortingSet(
        id: json['id'] as String,
        name: json['name'] as String,
        values: (json['values'] as List<dynamic>).cast<int>(),
        savedAt: DateTime.parse(json['savedAt'] as String),
      );
}

class SortingSetStorageService {
  static const storageKey = 'saved_sorting_sets_v1';

  static Future<List<SavedSortingSet>> getSavedSets() async {
    final prefs = await SharedPreferences.getInstance();
    final source = prefs.getString(storageKey);
    if (source == null || source.isEmpty) return [];
    final decoded = jsonDecode(source) as List<dynamic>;
    return decoded
        .map((item) => SavedSortingSet.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<SavedSortingSet> save(String name, List<int> values) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty || values.isEmpty) {
      throw ArgumentError('El conjunto necesita un nombre y números.');
    }
    final prefs = await SharedPreferences.getInstance();
    final sets = await getSavedSets();
    var uniqueName = cleanName;
    var suffix = 2;
    while (sets.any(
      (item) => item.name.toLowerCase() == uniqueName.toLowerCase(),
    )) {
      uniqueName = '$cleanName ($suffix)';
      suffix++;
    }
    final now = DateTime.now();
    var id = 'sort_${now.microsecondsSinceEpoch}';
    var idSuffix = 2;
    while (sets.any((item) => item.id == id)) {
      id = 'sort_${now.microsecondsSinceEpoch}_$idSuffix';
      idSuffix++;
    }
    final saved = SavedSortingSet(
      id: id,
      name: uniqueName,
      values: values,
      savedAt: now,
    );
    sets.insert(0, saved);
    final stored = await prefs.setString(
      storageKey,
      jsonEncode(sets.map((item) => item.toJson()).toList()),
    );
    if (!stored) throw StateError('No se pudo guardar el conjunto.');
    return saved;
  }

  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final sets = await getSavedSets();
    sets.removeWhere((item) => item.id == id);
    final stored = await prefs.setString(
      storageKey,
      jsonEncode(sets.map((item) => item.toJson()).toList()),
    );
    if (!stored) throw StateError('No se pudo eliminar el conjunto.');
  }
}
