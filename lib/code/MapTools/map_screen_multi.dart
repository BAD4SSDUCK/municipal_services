// import 'dart:convert';
// import 'map_user_badge.dart';
// import 'package:get/get.dart';
// import 'package:flutter/material.dart';
// import 'location_search_dialogue.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter/foundation.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:map_box_geocoder/map_box_geocoder.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:municipal_services/code/MapTools/location_controller.dart';
// import 'package:municipal_services/code/MapTools/map_screen_multi_invert.dart';
// import 'package:municipal_services/code/SQLApp/propertiesData/properties_data.dart';
// import 'package:municipal_services/code/ReportGeneration/display_capture_report.dart';
//
//
// const LatLng SOURCE_LOCATION = LatLng(-29.601505328570788, 30.379442518631805);
//
//
// class MapScreenMulti extends StatefulWidget {
//   const MapScreenMulti({super.key,});
//
//   @override
//   State<MapScreenMulti> createState() => _MapScreenMultiState();
// }
//
// final FirebaseAuth auth = FirebaseAuth.instance;
// final User? user = auth.currentUser;
// final uid = user?.uid;
// final email = user?.email;
// String userID = uid as String;
// String userEmail = email as String;
//
// class _MapScreenMultiState extends State<MapScreenMulti> {
//   CollectionReference? _propList;
//   // final CollectionReference _propList =
//   // FirebaseFirestore.instance.collection('properties');
//   String? userEmail;
//   String districtId='';
//   String municipalityId='';
//   bool isLocalMunicipality = false;
//   final PropertiesData _propertiesData = Get.put(PropertiesData());
//   bool isLocalUser=false;
//   late CameraPosition _cameraPosition;
//   late LatLng currentLocation;
//   late LatLng addressLocation;
//   late bool _isLoading;
//
//   String location ='Null, Press Button';
//   String Address = 'search';
//
//   List _allPropertiesResults = [];
//
//   bool adminAcc = false;
//   bool visAdmin = false;
//   bool visManager = false;
//   bool visEmployee = false;
//   bool visCapture = false;
//   bool visDev = false;
//   String userRole = '';
//   String userDept = '';
//   List _allUserRolesResults = [];
//
//   @override
//   void initState(){
//     fetchUserDetails();
//     checkAdmin();
//
//     ///This is the circular loading widget in this future.delayed call
//     _isLoading = true;
//     Future.delayed(const Duration(seconds: 5),(){
//       setState(() {
//         _isLoading = false;
//       });
//     });
//
//     //Allows user's location to be captured while using the map
//     locationAllow();
//     //Set camera position based on db address given
//     addressConvert('Chief Albert Luthuli St, Pietermaritzburg, 3200');
//     //Set multiple markers
//     multiMarkerInit();
//
//     getPropertyStream();
//     //Set up initial locations
//     setInitialLocation();
//     //Set up the marker icons
//     setSourceAndDestinationMarkerIcons();
//
//     // city all position for camera default (target: LatLng(-29.601505328570788, 30.379442518631805), zoom: 16);
//     _cameraPosition = CameraPosition(target: currentLocation, zoom: 16);
//
//     super.initState();
//   }
//   @override
//   void dispose() {
//     super.dispose();
//   }
//
//   Future<void> fetchUserDetails() async {
//     try {
//       print("Fetching user details...");
//       User? user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         userEmail = user.email;
//
//         QuerySnapshot userSnapshot = await FirebaseFirestore.instance
//             .collectionGroup('users')
//             .where('email', isEqualTo: userEmail)
//             .limit(1)
//             .get();
//
//         if (userSnapshot.docs.isNotEmpty) {
//           var userDoc = userSnapshot.docs.first;
//           final data = userDoc.data() as Map<String, dynamic>?;
//
//           // Check for isLocalMunicipality field
//           if (data != null && data.containsKey('isLocalMunicipality')) {
//             isLocalMunicipality = data['isLocalMunicipality'] ?? false;
//           }
//
//           if (isLocalMunicipality) {
//             municipalityId = userDoc.reference.parent.parent?.id ?? '';
//             print("User is in a local municipality: $municipalityId");
//             _propList = FirebaseFirestore.instance
//                 .collection('localMunicipalities')
//                 .doc(municipalityId)
//                 .collection('properties');
//           } else {
//             districtId = userDoc.reference.parent.parent?.parent.id ?? '';
//             municipalityId = userDoc.reference.parent.parent?.id ?? '';
//             print("User is in a district municipality: District ID: $districtId, Municipality ID: $municipalityId");
//             _propList = FirebaseFirestore.instance
//                 .collection('districts')
//                 .doc(districtId)
//                 .collection('municipalities')
//                 .doc(municipalityId)
//                 .collection('properties');
//           }
//
//           setState(() {
//             getPropertyStream();
//           });
//         } else {
//           print("No user document found for the provided email.");
//         }
//       }
//     } catch (e) {
//       print('Error fetching user details: $e');
//     }
//   }
//
//
//   void checkAdmin() {
//     getUsersStream();
//     if(userRole == 'Admin'|| userRole == 'Administrator'){
//       adminAcc = true;
//     } else {
//       adminAcc = false;
//     }
//   }
//
//   getUsersStream() async {
//     var data = await FirebaseFirestore.instance
//         .collection(isLocalMunicipality ? 'localMunicipalities' : 'districts')
//         .doc(isLocalMunicipality ? municipalityId : districtId)
//         .collection('users')
//         .get();
//
//     setState(() {
//       _allUserRolesResults = data.docs;
//     });
//
//     getUserDetails();
//   }
//
//   getUserDetails() async {
//     for (var userSnapshot in _allUserRolesResults) {
//       ///Need to build a property model that retrieves property data entirely from the db
//       var user = userSnapshot['email'].toString();
//       var role = userSnapshot['userRole'].toString();
//       var userName = userSnapshot['userName'].toString();
//       var firstName = userSnapshot['firstName'].toString();
//       var lastName = userSnapshot['lastName'].toString();
//       var userDepartment = userSnapshot['deptName'].toString();
//
//       if (user == userEmail) {
//         userRole = role;
//         userDept = userDepartment;
//         print('My Role is::: $userRole');
//
//         if(userRole == 'Admin'|| userRole == 'Administrator'){
//           visAdmin = true;
//           visManager = false;
//           visEmployee = false;
//           visCapture = false;
//         } else if(userRole == 'Manager'){
//           visAdmin = false;
//           visManager = true;
//           visEmployee = false;
//           visCapture = false;
//         } else if(userRole == 'Employee'){
//           visAdmin = false;
//           visManager = false;
//           visEmployee = true;
//           visCapture = false;
//         } else if(userRole == 'Capturer'){
//           visAdmin = false;
//           visManager = false;
//           visEmployee = false;
//           visCapture = true;
//         }
//         if(userDept == 'Developer'){
//           visDev = true;
//         }
//       }
//     }
//   }
//
//   late GoogleMapController _mapController;
//
//   late BitmapDescriptor sourceIcon;
//   final Set<Marker> _markers = <Marker>{};
//   Set<Marker> newMarker = <Marker>{};
//
//
//   void setSourceAndDestinationMarkerIcons() async{
//     if(defaultTargetPlatform == TargetPlatform.android){
//       sourceIcon = await BitmapDescriptor.fromAssetImage(
//           const ImageConfiguration(devicePixelRatio: 2.0),
//           'assets/images/location/source_pin_android.png'
//       );
//     } else {
//       sourceIcon = await BitmapDescriptor.fromAssetImage(
//           const ImageConfiguration(devicePixelRatio: 0.5,size: Size(35, 50)),
//           'assets/images/location/source_pin_android.png'
//       );
//     }
//   }
//
//   Future<void> locationAllow() async {
//     Position position = await _getGeoLocationPosition();
//     location ='Lat: ${position.latitude} , Long: ${position.longitude}';
//     GetAddressFromLatLong(position);
//     if(_getGeoLocationPosition.isBlank == false){
//
//     }
//   }
//
//   Future<Position> _getGeoLocationPosition() async {
//     bool serviceEnabled;
//     LocationPermission permission;
//     // Test if location services are enabled.
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       // Location services are not enabled don't continue
//       // accessing the position and request users of the
//       // App to enable the location services.
//       await Geolocator.openLocationSettings();
//       return Future.error('Location services are disabled.');
//     }
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//
//         return Future.error('Location permissions are denied');
//       }
//     }
//     if (permission == LocationPermission.deniedForever) {
//       // Permissions are denied forever, handle appropriately.
//       return Future.error(
//           'Location permissions are permanently denied, we cannot request permissions.');
//     }
//
//     // When we reach here, permissions are granted and we can
//     // continue accessing the position of the device.
//     return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//   }
//
//   Future<void> GetAddressFromLatLong(Position position)async {
//     if(defaultTargetPlatform == TargetPlatform.android){
//       List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
//       print(placemarks);
//       Placemark place = placemarks[0];
//       Address = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
//     } else {
//
//       List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
//       print(placemarks);
//       Placemark place = placemarks[0];
//       Address = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
//
//     }
//
//   }
//
//   void addressConvert(String address) async {
//     ///Location change here for address conversion into lat long
//     if (defaultTargetPlatform == TargetPlatform.android) {
//       try {
//         List<Location> locations = await locationFromAddress(address);
//
//         if (locations.isNotEmpty) {
//           Location location = locations.first;
//
//           double latitude = location.latitude;
//           double longitude = location.longitude;
//
//           addressLocation = LatLng(latitude, longitude);
//         }
//
//         _cameraPosition = CameraPosition(target: addressLocation, zoom: 16);
//         showPinOnMap();
//       } catch (e) {
//         currentLocation = LatLng(-29.601505328570788, 30.379442518631805);
//
//         _cameraPosition = CameraPosition(target: currentLocation, zoom: 16);
//
//         Fluttertoast.showToast(msg: "Default map location City Hall!",
//             gravity: ToastGravity.CENTER);
//       }
//     } else {
//       ///for web version
//       final apiKey = 'AIzaSyCsOGfD-agV8u68pCfeCManNNoSs4csIbY';
//       final encodedAddress = Uri.encodeComponent(address);
//       final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey&libraries=maps,drawing,visualization,places,routes&callback=initMap';
//
//       final response = await http.get(Uri.parse(url));
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['results'] != null && data['results'].isNotEmpty) {
//           final location = data['results'][0]['geometry']['location'];
//
//           double latitude = location['lat'];
//           double longitude = location['lng'];
//
//           addressLocation = LatLng(latitude, longitude);
//           _cameraPosition = CameraPosition(target: addressLocation, zoom: 16);
//           showPinOnMap();
//         }
//
//       } else {
//         addressLocation = LatLng(-29.601505328570788, 30.379442518631805);
//
//         _cameraPosition = CameraPosition(target: addressLocation, zoom: 16);
//
//         // Fluttertoast.showToast(msg: "Address not found! Default map location City Hall!", gravity: ToastGravity.CENTER);
//
//       }
//     }
//
//     print('$addressLocation this is the change');
//   }
//
//   void multiMarkerInit() async {
//     _propList?.get().then((querySnapshot) async {
//       for (var result in querySnapshot.docs) {
//         print('The address from property is::: ${result['address']}');
//
//         String address = result['address'];
//
//         if (result.isBlank == false) {
//
//           ///A check for if meter image is outstanding or not and add the address of the outstanding images to the map marker
//
//           if(defaultTargetPlatform == TargetPlatform.android){
//             if (result['imgStateE'] == false || result['imgStateW'] == false){
//
//               // addressConvert(address);
//
//               try {
//                 List<Location> locations = await locationFromAddress(address);
//
//                 if (locations.isNotEmpty) {
//                   Location location = locations.first;
//
//                   double latitude = location.latitude;
//                   double longitude = location.longitude;
//
//                   addressLocation = LatLng(latitude, longitude);
//
//                   showPinOnMap();
//                 }
//               } catch (e) {
//                 addressLocation = LatLng(-29.601505328570788, 30.379442518631805);
//               }
//             } else if (result['imgStateE'].isBlank || result['imgStateW'].isBlank){
//               try {
//                 List<Location> locations = await locationFromAddress(address);
//
//                 if (locations.isNotEmpty) {
//                   Location location = locations.first;
//
//                   double latitude = location.latitude;
//                   double longitude = location.longitude;
//
//                   addressLocation = LatLng(latitude, longitude);
//
//                   showPinOnMap();
//                 }
//               } catch (e) {
//                 addressLocation = LatLng(-29.601505328570788, 30.379442518631805);
//               }
//             }
//
//           } else{
//             if (result['imgStateE'] == false || result['imgStateW'] == false){
//               try {
//                 List<Location> locations = await locationFromAddress(address);
//
//                 if (locations.isNotEmpty) {
//                   Location location = locations.first;
//
//                   double latitude = location.latitude;
//                   double longitude = location.longitude;
//
//                   addressLocation = LatLng(latitude, longitude);
//
//                   showPinOnMap();
//                 }
//               } catch (e) {
//                 addressLocation = const LatLng(-29.601505328570788, 30.379442518631805);
//               }
//             } else if (result['imgStateE'] == true || result['imgStateW'] == true){
//               try {
//                 List<Location> locations = await locationFromAddress(address);
//
//                 if (locations.isNotEmpty) {
//                   Location location = locations.first;
//
//                   double latitude = location.latitude;
//                   double longitude = location.longitude;
//
//                   addressLocation = LatLng(latitude, longitude);
//
//                   showPinOnMap();
//                 }
//               } catch (e) {
//                 addressLocation = const LatLng(-29.601505328570788, 30.379442518631805);
//               }
//             }
//
//           }
//
//           ///A check for if payment is outstanding or not and add the address of the outstanding payments to the map marker
//           // if (result['eBill'] != 'R0.00' || result['eBill'] != 'R0' || result['eBill'] != '0' || result['eBill'] != '' || result['eBill'] == false) {
//           //
//           //   try {
//           //     List<Location> locations = await locationFromAddress(address);
//           //
//           //     if (locations.isNotEmpty) {
//           //       Location location = locations.first;
//           //
//           //       double latitude = location.latitude;
//           //       double longitude = location.longitude;
//           //
//           //       addressLocation = LatLng(latitude, longitude);
//           //
//           //       showPinOnMap();
//           //     }
//           //   } catch (e) {
//           //     addressLocation = LatLng(-29.601505328570788, 30.379442518631805);
//           //   }
//           //
//           // }
//           print('Property listed::: $addressLocation');
//
//         }
//       }
//     });
//   }
//
//   getPropertyStream() async{
//     var data = await FirebaseFirestore.instance
//         .collection('districts')
//         .doc(districtId)
//         .collection('municipalities')
//         .doc(municipalityId)
//         .collection('properties')
//         .get();
//     setState(() {
//       _allPropertiesResults = data.docs;
//     });
//     getPropertyDetails();
//   }
//
//   getPropertyDetails() async {
//     for (var propertySnapshot in _allPropertiesResults) {
//       ///Need to build a property model that retrieves property data entirely from the db
//       var prop = propertySnapshot['address'].toString();
//       var meterImageState = propertySnapshot['imgStateE'];
//       var waterImageState = propertySnapshot['imgStateW'];
//
//       if (defaultTargetPlatform == TargetPlatform.android) {
//         if (meterImageState == false || waterImageState == false) {
//           addressConvert(prop);
//           try {
//             List<Location> locations = await locationFromAddress(prop);
//
//             if (locations.isNotEmpty) {
//               Location location = locations.first;
//
//               double latitude = location.latitude;
//               double longitude = location.longitude;
//
//               addressLocation = LatLng(latitude, longitude);
//
//               showPinOnMap();
//             }
//           } catch (e) {
//             addressLocation = LatLng(-29.601505328570788, 30.379442518631805);
//           }
//         }
//       } else {
//         if (meterImageState == false || waterImageState == false) {
//           try {
//             List<Location> locations = await locationFromAddress(prop);
//
//             if (locations.isNotEmpty) {
//               Location location = locations.first;
//
//               double latitude = location.latitude;
//               double longitude = location.longitude;
//
//               addressLocation = LatLng(latitude, longitude);
//
//               showPinOnMap();
//             }
//           } catch (e) {
//             addressLocation = LatLng(-29.601505328570788, 30.379442518631805);
//           }
//         }
//       }
//     }
//   }
//
//   void setAddressLocation() async {
//     addressLocation = LatLng(
//         SOURCE_LOCATION.latitude,
//         SOURCE_LOCATION.longitude
//     );
//   }
//
//   void setInitialLocation() async{
//     currentLocation = LatLng(
//         SOURCE_LOCATION.latitude,
//         SOURCE_LOCATION.longitude
//     );
//   }
//
//   var mapType = MapType.normal;
//
//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<LocationController>(
//         builder: (locationController) {
//           return Scaffold(
//               appBar: AppBar(
//                 title: const Text('Outstanding Captures',style: TextStyle(color: Colors.white),),
//                 iconTheme: const IconThemeData(color: Colors.white),
//                 backgroundColor: Colors.green[700],
//                 actions: <Widget>[
//                   Visibility(
//                     visible: visAdmin,
//                     child: Container(
//                       alignment: Alignment.center,
//                       child:  Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           Row(
//                             children: [
//                               InkWell(
//                                   onTap: () {
//                                     Navigator.push(context,
//                                         MaterialPageRoute(builder: (context) =>  ReportBuilderCaptured(isLocalMunicipality: isLocalMunicipality, isLocalUser: isLocalUser,)));
//                                   },
//                                   child: Text('Reports', style: GoogleFonts.jacquesFrancois(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.w500,
//                                     fontStyle: FontStyle.italic,
//                                     fontSize: 14,), textAlign: TextAlign.center,)
//                               ),
//                               IconButton(
//                                   onPressed: (){
//                                     Navigator.push(context,
//                                         MaterialPageRoute(builder: (context) => ReportBuilderCaptured(isLocalMunicipality: isLocalMunicipality, isLocalUser: isLocalUser,)));
//                                   },
//                                   icon: const Icon(Icons.file_copy_outlined, color: Colors.white,)),
//                             ],
//                           ),
//                         ],
//                       ),),
//                   ),
//                   Visibility(
//                     visible: true,
//                     child: IconButton(
//                         onPressed: (){
//                           Navigator.push(context,
//                               MaterialPageRoute(builder: (context) =>  MapScreenMultiInvert()));
//                         },
//                         icon: const Icon(Icons.credit_score, color: Colors.white,)),),
//                 ],
//               ),
//               body: Stack(
//                 children: <Widget>[
//
//                   ///loading page component starts here
//                   _isLoading
//                       ? const Center(child: CircularProgressIndicator(),)
//                       : GoogleMap(
//                           myLocationEnabled: true,
//                           compassEnabled: false,
//                           tiltGesturesEnabled: false,
//                           markers: _markers,
//                           mapType: mapType,
//
//                           onMapCreated: (GoogleMapController mapController) {
//                             addressConvert(_propertiesData.properties.address);
//                             setState(() {
//                               _mapController = mapController;
//                             });
//                             Fluttertoast.showToast(msg: "Tap on the pin and access directions to the property.", gravity: ToastGravity.TOP);
//                           },
//                           initialCameraPosition: _cameraPosition
//                       ),
//
//                   ///Positioned widget is for searching an address
//                   Positioned(
//                       top: 60,
//                       left: 25, right: 25,
//                       child: GestureDetector(
//                         onTap: () {
//                           Get.dialog(LocationSearchDialogue(mapController: _mapController));
//                           Fluttertoast.showToast(msg: "Select address from the search list!", gravity: ToastGravity.CENTER);
//                           },
//                         child: Container(
//                           height: 50,
//                           padding: const EdgeInsets.symmetric(horizontal: 5),
//                           decoration: BoxDecoration(color: Theme.of(context).highlightColor,),
//
//                           child: Row(children: [
//                             Icon(Icons.location_on, size: 25, color: Colors.green[700],
//                             ),
//                             const SizedBox(width: 5,),
//                             Expanded(
//                                 child: Text(
//                                   '${locationController.pickPlaceMark.name ?? ''}'
//                                       '${locationController.pickPlaceMark.locality ?? ''}'
//                                       '${locationController.pickPlaceMark.postalCode ?? ''}'
//                                       '${locationController.pickPlaceMark.country ?? ''}',
//                                   style: const TextStyle(fontSize: 20),
//                                   maxLines: 1, overflow: TextOverflow.ellipsis,
//                                 ),
//                             ),
//                             const SizedBox(width: 10),
//                             Icon(Icons.search, size: 25, color: Theme.of(context).textTheme.bodyLarge!.color),
//                           ],),
//                         ),
//                       )
//                   ),
//
//                   const SizedBox(height: 10,),
//
//                   ///Positioned badge that shows account number and address shown on the pin
//                   // Positioned(
//                   //     top: 10, left: 0, right: 0,
//                   //     child: MapUserBadge(
//                   //       locationGiven: locationGiven,
//                   //       accountNumber: accountNumber,)
//                   // ),
//                 ],
//               ),
//             floatingActionButton: FloatingActionButton.small(
//               backgroundColor: Colors.white,
//               foregroundColor: Colors.black,
//               child: const Icon(Icons.broken_image_rounded),
//               onPressed: () {
//                 setState(() {
//                   if(mapType == MapType.normal){
//                     mapType=MapType.satellite;
//                   } else if(mapType == MapType.satellite){
//                     mapType=MapType.terrain;
//                   } else if(mapType == MapType.terrain){
//                     mapType=MapType.hybrid;
//                   } else if(mapType == MapType.hybrid){
//                     mapType=MapType.normal;
//                   }
//                 });
//               },
//             ),
//             floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
//           );
//         });
//   }
//
//   void showPinOnMap(){
//     setState(() {
//       _markers.add(Marker(
//         markerId: const MarkerId('sourcePin'),
//         position: addressLocation,
//         icon: sourceIcon,
//       ));
//     });
//   }
//
//   void setNewMarker(LatLng newPos){
//     setState(() {
//       newMarker.add(Marker(
//         markerId: const MarkerId('sourcePin'),
//         position: newPos,
//         icon: sourceIcon,
//       ),);
//     });
//   }
//
// }
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
 import 'package:google_fonts/google_fonts.dart';
import 'package:municipal_services/code/ReportGeneration/display_capture_report.dart';
import 'package:municipal_services/code/MapTools/map_screen_multi_invert.dart';

const LatLng SOURCE_LOCATION = LatLng(-29.601505328570788, 30.379442518631805);

class MapScreenMulti extends StatefulWidget {
  const MapScreenMulti({Key? key}) : super(key: key);

  @override
  State<MapScreenMulti> createState() => _MapScreenMultiState();
}

class _MapScreenMultiState extends State<MapScreenMulti> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = <Marker>{};
  late BitmapDescriptor sourceIcon;
  bool _isLoading = true;
  late CameraPosition _cameraPosition;
  bool isLocalMunicipality = false;
  String districtId = '';
  String municipalityId = '';
  CollectionReference<Map<String, dynamic>>? _propertyCollection;
  Query<Map<String, dynamic>>? _propertyQuery;
  List<String> municipalityOptions = ["All Municipalities"];
  String selectedMunicipality = "All Municipalities";
  MapType _currentMapType = MapType.normal;
  List _allPropResults = [];
  bool isLocalUser = true;
  String? userEmail;
  bool isLoading = false;
  bool adminAcc = false;
  bool visAdmin = false;
  bool visManager = false;
  bool visEmployee = false;
  bool visCapture = false;
  bool visDev = false;
  String userRole = '';
  String userDept = '';

  @override
  void initState() {
    super.initState();
    initializeMapData();
  }

  Future<void> initializeMapData() async {
    await fetchUserDetails();
    await setSourceAndDestinationMarkerIcons();
    await fetchMunicipalities();
    await fetchOutstandingCaptures();
    if(mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchUserDetails() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userEmail = user.email ?? ''; // Ensure userEmail is correctly set
        print("User email initialized: $userEmail");

        // Fetch the user document from Firestore using collectionGroup
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collectionGroup('users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          var userDoc = userSnapshot.docs.first;
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

          var userPathSegments = userDoc.reference.path.split('/');

          // Determine if the user belongs to a district or local municipality
          if (userPathSegments.contains('districts')) {
            // District-based municipality
            districtId = userPathSegments[1];
            municipalityId = userPathSegments[3];
            isLocalMunicipality = false;
            print("District User Detected");
          } else if (userPathSegments.contains('localMunicipalities')) {
            // Local municipality
            municipalityId = userPathSegments[1];
            districtId = ''; // No district for local municipality
            isLocalMunicipality = true;
            print("Local Municipality User Detected");
          }

          // Safely access the 'isLocalUser' field
          isLocalUser = userData['isLocalUser'] ?? false;

          print("After fetchUserDetails:");
          print("districtId: $districtId");
          print("municipalityId: $municipalityId");
          print("isLocalMunicipality: $isLocalMunicipality");
          print("isLocalUser: $isLocalUser");

          // Fetch properties based on the municipality type
          if (isLocalMunicipality) {
            await fetchPropertiesForLocalMunicipality();
          } else if (!isLocalMunicipality) {
            await fetchPropertiesForAllMunicipalities();
          } else if (municipalityId.isNotEmpty) {
            await fetchPropertiesByMunicipality(municipalityId);
          } else {
            print("Error: municipalityId is empty for the local municipality user.");
          }
        } else {
          print('No user document found.');
        }
      } else {
        print("No current user found.");
      }
    } catch (e) {
      print('Error fetching user details: $e');
      if(mounted){
      setState(() {
        isLoading = false;
      });}
    }
  }

  // Future<void> fetchMunicipalities() async {
  //   try {
  //     if (districtId.isNotEmpty) {
  //       print("Fetching municipalities under district: $districtId");
  //       // Fetch all municipalities under the district
  //       var municipalitiesSnapshot = await FirebaseFirestore.instance
  //           .collection('districts')
  //           .doc(districtId)
  //           .collection('municipalities')
  //           .get();
  //
  //       print("Municipalities fetched: ${municipalitiesSnapshot.docs.length}");
  //       if (mounted) {
  //         setState(() {
  //           if (municipalitiesSnapshot.docs.isNotEmpty) {
  //             municipalityOptions = municipalitiesSnapshot.docs
  //                 .map((doc) =>
  //             doc.id) // Using document ID as the municipality name
  //                 .toList();
  //             print("Municipalities list: $municipalityOptions");
  //           } else {
  //             print("No municipalities found");
  //             municipalityOptions = []; // No municipalities found
  //           }
  //
  //           // Ensure selectedMunicipality is "Select Municipality" by default
  //           selectedMunicipality = "All Municipalities";
  //           print("All Municipalities: $selectedMunicipality");
  //
  //           // Fetch properties for all municipalities initially
  //           fetchPropertiesForAllMunicipalities();
  //         });
  //       }
  //     } else {
  //       print("districtId is empty or null.");
  //       if (mounted) {
  //         setState(() {
  //           municipalityOptions = [];
  //           selectedMunicipality = "All Municipalities";
  //         });
  //       }
  //     }
  //   } catch (e) {
  //     print('Error fetching municipalities: $e');
  //   }
  // }
  Future<void> fetchMunicipalities() async {
    if (districtId.isNotEmpty) {
      try {
        var municipalitiesSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .get();
          if(mounted) {
            setState(() {
              municipalityOptions = ["All Municipalities"];
              municipalityOptions.addAll(
                  municipalitiesSnapshot.docs.map((doc) => doc.id).toSet());
              selectedMunicipality = "All Municipalities";
            });
          }
      } catch (e) {
        print('Error fetching municipalities: $e');
      }
    }
  }

  Future<void> fetchPropertiesForAllMunicipalities() async {
    try {
      QuerySnapshot propertiesSnapshot;

      // Check if no specific municipality is selected
      if (selectedMunicipality == null || selectedMunicipality == "All Municipalities") {
        // Fetch properties for all municipalities in the district
        print("Fetching properties for all municipalities under district: $districtId");
        propertiesSnapshot = await FirebaseFirestore.instance
            .collectionGroup('properties')
            .where('districtId', isEqualTo: districtId) // Ensure filtering by district
            .get();

        if (mounted) {
          setState(() {
            _allPropResults = propertiesSnapshot.docs;
            print('Fetched ${_allPropResults.length} properties.');
          });
        }
      } else {
        // Fetch properties for the selected municipality
        print("Fetching properties for municipality: $selectedMunicipality");
        propertiesSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(selectedMunicipality)
            .collection('properties')
            .get();

        if (mounted) {
          setState(() {
            _allPropResults = propertiesSnapshot.docs;
            print('Properties fetched for $selectedMunicipality: ${_allPropResults.length}');
          });
        }
      }
    } catch (e) {
      print('Error fetching properties: $e');
    }
  }

  Future<void> fetchPropertiesForLocalMunicipality() async {
    if (municipalityId.isEmpty) {
      print("Error: municipalityId is empty. Cannot fetch properties.");
      return;
    }

    try {
      print("Fetching properties for local municipality: $municipalityId");

      // Fetch properties only for the specific municipality the user belongs to
      QuerySnapshot propertiesSnapshot = await FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId) // The local municipality ID for the user
          .collection('properties')
          .get();

      // Check if any properties were fetched
      if (propertiesSnapshot.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _allPropResults =
                propertiesSnapshot.docs; // Store fetched properties
          });
        }
        print('Properties fetched for local municipality: $municipalityId');
        print(
            'Number of properties fetched: ${propertiesSnapshot.docs.length}');
      } else {
        print("No properties found for local municipality: $municipalityId");
      }
    } catch (e) {
      print('Error fetching properties for local municipality: $e');
    }
  }

  Future<void> fetchPropertiesByMunicipality(String municipality) async {
    try {
      // Fetch properties for the selected municipality
      QuerySnapshot propertiesSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipality)
          .collection('properties')
          .get();

      // Log the properties fetched
      print(
          'Properties fetched for $municipality: ${propertiesSnapshot.docs.length}');
      if (mounted) {
        setState(() {
          _allPropResults =
              propertiesSnapshot.docs; // Store filtered properties
          print(
              "Number of properties fetched: ${_allPropResults.length}"); // Debugging to ensure properties are set
        });
      }
    } catch (e) {
      print('Error fetching properties for $municipality: $e');
    }
  }

  // Future<void> fetchOutstandingCaptures() async {
  //   _markers.clear();
  //
  //   try {
  //     print("Determining query type based on selectedMunicipality: $selectedMunicipality");
  //
  //     // Set up the query for district-level users when "All Municipalities" is selected
  //     if (!isLocalMunicipality && selectedMunicipality == "All Municipalities") {
  //       print("Setting up collectionGroup query for all properties under district: $districtId");
  //
  //       // Initialize _propertyQuery for all municipalities under the district
  //       _propertyQuery = FirebaseFirestore.instance
  //           .collectionGroup('properties')
  //           .where('districtId', isEqualTo: districtId)
  //           .where('imgStateW', isEqualTo: false); // Filter only outstanding captures
  //
  //       print("CollectionGroup query initialized for all municipalities under district.");
  //     }
  //
  //     // Set up query for a specific municipality
  //     if (!isLocalMunicipality && selectedMunicipality != "All Municipalities") {
  //       print("Setting up query for a specific municipality: $selectedMunicipality");
  //
  //       // Query properties for the selected municipality only
  //       _propertyQuery = FirebaseFirestore.instance
  //           .collection('districts')
  //           .doc(districtId)
  //           .collection('municipalities')
  //           .doc(selectedMunicipality)
  //           .collection('properties')
  //           .where('imgStateW', isEqualTo: false); // Filter only outstanding captures
  //
  //       print("Query initialized for municipality: $selectedMunicipality.");
  //     }
  //
  //     // Check if _propertyQuery is still null before proceeding
  //     if (_propertyQuery == null) {
  //       print("Error: _propertyQuery remains null, cannot proceed with collectionGroup query.");
  //       return;
  //     }
  //
  //     // Fetch properties from the query
  //     QuerySnapshot propertiesSnapshot = await _propertyQuery!.get();
  //     print("Fetched ${propertiesSnapshot.docs.length} properties across all municipalities.");
  //
  //     for (var doc in propertiesSnapshot.docs) {
  //       try {
  //         // Document data
  //         final propertyData = doc.data() as Map<String, dynamic>;
  //
  //         // Check for outstanding capture (imgStateW == false)
  //         bool? imgStateW = propertyData['imgStateW'];
  //         if (imgStateW == false) {
  //           final String? address = propertyData['address'] as String?;
  //
  //           if (address != null && address.isNotEmpty) {
  //             print("Processing property with address: $address");
  //
  //             // Use the same address conversion logic as in `MapScreenProp`
  //             await addressConvertAndAddMarker(address, doc.id);
  //           } else {
  //             print("Address is null or empty for document ID: ${doc.id}, skipping.");
  //           }
  //         } else {
  //           print("Property ${doc.id} does not have outstanding captures.");
  //         }
  //       } catch (e) {
  //         print("Error processing document ID: ${doc.id} - Error: $e");
  //       }
  //     }
  //
  //     if (mounted) {
  //       setState(() {}); // Refresh map with markers
  //     }
  //   } catch (e) {
  //     print("Error fetching outstanding captures: $e");
  //   }
  // }
