import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/inscription_screen.dart';
import 'screens/etudiant_screen.dart';
import 'screens/enseignant_screen.dart';

void main() {
  runApp(const QcmAiApp());
}

class QcmAiApp extends StatelessWidget {
  const QcmAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "QCM AI",
      theme: AppTheme.light,
      initialRoute: "/login",
      routes: {
        "/login": (context) => const LoginScreen(),
        "/inscription": (context) => const InscriptionScreen(),
        "/etudiant": (context) => const EtudiantScreen(),
        "/enseignant": (context) => const EnseignantScreen(),
      },
    );
  }
}