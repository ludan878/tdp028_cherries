import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For saving the last location
import 'post_view.dart';
import 'dart:math'; // For cos function

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
      // Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Location services are disabled. Please enable them.'),
          ),
        );
        return;
      }

      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permission is denied. Please allow location access.'),
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are permanently denied, open app settings
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Location permissions are permanently denied. Enable them in app settings.'),
          ),
        );
        await Geolocator.openAppSettings();
        return;
      }

      // If all permissions are granted, get the current position
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while fetching location.'),
        ),
      );
    }
  }

  Future<void> _fetchReviews(LatLng location) async {
    try {
      setState(() {
        _isLoading = true;
      });

      const double earthRadius = 6371e3; // Earth's radius in meters
      final double lat = location.latitude;
      final double lng = location.longitude;

      // Calculate bounding box
      final double radiusInDegrees = _filterRadius / earthRadius * (180 / pi);
      final double latMin = lat - radiusInDegrees;
      final double latMax = lat + radiusInDegrees;
      final double lngMin = lng - radiusInDegrees / cos(lat * pi / 180);
      final double lngMax = lng + radiusInDegrees / cos(lat * pi / 180);

      // Query Firestore for documents within the bounding box
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('latitude', isGreaterThanOrEqualTo: latMin)
          .where('latitude', isLessThanOrEqualTo: latMax)
          .where('longitude', isGreaterThanOrEqualTo: lngMin)
          .where('longitude', isLessThanOrEqualTo: lngMax)
          .get();

      final List<Map<String, dynamic>> reviews = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        if (data.containsKey('latitude') && data.containsKey('longitude')) {
          final double reviewLat = data['latitude'];
          final double reviewLng = data['longitude'];

          // Further filter reviews by distance
          final double distance = Geolocator.distanceBetween(
            location.latitude,
            location.longitude,
            reviewLat,
            reviewLng,
          );

          // Only add reviews within the filter radius
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
              // Slider for selecting the filter radius
              SliderTheme(
                data: SliderThemeData(
                  tickMarkShape: SliderTickMarkShape.noTickMark,
                  thumbColor: Colors.amber,
                  activeTrackColor: Colors.amber,
                  inactiveTrackColor: Colors.grey[800],
                  overlayColor: Colors.amber.withAlpha(32),
                  valueIndicatorColor: Colors.amber,
                  valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                ),
                child: Slider(
                  value: _filterRadius,
                  min: 1000,
                  max: 50000,
                  divisions: 499,
                  label: '${(_filterRadius / 1000).toStringAsFixed(1)} km',
                  onChanged: (value) {
                    setState(() {
                      _filterRadius = value;
                      if (_selectedLocation != null) {
                        _fetchReviews(_selectedLocation!);
                      } else if (_currentLocation != null) {
                        _fetchReviews(_currentLocation!);
                      } else {
                        print('No location is available.');
                      }
                    });
                  },
                ),
              ),
              Text(
                '${(_filterRadius / 1000).toStringAsFixed(1)} km',
                style: const TextStyle(color: Colors.white),
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
                          crossAxisCount: 1,
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
                                StarRating(rating: rating), // Updated here
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

class StarRating extends StatelessWidget {
  final double rating;

  const StarRating({Key? key, required this.rating}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int fullStars = rating.floor();
    double fractionalStar = rating - fullStars;
    bool hasPartialStar = fractionalStar > 0;
    int emptyStars = 5 - fullStars - (hasPartialStar ? 1 : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < fullStars; i++)
          const Icon(Icons.star, color: Colors.amber, size: 16),
        if (hasPartialStar)
          Stack(
            children: [
              const Icon(Icons.star_border, color: Colors.amber, size: 16),
              ClipRect(
                clipper: _StarClipper(fractionalStar),
                child: const Icon(Icons.star, color: Colors.amber, size: 16),
              ),
            ],
          ),
        for (int i = 0; i < emptyStars; i++)
          const Icon(Icons.star_border, color: Colors.amber, size: 16),
      ],
    );
  }
}

class _StarClipper extends CustomClipper<Rect> {
  final double fraction;

  _StarClipper(this.fraction);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * fraction, size.height);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) {
    return true;
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
