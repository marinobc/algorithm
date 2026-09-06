import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grafo.dart';
import 'graph_share_service.dart';

class GraphVersion {
  final int versionNumber;
  final String fecha;
  final int nodoCount;
  final int conexionCount;
  final String jsonContent;

  const GraphVersion({
    required this.versionNumber,
    required this.fecha,
    required this.nodoCount,
    required this.conexionCount,
    required this.jsonContent,
  });

  Map<String, dynamic> toJson() {
    return {
      'versionNumber': versionNumber,
      'fecha': fecha,
      'nodoCount': nodoCount,
      'conexionCount': conexionCount,
      'jsonContent': jsonContent,
    };
  }

  factory GraphVersion.fromJson(Map<String, dynamic> json) {
    return GraphVersion(
      versionNumber: json['versionNumber'] as int? ?? 1,
      fecha: json['fecha'] as String,
      nodoCount: json['nodoCount'] as int? ?? 0,
      conexionCount: json['conexionCount'] as int? ?? 0,
      jsonContent: json['jsonContent'] as String,
    );
  }
}

class SavedGraphItem {
  final String id;
  final String nombre;
  final String fecha;
  final int nodoCount;
  final int conexionCount;
  final String jsonContent;
  final int currentVersion;
  final List<GraphVersion> history;
  final String? thumbnailBase64;

  const SavedGraphItem({
    required this.id,
    required this.nombre,
    required this.fecha,
    required this.nodoCount,
    required this.conexionCount,
    required this.jsonContent,
    this.currentVersion = 1,
    this.history = const [],
    this.thumbnailBase64,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'fecha': fecha,
      'nodoCount': nodoCount,
      'conexionCount': conexionCount,
      'jsonContent': jsonContent,
      'currentVersion': currentVersion,
      'history': history.map((h) => h.toJson()).toList(),
      'thumbnailBase64': thumbnailBase64,
    };
  }

  factory SavedGraphItem.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['history'] as List<dynamic>? ?? [];
    final historyList = rawHistory
        .map((h) => GraphVersion.fromJson(h as Map<String, dynamic>))
        .toList();

    return SavedGraphItem(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      fecha: json['fecha'] as String,
      nodoCount: json['nodoCount'] as int? ?? 0,
      conexionCount: json['conexionCount'] as int? ?? 0,
      jsonContent: json['jsonContent'] as String,
      currentVersion: json['currentVersion'] as int? ??
          (historyList.isNotEmpty ? historyList.last.versionNumber : 1),
      history: historyList,
      thumbnailBase64: json['thumbnailBase64'] as String?,
    );
  }
}

class GraphStorageService {
  static const String _storageKey = 'saved_graphs_list_v1';

  static String exportToJson(Grafo graph) {
    final Map<String, dynamic> jsonMap = graph.toJson();
    return const JsonEncoder.withIndent('  ').convert(jsonMap);
  }

