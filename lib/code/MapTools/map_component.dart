import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:municipal_track/code/DisplayPages/display_info_edit.dart';
import 'map_user_badge.dart';

///TODO The lat,long information from the DB per user when selected account number that has an address. The address must be converted to lat long in order to show on map
///given latLng is initial location
const LatLng SOURCE_LOCATION = LatLng(-29.601505328570788, 30.379442518631805);

class MapPage extends StatefulWidget {
  const MapPage({
    Key? key,

  }) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Completer<GoogleMapController> _controller = Completer();
  late BitmapDescriptor sourceIcon;
  Set<Marker> _markers = Set<Marker>();

  late LatLng currentLocation;
  late double CAMERA_ZOOM = 16;
  late double CAMERA_TILT = 50;
  late double CAMERA_BEARING = 0;

  @override
  void initState(){
    super.initState();

    //Set up initial locations
    this.setInitialLocation();

    //Set up the marker icons
    this.setSourceAndDestinationMarkerIcons();
  }

  void setSourceAndDestinationMarkerIcons() async{
    sourceIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 2.0),
      'assets/images/location/source_pin_android.png'
    );
  }

  void setInitialLocation(){
    currentLocation = LatLng(
        SOURCE_LOCATION.latitude,
        SOURCE_LOCATION.longitude
    );
  }

  @override
  Widget build(BuildContext context) {

    CameraPosition initialCameraPosition = CameraPosition(
        zoom: CAMERA_ZOOM,
        tilt: CAMERA_TILT,
        bearing: CAMERA_BEARING,
        target: SOURCE_LOCATION
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maps Location View'),
        backgroundColor: Colors.green[700],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              myLocationEnabled: true,
              compassEnabled: false,
              tiltGesturesEnabled: false,
              markers: _markers,
              mapType: MapType.normal,
              initialCameraPosition: initialCameraPosition,
              onMapCreated: (GoogleMapController controller){
                _controller.complete(controller);

                showPinsOnMap();
            },
          ),
          ),
           Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: MapUserBadge(locationGiven: locationGiven, accountNumber: accountNumber,))
        ],
      ),
    );
  }

  void showPinsOnMap(){
    setState(() {
      _markers.add(Marker(
          markerId: const MarkerId('sourcePin'),
          position: currentLocation,
          icon: sourceIcon,
      ));
    });
  }



}