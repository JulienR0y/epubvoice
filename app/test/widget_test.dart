import 'package:flutter_test/flutter_test.dart';
import 'package:epubvoice/main.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const EpubVoiceApp());
    expect(find.text('EpubVoice'), findsOneWidget);
    expect(find.text('Import Epub'), findsOneWidget);
  });
}
