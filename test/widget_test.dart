import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auramix/main.dart';

void main() {
  testWidgets('AuraMixApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AuraMixApp(),
      ),
    );
    expect(find.byType(AuraMixApp), findsOneWidget);
  });
}
