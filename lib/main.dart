import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class QuizResult {
  final int score;
  final int totalQuestions;
  final int timeSeconds;
  final DateTime date;
  final String operations;
  final int min1;
  final int max1;
  final int min2;
  final int max2;

  QuizResult({
    required this.score,
    required this.totalQuestions,
    required this.timeSeconds,
    required this.date,
    required this.operations,
    required this.min1,
    required this.max1,
    required this.min2,
    required this.max2,
  });

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'totalQuestions': totalQuestions,
      'timeSeconds': timeSeconds,
      'date': date.toIso8601String(),
      'operations': operations,
    };
  }

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      score: json['score'],
      totalQuestions: json['totalQuestions'],
      timeSeconds: json['timeSeconds'],
      date: DateTime.parse(json['date']),
      operations: json['operations'],
      min1: json['min1'] ?? 1,
      max1: json['max1'] ?? 10,
      min2: json['min2'] ?? 1,
      max2: json['max2'] ?? 10,
    );
  }

  double get percentage => (score / totalQuestions) * 100;
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

class HistoryPage extends StatefulWidget {
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<QuizResult> results = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final resultsJson = prefs.getStringList('quiz_history') ?? [];
    final loadedResults = resultsJson.map((json) => QuizResult.fromJson(jsonDecode(json))).toList();

    // Sort by date (newest first)
    loadedResults.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      results = loadedResults;
      isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Clear History'),
      content: Text('Are you sure you want to clear all quiz history?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Clear'),
        ),
      ],
    ),
  );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('quiz_history');
      setState(() {
        results.clear();
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz History'),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (results.isNotEmpty)
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: _clearHistory,
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: isLoading
      ? Center(child: CircularProgressIndicator())
      : results.isEmpty
      ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No quiz history yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Complete a quiz to see your results here!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      )
      : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final result = results[index];
          final isGoodScore = result.percentage >= 80;

          return Card(
            margin: EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(result.date),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isGoodScore ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${result.percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: isGoodScore ? Colors.green[700] : Colors.orange[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Score: ${result.score}/${result.totalQuestions}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Time: ${_formatTime(result.timeSeconds)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        'Range: ${result.min1}-${result.max1} & ${result.min2}-${result.max2}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Operations: ${result.operations}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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

  void viewHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HistoryPage()),
    );
  }

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
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: viewHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                ),
                child: Text("View History"),
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
         _saveQuizResult();
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

  Future<void> _saveQuizResult() async {
    final prefs = await SharedPreferences.getInstance();
    final operations = <String>[];
    if (widget.useMultiplication) operations.add('Multiplication');
    if (widget.useDivision) operations.add('Division');

    final result = QuizResult(
      score: score,
      totalQuestions: widget.totalQuestions,
      timeSeconds: elapsedSeconds,
      date: DateTime.now(),
      operations: operations.join(', '),
      min1: widget.min1,
      max1: widget.max1,
      min2: widget.min2,
      max2: widget.max2,
    );

    final existingResultsJson = prefs.getStringList('quiz_history') ?? [];
    final existingResults = existingResultsJson.map((json) => QuizResult.fromJson(jsonDecode(json))).toList();

    existingResults.add(result);

    // Keep only the last 50 results
    if (existingResults.length > 50) {
         existingResults.removeAt(0);
       }

    final updatedResultsJson = existingResults.map((result) => jsonEncode(result.toJson())).toList();
    await prefs.setStringList('quiz_history', updatedResultsJson);
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
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height - 
            MediaQuery.of(context).padding.top -
            kToolbarHeight - 200, // Account for app bar and padding
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
        ),
      ),
    );
  }
}
