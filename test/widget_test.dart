import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const QRCafeCustomerApp());
    expect(find.byType(QRCafeCustomerApp), findsOneWidget);
  });
}
