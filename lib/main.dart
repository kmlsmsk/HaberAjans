import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const EgeAjansApp());
}

class EgeAjansApp extends StatelessWidget {
  const EgeAjansApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HaberVAR - Akıllı Medya Asistanı',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