  static Grafo importFromJson(String jsonStr) {
    final dynamic decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El formato del JSON no corresponde a un mapa de grafo válido.');
    }
    return Grafo.fromJson(decoded);
  }

  static Future<List<SavedGraphItem>> getSavedGraphs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_storageKey);
      if (jsonStr == null || jsonStr.isEmpty) return [];

      final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((item) => SavedGraphItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String generateUniqueName(
    String baseName,
    List<SavedGraphItem> existingItems, {
    String? excludeId,
  }) {
    final cleanName = baseName.trim().isEmpty ? 'Grafo Guardado' : baseName.trim();
    final otherNames = existingItems
        .where((item) => item.id != excludeId)
        .map((item) => item.nombre.trim())
        .toSet();

    if (!otherNames.contains(cleanName)) {
      return cleanName;
    }

    int counter = 1;
    while (true) {
      final candidate = '$cleanName ($counter)';
      if (!otherNames.contains(candidate)) {
        return candidate;
      }
      counter++;
    }
  }

  static Future<SavedGraphItem> saveGraphSlot(String name, Grafo graph) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getSavedGraphs();
    final uniqueName = generateUniqueName(name, items);

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final jsonStr = jsonEncode(graph.toJson());
    final thumbnailBase64 = await GraphShareService.generateThumbnailBase64(graph);
    final initialVersion = GraphVersion(
      versionNumber: 1,
      fecha: dateStr,
      nodoCount: graph.nodos.length,
      conexionCount: graph.conexiones.length,
      jsonContent: jsonStr,
    );

    final newItem = SavedGraphItem(
      id: 'graph_${now.millisecondsSinceEpoch}',
      nombre: uniqueName,
      fecha: dateStr,
      nodoCount: graph.nodos.length,
      conexionCount: graph.conexiones.length,
      jsonContent: jsonStr,
      currentVersion: 1,
      history: [initialVersion],
      thumbnailBase64: thumbnailBase64,
    );

    items.insert(0, newItem);
    final jsonList = items.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
    return newItem;
  }

  static Future<SavedGraphItem> overrideSavedGraphSlot(
    String id,
    String name,
    Grafo graph,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getSavedGraphs();
    final uniqueName = generateUniqueName(name, items, excludeId: id);

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final index = items.indexWhere((item) => item.id == id);
    final existingItem = index != -1 ? items[index] : null;

    final nextVersionNumber = (existingItem?.currentVersion ?? 0) + 1;
    final jsonStr = jsonEncode(graph.toJson());
    final thumbnailBase64 = await GraphShareService.generateThumbnailBase64(graph);

    final newVersion = GraphVersion(
      versionNumber: nextVersionNumber,
      fecha: dateStr,
      nodoCount: graph.nodos.length,
      conexionCount: graph.conexiones.length,
      jsonContent: jsonStr,
    );

    final existingHistory = existingItem != null && existingItem.history.isNotEmpty
        ? existingItem.history
        : (existingItem != null
            ? [
                GraphVersion(
                  versionNumber: 1,
                  fecha: existingItem.fecha,
                  nodoCount: existingItem.nodoCount,
                  conexionCount: existingItem.conexionCount,
                  jsonContent: existingItem.jsonContent,
                )
              ]
            : <GraphVersion>[]);

    final updatedHistory = [...existingHistory, newVersion];

    final updatedItem = SavedGraphItem(
      id: id,
      nombre: uniqueName,
      fecha: dateStr,
      nodoCount: graph.nodos.length,
      conexionCount: graph.conexiones.length,
      jsonContent: jsonStr,
      currentVersion: nextVersionNumber,
      history: updatedHistory,
      thumbnailBase64: thumbnailBase64,
    );

    if (index != -1) {
      items[index] = updatedItem;
    } else {
      items.insert(0, updatedItem);
    }
    final jsonList = items.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
    return updatedItem;
  }

  static Future<SavedGraphItem?> findExistingGraphByName(String name, {String? excludeId}) async {
    final items = await getSavedGraphs();
    final clean = name.trim().toLowerCase();
    for (final item in items) {
      if (item.id != excludeId && item.nombre.trim().toLowerCase() == clean) {
        return item;
      }
    }
    return null;
  }

  static Future<SavedGraphItem> renameSavedGraphSlot(String id, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getSavedGraphs();
    final index = items.indexWhere((item) => item.id == id);
    if (index == -1) throw Exception('Grafo no encontrado.');

    final existing = items[index];
    final updated = SavedGraphItem(
      id: existing.id,
      nombre: newName.trim(),
      fecha: existing.fecha,
      nodoCount: existing.nodoCount,
      conexionCount: existing.conexionCount,
      jsonContent: existing.jsonContent,
      currentVersion: existing.currentVersion,
      history: existing.history,
      thumbnailBase64: existing.thumbnailBase64,
    );

    items[index] = updated;
    final jsonList = items.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
    return updated;
  }

  static Future<void> updateItemThumbnail(String id, String thumbnailBase64) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getSavedGraphs();
    final index = items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final existing = items[index];
    final updated = SavedGraphItem(
      id: existing.id,
      nombre: existing.nombre,
      fecha: existing.fecha,
      nodoCount: existing.nodoCount,
      conexionCount: existing.conexionCount,
      jsonContent: existing.jsonContent,
      currentVersion: existing.currentVersion,
      history: existing.history,
      thumbnailBase64: thumbnailBase64,
    );

    items[index] = updated;
    final jsonList = items.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  static Future<void> deleteSavedGraph(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getSavedGraphs();
    items.removeWhere((item) => item.id == id);
    final jsonList = items.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }
}
