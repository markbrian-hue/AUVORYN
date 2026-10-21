import 'package:auvoryn/features/settings/presentation/about_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('privacy page explains local data and uninstall risks',
      (tester) async {
    tester.view.physicalSize = const Size(430, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: AboutPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your files stay here.'), findsOneWidget);
    expect(find.text('Imported music'), findsOneWidget);
    expect(find.text('Listening memories'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(ListView), const Offset(0, -750));
    await tester.pumpAndSettle();

    expect(find.text('Before uninstalling'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
