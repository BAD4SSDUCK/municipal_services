import 'dart:convert';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as excel;
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'package:municipal_services/code/ImageUploading/image_upload_meter.dart';
import 'package:municipal_services/code/ImageUploading/image_upload_water.dart';
import 'package:municipal_services/code/ImageUploading/image_zoom_page.dart';
import 'package:municipal_services/code/MapTools/map_screen_prop.dart';
import 'package:municipal_services/code/PDFViewer/pdf_api.dart';
import 'package:municipal_services/code/PDFViewer/view_pdf.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';
import 'package:municipal_services/code/Reusable/push_notification_message.dart';
import 'package:municipal_services/code/NoticePages/notice_config_screen.dart';
import 'package:municipal_services/code/ReportGeneration/display_prop_report.dart';

import '../Models/prop_provider.dart';
import '../Models/property.dart';
//Capture Reading

class AllPropCapture extends StatefulWidget {
  final String? municipalityUserEmail;
  final String? districtId;
  final String municipalityId;
  final bool isLocalMunicipality;
  final bool isLocalUser;
  const AllPropCapture({
    super.key,
    this.municipalityUserEmail,
    this.districtId,
    required this.municipalityId,
    required this.isLocalMunicipality,
    required this.isLocalUser,
  });

  @override
  _AllPropCaptureState createState() => _AllPropCaptureState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

final User? user = auth.currentUser;
final uid = user?.uid;
final email = user?.email;
String userID = uid as String;
String userEmail = email as String;
DateTime now = DateTime.now();

String phoneNum = '';

String accountNumberAll = '';
String locationGivenAll = '';
// String eMeterNumber = '';
String accountNumberW = '';
String locationGivenW = '';
String wMeterNumber = '';
String addressForTrend = '';

String propPhoneNum = '';
String imageName = '';
String addressSnap = '';

bool visibilityState1 = true;
bool visibilityState2 = false;
bool adminAcc = false;
bool imgUploadCheck = false;

final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;

class FireStorageService extends ChangeNotifier {
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async {
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

// Future<String> _getImage(BuildContext context, String imagePath) async {
//   try {
//     String imageUrl =
//         await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
//     return imageUrl; // Returns the image URL
//   } catch (e) {
//     throw Exception('Failed to load image');
//   }
// }

Future<String> _getImageW(BuildContext context, String imagePath) async {
  try {
    String imageUrl =
        await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    return imageUrl; // Returns the image URL
  } catch (e) {
    throw Exception('Failed to load image');
  }
}
// final CollectionReference _propList =
// FirebaseFirestore.instance.collection('properties');

class _AllPropCaptureState extends State<AllPropCapture> {
  String? userEmail;
  String districtId = '';
  String municipalityId = '';
  bool isLocalMunicipality = false;
  bool isLocalUser = true;
  List<String> municipalities = []; // To hold the list of municipality names
  String? selectedMunicipality = "Select Municipality";
  CollectionReference? _propList;
  bool _isLoading = false;
  Property? property;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  void _onSubmit() {
    setState(() => _isLoading = true);
    Future.delayed(
      const Duration(seconds: 5),
      () => setState(() => _isLoading = false),
    );
  }

  @override
  void initState() {
    super.initState();
    print("Initializing UsersPropsAllState...");
    fetchUserDetails(); // Only fetch user details in initState
    _searchController.addListener(_onSearchChanged);
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    // searchText;
    // _allPropertyResults;
    // _allPropertyReport;
    // getPropertyStream();
    // searchResultsList();
    super.dispose();
  }

  Future<void> fetchUserDetails() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collectionGroup('users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          var userDoc = userSnapshot.docs.first;
          var userData = userDoc.data() as Map<String, dynamic>;
          var userPathSegments = userDoc.reference.path.split('/');
          if (mounted) {
            setState(() {
              if (userPathSegments.contains('districts')) {
                districtId = userPathSegments[1];
                municipalityId = userPathSegments[3];
                isLocalMunicipality = false;
              } else if (userPathSegments.contains('localMunicipalities')) {
                municipalityId = userPathSegments[1];
                isLocalMunicipality = true;
              }

              isLocalUser = userData['isLocalUser'] ?? false;
            });
          }
          if (isLocalMunicipality || isLocalUser) {
            fetchPropertiesForLocalMunicipality();
          } else {
            fetchMunicipalities();
          }
        }
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  Future<void> fetchMunicipalities() async {
    try {
      var municipalitiesSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .get();
      if (mounted) {
        setState(() {
          municipalities =
              municipalitiesSnapshot.docs.map((doc) => doc.id).toList();
          fetchPropertiesForAllMunicipalities();
        });
      }
    } catch (e) {
      print('Error fetching municipalities: $e');
    }
  }

  Future<void> fetchPropertiesForAllMunicipalities() async {
    try {
      QuerySnapshot propertiesSnapshot = selectedMunicipality == null ||
              selectedMunicipality == "Select Municipality"
          ? await FirebaseFirestore.instance
              .collectionGroup('properties')
              .where('districtId', isEqualTo: districtId)
              .get()
          : await FirebaseFirestore.instance
              .collection('districts')
              .doc(districtId)
              .collection('municipalities')
              .doc(selectedMunicipality!)
              .collection('properties')
              .get();
      if (mounted) {
        setState(() {
          _allPropertyResults = propertiesSnapshot.docs;
        });
      }
    } catch (e) {
      print('Error fetching properties: $e');
    }
  }

  Future<void> fetchPropertiesForLocalMunicipality() async {
    try {
      var propertiesSnapshot = await FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('properties')
          .get();
      if (mounted) {
        setState(() {
          _allPropertyResults = propertiesSnapshot.docs;
        });
      }
    } catch (e) {
      print('Error fetching properties: $e');
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
          _allPropertyResults =
              propertiesSnapshot.docs; // Store filtered properties
          print(
              "Number of properties fetched: ${_allPropertyResults.length}"); // Debugging to ensure properties are set
        });
      }
    } catch (e) {
      print('Error fetching properties for $municipality: $e');
    }
  }

  void checkAdmin() {
    getUsersStream();
    if (userRole == 'Admin' || userRole == 'Administrator') {
      adminAcc = true;
    } else {
      adminAcc = false;
    }
  }

