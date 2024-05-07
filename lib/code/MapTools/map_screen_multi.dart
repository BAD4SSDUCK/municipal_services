import 'dart:convert';
import 'map_user_badge.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'location_search_dialogue.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:map_box_geocoder/map_box_geocoder.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:municipal_services/code/MapTools/location_controller.dart';
import 'package:municipal_services/code/MapTools/map_screen_multi_invert.dart';
import 'package:municipal_services/code/SQLApp/propertiesData/properties_data.dart';
import 'package:municipal_services/code/ReportGeneration/display_capture_report.dart';


const LatLng SOURCE_LOCATION = LatLng(-29.601505328570788, 30.379442518631805);


class MapScreenMulti extends StatefulWidget {
  const MapScreenMulti({Key? key}) : super(key: key);

  @override
  State<MapScreenMulti> createState() => _MapScreenMultiState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final User? user = auth.currentUser;
final uid = user?.uid;
final email = user?.email;
String userID = uid as String;
String userEmail = email as String;

class _MapScreenMultiState extends State<MapScreenMulti> {

  final CollectionReference _propList =
  FirebaseFirestore.instance.collection('properties');

  final PropertiesData _propertiesData = Get.put(PropertiesData());

  late CameraPosition _cameraPosition;
  late LatLng currentLocation;
  late LatLng addressLocation;
  late bool _isLoading;

  String location ='Null, Press Button';
  String Address = 'search';

  List _allPropertiesResults = [];

  bool adminAcc = false;
  bool visAdmin = false;
  bool visManager = false;
  bool visEmployee = false;
  bool visCapture = false;
  bool visDev = false;
  String userRole = '';
  String userDept = '';
  List _allUserRolesResults = [];

  @override
  void initState(){

    checkAdmin();

    ///This is the circular loading widget in this future.delayed call
    _isLoading = true;
    Future.delayed(const Duration(seconds: 5),(){
      setState(() {
        _isLoading = false;
      });
    });

    //Allows user's location to be captured while using the map
    locationAllow();
    //Set camera position based on db address given
    addressConvert('Chief Albert Luthuli St, Pietermaritzburg, 3200');
    //Set multiple markers
    multiMarkerInit();

    getPropertyStream();
    //Set up initial locations
    setInitialLocation();
    //Set up the marker icons
    setSourceAndDestinationMarkerIcons();

    // city all position for camera default (target: LatLng(-29.601505328570788, 30.379442518631805), zoom: 16);
    _cameraPosition = CameraPosition(target: currentLocation, zoom: 16);

    super.initState();
  }

  void checkAdmin() {
    getUsersStream();
    if(userRole == 'Admin'|| userRole == 'Administrator'){
      adminAcc = true;
    } else {
      adminAcc = false;
    }
  }

