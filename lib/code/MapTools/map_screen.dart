import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';

import 'package:municipal_track/code/MapTools/location_controller.dart';

import '../DisplayPages/display_info_edit.dart';
import 'location_search_dialogue.dart';
import 'map_user_badge.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late CameraPosition _cameraPosition;
  @override
  void initState(){
    super.initState();
    _cameraPosition = CameraPosition(target: LatLng(-29.601505328570788, 30.379442518631805), zoom: 16);
  }

  late GoogleMapController _mapController;



  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocationController>(
        builder: (locationController) {
          return Scaffold(
              appBar: AppBar(
                title: const Text('Map View'),
                backgroundColor: Colors.green[700],
              ),
              body: Stack(
                children: <Widget>[
                  GoogleMap(
                      onMapCreated: (GoogleMapController mapController) {
                        _mapController = mapController;
                      },
                      initialCameraPosition: _cameraPosition
                  ),
                  Positioned(
                      top: 100,
                      left: 25, right: 25,
                      child: GestureDetector(

                        onTap: () => Get.dialog(LocationSearchDialogue(mapController: _mapController)),

                        child: Container(
                          height: 50,
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(color: Theme
                              .of(context)
                              .cardColor,
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(children: [
                            Icon(Icons.location_on, size: 25, color: Colors.green[700],
                            ),
                            SizedBox(width: 5,),
                            Expanded(
                              child: Text(
                                '${locationController.pickPlaceMark.name ?? ''}'
                                    '${locationController.pickPlaceMark.locality ?? ''}'
                                    '${locationController.pickPlaceMark.postalCode ?? ''}'
                                    '${locationController.pickPlaceMark.country ?? ''}',
                                style: TextStyle(fontSize: 20),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.search, size: 25, color: Theme.of(context).textTheme.bodyText1!.color),
                          ],),
                        ),
                      )),

                  SizedBox(height: 10,),
                  Positioned(
                      top: 10, left: 0, right: 0,
                      child: MapUserBadge(
                        locationGiven: locationGiven, accountNumber: accountNumber,)),
                ],
              )
          );
        });
  }

  // void showPinOnMap(){
  //   setState(() {
  //     _markers.add(Marker(
  //       markerId: const MarkerId('sourcePin'),
  //       position: currentLocation,
  //       icon: sourceIcon,
  //     ));
  //   });
  // }

}
