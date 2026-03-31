import 'package:flutter_test/flutter_test.dart';

import 'package:pulselink_site/app.dart';

void main() {
  testWidgets('PulseLink home shell renders', (tester) async {
    await tester.pumpWidget(const PulseLinkApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('PulseLink'), findsWidgets);
    expect(find.textContaining('Explore Projects'), findsOneWidget);
  });
}