//   Future<void> addressConvertAndAddMarker(String address, String docId) async {
//     await googleMapsAddressConversion(address, docId);
//   }
//
// // Google Maps API Address Conversion Function
//   Future<void> googleMapsAddressConversion(String address, String docId) async {
//     final apiKey = 'AIzaSyCsOGfD-agV8u68pCfeCManNNoSs4csIbY'; // Use your actual API key here
//     final encodedAddress = Uri.encodeComponent(address);
//     final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey';
//
//     try {
//       final response = await http.get(Uri.parse(url));
//       final data = json.decode(response.body);
//
//       if (data['status'] == 'OK' && data['results'].isNotEmpty) {
//         final location = data['results'][0]['geometry']['location'];
//         LatLng coordinates = LatLng(location['lat'], location['lng']);
//
//         if (mounted) {
//           setState(() {
//             _markers.add(Marker(
//               markerId: MarkerId(docId),
//               position: coordinates,
//               icon: sourceIcon,
//               infoWindow: InfoWindow(
//                 title: address,
//                 snippet: 'Outstanding Capture',
//               ),
//             ));
//           });
//         }
//         print("Marker added via Google Maps API for address: $address at coordinates: $coordinates");
//       } else {
//         print("Google Maps API returned no results for address: $address");
//         addDefaultMarker(address, docId);
//       }
//     } catch (e) {
//       print("Google Maps API error for address $address: $e");
//       addDefaultMarker(address, docId);
//     }
//   }
//
// // Default Marker Function (for unfound addresses)
//   void addDefaultMarker(String address, String docId) {
//     LatLng defaultLocation = LatLng(-29.601505328570788, 30.379442518631805);
//
//     if (mounted) {
//       setState(() {
//         _markers.add(Marker(
//           markerId: MarkerId(docId),
//           position: defaultLocation,
//           icon: sourceIcon,
//           infoWindow: InfoWindow(
//             title: address,
//             snippet: 'Default Location (Address not found)',
//           ),
//         ));
//       });
//     }
//     print("Default marker added for address: $address at coordinates: $defaultLocation");
//   }

