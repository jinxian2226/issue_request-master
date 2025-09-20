import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'services/parts_service.dart';
import 'services/stock_inquiry_service.dart';
import 'models/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hsrlentjglqgdvyhxhvd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhzcmxlbnRqZ2xxZ2R2eWh4aHZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MDgzMDYsImV4cCI6MjA3MzQ4NDMwNn0.uq6WrBMzBgglNNj0Lyg0f68TqfPleHH3hmAXcX1nuwo',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => PartsService()),
        ChangeNotifierProvider(create: (context) => StockInquiryService()),
      ],
      child: MaterialApp(
        title: 'PartInventory Pro',
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
          cardTheme: const CardThemeData(
            color: Color(0xFF2C2C2C),
            elevation: 0,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF2C2C2C),
            selectedItemColor: Color(0xFF2196F3),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize auth service when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().initializeAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF1A1A1A),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2196F3)),
                  SizedBox(height: 24),
                  Text(
                    'PartInventory Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (authService.isLoggedIn) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}