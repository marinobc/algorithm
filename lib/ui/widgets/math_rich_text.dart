import 'package:flutter/material.dart';

/// Parses inline LaTeX-style notation like $u_i$, $v_j$, $c_{ij}$, $O(m + n)$, $m^n$, $\Delta_{ij}$
/// and renders them using RichText with appropriate subscripts, superscripts, mathematical styling,
/// and highlighted pill chips.
class MathRichText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final Color? mathColor;
  final Color? mathBgColor;

  const MathRichText({
    super.key,
    required this.text,
    this.baseStyle,
    this.mathColor,
    this.mathBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle =
        baseStyle ??
        TextStyle(
          fontSize: 14,
          height: 1.5,
          color: theme.colorScheme.onSurfaceVariant,
        );

    final highlightColor = mathColor ?? theme.colorScheme.primary;
    final bgColor =
        mathBgColor ??
        theme.colorScheme.primaryContainer.withValues(alpha: 0.35);

    final spans = <InlineSpan>[];
    final regex = RegExp(r'\$\$?([^\$]+)\$\$?');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      final mathExpr = match.group(1)!;
      spans.add(
        _buildMathSpan(mathExpr, defaultStyle, highlightColor, bgColor),
      );
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(style: defaultStyle, children: spans),
    );
  }

  static final List<MapEntry<String, String>> _symbolReplacements = [
    MapEntry(r'\min', 'min'),
    MapEntry(r'\max', 'max'),
    MapEntry(r'\quad', '  '),
    MapEntry(r'\forall', '∀'),
    MapEntry(r'\Delta', 'Δ'),
    MapEntry(r'\delta', 'δ'),
    MapEntry(r'\alpha', 'α'),
    MapEntry(r'\beta', 'β'),
    MapEntry(r'\gamma', 'γ'),
    MapEntry(r'\Gamma', 'Γ'),
    MapEntry(r'\theta', 'θ'),
    MapEntry(r'\lambda', 'λ'),
    MapEntry(r'\mu', 'μ'),
    MapEntry(r'\pi', 'π'),
    MapEntry(r'\sigma', 'σ'),
    MapEntry(r'\Sigma', 'Σ'),
    MapEntry(r'\omega', 'ω'),
    MapEntry(r'\Omega', 'Ω'),
    MapEntry(r'\geq', '≥'),
    MapEntry(r'\ge', '≥'),
    MapEntry(r'\leq', '≤'),
    MapEntry(r'\le', '≤'),
    MapEntry(r'\neq', '≠'),
    MapEntry(r'\ne', '≠'),
    MapEntry(r'\approx', '≈'),
    MapEntry(r'\infty', '∞'),
    MapEntry(r'\cdot', '·'),
    MapEntry(r'\times', '×'),
    MapEntry(r'\pm', '±'),
    MapEntry(r'\in', '∈'),
    MapEntry(r'\notin', '∉'),
    MapEntry(r'\rightarrow', '→'),
    MapEntry(r'\to', '→'),
  ];

  static String _sanitizeMathSymbols(String input) {
    String clean = input;
    for (final entry in _symbolReplacements) {
      clean = clean.replaceAll(entry.key, entry.value);
    }
    return clean;
  }

  InlineSpan _buildMathSpan(
    String rawExpr,
    TextStyle defaultStyle,
    Color mathColor,
    Color mathBgColor,
  ) {
    final expr = _sanitizeMathSymbols(rawExpr);
    final mathStyle = defaultStyle.copyWith(
      fontFamily: 'monospace',
      fontWeight: FontWeight.bold,
      color: mathColor,
      fontSize: (defaultStyle.fontSize ?? 14) * 0.95,
    );

    final children = <InlineSpan>[];
    int i = 0;

    while (i < expr.length) {
      if (expr.startsWith(r'\sum', i)) {
        i += 4;
        String sub = '';
        String sup = '';

        if (i < expr.length && expr[i] == '_') {
          i++;
          if (i < expr.length && expr[i] == '{') {
            i++;
            final end = expr.indexOf('}', i);
            if (end != -1) {
              sub = expr.substring(i, end);
              i = end + 1;
            }
          } else if (i < expr.length) {
            sub = expr[i];
            i++;
          }
        }

        if (i < expr.length && expr[i] == '^') {
          i++;
          if (i < expr.length && expr[i] == '{') {
            i++;
            final end = expr.indexOf('}', i);
            if (end != -1) {
              sup = expr.substring(i, end);
              i = end + 1;
            }
          } else if (i < expr.length) {
            sup = expr[i];
            i++;
          }
        }

        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (sup.isNotEmpty)
                    Text(
                      sup,
                      style: mathStyle.copyWith(
                        fontSize: (mathStyle.fontSize ?? 13) * 0.75,
                        height: 1.0,
                      ),
                    ),
                  Text(
                    '∑',
                    style: TextStyle(
                      fontSize: (mathStyle.fontSize ?? 13) * 1.5,
                      height: 0.95,
                      fontWeight: FontWeight.w300,
                      color: mathColor,
                    ),
                  ),
                  if (sub.isNotEmpty)
                    Text(
                      sub,
                      style: mathStyle.copyWith(
                        fontSize: (mathStyle.fontSize ?? 13) * 0.75,
                        height: 1.0,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      } else if (expr[i] == '_') {
        i++;
        String sub = '';
        if (i < expr.length && expr[i] == '{') {
          i++;
          final end = expr.indexOf('}', i);
          if (end != -1) {
            sub = expr.substring(i, end);
            i = end + 1;
          } else {
            sub = expr.substring(i);
            i = expr.length;
          }
        } else if (i < expr.length) {
          sub = expr[i];
          i++;
        }
        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Transform.translate(
              offset: const Offset(0, 3),
              child: Text(
                sub,
                style: mathStyle.copyWith(
                  fontSize: (mathStyle.fontSize ?? 13) * 0.78,
                ),
              ),
            ),
          ),
        );
      } else if (expr[i] == '^') {
        i++;
        String sup = '';
        if (i < expr.length && expr[i] == '{') {
          i++;
          final end = expr.indexOf('}', i);
          if (end != -1) {
            sup = expr.substring(i, end);
            i = end + 1;
          } else {
            sup = expr.substring(i);
            i = expr.length;
          }
        } else if (i < expr.length) {
          sup = expr[i];
          i++;
        }
        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Transform.translate(
              offset: const Offset(0, -4),
              child: Text(
                sup,
                style: mathStyle.copyWith(
                  fontSize: (mathStyle.fontSize ?? 13) * 0.78,
                ),
              ),
            ),
          ),
        );
      } else {
        int nextSpecial = expr.indexOf(RegExp(r'[_^]|\\sum'), i);
        if (nextSpecial == -1) nextSpecial = expr.length;
        final normal = expr.substring(i, nextSpecial);
        children.add(TextSpan(text: normal));
        i = nextSpecial;
      }
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: mathBgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: RichText(
          text: TextSpan(style: mathStyle, children: children),
        ),
      ),
    );
  }
}
