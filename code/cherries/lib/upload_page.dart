import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class NearbyRestaurantsService {
  final GoogleMapsPlaces _places;

  NearbyRestaurantsService(String apiKey)
      : _places = GoogleMapsPlaces(apiKey: apiKey);

  Future<List<PlacesSearchResult>> fetchNearbyRestaurants(
      double latitude, double longitude) async {
    try {
      PlacesSearchResponse response = await _places.searchNearbyWithRadius(
        Location(lat: latitude, lng: longitude),
        1500, // 1.5 km radius
        type: 'restaurant',
      );

      if (response.isOkay) {
        return response.results;
      } else {
        throw Exception('Places API error: ${response.errorMessage}');
      }
    } catch (e) {
      print('Error fetching restaurants: $e');
      return [];
    }
  }
}

class UploadingPage extends StatefulWidget {
  final String userId;

  const UploadingPage({super.key, required this.userId});

  @override
  State<UploadingPage> createState() => _UploadingPageState();
}

class _UploadingPageState extends State<UploadingPage> {
  final NearbyRestaurantsService _restaurantsService = NearbyRestaurantsService(
      'AIzaSyBQ4quOwrSzTwoBoJF4zt3AbLHoYm2V2GA'); // Replace with your API Key
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  File? _selectedImage;
  String _selectedRestaurant = '';
  double? _restaurantLatitude; // To store restaurant latitude
  double? _restaurantLongitude; // To store restaurant longitude
  double _rating = 3.0; // Default rating
  bool _isLoadingRestaurants = false;
  bool _isSubmitting = false;
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Function to fetch nearby restaurants
  Future<void> _findNearbyRestaurants() async {
    setState(() {
      _isLoadingRestaurants = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        setState(() {
          _isLoadingRestaurants = false;
        });
        return;
      }

      // Request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
          setState(() {
            _isLoadingRestaurants = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Location permissions are permanently denied.')),
        );
        setState(() {
          _isLoadingRestaurants = false;
        });
        return;
      }

      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('User location: ${position.latitude}, ${position.longitude}');

      // Fetch restaurants from Google Places API
      final results = await _restaurantsService.fetchNearbyRestaurants(
        position.latitude,
        position.longitude,
      );

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No restaurants found nearby.')),
        );
      } else {
        print('Found ${results.length} restaurants');
        _showRestaurantDialog(results);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching nearby restaurants: $e')),
      );
    } finally {
      setState(() {
        _isLoadingRestaurants = false;
      });
    }
  }

  // Show a dialog to select a restaurant
  void _showRestaurantDialog(List<PlacesSearchResult> restaurants) {
    if (restaurants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No restaurants found nearby.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select a Restaurant'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.5,
            child: ListView.builder(
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                final restaurant = restaurants[index];
                final restaurantName = restaurant.name ?? 'Unknown Restaurant';
                final restaurantAddress =
                    restaurant.vicinity ?? 'No address available';
                final restaurantLocation = restaurant.geometry?.location;

                return ListTile(
                  title: Text(
                    restaurantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    restaurantAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    setState(() {
                      _selectedRestaurant = restaurantName;
                      _restaurantLatitude = restaurantLocation?.lat ?? 0.0;
                      _restaurantLongitude = restaurantLocation?.lng ?? 0.0;
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Function to pick an image (gallery or camera)
  Future<void> _pickImage() async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        content: const Text(
            'Would you like to take a photo or choose from the gallery?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
            child: const Text('Gallery'),
          ),
        ],
      ),
    );

    if (source != null) {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    }
  }

  // Function to submit the review
  Future<void> _submitReview() async {
    if (_selectedImage == null ||
        _selectedRestaurant.isEmpty ||
        _descriptionController.text.isEmpty ||
        _restaurantLatitude == null ||
        _restaurantLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please complete all fields before submitting.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Upload image to ImgBB
      final String imageUrl = await _uploadImageToImgBB(_selectedImage!);

      // Create review in Firestore
      final String reviewId = _firestore.collection('reviews').doc().id;
      final reviewData = {
        "reviewId": reviewId,
        "userId": widget.userId,
        "restaurantName": _selectedRestaurant,
        "latitude": _restaurantLatitude!,
        "longitude": _restaurantLongitude!,
        "description": _descriptionController.text,
        "rating": _rating,
        "imageUrl": imageUrl,
        "timestamp": FieldValue.serverTimestamp(),
      };

      await _firestore.collection('reviews').doc(reviewId).set(reviewData);

      // Add review ID to user's document
      await _firestore.collection('users').doc(widget.userId).update({
        "reviews": FieldValue.arrayUnion([reviewId]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully!')),
      );

      // Reset the form
      setState(() {
        _selectedImage = null;
        _selectedRestaurant = '';
        _restaurantLatitude = null;
        _restaurantLongitude = null;
        _rating = 3.0;
        _descriptionController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Upload image to ImgBB
  Future<String> _uploadImageToImgBB(File imageFile) async {
    const String apiKey = '9cdc111b99442ca827e2af1980558e08';
    try {
      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: {
          "key": apiKey,
          "image": base64Image,
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['data']['display_url'];
      } else {
        throw Exception('Failed to upload image: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title:
            const Text('Upload Review', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Picker
            Center(
              child: _selectedImage != null
                  ? Image.file(
                      _selectedImage!,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    )
                  : const Text('No image selected.'),
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Upload Image'),
              ),
            ),
            const SizedBox(height: 20),

            // Restaurant Selection
            const Text(
              'Restaurant Name',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedRestaurant.isNotEmpty
                        ? 'Selected: $_selectedRestaurant'
                        : 'No restaurant selected.',
                    style: const TextStyle(fontSize: 16, color: Colors.white38),
                  ),
                ),
                if (_isLoadingRestaurants)
                  const CircularProgressIndicator()
                else
                  IconButton(
                    onPressed: _findNearbyRestaurants,
                    icon: const Icon(Icons.search),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Description Field
            const Text(
              'Description',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70),
            ),
            const SizedBox(height: 10),
            TextField(
              style: const TextStyle(color: Colors.white),
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe your experience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Rating Slider
            const Text(
              'Rating',
              style: TextStyle(
                  fontSize: 18, color: Color.fromARGB(255, 255, 226, 130)),
            ),
            Slider(
              value: _rating,
              min: 1.0,
              max: 5.0,
              divisions: 40,
              thumbColor: Color.fromARGB(255, 255, 215, 86),
              activeColor: Color.fromARGB(255, 162, 124, 0),
              label: _rating.toStringAsFixed(1),
              // Rating Text Color
              inactiveColor: Colors.white38,
              onChanged: (value) {
                setState(() {
                  _rating = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // Submit Button
            Center(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
