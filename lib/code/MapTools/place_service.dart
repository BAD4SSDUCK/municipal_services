import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class Place {
  String streetNumber;
  String street;
  String city;
  String zipCode;

  Place({
    required this.streetNumber,
    required this.street,
    required this.city,
    required this.zipCode,
  });

  @override
  String toString() {
    return 'Place(streetNumber: $streetNumber, street: $street, city: $city, zipCode: $zipCode)';
  }
}

// For storing our result
class Suggestion {
  final String placeId;
  final String description;

  Suggestion(this.placeId, this.description);

  @override
  String toString() {
    return 'Suggestion(description: $description, placeId: $placeId)';
  }
}

class PlaceApiProvider {
  final client = Client();

  PlaceApiProvider(this.sessionToken);

  final sessionToken;

  static final String androidKey = 'AIzaSyCsOGfD-agV8u68pCfeCManNNoSs4csIbY';
  static final String webKey = 'AIzaSyCsOGfD-agV8u68pCfeCManNNoSs4csIbY';
  static final String iosKey = 'YOUR_API_KEY_HERE';
  final apiKey = Platform.isAndroid ? androidKey : webKey;

  Future<List<Suggestion>> fetchSuggestions(String input, String lang) async {
    final request =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&types=address&language=$lang&components=country:ch&key=$apiKey&sessiontoken=$sessionToken';
    final response = await client.get(request as Uri);

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        // compose suggestions in a list
        return result['predictions']
            .map<Suggestion>((p) => Suggestion(p['place_id'], p['description']))
            .toList();
      }
      if (result['status'] == 'ZERO_RESULTS') {
        return [];
      }
      throw Exception(result['error_message']);
    } else {
      throw Exception('Failed to fetch suggestion');
    }
  }

  static Future<List<Suggestion>> getSuggestions(String query) async {
    // Make an API call or perform a search to get address suggestions
    // Replace the code below with your actual implementation

    // For example, if you're using Google Places API
    // You can use the http package to make API calls

    // Make sure to handle errors and exceptions appropriately
    // Here, we're using a dummy response for demonstration purposes

    // Replace with your actual API endpoint and API key
    final apiKey = 'AIzaSyCsOGfD-agV8u68pCfeCManNNoSs4csIbY';
    final endpoint = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';

    final response = await http.get(
      Uri.parse('$endpoint?input=$query&key=$apiKey'),
    );

    if (response.statusCode == 200) {
      // Parse the response and return a list of suggestions
      // Replace the code below with your actual parsing logic

      final List<Suggestion> suggestions = List.generate(5, (index) {
        return Suggestion('Suggestion $index','');
      });

      return suggestions;
    } else {
      // Handle error cases
      throw Exception('Failed to load suggestions');
    }
  }

  Future<Place> getPlaceDetailFromId(String placeId) async {
    final Uri request =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=address_component&key=$apiKey&sessiontoken=$sessionToken' as Uri;
    final response = await client.get(request);

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        final components =
        result['result']['address_components'] as List<dynamic>;
        // build result
        final place = Place(streetNumber: '', street: '', city: '', zipCode: '');
        components.forEach((c) {
          final List type = c['types'];
          if (type.contains('street_number')) {
            place.streetNumber = c['long_name'];
          }
          if (type.contains('route')) {
            place.street = c['long_name'];
          }
          if (type.contains('locality')) {
            place.city = c['long_name'];
          }
          if (type.contains('postal_code')) {
            place.zipCode = c['long_name'];
          }
        });
        return place;
      }
      throw Exception(result['error_message']);
    } else {
      throw Exception('Failed to fetch suggestion');
    }
  }
}