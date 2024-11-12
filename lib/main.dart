import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:freshers/userpage/adminpage.dart';
import 'package:freshers/userpage/loginpage.dart'; // Import LoginPage
import 'package:freshers/userpage/quizpagestate.dart';
import 'package:freshers/userpage/userverificationpage.dart'; // Import UserVerificationPage
import 'package:freshers/userpage/scoreboardpage.dart';
import 'package:provider/provider.dart'; // Import ScoreboardPage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAT9nOFo3DuDMksnTBtdKCgwS7LCLXwk4I",
      appId: "1:475088015638:web:ab5aa1ad2800104627c037",
      messagingSenderId: "475088015638",
      projectId: "freshers-8af04",
      databaseURL: "https://freshers-8af04-default-rtdb.firebaseio.com",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final DatabaseReference database = FirebaseDatabase.instance.ref();
  String gameState = 'login';

  @override
  void initState() {
    super.initState();
    _listenToGameState();
  }

  // Listen for real-time changes to gameState
  void _listenToGameState() {
    database.child("gameState").onValue.listen((event) {
      setState(() {
        gameState = event.snapshot.value.toString();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuizState(),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: _buildHomePage(),
      ),
    );
  }

  // Determine which page to show based on the gameState
  Widget _buildHomePage() {
    switch (gameState) {
      case 'login':
        return const LoginPage(); // Show LoginPage
      case 'start':
        return UserVerificationPage(); // Show UserVerificationPage
      case 'end':
        return ScoreboardPage(); // Show ScoreboardPage
      default:
        return const Center(
            child:
                CircularProgressIndicator()); // Loading indicator if state is unknown
    }
  }
}
