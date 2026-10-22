import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../algorithms/bst/domain/bst_tree.dart';

class SavedBstPractice {
  final String id;
  final String name;
  final String treeJson;
  final String manualText;
  final String quantity;
  final String firstText;
  final String secondText;
  final String mode;
  final String firstType;
  final String secondType;
  final DateTime savedAt;

  const SavedBstPractice({
    required this.id,
    required this.name,
    required this.treeJson,
    required this.manualText,
    required this.quantity,
    required this.firstText,
    required this.secondText,
    required this.mode,
    required this.firstType,
    required this.secondType,
    required this.savedAt,
  });

  BstTree get tree => BstTree.fromJson(treeJson);

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'treeJson': treeJson,
    'manualText': manualText,
    'quantity': quantity,
    'firstText': firstText,
    'secondText': secondText,
    'mode': mode,
    'firstType': firstType,
    'secondType': secondType,
    'savedAt': savedAt.toIso8601String(),
  };

  factory SavedBstPractice.fromJson(Map<String, dynamic> json) =>
      SavedBstPractice(
        id: json['id'] as String,
        name: json['name'] as String,
        treeJson: json['treeJson'] as String,
        manualText: json['manualText'] as String,
        quantity: json['quantity'] as String,
        firstText: json['firstText'] as String,
        secondText: json['secondText'] as String,
        mode: json['mode'] as String,
        firstType: json['firstType'] as String,
        secondType: json['secondType'] as String,
        savedAt: DateTime.parse(json['savedAt'] as String),
      );
}

class BstStorageService {
  static const storageKey = 'saved_bst_practices_v1';

  static Future<List<SavedBstPractice>> getSavedPractices() async {
    final prefs = await SharedPreferences.getInstance();
    final source = prefs.getString(storageKey);
    if (source == null || source.isEmpty) return [];
    return (jsonDecode(source) as List<dynamic>)
        .map((item) => SavedBstPractice.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<SavedBstPractice> save(SavedBstPractice practice) async {
    if (practice.name.trim().isEmpty || practice.tree.isEmpty) {
      throw ArgumentError('El árbol necesita un nombre y al menos un nodo.');
    }
    final items = await getSavedPractices();
    var name = practice.name.trim();
    var suffix = 2;
    while (items.any((item) => item.name.toLowerCase() == name.toLowerCase())) {
      name = '${practice.name.trim()} ($suffix)';
      suffix++;
    }
    final saved = SavedBstPractice(
      id: 'bst_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      treeJson: practice.treeJson,
      manualText: practice.manualText,
      quantity: practice.quantity,
      firstText: practice.firstText,
      secondText: practice.secondText,
      mode: practice.mode,
      firstType: practice.firstType,
      secondType: practice.secondType,
      savedAt: DateTime.now(),
    );
    items.insert(0, saved);
    await _write(items);
    return saved;
  }

  static Future<void> delete(String id) async {
    final items = await getSavedPractices();
    items.removeWhere((item) => item.id == id);
    await _write(items);
  }

  static Future<void> _write(List<SavedBstPractice> items) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = await prefs.setString(
      storageKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
    if (!stored) throw StateError('No se pudieron guardar los árboles.');
  }
}
