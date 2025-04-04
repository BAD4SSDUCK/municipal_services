import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:municipal_services/code/ImageUploading/image_zoom_fault_page.dart';
import 'package:municipal_services/code/ReportGeneration/display_fault_report.dart'
    as displayReport;
import 'package:municipal_services/code/faultPages/fault_task_screen_archive.dart'
    as faultTask;

import 'package:municipal_services/code/MapTools/map_screen.dart';
import 'package:municipal_services/code/MapTools/map_screen_prop.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';

import '../ReportGeneration/display_fault_report.dart';
import 'fault_task_screen_archive.dart';

class FaultAttendantScreen extends StatefulWidget {
  const FaultAttendantScreen({
    super.key,
  });

  @override
  State<FaultAttendantScreen> createState() => _FaultAttendantScreenState();
}

final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;
final storageRef = FirebaseStorage.instance.ref();

final FirebaseAuth auth = FirebaseAuth.instance;

final User? user = auth.currentUser;
final uid = user?.uid;
final email = user?.email;
String userID = uid as String;
String myUserEmail = email as String;
String userEmail = auth.currentUser?.email as String; // From current file

String emailFromDisplayReport = displayReport.userEmail;
String emailFromFaultTask = faultTask.userEmail;

class FireStorageService extends ChangeNotifier {
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async {
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

String imageName = '';
String dateReported = '';

late LatLng addressLocation;
late LatLng addressLocation2;

class _FaultAttendantScreenState extends State<FaultAttendantScreen> {
  CollectionReference? _faultData;
  CollectionReference? _departmentData;
  String districtId = '';
  String municipalityId = '';
  bool isLocalMunicipality = false;
  bool isLocalUser = true;
  @override
  void initState() {
    if (_searchController.text == "") {
      getFaultStream();
    }

    _searchController.addListener(_onSearchChanged);
    checkRole();
    // getUserDepartmentDetails();
    getDBDept(_departmentData!);

    if (myDepartment == "Water & Sanitation") {
      getSimilarFaultStreamWater();
    } else if (myDepartment == "Waste Management") {
      getSimilarFaultStreamWaste();
      // } else if (myDepartment=="Electricity"){
      //   getSimilarFaultStreamElectricity();
    } else if (myDepartment == "Roadworks") {
      getSimilarFaultStreamRoad();
    }

    _isLoading = true;
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isLoading = false;
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    searchText;
    myUserRole;
    myDepartment;
    adminAcc;
    managerAcc;
    employeeAcc;
    visStage1;
    visStage2;
    visStage3;
    visStage4;
    visStage5;
    super.dispose();
  }

  Future<void> fetchUserDetails() async {
    try {
      print("Fetching user details...");
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userEmail = user.email!;
        print("User email: $userEmail");

        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collectionGroup('users')
            .where('email', isEqualTo: userEmail)
            .limit(1)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          var userDoc = userSnapshot.docs.first;

          // Correct path traversal to retrieve the districtId and municipalityId
          final userPathSegments = userDoc.reference.path.split('/');
          districtId = userPathSegments[1]; // Should be the second segment
          municipalityId = userPathSegments[3]; // Should be the fourth segment

          print("Corrected District ID: $districtId");
          print("Corrected Municipality ID: $municipalityId");

          setState(() {
            _faultData = FirebaseFirestore.instance
                .collection('districts')
                .doc(districtId)
                .collection('municipalities')
                .doc(municipalityId)
                .collection('faultReporting');

            _departmentData = FirebaseFirestore.instance
                .collection('districts')
                .doc(districtId)
                .collection('municipalities')
                .doc(municipalityId)
                .collection('departments');
          });
        } else {
          print("No user document found for the provided email.");
        }
      } else {
        print("No current user found.");
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  late bool _isLoading;

  final _accountNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _commentController = TextEditingController();
  final _deptManagerController = TextEditingController();
  final _depAllocationController = TextEditingController();
  late bool _faultResolvedController;
  final _dateReportedController = TextEditingController();

  // final CollectionReference _faultData =
  // FirebaseFirestore.instance.collection('faultReporting');
  //
  // final CollectionReference _departmentData =
  // FirebaseFirestore.instance.collection('departments');

  String accountNumberRep = '';
  String locationGivenRep = '';
  int faultStage = 0;
  String reporterCellGiven = '';
  String searchText = '';

  User? user = FirebaseAuth.instance.currentUser;

  TextEditingController _searchController = TextEditingController();
  List _allFaultResults = [];
  List _similarFaultResults = [];
  List _closeFaultResults = [];
  List<String> _allUserNames = ["Assign User..."];
  List<String> _allUserByNames = ["Assign User..."];
  List<String> _managerUserNames = ["Assign User..."];
  List<String> _employeesUserNames = ["Assign User..."];
  List<String> _deptName = ["Select Department..."];

  String myUserName = '';
  String myUserRole = '';
  String myDepartment = '';
  String autoManager = '';
  List _allUserRolesResults = [];
  List _allUserResults = [];
  bool visShow = true;
  bool visHide = false;

  bool visNotification = false;

  bool adminAcc = false;
  bool managerAcc = false;
  bool employeeAcc = false;
  bool visStage1 = false;
  bool visStage2 = false;
  bool visStage3 = false;
  bool visStage4 = false;
  bool visStage5 = false;

  final CollectionReference _listUser =
      FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[350],
        appBar: AppBar(
          title: const Text(
            'Faults Reported',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: <Widget>[
            Visibility(
              visible: adminAcc,
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ReportBuilderFaults()));
                },
                icon: const Icon(
                  Icons.file_copy_outlined,
                  color: Colors.white,
                ),
              ),
            ),
            Visibility(
              visible: adminAcc || managerAcc,
              child: IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => FaultTaskScreenArchive()));
                  },
                  icon: const Icon(
                    Icons.history_outlined,
                    color: Colors.white,
                  )),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                text: 'My Assigned Faults',
                icon: FaIcon(Icons.handyman),
              ),
              Tab(
                text: 'All Department Faults',
                icon: FaIcon(Icons.bar_chart),
              ),
            ],
          ),
        ),
        body: TabBarView(children: [
          ///Tab for my faults reported for work
          Column(
            children: [
              /// Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 5.0),
                child: SearchBar(
                  controller: _searchController,
                  padding: const MaterialStatePropertyAll<EdgeInsets>(
                      EdgeInsets.symmetric(horizontal: 16.0)),
                  leading: const Icon(Icons.search),
                  hintText: "Search by Address...",
                  onChanged: (value) async {
                    setState(() {
                      searchText = value;
                      print('this is the input text ::: $searchText');
                    });
                  },
                ),
              ),

              /// Search bar end
              Expanded(
                child: myFaultCard(),
              ),
              const SizedBox(
                height: 5,
              ),
            ],
          ),

          ///Tab for all faults reported to this department
          Column(
            children: [
              /// Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 5.0),
                child: SearchBar(
                  controller: _searchController,
                  padding: const MaterialStatePropertyAll<EdgeInsets>(
                      EdgeInsets.symmetric(horizontal: 16.0)),
                  leading: const Icon(Icons.search),
                  hintText: "Search by Address...",
                  onChanged: (value) async {
                    setState(() {
                      searchText = value;
                      print('this is the input text ::: $searchText');
                    });
                  },
                ),
              ),

              /// Search bar end
              Expanded(
                child: faultCard(),
              ),
              const SizedBox(
                height: 5,
              ),
            ],
          ),
        ]),
      ),
    );
  }

  void getDBDept(CollectionReference dept) async {
    dept.get().then((querySnapshot) async {
      for (var result in querySnapshot.docs) {
        if (_deptName.length - 1 < querySnapshot.docs.length) {
          _deptName.add(result['deptName']);
        }
      }
    });
  }

  ///Looping department collection

  getFaultStream() async {
    var data = await FirebaseFirestore.instance
        .collection('districts')
        .doc(districtId)
        .collection('municipalities')
        .doc(municipalityId)
        .collection('faultReporting')
        .orderBy('dateReported', descending: true)
        .get();

    setState(() {
      _allFaultResults = data.docs;
    });
    searchResultsList();
  }

  getSimilarFaultStreamWater() async {
    var data = await FirebaseFirestore.instance
        .collection('districts')
        .doc(districtId)
        .collection('municipalities')
        .doc(municipalityId)
        .collection('faultReporting')
        .orderBy('dateReported', descending: true)
        .get();

    _similarFaultResults = data.docs;
    addressLocation = LatLng(0, 0);
    addressLocation2 = LatLng(0, 0);

    var queryWater = FirebaseFirestore.instance
        .collection('districts')
        .doc(districtId)
        .collection('municipalities')
        .doc(municipalityId)
        .collection('faultReporting')
        .where('faultType', isEqualTo: 'Water & Sanitation');

    var queryWaterSnapshot = await queryWater.get();

    for (var i = 0; i < queryWaterSnapshot.docs.length; i++) {
      var address1 = queryWaterSnapshot.docs[i]['address'];
      addressConvert(address1);

      var fault1Coordinates = addressLocation;

      for (var j = i + 1; j < queryWaterSnapshot.docs.length; j++) {
        var address2 = queryWaterSnapshot.docs[j]['address'];
        addressConvert2(address2);

        var fault2Coordinates = addressLocation2;

        double distance = await calculateDistance(
          fault1Coordinates.latitude,
          fault1Coordinates.longitude,
          fault2Coordinates.latitude,
          fault2Coordinates.longitude,
        );

        if (distance <= 5.0 && address1 != address2) {
          _closeFaultResults.add(address2);
        }
      }
    }
  }

  getSimilarFaultStreamWaste() async {
    var data = await FirebaseFirestore.instance
        .collection('districts')
        .doc(districtId)
        .collection('municipalities')
        .doc(municipalityId)
        .collection('faultReporting')
        .orderBy('dateReported', descending: true)
        .get();

    _similarFaultResults = data.docs;
    addressLocation = LatLng(0, 0);
    addressLocation2 = LatLng(0, 0);

    /// Example query to get faults of the water & sanitation type
    var queryWaste = FirebaseFirestore.instance
        .collection('districts')
        .doc(districtId)
        .collection('municipalities')
        .doc(municipalityId)
        .collection('faultReporting')
        .where('faultType', isEqualTo: 'Waste Management');

    var queryWasteSnapshot = await queryWaste.get();

    // Iterate through the documents and compare distances
    for (var i = 0; i < queryWasteSnapshot.docs.length; i++) {
      var address1 = queryWasteSnapshot.docs[i]['address'];
      addressConvert(address1);

      var fault1 = queryWasteSnapshot.docs[i];
      var fault1Coordinates = addressLocation;
      // GeoPoint(
      //   fault1['latitude'] as double,
      //   fault1['longitude'] as double,
      // );

      // Compare distances using geolocator
      for (var j = i + 1; j < queryWasteSnapshot.docs.length; j++) {
        var address2 = queryWasteSnapshot.docs[i]['address'];
        addressConvert2(address2);

        var fault2 = queryWasteSnapshot.docs[j];
        var fault2Coordinates = addressLocation2;
        // GeoPoint(
        //   fault2['latitude'] as double,
        //   fault2['longitude'] as double,
        // );

        if (fault1Coordinates != fault2Coordinates) {
          // Calculate distance
          double distance = await calculateDistance(
            fault1Coordinates.latitude,
            fault1Coordinates.longitude,
            fault2Coordinates.latitude,
            fault2Coordinates.longitude,
          );

          // Check if distance is within 5 meters
          if (distance <= 5.0) {
            // Flag or process the faults as needed
            if (address1 != address2) {
              _closeFaultResults.add(address2);

              print('Fault at $address1 is within 5 meters of '
                  'Fault at $address2');
            }
          }
        }
      }
    }
  }

  // getSimilarFaultStreamElectricity() async{
  //   var data = await FirebaseFirestore.instance
  //       .collection('districts')
  //       .doc(districtId)
  //       .collection('municipalities')
  //       .doc(municipalityId)
  //       .collection('faultReporting')
  //       .orderBy('dateReported', descending: true)
  //       .get();
  //
  //   _similarFaultResults = data.docs;
  //   addressLocation=LatLng(0,0);
  //   addressLocation2=LatLng(0,0);
  //
  //   /// Example query to get faults of the water & sanitation type
  //   var queryElectricity = FirebaseFirestore.instance
  //       .collection('districts')
  //       .doc(districtId)
  //       .collection('municipalities')
  //       .doc(municipalityId)
  //       .collection('faultReporting')
  //       .where('faultType', isEqualTo: 'Electricity');
  //
  //   var queryElectricitySnapshot = await queryElectricity.get();
  //
  //   // Iterate through the documents and compare distances
  //   for (var i = 0; i < queryElectricitySnapshot.docs.length; i++) {
  //
  //     var address1 = queryElectricitySnapshot.docs[i]['address'];
  //     addressConvert(address1);
  //
  //     var fault1 = queryElectricitySnapshot.docs[i];
  //     var fault1Coordinates = addressLocation;
  //     // GeoPoint(
  //     //   fault1['latitude'] as double,
  //     //   fault1['longitude'] as double,
  //     // );
  //
  //     // Compare distances using geolocator
  //     for (var j = i + 1; j < queryElectricitySnapshot.docs.length; j++) {
  //       var address2 = queryElectricitySnapshot.docs[i]['address'];
  //       addressConvert2(address2);
  //
  //       var fault2 = queryElectricitySnapshot.docs[j];
  //       var fault2Coordinates = addressLocation2;
  //       // GeoPoint(
  //       //   fault2['latitude'] as double,
  //       //   fault2['longitude'] as double,
  //       // );
  //
  //       if (fault1Coordinates != fault2Coordinates){
  //         // Calculate distance
  //         double distance = await calculateDistance(
  //           fault1Coordinates.latitude,
  //           fault1Coordinates.longitude,
  //           fault2Coordinates.latitude,
  //           fault2Coordinates.longitude,
  //         );
  //
  //         // Check if distance is within 5 meters
  //         if (distance <= 5.0) {
  //           // Flag or process the faults as needed
  //           if(address1 != address2) {
  //             _closeFaultResults.add(address2);
  //
  //             print('Fault at $address1 is within 5 meters of ''Fault at $address2');
  //           }
  //         }
  //       }
  //     }
  //   }
  // }

  getSimilarFaultStreamRoad() async {
    var data = await FirebaseFirestore.instance
        .collection('districts')
        .doc(districtId)
        .collection('municipalities')
        .doc(municipalityId)
        .collection('faultReporting')
        .orderBy('dateReported', descending: true)
        .get();

    _similarFaultResults = data.docs;
    addressLocation = LatLng(0, 0);
    addressLocation2 = LatLng(0, 0);

    /// Example query to get faults of the water & sanitation type
    var queryRoadworks = FirebaseFirestore.instance
        .collection('districts')
        .doc(districtId)
        .collection('municipalities')
        .doc(municipalityId)
        .collection('faultReporting')
        .where('faultType', isEqualTo: 'Roadworks');

    var queryRoadworksSnapshot = await queryRoadworks.get();

    // Iterate through the documents and compare distances
    for (var i = 0; i < queryRoadworksSnapshot.docs.length; i++) {
      var address1 = queryRoadworksSnapshot.docs[i]['address'];
      addressConvert(address1);

      var fault1 = queryRoadworksSnapshot.docs[i];
      var fault1Coordinates = addressLocation;
      // GeoPoint(
      //   fault1['latitude'] as double,
      //   fault1['longitude'] as double,
      // );

      // Compare distances using geolocator
      for (var j = i + 1; j < queryRoadworksSnapshot.docs.length; j++) {
        var address2 = queryRoadworksSnapshot.docs[i]['address'];
        addressConvert2(address2);

        var fault2 = queryRoadworksSnapshot.docs[j];
        var fault2Coordinates = addressLocation2;
        // GeoPoint(
        //   fault2['latitude'] as double,
        //   fault2['longitude'] as double,
        // );

        // Calculate distance
        double distance = await calculateDistance(
          fault1Coordinates.latitude,
          fault1Coordinates.longitude,
          fault2Coordinates.latitude,
          fault2Coordinates.longitude,
        );

        print('The distance is::: $distance');
        // Check if distance is within 5 meters
        if (distance <= 5.0) {
          // Flag or process the faults as needed
          if (address1 != address2) {
            _closeFaultResults.add(address2);
            print('Fault at $address1 is within 5 meters of '
                'Fault at $address2');
          }
        }
      }
    }
  }

  Future<double> calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) async {
    try {
      double distanceInMeters = await Geolocator.distanceBetween(
        lat1,
        lon1,
        lat2,
        lon2,
      );
      print('Distance in meters ::: $distanceInMeters');
      return distanceInMeters;
    } catch (e) {
      print('Error calculating distance: $e');
      return 0.0;
    }
  }

  void toggleVisibilityNotification() {
    setState(() {
      visNotification = !visNotification;
    });
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
          print('$addressLocation this is the change');
        }
      } catch (e) {
        print('Address incorrect with no latlng to calculate');
      }
    } else {
      ///for web version
      final apiKey = 'AIzaSyCsOGfD-agV8u68pCfeCManNNoSs4csIbY';
      final encodedAddress = Uri.encodeComponent(address);
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey&libraries=maps,drawing,visualization,places,routes&callback=initMap';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];

          double latitude = location['lat'];
          double longitude = location['lng'];

          addressLocation = LatLng(latitude, longitude);
          print('$addressLocation this is the change');
        }
      } else {
        print('Address incorrect with no latlng to calculate');
      }
    }
  }

  void addressConvert2(String address) async {
    ///Location change here for address conversion into lat long
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        List<Location> locations = await locationFromAddress(address);

        if (locations.isNotEmpty) {
          Location location = locations.first;

          double latitude = location.latitude;
          double longitude = location.longitude;

          addressLocation2 = LatLng(latitude, longitude);
          print('$addressLocation2 this is the change');
        }
      } catch (e) {
        print('Address incorrect with no latlng to calculate');
      }
    } else {
      ///for web version
      final apiKey = 'AIzaSyCsOGfD-agV8u68pCfeCManNNoSs4csIbY';
      final encodedAddress = Uri.encodeComponent(address);
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey&libraries=maps,drawing,visualization,places,routes&callback=initMap';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];

          double latitude = location['lat'];
          double longitude = location['lng'];

          addressLocation2 = LatLng(latitude, longitude);
          print('$addressLocation2 this is the change');
        }
      } else {
        print('Address incorrect with no latlng to calculate');
      }
    }
  }

  _onSearchChanged() async {
    searchResultsList();
  }

  searchResultsList() async {
    var showResults = [];
    if (_searchController.text != "") {
      getFaultStream();
      for (var faultSnapshot in _allFaultResults) {
        ///Need to build a property model that retrieves property data entirely from the db
        var address = faultSnapshot['address'].toString().toLowerCase();

        if (address.contains(_searchController.text.toLowerCase())) {
          showResults.add(faultSnapshot);
        }
      }
    } else {
      getFaultStream();
      showResults = List.from(_allFaultResults);
    }
    setState(() {
      _allFaultResults = showResults;
    });
  }

  void checkRole() {
    getUsersStream();
    if (myUserRole == 'Admin' || myUserRole == 'Administrator') {
      adminAcc = true;
      managerAcc = false;
      employeeAcc = false;
    } else if (myUserRole == 'Manager') {
      adminAcc = false;
      managerAcc = true;
      employeeAcc = false;
    } else {
      adminAcc = false;
      managerAcc = false;
      employeeAcc = true;
    }
  }

  getUsersStream() async {
    var data = await FirebaseFirestore.instance
        .collection('districts')
        .doc(districtId)
        .collection('municipalities')
        .doc(municipalityId)
        .collection('users')
        .get();

    _allUserRolesResults = data.docs;
    getUserDetails();
  }

  getUserDetails() async {
    for (var userSnapshot in _allUserRolesResults) {
      ///Need to build a property model that retrieves property data entirely from the db
      var userEmail = userSnapshot['email'].toString();
      var role = userSnapshot['userRole'].toString();
      var userName = userSnapshot['userName'].toString();
      var firstName = userSnapshot['firstName'].toString();
      var lastName = userSnapshot['lastName'].toString();
      var userDepartment = userSnapshot['deptName'].toString();

      _allUserNames.add(userName);
      _allUserByNames.add('$firstName $lastName');

      if (userEmail == myUserEmail) {
        myUserName = userName;
        myUserRole = role;
        print('My Role is::: $myUserRole');
        myDepartment = userDepartment;
        print('My Department is::: $myDepartment');

        if (myUserRole == 'Admin' || myUserRole == 'Administrator') {
          adminAcc = true;
          managerAcc = false;
          employeeAcc = false;
        } else if (myUserRole == 'Service Provider') {
          adminAcc = true;
          managerAcc = false;
          employeeAcc = false;
        } else if (myUserRole == 'Manager') {
          adminAcc = false;
          managerAcc = true;
          employeeAcc = false;
        } else {
          adminAcc = false;
          managerAcc = false;
          employeeAcc = true;
        }

        if (myDepartment == "Water & Sanitation") {
          getSimilarFaultStreamWater();
        } else if (myDepartment == "Waste Management") {
          getSimilarFaultStreamWaste();
          // } else if (myDepartment=="Electricity"){
          //   getSimilarFaultStreamElectricity();
        } else if (myDepartment == "Roadworks") {
          getSimilarFaultStreamRoad();
        } else if (myDepartment == "Service Provider") {
          getSimilarFaultStreamWater();
          getSimilarFaultStreamWaste();
          // getSimilarFaultStreamElectricity();
          getSimilarFaultStreamRoad();
        }
      }
    }
    getUserDepartmentDetails();
  }

  getUserDepartmentDetails() async {
    var data = await FirebaseFirestore.instance
        .collection('districts')
        .doc(districtId)
        .collection('municipalities')
        .doc(municipalityId)
        .collection('users')
        .get();
    _allUserResults = data.docs;

    for (var userSnapshot in _allUserResults) {
      ///Need to build a property model that retrieves property data entirely from the db
      var userEmail = userSnapshot['email'].toString();
      var role = userSnapshot['userRole'].toString();
      var userName = userSnapshot['userName'].toString();
      var firstName = userSnapshot['firstName'].toString();
      var lastName = userSnapshot['lastName'].toString();
      var userDepartment = userSnapshot['deptName'].toString();

      if (role == 'Manager') {
        if (userDepartment == myDepartment) {
          _managerUserNames.add(userName);
          print('Manager to list::: $userName');
          autoManager = userName;
        } else if ((myDepartment != 'Water & Sanitation' &&
            myDepartment != 'Waste Management' &&
            myDepartment != 'Electricity' &&
            myDepartment != 'Roadworks')) {
          _managerUserNames.add(userName);
          print('Manager to list::: $userName');
        }
      } else if (role == 'Employee') {
        if (userDepartment == myDepartment) {
          _employeesUserNames.add(userName);
          print('Employee to list::: $userName');
        } else if ((myDepartment != 'Water & Sanitation' &&
            myDepartment != 'Waste Management' &&
            myDepartment != 'Electricity' &&
            myDepartment != 'Roadworks')) {
          _employeesUserNames.add(userName);
          print('Employee to list::: $userName');
        }
      }
    }
  }

  Future<Widget> _getImage(BuildContext context, String imageName) async {
    Image image;
    final value = await FireStorageService.loadImage(context, imageName);

    final imageUrl = await storageRef.child(imageName).getDownloadURL();

    ///Check what the app is running on
    if (defaultTargetPlatform == TargetPlatform.android) {
      image = Image.network(
        value.toString(),
        fit: BoxFit.fill,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      // print('The url is::: $imageUrl');
      image = Image.network(
        imageUrl,
        fit: BoxFit.fitHeight,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return image;
  }

  //this widget is for displaying a property field of information with an icon next to it, NB. the icon is to make it look good
  //it is called within a listview page widget
  Widget faultItemField(String faultDat) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 6,
          ),
          Text(
            faultDat,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget faultCard() {
    if (_allFaultResults.isNotEmpty) {
      return _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: _allFaultResults.length,
              itemBuilder: (context, index) {
                String status;
                if (_allFaultResults[index]['faultResolved'] == false) {
                  status = "Pending";
                } else {
                  status = "Completed";
                }

                // if(_closeFaultResults.isNotEmpty){
                //   for(int i = 0; i <= _closeFaultResults.length; i++){
                //     if(_allFaultResults[index]['address'] == _closeFaultResults[i]){
                //       print('Should display notif on ::: ${_allFaultResults[index]['address']}');
                //       toggleVisibilityNotification();
                //     }else{
                //       visNotification = false;
                //     }
                //   }
                // }

                if (_allFaultResults[index]['faultResolved'] == false) {
                  if (myDepartment == _allFaultResults[index]['faultType']) {
                    return Card(
                      margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Row(
                                children: [
                                  const Text(
                                    'Fault Information',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  Visibility(
                                      visible: visNotification,
                                      child: const Icon(
                                        Icons.notification_important,
                                        color: Colors.red,
                                      )),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Text(
                              'Reference Number: ${_allFaultResults[index]['ref']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['accountNumber'] !=
                                    "") ...[
                                  Text(
                                    'Reporter Account Number: ${_allFaultResults[index]['accountNumber']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Text(
                              'Street Address of Fault: ${_allFaultResults[index]['address']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              'Date of Fault Report: ${_allFaultResults[index]['dateReported']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['faultStage'] ==
                                    1) ...[
                                  Text(
                                    'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.deepOrange),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else if (_allFaultResults[index]
                                        ['faultStage'] ==
                                    2) ...[
                                  Text(
                                    'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.orange),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else if (_allFaultResults[index]
                                        ['faultStage'] ==
                                    3) ...[
                                  Text(
                                    'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.orangeAccent),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else if (_allFaultResults[index]
                                        ['faultStage'] ==
                                    4) ...[
                                  Text(
                                    'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.greenAccent),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else if (_allFaultResults[index]
                                        ['faultStage'] ==
                                    5) ...[
                                  Text(
                                    'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.lightGreen),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Text(
                              'Fault Type: ${_allFaultResults[index]['faultType']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]
                                        ['faultDescription'] !=
                                    "") ...[
                                  Text(
                                    'Fault Description: ${_allFaultResults[index]['faultDescription']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['adminComment'] !=
                                    "") ...[
                                  Text(
                                    'Admin Comment: ${_allFaultResults[index]['adminComment']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]
                                        ['reallocationComment'] !=
                                    "") ...[
                                  Text(
                                    'Reason fault reallocated: ${_allFaultResults[index]['reallocationComment']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]
                                        ['managerAllocated'] !=
                                    "") ...[
                                  Text(
                                    'Manager of fault: ${_allFaultResults[index]['managerAllocated']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]
                                        ['attendeeAllocated'] !=
                                    "") ...[
                                  Text(
                                    'Attendee Allocated: ${_allFaultResults[index]['attendeeAllocated']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['attendeeCom1'] !=
                                    "") ...[
                                  Text(
                                    'Attendee Comment: ${_allFaultResults[index]['attendeeCom1']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['managerCom1'] !=
                                    "") ...[
                                  Text(
                                    'Manager Comment: ${_allFaultResults[index]['managerCom1']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['attendeeCom2'] !=
                                    "") ...[
                                  Text(
                                    'Attendee Followup Comment: ${_allFaultResults[index]['attendeeCom2']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['managerCom2'] !=
                                    "") ...[
                                  Text(
                                    'Manager Final/Additional Comment: ${_allFaultResults[index]['managerCom2']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['attendeeCom3'] !=
                                    "") ...[
                                  Text(
                                    'Attendee Final Comment: ${_allFaultResults[index]['attendeeCom3']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['managerCom3'] !=
                                    "") ...[
                                  Text(
                                    'Manager Final Comment: ${_allFaultResults[index]['managerCom3']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Text(
                              'Resolve State: $status',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Center(
                              child: BasicIconButtonGrey(
                                onPress: () async {
                                  imageName =
                                      'files/faultImages/${_allFaultResults[index]['dateReported']}/${_allFaultResults[index]['address']}';
                                  dateReported =
                                      _allFaultResults[index]['dateReported'];

                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ImageZoomFaultPage(
                                                imageName: imageName,
                                                dateReported: dateReported,
                                                isLocalMunicipality:
                                                    isLocalMunicipality,
                                                districtId: districtId,
                                                municipalityId: municipalityId,
                                                isLocalUser: isLocalUser,
                                              )));
                                },
                                labelText: 'View Fault Image',
                                fSize: 14,
                                faIcon: const FaIcon(
                                  Icons.zoom_in,
                                ),
                                fgColor: Colors.grey,
                                btSize: const Size(100, 38),
                              ),
                            ),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        accountNumberRep =
                                            _allFaultResults[index]
                                                ['accountNumber'];
                                        locationGivenRep =
                                            _allFaultResults[index]['address'];

                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    MapScreenProp(
                                                      propAddress:
                                                          locationGivenRep,
                                                      propAccNumber:
                                                          accountNumberRep,
                                                    )));
                                      },
                                      labelText: 'Location',
                                      fSize: 14,
                                      faIcon: const FaIcon(
                                        Icons.map,
                                      ),
                                      fgColor: Colors.green,
                                      btSize: const Size(50, 38),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (myDepartment == 'Service Provider' ||
                      myDepartment == 'Developer') {
                    return Card(
                      margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'Fault Information',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Text(
                              'Reference Number: ${_allFaultResults[index]['ref']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['accountNumber'] !=
                                    "") ...[
                                  Text(
                                    'Reporter Account Number: ${_allFaultResults[index]['accountNumber']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Text(
                              'Street Address of Fault: ${_allFaultResults[index]['address']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              'Date of Fault Report: ${_allFaultResults[index]['dateReported']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['faultStage'] ==
                                    1) ...[
                                  Text(
                                    'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.deepOrange),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else if (_allFaultResults[index]
                                        ['faultStage'] ==
                                    2) ...[
                                  Text(
                                    'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.orange),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else if (_allFaultResults[index]
                                        ['faultStage'] ==
                                    3) ...[
                                  Text(
                                    'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.orangeAccent),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else if (_allFaultResults[index]
                                        ['faultStage'] ==
                                    4) ...[
                                  Text(
                                    'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.lightGreen),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else if (_allFaultResults[index]
                                        ['faultStage'] ==
                                    5) ...[
                                  Text(
                                    'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.lightGreen),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Text(
                              'Fault Type: ${_allFaultResults[index]['faultType']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]
                                        ['faultDescription'] !=
                                    "") ...[
                                  Text(
                                    'Fault Description: ${_allFaultResults[index]['faultDescription']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['adminComment'] !=
                                    "") ...[
                                  Text(
                                    'Admin Comment: ${_allFaultResults[index]['adminComment']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]
                                        ['reallocationComment'] !=
                                    "") ...[
                                  Text(
                                    'Reason fault reallocated: ${_allFaultResults[index]['reAllocationComment']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]
                                        ['managerAllocated'] !=
                                    "") ...[
                                  Text(
                                    'Manager of fault: ${_allFaultResults[index]['managerAllocated']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]
                                        ['attendeeAllocated'] !=
                                    "") ...[
                                  Text(
                                    'Attendee Allocated: ${_allFaultResults[index]['attendeeAllocated']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['attendeeCom1'] !=
                                    "") ...[
                                  Text(
                                    'Attendee Comment: ${_allFaultResults[index]['attendeeCom1']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['managerCom1'] !=
                                    "") ...[
                                  Text(
                                    'Manager Comment: ${_allFaultResults[index]['managerCom1']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['attendeeCom2'] !=
                                    "") ...[
                                  Text(
                                    'Attendee Followup Comment: ${_allFaultResults[index]['attendeeCom2']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['managerCom2'] !=
                                    "") ...[
                                  Text(
                                    'Manager Final/Additional Comment: ${_allFaultResults[index]['managerCom2']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['attendeeCom3'] !=
                                    "") ...[
                                  Text(
                                    'Attendee Final Comment: ${_allFaultResults[index]['attendeeCom3']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['managerCom3'] !=
                                    "") ...[
                                  Text(
                                    'Manager Final Comment: ${_allFaultResults[index]['managerCom3']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Text(
                              'Resolve State: $status',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Center(
                              child: BasicIconButtonGrey(
                                onPress: () async {
                                  imageName =
                                      'files/faultImages/${_allFaultResults[index]['dateReported']}/${_allFaultResults[index]['address']}';
                                  dateReported =
                                      _allFaultResults[index]['dateReported'];

                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ImageZoomFaultPage(
                                                imageName: imageName,
                                                dateReported: dateReported,
                                                isLocalMunicipality:
                                                    isLocalMunicipality,
                                                districtId: districtId,
                                                municipalityId: municipalityId,
                                                isLocalUser: isLocalUser,
                                              )));
                                },
                                labelText: 'View Fault Image',
                                fSize: 14,
                                faIcon: const FaIcon(
                                  Icons.zoom_in,
                                ),
                                fgColor: Colors.grey,
                                btSize: const Size(100, 38),
                              ),
                            ),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        accountNumberRep =
                                            _allFaultResults[index]
                                                ['accountNumber'];
                                        locationGivenRep =
                                            _allFaultResults[index]['address'];

                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    MapScreenProp(
                                                      propAddress:
                                                          locationGivenRep,
                                                      propAccNumber:
                                                          accountNumberRep,
                                                    )));
                                      },
                                      labelText: 'Location',
                                      fSize: 14,
                                      faIcon: const FaIcon(
                                        Icons.map,
                                      ),
                                      fgColor: Colors.green,
                                      btSize: const Size(50, 38),
                                    ),
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        showDialog(
                                            barrierDismissible: false,
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                shape:
                                                    const RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    16))),
                                                title: const Text(
                                                    "Call Reporter!"),
                                                content: const Text(
                                                    "Would you like to call the individual who logged the fault?"),
                                                actions: [
                                                  IconButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    icon: const Icon(
                                                      Icons.cancel,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () {
                                                      reporterCellGiven =
                                                          _allFaultResults[
                                                                  index][
                                                              'reporterContact'];

                                                      final Uri _tel = Uri.parse(
                                                          'tel:${reporterCellGiven.toString()}');
                                                      launchUrl(_tel);

                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    icon: const Icon(
                                                      Icons.done,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            });
                                      },
                                      labelText: 'Call User',
                                      fSize: 14,
                                      faIcon: const FaIcon(
                                        Icons.call,
                                      ),
                                      fgColor: Colors.orange,
                                      btSize: const Size(50, 38),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Visibility(
                                      visible: adminAcc,
                                      child: Center(
                                        child: BasicIconButtonGrey(
                                          onPress: () async {
                                            _reassignDept(
                                                _allFaultResults[index]);
                                          },
                                          labelText: 'Department Reallocation',
                                          fSize: 14,
                                          faIcon: const FaIcon(
                                            Icons.compare_arrows,
                                          ),
                                          fgColor: Colors.blue,
                                          btSize: const Size(50, 38),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // const SizedBox(height: 5,),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Visibility(
                                      visible: (_allFaultResults[index]
                                                      ['faultStage'] ==
                                                  2 ||
                                              _allFaultResults[index]
                                                      ['faultStage'] ==
                                                  3) &&
                                          (managerAcc || employeeAcc),
                                      child: BasicIconButtonGrey(
                                        onPress: () async {
                                          faultStage = _allFaultResults[index]
                                              ['faultStage'];

                                          ///working on
                                          _returnFaultToAdmin(
                                              _allFaultResults[index]);
                                        },
                                        labelText: 'Return',
                                        fSize: 14,
                                        faIcon: const FaIcon(
                                          Icons.error_outline,
                                        ),
                                        fgColor: Colors.orangeAccent,
                                        btSize: const Size(50, 38),
                                      ),
                                    ),
                                    Visibility(
                                      visible: adminAcc,
                                      child: BasicIconButtonGrey(
                                        onPress: () async {
                                          _reassignFault(
                                              _allFaultResults[index]);
                                        },
                                        labelText: 'Reassign',
                                        fSize: 14,
                                        faIcon: const FaIcon(
                                          Icons.update,
                                        ),
                                        fgColor: Theme.of(context).primaryColor,
                                        btSize: const Size(50, 38),
                                      ),
                                    ),
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        faultStage = _allFaultResults[index]
                                            ['faultStage'];
                                        _updateReport(_allFaultResults[index]);
                                      },
                                      labelText: 'Update',
                                      fSize: 14,
                                      faIcon: const FaIcon(
                                        Icons.edit,
                                      ),
                                      fgColor: Colors.blue,
                                      btSize: const Size(50, 38),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox();
                  }
                }
              },
            );
    }
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget myFaultCard() {
    if (_allFaultResults.isNotEmpty) {
      return _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: _allFaultResults.length,
              itemBuilder: (context, index) {
                String status;
                if (_allFaultResults[index]['faultResolved'] == false) {
                  status = "Pending";
                } else {
                  status = "Completed";
                }

                if (_closeFaultResults.isNotEmpty) {
                  for (int i = 0; i <= _closeFaultResults.length; i++) {
                    if (_allFaultResults[index]['address'] ==
                        _closeFaultResults[i]) {
                      print(
                          'Should display notify on ::: ${_allFaultResults[index]['address']}');
                      toggleVisibilityNotification();
                    } else {
                      visNotification = false;
                    }
                  }
                }

                if (_allFaultResults[index]['faultResolved'] == false) {
                  if (myDepartment == _allFaultResults[index]['faultType'] &&
                      myUserName ==
                          _allFaultResults[index]['attendeeAllocated'] &&
                      _allFaultResults[index]['faultStage'] != 5) {
                    return Card(
                      margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Row(
                                children: [
                                  const Text(
                                    'Fault Information',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  Visibility(
                                      visible: visNotification,
                                      child: const Icon(
                                        Icons.notification_important,
                                        color: Colors.red,
                                      )),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Text(
                              'Reference Number: ${_allFaultResults[index]['ref']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['accountNumber'] !=
                                    "") ...[
                                  Text(
                                    'Reporter Account Number: ${_allFaultResults[index]['accountNumber']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Text(
                              'Street Address of Fault: ${_allFaultResults[index]['address']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              'Date of Fault Report: ${_allFaultResults[index]['dateReported']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['faultStage'] ==
                                    1) ...[
                                  Text(
                                    'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.deepOrange),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else if (_allFaultResults[index]
                                        ['faultStage'] ==
                                    2) ...[
                                  Text(
                                    'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.orange),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else if (_allFaultResults[index]
                                        ['faultStage'] ==
                                    3) ...[
                                  Text(
                                    'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.orangeAccent),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else if (_allFaultResults[index]
                                        ['faultStage'] ==
                                    4) ...[
                                  Text(
                                    'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.greenAccent),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else if (_allFaultResults[index]
                                        ['faultStage'] ==
                                    5) ...[
                                  Text(
                                    'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.lightGreen),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Text(
                              'Fault Type: ${_allFaultResults[index]['faultType']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]
                                        ['faultDescription'] !=
                                    "") ...[
                                  Text(
                                    'Fault Description: ${_allFaultResults[index]['faultDescription']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['adminComment'] !=
                                    "") ...[
                                  Text(
                                    'Admin Comment: ${_allFaultResults[index]['adminComment']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]
                                        ['reallocationComment'] !=
                                    "") ...[
                                  Text(
                                    'Reason fault reallocated: ${_allFaultResults[index]['reallocationComment']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]
                                        ['managerAllocated'] !=
                                    "") ...[
                                  Text(
                                    'Manager of fault: ${_allFaultResults[index]['managerAllocated']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]
                                        ['attendeeAllocated'] !=
                                    "") ...[
                                  Text(
                                    'Attendee Allocated: ${_allFaultResults[index]['attendeeAllocated']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['attendeeCom1'] !=
                                    "") ...[
                                  Text(
                                    'Attendee Comment: ${_allFaultResults[index]['attendeeCom1']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['managerCom1'] !=
                                    "") ...[
                                  Text(
                                    'Manager Comment: ${_allFaultResults[index]['managerCom1']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['attendeeCom2'] !=
                                    "") ...[
                                  Text(
                                    'Attendee Followup Comment: ${_allFaultResults[index]['attendeeCom2']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['managerCom2'] !=
                                    "") ...[
                                  Text(
                                    'Manager Final/Additional Comment: ${_allFaultResults[index]['managerCom2']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['attendeeCom3'] !=
                                    "") ...[
                                  Text(
                                    'Attendee Final Comment: ${_allFaultResults[index]['attendeeCom3']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['managerCom3'] !=
                                    "") ...[
                                  Text(
                                    'Manager Final Comment: ${_allFaultResults[index]['managerCom3']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Text(
                              'Resolve State: $status',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Center(
                              child: BasicIconButtonGrey(
                                onPress: () async {
                                  imageName =
                                      'files/faultImages/${_allFaultResults[index]['dateReported']}/${_allFaultResults[index]['address']}';
                                  dateReported =
                                      _allFaultResults[index]['dateReported'];

                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ImageZoomFaultPage(
                                                imageName: imageName,
                                                dateReported: dateReported,
                                                isLocalMunicipality:
                                                    isLocalMunicipality,
                                                districtId: districtId,
                                                municipalityId: municipalityId,
                                                isLocalUser: isLocalUser,
                                              )));
                                },
                                labelText: 'View Fault Image',
                                fSize: 14,
                                faIcon: const FaIcon(
                                  Icons.zoom_in,
                                ),
                                fgColor: Colors.grey,
                                btSize: const Size(100, 38),
                              ),
                            ),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        accountNumberRep =
                                            _allFaultResults[index]
                                                ['accountNumber'];
                                        locationGivenRep =
                                            _allFaultResults[index]['address'];

                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    MapScreenProp(
                                                      propAddress:
                                                          locationGivenRep,
                                                      propAccNumber:
                                                          accountNumberRep,
                                                    )));
                                      },
                                      labelText: 'Location',
                                      fSize: 14,
                                      faIcon: const FaIcon(
                                        Icons.map,
                                      ),
                                      fgColor: Colors.green,
                                      btSize: const Size(50, 38),
                                    ),
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        showDialog(
                                            barrierDismissible: false,
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                shape:
                                                    const RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    16))),
                                                title: const Text(
                                                    "Call Reporter!"),
                                                content: const Text(
                                                    "Would you like to call the individual who logged the fault?"),
                                                actions: [
                                                  IconButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    icon: const Icon(
                                                      Icons.cancel,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () {
                                                      reporterCellGiven =
                                                          _allFaultResults[
                                                                  index][
                                                              'reporterContact'];

                                                      final Uri _tel = Uri.parse(
                                                          'tel:${reporterCellGiven.toString()}');
                                                      launchUrl(_tel);

                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    icon: const Icon(
                                                      Icons.done,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            });
                                      },
                                      labelText: 'Call User',
                                      fSize: 14,
                                      faIcon: const FaIcon(
                                        Icons.call,
                                      ),
                                      fgColor: Colors.orange,
                                      btSize: const Size(50, 38),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Visibility(
                                      visible: adminAcc,
                                      child: Center(
                                        child: BasicIconButtonGrey(
                                          onPress: () async {
                                            _reassignDept(
                                                _allFaultResults[index]);
                                          },
                                          labelText: 'Reallocate Department',
                                          fSize: 14,
                                          faIcon: const FaIcon(
                                            Icons.compare_arrows,
                                          ),
                                          fgColor: Colors.blue,
                                          btSize: const Size(50, 38),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // const SizedBox(height: 5,),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Visibility(
                                      visible: (_allFaultResults[index]
                                                      ['faultStage'] ==
                                                  2 ||
                                              _allFaultResults[index]
                                                      ['faultStage'] ==
                                                  3) &&
                                          (managerAcc || employeeAcc),
                                      child: BasicIconButtonGrey(
                                        onPress: () async {
                                          faultStage = _allFaultResults[index]
                                              ['faultStage'];

                                          ///working on
                                          _returnFaultToAdmin(
                                              _allFaultResults[index]);
                                        },
                                        labelText: 'Return',
                                        fSize: 14,
                                        faIcon: const FaIcon(
                                          Icons.error_outline,
                                        ),
                                        fgColor: Colors.orangeAccent,
                                        btSize: const Size(50, 38),
                                      ),
                                    ),
                                    Visibility(
                                      visible: adminAcc,
                                      child: BasicIconButtonGrey(
                                        onPress: () async {
                                          _reassignFault(
                                              _allFaultResults[index]);
                                        },
                                        labelText: 'Reassign',
                                        fSize: 14,
                                        faIcon: const FaIcon(
                                          Icons.update,
                                        ),
                                        fgColor: Theme.of(context).primaryColor,
                                        btSize: const Size(50, 38),
                                      ),
                                    ),
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        faultStage = _allFaultResults[index]
                                            ['faultStage'];
                                        _updateReport(_allFaultResults[index]);
                                      },
                                      labelText: 'Update',
                                      fSize: 14,
                                      faIcon: const FaIcon(
                                        Icons.edit,
                                      ),
                                      fgColor: Colors.blue,
                                      btSize: const Size(50, 38),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (myDepartment == 'Service Provider' ||
                      myDepartment == 'Developer') {
                    return Card(
                      margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'Fault Information',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Text(
                              'Reference Number: ${_allFaultResults[index]['ref']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['accountNumber'] !=
                                    "") ...[
                                  Text(
                                    'Reporter Account Number: ${_allFaultResults[index]['accountNumber']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Text(
                              'Street Address of Fault: ${_allFaultResults[index]['address']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              'Date of Fault Report: ${_allFaultResults[index]['dateReported']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['faultStage'] ==
                                    1) ...[
                                  Text(
                                    'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.deepOrange),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else if (_allFaultResults[index]
                                        ['faultStage'] ==
                                    2) ...[
                                  Text(
                                    'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.orange),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else if (_allFaultResults[index]
                                        ['faultStage'] ==
                                    3) ...[
                                  Text(
                                    'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.orangeAccent),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else if (_allFaultResults[index]
                                        ['faultStage'] ==
                                    4) ...[
                                  Text(
                                    'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.lightGreen),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else if (_allFaultResults[index]
                                        ['faultStage'] ==
                                    5) ...[
                                  Text(
                                    'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.lightGreen),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Text(
                              'Fault Type: ${_allFaultResults[index]['faultType']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]
                                        ['faultDescription'] !=
                                    "") ...[
                                  Text(
                                    'Fault Description: ${_allFaultResults[index]['faultDescription']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['adminComment'] !=
                                    "") ...[
                                  Text(
                                    'Admin Comment: ${_allFaultResults[index]['adminComment']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]
                                        ['reallocationComment'] !=
                                    "") ...[
                                  Text(
                                    'Reason fault reallocated: ${_allFaultResults[index]['reAllocationComment']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]
                                        ['managerAllocated'] !=
                                    "") ...[
                                  Text(
                                    'Manager of fault: ${_allFaultResults[index]['managerAllocated']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]
                                        ['attendeeAllocated'] !=
                                    "") ...[
                                  Text(
                                    'Attendee Allocated: ${_allFaultResults[index]['attendeeAllocated']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['attendeeCom1'] !=
                                    "") ...[
                                  Text(
                                    'Attendee Comment: ${_allFaultResults[index]['attendeeCom1']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['managerCom1'] !=
                                    "") ...[
                                  Text(
                                    'Manager Comment: ${_allFaultResults[index]['managerCom1']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['attendeeCom2'] !=
                                    "") ...[
                                  Text(
                                    'Attendee Followup Comment: ${_allFaultResults[index]['attendeeCom2']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['managerCom2'] !=
                                    "") ...[
                                  Text(
                                    'Manager Final/Additional Comment: ${_allFaultResults[index]['managerCom2']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['attendeeCom3'] !=
                                    "") ...[
                                  Text(
                                    'Attendee Final Comment: ${_allFaultResults[index]['attendeeCom3']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Column(
                              children: [
                                if (_allFaultResults[index]['managerCom3'] !=
                                    "") ...[
                                  Text(
                                    'Manager Final Comment: ${_allFaultResults[index]['managerCom3']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ] else
                                  ...[],
                              ],
                            ),
                            Text(
                              'Resolve State: $status',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Center(
                              child: BasicIconButtonGrey(
                                onPress: () async {
                                  imageName =
                                      'files/faultImages/${_allFaultResults[index]['dateReported']}/${_allFaultResults[index]['address']}';
                                  dateReported =
                                      _allFaultResults[index]['dateReported'];

                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ImageZoomFaultPage(
                                                imageName: imageName,
                                                dateReported: dateReported,
                                                isLocalMunicipality:
                                                    isLocalMunicipality,
                                                districtId: districtId,
                                                municipalityId: municipalityId,
                                                isLocalUser: isLocalUser,
                                              )));
                                },
                                labelText: 'View Fault Image',
                                fSize: 14,
                                faIcon: const FaIcon(
                                  Icons.zoom_in,
                                ),
                                fgColor: Colors.grey,
                                btSize: const Size(100, 38),
                              ),
                            ),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        accountNumberRep =
                                            _allFaultResults[index]
                                                ['accountNumber'];
                                        locationGivenRep =
                                            _allFaultResults[index]['address'];

                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    MapScreenProp(
                                                      propAddress:
                                                          locationGivenRep,
                                                      propAccNumber:
                                                          accountNumberRep,
                                                    )));
                                      },
                                      labelText: 'Location',
                                      fSize: 14,
                                      faIcon: const FaIcon(
                                        Icons.map,
                                      ),
                                      fgColor: Colors.green,
                                      btSize: const Size(50, 38),
                                    ),
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        showDialog(
                                            barrierDismissible: false,
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                shape:
                                                    const RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    16))),
                                                title: const Text(
                                                    "Call Reporter!"),
                                                content: const Text(
                                                    "Would you like to call the individual who logged the fault?"),
                                                actions: [
                                                  IconButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    icon: const Icon(
                                                      Icons.cancel,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () {
                                                      reporterCellGiven =
                                                          _allFaultResults[
                                                                  index][
                                                              'reporterContact'];

                                                      final Uri _tel = Uri.parse(
                                                          'tel:${reporterCellGiven.toString()}');
                                                      launchUrl(_tel);

                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    icon: const Icon(
                                                      Icons.done,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            });
                                      },
                                      labelText: 'Call User',
                                      fSize: 14,
                                      faIcon: const FaIcon(
                                        Icons.call,
                                      ),
                                      fgColor: Colors.orange,
                                      btSize: const Size(50, 38),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Visibility(
                                      visible: adminAcc,
                                      child: Center(
                                        child: BasicIconButtonGrey(
                                          onPress: () async {
                                            _reassignDept(
                                                _allFaultResults[index]);
                                          },
                                          labelText: 'Department Reallocation',
                                          fSize: 14,
                                          faIcon: const FaIcon(
                                            Icons.compare_arrows,
                                          ),
                                          fgColor: Colors.blue,
                                          btSize: const Size(50, 38),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // const SizedBox(height: 5,),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Visibility(
                                      visible: (_allFaultResults[index]
                                                      ['faultStage'] ==
                                                  2 ||
                                              _allFaultResults[index]
                                                      ['faultStage'] ==
                                                  3) &&
                                          (managerAcc || employeeAcc),
                                      child: BasicIconButtonGrey(
                                        onPress: () async {
                                          faultStage = _allFaultResults[index]
                                              ['faultStage'];

                                          ///working on
                                          _returnFaultToAdmin(
                                              _allFaultResults[index]);
                                        },
                                        labelText: 'Return',
                                        fSize: 14,
                                        faIcon: const FaIcon(
                                          Icons.error_outline,
                                        ),
                                        fgColor: Colors.orangeAccent,
                                        btSize: const Size(50, 38),
                                      ),
                                    ),
                                    Visibility(
                                      visible: adminAcc,
                                      child: BasicIconButtonGrey(
                                        onPress: () async {
                                          _reassignFault(
                                              _allFaultResults[index]);
                                        },
                                        labelText: 'Reassign',
                                        fSize: 14,
                                        faIcon: const FaIcon(
                                          Icons.update,
                                        ),
                                        fgColor: Theme.of(context).primaryColor,
                                        btSize: const Size(50, 38),
                                      ),
                                    ),
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        faultStage = _allFaultResults[index]
                                            ['faultStage'];
                                        _updateReport(_allFaultResults[index]);
                                      },
                                      labelText: 'Update',
                                      fSize: 14,
                                      faIcon: const FaIcon(
                                        Icons.edit,
                                      ),
                                      fgColor: Colors.blue,
                                      btSize: const Size(50, 38),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox();
                  }
                }
              },
            );
    }
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  //This class is for updating the report stages by the manager and the handler to comment through phases of the report
  Future<void> _updateReport([DocumentSnapshot? documentSnapshot]) async {
    String dropdownValue = 'Select Department...';
    dropdownValue = documentSnapshot?['faultType'];
    String dropdownValue2 = 'Assign User...';
    String dropdownValue3 = 'Assign User...';
    print('Default manager pulled ::::${_managerUserNames[0]}');

    // if(documentSnapshot?['managerAllocated'] != "" && documentSnapshot?['managerAllocated'] != "Service Provider" && documentSnapshot?['managerAllocated'] != "Developer" ){
    //   dropdownValue2 = documentSnapshot?['managerAllocated'];
    // }
    // if(documentSnapshot?['attendeeAllocated'] != "" && documentSnapshot?['attendeeAllocated'] != "Service Provider" && documentSnapshot?['attendeeAllocated'] != "Developer" ){
    //   dropdownValue3 = documentSnapshot?['attendeeAllocated'];
    // }

    //This checks the current state of the fault stage 5 is resolve stage
    int stageNum = documentSnapshot!['faultStage'];
    if (stageNum == 1) {
      visStage1 = true;
      visStage2 = false;
      visStage3 = false;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 2) {
      visStage1 = false;
      visStage2 = true;
      visStage3 = false;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 3) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = true;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 4) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = false;
      visStage4 = true;
      visStage5 = false;
    } else if (stageNum == 5) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = false;
      visStage4 = false;
      visStage5 = true;
    }

    _accountNumberController.text = documentSnapshot['accountNumber'];
    _addressController.text = documentSnapshot['address'];
    _descriptionController.text = documentSnapshot['faultDescription'];
    _commentController.text = '';
    _depAllocationController.text = documentSnapshot['depAllocated'];
    _faultResolvedController = documentSnapshot['faultResolved'];

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    void _createBottomSheet() async {
      showModalBottomSheet(
          context: context,
          builder: await showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (BuildContext ctx) {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(
                            top: 20,
                            left: 20,
                            right: 20,
                            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Visibility(
                              visible: visStage1 && employeeAcc,
                              child: const Text(
                                'Only Administrators may assign faults.',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Visibility(
                              visible: (visStage2 ||
                                      visStage3 ||
                                      visStage4 ||
                                      visStage5) &&
                                  adminAcc,
                              child: const Text(
                                'Awaiting Attendee & Manager processing.',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            // Visibility(
                            //   visible: visStage1 && adminAcc,
                            //   child: const Text('Department Allocation'),
                            // ),
                            // Visibility(
                            //   visible: visStage1 && adminAcc,
                            //   child: DropdownButtonFormField <String>(
                            //     value: dropdownValue,
                            //     items: _deptName.toSet()
                            //         .map<DropdownMenuItem<String>>((String value) {
                            //       return DropdownMenuItem<String>(
                            //         value: value,
                            //         child: Text(value, style: const TextStyle(fontSize: 16),),
                            //       );
                            //     }).toList(),
                            //     onChanged: (String? newValue) {
                            //       setState(() {
                            //         dropdownValue = newValue!;
                            //       });
                            //     },
                            //   ),
                            // ),

                            Visibility(
                              visible: visStage1 && adminAcc,
                              child: const Text('Assign To'),
                            ),
                            Visibility(
                              visible: visStage1 && adminAcc,
                              child: DropdownButtonFormField<String>(
                                value: dropdownValue3,
                                items: _employeesUserNames
                                    .toSet()
                                    .map<DropdownMenuItem<String>>(
                                        (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    dropdownValue3 = newValue!;
                                  });
                                },
                              ),
                            ),

                            Visibility(
                              // visible: visStage1 && adminAcc,
                              visible: visHide,
                              child: const Text('Department Manager Allocated'),
                            ),
                            Visibility(
                              // visible: visStage1 && adminAcc,
                              visible: visHide,
                              child: DropdownButtonFormField<String>(
                                value: dropdownValue2,
                                items: _managerUserNames
                                    .toSet()
                                    .map<DropdownMenuItem<String>>(
                                        (String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      );
                                    })
                                    .toSet()
                                    .toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    dropdownValue2 = newValue!;
                                  });
                                },
                              ),
                            ),

                            Visibility(
                              visible: (visStage1 ||
                                      visStage2 ||
                                      visStage4 ||
                                      visStage5) &&
                                  adminAcc,
                              child: TextField(
                                keyboardType: TextInputType.text,
                                controller: _commentController,
                                decoration: const InputDecoration(
                                  labelText: 'Comment...',
                                ),
                              ),
                            ),
                            Visibility(
                              visible: (visStage2 || visStage3 || visStage5) &&
                                  managerAcc,
                              child: TextField(
                                keyboardType: TextInputType.text,
                                controller: _commentController,
                                decoration: const InputDecoration(
                                  labelText: 'Comment...',
                                ),
                              ),
                            ),

                            Visibility(
                              visible: (visStage3 || visStage5) && employeeAcc,
                              child: const Text(
                                'Awaiting Manager processing & feedback.',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),

                            Visibility(
                              visible: (visStage2 || visStage4) && employeeAcc,
                              child: TextField(
                                keyboardType: TextInputType.text,
                                controller: _commentController,
                                decoration: const InputDecoration(
                                  labelText: 'Comment...',
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Visibility(
                              visible: (visStage3 || visStage4 || visStage5) &&
                                  managerAcc,
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.only(
                                    left: 0.0, right: 25.0),
                                child: Row(
                                  children: <Widget>[
                                    const Text(
                                      'Fault Resolved?',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400),
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Checkbox(
                                      checkColor: Colors.white,
                                      fillColor:
                                          MaterialStateProperty.all<Color>(
                                              Colors.green),
                                      value: _faultResolvedController,
                                      onChanged: (bool? value) async {
                                        setState(() {
                                          _faultResolvedController = value!;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Row(
                              children: [
                                Visibility(
                                  visible: (visStage1 && adminAcc) ||
                                      ((visStage3 || visStage5) &&
                                          managerAcc) ||
                                      ((visStage2 || visStage4) && employeeAcc),
                                  child: ElevatedButton(
                                    child: const Text('Update'),
                                    onPressed: () async {
                                      final String depSelected = dropdownValue;
                                      final String attendeeAllocated =
                                          dropdownValue3;
                                      // String managerAllocated = dropdownValue2;
                                      String managerAllocated =
                                          _managerUserNames[0];
                                      final String userComment =
                                          _commentController.text;
                                      final bool faultResolved =
                                          _faultResolvedController;

                                      if (faultStage == 1 && adminAcc) {
                                        if (autoManager != '') {
                                          managerAllocated = autoManager;
                                        }
                                        if ((_commentController.text != '' ||
                                                _commentController
                                                    .text.isNotEmpty) &&
                                            (dropdownValue3 !=
                                                    'Assign User...' &&
                                                dropdownValue !=
                                                    'Select Department...')) {
                                          ///dropdownValue2 != 'Assign User...' &&
                                          await _faultData
                                              ?.doc(documentSnapshot.id)
                                              .update({
                                            "depAllocated": depSelected,
                                            "attendeeAllocated":
                                                attendeeAllocated,
                                            "managerAllocated":
                                                managerAllocated,
                                            "adminComment": userComment,
                                            "faultStage": 2,
                                          });

                                          dropdownValue =
                                              'Select Department...';
                                          dropdownValue2 = 'Assign User...';
                                          dropdownValue3 = 'Assign User...';
                                          _commentController.text = '';
                                          _faultResolvedController = false;

                                          visStage1 = false;
                                          visStage2 = false;
                                          visStage3 = false;
                                          visStage4 = false;
                                          visStage4 = false;

                                          Navigator.of(context).pop();
                                        } else if (dropdownValue ==
                                            'Select Department...') {
                                          Fluttertoast.showToast(
                                              msg:
                                                  'Please allocate the fault to the correct department before continuing',
                                              gravity: ToastGravity.CENTER);
                                        } else if (dropdownValue3 ==
                                            'Assign User...') {
                                          Fluttertoast.showToast(
                                              msg:
                                                  'Please assign attendee to the fault and comment to the attendee before continuing',
                                              gravity: ToastGravity.CENTER);
                                        }
                                      } else if (faultStage == 2) {
                                        if (employeeAcc) {
                                          await _faultData
                                              ?.doc(documentSnapshot.id)
                                              .update({
                                            "attendeeCom1": userComment,
                                            "faultStage": 3,
                                          });

                                          _commentController.text = '';
                                          _depAllocationController.text = '';
                                          dropdownValue = '';
                                          _faultResolvedController = false;
                                          _dateReportedController.text = '';

                                          visStage1 = false;
                                          visStage2 = false;
                                          visStage3 = false;
                                          visStage4 = false;
                                          visStage5 = false;

                                          if (context.mounted)
                                            Navigator.of(context).pop();
                                        } else if (managerAcc) {
                                          await _faultData
                                              ?.doc(documentSnapshot.id)
                                              .update({
                                            "managerCom1": userComment,
                                            "faultStage": 3,
                                          });

                                          _commentController.text = '';
                                          _depAllocationController.text = '';
                                          dropdownValue = '';
                                          _faultResolvedController = false;
                                          _dateReportedController.text = '';

                                          visStage1 = false;
                                          visStage2 = false;
                                          visStage3 = false;
                                          visStage4 = false;
                                          visStage5 = false;

                                          if (context.mounted)
                                            Navigator.of(context).pop();
                                        } else {
                                          Fluttertoast.showToast(
                                              msg:
                                                  'Please give a comment of information before continuing',
                                              gravity: ToastGravity.CENTER);
                                        }
                                      } else if (faultStage == 3) {
                                        if (employeeAcc) {
                                          await _faultData
                                              ?.doc(documentSnapshot.id)
                                              .update({
                                            "attendeeCom2": userComment,
                                            "faultStage": 4,
                                          });

                                          _commentController.text = '';
                                          _depAllocationController.text = '';
                                          dropdownValue = '';
                                          _faultResolvedController = false;
                                          _dateReportedController.text = '';

                                          visStage1 = false;
                                          visStage2 = false;
                                          visStage3 = false;
                                          visStage4 = false;
                                          visStage5 = false;

                                          if (context.mounted)
                                            Navigator.of(context).pop();
                                        } else if (managerAcc) {
                                          await _faultData
                                              ?.doc(documentSnapshot.id)
                                              .update({
                                            "managerCom2": userComment,
                                            "faultStage": 3,
                                          });

                                          _commentController.text = '';
                                          _depAllocationController.text = '';
                                          dropdownValue = '';
                                          _faultResolvedController = false;
                                          _dateReportedController.text = '';

                                          visStage1 = false;
                                          visStage2 = false;
                                          visStage3 = false;
                                          visStage4 = false;
                                          visStage5 = false;

                                          if (context.mounted)
                                            Navigator.of(context).pop();
                                        } else {
                                          Fluttertoast.showToast(
                                              msg:
                                                  'Please give a comment of information before continuing',
                                              gravity: ToastGravity.CENTER);
                                        }
                                      } else if (faultStage == 4) {
                                        if ((_commentController.text != '' ||
                                                _commentController
                                                    .text.isNotEmpty) &&
                                            faultResolved == true) {
                                          await _faultData
                                              ?.doc(documentSnapshot.id)
                                              .update({
                                            "managerCom2": userComment,
                                            "faultResolved": faultResolved,
                                            "faultStage": 5,
                                          });

                                          _commentController.text = '';
                                          _depAllocationController.text = '';
                                          dropdownValue = '';
                                          _faultResolvedController = false;
                                          _dateReportedController.text = '';

                                          visStage1 = false;
                                          visStage2 = false;
                                          visStage3 = false;
                                          visStage4 = false;
                                          visStage5 = false;

                                          if (context.mounted)
                                            Navigator.of(context).pop();
                                        } else if ((_commentController.text !=
                                                    '' ||
                                                _commentController
                                                    .text.isNotEmpty) &&
                                            faultResolved == true) {
                                          await _faultData
                                              ?.doc(documentSnapshot.id)
                                              .update({
                                            "managerCom2": userComment,
                                            "faultResolved": faultResolved,
                                            "faultStage": 3,
                                          });

                                          _commentController.text = '';
                                          _depAllocationController.text = '';
                                          dropdownValue = '';
                                          _faultResolvedController = false;
                                          _dateReportedController.text = '';

                                          visStage1 = false;
                                          visStage2 = false;
                                          visStage3 = false;
                                          visStage4 = false;
                                          visStage5 = false;

                                          if (context.mounted)
                                            Navigator.of(context).pop();
                                        } else {
                                          Fluttertoast.showToast(
                                              msg:
                                                  'Please give a comment to what you are doing before continuing',
                                              gravity: ToastGravity.CENTER);
                                        }
                                      } else if (faultStage == 5) {
                                        await _faultData
                                            ?.doc(documentSnapshot.id)
                                            .update({
                                          "managerCom3": userComment,
                                          "faultResolved": faultResolved,
                                          "faultStage": 6,
                                        });

                                        _commentController.text = '';
                                        _depAllocationController.text = '';
                                        dropdownValue = '';
                                        _faultResolvedController = false;
                                        _dateReportedController.text = '';

                                        visStage1 = false;
                                        visStage2 = false;
                                        visStage3 = false;
                                        visStage4 = false;
                                        visStage5 = false;

                                        if (context.mounted)
                                          Navigator.of(context).pop();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              }));
    }

    _createBottomSheet();
  }

  Future<void> _reassignFault([DocumentSnapshot? documentSnapshot]) async {
    String dropdownValue = 'Select Department...';
    dropdownValue = documentSnapshot?['faultType'];
    String dropdownValue2 = 'Assign User...';
    String dropdownValue3 = 'Assign User...';
    _commentController.text = '';

    //This checks the current state of the fault stage 5 is resolve stage
    int stageNum = documentSnapshot!['faultStage'];
    if (stageNum == 1) {
      visStage1 = true;
      visStage2 = false;
      visStage3 = false;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 2) {
      visStage1 = false;
      visStage2 = true;
      visStage3 = false;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 3) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = true;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 4) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = false;
      visStage4 = true;
      visStage5 = false;
    } else if (stageNum == 5) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = false;
      visStage4 = false;
      visStage5 = true;
    }

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    void _createBottomSheet() async {
      showModalBottomSheet(
          context: context,
          builder: await showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (BuildContext ctx) {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(
                            top: 20,
                            left: 20,
                            right: 20,
                            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Visibility(
                            //   visible: adminAcc,
                            //   child: const Text('Department Allocation'),
                            // ),
                            // Visibility(
                            //   visible: adminAcc,
                            //   child: DropdownButtonFormField <String>(
                            //     value: dropdownValue,
                            //     items: _deptName.toSet()
                            //         .map<DropdownMenuItem<String>>((String value) {
                            //       return DropdownMenuItem<String>(
                            //         value: value,
                            //         child: Text(value, style: const TextStyle(fontSize: 16),),
                            //       );
                            //     }).toList(),
                            //     onChanged: (String? newValue) {
                            //       setState(() {
                            //         dropdownValue = newValue!;
                            //       });
                            //     },
                            //   ),
                            // ),

                            // Visibility(
                            //   visible: adminAcc,
                            //   child: const Text('Manager Allocation'),
                            // ),
                            // Visibility(
                            //   visible: adminAcc,
                            //   child: DropdownButtonFormField <String>(
                            //     value: dropdownValue2,
                            //     items: _managerUserNames.toSet()
                            //         .map<DropdownMenuItem<String>>((String value) {
                            //       return DropdownMenuItem<String>(
                            //         value: value,
                            //         child: Text(value, style: const TextStyle(fontSize: 16),),
                            //       );
                            //     }).toList(),
                            //     onChanged: (String? newValue) {
                            //       setState(() {
                            //         dropdownValue2 = newValue!;
                            //       });
                            //     },
                            //   ),
                            // ),

                            Visibility(
                              visible: adminAcc,
                              child: const Text('Reassign To'),
                            ),
                            Visibility(
                              visible: adminAcc,
                              child: DropdownButtonFormField<String>(
                                value: dropdownValue3,
                                items: _employeesUserNames
                                    .toSet()
                                    .map<DropdownMenuItem<String>>(
                                        (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    dropdownValue3 = newValue!;
                                  });
                                },
                              ),
                            ),

                            Visibility(
                              visible: adminAcc,
                              child: TextField(
                                keyboardType: TextInputType.text,
                                controller: _commentController,
                                decoration: const InputDecoration(
                                  labelText: 'Reason for reallocation...',
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 10,
                            ),
                            ElevatedButton(
                              child: const Text('Reassign'),
                              onPressed: () async {
                                final String userComment =
                                    _commentController.text;
                                // final String depSelected = dropdownValue;
                                // final String managerAllocated = dropdownValue2;
                                final String attendeeAllocated = dropdownValue3;

                                if (_deptManagerController.text != '' ||
                                    _deptManagerController.text.isNotEmpty) {
                                  await _faultData
                                      ?.doc(documentSnapshot.id)
                                      .update({
                                    "reallocationComment": userComment,
                                    // "depAllocated": depSelected,
                                    // "managerAllocated": managerAllocated,
                                    "attendeeAllocated": attendeeAllocated,
                                    "faultResolved": false,
                                    "faultStage": 2,
                                  });
                                }
                                // else if (dropdownValue2 == 'Assign User...') {
                                //   Fluttertoast.showToast(
                                //       msg: 'Please allocate the fault to a new manager if necessary!',
                                //       gravity: ToastGravity.CENTER);
                                // }
                                else if (dropdownValue3 == 'Assign User...') {
                                  Fluttertoast.showToast(
                                      msg:
                                          'Please allocate the fault to a new fault attendee!',
                                      gravity: ToastGravity.CENTER);
                                } else if (_commentController.text != '' ||
                                    _commentController.text.isNotEmpty) {
                                  Fluttertoast.showToast(
                                      msg:
                                          'Please provide reasoning for your reallocation!',
                                      gravity: ToastGravity.CENTER);
                                } else {
                                  Fluttertoast.showToast(
                                      msg:
                                          'Please allocate the fault to a new attendee or manager and explain your reallocation!',
                                      gravity: ToastGravity.CENTER);
                                }

                                _commentController.text = '';
                                _depAllocationController.text = '';
                                dropdownValue = 'Select Department...';
                                _faultResolvedController = false;
                                _dateReportedController.text = '';

                                visStage1 = false;
                                visStage2 = false;
                                visStage3 = false;
                                visStage4 = false;
                                visStage4 = false;

                                Navigator.of(context).pop();
                              },
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              }));
    }

    _createBottomSheet();
  }

  Future<void> _managersReassignWorker(
      [DocumentSnapshot? documentSnapshot]) async {
    String dropdownValue = 'Select Department...';
    // String dropdownValue = documentSnapshot?['faultType'];
    String dropdownValue2 = 'Assign User...';

    //This checks the current state of the fault stage 5 is resolve stage
    int stageNum = documentSnapshot!['faultStage'];
    if (stageNum == 1) {
      visStage1 = true;
      visStage2 = false;
      visStage3 = false;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 2) {
      visStage1 = false;
      visStage2 = true;
      visStage3 = false;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 3) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = true;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 4) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = false;
      visStage4 = true;
      visStage5 = false;
    } else if (stageNum == 5) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = false;
      visStage4 = false;
      visStage5 = true;
    }

    _accountNumberController.text = documentSnapshot['accountNumber'];
    _addressController.text = documentSnapshot['address'];
    _descriptionController.text = documentSnapshot['faultDescription'];
    _deptManagerController.text = documentSnapshot['managerAllocated'];
    _commentController.text = '';
    _depAllocationController.text = documentSnapshot['depAllocated'];
    _faultResolvedController = documentSnapshot['faultResolved'];
    _dateReportedController.text = documentSnapshot['dateReported'];

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    void _createBottomSheet() async {
      showModalBottomSheet(
          context: context,
          builder: await showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (BuildContext ctx) {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(
                            top: 20,
                            left: 20,
                            right: 20,
                            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Visibility(
                              visible: (visStage1) && employeeAcc,
                              child: const Text(
                                  'Only Administrators may assign this fault.'),
                            ),

                            Visibility(
                              visible: managerAcc,
                              child:
                                  const Text('Return fault to administrator'),
                            ),
                            Visibility(
                              visible: adminAcc && visStage1,
                              child: DropdownButtonFormField<String>(
                                value: dropdownValue2,
                                items: _employeesUserNames
                                    .toSet()
                                    .map<DropdownMenuItem<String>>(
                                        (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    dropdownValue2 = newValue!;
                                  });
                                },
                              ),
                            ),

                            Visibility(
                              visible: employeeAcc,
                              child: const Text('Return fault to manager'),
                            ),
                            Visibility(
                              visible: (visStage2 || visStage3) &&
                                  (managerAcc || employeeAcc),
                              child: TextField(
                                keyboardType: TextInputType.text,
                                controller: _commentController,
                                decoration: const InputDecoration(
                                  labelText: 'Reason for return',
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),

                            Visibility(
                              visible: (visStage2 ||
                                      visStage3 ||
                                      visStage4 ||
                                      visStage5) &&
                                  managerAcc,
                              child: ElevatedButton(
                                child: const Text('Return Fault'),
                                onPressed: () async {
                                  final String userComment =
                                      _commentController.text;

                                  if (_commentController.text != '' ||
                                      _commentController.text.isNotEmpty) {
                                    await _faultData
                                        ?.doc(documentSnapshot.id)
                                        .update({
                                      "managerReturnCom": userComment,
                                      "faultStage": 1,
                                    });
                                  } else {
                                    Fluttertoast.showToast(
                                        msg:
                                            'Please explain why you want to return this fault to the admin to reassign',
                                        gravity: ToastGravity.CENTER);
                                  }

                                  _commentController.text = '';
                                  _depAllocationController.text = '';
                                  dropdownValue = 'Select Department...';
                                  _faultResolvedController = false;
                                  _dateReportedController.text = '';

                                  visStage1 = false;
                                  visStage2 = false;
                                  visStage3 = false;
                                  visStage4 = false;
                                  visStage4 = false;

                                  Navigator.of(context).pop();
                                },
                              ),
                            ), //button for managers to return a fault if it cannot be handled

                            Visibility(
                              visible: (visStage3 || visStage4) && employeeAcc,
                              child: ElevatedButton(
                                child: const Text('Return to manager'),
                                onPressed: () async {
                                  final String userComment =
                                      _commentController.text;

                                  if (_commentController.text != '' ||
                                      _commentController.text.isNotEmpty) {
                                    await _faultData
                                        ?.doc(documentSnapshot.id)
                                        .update({
                                      "attendeeReturnCom": userComment,
                                      "faultStage": 2,
                                    });
                                  } else {
                                    Fluttertoast.showToast(
                                        msg:
                                            'Please explain why you want to return this fault to your manager to reassign',
                                        gravity: ToastGravity.CENTER);
                                  }

                                  _commentController.text = '';
                                  _depAllocationController.text = '';
                                  dropdownValue = 'Select Department...';
                                  _faultResolvedController = false;
                                  _dateReportedController.text = '';

                                  visStage1 = false;
                                  visStage2 = false;
                                  visStage3 = false;
                                  visStage4 = false;
                                  visStage4 = false;

                                  Navigator.of(context).pop();
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              }));
    }

    _createBottomSheet();
  }

  Future<void> _returnFaultToAdmin([DocumentSnapshot? documentSnapshot]) async {
    String dropdownValue = 'Select Department...';
    // String dropdownValue = documentSnapshot?['faultType'];
    String dropdownValue2 = 'Assign User...';

    //This checks the current state of the fault stage 5 is resolve stage
    int stageNum = documentSnapshot!['faultStage'];
    if (stageNum == 1) {
      visStage1 = true;
      visStage2 = false;
      visStage3 = false;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 2) {
      visStage1 = false;
      visStage2 = true;
      visStage3 = false;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 3) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = true;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 4) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = false;
      visStage4 = true;
      visStage5 = false;
    } else if (stageNum == 5) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = false;
      visStage4 = false;
      visStage5 = true;
    }

    _accountNumberController.text = documentSnapshot['accountNumber'];
    _addressController.text = documentSnapshot['address'];
    _descriptionController.text = documentSnapshot['faultDescription'];
    _deptManagerController.text = documentSnapshot['managerAllocated'];
    _commentController.text = '';
    _depAllocationController.text = documentSnapshot['depAllocated'];
    _faultResolvedController = documentSnapshot['faultResolved'];
    _dateReportedController.text = documentSnapshot['dateReported'];

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    void _createBottomSheet() async {
      showModalBottomSheet(
          context: context,
          builder: await showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (BuildContext ctx) {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(
                            top: 20,
                            left: 20,
                            right: 20,
                            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Visibility(
                              visible: managerAcc,
                              child:
                                  const Text('Return fault to administrator'),
                            ),

                            Visibility(
                              visible: employeeAcc,
                              child: const Text('Return fault to manager'),
                            ),

                            Visibility(
                              visible: (visStage2 || visStage3) &&
                                  (managerAcc || employeeAcc),
                              child: TextField(
                                keyboardType: TextInputType.text,
                                controller: _commentController,
                                decoration: const InputDecoration(
                                  labelText: 'Reason for returning fault',
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),

                            Visibility(
                              visible: (visStage2 ||
                                      visStage3 ||
                                      visStage4 ||
                                      visStage5) &&
                                  managerAcc,
                              child: ElevatedButton(
                                child: const Text('Return Fault'),
                                onPressed: () async {
                                  final String userComment =
                                      _commentController.text;

                                  if (_commentController.text != '' ||
                                      _commentController.text.isNotEmpty) {
                                    await _faultData
                                        ?.doc(documentSnapshot.id)
                                        .update({
                                      "managerReturnCom": userComment,
                                      "faultStage": 1,
                                    });
                                  } else {
                                    Fluttertoast.showToast(
                                        msg:
                                            'Please explain why you want to return this fault to the admin to reassign',
                                        gravity: ToastGravity.CENTER);
                                  }

                                  _commentController.text = '';
                                  _depAllocationController.text = '';
                                  dropdownValue = 'Select Department...';
                                  _faultResolvedController = false;
                                  _dateReportedController.text = '';

                                  visStage1 = false;
                                  visStage2 = false;
                                  visStage3 = false;
                                  visStage4 = false;
                                  visStage4 = false;

                                  Navigator.of(context).pop();
                                },
                              ),
                            ), //button for managers to return a fault if it cannot be handled

                            Visibility(
                              visible: (visStage2 || visStage3 || visStage4) &&
                                  employeeAcc,
                              child: ElevatedButton(
                                child: const Text('Return to manager'),
                                onPressed: () async {
                                  final String userComment =
                                      _commentController.text;

                                  if (_commentController.text != '' ||
                                      _commentController.text.isNotEmpty) {
                                    await _faultData
                                        ?.doc(documentSnapshot.id)
                                        .update({
                                      "attendeeReturnCom": userComment,
                                      "attendeeAllocated": '',
                                      "faultStage": 1,
                                    });
                                  } else {
                                    Fluttertoast.showToast(
                                        msg:
                                            'Please explain why you want to return this fault to your manager to reassign',
                                        gravity: ToastGravity.CENTER);
                                  }

                                  _commentController.text = '';
                                  _depAllocationController.text = '';
                                  dropdownValue = 'Select Department...';
                                  _faultResolvedController = false;
                                  _dateReportedController.text = '';

                                  visStage1 = false;
                                  visStage2 = false;
                                  visStage3 = false;
                                  visStage4 = false;
                                  visStage4 = false;

                                  Navigator.of(context).pop();
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              }));
    }

    _createBottomSheet();
  }

  Future<void> _reassignDept([DocumentSnapshot? documentSnapshot]) async {
    String dropdownValue = 'Select Department...';
    _commentController.text = '';

    //This checks the current state of the fault stage 5 is resolve stage
    int stageNum = documentSnapshot!['faultStage'];
    if (stageNum == 1) {
      visStage1 = true;
      visStage2 = false;
      visStage3 = false;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 2) {
      visStage1 = false;
      visStage2 = true;
      visStage3 = false;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 3) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = true;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 4) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = false;
      visStage4 = true;
      visStage5 = false;
    } else if (stageNum == 5) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = false;
      visStage4 = false;
      visStage5 = true;
    }

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    void _createBottomSheet() async {
      showModalBottomSheet(
          context: context,
          builder: await showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (BuildContext ctx) {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(
                            top: 20,
                            left: 20,
                            right: 20,
                            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Visibility(
                              visible: adminAcc,
                              child: const Text('Department Allocation'),
                            ),
                            Visibility(
                              visible: adminAcc,
                              child: DropdownButtonFormField<String>(
                                value: dropdownValue,
                                items: _deptName
                                    .toSet()
                                    .map<DropdownMenuItem<String>>(
                                        (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    dropdownValue = newValue!;
                                  });
                                },
                              ),
                            ),
                            Visibility(
                              visible: adminAcc,
                              child: TextField(
                                keyboardType: TextInputType.text,
                                controller: _commentController,
                                decoration: const InputDecoration(
                                  labelText:
                                      'Reason for changing department...',
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            ElevatedButton(
                              child: const Text('Send to Department'),
                              onPressed: () async {
                                final String userComment =
                                    _commentController.text;
                                final String depSelected = dropdownValue;

                                if (dropdownValue != 'Select Department...' &&
                                    (_commentController.text != '' ||
                                        _commentController.text.isNotEmpty)) {
                                  await _faultData
                                      ?.doc(documentSnapshot.id)
                                      .update({
                                    "departmentSwitchComment": userComment,
                                    "faultType": depSelected,
                                    "depAllocated": depSelected,
                                    "faultResolved": false,
                                    "faultStage": 1,
                                  });
                                } else if (_commentController.text != '' ||
                                    _commentController.text.isNotEmpty) {
                                  Fluttertoast.showToast(
                                      msg:
                                          'Please provide reasoning for switching department!',
                                      gravity: ToastGravity.CENTER);
                                } else {
                                  Fluttertoast.showToast(
                                      msg:
                                          'Please select the department you wish to transfer this fault to!',
                                      gravity: ToastGravity.CENTER);
                                }

                                _commentController.text = '';
                                _depAllocationController.text = '';
                                dropdownValue = 'Select Department...';
                                _faultResolvedController = false;
                                _dateReportedController.text = '';

                                visStage1 = false;
                                visStage2 = false;
                                visStage3 = false;
                                visStage4 = false;
                                visStage4 = false;

                                Navigator.of(context).pop();
                              },
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              }));
    }

    _createBottomSheet();
  }
}
