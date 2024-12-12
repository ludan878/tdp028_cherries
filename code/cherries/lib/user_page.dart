import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'post_view.dart';

class UserPage extends StatefulWidget {
  final String? userId; // Profile being viewed (null for logged-in user)
  const UserPage({super.key, this.userId});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  String? _username;
  String? _description;
  String? _profilePicture;
  int _followersCount = 0;
  int _followingCount = 0;
  bool _isCurrentUser = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _isCurrentUser =
        widget.userId == null || widget.userId == _currentUser?.uid;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final userId = widget.userId ?? _currentUser?.uid;
    if (userId == null) return;

    try {
      // Fetch user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _username = data['username'];
          _description = data['description'] ?? "No description available.";
          _profilePicture = data['profilePicture'];
          _followersCount = data['followers'] ?? 0;
          _followingCount = data['following'] ?? 0;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editDescription() async {
    final TextEditingController descriptionController =
        TextEditingController(text: _description ?? "");

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Description'),
        content: TextField(
          controller: descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter a new description...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newDescription = descriptionController.text.trim();
              if (newDescription.isNotEmpty) {
                try {
                  await _firestore
                      .collection('users')
                      .doc(_currentUser?.uid)
                      .update({'description': newDescription});
                  setState(() {
                    _description = newDescription;
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Description updated!')),
                  );
                } catch (e) {
                  print('Error updating description: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error updating description')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title:
            const Text('User Profile', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _profilePicture != null
                      ? NetworkImage(_profilePicture!)
                      : null,
                  backgroundColor: Colors.white,
                  child: _profilePicture == null
                      ? const Icon(Icons.person, size: 60, color: Colors.black)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _username ?? 'Unknown',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _description ?? 'No description available.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (_isCurrentUser)
              ElevatedButton(
                onPressed: _editDescription,
                child: const Text('Edit Description'),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      '$_followersCount',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Followers',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(width: 40),
                Column(
                  children: [
                    Text(
                      '$_followingCount',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Following',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Reviews Grid
            const Text(
              'Reviews',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('reviews')
                  .where('userId',
                      isEqualTo: widget.userId ?? _currentUser?.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text(
                    'No reviews yet.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  );
                }

                final reviews = snapshot.data!.docs;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.7,
                  ),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    final imageUrl = review['imageUrl'] ?? '';
                    final restaurantName =
                        review['restaurantName'] ?? 'Unknown';
                    final rating = review['rating'] ?? 0;
                    final date = (review['timestamp'] as Timestamp?)
                            ?.toDate()
                            .toLocal()
                            .toString()
                            .split(' ')[0] ??
                        '';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostView(
                              postId: review.id,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image,
                                        color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            restaurantName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            date,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
