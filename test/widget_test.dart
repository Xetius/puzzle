import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/main.dart';

void main() {
  testWidgets('App renders game screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PuzzleApp());
    expect(find.text('Puzzle'), findsOneWidget);
    expect(find.text('Start Game'), findsOneWidget);
  });
}