//   Future<void> addressConvertAndAddMarker(String address, String docId) async {
//     try {
//       List<Location> locations = await locationFromAddress(address);
//
//       if (locations.isNotEmpty) {
//         Location location = locations.first;
//         LatLng coordinates = LatLng(location.latitude, location.longitude);
//
//         if (mounted) {
//           setState(() {
//             _markers.add(Marker(
//               markerId: MarkerId(docId),
//               position: coordinates,
//               icon: sourceIcon,
//               infoWindow: InfoWindow(
//                 title: address,
//                 snippet: 'Outstanding Capture',
//               ),
//             ));
//           });
//         }
//         print("Marker added for address: $address at coordinates: $coordinates");
//       } else {
//         print("No locations found for address: $address, attempting Google Maps API.");
//         // Fallback to Google Maps API for web if needed
//         await googleMapsAddressFallback(address, docId);
//       }
//     } catch (e) {
//       print("Error locating address $address: $e, attempting Google Maps API.");
//       await googleMapsAddressFallback(address, docId);
//     }
//   }
//
// // Fallback function using Google Maps API
//   Future<void> googleMapsAddressFallback(String address, String docId) async {
//     final apiKey = 'AIzaSyCsOGfD-agV8u68pCfeCManNNoSs4csIbY'; // Use your actual API key here
//     final encodedAddress = Uri.encodeComponent(address);
//     final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey';
//
//     try {
//       final response = await http.get(Uri.parse(url));
//       final data = json.decode(response.body);
//
//       if (data['status'] == 'OK' && data['results'].isNotEmpty) {
//         final location = data['results'][0]['geometry']['location'];
//         LatLng coordinates = LatLng(location['lat'], location['lng']);
//
//         if (mounted) {
//           setState(() {
//             _markers.add(Marker(
//               markerId: MarkerId(docId),
//               position: coordinates,
//               icon: sourceIcon,
//               infoWindow: InfoWindow(
//                 title: address,
//                 snippet: 'Outstanding Capture',
//               ),
//             ));
//           });
//         }
//         print("Marker added via Google Maps API for address: $address at coordinates: $coordinates");
//       } else {
//         print("Google Maps API returned no results for address: $address");
//         addDefaultMarker(address, docId);
//       }
//     } catch (e) {
//       print("Google Maps API error for address $address: $e");
//       addDefaultMarker(address, docId);
//     }
//   }

