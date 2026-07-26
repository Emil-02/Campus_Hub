import 'package:flutter/material.dart';

import 'core/network/supabase_service.dart';

class CampusMateApp extends StatelessWidget {
  const CampusMateApp({super.key, this.startupStatus});

  final SupabaseStartupStatus? startupStatus;

  String get _environmentMessage {
    switch (startupStatus) {
      case SupabaseStartupStatus.initialized:
        return 'Supabase initialized.';
      case SupabaseStartupStatus.initializationFailed:
        return 'Development Mode: Supabase initialization failed.';
      case SupabaseStartupStatus.developmentMode:
      case null:
        return 'Development Mode: Supabase environment is not configured.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusMate',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006874)),
      ),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'CampusMate',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Project Foundation Ready'),
              const SizedBox(height: 16),
              Text(
                _environmentMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.orange),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
