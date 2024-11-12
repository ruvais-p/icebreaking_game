import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class QuizPage extends StatefulWidget {
  final String email;
  final String userId; // Pass user ID along with email

  const QuizPage({super.key, required this.email, required this.userId});

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final DatabaseReference database = FirebaseDatabase.instance.ref();
  late StreamController<Map> _questionController;
  int score = 0; // The initial score will be fetched from Firebase
  bool isLoading = true;
  List<Map> questions = [];
  int currentQuestionIndex = 0;
  Set<String> answeredQuestions = <String>{}; // Track answered questions

  @override
  void initState() {
    super.initState();
    _questionController = StreamController<Map>();
    _loadData();
  }

  // Load both the questions and user's score from the database
  Future<void> _loadData() async {
    try {
      // Fetch the user's data from the database
      final userSnapshot =
          await database.child('users').child(widget.userId).get();

      if (userSnapshot.exists && userSnapshot.value != null) {
        // Check if the 'score' field exists, if not set the score to 0
        final userData = userSnapshot.value as Map?;
        setState(() {
          score = userData?['score'] ??
              0; // Initialize score from database or default to 0
        });
      } else {
        setState(() {
          score = 0; // If no user data is found, initialize score to 0
        });
      }

      // Fetch the quiz questions
      final questionSnapshot = await database.child("questions").get();
      if (questionSnapshot.exists) {
        final data = questionSnapshot.value as Map;

        // Filter out questions that are already assigned to this email
        questions = data.entries
            .where((e) {
              // Check if the email is not part of the question data
              return e.value['email'] != widget.email;
            })
            .map((e) => {
                  'id': e.key,
                  'question': e.value['question'],
                  'answer': e.value['answer'],
                  'options': List<String>.from(e.value['options']),
                })
            .toList();

        setState(() {
          isLoading = false;
        });

        // Shuffle the questions to ensure random order for each player
        questions.shuffle();

        // Emit the first question to the stream
        if (questions.isNotEmpty) {
          _showNextQuestion();
        }
      }
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  // Show next question, ensuring it's not already answered
  void _showNextQuestion() {
    for (int i = currentQuestionIndex; i < questions.length; i++) {
      final question = questions[i];

      // Check if the question has been answered by this player
      if (!answeredQuestions.contains(question['id'])) {
        // Randomize the options for the current question
        question['options'].shuffle();

        // Add the question to the stream
        _questionController.add(question);
        currentQuestionIndex = i + 1; // Update the current question index
        return;
      }
    }

    // If no more questions, stop the quiz and notify the player
    _questionController.add({'no_more_questions': true});
  }

  // Check the answer, update score, and load the next random question
  Future<void> _checkAnswer(String selectedAnswer, Map question) async {
    if (selectedAnswer == question['answer']) {
      score += 4;
    } else {
      score -= 1;
    }

    // Mark the question as answered
    answeredQuestions.add(question['id']);

    // Update the score in Firebase
    await _updateScoreInDatabase();

    // Move to the next question (loop through the shuffled list)
    _showNextQuestion();
  }

  // Method to update score in Firebase
  Future<void> _updateScoreInDatabase() async {
    try {
      // Update the score for the user in the Firebase database using userId
      await database.child('users').child(widget.userId).update({
        'score': score,
      });
    } catch (e) {
      print('Error updating score: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
    _questionController.close(); // Close the StreamController
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quiz")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<Map>(
          stream: _questionController.stream,
          builder: (context, snapshot) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Handle loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Handle the case when no more questions are available
            if (snapshot.hasData &&
                snapshot.data!['no_more_questions'] == true) {
              return const Center(child: Text("No more questions available."));
            }

            // Handle the state when data is available (quiz ongoing)
            if (snapshot.hasData) {
              final question = snapshot.data!;

              return Column(
                children: [
                  Text(
                    question['question'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ...question['options'].map<Widget>((option) {
                    return ListTile(
                      title: Text(option),
                      onTap: () => _checkAnswer(option, question),
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                  Text("Score: $score"),
                ],
              );
            }

            // Default case (shouldn't hit unless there's an issue)
            return const Center(child: Text("An error occurred."));
          },
        ),
      ),
    );
  }
}
