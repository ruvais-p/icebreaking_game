// quiz_event.dart

abstract class QuizEvent {}

class LoadQuestionsEvent extends QuizEvent {}

class CheckAnswerEvent extends QuizEvent {
  final String selectedAnswer;
  final Map question;

  CheckAnswerEvent({required this.selectedAnswer, required this.question});
}
