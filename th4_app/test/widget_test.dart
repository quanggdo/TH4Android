import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:th4_app/main.dart';

void main() {
  testWidgets('App renders core-only placeholder', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(
      find.text('Core layers only: models, services, providers, utils'),
      findsOneWidget,
    );
  });
}