// Consolidated locateAndMarkAddress function
//   Future<void> locateAndMarkAddress(String address, String docId) async {
//     try {
//       print("Attempting to locate address: $address");
//
//       List<Location> locations = await locationFromAddress(address);
//
//       if (locations.isEmpty) {
//         print("No locations found for address: $address, skipping.");
//         return;
//       }
//
//       Location location = locations.first;
//       LatLng coordinates = LatLng(location.latitude, location.longitude);
//
//       if (mounted) {
//         setState(() {
//           _markers.add(Marker(
//             markerId: MarkerId(docId),
//             position: coordinates,
//             icon: sourceIcon,
//             infoWindow: InfoWindow(
//               title: address,
//               snippet: 'Outstanding Capture',
//             ),
//           ));
//         });
//       }
//       print("Marker added for address: $address at coordinates: $coordinates");
//     } catch (e) {
//       print("Error locating address $address: $e");
//     }
//   }
//
// // The setSourceAndDestinationMarkerIcons method and sourceIcon initialization should match the successful implementation in MapScreenProp
//   Future<void> setSourceAndDestinationMarkerIcons() async {
//     if (defaultTargetPlatform == TargetPlatform.android) {
//       sourceIcon = await BitmapDescriptor.fromAssetImage(
//         const ImageConfiguration(devicePixelRatio: 2.0),
//         'assets/images/location/source_pin_android.png',
//       );
//     } else {
//       sourceIcon = await BitmapDescriptor.fromAssetImage(
//         const ImageConfiguration(devicePixelRatio: 0.5, size: Size(35, 50)),
//         'assets/images/location/source_pin_android.png',
//       );
//     }
//   }



  Future<void> fetchOutstandingCaptures() async {
    _markers.clear();

    try {
      if (selectedMunicipality == 'All Municipalities') {
        // Fetch for all municipalities
        await fetchAllMunicipalitiesOutstandingCaptures();
      } else {
        // Fetch for a single municipality
        await fetchSingleMunicipalityOutstandingCaptures(selectedMunicipality);
      }
      if(mounted){
        setState(() {});} // Refresh map with markers
    } catch (e) {
      print("Error fetching outstanding captures: $e");
    }
  }

