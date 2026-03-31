import 'package:flutter_test/flutter_test.dart';
import 'package:washer/main.dart';

void main() {
  testWidgets('MyApp renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(MyApp), findsOneWidget);
  });
}