  getUsersStream() async {
    try {
      // Use collectionGroup to query all 'users' subcollections across districts and municipalities
      QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collectionGroup('users').get();
      if (mounted) {
        setState(() {
          _allUserRolesResults = usersSnapshot.docs;
        });
      }
      getUserDetails(); // Call this after fetching the user data
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  getUserDetails() async {
    try {
      for (var userSnapshot in _allUserRolesResults) {
        if (userSnapshot.exists) {
          var userData = userSnapshot.data() as Map<String, dynamic>;
          String user =
              userData.containsKey('email') ? userData['email'].toString() : '';
          String role = userData.containsKey('userRole')
              ? userData['userRole'].toString()
              : 'Unknown';

          if (user == userEmail) {
            userRole = role;
            print('My Role is: $userRole');
            if (mounted) {
              setState(() {
                adminAcc = (userRole == 'Admin' || userRole == 'Administrator');
              });
              break;
            } // Stop loop if the matching user is found
          }
        }
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  // text fields' controllers
  final _accountNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaCodeController = TextEditingController();
  // final _meterNumberController = TextEditingController();
  // final _meterReadingController = TextEditingController();
  final _waterMeterController = TextEditingController();
  final _waterMeterReadingController = TextEditingController();
  final _cellNumberController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idNumberController = TextEditingController();

  String searchText = '';

  String formattedDate = DateFormat.MMMM().format(now);
  String formattedMonth =
      DateFormat.MMMM().format(now); //format for full Month by name
  String formattedDateMonth =
      DateFormat.MMMMd().format(now); //format for Day Month only

  final CollectionReference _listUserTokens =
      FirebaseFirestore.instance.collection('UserToken');

  // final CollectionReference _listNotifications =
  // FirebaseFirestore.instance.collection('Notifications');
  late final CollectionReference _listNotifications;
  final _headerController = TextEditingController();
  final _messageController = TextEditingController();

  List<String> usersNumbers = [];
  List<String> usersTokens = [];
  List<String> usersRetrieve = [];

  ///Methods and implementation for push notifications with firebase and specific device token saving
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  TextEditingController username = TextEditingController();
  TextEditingController title = TextEditingController();
  TextEditingController body = TextEditingController();
  String? mtoken = " ";

  ///This was made for testing a default message
  String title2 = "Outstanding Utilities Payment";
  String body2 =
      "Make sure you pay utilities before the end of this month or your services will be disconnected";

  String token = '';
  String notifyToken = '';

  String userRole = '';
  List _allUserRolesResults = [];
  bool visShow = true;
  bool visHide = false;
  bool adminAcc = false;

  bool imageLoadedE = false;
  bool imageLoadedW = false;

  int numTokens = 0;

  String dropdownValue = 'Select Month';
  List<String> dropdownMonths = [
    'Select Month',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  TextEditingController _searchController = TextEditingController();
  List _allPropertyResults = [];
  List _allPropertyReport = [];

  getPropertyStream() async {
    if (_propList != null) {
      var data = await _propList!.get();
      if (mounted) {
        setState(() {
          _allPropertyResults = data.docs;
        });
        searchResultsList();
      }
    }
  }

  _onSearchChanged() async {
    searchResultsList();
  }

  searchResultsList() async {
    var showResults = [];
    if (_searchController.text.isNotEmpty) {
      var searchLower = _searchController.text.toLowerCase();

      // Perform the search by filtering _allPropResults
      for (var propSnapshot in _allPropertyResults) {
        var address = propSnapshot['address'].toString().toLowerCase();
        var firstName = propSnapshot['firstName'].toString().toLowerCase();
        var lastName = propSnapshot['lastName'].toString().toLowerCase();
        var cellNumber = propSnapshot['cellNumber'].toString().toLowerCase();

        if (address.contains(searchLower) ||
            firstName.contains(searchLower) ||
            lastName.contains(searchLower) ||
            cellNumber.contains(searchLower)) {
          showResults.add(propSnapshot);
        }
      }
      if (mounted) {
        setState(() {
          _allPropertyResults =
              showResults; // Update state with filtered results
        });
      }
    } else {
      // If the search is cleared, reload the full property list
      if (isLocalUser) {
        await fetchPropertiesForLocalMunicipality();
      } else {
        await fetchPropertiesForAllMunicipalities();
      }
    }
  }

  Future<void> ensureDocumentExists(String cellNumber, String propertyAddress,
      String districtId, String municipalityId) async {
    print(
        'ensureDocumentExists called with: cellNumber = $cellNumber, propertyAddress = $propertyAddress');

    DocumentReference actionLogDocRef;

    if (isLocalMunicipality) {
      actionLogDocRef = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('actionLogs')
          .doc(cellNumber)
          .collection(propertyAddress)
          .doc(
              'actions'); // Reference a specific document in the 'actions' subcollection
    } else {
      actionLogDocRef = FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('actionLogs')
          .doc(cellNumber)
          .collection(propertyAddress)
          .doc('actions');
    }

    // Ensure the document exists by adding an initial record if necessary
    await actionLogDocRef.set(
        {'created': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  // Future<void> logEMeterReadingUpdate(
  //     String cellNumber,
  //     String address,
  //     String municipalityUserEmail,
  //     String districtId,
  //     String municipalityId,
  //     Map<String, dynamic> details) async {
  //   DocumentReference actionLogRef = FirebaseFirestore.instance
  //       .collection('districts')
  //       .doc(districtId)
  //       .collection('municipalities')
  //       .doc(municipalityId)
  //       .collection('actionLogs')
  //       .doc(userID)
  //       .collection(address)
  //       .doc();
  //
  //   // Ensure the document exists
  //   await actionLogRef.set(
  //     {'created': FieldValue.serverTimestamp()},
  //     SetOptions(merge: true),
  //   );
  //
  //   // Log the meter reading update action with the address
  //   await actionLogRef.collection('actions').add({
  //     'actionType': 'Electricity Meter Reading Update',
  //     'uploader': municipalityUserEmail,
  //     'details': details,
  //     'address': address, // Include the property address in the log
  //     'timestamp': FieldValue.serverTimestamp(),
  //     'description':
  //         '$municipalityUserEmail updated electricity meter readings for property at $address',
  //   });
  // }

  Future<void> logWMeterReadingUpdate(
      String cellNumber,
      String propertyAddress,
      String municipalityUserEmail,
      String districtId,
      String municipalityId,
      Map<String, dynamic> details) async {
    // Ensure the document exists before logging
    await ensureDocumentExists(
        cellNumber, districtId, municipalityId, propertyAddress);

    DocumentReference actionLogDocRef;

    if (isLocalMunicipality) {
      actionLogDocRef = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('actionLogs')
          .doc(cellNumber)
          .collection(propertyAddress)
          .doc('actions');
    } else {
      actionLogDocRef = FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('actionLogs')
          .doc(cellNumber)
          .collection(propertyAddress)
          .doc('actions');
    }

    await actionLogDocRef.set({
      'actionType': 'Water Meter Reading Update',
      'uploader': municipalityUserEmail,
      'details': details,
      'address': propertyAddress,
      'timestamp': FieldValue.serverTimestamp(),
      'description':
          '$municipalityUserEmail updated water meter readings for property at $propertyAddress',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(180.0),
        child: AppBar(
          title: const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text(
              'Reading Capture List',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.green,
          flexibleSpace: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 90.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.file_copy_outlined,
                                color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReportBuilderProps(
                                    municipalityUserEmail: userEmail,
                                    isLocalMunicipality: isLocalMunicipality,
                                    districtId: districtId,
                                    isLocalUser: isLocalUser,
                                  ),
                                ),
                              );
                            },
                          ),
                          Text(
                            'Report Generator',
                            style: GoogleFonts.jacquesFrancois(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Show dropdown only for district-level users
                  if (!isLocalMunicipality && !isLocalUser)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 40),
                        child: DropdownButton<String>(
                          value: selectedMunicipality,
                          hint: const Text('Select Municipality'),
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            if (mounted) {
                              setState(() {
                                selectedMunicipality = newValue;
                                if (selectedMunicipality == null ||
                                    selectedMunicipality ==
                                        "Select Municipality") {
                                  fetchPropertiesForAllMunicipalities();
                                } else {
                                  fetchPropertiesByMunicipality(newValue!);
                                }
                              });
                            }
                          },
                          items: [
                            const DropdownMenuItem<String>(
                              value: "Select Municipality",
                              child: Align(
                                alignment: Alignment.center,
                                child: Text("Select Municipality"),
                              ),
                            ),
                            ...municipalities.map((String municipality) {
                              return DropdownMenuItem<String>(
                                value: municipality,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Text(municipality),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        child: Column(
          children: [
            SearchBar(
              controller: _searchController,
              padding: const MaterialStatePropertyAll<EdgeInsets>(
                  EdgeInsets.symmetric(horizontal: 16.0)),
              leading: const Icon(Icons.search),
              hintText: "Search",
              onChanged: (value) async {
                if (mounted) {
                  setState(() {
                    searchText = value;
                  });
                }
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: propertyCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget propertyCard() {
    if (_allPropertyResults.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          // Refocus on keyboard listener when tapping within the list
          _focusNode.requestFocus();
        },
        child: KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent) {
              final double pageScrollAmount =
                  _scrollController.position.viewportDimension;

              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                _scrollController.animateTo(
                  _scrollController.offset + 50,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                _scrollController.animateTo(
                  _scrollController.offset - 50,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
                _scrollController.animateTo(
                  _scrollController.offset + pageScrollAmount,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
                _scrollController.animateTo(
                  _scrollController.offset - pageScrollAmount,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                );
              }
            }
          },
          child: Scrollbar(
            controller: _scrollController,
            thickness: 12, // Customize the thickness of the scrollbar
            radius: const Radius.circular(8), // Rounded edges for the scrollbar
            thumbVisibility: true,
            trackVisibility: true, // Makes the track visible as well
            interactive: true,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _allPropertyResults.length,
              itemBuilder: (context, index) {
                property = Property(
                    accountNo: _allPropertyResults[index]['accountNumber'],
                    address: _allPropertyResults[index]['address'],
                    areaCode: _allPropertyResults[index]['areaCode'],
                    cellNum: _allPropertyResults[index]['cellNumber'],
                    eBill: _allPropertyResults[index]['eBill'],
                    firstName: _allPropertyResults[index]['firstName'],
                    lastName: _allPropertyResults[index]['lastName'],
                    id: _allPropertyResults[index]['idNumber'],
                    // imgStateE: _allPropertyResults[index]['imgStateE'],
                    imgStateW: _allPropertyResults[index]['imgStateW'],
                    // meterNum: _allPropertyResults[index]['meter_number'],
                    // meterReading: _allPropertyResults[index]['meter_reading'],
                    waterMeterNum: _allPropertyResults[index]
                        ['water_meter_number'],
                    waterMeterReading: _allPropertyResults[index]
                        ['water_meter_reading'],
                    uid: _allPropertyResults[index]['userID'],
                    districtId: districtId,
                    municipalityId: municipalityId,
                    isLocalMunicipality: _allPropertyResults[index]
                        ['isLocalMunicipality']);
                // eMeterNumber = _allPropertyResults[index]['meter_number'];
                wMeterNumber = _allPropertyResults[index]['water_meter_number'];
                propPhoneNum = _allPropertyResults[index]['cellNumber'];

                return Card(
                  margin: const EdgeInsets.only(
                      left: 10, right: 10, top: 0, bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Property Information',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          'Account Number: ${_allPropertyResults[index]['accountNumber']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          'Street Address: ${_allPropertyResults[index]['address']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          'Area Code: ${_allPropertyResults[index]['areaCode']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        // Text(
                        //   'Meter Number: ${_allPropertyResults[index]['meter_number']}',
                        //   style: const TextStyle(
                        //       fontSize: 16, fontWeight: FontWeight.w400),
                        // ),
                        // const SizedBox(
                        //   height: 5,
                        // ),
                        // Text(
                        //   'Meter Reading: ${_allPropertyResults[index]['meter_reading']}',
                        //   style: const TextStyle(
                        //       fontSize: 16, fontWeight: FontWeight.w400),
                        // ),
                        // const SizedBox(
                        //   height: 5,
                        // ),
                        Text(
                          'Water Meter Number: ${_allPropertyResults[index]['water_meter_number']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          'Water Meter Reading: ${_allPropertyResults[index]['water_meter_reading']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          'Phone Number: ${_allPropertyResults[index]['cellNumber']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          'First Name: ${_allPropertyResults[index]['firstName']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          'Surname: ${_allPropertyResults[index]['lastName']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        const Center(
                          child: Text(
                            'Water Meter Photos',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Center(
                          child: BasicIconButtonGrey(
                            onPress: () async {
                              try {
                                // If the user is not a local municipality user (i.e., district-level user)
                                if (!isLocalUser && !isLocalMunicipality) {
                                  if (selectedMunicipality == null ||
                                      selectedMunicipality ==
                                          "Select Municipality") {
                                    Fluttertoast.showToast(
                                      msg:
                                          "Please select a municipality first!",
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.CENTER,
                                    );
                                    return; // Stop execution if no municipality is selected
                                  }
                                }

                                // Determine the appropriate municipality context
                                String municipalityContext =
                                    isLocalMunicipality || isLocalUser
                                        ? municipalityId
                                        : selectedMunicipality!;

                                if (municipalityContext.isEmpty) {
                                  Fluttertoast.showToast(
                                    msg:
                                        "Invalid municipality selection or missing municipality.",
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.CENTER,
                                  );
                                  return;
                                }

                                // Ensure necessary property details are not null
                                String? cellNumber =
                                    _allPropertyResults[index]['cellNumber'];
                                String? address =
                                    _allPropertyResults[index]['address'];
                                String? meterNumber = _allPropertyResults[index]
                                    ['water_meter_number'];

                                // Print statements for debugging
                                print(
                                    "cellNumber: $cellNumber, address: $address, meterNumber: $meterNumber");

                                if (cellNumber == null ||
                                    address == null ||
                                    meterNumber == null) {
                                  Fluttertoast.showToast(
                                    msg:
                                        "Incomplete property details. Cannot view the image.",
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.CENTER,
                                  );
                                  return;
                                }

                                imageName =
                                    'files/meters/$formattedDate/${_allPropertyResults[index]['cellNumber']}/water/${_allPropertyResults[index]['water_meter_number']}.jpg';
                                addressSnap =
                                    _allPropertyResults[index]['address'];
                                print(
                                    "Navigating to ImageZoomPage with details:");
                                print("imageName: $imageName");
                                print("addressSnap: $addressSnap");
                                print(
                                    "municipalityContext: $municipalityContext");
                                print("municipality email: $userEmail");
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ImageZoomPage(
                                              imageName: imageName,
                                              addressSnap: addressSnap,
                                              municipalityUserEmail: userEmail,
                                              isLocalMunicipality:
                                                  widget.isLocalMunicipality,
                                              districtId: districtId,
                                              municipalityId: municipalityId,
                                              isLocalUser: isLocalUser,
                                            )));
                              } catch (e) {
                                print(
                                    "Error in 'View Uploaded Image' button: $e");
                                Fluttertoast.showToast(
                                  msg: "Error: Unable to view uploaded image.",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.CENTER,
                                );
                              }
                            },
                            labelText: 'View & Capture Readings',
                            fSize: 16,
                            faIcon: const FaIcon(
                              Icons.zoom_in,
                            ),
                            fgColor: Colors.blue,
                            btSize: const Size(100, 38),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                BasicIconButtonGrey(
                                  onPress: () async {
                                    try {
                                      // Ensure the municipality context is valid for district users
                                      if (!isLocalUser &&
                                          !isLocalMunicipality) {
                                        if (selectedMunicipality == null ||
                                            selectedMunicipality ==
                                                "Select Municipality") {
                                          Fluttertoast.showToast(
                                            msg:
                                                "Please select a municipality first!",
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.CENTER,
                                          );
                                          return; // Stop execution if no municipality is selected
                                        }
                                      }

                                      // Determine the appropriate municipality context
                                      String municipalityContext =
                                          isLocalMunicipality || isLocalUser
                                              ? municipalityId
                                              : selectedMunicipality!;

                                      if (municipalityContext.isEmpty) {
                                        Fluttertoast.showToast(
                                          msg:
                                              "Invalid municipality selection or missing municipality.",
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.CENTER,
                                        );
                                        return;
                                      }
                                      accountNumberAll =
                                          _allPropertyResults[index]
                                              ['accountNumber'];
                                      locationGivenAll =
                                          _allPropertyResults[index]['address'];
                                      if (locationGivenAll == null ||
                                          accountNumberAll == null) {
                                        Fluttertoast.showToast(
                                          msg:
                                              "Error: Property information is missing.",
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.CENTER,
                                        );
                                        return;
                                      }
                                      print(
                                          "Navigating to MapScreenProp with:");
                                      print("Address: $locationGivenAll");
                                      print("Account Number: $accountNumber");
                                      print(
                                          "Municipality Context: $municipalityContext");
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  MapScreenProp(
                                                    propAddress:
                                                        locationGivenAll,
                                                    propAccNumber:
                                                        accountNumberAll,
                                                  )));
                                    } catch (e) {
                                      print("Error in Map button logic: $e");
                                      Fluttertoast.showToast(
                                        msg: "Error: Unable to open map.",
                                        toastLength: Toast.LENGTH_SHORT,
                                        gravity: ToastGravity.CENTER,
                                      );
                                    }
                                  },
                                  labelText: 'Map',
                                  fSize: 16,
                                  faIcon: const FaIcon(
                                    Icons.map,
                                  ),
                                  fgColor: Colors.green,
                                  btSize: const Size(100, 38),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // Future<void> updateImgCheckE(bool imgCheck,
  //     [DocumentSnapshot? documentSnapshot]) async {
  //   if (documentSnapshot != null) {
  //     await _propList?.doc(documentSnapshot.id).update({
  //       "imgStateE": imgCheck,
  //     });
  //   }
  //   imgCheck = false;
  // }

  Future<void> updateImgCheckW(bool imgCheck,
      [DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      await _propList?.doc(documentSnapshot.id).update({
        "imgStateW": imgCheck,
      });
    }
    imgCheck = false;
  }

  Future<void> _notifyThisUser([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      username.text = documentSnapshot.id;
    }

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    void _createBottomSheet() async {
      Future<void> future = showModalBottomSheet(
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
                            visible: visShow,
                            child: TextField(
                              controller: title,
                              decoration: const InputDecoration(
                                  labelText: 'Message Header'),
                            ),
                          ),
                          Visibility(
                            visible: visShow,
                            child: TextField(
                              controller: body,
                              decoration:
                                  const InputDecoration(labelText: 'Message'),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          ElevatedButton(
                            child: const Text('Send Notification'),
                            onPressed: () async {
                              Provider.of<PropertyProvider>(context,
                                      listen: false)
                                  .selectProperty(property!);

                              DateTime now = DateTime.now();
                              String formattedDate =
                                  DateFormat('yyyy-MM-dd – kk:mm').format(now);

                              final String tokenSelected = notifyToken;
                              final String? userNumber = documentSnapshot?.id;
                              final String notificationTitle = title.text;
                              final String notificationBody = body.text;
                              final String notificationDate = formattedDate;
                              const bool readStatus = false;

                              if (tokenSelected.isNotEmpty) {
                                if (title.text.isNotEmpty ||
                                    body.text.isNotEmpty) {
                                  await _listNotifications.add({
                                    "token": tokenSelected,
                                    "user": userNumber,
                                    "title": notificationTitle,
                                    "body": notificationBody,
                                    "read": readStatus,
                                    "date": notificationDate,
                                    "level": 'severe',
                                  });

                                  String titleText = title.text;
                                  String bodyText = body.text;

                                  if (userNumber != null &&
                                      userNumber.isNotEmpty) {
                                    DocumentSnapshot snap;

                                    // Fetch token from either local municipalities or district
                                    if (property!.isLocalMunicipality) {
                                      snap = await FirebaseFirestore.instance
                                          .collection('localMunicipalities')
                                          .doc(municipalityId)
                                          .collection('UserToken')
                                          .doc(userNumber)
                                          .get();
                                    } else {
                                      snap = await FirebaseFirestore.instance
                                          .collection('districts')
                                          .doc(districtId)
                                          .collection('municipalities')
                                          .doc(municipalityId)
                                          .collection('UserToken')
                                          .doc(userNumber)
                                          .get();
                                    }

                                    String token = snap['token'];
                                    print(
                                        'The phone number is retrieved as ::: $userNumber');
                                    print(
                                        'The token is retrieved as ::: $token');
                                    sendPushMessage(token, titleText, bodyText);
                                    Fluttertoast.showToast(
                                      msg:
                                          'The user has been sent the notification!',
                                      gravity: ToastGravity.CENTER,
                                    );
                                  }
                                } else {
                                  Fluttertoast.showToast(
                                    msg:
                                        'Please Fill Header and Message of the notification!',
                                    gravity: ToastGravity.CENTER,
                                  );
                                }

                                username.text = '';
                                title.text = '';
                                body.text = '';
                                _headerController.text = '';
                                _messageController.text = '';

                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ));
    }

    _createBottomSheet();
  }

  Widget firebasePropertyCard(
      CollectionReference<Object?> propertiesDataStream) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: propertiesDataStream.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              ///this call is to display all details for all users but is only displaying for the current user account.
              ///it can be changed to display all users for the staff to see if the role is set to all later on.
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                    streamSnapshot.data!.docs[index];

                // eMeterNumber = documentSnapshot['meter_number'];
                wMeterNumber = documentSnapshot['water_meter_number'];
                propPhoneNum = documentSnapshot['cellNumber'];

                String billMessage;

                ///A check for if payment is outstanding or not
                if (documentSnapshot['eBill'] != '' ||
                    documentSnapshot['eBill'] != 'R0,000.00' ||
                    documentSnapshot['eBill'] != 'R0.00' ||
                    documentSnapshot['eBill'] != 'R0' ||
                    documentSnapshot['eBill'] != '0') {
                  billMessage =
                      'Utilities bill outstanding: ${documentSnapshot['eBill']}';
                } else {
                  billMessage = 'No outstanding payments';
                }

                if ((documentSnapshot['address'].trim().toLowerCase())
                    .contains(_searchController.text.trim().toLowerCase())) {
                  return Card(
                    margin: const EdgeInsets.only(
                        left: 10, right: 10, top: 0, bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'Property Information',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            'Account Number: ${documentSnapshot['accountNumber']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Street Address: ${documentSnapshot['address']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Area Code: ${documentSnapshot['areaCode']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          // Text(
                          //   'Meter Number: ${documentSnapshot['meter_number']}',
                          //   style: const TextStyle(
                          //       fontSize: 16, fontWeight: FontWeight.w400),
                          // ),
                          // const SizedBox(
                          //   height: 5,
                          // ),
                          // Text(
                          //   'Meter Reading: ${documentSnapshot['meter_reading']}',
                          //   style: const TextStyle(
                          //       fontSize: 16, fontWeight: FontWeight.w400),
                          // ),
                          // const SizedBox(
                          //   height: 5,
                          // ),
                          Text(
                            'Water Meter Number: ${documentSnapshot['water_meter_number']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Water Meter Reading: ${documentSnapshot['water_meter_reading']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Phone Number: ${documentSnapshot['cellNumber']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            'First Name: ${documentSnapshot['firstName']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Surname: ${documentSnapshot['last name']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            'ID Number: ${documentSnapshot['idNumber']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(
                            height: 20,
                          ),

                          //const Center(
                          //   child: Text(
                          //     'Electricity Meter Reading Photo',
                          //     style: TextStyle(
                          //         fontSize: 16, fontWeight: FontWeight.w700),
                          //   ),
                          // ),
                          // const SizedBox(
                          //   height: 5,
                          // ),
                          // Column(
                          //   children: [
                          //     Row(
                          //       mainAxisAlignment: MainAxisAlignment.center,
                          //       crossAxisAlignment: CrossAxisAlignment.center,
                          //       children: [
                          //         BasicIconButtonGrey(
                          //           onPress: () async {
                          //             Provider.of<PropertyProvider>(context, listen: false).selectProperty(property!);
                          //
                          //             eMeterNumber =
                          //                 documentSnapshot['meter_number'];
                          //             propPhoneNum =
                          //                 documentSnapshot['cellNumber'];
                          //             showDialog(
                          //                 barrierDismissible: false,
                          //                 context: context,
                          //                 builder: (context) {
                          //                   return AlertDialog(
                          //                     title: const Text(
                          //                         "Upload Electricity Meter"),
                          //                     content: const Text(
                          //                         "Uploading a new image will replace current image!\n\nAre you sure?"),
                          //                     actions: [
                          //                       IconButton(
                          //                         onPressed: () {
                          //                           Navigator.pop(context);
                          //                         },
                          //                         icon: const Icon(
                          //                           Icons.cancel,
                          //                           color: Colors.red,
                          //                         ),
                          //                       ),
                          //                       IconButton(
                          //                         onPressed: () async {
                          //                           Provider.of<PropertyProvider>(context, listen: false).selectProperty(property!);
                          //
                          //                           Navigator.pop(context);
                          //                           Fluttertoast.showToast(
                          //                               msg:
                          //                                   "Uploading a new image\nwill replace current image!");
                          //                           Navigator.push(
                          //                               context,
                          //                               MaterialPageRoute(
                          //                                   builder: (context) =>
                          //                                       ImageUploadMeter(
                          //                                         userNumber:
                          //                                             propPhoneNum,
                          //                                         meterNumber:
                          //                                             eMeterNumber,
                          //                                         municipalityUserEmail:
                          //                                             userEmail,
                          //
                          //                                       )));
                          //                         },
                          //                         icon: const Icon(
                          //                           Icons.done,
                          //                           color: Colors.green,
                          //                         ),
                          //                       ),
                          //                     ],
                          //                   );
                          //                 });
                          //           },
                          //           labelText: 'Photo',
                          //           fSize: 16,
                          //           faIcon: const FaIcon(
                          //             Icons.camera_alt,
                          //           ),
                          //           fgColor: Colors.black38,
                          //           btSize: const Size(100, 38),
                          //         ),
                          //         BasicIconButtonGrey(
                          //           onPress: () async {
                          //             Provider.of<PropertyProvider>(context, listen: false).selectProperty(property!);
                          //
                          //             _updateE(documentSnapshot);
                          //           },
                          //           labelText: 'Capture',
                          //           fSize: 16,
                          //           faIcon: const FaIcon(
                          //             Icons.edit,
                          //           ),
                          //           fgColor: Theme.of(context).primaryColor,
                          //           btSize: const Size(100, 38),
                          //         ),
                          //       ],
                          //     )
                          //   ],
                          // ),
                          // const SizedBox(height: 5),
                          // FutureBuilder<String>(
                          //     future: _getImage(context,
                          //         'files/meters/$formattedMonth/$propPhoneNum/${property?.address}/electricity/$eMeterNumber.jpg'),
                          //     builder: (context, snapshot) {
                          //       if (snapshot.hasData &&
                          //           snapshot.connectionState ==
                          //               ConnectionState.done) {
                          //         return GestureDetector(
                          //           onTap: () {
                          //             final imageProvider =
                          //                 NetworkImage(snapshot.data!);
                          //             showImageViewer(context, imageProvider);
                          //           },
                          //           child: Container(
                          //             margin: const EdgeInsets.only(bottom: 5),
                          //             height: 180,
                          //             child: Card(
                          //               color: Colors.white54,
                          //               semanticContainer: true,
                          //               clipBehavior:
                          //                   Clip.antiAliasWithSaveLayer,
                          //               shape: RoundedRectangleBorder(
                          //                 borderRadius:
                          //                     BorderRadius.circular(10.0),
                          //               ),
                          //               elevation: 0,
                          //               margin: const EdgeInsets.all(10.0),
                          //               child: Center(
                          //                 // Ensuring the image is centered within the card
                          //                 child: Image.network(snapshot.data!,
                          //                     fit: BoxFit.cover),
                          //               ),
                          //             ),
                          //           ),
                          //         );
                          //       } else if (snapshot.hasError) {
                          //         return const Padding(
                          //           padding: EdgeInsets.all(20.0),
                          //           child: Column(
                          //             mainAxisSize: MainAxisSize.min,
                          //             children: [
                          //               Text('Image not yet uploaded.'),
                          //               SizedBox(height: 10),
                          //               FaIcon(Icons.camera_alt),
                          //             ],
                          //           ),
                          //         );
                          //       } else {
                          //         return Container(
                          //           height: 180,
                          //           margin: const EdgeInsets.all(10.0),
                          //           child: const Center(
                          //               child: CircularProgressIndicator()),
                          //         );
                          //       }
                          //     }),

                          ///Image display item needs to get the reference from the firestore using the users uploaded meter connection
                          // InkWell(
                          //   ///onTap allows to open image upload page if user taps on the image.
                          //   ///Can be later changed to display the picture zoomed in if user taps on it.
                          //   onTap: () {
                          //     eMeterNumber = documentSnapshot['meter number'];
                          //     propPhoneNum = documentSnapshot['cell number'];
                          //     showDialog(
                          //         barrierDismissible: false,
                          //         context: context,
                          //         builder: (context) {
                          //           return AlertDialog(
                          //             title: const Text("Upload Electricity Meter"),
                          //             content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
                          //             actions: [
                          //               IconButton(
                          //                 onPressed: () {
                          //                   Navigator.pop(context);
                          //                 },
                          //                 icon: const Icon(
                          //                   Icons.cancel,
                          //                   color: Colors.red,
                          //                 ),
                          //               ),
                          //               IconButton(
                          //                 onPressed: () async {
                          //                   Navigator.pop(context);
                          //                   Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
                          //                   Navigator.push(context, MaterialPageRoute(builder: (context) =>
                          //                               ImageUploadMeter(userNumber: propPhoneNum, meterNumber: eMeterNumber,)));
                          //                 },
                          //                 icon: const Icon(
                          //                   Icons.done,
                          //                   color: Colors.green,
                          //                 ),
                          //               ),
                          //             ],
                          //           );
                          //         });
                          //   },
                          //
                          //   child: Center(
                          //     child: Container(
                          //       margin: const EdgeInsets.only(bottom: 5),
                          //       // height: 300,
                          //       // width: 300,
                          //       child: Center(
                          //         child: Card(
                          //           color: Colors.grey,
                          //           semanticContainer: true,
                          //           clipBehavior: Clip.antiAliasWithSaveLayer,
                          //           shape: RoundedRectangleBorder(
                          //             borderRadius: BorderRadius.circular(10.0),
                          //           ),
                          //           elevation: 0,
                          //           margin: const EdgeInsets.all(10.0),
                          //           child: FutureBuilder<dynamic>(
                          //               future: _getImage(
                          //                 ///Firebase image location must be changed to display image based on the meter number
                          //                   context, 'files/meters/$formattedDate/$propPhoneNum/electricity/$eMeterNumber.jpg'),
                          //               builder: (context, AsyncSnapshot<dynamic> snapshot) {
                          //                 if (snapshot.hasError) {
                          //                   imgUploadCheck = false;
                          //                   updateImgCheckE(imgUploadCheck, documentSnapshot);
                          //                   return const Padding(
                          //                     padding: EdgeInsets.all(20.0),
                          //                     child: Column(
                          //                       mainAxisSize: MainAxisSize.min,
                          //                       children: [
                          //                         Text('Image not yet uploaded.',),
                          //                         SizedBox(height: 10,),
                          //                         FaIcon(Icons.camera_alt,),
                          //                       ],
                          //                     ),
                          //                   );
                          //                 }
                          //                 if (snapshot.connectionState == ConnectionState.done) {
                          //                   // imgUploadCheck = true;
                          //                   updateImgCheckE(imgUploadCheck, documentSnapshot);
                          //                   return Column(
                          //                     mainAxisSize: MainAxisSize.min,
                          //                     children: [
                          //                       SizedBox(
                          //                         height: 300,
                          //                         width: 300,
                          //                         child: snapshot.data,
                          //                       ),
                          //                     ],
                          //                   );
                          //                 }
                          //                 if (snapshot.connectionState == ConnectionState.waiting) {
                          //                   return Container(
                          //                     child: const Padding(
                          //                       padding: EdgeInsets.all(5.0),
                          //                       child: CircularProgressIndicator(),
                          //                     ),);
                          //                 }
                          //                 return Container();
                          //               }
                          //           ),
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          // const SizedBox(
                          //   height: 10,
                          // ),

                          const Center(
                            child: Text(
                              'Water Meter Reading Photo',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  BasicIconButtonGrey(
                                    onPress: () async {
                                      Provider.of<PropertyProvider>(context,
                                              listen: false)
                                          .selectProperty(property!);

                                      wMeterNumber = documentSnapshot[
                                          'water_meter_number'];
                                      propPhoneNum =
                                          documentSnapshot['cellNumber'];
                                      String propertyAddress =
                                          documentSnapshot['address'];
                                      showDialog(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: const Text(
                                                  "Upload Water Meter"),
                                              content: const Text(
                                                  "Uploading a new image will replace current image!\n\nAre you sure?"),
                                              actions: [
                                                IconButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  icon: const Icon(
                                                    Icons.cancel,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () async {
                                                    Provider.of<PropertyProvider>(
                                                            context,
                                                            listen: false)
                                                        .selectProperty(
                                                            property!);

                                                    Fluttertoast.showToast(
                                                        msg:
                                                            "Uploading a new image\nwill replace current image!");
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                ImageUploadWater(
                                                                  userNumber:
                                                                      propPhoneNum,
                                                                  meterNumber:
                                                                      wMeterNumber,
                                                                  propertyAddress:
                                                                      propertyAddress, // Pass property address
                                                                  districtId:
                                                                      districtId, // Pass districtId
                                                                  municipalityId:
                                                                      municipalityId,
                                                                  isLocalMunicipality:
                                                                      widget
                                                                          .isLocalMunicipality,
                                                                  isLocalUser:
                                                                      isLocalUser,
                                                                )));
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
                                    labelText: 'Photo',
                                    fSize: 16,
                                    faIcon: const FaIcon(
                                      Icons.camera_alt,
                                    ),
                                    fgColor: Colors.black38,
                                    btSize: const Size(100, 38),
                                  ),
                                  BasicIconButtonGrey(
                                    onPress: () async {
                                      Provider.of<PropertyProvider>(context,
                                              listen: false)
                                          .selectProperty(property!);

                                      _updateW(documentSnapshot);
                                    },
                                    labelText: 'Capture',
                                    fSize: 16,
                                    faIcon: const FaIcon(
                                      Icons.edit,
                                    ),
                                    fgColor: Theme.of(context).primaryColor,
                                    btSize: const Size(100, 38),
                                  ),
                                ],
                              )
                            ],
                          ),
                          // FutureBuilder<String>(
                          //     future: _getImageW(context,
                          //         'files/meters/$formattedMonth/$propPhoneNum/${property?.address}/water/$wMeterNumber.jpg'),
                          //     builder: (context, snapshot) {
                          //       if (snapshot.hasData &&
                          //           snapshot.connectionState ==
                          //               ConnectionState.done) {
                          //         return GestureDetector(
                          //           onTap: () {
                          //             final imageProvider =
                          //                 NetworkImage(snapshot.data!);
                          //             showImageViewer(context, imageProvider);
                          //           },
                          //           child: Container(
                          //             margin: const EdgeInsets.only(bottom: 5),
                          //             height: 180,
                          //             child: Card(
                          //               color: Colors.white54,
                          //               semanticContainer: true,
                          //               clipBehavior:
                          //                   Clip.antiAliasWithSaveLayer,
                          //               shape: RoundedRectangleBorder(
                          //                 borderRadius:
                          //                     BorderRadius.circular(10.0),
                          //               ),
                          //               elevation: 0,
                          //               margin: const EdgeInsets.all(10.0),
                          //               child: Center(
                          //                 // Ensuring the image is centered within the card
                          //                 child: Image.network(snapshot.data!,
                          //                     fit: BoxFit.cover),
                          //               ),
                          //             ),
                          //           ),
                          //         );
                          //       } else if (snapshot.hasError) {
                          //         return const Padding(
                          //           padding: EdgeInsets.all(20.0),
                          //           child: Column(
                          //             mainAxisSize: MainAxisSize.min,
                          //             children: [
                          //               Text('Image not yet uploaded.'),
                          //               SizedBox(height: 10),
                          //               FaIcon(Icons.camera_alt),
                          //             ],
                          //           ),
                          //         );
                          //       } else {
                          //         return Container(
                          //           height: 180,
                          //           margin: const EdgeInsets.all(10.0),
                          //           child: const Center(
                          //               child: CircularProgressIndicator()),
                          //         );
                          //       }
                          //     }),
                          InkWell(
                            ///onTap allows to open image upload page if user taps on the image.
                            ///Can be later changed to display the picture zoomed in if user taps on it.
                            onTap: () {
                              String propertyAddress =
                                  documentSnapshot['address'];
                              wMeterNumber =
                                  documentSnapshot['water meter number'];
                              propPhoneNum = documentSnapshot['cell number'];
                              showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text("Upload Water Meter"),
                                      content: const Text(
                                          "Uploading a new image will replace current image!\n\nAre you sure?"),
                                      actions: [
                                        IconButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          icon: const Icon(
                                            Icons.cancel,
                                            color: Colors.red,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () async {
                                            Provider.of<PropertyProvider>(
                                                    context,
                                                    listen: false)
                                                .selectProperty(property!);
                                            Fluttertoast.showToast(
                                                msg:
                                                    "Uploading a new image\nwill replace current image!");
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        ImageUploadWater(
                                                          userNumber:
                                                              propPhoneNum,
                                                          meterNumber:
                                                              wMeterNumber,
                                                          propertyAddress:
                                                              propertyAddress, // Pass property address
                                                          districtId:
                                                              districtId, // Pass districtId
                                                          municipalityId:
                                                              municipalityId,
                                                          isLocalMunicipality:
                                                              isLocalMunicipality,
                                                          isLocalUser:
                                                              isLocalUser,
                                                        )));
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

                            child: Center(
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 5),
                                // height: 300,
                                // width: 300,
                                child: Center(
                                  child: Card(
                                    color: Colors.grey,
                                    semanticContainer: true,
                                    clipBehavior: Clip.antiAliasWithSaveLayer,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    elevation: 0,
                                    margin: const EdgeInsets.all(10.0),
                                    child: FutureBuilder<dynamic>(
                                        future: _getImageW(

                                            ///Firebase image location must be changed to display image based on the meter number
                                            context,
                                            'files/meters/$formattedMonth/$propPhoneNum/${property?.address}/water/$wMeterNumber.jpg'),
                                        //$meterNumber
                                        builder: (context,
                                            AsyncSnapshot<dynamic> snapshot) {
                                          if (snapshot.hasError) {
                                            imgUploadCheck = false;
                                            updateImgCheckW(imgUploadCheck,
                                                documentSnapshot);
                                            return const Padding(
                                              padding: EdgeInsets.all(20.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'Image not yet uploaded.',
                                                  ),
                                                  SizedBox(
                                                    height: 10,
                                                  ),
                                                  FaIcon(
                                                    Icons.camera_alt,
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                          if (snapshot.connectionState ==
                                              ConnectionState.done) {
                                            // imgUploadCheck = true;
                                            updateImgCheckW(imgUploadCheck,
                                                documentSnapshot);
                                            return Container(
                                              height: 300,
                                              width: 300,
                                              child: snapshot.data,
                                            );
                                          }
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Container(
                                              child: const Padding(
                                                padding: EdgeInsets.all(5.0),
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            );
                                          }
                                          return Container();
                                        }),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            billMessage,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),

                          const SizedBox(
                            height: 10,
                          ),
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Stack(
                                    children: [
                                      BasicIconButtonGrey(
                                        onPress: () async {
                                          Provider.of<PropertyProvider>(context,
                                                  listen: false)
                                              .selectProperty(property!);

                                          Fluttertoast.showToast(
                                              msg:
                                                  "Now downloading your statement!\nPlease wait a few seconds!");

                                          _onSubmit();

                                          String accountNumberPDF =
                                              documentSnapshot['accountNumber'];
                                          print(
                                              'The acc number is ::: $accountNumberPDF');

                                          final storageRef = FirebaseStorage
                                              .instance
                                              .ref()
                                              .child(
                                                  "pdfs/$formattedMonth/${property?.cellNum}/${property?.address}");
                                          final listResult =
                                              await storageRef.listAll();
                                          for (var prefix
                                              in listResult.prefixes) {
                                            print('The ref is ::: $prefix');
                                            // The prefixes under storageRef.
                                            // You can call listAll() recursively on them.
                                          }
                                          for (var item in listResult.items) {
                                            int finalIndex =
                                                listResult.items.length;
                                            print('The item is ::: $item');
                                            // The items under storageRef.
                                            if (item
                                                .toString()
                                                .contains(accountNumberPDF)) {
                                              final url = item.fullPath;
                                              print('The url is ::: $url');
                                              final file =
                                                  await PDFApi.loadFirebase(
                                                      url);
                                              try {
                                                if (context.mounted)
                                                  openPDF(context, file);
                                                Fluttertoast.showToast(
                                                    msg:
                                                        "Download Successful!");
                                              } catch (e) {
                                                Fluttertoast.showToast(
                                                    msg:
                                                        "Unable to download statement.");
                                              }
                                            } else if (listResult
                                                    .items.length ==
                                                finalIndex) {
                                              Fluttertoast.showToast(
                                                  msg:
                                                      "Unable to download statement.");
                                            }
                                          }
                                        },
                                        labelText: 'Invoice',
                                        fSize: 16,
                                        faIcon: const FaIcon(
                                          Icons.picture_as_pdf,
                                        ),
                                        fgColor: Colors.orangeAccent,
                                        btSize: const Size(100, 38),
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Visibility(
                                          visible: _isLoading,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(
                                                height: 15,
                                                width: 130,
                                              ),
                                              Container(
                                                width: 24,
                                                height: 24,
                                                padding:
                                                    const EdgeInsets.all(2.0),
                                                child:
                                                    const CircularProgressIndicator(
                                                  color: Colors.purple,
                                                  strokeWidth: 3,
                                                ),
                                              ),
                                            ],
                                          ))
                                    ],
                                  ),
                                  BasicIconButtonGrey(
                                    onPress: () async {
                                      Provider.of<PropertyProvider>(context,
                                              listen: false)
                                          .selectProperty(property!);

                                      accountNumberAll =
                                          documentSnapshot['accountNumber'];
                                      locationGivenAll =
                                          documentSnapshot['address'];

                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  MapScreenProp(
                                                    propAddress:
                                                        locationGivenAll,
                                                    propAccNumber:
                                                        accountNumberAll,
                                                  )));
                                    },
                                    labelText: 'Map',
                                    fSize: 16,
                                    faIcon: const FaIcon(
                                      Icons.map,
                                    ),
                                    fgColor: Colors.green,
                                    btSize: const Size(100, 38),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return null;
              },
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  Future<void> _create([DocumentSnapshot? documentSnapshot]) async {
    _accountNumberController.text = '';
    _addressController.text = '';
    _areaCodeController.text = '';
    // _meterNumberController.text = '';
    // _meterReadingController.text = '';
    _waterMeterController.text = '';
    _waterMeterReadingController.text = '';
    _cellNumberController.text = '';
    _firstNameController.text = '';
    _lastNameController.text = '';
    _idNumberController.text = '';

    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
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
                    visible: visibilityState1,
                    child: TextField(
                      controller: _accountNumberController,
                      decoration:
                          const InputDecoration(labelText: 'Account Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _addressController,
                      decoration:
                          const InputDecoration(labelText: 'Street Address'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      keyboardType: const TextInputType.numberWithOptions(),
                      controller: _areaCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Area Code',
                      ),
                    ),
                  ),
                  // Visibility(
                  //   visible: visibilityState1,
                  //   child: TextField(
                  //     controller: _meterNumberController,
                  //     decoration:
                  //         const InputDecoration(labelText: 'Meter Number'),
                  //   ),
                  // ),
                  // Visibility(
                  //   visible: visibilityState1,
                  //   child: TextField(
                  //     controller: _meterReadingController,
                  //     decoration:
                  //         const InputDecoration(labelText: 'Meter Reading'),
                  //   ),
                  // ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _waterMeterController,
                      decoration: const InputDecoration(
                          labelText: 'Water Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _waterMeterReadingController,
                      decoration: const InputDecoration(
                          labelText: 'Water Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _cellNumberController,
                      decoration:
                          const InputDecoration(labelText: 'Phone Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _firstNameController,
                      decoration:
                          const InputDecoration(labelText: 'First Name'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _idNumberController,
                      decoration: const InputDecoration(labelText: 'ID Number'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    child: const Text('Create'),
                    onPressed: () async {
                      Provider.of<PropertyProvider>(context, listen: false)
                          .selectProperty(property!);

                      final String accountNumber =
                          _accountNumberController.text;
                      final String address = _addressController.text;
                      final String areaCode = _areaCodeController.text;
                      // final String meterNumber = _meterNumberController.text;
                      // final String meterReading = _meterReadingController.text;
                      final String waterMeterNumber =
                          _waterMeterController.text;
                      final String waterMeterReading =
                          _waterMeterReadingController.text;
                      final String cellNumber = _cellNumberController.text;
                      final String firstName = _firstNameController.text;
                      final String lastName = _lastNameController.text;
                      final String idNumber = _idNumberController.text;
                      if (accountNumber != null) {
                        await _propList?.add({
                          "accountNumber": accountNumber,
                          "address": address,
                          "areaCode": areaCode,
                          // "meter_number": meterNumber,
                          // "meter_reading": meterReading,
                          "water_meter_number": waterMeterNumber,
                          "water_meter_reading": waterMeterReading,
                          "cellNumber": cellNumber,
                          "firstName": firstName,
                          "lastName": lastName,
                          "idNumber": idNumber
                        });
                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _areaCodeController.text = '';
                        // _meterNumberController.text = '';
                        // _meterReadingController.text = '';
                        _waterMeterController.text = '';
                        _waterMeterReadingController.text = '';
                        _cellNumberController.text = '';
                        _firstNameController.text = '';
                        _lastNameController.text = '';
                        _idNumberController.text = '';

                        if (context.mounted) Navigator.of(context).pop();
                      }
                    },
                  )
                ],
              ),
            ),
          );
        });
  }

  /// on update the only info necessary to change should be meter reading
  Future<void> _update([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      _accountNumberController.text = documentSnapshot['accountNumber'];
      _addressController.text = documentSnapshot['address'];
      _areaCodeController.text = documentSnapshot['areaCode'].toString();
      // _meterNumberController.text = documentSnapshot['meter_number'];
      // _meterReadingController.text = documentSnapshot['meter_reading'];
      _waterMeterController.text = documentSnapshot['water_meter_number'];
      _waterMeterReadingController.text =
          documentSnapshot['water_meter_reading'];
      _cellNumberController.text = documentSnapshot['cellNumber'];
      _firstNameController.text = documentSnapshot['firstName'];
      _lastNameController.text = documentSnapshot['lastName'];
      _idNumberController.text = documentSnapshot['idNumber'];
      userID = documentSnapshot['userID'];
    }

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
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
                    visible: visibilityState2,
                    child: TextField(
                      controller: _accountNumberController,
                      decoration:
                          const InputDecoration(labelText: 'Account Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _addressController,
                      decoration:
                          const InputDecoration(labelText: 'Street Address'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      keyboardType: const TextInputType.numberWithOptions(),
                      controller: _areaCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Area Code',
                      ),
                    ),
                  ),
                  // Visibility(
                  //   visible: visibilityState2,
                  //   child: TextField(
                  //     controller: _meterNumberController,
                  //     decoration: const InputDecoration(
                  //         labelText: 'Electricity Meter Number'),
                  //   ),
                  // ),
                  // Visibility(
                  //   visible: visibilityState1,
                  //   child: TextField(
                  //     controller: _meterReadingController,
                  //     decoration: const InputDecoration(
                  //         labelText: 'Electricity Meter Reading'),
                  //   ),
                  // ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _waterMeterController,
                      decoration: const InputDecoration(
                          labelText: 'Water Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _waterMeterReadingController,
                      decoration: const InputDecoration(
                          labelText: 'Water Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _cellNumberController,
                      decoration:
                          const InputDecoration(labelText: 'Phone Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _firstNameController,
                      decoration:
                          const InputDecoration(labelText: 'First Name'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _idNumberController,
                      decoration: const InputDecoration(labelText: 'ID Number'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    child: const Text('Update'),
                    onPressed: () async {
                      Provider.of<PropertyProvider>(context, listen: false)
                          .selectProperty(property!);

                      final String accountNumber =
                          _accountNumberController.text;
                      final String address = _addressController.text;
                      final int areaCode = int.parse(_areaCodeController.text);
                      // final String meterNumber = _meterNumberController.text;
                      // final String meterReading = _meterReadingController.text;
                      final String waterMeterNumber =
                          _waterMeterController.text;
                      final String waterMeterReading =
                          _waterMeterReadingController.text;
                      final String cellNumber = _cellNumberController.text;
                      final String firstName = _firstNameController.text;
                      final String lastName = _lastNameController.text;
                      final String idNumber = _idNumberController.text;

                      if (accountNumber != null) {
                        await _propList?.doc(documentSnapshot!.id).update({
                          "accountNumber": accountNumber,
                          "address": address,
                          "areaCode": areaCode,
                          // "meter_number": meterNumber,
                          // "meter_reading": meterReading,
                          "water_meter_number": waterMeterNumber,
                          "water_meter_reading": waterMeterReading,
                          "cellNumber": cellNumber,
                          "firstName": firstName,
                          "lastName": lastName,
                          "idNumber": idNumber,
                          "userID": userID,
                        });

                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _areaCodeController.text = '';
                        // _meterNumberController.text = '';
                        // _meterReadingController.text = '';
                        _waterMeterController.text = '';
                        _waterMeterReadingController.text = '';
                        _cellNumberController.text = '';
                        _firstNameController.text = '';
                        _lastNameController.text = '';
                        _idNumberController.text = '';

                        if (context.mounted) Navigator.of(context).pop();

                        ///Added open the image upload straight after inputting the meter reading
                        // if(context.mounted) {
                        //   Navigator.push(context,
                        //       MaterialPageRoute(builder: (context) => ImageUploadMeter(userNumber: cellNumber, meterNumber: meterNumber,)));
                        // }
                      }
                    },
                  )
                ],
              ),
            ),
          );
        });
  }

  // Future<void> _updateE([DocumentSnapshot? documentSnapshot]) async {
  //   if (documentSnapshot != null) {
  //     _accountNumberController.text = documentSnapshot['accountNumber'];
  //     _addressController.text = documentSnapshot['address'];
  //     _areaCodeController.text = documentSnapshot['areaCode'].toString();
  //     _meterNumberController.text = documentSnapshot['meter_number'];
  //     _meterReadingController.text = documentSnapshot['meter_reading'];
  //     _waterMeterController.text = documentSnapshot['water_meter_number'];
  //     _waterMeterReadingController.text =
  //         documentSnapshot['water_meter_reading'];
  //     _cellNumberController.text = documentSnapshot['cellNumber'];
  //     _firstNameController.text = documentSnapshot['firstName'];
  //     _lastNameController.text = documentSnapshot['lastName'];
  //     _idNumberController.text = documentSnapshot['idNumber'];
  //     userID = documentSnapshot['userID'];
  //   }
  //
  //   /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
  //   await showModalBottomSheet(
  //       isScrollControlled: true,
  //       context: context,
  //       builder: (BuildContext ctx) {
  //         return SingleChildScrollView(
  //           child: Padding(
  //             padding: EdgeInsets.only(
  //                 top: 20,
  //                 left: 20,
  //                 right: 20,
  //                 bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Visibility(
  //                   visible: visibilityState2,
  //                   child: TextField(
  //                     controller: _accountNumberController,
  //                     decoration:
  //                         const InputDecoration(labelText: 'Account Number'),
  //                   ),
  //                 ),
  //                 Visibility(
  //                   visible: visibilityState2,
  //                   child: TextField(
  //                     controller: _addressController,
  //                     decoration:
  //                         const InputDecoration(labelText: 'Street Address'),
  //                   ),
  //                 ),
  //                 Visibility(
  //                   visible: visibilityState2,
  //                   child: TextField(
  //                     keyboardType: const TextInputType.numberWithOptions(),
  //                     controller: _areaCodeController,
  //                     decoration: const InputDecoration(
  //                       labelText: 'Area Code',
  //                     ),
  //                   ),
  //                 ),
  //                 Visibility(
  //                   visible: visibilityState2,
  //                   child: TextField(
  //                     controller: _meterNumberController,
  //                     decoration: const InputDecoration(
  //                         labelText: 'Electricity Meter Number'),
  //                   ),
  //                 ),
  //                 Visibility(
  //                   visible: visibilityState1,
  //                   child: TextField(
  //                     maxLength: 5,
  //                     maxLengthEnforcement: MaxLengthEnforcement.enforced,
  //                     keyboardType: TextInputType.number,
  //                     controller: _meterReadingController,
  //                     decoration: const InputDecoration(
  //                         labelText: 'Electricity Meter Reading'),
  //                   ),
  //                 ),
  //                 Visibility(
  //                   visible: visibilityState2,
  //                   child: TextField(
  //                     controller: _waterMeterController,
  //                     decoration: const InputDecoration(
  //                         labelText: 'Water Meter Number'),
  //                   ),
  //                 ),
  //                 Visibility(
  //                   visible: visibilityState2,
  //                   child: TextField(
  //                     maxLength: 8,
  //                     maxLengthEnforcement: MaxLengthEnforcement.enforced,
  //                     keyboardType: TextInputType.number,
  //                     controller: _waterMeterReadingController,
  //                     decoration: const InputDecoration(
  //                         labelText: 'Water Meter Reading'),
  //                   ),
  //                 ),
  //                 Visibility(
  //                   visible: visibilityState2,
  //                   child: TextField(
  //                     controller: _cellNumberController,
  //                     decoration:
  //                         const InputDecoration(labelText: 'Phone Number'),
  //                   ),
  //                 ),
  //                 Visibility(
  //                   visible: visibilityState2,
  //                   child: TextField(
  //                     controller: _firstNameController,
  //                     decoration:
  //                         const InputDecoration(labelText: 'First Name'),
  //                   ),
  //                 ),
  //                 Visibility(
  //                   visible: visibilityState2,
  //                   child: TextField(
  //                     controller: _lastNameController,
  //                     decoration: const InputDecoration(labelText: 'Last Name'),
  //                   ),
  //                 ),
  //                 Visibility(
  //                   visible: visibilityState2,
  //                   child: TextField(
  //                     controller: _idNumberController,
  //                     decoration: const InputDecoration(labelText: 'ID Number'),
  //                   ),
  //                 ),
  //                 const SizedBox(
  //                   height: 20,
  //                 ),
  //                 ElevatedButton(
  //                   child: const Text('Update'),
  //                   onPressed: () async {
  //                     Provider.of<PropertyProvider>(context, listen: false).selectProperty(property!);
  //
  //                     final String accountNumber =
  //                         _accountNumberController.text;
  //                     final String address = _addressController.text;
  //                     final int areaCode = int.parse(_areaCodeController.text);
  //                     final String meterNumber = _meterNumberController.text;
  //                     final String meterReading = _meterReadingController.text;
  //                     final String waterMeterNumber =
  //                         _waterMeterController.text;
  //                     final String waterMeterReading =
  //                         _waterMeterReadingController.text;
  //                     final String cellNumber = _cellNumberController.text;
  //                     final String firstName = _firstNameController.text;
  //                     final String lastName = _lastNameController.text;
  //                     final String idNumber = _idNumberController.text;
  //
  //                     // if (accountNumber != null) {
  //                     //   await _propList
  //                     //       .doc(documentSnapshot!.id)
  //                     //       .update({
  //                     //     "account number": accountNumber,
  //                     //     "address": address,
  //                     //     "area code": areaCode,
  //                     //     "meter number": meterNumber,
  //                     //     "meter reading": meterReading,
  //                     //     "water meter number": waterMeterNumber,
  //                     //     "water meter reading": waterMeterReading,
  //                     //     "cell number": cellNumber,
  //                     //     "first name": firstName,
  //                     //     "last name": lastName,
  //                     //     "id number": idNumber,
  //                     //     "user id" : userID,
  //                     //   });
  //                     //
  //                     //   final CollectionReference _propMonthReadings = FirebaseFirestore.instance
  //                     //       .collection('consumption').doc(formattedMonth)
  //                     //       .collection('address').doc(address) as CollectionReference<Object?>;
  //                     //
  //                     //   if(_propMonthReadings.id != address || _propMonthReadings.id == '' ){
  //                     //     await _propMonthReadings.add({
  //                     //       "address": address,
  //                     //       "meter reading": meterReading,
  //                     //       "water meter reading": waterMeterReading,
  //                     //     });
  //                     //   } else {
  //                     //     await _propMonthReadings.doc(address).update({
  //                     //       "address": address,
  //                     //       "meter reading": meterReading,
  //                     //       "water meter reading": waterMeterReading,
  //                     //     });
  //                     //   }
  //                     Map<String, dynamic> updateDetails = {
  //                       "accountNumber": accountNumber,
  //                       "address": address,
  //                       "areaCode": areaCode,
  //                       "meter_number": meterNumber,
  //                       "meter_reading": meterReading,
  //                       "water_meter_number": waterMeterNumber,
  //                       "water_meter_reading": waterMeterReading,
  //                       "cellNumber": cellNumber,
  //                       "firstName": firstName,
  //                       "lastName": lastName,
  //                       "idNumber": idNumber,
  //                       "userID": userID,
  //                     };
  //                     if (accountNumber.isNotEmpty) {
  //                       await documentSnapshot?.reference.update(updateDetails);
  //                       print(
  //                           "municipalityUserEmail: ${widget.municipalityUserEmail}");
  //                       // Log the update action using the municipalityUserEmail from the ImageZoomPage
  //                       await logEMeterReadingUpdate(
  //                           documentSnapshot?['cell number'] ??
  //                               '', // cellNumber
  //                           address, // address
  //                           widget.municipalityUserEmail ??
  //                               "Unknown", // municipalityUserEmail
  //                          districtId, // districtId
  //                         municipalityId, // municipalityId
  //                           updateDetails // Map<String, dynamic> details
  //                           );
  //
  //                       Navigator.pop(context);
  //                       ScaffoldMessenger.of(context)
  //                           .showSnackBar(const SnackBar(
  //                         content: Text("Meter readings updated successfully"),
  //                         duration: Duration(seconds: 2),
  //                       ));
  //                     } else {
  //                       // Handle the case where account number is not entered
  //                       ScaffoldMessenger.of(context)
  //                           .showSnackBar(const SnackBar(
  //                         content: Text("Please fill in all required fields."),
  //                         duration: Duration(seconds: 2),
  //                       ));
  //                       await FirebaseFirestore.instance
  //                           .collection('districts')
  //                           .doc(districtId)
  //                           .collection('municipalities')
  //                           .doc(municipalityId)
  //                           .collection('consumption')
  //                           .doc(formattedMonth)
  //                           .collection('properties')
  //                           .doc(address)
  //                           .set({
  //                         "address": address,
  //                         "meter_reading": meterReading,
  //                         "water_meter_reading": waterMeterReading,
  //                       });
  //                       _accountNumberController.text = '';
  //                       _addressController.text = '';
  //                       _areaCodeController.text = '';
  //                       _meterNumberController.text = '';
  //                       _meterReadingController.text = '';
  //                       _waterMeterController.text = '';
  //                       _waterMeterReadingController.text = '';
  //                       _cellNumberController.text = '';
  //                       _firstNameController.text = '';
  //                       _lastNameController.text = '';
  //                       _idNumberController.text = '';
  //
  //                       if (context.mounted) Navigator.of(context).pop();
  //
  //                       ///Added open the image upload straight after inputting the meter reading
  //                       // if(context.mounted) {
  //                       //   Navigator.push(context,
  //                       //       MaterialPageRoute(builder: (context) => ImageUploadMeter(userNumber: cellNumber, meterNumber: meterNumber,)));
  //                       // }
  //                     }
  //                   },
  //                 )
  //               ],
  //             ),
  //           ),
  //         );
  //       });
  // }

  Future<void> _updateW([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      _accountNumberController.text = documentSnapshot['accountNumber'];
      _addressController.text = documentSnapshot['address'];
      _areaCodeController.text = documentSnapshot['areaCode'].toString();
      // _meterNumberController.text = documentSnapshot['meter_number'];
      // _meterReadingController.text = documentSnapshot['meter_reading'];
      _waterMeterController.text = documentSnapshot['water_meter_number'];
      _waterMeterReadingController.text =
          documentSnapshot['water_meter_reading'];
      _cellNumberController.text = documentSnapshot['cellNumber'];
      _firstNameController.text = documentSnapshot['firstName'];
      _lastNameController.text = documentSnapshot['lastName'];
      _idNumberController.text = documentSnapshot['idNumber'];
      userID = documentSnapshot['userID'];
    }

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
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
                    visible: visibilityState2,
                    child: TextField(
                      controller: _accountNumberController,
                      decoration:
                          const InputDecoration(labelText: 'Account Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _addressController,
                      decoration:
                          const InputDecoration(labelText: 'Street Address'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      keyboardType: const TextInputType.numberWithOptions(),
                      controller: _areaCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Area Code',
                      ),
                    ),
                  ),
                  // Visibility(
                  //   visible: visibilityState2,
                  //   child: TextField(
                  //     controller: _meterNumberController,
                  //     decoration: const InputDecoration(
                  //         labelText: 'Electricity Meter Number'),
                  //   ),
                  // ),
                  // Visibility(
                  //   visible: visibilityState2,
                  //   child: TextField(
                  //     maxLength: 5,
                  //     maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  //     keyboardType: TextInputType.number,
                  //     controller: _meterReadingController,
                  //     decoration: const InputDecoration(
                  //         labelText: 'Electricity Meter Reading'),
                  //   ),
                  // ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _waterMeterController,
                      decoration: const InputDecoration(
                          labelText: 'Water Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      maxLength: 8,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      keyboardType: TextInputType.number,
                      controller: _waterMeterReadingController,
                      decoration: const InputDecoration(
                          labelText: 'Water Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _cellNumberController,
                      decoration:
                          const InputDecoration(labelText: 'Phone Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _firstNameController,
                      decoration:
                          const InputDecoration(labelText: 'First Name'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _idNumberController,
                      decoration: const InputDecoration(labelText: 'ID Number'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    child: const Text('Update'),
                    onPressed: () async {
                      Provider.of<PropertyProvider>(context, listen: false)
                          .selectProperty(property!);

                      final String accountNumber =
                          _accountNumberController.text;
                      final String address = _addressController.text;
                      final int areaCode = int.parse(_areaCodeController.text);
                      // final String meterNumber = _meterNumberController.text;
                      // final String meterReading = _meterReadingController.text;
                      final String waterMeterNumber =
                          _waterMeterController.text;
                      final String waterMeterReading =
                          _waterMeterReadingController.text;
                      final String cellNumber = _cellNumberController.text;
                      final String firstName = _firstNameController.text;
                      final String lastName = _lastNameController.text;
                      final String idNumber = _idNumberController.text;

                      // if (accountNumber != null) {
                      //   await _propList
                      //       .doc(documentSnapshot!.id)
                      //       .update({
                      //     "account number": accountNumber,
                      //     "address": address,
                      //     "area code": areaCode,
                      //     "meter number": meterNumber,
                      //     "meter reading": meterReading,
                      //     "water meter number": waterMeterNumber,
                      //     "water meter reading": waterMeterReading,
                      //     "cell number": cellNumber,
                      //     "first name": firstName,
                      //     "last name": lastName,
                      //     "id number": idNumber,
                      //     "user id" : userID,
                      //   });
                      Map<String, dynamic> updateDetails = {
                        "accountNumber": accountNumber,
                        "address": address,
                        "areaCode": areaCode,
                        // "meter_number": meterNumber,
                        // "meter_reading": meterReading,
                        "water_meter_number": waterMeterNumber,
                        "water_meter_reading": waterMeterReading,
                        "cellNumber": cellNumber,
                        "firstName": firstName,
                        "lastName": lastName,
                        "idNumber": idNumber,
                        "userID": userID,
                      };
                      if (accountNumber.isNotEmpty) {
                        // Check if it's a local municipality or district-based municipality
                        if (property!.isLocalMunicipality) {
                          // Update in the local municipalities collection
                          await FirebaseFirestore.instance
                              .collection('localMunicipalities')
                              .doc(municipalityId)
                              .collection('properties')
                              .doc(documentSnapshot!.id)
                              .update(updateDetails);
                        } else {
                          // Update in the district-based municipalities collection
                          await FirebaseFirestore.instance
                              .collection('districts')
                              .doc(districtId)
                              .collection('municipalities')
                              .doc(municipalityId)
                              .collection('properties')
                              .doc(documentSnapshot!.id)
                              .update(updateDetails);
                        }

                        // Log the update action using the municipalityUserEmail
                        await logWMeterReadingUpdate(
                          cellNumber, // cellNumber
                          address, // address
                          widget.municipalityUserEmail ??
                              "Unknown", // municipalityUserEmail
                          districtId, // districtId
                          municipalityId, // municipalityId
                          updateDetails, // Map<String, dynamic> details
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text("Meter readings updated successfully"),
                          duration: Duration(seconds: 2),
                        ));
                      } else {
                        // Handle the case where account number is not entered
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text("Please fill in all required fields."),
                          duration: Duration(seconds: 2),
                        ));
                        await FirebaseFirestore.instance
                            .collection('districts')
                            .doc(districtId)
                            .collection('municipalities')
                            .doc(municipalityId)
                            .collection('consumption')
                            .doc(formattedMonth)
                            .collection('properties')
                            .doc(address)
                            .set({
                          "address": address,
                          // "meter_reading": meterReading,
                          "water_meter_reading": waterMeterReading,
                        });
                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _areaCodeController.text = '';
                        // _meterNumberController.text = '';
                        // _meterReadingController.text = '';
                        _waterMeterController.text = '';
                        _waterMeterReadingController.text = '';
                        _cellNumberController.text = '';
                        _firstNameController.text = '';
                        _lastNameController.text = '';
                        _idNumberController.text = '';

                        if (context.mounted) Navigator.of(context).pop();

                        ///Added open the image upload straight after inputting the meter reading
                        // if(context.mounted) {
                        //   Navigator.push(context,
                        //       MaterialPageRoute(builder: (context) => ImageUploadMeter(userNumber: cellNumber, meterNumber: waterMeterNumber,)));
                        // }
                      }
                    },
                  )
                ],
              ),
            ),
          );
        });
  }

  Future<void> _delete(String users) async {
    await _propList?.doc(users).delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You have successfully deleted an account')));
    }
  }

  void setMonthLimits(String currentMonth) {
    String month1 = 'January';
    String month2 = 'February';
    String month3 = 'March';
    String month4 = 'April';
    String month5 = 'May';
    String month6 = 'June';
    String month7 = 'July';
    String month8 = 'August';
    String month9 = 'September';
    String month10 = 'October';
    String month11 = 'November';
    String month12 = 'December';

    if (currentMonth.contains(month1)) {
      dropdownMonths = [
        'Select Month',
        month10,
        month11,
        month12,
        currentMonth,
      ];
    } else if (currentMonth.contains(month2)) {
      dropdownMonths = [
        'Select Month',
        month11,
        month12,
        month1,
        currentMonth,
      ];
    } else if (currentMonth.contains(month3)) {
      dropdownMonths = [
        'Select Month',
        month12,
        month1,
        month2,
        currentMonth,
      ];
    } else if (currentMonth.contains(month4)) {
      dropdownMonths = [
        'Select Month',
        month1,
        month2,
        month3,
        currentMonth,
      ];
    } else if (currentMonth.contains(month5)) {
      dropdownMonths = [
        'Select Month',
        month2,
        month3,
        month4,
        currentMonth,
      ];
    } else if (currentMonth.contains(month6)) {
      dropdownMonths = [
        'Select Month',
        month3,
        month4,
        month5,
        currentMonth,
      ];
    } else if (currentMonth.contains(month7)) {
      dropdownMonths = [
        'Select Month',
        month4,
        month5,
        month6,
        currentMonth,
      ];
    } else if (currentMonth.contains(month8)) {
      dropdownMonths = [
        'Select Month',
        month5,
        month6,
        month7,
        currentMonth,
      ];
    } else if (currentMonth.contains(month9)) {
      dropdownMonths = [
        'Select Month',
        month6,
        month7,
        month8,
        currentMonth,
      ];
    } else if (currentMonth.contains(month10)) {
      dropdownMonths = [
        'Select Month',
        month7,
        month8,
        month9,
        currentMonth,
      ];
    } else if (currentMonth.contains(month11)) {
      dropdownMonths = [
        'Select Month',
        month8,
        month9,
        month10,
        currentMonth,
      ];
    } else if (currentMonth.contains(month12)) {
      dropdownMonths = [
        'Select Month',
        month9,
        month10,
        month11,
        currentMonth,
      ];
    } else {
      dropdownMonths = [
        'Select Month',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
    }
  }

  ///pdf view loader getting file name onPress/onTap that passes pdf filename to this class.
  void openPDF(BuildContext context, File file) => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
      );
}
