import 'dart:convert';
import 'package:http/http.dart' as http;

Future<http.Response> getLocationData(String text) async {
  http.Response response;

  ///Using the same uri url from a tutorial video, will need to check if that api works or is outdated
  response = await http.get(
    Uri.parse("https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$text&key=AIzaSyB3p4M0JwkbBauV_5_dIHxWNpk8PSqmmU0"),
    headers: {"Content-Type": "application/json"},);

  print(jsonDecode(response.body));
  return response;

}