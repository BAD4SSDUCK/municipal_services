import 'dart:async';

import 'package:flutter/material.dart';

import 'package:municipal_track/code/MapTools/location_controller.dart';
import 'package:municipal_track/code/MapTools/location_search_dialogue.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';

import 'map_user_badge.dart';

///The lat,long information from the DB
const LatLng SOURCE_LOCATION = LatLng(-29.601505328570788, 30.379442518631805);
const LatLng DEST_LOCATION = LatLng(-29.562115515970493, 30.404004300313627);

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Completer<GoogleMapController> _controller = Completer();
  late BitmapDescriptor sourceIcon;
  late BitmapDescriptor destinationIcon;
  Set<Marker> _markers = Set<Marker>();

  late LatLng currentLocation;
  late LatLng destinationLocation;
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
      'assets/images/location/source_pin.png'
    );
    destinationIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.0),
        'assets/images/location/destination_pin.png'
    );
  }

  void setInitialLocation(){
    currentLocation = LatLng(
        SOURCE_LOCATION.latitude,
        SOURCE_LOCATION.longitude
    );
    destinationLocation = LatLng(
        DEST_LOCATION.latitude,
        DEST_LOCATION.longitude
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
          const Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: MapUserBadge())
        ],
      ),
    );
  }
  void showPinsOnMap(){
    setState(() {
      _markers.add(Marker(
          markerId: const MarkerId('sourcePin'),
          position: currentLocation,
          icon: sourceIcon
      ));

      _markers.add(Marker(
          markerId: const MarkerId('destinationPin'),
          position: destinationLocation,
          icon: destinationIcon
      ));
    });
  }
}