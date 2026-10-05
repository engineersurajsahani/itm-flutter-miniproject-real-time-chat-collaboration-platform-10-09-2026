import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat_collab/app.dart';

void main() {
  testWidgets('shows the SyncUp launch screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CollaborationApp()));
    await tester.pump();
    expect(find.text('SyncUp'), findsOneWidget);
  });
}