// Function to fetch outstanding captures for all municipalities under the district
  Future<void> fetchAllMunicipalitiesOutstandingCaptures() async {
    try {
      // Fetch the list of municipalities for the district
      List<String> municipalityIds = await fetchMunicipalitiesUnderDistrict(districtId);

      List<Map<String, dynamic>> allProperties = [];

      // Fetch properties with imgStateW == false for each municipality separately
      for (String municipalityId in municipalityIds) {
        QuerySnapshot propertiesSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('properties')
            .where('imgStateW', isEqualTo: false)
            .get();

        // Add each property's data to the aggregate list if coordinates are valid
        for (var doc in propertiesSnapshot.docs) {
          var propertyData = doc.data() as Map<String, dynamic>;
          double? lat = propertyData['latitude'];
          double? lng = propertyData['longitude'];

          if (lat != null && lng != null) {
            allProperties.add({...propertyData, 'docId': doc.id});
          }
        }
      }

      // Now add markers for all fetched properties
      for (var propertyData in allProperties) {
        double lat = propertyData['latitude'];
        double lng = propertyData['longitude'];
        String docId = propertyData['docId'];
        String address = propertyData['address'];

        addMarker(lat, lng, docId, address);
      }
    } catch (e) {
      print("Error fetching outstanding captures for all municipalities: $e");
    }
  }

