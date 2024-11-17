import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
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

  // Previous methods remain the same (_submitData)...

  Widget _buildStyledTextField(String labelText, TextEditingController controller, {bool isNumeric = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3A78C2),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          inputFormatters: isNumeric ? [FilteringTextInputFormatter.digitsOnly] : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Enter $labelText',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(
                color: Color(0xFF3A78C2),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(
                color: Color(0xFF4D9FFF),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $labelText';
            }
            return null;
          },
        ),
      ],
    ),
  );
}


  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF4D9FFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF3A78C2),
          width: 3,
        ),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitData,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Submit',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFFDF6E3),
        child: SafeArea(
          child: _iswaiting
              ? const Center(
                  child: Text(
                    "Waiting page.....",
                    style: TextStyle(
                      color: Color(0xFF3A78C2),
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Create Quiz",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildStyledTextField('Email', emailController),
                              _buildStyledTextField('Full Name', fullNameController),
                              _buildStyledTextField('Semester', semesterController, isNumeric: true),
                              _buildStyledTextField('Question', questionController),
                              _buildStyledTextField('Answer', answerController),
                              _buildStyledTextField('Option 1', option1Controller),
                              _buildStyledTextField('Option 2', option2Controller),
                              _buildStyledTextField('Option 3', option3Controller),
                              const SizedBox(height: 24),
                              _buildSubmitButton(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}