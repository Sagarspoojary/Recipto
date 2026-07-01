import 'package:flutter_test/flutter_test.dart';
import 'package:receipto/main.dart';

void main() {
  testWidgets('Receipto smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ReceiptoApp());

    // Expect that the app shell pumps successfully without throwing errors
    expect(find.byType(ReceiptoApp), findsOneWidget);
  });
}
