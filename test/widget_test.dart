import 'package:flutter_test/flutter_test.dart';
import 'package:healthcompass_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HealthCompassApp());
    expect(find.byType(HealthCompassApp), findsOneWidget);
  });
}
