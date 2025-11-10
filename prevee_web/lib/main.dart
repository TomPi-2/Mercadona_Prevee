import 'package:flutter/material.dart';
import 'package:prevee_web/scripts/seed_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://apbovaeovrvxxegpbsuu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFwYm92YWVvdnJ2eHhlZ3Bic3V1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI3NTAxNDEsImV4cCI6MjA3ODMyNjE0MX0.JWSjalh6lrwk53_web6BhYC6xkEpScdWFDm7qXsQqUw',
  );

  DatabaseSeeder seeder = DatabaseSeeder();
  await seeder.clearProducts();
  await seeder.seedProducts();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MercaLista',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}