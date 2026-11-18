import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

void main() async {
  // 1. Wajib dipanggil sebelum menjalankan fungsi async di main()
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Hubungkan aplikasi ke proyek Supabase Anda
  await Supabase.initialize(
    url: 'https://rwvyqicrtwzenppdpjfs.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3dnlxaWNydHd6ZW5wcGRwamZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQ4NjA0NjQsImV4cCI6MjExMDQzNjQ2NH0.UEc5_WYBhbNIGJbn2NdQZWZqLGjDCyuSdXD2uzfwpoc',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenda Kegiatan Tendik',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
    );
  }
}
