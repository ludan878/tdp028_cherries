import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Upload image to ImgBB and return the image URL
  Future<String> uploadImageToImgBB(File imageFile) async {
    const String apiKey = 'YOUR_IMGBB_API_KEY';

    try {
      // Read image as bytes
      List<int> imageBytes = await imageFile.readAsBytes();

      // Convert to base64 string
      String base64Image = base64Encode(imageBytes);

      // Upload to ImgBB
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: {
          "key": apiKey,
          "image": base64Image,
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['data']['display_url']; // URL of the uploaded image
      } else {
        throw Exception('Failed to upload image: ${response.body}');
      }
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image');
    }
  }

  // Submit a new review and update the user document
  Future<void> submitReview({
    required String userId,
    required String restaurantName,
    required String description,
    required double rating,
    required File imageFile,
  }) async {
    try {
      // Step 1: Upload the image
      String imageUrl = await uploadImageToImgBB(imageFile);

      // Step 2: Generate unique review ID
      String reviewId = _firestore.collection('reviews').doc().id;

      // Step 3: Prepare review data
      Map<String, dynamic> reviewData = {
        "reviewId": reviewId,
        "userId": userId,
        "restaurantName": restaurantName,
        "description": description,
        "rating": rating,
        "imageUrl": imageUrl,
        "timestamp": FieldValue.serverTimestamp(),
      };

      // Step 4: Add review to "reviews" collection
      await _firestore.collection('reviews').doc(reviewId).set(reviewData);

      // Step 5: Update user's "reviews" array in the "users" collection
      await _firestore.collection('users').doc(userId).update({
        "reviews": FieldValue.arrayUnion([reviewId]),
      });

      print('Review submitted successfully!');
    } catch (e) {
      print('Error submitting review: $e');
      throw Exception('Failed to submit review');
    }
  }
}
