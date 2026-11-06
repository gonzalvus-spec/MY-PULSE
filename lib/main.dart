import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('es_ES', null);
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER ERROR: ${details.exception}\n${details.stack}');
  };
  runZonedGuarded(() => runApp(const PresionArterialApp()), (error, stack) {
    debugPrint('ZONED ERROR: $error\n$stack');
  });
}

class PresionArterialApp extends StatelessWidget {
  const PresionArterialApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Control de Presión Arterial',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006689)),
      scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    home: const SplashScreen(),
  );
}
