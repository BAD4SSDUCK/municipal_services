import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Future<http.Response> getLocationData(String text) async {
//   http.Response response;
//
//   ///Using the same uri url from a tutorial video, will need to check if that api works or is outdated
//   response = await http.get(
//     Uri.parse("https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$text&key=AIzaSyCsOGfD-agV8u68pCfeCManNNoSs4csIbY&libraries=maps,drawing,visualization,places,routes&callback=initMap"),
//     headers: {"Content-Type": "application/json"},);
//
//   print(jsonDecode(response.body));
//   return response;
//
// }
Future<http.Response> getLocationData(String text) async {
  if (kIsWeb) {
    return http.Response(
      jsonEncode({"predictions": []}),
      200,
      headers: {"content-type": "application/json"},
    );
  }

  // TODO: implement mobile autocomplete or return the same stub:
  return http.Response(
    jsonEncode({"predictions": []}),
    200,
    headers: {"content-type": "application/json"},
  );
}