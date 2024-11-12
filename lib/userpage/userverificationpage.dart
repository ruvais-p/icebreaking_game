import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:freshers/userpage/quizpage.dart';

class UserVerificationPage extends StatefulWidget {
  const UserVerificationPage({super.key});

  @override
  _UserVerificationPageState createState() => _UserVerificationPageState();
}

class _UserVerificationPageState extends State<UserVerificationPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final DatabaseReference database = FirebaseDatabase.instance.ref();

  // Corrected method to find userId by email
  Future<String?> _findUserIdByEmail(String email) async {
    try {
      final snapshot = await database
          .child('users')
          .orderByChild('email')
          .equalTo(email)
          .once();

      if (snapshot.snapshot.exists) {
        // If user exists, retrieve the userId (which is the key of the user)
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;

        // Getting the first key (which is the userId)
        final userId = data.keys.first;

        return userId;
      } else {
        // User does not exist
        print("User not found");
        return null;
      }
    } catch (e) {
      print("Error finding userId: $e");
      return null;
    }
  }

  // Handle button press and navigate to the quiz page
  void _verifyUser() async {
    final email = emailController.text.trim();

    // Call _findUserIdByEmail to find the userId
    final userId = await _findUserIdByEmail(email);

    if (userId != null) {
      // If userId is found, navigate to the QuizPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizPage(email: email, userId: userId),
        ),
      );
    } else {
      // If userId is not found, show an error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not found. Please register.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Verification")),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyUser, // Call _verifyUser on button press
              child: const Text("Continue..."),
            ),
          ],
        ),
      ),
    );
  }
}
