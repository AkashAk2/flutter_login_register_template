import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roomie/login.dart';
import 'package:roomie/homepage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roomie',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomePage(),
        // '/settings': (context) => SettingsScreen(), // Assuming you have a settings screen
      },
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextPage();
  }

  _navigateToNextPage() async {
  // Simulate a splash screen delay
  await Future.delayed(Duration(seconds: 2));

  var currentUser = FirebaseAuth.instance.currentUser;
  print("Current User: $currentUser"); // Check the console for output

  if (currentUser != null) {
    // User is logged in
    print("Navigating to Home");
    Navigator.of(context).pushReplacementNamed('/home');
  } else {
    // User is not logged in
    print("Navigating to Login");
    Navigator.of(context).pushReplacementNamed('/login');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Roomie',
          style: Theme.of(context).textTheme.headline3?.copyWith(color: Colors.deepPurple),
        ),
      ),
    );
  }
}
