import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import '../DisplayPages/display_info.dart';
import 'map_user_badge.dart';

///This is the old map page, currently using the mapPage

///given latLng is the initial location
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
  late LatLng addressLocation;
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

    this.setBadgeInformation();
  }

  void setBadgeInformation(){
    if(locationGiven == ' '){
      locationGiven = locationGivenW;
      if(locationGivenW == ' '){
        locationGiven = 'Chief Albert Luthuli St, Pietermaritzburg';
      }
    }
    if(accountNumber == ' '){
      accountNumber = accountNumberW;
    }
  }

  void setSourceAndDestinationMarkerIcons() async{
    sourceIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 2.0),
      'assets/images/location/source_pin_android.png'
    );
  }

  Future<void> setAddressLocation() async {
    ///Add location change here for address conversion into lat long

    List<Placemark> placemarks = await placemarkFromCoordinates(SOURCE_LOCATION.latitude, SOURCE_LOCATION.longitude);
    String placeName = "${placemarks.first.administrativeArea}, ${placemarks.first.street}";

    print(placeName);
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //     content: Text(placeName)));

    addressLocation = LatLng(
        SOURCE_LOCATION.latitude,
        SOURCE_LOCATION.longitude
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
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);

                showPinOnMap();
              },
            ),
          ),
          Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: MapUserBadge(
                locationGiven: locationGiven, accountNumber: accountNumber,
              )),

        ],
      ),
    );
  }

  void showPinOnMap(){
    setState(() {
      _markers.add(Marker(
          markerId: const MarkerId('sourcePin'),
          position: currentLocation,
          icon: sourceIcon,
      ));
    });
  }

}