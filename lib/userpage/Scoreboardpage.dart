import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ScoreboardPage extends StatefulWidget {
  const ScoreboardPage({super.key});

  @override
  _ScoreboardPageState createState() => _ScoreboardPageState();
}

class _ScoreboardPageState extends State<ScoreboardPage> {
  final DatabaseReference database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final snapshot = await database.child("users").get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      users = data.entries.map((e) {
        return {
          'name': e.value['fullName'],
          'semester': e.value['semester'],
          'score': e.value['score'],
        };
      }).toList();

      users.sort((a, b) => b['score'].compareTo(a['score']));

      setState(() {
        isLoading = false;
      });
    }
  }

  Color _getMedalColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // Gold
      case 1:
        return const Color(0xFFC0C0C0); // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.transparent;
    }
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    final bool isTopThree = index < 3;
    final medalColor = _getMedalColor(index);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isTopThree ? medalColor.withOpacity(0.1) : Colors.white,
        border: Border.all(
          color: isTopThree ? medalColor : const Color(0xFF3A78C2),
          width: isTopThree ? 3 : 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isTopThree ? medalColor : const Color(0xFF4D9FFF),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isTopThree ? medalColor.withOpacity(0.7) : const Color(0xFF3A78C2),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isTopThree ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'] ?? "Unknown",
                    style: TextStyle(
                      fontSize: isTopThree ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Semester: ${user['semester'] ?? 'N/A'}",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isTopThree ? medalColor.withOpacity(0.2) : const Color(0xFF4D9FFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isTopThree ? medalColor : const Color(0xFF3A78C2),
                  width: 2,
                ),
              ),
              child: Text(
                "${user['score']}",
                style: TextStyle(
                  fontSize: isTopThree ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: isTopThree ? Colors.black : const Color(0xFF3A78C2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFFDF6E3),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Scoreboard",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : users.isEmpty
                          ? const Center(
                              child: Text(
                                "No users found",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF3A78C2),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                return _buildUserCard(users[index], index);
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}