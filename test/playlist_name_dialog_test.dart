import 'package:auvoryn/features/library/presentation/library_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('playlist creation saves a trimmed name and safely closes', (tester) async {
    final results = <String?>[];
    await tester.pumpWidget(_DialogTestHost(
      onResult: results.add,
      title: 'New playlist',
    ));

    await tester.tap(find.byKey(const Key('open_playlist_dialog')));
    await tester.pumpAndSettle();
    expect(find.text('New playlist'), findsOneWidget);

    // Empty submissions should keep the form visible.
    await tester.tap(find.byKey(const Key('playlist_save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('playlist_name_input')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('playlist_name_input')),
      '  Night Drive  ',
    );
    await tester.tap(find.byKey(const Key('playlist_save')));
    await tester.pumpAndSettle();

    expect(results, ['Night Drive']);
    expect(find.byKey(const Key('playlist_name_input')), findsNothing);
    expect(tester.takeException(), isNull);

    // Opening the same dialog again must not reuse a disposed controller.
    await tester.tap(find.byKey(const Key('open_playlist_dialog')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('playlist_cancel')));
    await tester.pumpAndSettle();
    expect(results, ['Night Drive', null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('playlist rename retains initial text and cancels safely', (tester) async {
    final results = <String?>[];
    await tester.pumpWidget(_DialogTestHost(
      onResult: results.add,
      title: 'Rename playlist',
      initialName: 'Study Session',
    ));

    await tester.tap(find.byKey(const Key('open_playlist_dialog')));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.byKey(const Key('playlist_name_input')),
    );
    expect(field.controller?.text, 'Study Session');

    await tester.tap(find.byKey(const Key('playlist_cancel')));
    await tester.pumpAndSettle();
    expect(results, [null]);
    expect(tester.takeException(), isNull);
  });
}

class _DialogTestHost extends StatelessWidget {
  const _DialogTestHost({
    required this.onResult,
    required this.title,
    this.initialName = '',
  });

  final void Function(String?) onResult;
  final String title;
  final String initialName;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Builder(builder: (context) => Center(
        child: FilledButton(
          key: const Key('open_playlist_dialog'),
          onPressed: () async {
            final result = await playlistNameDialog(
              context,
              title: title,
              initialName: initialName,
            );
            onResult(result);
          },
          child: const Text('Open dialog'),
        ),
      )),
    ),
  );
}
