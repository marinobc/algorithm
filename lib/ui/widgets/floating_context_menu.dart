import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import '../text/app_text.dart';
import '../theme/app_theme.dart';

class FloatingContextMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDismiss;

  const FloatingContextMenu({
    super.key,
    required this.onEdit,
    required this.onDelete,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Outer overlay to dismiss when tapping outside
          GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.translucent,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
          ),
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: colorScheme.surfaceContainerHigh,
            child: SizedBox(
              width: 140,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: onEdit,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined,
                              color: colorScheme.primary, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            AppText.edit,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: colorScheme.outlineVariant,
                  ),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              color: colorScheme.error, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            AppText.delete,
                            style: TextStyle(
                              color: colorScheme.error,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(name: 'FloatingContextMenu - Dark', group: 'Widgets')
Widget floatingContextMenuDarkPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.darkTheme,
    themeMode: ThemeMode.dark,
    home: Scaffold(
      backgroundColor: NeumorphicPalette.dark.canvasBg,
      body: Center(
        child: FloatingContextMenu(
          onEdit: () {},
          onDelete: () {},
          onDismiss: () {},
        ),
      ),
    ),
  );
}

@Preview(name: 'FloatingContextMenu - Light', group: 'Widgets')
Widget floatingContextMenuLightPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    themeMode: ThemeMode.light,
    home: Scaffold(
      backgroundColor: NeumorphicPalette.light.canvasBg,
      body: Center(
        child: FloatingContextMenu(
          onEdit: () {},
          onDelete: () {},
          onDismiss: () {},
        ),
      ),
    ),
  );
}

