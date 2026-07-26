import 'package:flutter/material.dart';

class CampusMateApp extends StatelessWidget {
  const CampusMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusMate',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006874)),
      ),
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'CampusMate',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('Project Foundation Ready'),
              SizedBox(height: 16),
              Text(
                'Supabase configuration pending...',
                style: TextStyle(color: Colors.orange),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
