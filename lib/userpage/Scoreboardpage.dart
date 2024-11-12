import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ScoreboardPage extends StatefulWidget {
  @override
  _ScoreboardPageState createState() => _ScoreboardPageState();
}

class _ScoreboardPageState extends State<ScoreboardPage> {
  final DatabaseReference database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> users = [];  // To store user data
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // Load users from Firebase and sort them by score
  Future<void> _loadUsers() async {
    final snapshot = await database.child("users").get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      users = data.entries.map((e) {
        return {
          'name': e.value['fullName'],        // Get the name field
          'semester': e.value['semester'], // Get the semester field
          'score': e.value['score'],       // Get the score field
        };
      }).toList();

      // Sort users by score in descending order
      users.sort((a, b) => b['score'].compareTo(a['score']));

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scoreboard")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : users.isEmpty
                ? Center(child: Text("No users found"))
                : ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(users[index]['name'] ?? "Unknown"),
                        subtitle: Text("Semester: ${users[index]['semester'] ?? "N/A"}"),
                        trailing: Text("Score: ${users[index]['score']}"),
                      );
                    },
                  ),
      ),
    );
  }
}
