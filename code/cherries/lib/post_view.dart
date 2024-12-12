import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_page.dart';

class PostView extends StatefulWidget {
  final String postId; // ID of the review post
  const PostView({super.key, required this.postId});

  @override
  State<PostView> createState() => _PostViewState();
}

class _PostViewState extends State<PostView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Map<String, dynamic>? _postData;
  bool _isOwner = false;
  bool _isLoading = true;
  String _username = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchPostData();
  }

  Future<void> _fetchPostData() async {
    try {
      final postDoc =
          await _firestore.collection('reviews').doc(widget.postId).get();
      if (postDoc.exists) {
        final data = postDoc.data();
        setState(() {
          _postData = data;
          _isOwner = data?['userId'] == _currentUser?.uid;
        });

        // Fetch the username
        final userId = data?['userId'];
        if (userId != null) {
          final userDoc =
              await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            setState(() {
              _username = userDoc.data()?['username'] ?? 'Unknown';
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching post data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editReview() async {
    if (_postData == null) return;

    final TextEditingController descriptionController =
        TextEditingController(text: _postData?['description']);
    double rating = _postData?['rating'] ?? 3.0;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Edit Review',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Edit your review description...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text(
                      'Rating:',
                      style: TextStyle(color: Colors.white),
                    ),
                    Expanded(
                      child: Slider(
                        value: rating,
                        min: 1.0,
                        max: 5.0,
                        divisions: 40,
                        label: rating.toStringAsFixed(1),
                        activeColor: Colors.amber,
                        inactiveColor: Colors.grey,
                        onChanged: (value) {
                          setDialogState(() {
                            rating = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await _firestore
                        .collection('reviews')
                        .doc(widget.postId)
                        .update({
                      'description': descriptionController.text.trim(),
                      'rating': rating,
                    });
                    setState(() {
                      _postData?['description'] =
                          descriptionController.text.trim();
                      _postData?['rating'] = rating;
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Review updated!')),
                    );
                  } catch (e) {
                    print('Error updating review: $e');
                  }
                },
                child:
                    const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Post View'),
          backgroundColor: Colors.black,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_postData == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Post View'),
          backgroundColor: Colors.black,
        ),
        body: const Center(
          child: Text('Post not found', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final imageUrl = _postData?['imageUrl'] ?? '';
    final description = _postData?['description'] ?? 'No description';
    final restaurantName = _postData?['restaurantName'] ?? 'Unknown';
    final rating = _postData?['rating'] ?? 0.0;
    final userId = _postData?['userId'];
    final date = (_postData?['timestamp'] as Timestamp?)
            ?.toDate()
            .toLocal()
            .toString()
            .split(' ')[0] ??
        'Unknown Date';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          restaurantName,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        actions: [
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _editReview,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.network(
                  imageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      size: 100,
                      color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (userId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserPage(userId: userId),
                        ),
                      );
                    }
                  },
                  child: Text(
                    _username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontSize: 18,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  date,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 5),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              description,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