// Function to fetch outstanding captures for a single municipality
  Future<void> fetchSingleMunicipalityOutstandingCaptures(String municipalityId) async {
    try {
      QuerySnapshot propertiesSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('properties')
          .where('imgStateW', isEqualTo: false)
          .get();

      for (var doc in propertiesSnapshot.docs) {
        var propertyData = doc.data() as Map<String, dynamic>;
        double? lat = propertyData['latitude'];
        double? lng = propertyData['longitude'];

        if (lat != null && lng != null) {
          String docId = doc.id;
          String address = propertyData['address'];
          addMarker(lat, lng, docId, address);
        }
      }
    } catch (e) {
      print("Error fetching outstanding captures for municipality $municipalityId: $e");
    }
  }

// Helper function to fetch municipalities under a district
  Future<List<String>> fetchMunicipalitiesUnderDistrict(String districtId) async {
    QuerySnapshot municipalitiesSnapshot = await FirebaseFirestore.instance
        .collection('districts')
        .doc(districtId)
        .collection('municipalities')
        .get();
    return municipalitiesSnapshot.docs.map((doc) => doc.id).toList();
  }

  LatLng _getOffsetLatLng(LatLng originalLatLng, int offsetIndex) {
    const double offsetFactor = 0.00005; // Change this value to adjust how far apart the markers are
    return LatLng(
      originalLatLng.latitude + (offsetIndex * offsetFactor),
      originalLatLng.longitude + (offsetIndex * offsetFactor),
    );
  }


