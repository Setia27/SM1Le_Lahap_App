import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/splash_screen.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Gunakan 'await' agar Supabase siap sebelum SplashScreen mengecek sesi login
  await Supabase.initialize(
    url: 'https://rwvyqicrtwzenppdpjfs.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3dnlxaWNydHd6ZW5wcGRwamZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQ4NjA0NjQsImV4cCI6MjExMDQzNjQ2NH0.UEc5_WYBhbNIGJbn2NdQZWZqLGjDCyuSdXD2uzfwpoc',
  );

  FlutterNativeSplash.remove();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '"Lifelong Learning, Any One, Any Where, Any Time"',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
