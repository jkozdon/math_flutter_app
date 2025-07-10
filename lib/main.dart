import 'dart:math';
import 'package:flutter/material.dart';

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
  final TextEditingController numQuestionsController = TextEditingController(text: '10');
  final TextEditingController minController = TextEditingController(text: '1');
  final TextEditingController maxController = TextEditingController(text: '10');

  bool includeMultiplication = true;
  bool includeDivision = true;

  void startQuiz() {
    if (_formKey.currentState!.validate()) {
      int numQuestions = int.parse(numQuestionsController.text);
      int min = int.parse(minController.text);
      int max = int.parse(maxController.text);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizPage(
            totalQuestions: numQuestions,
            min: min,
            max: max,
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
              Text("Range (min - max)", style: TextStyle(fontSize: 18)),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: minController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Min'),
                      validator: (val) => val == null || int.tryParse(val) == null
                          ? "Enter min"
                          : null,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: maxController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Max'),
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
  final int min;
  final int max;
  final bool useMultiplication;
  final bool useDivision;

  QuizPage({
    required this.totalQuestions,
    required this.min,
    required this.max,
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

  late List<String> allowedOperators;

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

    if (operator == '×') {
      num1 = rand.nextInt(widget.max - widget.min + 1) + widget.min;
      num2 = rand.nextInt(widget.max - widget.min + 1) + widget.min;
      answer = num1 * num2;
    } else {
      num2 = rand.nextInt(widget.max - widget.min + 1) + widget.min;
      answer = rand.nextInt(widget.max - widget.min + 1) + widget.min;
      num1 = num2 * answer;
    }
  }

  void checkAnswer(String? input) {
    int? userAnswer = int.tryParse(input ?? '');
    if (userAnswer == answer) score++;

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
    }
  }

  void restartQuiz() {
    Navigator.pop(context); // go back to settings
  }

  @override
  void dispose() {
    stopwatch.stop();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (quizFinished) {
      return Scaffold(
        appBar: AppBar(title: Text('Quiz Complete'), backgroundColor: Colors.deepPurple),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Your Score:', style: TextStyle(fontSize: 24)),
                SizedBox(height: 10),
                Text(
                  '$score / ${widget.totalQuestions}',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                SizedBox(height: 30),
                Text('Total Time:', style: TextStyle(fontSize: 24)),
                SizedBox(height: 10),
                Text(
                  '$elapsedSeconds seconds',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 40),
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

