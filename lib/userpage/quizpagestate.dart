import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class QuizState with ChangeNotifier {
  List<Map> questions = [];
  Set<String> answeredQuestions = Set();
  int score = 0;
  bool isLoading = true;

  // Load questions
  Future<void> loadQuestions(DatabaseReference database) async {
    final snapshot = await database.child("questions").get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      questions = data.entries.map((e) => {
            'id': e.key,
            'question': e.value['question'],
            'answer': e.value['answer'],
            'options': e.value['options'],
            'email': e.value['email'],
          }).toList();
      isLoading = false;
      notifyListeners();  // Notify listeners after data is loaded
    }
  }

  // Check answer and update the score
  Timer? _debounceTimer;

Future<void> checkAnswer(String selectedAnswer, Map question, DatabaseReference database, String email) async {
  // Cancel previous debounce
  _debounceTimer?.cancel();

  _debounceTimer = Timer(Duration(milliseconds: 200), () async {
    if (selectedAnswer == question['answer']) {
      score += 4;
    } else {
      score -= 1;
    }

    // Update the score in the database
    await database.child("users").orderByChild("email").equalTo(email).once().then((snapshot) {
      if (snapshot.snapshot.exists) {
        final userId = (snapshot.snapshot.value as Map).keys.first;
        database.child("users/$userId/score").set(score);
      }
    });

    // Mark the question as answered and reload
    answeredQuestions.add(question['id']);
    questions.remove(question);

    notifyListeners();  // Notify listeners after the delay

    if (questions.isEmpty) {
      loadQuestions(database);  // Reload questions if all are answered
    }
  });
}


  // Get the next unanswered question
  Map getNextQuestion() {
    final unansweredQuestions = questions.where((q) => !answeredQuestions.contains(q['id'])).toList();
    if (unansweredQuestions.isNotEmpty) {
      final random = Random();
      return unansweredQuestions[random.nextInt(unansweredQuestions.length)];
    }
    return {};
  }
}
