import 'package:get/get.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:municipal_services/code/MapTools/location_service.dart';

class LocationController extends GetxController{
  final Placemark _pickPlaceMark = Placemark();
  Placemark get pickPlaceMark=>_pickPlaceMark;

  List<Prediction> _predictionList = [];

  Future<List<Prediction>> searchLocation(BuildContext context, String text) async {
    if(text != null && text.isNotEmpty){
      http.Response response = await getLocationData(text);
      var data = jsonDecode(response.body.toString());
      print("my status is "+data["status"]);
      if(data['status'] == 'OK'){
        _predictionList = [];
        data['predictions'].forEach((prediction)
        => _predictionList.add(Prediction.fromJson(prediction)));
      } else {
        // ApiChecker.checkApi(response);
      }
    }
    return _predictionList;
  }

  // Define variables to store the location data
  late String _placeId;
  late String _description;
  late GoogleMapController _mapController;

  // Define getters to access the location data
  String get placeId => _placeId;
  String get description => _description;
  GoogleMapController get mapController => _mapController;

  void setLocation(String placeId, String description, GoogleMapController mapController) {
    _placeId = placeId;
    _description = description;
    _mapController = mapController;

  }

}