import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campusmate/app.dart';
import 'package:campusmate/core/config/environment_config.dart';
import 'package:campusmate/core/network/supabase_service.dart';

void main() {
  test('empty Supabase environment uses development mode', () async {
    const environmentConfig = EnvironmentConfig();

    final status = await SupabaseService.initialize(environmentConfig);

    expect(status, SupabaseStartupStatus.developmentMode);
    expect(SupabaseService.client, isNull);
  });

  testWidgets('Authentication bootstrap smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: CampusMateApp()));
    await tester.pump();
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.text('0'), findsNothing);
  });
}
