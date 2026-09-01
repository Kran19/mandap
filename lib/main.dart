import 'package:flutter/material.dart';
import 'features/mandap/presentation/mandap_editor_screen.dart';

void main() {
  runApp(const MandapApp());
}

class MandapApp extends StatelessWidget {
  const MandapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MANDAP — Mandap Truss Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
        useMaterial3: true,
      ),
      home: const MandapEditorScreen(),
    );
  }
}
