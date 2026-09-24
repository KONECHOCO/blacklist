import 'package:flutter_test/flutter_test.dart';
import 'package:blacklist/main.dart';

void main() {
  testWidgets('BlacklistApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BlacklistApp());
    expect(find.byType(BlacklistApp), findsOneWidget);
  });
}
