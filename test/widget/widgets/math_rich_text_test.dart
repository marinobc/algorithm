import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/ui/widgets/math_rich_text.dart';

void main() {
  group('MathRichText Widget Tests', () {
    testWidgets('renders simple inline TeX notation properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathRichText(text: r'Formula $x_{ij} \ge 0$ test'),
          ),
        ),
      );

      expect(find.byType(MathRichText), findsOneWidget);
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('renders block TeX notation with double dollar signs', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathRichText(
              text: r'$$\min Z = \sum_{i=1}^{m} \sum_{j=1}^{n} c_{ij} x_{ij}$$',
            ),
          ),
        ),
      );

      expect(find.byType(MathRichText), findsOneWidget);
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets(
      'renders TeX symbols and quantifiers (\\le, \\forall, \\quad)',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MathRichText(
                text: r'$\sum_{j=1}^{n} x_{ij} \le a_i \quad \forall i$',
              ),
            ),
          ),
        );

        expect(find.byType(MathRichText), findsOneWidget);
        expect(find.byType(RichText), findsWidgets);
      },
    );
  });
}
