// quiz_state.dart

abstract class QuizState {}

class QuizInitial extends QuizState {}

class QuizLoadingState extends QuizState {}

class QuizLoadedState extends QuizState {
  final Map question;

  QuizLoadedState(this.question);
}

class QuizAnsweredState extends QuizState {
  final int score;
  final Map question;

  QuizAnsweredState({required this.score, required this.question});
}

class QuizNoMoreQuestionsState extends QuizState {}