/// Keep track of existing marker positions to handle overlaps
  Map<String, int> _markerOverlapCounter = {};

  void addMarker(double lat, double lng, String docId, String address) {
    if (mounted) {
      LatLng position = LatLng(lat, lng);
      String positionKey = '${position.latitude},${position.longitude}';

      // Check for overlaps at this position and apply offset if needed
      int offsetIndex = _markerOverlapCounter[positionKey] ?? 0;
      if (offsetIndex > 0) {
        // Apply an offset to prevent overlap
        position = _getOffsetLatLng(position, offsetIndex);
      }
        if(mounted) {
          setState(() {
            _markers.add(Marker(
              markerId: MarkerId(docId),
              position: position,
              icon: sourceIcon,
              infoWindow: InfoWindow(
                title: address,
                snippet: 'Outstanding Capture',
              ),
            ));
          });
        }

      // Increment the overlap counter for this position
      _markerOverlapCounter[positionKey] = offsetIndex + 1;

      print("Marker added for $address at LatLng(${position.latitude}, ${position.longitude})");
    } else {
      print("Marker not added for $address: Invalid criteria.");
    }
  }


  Future<void> setSourceAndDestinationMarkerIcons() async {
    sourceIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 0.3),
      'assets/images/location/source_pin_android.png',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outstanding Captures', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[700],
        actions: [
          // Reports section
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.only(right: 16), // Add spacing between Reports and Submitted Captures
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportBuilderCaptured(
                          isLocalMunicipality: isLocalMunicipality,
                          isLocalUser: isLocalUser,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Reports',
                    style: GoogleFonts.jacquesFrancois(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportBuilderCaptured(
                          isLocalMunicipality: isLocalMunicipality,
                          isLocalUser: isLocalUser,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.file_copy_outlined, color: Colors.white),
                ),
              ],
            ),
          ),
          // Submitted Captures section
          Row(
            children: [
              Text(
                'Submitted Captures',
                style: GoogleFonts.jacquesFrancois(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  fontSize: 14,),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MapScreenMultiInvert()));
                },
                icon: const Icon(Icons.credit_score, color: Colors.white),
              ),
            ],
          ),
        ],
      ),

      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
            myLocationEnabled: true,
            markers: _markers,
            mapType: _currentMapType,
            initialCameraPosition: const CameraPosition(
              target: LatLng(-29.601505328570788, 30.379442518631805),
              zoom: 10,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),
          Positioned(
            top: 20,
            left: 10,
            right: 10,
            child: DropdownButton<String>(
              value: municipalityOptions.contains(selectedMunicipality)
                  ? selectedMunicipality
                  : "All Municipalities",
              onChanged: (String? newValue) async {
                setState(() {
                  selectedMunicipality = newValue!;
                });
                await fetchPropertiesForAllMunicipalities();
                await fetchOutstandingCaptures();
              },
              items: municipalityOptions.map((String municipality) {
                return DropdownMenuItem<String>(
                  value: municipality,
                  child: Text(municipality),
                );
              }).toList(),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 10,
            child: FloatingActionButton(
              heroTag: "map_type_button",
              onPressed: () {
                setState(() {
                  _currentMapType = _currentMapType == MapType.normal ? MapType.satellite : MapType.normal;
                });
              },
              child: const Icon(Icons.map),
            ),
          ),
        ],
      ),
    );
  }
}
