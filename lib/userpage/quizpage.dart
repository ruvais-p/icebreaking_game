import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class QuizPage extends StatefulWidget {
  final String email;
  final String userId;

  const QuizPage({super.key, required this.email, required this.userId});

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final DatabaseReference database = FirebaseDatabase.instance.ref();
  late StreamController<Map> _questionController;
  int score = 0;
  bool isLoading = true;
  List<Map> questions = [];
  int currentQuestionIndex = 0;
  Set<String> answeredQuestions = <String>{};

  @override
  void initState() {
    super.initState();
    _questionController = StreamController<Map>();
    _loadData();
  }

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
  // Get the current gameState from the database
  final gameStateSnapshot = await database.child("gameState").get();
  final gameState = gameStateSnapshot.value;

  // Proceed only if the gameState is "start"
  if (gameState == "start") {
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
  } else {
    // Notify the user that the game is not in progress
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Game is not active currently')),
    );
  }
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

  Widget _buildOptionButton(String option, int index, Map question) {
    final List<Color> buttonColors = [
      const Color(0xFFFF69B4),  // Pink
      const Color(0xFF90EE90),  // Green
      const Color(0xFFFFD700),  // Gold
      const Color(0xFF4D9FFF),  // Blue
    ];
    
    final List<Color> borderColors = [
      const Color(0xFFD4527A),  // Darker Pink
      const Color(0xFF6CB76C),  // Darker Green
      const Color(0xFFD4B400),  // Darker Gold
      const Color(0xFF3A78C2),  // Darker Blue
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () => _checkAnswer(option, question),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 24,
          ),
          decoration: BoxDecoration(
            color: buttonColors[index],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColors[index],
              width: 3,
            ),
          ),
          child: Text(
            "${String.fromCharCode(65 + index)}) $option",
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFFDF6E3), // Cream background color
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<Map>(
              stream: _questionController.stream,
              builder: (context, snapshot) {
                if (isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasData && snapshot.data!['no_more_questions'] == true) {
                  return const Center(child: Text("No more questions available."));
                }

                if (snapshot.hasData) {
                  final question = snapshot.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Quiz",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        question['question'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ...List.generate(
                        question['options'].length,
                        (index) => _buildOptionButton(
                          question['options'][index],
                          index,
                          question,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          "Score: $score",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return const Center(child: Text("An error occurred."));
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _questionController.close();
    super.dispose();
  }
}