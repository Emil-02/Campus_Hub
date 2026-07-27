import 'package:flutter/material.dart';

/// Temporary page used until the corresponding authentication UI batch.
final class AuthPlaceholderPage extends StatelessWidget {
  const AuthPlaceholderPage({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title placeholder')),
    );
  }
}
