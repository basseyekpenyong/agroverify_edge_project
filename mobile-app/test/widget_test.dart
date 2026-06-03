import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agroverify_edge/app.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AgroVerifyApp()));
    await tester.pumpAndSettle();
    // App loaded without crashing
    expect(find.byType(AgroVerifyApp), findsNothing);
  });
}
