import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/tracker_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const NokiaFmTrackerApp());
}

class NokiaFmTrackerApp extends StatelessWidget {
  const NokiaFmTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TrackerProvider(),
      child: MaterialApp(
        title: 'Nokia FM Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1D9E75),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF7F8FA),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
          ),
          cardTheme: const CardThemeData(
            color: Colors.white,
            surfaceTintColor: Colors.white,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
