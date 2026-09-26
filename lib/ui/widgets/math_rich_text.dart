import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../core/utils/app_logger.dart';

/// Production-grade math text widget backed by the KaTeX rendering engine ([flutter_math_fork]).
///
/// Parses LaTeX formulas (either wrapped in `$..$` / `$$..$$` or standalone math expressions)
/// and renders crisp vector mathematical notation for equations, Greek symbols, subscripts, and matrices.
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

    // 1. Explicit $ or $$ delimited math parsing inside narrative text
    if (text.contains('\$')) {
      final lines = text.split('\n');
      final lineWidgets = <Widget>[];

      for (final line in lines) {
        if (line.trim().isEmpty) {
          lineWidgets.add(const SizedBox(height: 6));
          continue;
        }

        if (!line.contains('\$')) {
          lineWidgets.add(Text(line, style: defaultStyle));
          continue;
        }

        final spans = <InlineSpan>[];
        final regex = RegExp(r'\$\$?([^\$]+)\$\$?');
        int lastEnd = 0;

        for (final match in regex.allMatches(line)) {
          if (match.start > lastEnd) {
            spans.add(TextSpan(text: line.substring(lastEnd, match.start)));
          }

          final mathExpr = match.group(1)!;
          final normalized = _normalizeTex(mathExpr);
          AppLogger.d(
            'MathRichText',
            'Rendering delimited TeX: "$mathExpr" -> "$normalized"',
          );

          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Math.tex(
                  normalized,
                  mathStyle: MathStyle.text,
                  textStyle: defaultStyle.copyWith(
                    color: highlightColor,
                    fontWeight: FontWeight.bold,
                  ),
                  onErrorFallback: (err) {
                    AppLogger.w(
                      'MathRichText',
                      'KaTeX error rendering expr "$mathExpr" (normalized: "$normalized"): $err',
                    );
                    return Text(
                      mathExpr,
                      style: defaultStyle.copyWith(color: highlightColor),
                    );
                  },
                ),
              ),
            ),
          );
          lastEnd = match.end;
        }

        if (lastEnd < line.length) {
          spans.add(TextSpan(text: line.substring(lastEnd)));
        }

        lineWidgets.add(
          RichText(
            text: TextSpan(style: defaultStyle, children: spans),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: lineWidgets,
      );
    }

    // 2. Standalone TeX formula detection (without $ delimiters)
    final containsPmatrix = text.contains(r'\begin{pmatrix}');
    final hasMathTokens =
        text.contains('\\') ||
        text.contains('_') ||
        text.contains('^') ||
        RegExp(
          r'\b(min|max|delta|alpha|beta|theta|sum)\b',
          caseSensitive: false,
        ).hasMatch(text);

    if (containsPmatrix) {
      final normalized = _normalizeTex(text);
      AppLogger.d('MathRichText', 'Rendering pmatrix TeX: "$normalized"');
      return Math.tex(
        normalized,
        mathStyle: MathStyle.display,
        textStyle: defaultStyle.copyWith(
          color: highlightColor,
          fontWeight: FontWeight.bold,
        ),
        onErrorFallback: (err) {
          AppLogger.w('MathRichText', 'KaTeX error on pmatrix: $err');
          return Text(text, style: defaultStyle);
        },
      );
    } else if (hasMathTokens &&
        (!text.contains(' ') || text.contains('_') || text.contains('\\'))) {
      final normalized = _normalizeTex(text);
      AppLogger.d(
        'MathRichText',
        'Rendering standalone TeX: "$text" -> "$normalized"',
      );
      return Math.tex(
        normalized,
        mathStyle: MathStyle.text,
        textStyle: defaultStyle.copyWith(
          color: highlightColor,
          fontWeight: FontWeight.bold,
        ),
        onErrorFallback: (err) {
          AppLogger.w(
            'MathRichText',
            'KaTeX error on standalone expr "$text" (normalized: "$normalized"): $err',
          );
          return Text(text, style: defaultStyle);
        },
      );
    }

    // 3. Plain text fallback
    return Text(text, style: defaultStyle);
  }

  /// Normalizes non-standard TeX notation into valid KaTeX syntax.
  static String _normalizeTex(String input) {
    return input
        .replaceAll(r'\Alpha', 'A')
        .replaceAll(r'\Beta', 'B')
        .replaceAll('lapha_alpha', r'\alpha_\alpha')
        .replaceAll('beta_beta', r'\beta_\beta')
        .replaceAll('lapha', r'\alpha')
        .replaceAll(r'^\prime', "'")
        .replaceAll(r'\prime', "'")
        .replaceAll(r'\boldsymbol', r'\mathbf')
        .replaceAll(r'\implies', r'\Rightarrow')
        .replaceAll(r'\min', r'\min ')
        .replaceAll(r'\max', r'\max ');
  }
}
