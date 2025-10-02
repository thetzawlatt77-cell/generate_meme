import 'package:flutter_test/flutter_test.dart';

import 'package:meme_maker/main.dart';

void main() {
  testWidgets('Meme Maker app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MemeMakerApp());

    // Verify that our app loads
    expect(find.text('Meme Generator'), findsOneWidget);
  });
}
