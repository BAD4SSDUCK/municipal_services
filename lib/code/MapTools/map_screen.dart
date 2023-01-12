import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:geocoding/geocoding.dart';
import 'package:municipal_track/code/MapTools/location_controller.dart';

import '../DisplayPages/display_info.dart';
import 'map_user_badge.dart';


const LatLng SOURCE_LOCATION = LatLng(-29.601505328570788, 30.379442518631805);


class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late CameraPosition _cameraPosition;
  late LatLng currentLocation;
  late LatLng addressLocation;
  late bool _isLoading;

  @override
  void initState(){

    ///This is the circular loading widget in this future.delayed call
    _isLoading = true;
    Future.delayed(const Duration(seconds: 5),(){
      setState(() {
        _isLoading = false;
      });
    });

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



  void setSourceAndDestinationMarkerIcons() async{
    sourceIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.0),
        'assets/images/location/source_pin_android.png'
    );
  }

  void addressConvert() async {
    ///Location change here for address conversion into lat long
    String address = locationGiven;

    //List<Location> locations = await Geocoding.google(apiKey: "AIzaSyB3p4M0JwkbBauV_5_dIHxWNpk8PSqmmU0").searchByAddress(address);

    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        Location location = locations.first;

        double latitude = location.latitude;
        double longitude = location.longitude;

        currentLocation = LatLng(latitude, longitude);

        showPinOnMap();
      }

      _cameraPosition = CameraPosition(target: currentLocation, zoom: 16);

    } catch(e) {
      currentLocation = LatLng(-29.601505328570788, 30.379442518631805);

      _cameraPosition = CameraPosition(target: currentLocation, zoom: 16);

      showPinOnMap();

      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text('Address not found! Default map location City Hall!'),
        ),
      );

    }
    print('$currentLocation this is the change');

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
                title: const Text('Map View'),
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

                  ///Positioned widget is for searching an address but will not be used
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

                  SizedBox(height: 10,),

                  ///Positioned badge that shows account number and address shown on the pin
                  Positioned(
                      top: 10, left: 0, right: 0,
                      child: MapUserBadge(
                        locationGiven: locationGiven,
                        accountNumber: accountNumber,)),
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
        position: currentLocation,
        icon: sourceIcon,
      ));
    });
  }

}
