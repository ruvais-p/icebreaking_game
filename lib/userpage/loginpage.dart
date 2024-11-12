import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for each field
  final TextEditingController emailController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController semesterController = TextEditingController();
  final TextEditingController questionController = TextEditingController();
  final TextEditingController answerController = TextEditingController();
  final TextEditingController option1Controller = TextEditingController();
  final TextEditingController option2Controller = TextEditingController();
  final TextEditingController option3Controller = TextEditingController();

  final DatabaseReference database = FirebaseDatabase.instance.ref();

  bool _isLoading = false;
  bool _iswaiting = false;

  Future<void> _submitData() async {
    String question;
    if (_formKey.currentState!.validate()) {
      question =
          "${fullNameController.text}'s (S${semesterController.text}) ${questionController.text}";

      setState(() {
        _isLoading = true; // Show loader
      });

      try {
        // Create User data
        final userData = {
          "email": emailController.text,
          "fullName": fullNameController.text,
          "semester": semesterController.text,
          "score": 0
        };

        // Create Question data
        final questionData = {
          "email": emailController.text,
          "question": question,
          "answer": answerController.text,
          "options": [
            option1Controller.text,
            option2Controller.text,
            option3Controller.text,
            answerController.text,
          ]
        };

        // Save data to Firebase
        await database.child("users").push().set(userData);
        await database.child("questions").push().set(questionData);

        // Clear form fields after submission
        emailController.clear();
        fullNameController.clear();
        semesterController.clear();
        questionController.clear();
        answerController.clear();
        option1Controller.clear();
        option2Controller.clear();
        option3Controller.clear();

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created successfully')),
        );
        setState(() {
          _iswaiting = true;
        });
      } catch (e) {
        // Show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit data: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false; // Hide loader
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _iswaiting
          ? const Text(
              "Waiting page.....",
              style: TextStyle(color: Colors.red, fontSize: 30),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                          labelText: 'Email', controller: emailController),
                      CustomTextField(
                          labelText: 'Full Name',
                          controller: fullNameController),
                      CustomTextField(
                          labelText: 'Semester',
                          controller: semesterController),
                      CustomTextField(
                          labelText: 'Question',
                          controller: questionController),
                      CustomTextField(
                          labelText: 'Answer', controller: answerController),
                      CustomTextField(
                          labelText: 'Option 1', controller: option1Controller),
                      CustomTextField(
                          labelText: 'Option 2', controller: option2Controller),
                      CustomTextField(
                          labelText: 'Option 3', controller: option3Controller),
                      const SizedBox(height: 20),
                      _isLoading
                          ? const CircularProgressIndicator() // Show loader if loading
                          : ElevatedButton(
                              onPressed:
                                  _submitData, // Call _submitData function
                              child: const Text('Submit'),
                            ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String labelText;
  final TextEditingController controller;

  const CustomTextField({super.key, required this.labelText, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $labelText';
          }
          return null;
        },
      ),
    );
  }
}
