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
  bool _isLiked = false;
  String _username = 'Loading...';
  int _likeCount = 0;

  final TextEditingController _commentController = TextEditingController();

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
          _likeCount = data?['likes']?.length ?? 0;
          _isLiked = data?['likes']?.contains(_currentUser?.uid) ?? false;
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

  Future<void> _toggleLike() async {
    if (_postData == null || _currentUser == null) return;

    final userId = _currentUser!.uid;
    final likes = _postData?['likes'] ?? [];

    try {
      if (_isLiked) {
        // Unlike the post
        await _firestore.collection('reviews').doc(widget.postId).update({
          'likes': FieldValue.arrayRemove([userId]),
        });
        setState(() {
          _isLiked = false;
          _likeCount -= 1;
        });
      } else {
        // Like the post
        await _firestore.collection('reviews').doc(widget.postId).update({
          'likes': FieldValue.arrayUnion([userId]),
        });
        setState(() {
          _isLiked = true;
          _likeCount += 1;
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  Future<void> _postComment(String commentText) async {
    if (commentText.trim().isEmpty || _currentUser == null) return;

    try {
      // Fetch the username of the current user
      final currentUserDoc =
          await _firestore.collection('users').doc(_currentUser!.uid).get();
      final currentUsername = currentUserDoc.data()?['username'] ?? 'Unknown';

      // Create a new comment
      final newComment = {
        'userId': _currentUser!.uid,
        'username': currentUsername, // Save the commenter's username
        'text': commentText,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('reviews')
          .doc(widget.postId)
          .collection('comments')
          .add(newComment);

      _commentController.clear();
    } catch (e) {
      print('Error posting comment: $e');
    }
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
                    final userId = _postData?['userId'];
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
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.white,
                  ),
                  onPressed: _toggleLike,
                ),
                Text(
                  '$_likeCount',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              description,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            const Divider(color: Colors.grey),
            const SizedBox(height: 10),
            const Text(
              'Comments',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('reviews')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                final comments = snapshot.data!.docs;

                if (comments.isEmpty) {
                  return const Text(
                    'No comments yet.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment =
                        comments[index].data() as Map<String, dynamic>;
                    final username = comment['username'] ?? 'Unknown';
                    final text = comment['text'] ?? '';
                    final timestamp = (comment['timestamp'] as Timestamp?)
                        ?.toDate()
                        .toLocal()
                        .toString()
                        .split(' ')[0];

                    return ListTile(
                      title: Text(
                        username,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        text,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: Text(
                        timestamp ?? '',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () {
                    _postComment(_commentController.text.trim());
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
