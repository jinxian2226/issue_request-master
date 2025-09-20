import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'services/parts_service.dart';
import 'screens/home_screen.dart';

//After making Supabase project wide
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://hsrlentjglqgdvyhxhvd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhzcmxlbnRqZ2xxZ2R2eWh4aHZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MDgzMDYsImV4cCI6MjA3MzQ4NDMwNn0.uq6WrBMzBgglNNj0Lyg0f68TqfPleHH3hmAXcX1nuwo',
  );
  runApp(const MyApp());
}

//Original code
/*void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // Replace with your Supabase URL and anon key
    url: 'https://hsrlentjglqgdvyhxhvd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhzcmxlbnRqZ2xxZ2R2eWh4aHZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MDgzMDYsImV4cCI6MjA3MzQ4NDMwNn0.uq6WrBMzBgglNNj0Lyg0f68TqfPleHH3hmAXcX1nuwo',
  );

  runApp(const MyApp());
}*/

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PartsService(),
      child: MaterialApp(
        title: 'PartTracker Pro',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF2196F3),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF1A1A1A),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2C2C2C),
            foregroundColor: Colors.white,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}