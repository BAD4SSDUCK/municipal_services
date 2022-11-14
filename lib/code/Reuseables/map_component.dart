import 'dart:async';

import 'package:flutter/material.dart';

import 'package:municipal_track/code/MapTools/location_controller.dart';
import 'package:municipal_track/code/MapTools/location_search_dialogue.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';

const LatLng SOURCE_LOCATION = LatLng(-29.601505328570788, 30.379442518631805);
const LatLng DEST_LOCATION = LatLng(-29.601505328570788, 30.379442518631805);

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

  @override
  void initState(){
    super.initState();

    //Set up initial locations
    this.setInitialLocation();

    //Set up the marker icons
  }

  void setSourceAndDestinationMarkerIcons() async{
    sourceIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 2.0),
      'image/'
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
    return Scaffold(
      body: Container(
        child: Center(
          child: Text('Map Page!'),
        ),
      ),
    );
  }
}
