import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:geocoding/geocoding.dart';
import 'package:municipal_tracker_msunduzi/code/MapTools/location_controller.dart';

import 'package:municipal_tracker_msunduzi/code/DisplayPages/display_info.dart';
import 'map_user_badge.dart';


const LatLng SOURCE_LOCATION = LatLng(-29.601505328570788, 30.379442518631805);


class MapScreenProp extends StatefulWidget {
  const MapScreenProp({Key? key, required this.propAddress, required this.propAccNumber}) : super(key: key);

  final String propAccNumber;
  final String propAddress;

  @override
  State<MapScreenProp> createState() => _MapScreenPropState();
}

class _MapScreenPropState extends State<MapScreenProp> {
  late CameraPosition _cameraPosition;
  late LatLng currentLocation;
  late LatLng addressLocation;
  late bool _isLoading;

  String location ='Null, Press Button';
  String Address = 'search';

  @override
  void initState(){

    ///This is the circular loading widget in this future.delayed call
    _isLoading = true;
    Future.delayed(const Duration(seconds: 5),(){
      setState(() {
        _isLoading = false;
      });
    });

    //Allows user's location to be captured while using the map
    locationAllow();

    super.initState();

    //Set camera position based on db address given
    this.addressConvert();
    //Set up initial locations
    this.setInitialLocation();
    //Set up the marker icons
    this.setSourceAndDestinationMarkerIcons();

    // city all position for camera default (target: LatLng(-29.601505328570788, 30.379442518631805), zoom: 16);
    //_cameraPosition = CameraPosition(target: currentLocation, zoom: 16);
  }

  late GoogleMapController _mapController;

  late BitmapDescriptor sourceIcon;
  Set<Marker> _markers = Set<Marker>();

  ///This checks current users location
  Future<void> locationAllow() async {
    Position position = await _getGeoLocationPosition();
    location ='Lat: ${position.latitude} , Long: ${position.longitude}';
    GetAddressFromLatLong(position);
    if(_getGeoLocationPosition.isBlank == false){

    }
  }

  Future<Position> _getGeoLocationPosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {

        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> GetAddressFromLatLong(Position position)async {
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    print(placemarks);
    Placemark place = placemarks[0];
    Address = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
  }
  ///End of current user location check

  void setSourceAndDestinationMarkerIcons() async{
    sourceIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.0),
        'assets/images/location/source_pin_android.png'
    );
  }

  void addressConvert() async {
    ///Location change here for address conversion into lat long
    String address = widget.propAddress;
    //List<Location> locations = await Geocoding.google(apiKey: "AIzaSyB3p4M0JwkbBauV_5_dIHxWNpk8PSqmmU0").searchByAddress(address);

    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        Location location = locations.first;

        double latitude = location.latitude;
        double longitude = location.longitude;

        addressLocation = LatLng(latitude, longitude);

        showPinOnMap();
      }

      _cameraPosition = CameraPosition(target: addressLocation, zoom: 16);
    } catch (e) {
      addressLocation = LatLng(-29.601505328570788, 30.379442518631805);

      _cameraPosition = CameraPosition(target: addressLocation, zoom: 16);

      showPinOnMap();

      Fluttertoast.showToast(
          msg: "Address not found! Default map location City Hall!",
          gravity: ToastGravity.CENTER);
    }
    print('$addressLocation this is the change');
  }

  void setAddressLocation() async {
    addressLocation = LatLng(
        SOURCE_LOCATION.latitude,
        SOURCE_LOCATION.longitude
    );
  }

  void setInitialLocation() async{
    currentLocation = LatLng(
        SOURCE_LOCATION.latitude,
        SOURCE_LOCATION.longitude
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocationController>(
        builder: (locationController) {
          return Scaffold(
              appBar: AppBar(
                title: const Text('Map View',style: TextStyle(color: Colors.white),),
                iconTheme: const IconThemeData(color: Colors.white),
                backgroundColor: Colors.green[700],
              ),
              body: Stack(
                children: <Widget>[

                  ///loading page component starts here
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(),)
                      : Expanded(
                        ///everything put into this expanded widget will be loading for the amount of seconds established in the initState()
                        child: GoogleMap(
                            myLocationEnabled: true,
                            compassEnabled: false,
                            tiltGesturesEnabled: false,
                            markers: _markers,
                            mapType: MapType.normal,

                            onMapCreated: (GoogleMapController mapController) {
                              addressConvert();
                              _mapController = mapController;
                            },
                            initialCameraPosition: _cameraPosition
                      ),
                  ),

                  ///Positioned widget is for searching an address but will not be used in view mode
                  // Positioned(
                  //     top: 100,
                  //     left: 25, right: 25,
                  //     child: GestureDetector(
                  //
                  //       onTap: () => Get.dialog(LocationSearchDialogue(mapController: _mapController)),
                  //
                  //       child: Container(
                  //         height: 50,
                  //         padding: EdgeInsets.symmetric(horizontal: 5),
                  //         decoration: BoxDecoration(color: Theme
                  //             .of(context)
                  //             .cardColor,
                  //             borderRadius: BorderRadius.circular(10)),
                  //         child: Row(children: [
                  //           Icon(Icons.location_on, size: 25, color: Colors.green[700],
                  //           ),
                  //           SizedBox(width: 5,),
                  //           Expanded(
                  //             child: Text(
                  //               '${locationController.pickPlaceMark.name ?? ''}'
                  //                   '${locationController.pickPlaceMark.locality ?? ''}'
                  //                   '${locationController.pickPlaceMark.postalCode ?? ''}'
                  //                   '${locationController.pickPlaceMark.country ?? ''}',
                  //               style: TextStyle(fontSize: 20),
                  //               maxLines: 1, overflow: TextOverflow.ellipsis,
                  //             ),
                  //           ),
                  //           SizedBox(width: 10),
                  //           Icon(Icons.search, size: 25, color: Theme.of(context).textTheme.bodyText1!.color),
                  //         ],),
                  //       ),
                  //     )),

                  const SizedBox(height: 10,),

                  ///Positioned badge that shows account number and address shown on the pin
                  Positioned(
                      top: 10, left: 0, right: 0,
                      child: MapUserBadge(locationGivenGet: widget.propAddress, accountNumberGet: widget.propAccNumber,
                      )
                  ),
                ],
              )
          );
        });
  }

  void showPinOnMap(){
    addressConvert;

    setState(() {
      _markers.add(Marker(
        markerId: const MarkerId('sourcePin'),
        position: addressLocation,
        icon: sourceIcon,
      ));
    });
  }

}
