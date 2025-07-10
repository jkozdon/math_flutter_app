import 'dart:math';
import 'package:flutter/material.dart';

class QuestionData {
  final int num1;
  final int num2;
  final String operator;
  final int correctAnswer;
  final int? userAnswer;
  final bool isCorrect;

  QuestionData({
    required this.num1,
    required this.num2,
    required this.operator,
    required this.correctAnswer,
    this.userAnswer,
    required this.isCorrect,
  });

  String get questionText => '$num1 $operator $num2 = $correctAnswer';
}

void main() {
  runApp(MathQuizApp());
}

class MathQuizApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Quiz',
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final numQuestionsController = TextEditingController(text: '10');

  final min1Controller = TextEditingController(text: '1');
  final max1Controller = TextEditingController(text: '10');
  final min2Controller = TextEditingController(text: '1');
  final max2Controller = TextEditingController(text: '10');

  bool includeMultiplication = true;
  bool includeDivision = true;

  void startQuiz() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizPage(
            totalQuestions: int.parse(numQuestionsController.text),
            min1: int.parse(min1Controller.text),
            max1: int.parse(max1Controller.text),
            min2: int.parse(min2Controller.text),
            max2: int.parse(max2Controller.text),
            useMultiplication: includeMultiplication,
            useDivision: includeDivision,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Math Quiz Setup'), backgroundColor: Colors.deepPurple),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text("Number of Questions", style: TextStyle(fontSize: 18)),
              TextFormField(
                controller: numQuestionsController,
                keyboardType: TextInputType.number,
                validator: (val) =>
                  val == null || int.tryParse(val) == null || int.parse(val) < 1
                  ? "Enter a valid number"
                  : null,
              ),
              SizedBox(height: 20),
              Text("Range for First Number", style: TextStyle(fontSize: 18)),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: min1Controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Min 1'),
                      validator: (val) => val == null || int.tryParse(val) == null
                        ? "Enter min"
                        : null,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: max1Controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Max 1'),
                      validator: (val) => val == null || int.tryParse(val) == null
                        ? "Enter max"
                        : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text("Range for Second Number", style: TextStyle(fontSize: 18)),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: min2Controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Min 2'),
                      validator: (val) => val == null || int.tryParse(val) == null
                        ? "Enter min"
                        : null,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: max2Controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Max 2'),
                      validator: (val) => val == null || int.tryParse(val) == null
                        ? "Enter max"
                        : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text("Operations", style: TextStyle(fontSize: 18)),
              CheckboxListTile(
                value: includeMultiplication,
                onChanged: (val) => setState(() => includeMultiplication = val ?? false),
                title: Text("Multiplication"),
              ),
              CheckboxListTile(
                value: includeDivision,
                onChanged: (val) => setState(() => includeDivision = val ?? false),
                title: Text("Division (no remainder)"),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: startQuiz,
                child: Text("Start Quiz"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuizPage extends StatefulWidget {
  final int totalQuestions;
  final int min1, max1, min2, max2;
  final bool useMultiplication;
  final bool useDivision;

  QuizPage({
    required this.totalQuestions,
    required this.min1,
    required this.max1,
    required this.min2,
    required this.max2,
    required this.useMultiplication,
    required this.useDivision,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int num1 = 0;
  int num2 = 0;
  String operator = '';
  int answer = 0;

  int currentQuestion = 1;
  int score = 0;
  final TextEditingController controller = TextEditingController();
  late Stopwatch stopwatch;
  bool quizFinished = false;
  int elapsedSeconds = 0;
  List<QuestionData> allQuestions = [];

  late List<String> allowedOperators;

  final FocusNode _answerFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    allowedOperators = [];
    if (widget.useMultiplication) allowedOperators.add('×');
    if (widget.useDivision) allowedOperators.add('÷');

    if (allowedOperators.isEmpty) {
      allowedOperators.add('×'); // fallback
    }

    startQuiz();
  }

  void startQuiz() {
    score = 0;
    currentQuestion = 1;
    quizFinished = false;
    elapsedSeconds = 0;
    stopwatch = Stopwatch()..start();
    generateQuestion();
    setState(() {});
  }

  void generateQuestion() {
    final rand = Random();
    operator = allowedOperators[rand.nextInt(allowedOperators.length)];

    int a, b;

    a = rand.nextInt(widget.max1 - widget.min1 + 1) + widget.min1;
    b = rand.nextInt(widget.max2 - widget.min2 + 1) + widget.min2;

    // Randomize order
    if (rand.nextBool()) {
      num1 = a;
      num2 = b;
    } else {
      num1 = b;
      num2 = a;
    }

    if (operator == '×') {
      answer = num1 * num2;
    } else {
      int result = num1 * num2;
      answer = num1;
      num1 = result;
    }
  }

  void checkAnswer(String? input) {
    int? userAnswer = int.tryParse(input ?? '');
    bool isCorrect = userAnswer == answer;
    if (isCorrect) score++;

    // Store the question data
    allQuestions.add(QuestionData(
      num1: num1,
      num2: num2,
      operator: operator,
      correctAnswer: answer,
      userAnswer: userAnswer,
      isCorrect: isCorrect,
    ));

    controller.clear();

    if (currentQuestion >= widget.totalQuestions) {
      stopwatch.stop();
      elapsedSeconds = stopwatch.elapsed.inSeconds;
      quizFinished = true;
      setState(() {});
    } else {
      currentQuestion++;
      generateQuestion();
      setState(() {});
       // Request focus after the widget rebuilds
       WidgetsBinding.instance.addPostFrameCallback((_) {
         _answerFocusNode.requestFocus();
       });
    }
  }

  void restartQuiz() {
    Navigator.pop(context); // Go back to settings screen
  }

  @override
  void dispose() {
    stopwatch.stop();
    controller.dispose();
    _answerFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (quizFinished) {
      List<QuestionData> missedQuestions = allQuestions.where((q) => !q.isCorrect).toList();

      return Scaffold(
        appBar: AppBar(title: Text('Quiz Complete'), backgroundColor: Colors.deepPurple),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Score section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text('Your Score:', style: TextStyle(fontSize: 24)),
                      SizedBox(height: 10),
                      Text(
                        '$score / ${widget.totalQuestions}',
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                      SizedBox(height: 20),
                      Text('Total Time:', style: TextStyle(fontSize: 18)),
                      SizedBox(height: 5),
                      Text(
                        '$elapsedSeconds seconds',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),

                // Missed problems section
                if (missedQuestions.isNotEmpty) ...[
                  Text(
                    'Problems You Missed:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red[700]),
                  ),
                  SizedBox(height: 15),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: missedQuestions.length,
                      separatorBuilder: (context, index) => Divider(height: 1),
                      itemBuilder: (context, index) {
                        final question = missedQuestions[index];
                        return Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${question.num1} ${question.operator} ${question.num2} = ?',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'Your answer: ',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    question.userAnswer?.toString() ?? 'No answer',
                                    style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Correct answer: ',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    question.correctAnswer.toString(),
                                    style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 30),
                ] else ...[
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 32),
                        SizedBox(width: 12),
                        Text(
                          'Perfect Score! 🎉',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[700]),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                ],

                ElevatedButton(
                  onPressed: restartQuiz,
                  child: Text('Back to Settings'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Math Quiz'), backgroundColor: Colors.deepPurple),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Question $currentQuestion of ${widget.totalQuestions}', style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            Text('Score: $score', style: TextStyle(fontSize: 18)),
            SizedBox(height: 40),
            Text(
              '$num1 $operator $num2 = ?',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            TextField(
              controller: controller,
              focusNode: _answerFocusNode,
              keyboardType: TextInputType.number,
              onSubmitted: checkAnswer,
              decoration: InputDecoration(
                hintText: 'Enter your answer',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => checkAnswer(controller.text),
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

