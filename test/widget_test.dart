import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/main.dart';
import 'package:puzzle/services/storage_service.dart';

void main() {
  testWidgets('App renders title screen', (WidgetTester tester) async {
    await tester.pumpWidget(PuzzleApp(storageService: StorageService()));
    await tester.pump();
    expect(find.text('Puzzle'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
  });
}
