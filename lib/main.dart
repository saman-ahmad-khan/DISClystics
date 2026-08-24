import 'package:DISClystics/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'login.dart';
import 'register.dart';
import 'home.dart';

void main() async {

    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();




  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
  } catch (e) {
    print("🔥 Firebase initialization error: $e");
    // Consider showing an error screen here
  }

    runApp(
      EasyLocalization(
        supportedLocales: [Locale('en'), Locale('ur')],
        path: 'assets/translations', // Your JSON path
        fallbackLocale: Locale('en'),
        child: MyApp(),
      ),
    );
}

class MyApp extends StatelessWidget {
  final String? testInitialRoute; // Add this line

  const MyApp({super.key, this.testInitialRoute}); // Modify constructor

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final isLoggedIn = snapshot.hasData;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'DISClystics',
          theme: _buildAppTheme(),
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: isLoggedIn ? const HomeScreen() : const SignInPage(),
          routes: _appRoutes(),
          onUnknownRoute: _handleUnknownRoutes,
        );
      },
    );
  }

  ThemeData _buildAppTheme() {
    const primaryColor = Color(0xff582562);
    const secondaryColor = Color(0xffE4450F);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 16.0,
        ),
      ),
    );
  }

  Map<String, WidgetBuilder> _appRoutes() {
    return {
      '/login': (context) => const SignInPage(),
      '/register': (context) => const RegistrationScreen(),
      '/home': (context) => const HomeScreen(),
    };
  }

  Route<dynamic>? _handleUnknownRoutes(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text(
            'Page not found: ${settings.name}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}