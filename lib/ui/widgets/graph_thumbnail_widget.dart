import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../domain/services/graph_share_service.dart';
import '../../domain/services/graph_storage_service.dart';

class GraphThumbnailWidget extends StatefulWidget {
  final SavedGraphItem item;
  final Color backgroundColor;

  const GraphThumbnailWidget({
    super.key,
    required this.item,
    required this.backgroundColor,
  });

  @override
  State<GraphThumbnailWidget> createState() => _GraphThumbnailWidgetState();
}

class _GraphThumbnailWidgetState extends State<GraphThumbnailWidget> {
  Uint8List? _imageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrGenerateThumbnail();
  }

  @override
  void didUpdateWidget(covariant GraphThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id ||
        oldWidget.item.thumbnailBase64 != widget.item.thumbnailBase64 ||
        oldWidget.item.jsonContent != widget.item.jsonContent ||
        oldWidget.backgroundColor != widget.backgroundColor) {
      _loadOrGenerateThumbnail();
    }
  }

  void _loadOrGenerateThumbnail() {
    if (widget.item.nodoCount == 0) {
      setState(() {
        _imageBytes = null;
        _isLoading = false;
      });
      return;
    }

    if (widget.item.thumbnailBase64 != null &&
        widget.item.thumbnailBase64!.isNotEmpty) {
      try {
        final decoded = base64Decode(widget.item.thumbnailBase64!);
        setState(() {
          _imageBytes = decoded;
          _isLoading = false;
        });
        return;
      } catch (_) {}
    }

    _generateAndCacheThumbnail();
  }

  Future<void> _generateAndCacheThumbnail() async {
    setState(() => _isLoading = true);
    try {
      final graph = GraphStorageService.importFromJson(widget.item.jsonContent);
      if (graph.nodos.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final base64Str = await GraphShareService.generateThumbnailBase64(graph);
      if (base64Str != null && mounted) {
        final bytes = base64Decode(base64Str);
        setState(() {
          _imageBytes = bytes;
          _isLoading = false;
        });
        GraphStorageService.updateItemThumbnail(widget.item.id, base64Str);
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: _isLoading
          ? Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
            )
          : _imageBytes != null
          ? Image.memory(
              _imageBytes!,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              filterQuality: FilterQuality.high,
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.dashboard_customize_outlined,
                    color: colorScheme.outline.withValues(alpha: 0.5),
                    size: 32,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Lienzo Vacío',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.outline.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
