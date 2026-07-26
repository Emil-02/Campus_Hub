import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campusmate/app.dart';

void main() {
  testWidgets('Foundation text smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: CampusMateApp()));

    // Verify that the initial foundation text is present.
    expect(find.text('CampusMate'), findsOneWidget);
    expect(find.text('Project Foundation Ready'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.text('0'), findsNothing);
  });
}
