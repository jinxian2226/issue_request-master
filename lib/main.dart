import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'services/parts_service.dart';
import 'services/stock_inquiry_service.dart';
import 'services/theme_service.dart';
import 'models/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigator.dart';
import 'screens/part_marking.dart';

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
        ChangeNotifierProvider(create: (context) => ThemeService()),
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => PartsService()),
        ChangeNotifierProvider(create: (context) => StockInquiryService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'PartInventory Pro',
            debugShowCheckedModeBanner: false,
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: '/',
            routes: {
              '/': (context) => const AuthWrapper(),
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const MainNavigator(),
            },
          );
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
    return Consumer2<AuthService, ThemeService>(
      builder: (context, authService, themeService, child) {
        if (authService.isLoading) {
          return Scaffold(
            backgroundColor: themeService.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[100],
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF2196F3)),
                  const SizedBox(height: 24),
                  Text(
                    'PartInventory Pro',
                    style: TextStyle(
                      color: themeService.isDarkMode ? Colors.white : Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      color: themeService.isDarkMode ? Colors.grey : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (authService.isLoggedIn) {
          return const MainNavigator();
        }

        return const LoginScreen();
      },
    );
  }
}