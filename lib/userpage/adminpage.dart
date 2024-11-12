import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final DatabaseReference database = FirebaseDatabase.instance.ref();
  String gameState = 'login'; // Initial game state
  List<Map> users = []; // To store user data for the scoreboard
  bool isLoading = true;
  late Stream<DatabaseEvent> gameStateStream; // Stream for gameState changes

  @override
  void initState() {
    super.initState();
    _initializeGameStateListener();
    _loadUsers();
  }

  // Initialize the game state listener
  void _initializeGameStateListener() {
    gameStateStream = database.child("gameState").onValue;
    gameStateStream.listen((event) {
      final newState = event.snapshot.value.toString();
      setState(() {
        gameState = newState;
      });
      // Reload users if the game is started or ended to update the leaderboard
      if (newState == 'start' || newState == 'end') {
        _loadUsers();
      }
    });
  }

  // Load user scores for the scoreboard
  Future<void> _loadUsers() async {
    setState(() {
      isLoading = true;
    });
    final snapshot = await database.child("users").get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      users = data.entries
          .map((e) => {
                'name': e.value['fullName'], // Retrieve name
                'semester': e.value['semester'], // Retrieve semester
                'score': e.value['score'], // Retrieve score
              })
          .toList();

      // Ensure score is treated as an integer for comparison
      users.sort((a, b) {
        int scoreA = a['score'] is int
            ? a['score']
            : int.tryParse(a['score'].toString()) ?? 0;
        int scoreB = b['score'] is int
            ? b['score']
            : int.tryParse(b['score'].toString()) ?? 0;
        return scoreB.compareTo(scoreA); // Sorting in descending order
      });

      setState(() {
        isLoading = false;
      });
    }
  }

  // Update game state in Firebase
  Future<void> _updateGameState(String state) async {
    await database.child("gameState").set(state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Page")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _updateGameState('login'),
                  child: const Text("Login"),
                ),
                ElevatedButton(
                  onPressed: () => _updateGameState('start'),
                  child: const Text("Start"),
                ),
                ElevatedButton(
                  onPressed: () => _updateGameState('end'),
                  child: const Text("End"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text("Current Game State: $gameState",
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            // Show scoreboard if game state is 'start' or 'end'
            if (gameState == 'start' || gameState == 'end')
              isLoading
                  ? const CircularProgressIndicator()
                  : Expanded(
                      child: ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                                "Name: ${users[index]['name']}"), // Display name
                            subtitle: Text(
                                "Semester: ${users[index]['semester']}"), // Display semester
                            trailing: Text(
                                "Score: ${users[index]['score']}"), // Display score
                          );
                        },
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}
