import 'package:google_maps_webservice/places.dart';
import 'package:geolocator/geolocator.dart';

class NearbyRestaurantsService {
  final GoogleMapsPlaces _places;

  NearbyRestaurantsService(String apiKey)
      : _places = GoogleMapsPlaces(apiKey: apiKey);

  Future<List<PlacesSearchResult>> fetchNearbyRestaurants() async {
    try {
      // Get the user's current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Call the Google Places API
      PlacesSearchResponse response = await _places.searchNearbyWithRadius(
        Location(lat: position.latitude, lng: position.longitude),
        1500, // Radius in meters
        type: "restaurant",
      );

      if (response.isOkay) {
        return response.results;
      } else {
        throw Exception(
            "Failed to fetch nearby restaurants: ${response.errorMessage}");
      }
    } catch (e) {
      print("Error fetching nearby restaurants: $e");
      return [];
    }
  }
}
