import 'package:web/web.dart' as web;

/// Web implementation using package:web to dynamically update the
/// <meta name="theme-color"> tag in the browser DOM.
void syncWebThemeColor(bool isDark) {
  final colorHex = isDark ? '#141218' : '#FFFFFF';
  final metaTags = web.document.querySelectorAll('meta[name="theme-color"]');
  if (metaTags.length > 0) {
    for (int i = 0; i < metaTags.length; i++) {
      final item = metaTags.item(i);
      if (item != null) {
        final meta = item as web.HTMLMetaElement;
        meta.content = colorHex;
        meta.removeAttribute('media');
      }
    }
  } else {
    final meta = web.HTMLMetaElement()
      ..name = 'theme-color'
      ..content = colorHex;
    web.document.head?.append(meta);
  }
}
