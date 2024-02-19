import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:get/get.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';

import 'package:municipal_tracker_msunduzi/code/MapTools/location_controller.dart';

class LocationSearchDialogue extends StatelessWidget {
  final GoogleMapController? mapController;
  const LocationSearchDialogue({super.key, required this.mapController});

  @override
  Widget build(BuildContext context) {
    final TextEditingController _controller = TextEditingController();

    LatLng newlatlang = LatLng(-29.601505328570788, 30.379442518631805);

    void addressConvert(String address) async {
      ///Location change here for address conversion into lat long
      //String address = _propertiesData.properties.address[0];

      try {
        List<geo.Location> locations = await locationFromAddress(address);

        if (locations.isNotEmpty) {
          geo.Location location = locations.first;

          double latitude = location.latitude;
          double longitude = location.longitude;

          newlatlang = LatLng(latitude, longitude);
        }
        mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
                CameraPosition(target: newlatlang, zoom: 16)
              //17 is new zoom level
            )
        );
        //move position of map camera to new location

      } catch(e) {
        Fluttertoast.showToast(msg: "The location map position was not found", gravity: ToastGravity.CENTER);
      }
    }

    return Container(
      margin: EdgeInsets.only(top : 110),
      padding: EdgeInsets.all(6),
      alignment: Alignment.topCenter,
      child: Material(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        child: SizedBox(width: 320, height: 50, child: TypeAheadField(

          suggestionsCallback: (pattern) async {
            return await Get.find<LocationController>().searchLocation(context, pattern);
          },
          itemBuilder: (context, Prediction suggestion) {
            return Padding(
              padding: EdgeInsets.all(10),
              child: Row(children: [
                Icon(Icons.location_on),
                Expanded(
                  child: Text(suggestion.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 20,
                  )),
                ),
              ]),
            );
          },

          onSelected: (Prediction suggestion) {
            print("Location selected is "+suggestion.description!);

            addressConvert(suggestion.description!);

            Get.find<LocationController>().setLocation(suggestion.placeId!, suggestion.description!, mapController!);
            Get.back();
          },

        )),
      ),
    );
  }
}
