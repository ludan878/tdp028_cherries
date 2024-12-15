import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For saving the last location
import 'post_view.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  double _filterRadius = 5000; // Default radius: 5 km

  @override
  void initState() {
    super.initState();
    _loadLastLocation();
  }

  Future<void> _loadLastLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('last_lat');
      final lng = prefs.getDouble('last_lng');

      if (lat != null && lng != null) {
        _selectedLocation = LatLng(lat, lng);
      } else {
        await _getCurrentLocation();
      }

      await _fetchReviews(_selectedLocation!);
    } catch (e) {
      print('Error loading last location: $e');
      await _getCurrentLocation();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLastLocation(LatLng location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_lat', location.latitude);
    await prefs.setDouble('last_lng', location.longitude);
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _selectedLocation = _currentLocation;
      });

      await _saveLastLocation(_currentLocation!);
      await _fetchReviews(_currentLocation!);
    } catch (e) {
      print('Error fetching current location: $e');
    }
  }

  Future<void> _fetchReviews(LatLng location) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final querySnapshot = await _firestore.collection('reviews').get();
      final List<Map<String, dynamic>> reviews = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        if (data.containsKey('restaurantLocation') &&
            data['restaurantLocation'] is GeoPoint) {
          final GeoPoint restaurantLocation = data['restaurantLocation'];

          final double reviewLat = restaurantLocation.latitude;
          final double reviewLng = restaurantLocation.longitude;

          // Calculate distance
          final distance = Geolocator.distanceBetween(
            location.latitude,
            location.longitude,
            reviewLat,
            reviewLng,
          );

          // Add review if it's within the filter radius
          if (distance <= _filterRadius) {
            reviews.add({
              'reviewId': doc.id,
              ...data,
              'distance': distance, // Include distance for sorting
            });
          }
        }
      }

      // Sort reviews by distance
      reviews
          .sort((a, b) => (a['distance'] as double).compareTo(b['distance']));

      setState(() {
        _reviews = reviews;
      });
    } catch (e) {
      print('Error fetching reviews: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectLocation() async {
    LatLng? pickedLocation = await showDialog<LatLng>(
      context: context,
      builder: (context) => LocationPickerDialog(
        initialLocation: _selectedLocation ?? _currentLocation,
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        _selectedLocation = pickedLocation;
      });
      await _saveLastLocation(_selectedLocation!);
      await _fetchReviews(_selectedLocation!);
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedLocation = _currentLocation;
      _filterRadius = 5000; // Reset radius to default (5 km)
    });
    if (_currentLocation != null) {
      _fetchReviews(_currentLocation!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Discover',
          style: TextStyle(
              color: Colors.white,
              fontFamily: 'Mono',
              fontSize: 24,
              fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                  ),
                  icon: const Icon(Icons.my_location, color: Colors.white),
                  label: const Text('Current Location',
                      style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton.icon(
                  onPressed: _selectLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                  ),
                  icon: const Icon(Icons.location_on, color: Colors.white),
                  label: const Text('Pick Location',
                      style: TextStyle(color: Colors.white)),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _resetFilters,
                  tooltip: 'Reset Filters',
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Radius:', style: TextStyle(color: Colors.white)),
              DropdownButton<double>(
                value: _filterRadius,
                dropdownColor: Colors.grey[900],
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(
                    value: 1000,
                    child: Text('1 km'),
                  ),
                  DropdownMenuItem(
                    value: 5000,
                    child: Text('5 km'),
                  ),
                  DropdownMenuItem(
                    value: 10000,
                    child: Text('10 km'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _filterRadius = value;
                    });
                    _fetchReviews(_selectedLocation!);
                  }
                },
              ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _reviews.isEmpty
                    ? const Center(
                        child: Text(
                          'No reviews found nearby.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(10.0),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _reviews.length,
                        itemBuilder: (context, index) {
                          final review = _reviews[index];
                          final imageUrl = review['imageUrl'] ?? '';
                          final restaurantName =
                              review['restaurantName'] ?? 'Unknown';
                          final rating = review['rating'] ?? 0.0;
                          final distance = review['distance'] ?? 0.0;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PostView(
                                    postId: review['reviewId'],
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10.0),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.star,
                                        color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${(distance / 1000).toStringAsFixed(1)} km away',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class LocationPickerDialog extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerDialog({super.key, this.initialLocation});

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? const LatLng(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text(
        'Select Location',
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _selectedLocation!,
            zoom: 14,
          ),
          onTap: (position) {
            setState(() {
              _selectedLocation = position;
            });
          },
          markers: _selectedLocation != null
              ? {
                  Marker(
                    markerId: const MarkerId('selected_location'),
                    position: _selectedLocation!,
                  )
                }
              : {},
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selectedLocation),
          child: const Text('Select', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