  getUsersStream() async{
    var data = await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      _allUserRolesResults = data.docs;
    });
    getUserDetails();
  }

  getUserDetails() async {
    for (var userSnapshot in _allUserRolesResults) {
      ///Need to build a property model that retrieves property data entirely from the db
      var user = userSnapshot['email'].toString();
      var role = userSnapshot['userRole'].toString();
      var userName = userSnapshot['userName'].toString();
      var firstName = userSnapshot['firstName'].toString();
      var lastName = userSnapshot['lastName'].toString();
      var userDepartment = userSnapshot['deptName'].toString();

      if (user == userEmail) {
        userRole = role;
        userDept = userDepartment;
        print('My Role is::: $userRole');

        if(userRole == 'Admin'|| userRole == 'Administrator'){
          visAdmin = true;
          visManager = false;
          visEmployee = false;
          visCapture = false;
        } else if(userRole == 'Manager'){
          visAdmin = false;
          visManager = true;
          visEmployee = false;
          visCapture = false;
        } else if(userRole == 'Employee'){
          visAdmin = false;
          visManager = false;
          visEmployee = true;
          visCapture = false;
        } else if(userRole == 'Capturer'){
          visAdmin = false;
          visManager = false;
          visEmployee = false;
          visCapture = true;
        }
        if(userDept == 'Developer'){
          visDev = true;
        }
      }
    }
  }

  late GoogleMapController _mapController;

  late BitmapDescriptor sourceIcon;
  final Set<Marker> _markers = <Marker>{};
  Set<Marker> newMarker = <Marker>{};


  void setSourceAndDestinationMarkerIcons() async{
    if(defaultTargetPlatform == TargetPlatform.android){
      sourceIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(devicePixelRatio: 2.0),
          'assets/images/location/source_pin_android.png'
      );
    } else {
      sourceIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(devicePixelRatio: 0.5,size: Size(35, 50)),
          'assets/images/location/source_pin_android.png'
      );
    }
  }

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
    if(defaultTargetPlatform == TargetPlatform.android){
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      print(placemarks);
      Placemark place = placemarks[0];
      Address = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
    } else {

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      print(placemarks);
      Placemark place = placemarks[0];
      Address = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';

    }

  }

  void addressConvert(String address) async {
    ///Location change here for address conversion into lat long
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        List<Location> locations = await locationFromAddress(address);

        if (locations.isNotEmpty) {
          Location location = locations.first;

          double latitude = location.latitude;
          double longitude = location.longitude;

          addressLocation = LatLng(latitude, longitude);
        }

        _cameraPosition = CameraPosition(target: addressLocation, zoom: 16);
        showPinOnMap();
      } catch (e) {
        currentLocation = LatLng(-29.601505328570788, 30.379442518631805);

        _cameraPosition = CameraPosition(target: currentLocation, zoom: 16);

        Fluttertoast.showToast(msg: "Default map location City Hall!",
            gravity: ToastGravity.CENTER);
      }
    } else {
      ///for web version
      final apiKey = 'AIzaSyCsOGfD-agV8u68pCfeCManNNoSs4csIbY';
      final encodedAddress = Uri.encodeComponent(address);
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey&libraries=maps,drawing,visualization,places,routes&callback=initMap';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];

          double latitude = location['lat'];
          double longitude = location['lng'];

          addressLocation = LatLng(latitude, longitude);
          _cameraPosition = CameraPosition(target: addressLocation, zoom: 16);
          showPinOnMap();
        }

      } else {
        addressLocation = LatLng(-29.601505328570788, 30.379442518631805);

        _cameraPosition = CameraPosition(target: addressLocation, zoom: 16);

        // Fluttertoast.showToast(msg: "Address not found! Default map location City Hall!", gravity: ToastGravity.CENTER);

      }
    }

    print('$addressLocation this is the change');
  }

  void multiMarkerInit() async {
    _propList.get().then((querySnapshot) async {
      for (var result in querySnapshot.docs) {
        print('The address from property is::: ${result['address']}');

        String address = result['address'];

        if (result.isBlank == false) {

          ///A check for if meter image is outstanding or not and add the address of the outstanding images to the map marker

          if(defaultTargetPlatform == TargetPlatform.android){
            if (result['imgStateE'] == false || result['imgStateW'] == false){

              // addressConvert(address);

              try {
                List<Location> locations = await locationFromAddress(address);

                if (locations.isNotEmpty) {
                  Location location = locations.first;

                  double latitude = location.latitude;
                  double longitude = location.longitude;

                  addressLocation = LatLng(latitude, longitude);

                  showPinOnMap();
                }
              } catch (e) {
                addressLocation = LatLng(-29.601505328570788, 30.379442518631805);
              }
            } else if (result['imgStateE'].isBlank || result['imgStateW'].isBlank){
              try {
                List<Location> locations = await locationFromAddress(address);

                if (locations.isNotEmpty) {
                  Location location = locations.first;

                  double latitude = location.latitude;
                  double longitude = location.longitude;

                  addressLocation = LatLng(latitude, longitude);

                  showPinOnMap();
                }
              } catch (e) {
                addressLocation = LatLng(-29.601505328570788, 30.379442518631805);
              }
            }

          } else{
            if (result['imgStateE'] == false || result['imgStateW'] == false){
              try {
                List<Location> locations = await locationFromAddress(address);

                if (locations.isNotEmpty) {
                  Location location = locations.first;

                  double latitude = location.latitude;
                  double longitude = location.longitude;

                  addressLocation = LatLng(latitude, longitude);

                  showPinOnMap();
                }
              } catch (e) {
                addressLocation = const LatLng(-29.601505328570788, 30.379442518631805);
              }
            } else if (result['imgStateE'] == true || result['imgStateW'] == true){
              try {
                List<Location> locations = await locationFromAddress(address);

                if (locations.isNotEmpty) {
                  Location location = locations.first;

                  double latitude = location.latitude;
                  double longitude = location.longitude;

                  addressLocation = LatLng(latitude, longitude);

                  showPinOnMap();
                }
              } catch (e) {
                addressLocation = const LatLng(-29.601505328570788, 30.379442518631805);
              }
            }

          }

          ///A check for if payment is outstanding or not and add the address of the outstanding payments to the map marker
          // if (result['eBill'] != 'R0.00' || result['eBill'] != 'R0' || result['eBill'] != '0' || result['eBill'] != '' || result['eBill'] == false) {
          //
          //   try {
          //     List<Location> locations = await locationFromAddress(address);
          //
          //     if (locations.isNotEmpty) {
          //       Location location = locations.first;
          //
          //       double latitude = location.latitude;
          //       double longitude = location.longitude;
          //
          //       addressLocation = LatLng(latitude, longitude);
          //
          //       showPinOnMap();
          //     }
          //   } catch (e) {
          //     addressLocation = LatLng(-29.601505328570788, 30.379442518631805);
          //   }
          //
          // }
          print('Property listed::: $addressLocation');

        }
      }
    });
  }

  getPropertyStream() async{
    var data = await FirebaseFirestore.instance.collection('properties').get();
    setState(() {
      _allPropertiesResults = data.docs;
    });
    getPropertyDetails();
  }

  getPropertyDetails() async {
    for (var propertySnapshot in _allPropertiesResults) {
      ///Need to build a property model that retrieves property data entirely from the db
      var prop = propertySnapshot['address'].toString();
      var meterImageState = propertySnapshot['imgStateE'];
      var waterImageState = propertySnapshot['imgStateW'];

      if (defaultTargetPlatform == TargetPlatform.android) {
        if (meterImageState == false || waterImageState == false) {
          addressConvert(prop);
          try {
            List<Location> locations = await locationFromAddress(prop);

            if (locations.isNotEmpty) {
              Location location = locations.first;

              double latitude = location.latitude;
              double longitude = location.longitude;

              addressLocation = LatLng(latitude, longitude);

              showPinOnMap();
            }
          } catch (e) {
            addressLocation = LatLng(-29.601505328570788, 30.379442518631805);
          }
        }
      } else {
        if (meterImageState == false || waterImageState == false) {
          try {
            List<Location> locations = await locationFromAddress(prop);

            if (locations.isNotEmpty) {
              Location location = locations.first;

              double latitude = location.latitude;
              double longitude = location.longitude;

              addressLocation = LatLng(latitude, longitude);

              showPinOnMap();
            }
          } catch (e) {
            addressLocation = LatLng(-29.601505328570788, 30.379442518631805);
          }
        }
      }
    }
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

  var mapType = MapType.normal;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocationController>(
        builder: (locationController) {
          return Scaffold(
              appBar: AppBar(
                title: const Text('Outstanding Captures',style: TextStyle(color: Colors.white),),
                iconTheme: const IconThemeData(color: Colors.white),
                backgroundColor: Colors.green[700],
                actions: <Widget>[
                  Visibility(
                    visible: visAdmin,
                    child: Container(
                      alignment: Alignment.center,
                      child:  Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              InkWell(
                                  onTap: () {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context) => const ReportBuilderCaptured()));
                                  },
                                  child: Text('Reports', style: GoogleFonts.jacquesFrancois(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 14,), textAlign: TextAlign.center,)
                              ),
                              IconButton(
                                  onPressed: (){
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context) => const ReportBuilderCaptured()));
                                  },
                                  icon: const Icon(Icons.file_copy_outlined, color: Colors.white,)),
                            ],
                          ),
                        ],
                      ),),
                  ),
                  Visibility(
                    visible: true,
                    child: IconButton(
                        onPressed: (){
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const MapScreenMultiInvert()));
                        },
                        icon: const Icon(Icons.credit_score, color: Colors.white,)),),
                ],
              ),
              body: Stack(
                children: <Widget>[

                  ///loading page component starts here
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(),)
                      : GoogleMap(
                          myLocationEnabled: true,
                          compassEnabled: false,
                          tiltGesturesEnabled: false,
                          markers: _markers,
                          mapType: mapType,

                          onMapCreated: (GoogleMapController mapController) {
                            addressConvert(_propertiesData.properties.address);
                            setState(() {
                              _mapController = mapController;
                            });
                            Fluttertoast.showToast(msg: "Tap on the pin and access directions to the property.", gravity: ToastGravity.TOP);
                          },
                          initialCameraPosition: _cameraPosition
                      ),

                  ///Positioned widget is for searching an address
                  Positioned(
                      top: 60,
                      left: 25, right: 25,
                      child: GestureDetector(
                        onTap: () {
                          Get.dialog(LocationSearchDialogue(mapController: _mapController));
                          Fluttertoast.showToast(msg: "Select address from the search list!", gravity: ToastGravity.CENTER);
                          },
                        child: Container(
                          height: 50,
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(color: Theme
                              .of(context)
                              .highlightColor,
                          ),

                          child: Row(children: [
                            Icon(Icons.location_on, size: 25, color: Colors.green[700],
                            ),
                            const SizedBox(width: 5,),
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
                            const SizedBox(width: 10),
                            Icon(Icons.search, size: 25, color: Theme.of(context).textTheme.bodyLarge!.color),
                          ],),
                        ),
                      )
                  ),

                  const SizedBox(height: 10,),

                  ///Positioned badge that shows account number and address shown on the pin
                  // Positioned(
                  //     top: 10, left: 0, right: 0,
                  //     child: MapUserBadge(
                  //       locationGiven: locationGiven,
                  //       accountNumber: accountNumber,)
                  // ),
                ],
              ),
            floatingActionButton: FloatingActionButton.small(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              child: const Icon(Icons.broken_image_rounded),
              onPressed: () {
                setState(() {
                  if(mapType == MapType.normal){
                    mapType=MapType.satellite;
                  } else if(mapType == MapType.satellite){
                    mapType=MapType.terrain;
                  } else if(mapType == MapType.terrain){
                    mapType=MapType.hybrid;
                  } else if(mapType == MapType.hybrid){
                    mapType=MapType.normal;
                  }
                });
              },
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          );
        });
  }

  void showPinOnMap(){
    setState(() {
      _markers.add(Marker(
        markerId: const MarkerId('sourcePin'),
        position: addressLocation,
        icon: sourceIcon,
      ));
    });
  }

  void setNewMarker(LatLng newPos){
    setState(() {
      newMarker.add(Marker(
        markerId: const MarkerId('sourcePin'),
        position: newPos,
        icon: sourceIcon,
      ),);
    });
  }

}
