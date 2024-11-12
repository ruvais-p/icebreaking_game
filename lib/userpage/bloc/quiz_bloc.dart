// quiz_bloc.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'quiz_event.dart';
import 'quiz_state.dart';
import 'package:firebase_database/firebase_database.dart';

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final DatabaseReference database = FirebaseDatabase.instance.ref();
  List<Map> questions = [];
  Set<String> answeredQuestions = Set();
  int score = 0;

  QuizBloc() : super(QuizInitial());

  @override
  Stream<QuizState> mapEventToState(QuizEvent event) async* {
    if (event is LoadQuestionsEvent) {
      yield QuizLoadingState();

      // Load questions from Firebase
      final snapshot = await database.child("questions").get();
      if (snapshot.exists) {
        final data = snapshot.value as Map;
        questions = data.entries
            .map((e) => {
                  'id': e.key,
                  'question': e.value['question'],
                  'answer': e.value['answer'],
                  'options': e.value['options'],
                  'email': e.value['email'],
                })
            .toList();

        if (questions.isNotEmpty) {
          // Fire the first question
          yield QuizLoadedState(questions[0]);
        } else {
          yield QuizNoMoreQuestionsState();
        }
      } else {
        yield QuizNoMoreQuestionsState();
      }
    }

    if (event is CheckAnswerEvent) {
      // Check the answer and update the score
      if (event.selectedAnswer == event.question['answer']) {
        score += 4;
      } else {
        score -= 1;
      }

      // Mark question as answered and remove it
      answeredQuestions.add(event.question['id']);
      questions.remove(event.question);

      // Update score in the Firebase database
      await database.child("users").orderByChild("email").equalTo(event.question['email']).once().then((snapshot) {
        if (snapshot.snapshot.exists) {
          final userId = (snapshot.snapshot.value as Map).keys.first;
          database.child("users/$userId/score").set(score);
        }
      });

      // Proceed to the next question if available, otherwise end the quiz
      if (questions.isNotEmpty) {
        yield QuizLoadedState(questions[0]);
      } else {
        yield QuizNoMoreQuestionsState();
      }
    }
  }
}
