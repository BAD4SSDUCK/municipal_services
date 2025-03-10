import 'dart:convert';
import 'dart:io';

import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as excel;
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';
import 'package:municipal_services/code/Reusable/push_notification_message.dart';
import 'package:municipal_services/code/ImageUploading/image_upload_meter.dart';
import 'package:municipal_services/code/ImageUploading/image_upload_water.dart';
import 'package:municipal_services/code/MapTools/map_screen_prop.dart';
import 'package:municipal_services/code/PDFViewer/view_pdf.dart';
import 'package:municipal_services/code/PDFViewer/pdf_api.dart';
import 'package:municipal_services/code/NoticePages/notice_config_screen.dart';
import 'display_property_trend.dart';
//Meter Update from municipal side

class PropertyMetersAll extends StatefulWidget {
  final String? municipalityUserEmail;
  final String? districtId;
  final String municipalityId;
  final bool isLocalMunicipality;
  final bool isLocalUser;
  const PropertyMetersAll({super.key, this.municipalityUserEmail,
    this.districtId,
    required this.municipalityId,
    required this.isLocalMunicipality,
    required this.isLocalUser, });

  @override
  _PropertyMetersAllState createState() => _PropertyMetersAllState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

final User? user = auth.currentUser;
final uid = user?.uid;
final email = user?.email;
String userID = uid as String;
String userEmail = email as String;
DateTime now = DateTime.now();

String phoneNum = ' ';

String accountNumberAll = ' ';
String locationGivenAll = ' ';
// String eMeterNumber = ' ';
String accountNumberW = ' ';
String locationGivenW = ' ';
String wMeterNumber = ' ';

String propPhoneNum = ' ';

bool visShow = true;
bool visHide = false;
bool adminAcc = false;

List<Map<String, dynamic>> _allProps = [];
List<Map<String, dynamic>> _filteredProps = [];
Map<String, String> imageCacheMap = {}; // Stores property image URLs

final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;

class FireStorageService extends ChangeNotifier{
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async{
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

Future<String> _getImageW(BuildContext context, String? imagePath, String propertyAddress) async {
  if (imagePath == null) {
    throw Exception('Image path cannot be null');
  }

  // ✅ Check cache before fetching
  if (imageCacheMap.containsKey(propertyAddress)) {
    print("🔄 Using cached image for $propertyAddress");
    return imageCacheMap[propertyAddress]!; // Return cached URL
  }

  try {
    String imageUrl = await FirebaseStorage.instance.ref(imagePath).getDownloadURL();

    // ✅ Cache image URL to prevent repeated loading
    imageCacheMap[propertyAddress] = imageUrl;
    return imageUrl;
  } catch (e) {
    print('Failed to load image for $propertyAddress: $e');
    throw Exception('Failed to load image');
  }
}


// final CollectionReference _propList =
// FirebaseFirestore.instance.collection('properties');

class _PropertyMetersAllState extends State<PropertyMetersAll> {
  String? userEmail;
   String districtId='';
   String municipalityId='';
   CollectionReference? _propList;
  bool isLoading = true;
  bool isLocalMunicipality = false;
  bool isLocalUser=true;
  final String formattedMonth = DateFormat.MMMM().format(DateTime.now());
  List<String> municipalities = []; // To hold the list of municipality names
  String? selectedMunicipality = "Select Municipality";
  List<DocumentSnapshot> filteredProperties = [];
  List<QueryDocumentSnapshot<Object?>> _fetchedProperties = [];
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  String currentMonth = DateFormat.MMMM().format(DateTime.now()); // Example: February
  String previousMonth = DateFormat.MMMM().format(DateTime.now().subtract(Duration(days: 30))); // Example: January
  Map<String, String> previousMonthReadings = {}; // Store previous readings per address
  Map<String, String> currentMonthReadings = {};
  Map<String, DateTime?> latestImageTimestamps = {}; // Stores the latest upload timestamp for each property

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    fetchUserDetails().then((_) {
      if (isLocalUser) {
        // For local municipality users, fetch properties only for their municipality
        fetchPropertiesForLocalMunicipality();
      } else {
        // For district-level users, fetch properties for all municipalities
        fetchMunicipalities(); // Fetch municipalities after user details are loaded
      }
    });
    fetchAllPreviousMonthReadings().then((_) {
      if (mounted) {
        setState(() {}); // Refresh UI after loading data
      }
    });

    _searchBarController.addListener(filterProperties);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchBarController.removeListener(filterProperties);
    _searchBarController.dispose();
    super.dispose();
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

          // Set the property and notifications paths based on municipality type
          if(mounted) {
            setState(() {
              if (isLocalMunicipality) {
                _propList = FirebaseFirestore.instance
                    .collection('localMunicipalities')
                    .doc(municipalityId)
                    .collection('properties');
                _listNotifications = FirebaseFirestore.instance
                    .collection('localMunicipalities')
                    .doc(municipalityId)
                    .collection('Notifications');
              } else {
                _propList = FirebaseFirestore.instance
                    .collection('districts')
                    .doc(districtId)
                    .collection('municipalities')
                    .doc(municipalityId)
                    .collection('properties');
                _listNotifications = FirebaseFirestore.instance
                    .collection('districts')
                    .doc(districtId)
                    .collection('municipalities')
                    .doc(municipalityId)
                    .collection('Notifications');
              }
            });
          }
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
      if(mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchMunicipalities() async {
    try {
      if (districtId.isNotEmpty) {
        print("Fetching municipalities under district: $districtId");
        // Fetch all municipalities under the district
        var municipalitiesSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .get();

        print("Municipalities fetched: ${municipalitiesSnapshot.docs.length}");
        if (mounted) {
          setState(() {
            municipalities = municipalitiesSnapshot.docs
                .map((doc) => doc.id) // Using document ID as the municipality name
                .toList();
            selectedMunicipality = "Select Municipality";
            fetchPropertiesForAllMunicipalities();
          });
        }
      } else {
        print("districtId is empty or null.");
        if (mounted) {
          setState(() {
            municipalities = [];
            selectedMunicipality = "Select Municipality";
          });
        }
      }
    } catch (e) {
      print('Error fetching municipalities: $e');
    }
  }

  Future<void> fetchPropertiesForAllMunicipalities() async {
    try {
      QuerySnapshot propertiesSnapshot;

      print("Fetching properties for all municipalities...");

      if (selectedMunicipality == null ||
          selectedMunicipality == "Select Municipality") {
        // Fetch properties from all municipalities in the district
        print("Fetching properties for district: $districtId");
        propertiesSnapshot = await FirebaseFirestore.instance
            .collectionGroup('properties')
            .where('districtId', isEqualTo: districtId)
            .get();
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
      }

      print('Fetched ${propertiesSnapshot.docs.length} properties.');

      if (mounted) {
        setState(() {
          _fetchedProperties = propertiesSnapshot.docs; // Store all fetched properties
          isLoading = false; // Stop the loading spinner once properties are fetched
        });
      }

      print('Properties fetched: ${_fetchedProperties.length}');
    } catch (e) {
      print('Error fetching properties: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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

      if (mounted) {
        setState(() {
          _fetchedProperties = propertiesSnapshot.docs;
          isLoading = false; // Stop loading indicator
        });
      }
    } catch (e) {
      print('Error fetching properties for local municipality: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchPropertiesByMunicipality(String municipality) async {
    try {
      print("Fetching properties for selected municipality: $municipality");
      QuerySnapshot propertiesSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipality)
          .collection('properties')
          .get();

      if (mounted) {
        setState(() {
          _fetchedProperties = propertiesSnapshot.docs;
          municipalityId = municipality; // Update municipalityId
          print("Updated municipalityId: $municipalityId");
        });
      }
    } catch (e) {
      print('Error fetching properties for $municipality: $e');
    }
  }


  Future<String> fetchPropertyAddress(
      String userNumber,
      String wMeterNumber,
      String districtId,
      String municipalityId,
      bool isLocalMunicipality) async {
    try {
      QuerySnapshot propertyQuery;

      print('Fetching property address with:');
      print('User Number: $userNumber');
      print('Water Meter Number: $wMeterNumber');
      print('District ID: $districtId');
      print('Municipality ID: $municipalityId');
      print('Is Local Municipality: $isLocalMunicipality');

      if (isLocalMunicipality) {
        // Query for local municipality properties
        print('Query Path: localMunicipalities/$municipalityId/properties');
        propertyQuery = await FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(municipalityId)
            .collection('properties')
            .where('cellNumber', isEqualTo: userNumber)
            .where('water_meter_number', isEqualTo: wMeterNumber)
            .limit(1)
            .get();
      } else {
        // Query for district-based properties
        print(
            'Query Path: districts/$districtId/municipalities/$municipalityId/properties');
        propertyQuery = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('properties')
            .where('cellNumber', isEqualTo: userNumber)
            .where('water_meter_number', isEqualTo: wMeterNumber)
            .limit(1)
            .get();
      }

      if (propertyQuery.docs.isNotEmpty) {
        print('Property found: ${propertyQuery.docs.first.data()}');
        var propertyData =
        propertyQuery.docs.first.data() as Map<String, dynamic>;

        String? address = propertyData['address'];
        if (address != null) {
          // Sanitize address
          address = address.replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_');
          print('Sanitized Address: $address');
          return address;
        } else {
          throw Exception(
              "Address not found for user number: $userNumber and meter number: $wMeterNumber");
        }
      } else {
        throw Exception(
            "No property found for user number: $userNumber and meter number: $wMeterNumber");
      }
    } catch (e) {
      print('Error fetching property details: $e');
      return 'Unknown Address'; // Return a default value if an error occurs
    }
  }

  Future<void> fetchAllPreviousMonthReadings() async {
    try {
      int currentYear = DateTime.now().year;
      int previousYear = currentYear - 1;

      String currentMonth = DateFormat.MMMM().format(DateTime.now()); // Example: March
      String prevMonth = DateFormat.MMMM().format(DateTime.now().subtract(Duration(days: 30))); // Example: February

      String prevMonthYear = (currentMonth == "January") ? previousYear.toString() : currentYear.toString();
      String currentMonthYear = currentYear.toString(); // Always use the current year for current readings

      previousMonthReadings.clear(); // Clear previous data
      currentMonthReadings.clear();  // Clear current month data

      if (widget.isLocalMunicipality) {
        // ✅ Local Municipality: Fetch readings from the correct paths
        CollectionReference consumptionCollection = FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(widget.municipalityId)
            .collection('consumption');

        // Fetch **Previous Month's Readings**
        QuerySnapshot prevQuerySnapshot = await consumptionCollection
            .doc(prevMonthYear) // Year Folder
            .collection(prevMonth) // Previous Month Collection
            .get();

        if (prevQuerySnapshot.docs.isNotEmpty) {
          for (var doc in prevQuerySnapshot.docs) {
            var data = doc.data() as Map<String, dynamic>;
            previousMonthReadings[data['address']] = data['water_meter_reading'] ?? "N/A";
          }
        }

        // Fetch **Current Month's Readings**
        QuerySnapshot currentQuerySnapshot = await consumptionCollection
            .doc(currentMonthYear) // Year Folder
            .collection(currentMonth) // Current Month Collection
            .get();

        if (currentQuerySnapshot.docs.isNotEmpty) {
          for (var doc in currentQuerySnapshot.docs) {
            var data = doc.data() as Map<String, dynamic>;
            currentMonthReadings[data['address']] = data['water_meter_reading'] ?? "N/A";
          }
        }
      } else {
        // ✅ District Municipality: Fetch readings for ALL municipalities under the district
        CollectionReference municipalitiesCollection = FirebaseFirestore.instance
            .collection('districts')
            .doc(widget.districtId)
            .collection('municipalities');

        QuerySnapshot municipalitiesSnapshot = await municipalitiesCollection.get();

        for (var municipalityDoc in municipalitiesSnapshot.docs) {
          String municipalityId = municipalityDoc.id;

          CollectionReference consumptionCollection = municipalitiesCollection
              .doc(municipalityId)
              .collection('consumption');

          // Fetch **Previous Month's Readings**
          QuerySnapshot prevQuerySnapshot = await consumptionCollection
              .doc(prevMonthYear) // Year Folder
              .collection(prevMonth) // Previous Month Collection
              .get();

          if (prevQuerySnapshot.docs.isNotEmpty) {
            for (var doc in prevQuerySnapshot.docs) {
              var data = doc.data() as Map<String, dynamic>;
              previousMonthReadings[data['address']] = data['water_meter_reading'] ?? "N/A";
            }
          }

          // Fetch **Current Month's Readings**
          QuerySnapshot currentQuerySnapshot = await consumptionCollection
              .doc(currentMonthYear) // Year Folder
              .collection(currentMonth) // Current Month Collection
              .get();

          if (currentQuerySnapshot.docs.isNotEmpty) {
            for (var doc in currentQuerySnapshot.docs) {
              var data = doc.data() as Map<String, dynamic>;
              currentMonthReadings[data['address']] = data['water_meter_reading'] ?? "N/A";
            }
          }
        }
      }

      if (mounted) {
        setState(() {}); // Refresh UI
      }

      print("✅ Fetch complete: Previous Month ($prevMonthYear/$prevMonth), Current Month ($currentMonthYear/$currentMonth)");

    } catch (e) {
      print("❌ Error fetching previous and current month readings: $e");
    }
  }


  // void fetchProperties() async {
  //   try {
  //     QuerySnapshot data;
  //     if (isLocalMunicipality) {
  //       // If the user belongs to a local municipality
  //       data = await FirebaseFirestore.instance
  //           .collection('localMunicipalities')
  //           .doc(municipalityId)
  //           .collection('properties')
  //           .get();
  //     } else {
  //       // If the user belongs to a district municipality
  //       data = await FirebaseFirestore.instance
  //           .collection('districts')
  //           .doc(districtId)
  //           .collection('municipalities')
  //           .doc(municipalityId)
  //           .collection('properties')
  //           .get();
  //     }
  //
  //     setState(() {
  //       _allProps = data.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  //       _filteredProps = _allProps;
  //     });
  //
  //     print("Properties fetched successfully. Total properties: ${_allProps.length}");
  //   } catch (e) {
  //     print('Error fetching properties: $e');
  //   }
  // }


  Future<void> ensureDocumentExists(String cellNumber, String propertyAddress,String districtId,String municipalityId) async {
    print('ensureDocumentExists called with: cellNumber = $cellNumber, propertyAddress = $propertyAddress');

    DocumentReference actionLogDocRef;

    if (isLocalMunicipality) {
      actionLogDocRef = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('actionLogs')
          .doc(cellNumber)
          .collection(propertyAddress)
          .doc('actions');  // Reference a specific document in the 'actions' subcollection
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
    await actionLogDocRef.set({'created': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  // Future<void> logEMeterReadingUpdate(
  //     String cellNumber,
  //     String address,
  //     String municipalityUserEmail,
  //     String districtId,
  //     String municipalityId,
  //     Map<String, dynamic> details) async {
  //   DocumentReference userLogRef = FirebaseFirestore.instance
  //       .collection('districts')
  //       .doc(districtId)
  //       .collection('municipalities')
  //       .doc(municipalityId)
  //       .collection('actionLogs')
  //       .doc(cellNumber);
  //
  //   // Ensure the document exists
  //   await userLogRef.set(
  //     {'created': FieldValue.serverTimestamp()},
  //     SetOptions(merge: true),
  //   );
  //
  //   // Log the meter reading update action with the address
  //   await userLogRef.collection('actions').add({
  //     'actionType': 'Electricity Meter Reading Update',
  //     'uploader': municipalityUserEmail,
  //     'details': details,
  //     'address': address, // Include the property address in the log
  //     'timestamp': FieldValue.serverTimestamp(),
  //     'description': '$municipalityUserEmail updated electricity meter readings for property at $address',
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
    await ensureDocumentExists(cellNumber, districtId, municipalityId, propertyAddress);

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
      'description': '$municipalityUserEmail updated water meter readings for property at $propertyAddress',
    });
  }

  void filterProperties() {
    String query = _searchBarController.text.trim().toLowerCase();
    setState(() {
      _filteredProps = _allProps.where((property) {
        String address = (property['address'] as String).toLowerCase();
        String cellNumber = (property['cellNumber'] as String).toLowerCase();
        String firstName = (property['firstName'] as String).toLowerCase();
        String lastName = (property['lastName'] as String).toLowerCase();
        return address.contains(query) ||
            cellNumber.contains(query) ||
            firstName.contains(query) ||
            lastName.contains(query);
      }).toList();
    });
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
  final _searchBarController = TextEditingController();

  String searchText = '';
  final _userIDController = userID;

  String formattedDate = DateFormat.MMMM().format(now);

  final CollectionReference _listUserTokens =
  FirebaseFirestore.instance.collection('UserToken');

  // final CollectionReference _listNotifications =
  // FirebaseFirestore.instance.collection('Notifications');
  late final CollectionReference _listNotifications;
  final _headerController = TextEditingController();
  final _messageController = TextEditingController();
  late bool _noticeReadController;

  List<String> usersNumbers =[];
  List<String> usersTokens =[];
  List<String> usersRetrieve =[];

  ///Methods and implementation for push notifications with firebase and specific device token saving
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  TextEditingController username = TextEditingController();
  TextEditingController title = TextEditingController();
  TextEditingController body = TextEditingController();
  String? mtoken = " ";

  ///This was made for testing a default message
  String title2 = "Outstanding Utilities Payment";
  String body2 = "Make sure you pay utilities before the end of this month or your services will be disconnected";

  String token = '';
  String notifyToken = '';

  String userRole = '';
  List _allUserRolesResults = [];
  bool adminAcc = false;

  int numTokens=0;


  String dropdownValue = 'Select Month';
  List<String> dropdownMonths = ['Select Month','January','February','March','April','May','June','July','August','September','October','November','December'];

  List<Map<String, dynamic>> _allProps =[];

  void checkAdmin() {
    getUsersStream();
    if(userRole == 'Admin'|| userRole == 'Administrator'){
      adminAcc = true;
    } else {
      adminAcc = false;
    }
  }

  Future<void> getUsersStream() async {
    List<QuerySnapshot> allMunicipalUserDocs = [];

    try {
      // Fetch all districts
      var districtsSnapshot = await FirebaseFirestore.instance.collection('districts').get();

      // Iterate through each district
      for (var districtDoc in districtsSnapshot.docs) {
        // Fetch municipalities in each district
        var municipalitiesSnapshot = await districtDoc.reference.collection('municipalities').get();

        // Iterate through each municipality
        for (var municipalityDoc in municipalitiesSnapshot.docs) {
          // Get all users in the municipality
          var usersSnapshot = await municipalityDoc.reference.collection('users').get();
          allMunicipalUserDocs.add(usersSnapshot);
        }
      }

      // Fetch all local municipalities separately
      var localMunicipalitiesSnapshot = await FirebaseFirestore.instance.collection('localMunicipalities').get();

      // Iterate through each local municipality
      for (var localMunicipalityDoc in localMunicipalitiesSnapshot.docs) {
        // Get all users in the local municipality
        var usersSnapshot = await localMunicipalityDoc.reference.collection('users').get();
        allMunicipalUserDocs.add(usersSnapshot);
      }

      // Flatten the list of all user documents and set state
      List<DocumentSnapshot> allUserDocs = allMunicipalUserDocs.expand((snapshot) => snapshot.docs).toList();
      setState(() {
        _allUserRolesResults = allUserDocs;
      });

      // Call method to process user details
      getUserDetails();
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }



  getUserDetails() async {
    for (var userSnapshot in _allUserRolesResults) {
      ///Need to build a property model that retrieves property data entirely from the db
      var user = userSnapshot['email'].toString();
      var role = userSnapshot['userRole'].toString();

      if (user == userEmail) {
        userRole = role;
        print('My Role is::: $userRole');

        if (userRole == 'Admin' || userRole == 'Administrator') {
          adminAcc = true;
        } else {
          adminAcc = false;
        }
      }
    }
  }


  Future<void> fetchLatestUploadTimestamp(String propertyAddress, String propPhoneNum) async {
    if (propPhoneNum.isEmpty) return; // Ensure phone number is set

    print("🔍 Fetching latest timestamp in PropertyMetersAll...");
    print("➡️ Using Phone Number: $propPhoneNum");
    print("➡️ District ID: $districtId");
    print("➡️ Municipality ID: $municipalityId");
    print("➡️ Property Address (Formatted): $propertyAddress");

    Timestamp? fetchedTimestamp = await getLatestUploadTimestamp(
      districtId,
      municipalityId,
      propPhoneNum,
      propertyAddress,
    );

    if (fetchedTimestamp != null) {
      DateTime newTimestamp = fetchedTimestamp.toDate();

      // ✅ Only update UI if timestamp has changed
      if (latestImageTimestamps[propertyAddress] != newTimestamp) {
        setState(() {
          latestImageTimestamps[propertyAddress] = newTimestamp;
        });
        print("📅 Updated Timestamp for $propertyAddress: $newTimestamp");
      } else {
        print("✅ No timestamp change, avoiding unnecessary UI rebuild.");
      }
    }
  }


  Future<Timestamp?> getLatestUploadTimestamp(
      String? districtId, String municipalityId, String userPhoneNumber, String propertyAddress) async {
    try {
      QuerySnapshot querySnapshot;

      if (districtId != null && districtId.isNotEmpty) {
        // 🔹 District-based municipality
        querySnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('actionLogs')
            .doc(userPhoneNumber)
            .collection(propertyAddress)
            .orderBy('timestamp', descending: true) // Get latest entry
            .limit(1)
            .get();
      } else {
        // 🔹 Local municipality
        querySnapshot = await FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(municipalityId)
            .collection('actionLogs')
            .doc(userPhoneNumber)
            .collection(propertyAddress)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
      }

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first['timestamp']; // Return latest timestamp
      } else {
        print("⚠️ No timestamp found for $propertyAddress");
        return null; // No records found
      }
    } catch (e) {
      print("❌ Error fetching timestamp: $e");
      return null;
    }
  }




  Future<void> _notifyThisUser([DocumentSnapshot? documentSnapshot]) async {

    if (documentSnapshot != null) {
      username.text = documentSnapshot.id;
    }

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    void _createBottomSheet() async{
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
                                decoration: const InputDecoration(
                                    labelText: 'Message'),
                              ),
                            ),

                            const SizedBox(
                              height: 10,
                            ),
                            ElevatedButton(
                                child: const Text('Send Notification'),
                                onPressed: () async {

                                  DateTime now = DateTime.now();
                                  String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);



                                  final String tokenSelected = notifyToken;
                                  final String? userNumber = documentSnapshot?.id;
                                  final String notificationTitle = title.text;
                                  final String notificationBody = body.text;
                                  final String notificationDate = formattedDate;
                                  const bool readStatus = false;

                                  if (tokenSelected != null) {
                                    if(title.text != '' || title.text.isNotEmpty || body.text != '' || body.text.isNotEmpty) {
                                      await _listNotifications.add({
                                        "token": tokenSelected,
                                        "user": userNumber,
                                        "title": notificationTitle,
                                        "body": notificationBody,
                                        "read": readStatus,
                                        "date": notificationDate,
                                        "level": 'severe',
                                      });

                                      ///It can be changed to the firebase notification
                                      String titleText = title.text;
                                      String bodyText = body.text;

                                      ///gets users phone token to send notification to this phone
                                      if (userNumber != "") {
                                        DocumentSnapshot snap = await FirebaseFirestore.instance.collection("UserToken").doc(userNumber).get();
                                        String token = snap['token'];
                                        print('The phone number is retrieved as ::: $userNumber');
                                        print('The token is retrieved as ::: $token');
                                        sendPushMessage(token, titleText, bodyText);
                                        Fluttertoast.showToast(msg: 'The user has been sent the notification!', gravity: ToastGravity.CENTER);
                                      }
                                    } else {
                                      Fluttertoast.showToast(msg: 'Please Fill Header and Message of the notification!', gravity: ToastGravity.CENTER);
                                    }
                                  }

                                  username.text =  '';
                                  title.text =  '';
                                  body.text =  '';
                                  _headerController.text =  '';
                                  _messageController.text =  '';

                                  if(context.mounted)Navigator.of(context).pop();

                                }
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


  // Widget firebasePropertyCard(CollectionReference<Object?> propertiesDataStream) {
  //   return StreamBuilder<QuerySnapshot>(
  //     stream: propertiesDataStream.snapshots(),
  //     builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
  //       if (streamSnapshot.hasData) {
  //         // Filter the properties based on the search text
  //         var filteredDocs = streamSnapshot.data!.docs.where((doc) {
  //           var address = (doc['address'] as String).toLowerCase();
  //           var cellNumber = (doc['cellNumber'] as String).toLowerCase();
  //           var firstName = (doc['firstName'] as String).toLowerCase();
  //           var lastName = (doc['lastName'] as String).toLowerCase();
  //           var query = _searchBarController.text.trim().toLowerCase();
  //           return address.contains(query) ||
  //               cellNumber.contains(query) ||
  //               firstName.contains(query) ||
  //               lastName.contains(query);
  //         }).toList();
  //
  //         return ListView.builder(
  //           itemCount: _fetchedProperties.length,
  //           itemBuilder: (context, index) {
  //             final DocumentSnapshot documentSnapshot = filteredDocs[index];
  //
  //             // String eMeterNumber = documentSnapshot['meter_number'];
  //             String wMeterNumber = documentSnapshot['water_meter_number'];
  //             String propPhoneNum = documentSnapshot['cellNumber'];
  //
  //             String billMessage; // A check for if payment is outstanding or not
  //             if (documentSnapshot['eBill'] != '' &&
  //                 documentSnapshot['eBill'] != 'R0,000.00' &&
  //                 documentSnapshot['eBill'] != 'R0.00' &&
  //                 documentSnapshot['eBill'] != 'R0' &&
  //                 documentSnapshot['eBill'] != '0') {
  //               billMessage = 'Utilities bill outstanding: ${documentSnapshot['eBill']}';
  //             } else {
  //               billMessage = 'No outstanding payments';
  //             }
  //
  //             return Card(
  //               margin: const EdgeInsets.all(10),
  //               child: Padding(
  //                 padding: const EdgeInsets.all(20.0),
  //                 child: Column(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     const Center(
  //                       child: Text(
  //                         'Property Information',
  //                         style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  //                       ),
  //                     ),
  //                     const SizedBox(height: 10),
  //                     Text(
  //                       'Account Number: ${documentSnapshot['accountNumber']}',
  //                       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  //                     ),
  //                     const SizedBox(height: 5),
  //                     Text(
  //                       'Street Address: ${documentSnapshot['address']}',
  //                       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  //                     ),
  //                     const SizedBox(height: 5),
  //                     Text(
  //                       'Area Code: ${documentSnapshot['areaCode']}',
  //                       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  //                     ),
  //                     const SizedBox(height: 5),
  //                     // Text(
  //                     //   'Meter Number: ${documentSnapshot['meter_number']}',
  //                     //   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  //                     // ),
  //                     // const SizedBox(height: 5),
  //                     // Text(
  //                     //   'Meter Reading: ${documentSnapshot['meter_reading']}',
  //                     //   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  //                     // ),
  //                     // const SizedBox(height: 5),
  //                     Text(
  //                       'Water Meter Number: ${documentSnapshot['water_meter_number']}',
  //                       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  //                     ),
  //                     const SizedBox(height: 5),
  //                     Text(
  //                       'Water Meter Reading: ${documentSnapshot['water_meter_reading']}',
  //                       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  //                     ),
  //                     const SizedBox(height: 5),
  //                     Text(
  //                       'Phone Number: ${documentSnapshot['cellNumber']}',
  //                       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  //                     ),
  //                     const SizedBox(height: 5),
  //                     Text(
  //                       'First Name: ${documentSnapshot['firstName']}',
  //                       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  //                     ),
  //                     const SizedBox(height: 5),
  //                     Text(
  //                       'Surname: ${documentSnapshot['lastName']}',
  //                       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  //                     ),
  //                     const SizedBox(height: 5),
  //                     Text(
  //                       'ID Number: ${documentSnapshot['idNumber']}',
  //                       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  //                     ),
  //                     const SizedBox(height: 20),
  //                     // const Center(
  //                     //   child: Text(
  //                     //     'Electricity Meter Reading Photo',
  //                     //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  //                     //   ),
  //                     // ),
  //                     // const SizedBox(height: 5),
  //                     // Column(
  //                     //   children: [
  //                     //     Row(
  //                     //       mainAxisAlignment: MainAxisAlignment.center,
  //                     //       crossAxisAlignment: CrossAxisAlignment.center,
  //                     //       children: [
  //                     //         BasicIconButtonGrey(
  //                     //           onPress: () async {
  //                     //             eMeterNumber =
  //                     //             documentSnapshot['meter_number'];
  //                     //             propPhoneNum =
  //                     //             documentSnapshot['cellNumber'];
  //                     //             showDialog(
  //                     //                 barrierDismissible: false,
  //                     //                 context: context,
  //                     //                 builder: (context) {
  //                     //                   return AlertDialog(
  //                     //                     title: const Text(
  //                     //                         "Upload Electricity Meter"),
  //                     //                     content: const Text(
  //                     //                         "Uploading a new image will replace current image!\n\nAre you sure?"),
  //                     //                     actions: [
  //                     //                       IconButton(
  //                     //                         onPressed: () {
  //                     //                           Navigator.pop(context);
  //                     //                         },
  //                     //                         icon: const Icon(
  //                     //                           Icons.cancel,
  //                     //                           color: Colors.red,
  //                     //                         ),
  //                     //                       ),
  //                     //                       IconButton(
  //                     //                         onPressed: () async {
  //                     //                           Fluttertoast.showToast(
  //                     //                               msg:
  //                     //                               "Uploading a new image\nwill replace current image!");
  //                     //                           Navigator.push(
  //                     //                               context,
  //                     //                               MaterialPageRoute(
  //                     //                                   builder: (context) =>
  //                     //                                       ImageUploadMeter(
  //                     //                                         userNumber:
  //                     //                                         propPhoneNum,
  //                     //                                         meterNumber:
  //                     //                                         eMeterNumber,
  //                     //                                         municipalityUserEmail: userEmail,
  //                     //
  //                     //                                       )));
  //                     //                         },
  //                     //                         icon: const Icon(
  //                     //                           Icons.done,
  //                     //                           color: Colors.green,
  //                     //                         ),
  //                     //                       ),
  //                     //                     ],
  //                     //                   );
  //                     //                 });
  //                     //           },
  //                     //           labelText: 'Electricity',
  //                     //           fSize: 15,
  //                     //           faIcon: const FaIcon(
  //                     //             Icons.camera_alt,
  //                     //           ),
  //                     //           fgColor: Colors.black38,
  //                     //           btSize: const Size(50, 38),
  //                     //         ),
  //                     //         BasicIconButtonGrey(
  //                     //           onPress: () async {
  //                     //             _updateE(documentSnapshot);
  //                     //           },
  //                     //           labelText: 'Capture',
  //                     //           fSize: 15,
  //                     //           faIcon: const FaIcon(
  //                     //             Icons.edit,
  //                     //           ),
  //                     //           fgColor: Theme.of(context).primaryColor,
  //                     //           btSize: const Size(50, 38),
  //                     //         ),
  //                     //       ],
  //                     //     )
  //                     //   ],
  //                     // ),
  //                     // const SizedBox(height: 5),
  //                     // FutureBuilder<String>(
  //                     //     future:fetchPropertyAddress(
  //                     //         propPhoneNum, eMeterNumber,districtId,municipalityId)
  //                     //         .then((propertyAddress) => _getImage(
  //                     //         context,
  //                     //         'files/meters/$formattedMonth/$propPhoneNum/$propertyAddress/electricity/$eMeterNumber.jpg')),
  //                     //     builder: (context, snapshot) {
  //                     //       if (snapshot.hasData &&
  //                     //           snapshot.connectionState ==
  //                     //               ConnectionState.done) {
  //                     //         return GestureDetector(
  //                     //           onTap: () {
  //                     //             final imageProvider =
  //                     //             NetworkImage(snapshot.data!);
  //                     //             showImageViewer(context, imageProvider);
  //                     //           },
  //                     //           child: Container(
  //                     //             margin:
  //                     //             const EdgeInsets.only(bottom: 5),
  //                     //             height: 180,
  //                     //             child: Card(
  //                     //               color: Colors.white54,
  //                     //               semanticContainer: true,
  //                     //               clipBehavior:
  //                     //               Clip.antiAliasWithSaveLayer,
  //                     //               shape: RoundedRectangleBorder(
  //                     //                 borderRadius:
  //                     //                 BorderRadius.circular(10.0),
  //                     //               ),
  //                     //               elevation: 0,
  //                     //               margin: const EdgeInsets.all(10.0),
  //                     //               child: Center(
  //                     //                 // Ensuring the image is centered within the card
  //                     //                 child: Image.network(snapshot.data!,
  //                     //                     fit: BoxFit.cover),
  //                     //               ),
  //                     //             ),
  //                     //           ),
  //                     //         );
  //                     //       } else if (snapshot.hasError) {
  //                     //         return const Padding(
  //                     //           padding: EdgeInsets.all(20.0),
  //                     //           child: Center(
  //                     //             child: Column(
  //                     //               mainAxisSize: MainAxisSize.min,
  //                     //               children: [
  //                     //                 Text('Image not yet uploaded.'),
  //                     //                 SizedBox(height: 10),
  //                     //                 FaIcon(Icons.camera_alt),
  //                     //               ],
  //                     //             ),
  //                     //           ),
  //                     //         );
  //                     //       } else {
  //                     //         return Container(
  //                     //           height: 180,
  //                     //           margin: const EdgeInsets.all(10.0),
  //                     //           child: const Center(
  //                     //               child: CircularProgressIndicator()),
  //                     //         );
  //                     //       }
  //                     //     }),
  //                     const SizedBox(height: 10),
  //                     const Center(
  //                       child: Text(
  //                         'Water Meter Reading Photo',
  //                         style: TextStyle(fontSize: 16,
  //                             fontWeight: FontWeight.w700),
  //                       ),
  //                     ),
  //                     const SizedBox(height: 5,),
  //                     Column(
  //                       children: [
  //                         Row(
  //                           mainAxisAlignment: MainAxisAlignment.center,
  //                           crossAxisAlignment: CrossAxisAlignment.center,
  //                           children: [
  //                             Expanded(
  //                               child: BasicIconButtonGrey(
  //                                 onPress: () async {
  //                                   if (!isLocalUser && !isLocalMunicipality) {
  //                                     if (selectedMunicipality == null || selectedMunicipality == "Select Municipality") {
  //                                       Fluttertoast.showToast(
  //                                         msg: "Please select a municipality first!",
  //                                         toastLength: Toast.LENGTH_SHORT,
  //                                         gravity: ToastGravity.CENTER,
  //                                       );
  //                                       return; // Stop execution if no municipality is selected
  //                                     }
  //                                   }
  //
  //                                   // Determine the appropriate municipality context
  //                                   String municipalityContext = isLocalMunicipality || isLocalUser
  //                                       ? municipalityId
  //                                       : selectedMunicipality!;
  //
  //                                   if (municipalityContext.isEmpty) {
  //                                     Fluttertoast.showToast(
  //                                       msg: "Invalid municipality selection or missing municipality.",
  //                                       toastLength: Toast.LENGTH_SHORT,
  //                                       gravity: ToastGravity.CENTER,
  //                                     );
  //                                     return;
  //                                   }
  //                                   // Get values from the documentSnapshot
  //                                   wMeterNumber = documentSnapshot['water_meter_number'];
  //                                   propPhoneNum = documentSnapshot['cellNumber'];
  //
  //                                   // Ensure the address is correctly populated or fallback to 'unknown_address'
  //                                   String propertyAddress = documentSnapshot['address'];
  //
  //                                   print("Property Address: $propertyAddress");
  //
  //                                   // Store the values in local variables before showing the dialog
  //                                   String passedPropertyAddress = propertyAddress;
  //                                   String passedDistrictId = districtId;
  //                                   String passedMunicipalityId = municipalityId;
  //
  //                                   // Show the dialog
  //                                   showDialog(
  //                                       barrierDismissible: false,
  //                                       context: context,
  //                                       builder: (context) {
  //                                         return AlertDialog(
  //                                           title: const Text("Upload Water Meter"),
  //                                           content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
  //                                           actions: [
  //                                             IconButton(
  //                                               onPressed: () {
  //                                                 Navigator.pop(context); // Close the dialog
  //                                               },
  //                                               icon: const Icon(
  //                                                 Icons.cancel,
  //                                                 color: Colors.red,
  //                                               ),
  //                                             ),
  //                                             IconButton(
  //                                               onPressed: () async {
  //                                                 Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
  //
  //                                                 // Ensure the values are passed correctly
  //                                                 Navigator.push(
  //                                                   context,
  //                                                   MaterialPageRoute(
  //                                                     builder: (context) => ImageUploadWater(
  //                                                         userNumber: propPhoneNum,
  //                                                         meterNumber: wMeterNumber,
  //                                                         propertyAddress: passedPropertyAddress, // Pass the property address stored earlier
  //                                                         districtId: passedDistrictId,           // Pass the districtId stored earlier
  //                                                         municipalityId: passedMunicipalityId, isLocalMunicipality: widget.isLocalMunicipality, isLocalUser: isLocalUser,    // Pass the municipalityId stored earlier
  //                                                     ),
  //                                                   ),
  //                                                 );
  //                                               },
  //                                               icon: const Icon(
  //                                                 Icons.done,
  //                                                 color: Colors.green,
  //                                               ),
  //                                             ),
  //                                           ],
  //                                         );
  //                                       });
  //                                 },
  //                                 labelText: 'Update image and reading',
  //                                 fSize: 16,
  //                                 faIcon: const FaIcon(Icons.camera_alt,),
  //                                 fgColor: Colors.black38,
  //                                 btSize: const Size(100, 38),
  //                               ),
  //                             ),
  //                             // BasicIconButtonGrey(
  //                             //   onPress: () async {
  //                             //     _updateW(documentSnapshot);
  //                             //   },
  //                             //   labelText: 'Capture',
  //                             //   fSize: 16,
  //                             //   faIcon: const FaIcon(Icons.edit,),
  //                             //   fgColor: Theme.of(context).primaryColor,
  //                             //   btSize: const Size(100, 38),
  //                             // ),
  //                           ],
  //                         )
  //                       ],
  //                     ),
  //
  //               FutureBuilder<String>(
  //                 future: fetchPropertyAddress(
  //                   propPhoneNum,
  //                   wMeterNumber,
  //                   districtId,
  //                   municipalityId,
  //                   isLocalMunicipality,
  //                 ).then((propertyAddress) {
  //                   // Print the retrieved property address to verify its value
  //                   print('Property Address retrieved: $propertyAddress');
  //
  //                   // Construct the image path and print it to verify correctness
  //                   String imagePath = 'files/meters/$formattedMonth/$propPhoneNum/$propertyAddress/water/$wMeterNumber.jpg';
  //                   print('Constructed Image Path: $imagePath');
  //
  //                   // Get the image URL
  //                   return _getImageW(context, imagePath);
  //                 }),
  //                 builder: (context, snapshot) {
  //                   if (snapshot.hasData && snapshot.connectionState == ConnectionState.done) {
  //                     return GestureDetector(
  //                       onTap: () {
  //                         final imageProvider = NetworkImage(snapshot.data!);
  //                         showImageViewer(context, imageProvider);
  //                       },
  //                       child: Container(
  //                         margin: const EdgeInsets.only(bottom: 5),
  //                         height: 180,
  //                         child: Card(
  //                           color: Colors.white54,
  //                           semanticContainer: true,
  //                           clipBehavior: Clip.antiAliasWithSaveLayer,
  //                           shape: RoundedRectangleBorder(
  //                             borderRadius: BorderRadius.circular(10.0),
  //                           ),
  //                           elevation: 0,
  //                           margin: const EdgeInsets.all(10.0),
  //                           child: Center(
  //                             // Ensuring the image is centered within the card
  //                             child: Image.network(snapshot.data!, fit: BoxFit.cover),
  //                           ),
  //                         ),
  //                       ),
  //                     );
  //                   } else if (snapshot.hasError) {
  //                     return const Padding(
  //                       padding: EdgeInsets.all(20.0),
  //                       child: Center(
  //                         child: Column(
  //                           mainAxisSize: MainAxisSize.min,
  //                           children: [
  //                             Text('Image not yet uploaded.'),
  //                             SizedBox(height: 10),
  //                             FaIcon(Icons.camera_alt),
  //                           ],
  //                         ),
  //                       ),
  //                     );
  //                   } else {
  //                     return Container(
  //                       height: 180,
  //                       margin: const EdgeInsets.all(10.0),
  //                       child: const Center(
  //                         child: CircularProgressIndicator(),
  //                       ),
  //                     );
  //                   }
  //                 },
  //               ),
  //
  //               Text(
  //                       billMessage,
  //                       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  //                     ),
  //                     const SizedBox(height: 10),
  //                     Column(
  //                       children: [
  //                         Row(
  //                           mainAxisAlignment: MainAxisAlignment.center,
  //                           crossAxisAlignment: CrossAxisAlignment.center,
  //                           children: [
  //                             BasicIconButtonGrey(
  //                               onPress: () {
  //                                 if (!isLocalUser && !isLocalMunicipality) {
  //                                   if (selectedMunicipality == null || selectedMunicipality == "Select Municipality") {
  //                                     Fluttertoast.showToast(
  //                                       msg: "Please select a municipality first!",
  //                                       toastLength: Toast.LENGTH_SHORT,
  //                                       gravity: ToastGravity.CENTER,
  //                                     );
  //                                     return; // Stop execution if no municipality is selected
  //                                   }
  //                                 }
  //
  //                                 // Determine the appropriate municipality context
  //                                 String municipalityContext = isLocalMunicipality || isLocalUser
  //                                     ? municipalityId
  //                                     : selectedMunicipality!;
  //
  //                                 if (municipalityContext.isEmpty) {
  //                                   Fluttertoast.showToast(
  //                                     msg: "Invalid municipality selection or missing municipality.",
  //                                     toastLength: Toast.LENGTH_SHORT,
  //                                     gravity: ToastGravity.CENTER,
  //                                   );
  //                                   return;
  //                                 }
  //                                 showDialog(
  //                                     barrierDismissible: false,
  //                                     context: context,
  //                                     builder: (context) {
  //                                       return AlertDialog(
  //                                         title: const Text("Application for service"),
  //                                         content: const Text("Upgrading or installing a new meter for a property requires a filled application for service document!\nYour options are:\n\n- Download the Application For Service document to save & fill manually.\n\n- Call Infrastructure, Planning & Survey to assist with this process."),
  //                                         actions: [
  //                                           Center(
  //                                             child: Column(
  //                                               children: [
  //                                                 Center(
  //                                                   child: Row(
  //                                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                                                     children: [
  //                                                       BasicIconButtonGrey(
  //                                                         onPress: () async {
  //                                                           Fluttertoast.showToast(msg: "Entering contact number for Infrastructure, Planning & Survey!");
  //                                                           final Uri _tel = Uri.parse('tel:+27${0333923000}');
  //                                                           launchUrl(_tel);
  //                                                           Navigator.pop(context);
  //                                                         },
  //                                                         labelText: "Call", fSize: 12, faIcon: const FaIcon(Icons.phone), fgColor: Colors.green, btSize: const Size(50, 30),
  //                                                       ),
  //                                                       BasicIconButtonGrey(
  //                                                         onPress: () async {
  //                                                           Fluttertoast.showToast(msg: "Now directing to application for service document!");
  //                                                           final Uri _url = Uri.parse('http://www.msunduzi.gov.za/site/search/downloadencode/APPLICATION%20FOR%20SERVICES%20-%20INDIVIDUALS.pdf');
  //                                                           _launchURLExternal(_url);
  //                                                           Navigator.pop(context);
  //                                                         },
  //                                                         labelText: "Apply", fSize: 12, faIcon: const FaIcon(Icons.picture_as_pdf), fgColor: Colors.grey, btSize: const Size(50, 30),
  //                                                       ),
  //                                                     ],
  //                                                   ),
  //                                                 ),
  //                                                 BasicIconButtonGrey(
  //                                                   onPress: () {
  //                                                     Navigator.pop(context);
  //                                                   },
  //                                                   labelText: "Cancel", fSize: 12, faIcon: const FaIcon(Icons.cancel), fgColor: Colors.red, btSize: const Size(50, 30),
  //                                                 ),
  //                                               ],
  //                                             ),
  //                                           ),
  //                                         ],
  //                                       );
  //                                     }
  //                                 );
  //                               },
  //                               labelText: 'Create Request',
  //                               fSize: 16,
  //                               faIcon: const FaIcon(Icons.build),
  //                               fgColor: Colors.orangeAccent,
  //                               btSize: const Size(100, 38),
  //                             ),
  //                           ],
  //                         ),
  //                         const SizedBox(height: 5),
  //                         // BasicIconButtonGrey(
  //                         //   onPress: () async {
  //                         //     _update(documentSnapshot);
  //                         //   },
  //                         //   labelText: 'Update Meter Info',
  //                         //   fSize: 16,
  //                         //   faIcon: const FaIcon(Icons.library_books_sharp),
  //                         //   fgColor: Colors.orangeAccent,
  //                         //   btSize: const Size(100, 38),
  //                         // ),
  //                         const SizedBox(height: 5),
  //                         BasicIconButtonGrey(
  //                           onPress: () async {
  //                             if (!isLocalUser && !isLocalMunicipality) {
  //                               if (selectedMunicipality == null || selectedMunicipality == "Select Municipality") {
  //                                 Fluttertoast.showToast(
  //                                   msg: "Please select a municipality first!",
  //                                   toastLength: Toast.LENGTH_SHORT,
  //                                   gravity: ToastGravity.CENTER,
  //                                 );
  //                                 return; // Stop execution if no municipality is selected
  //                               }
  //                             }
  //
  //                             // Determine the appropriate municipality context
  //                             String municipalityContext = isLocalMunicipality || isLocalUser
  //                                 ? municipalityId
  //                                 : selectedMunicipality!;
  //
  //                             if (municipalityContext.isEmpty) {
  //                               Fluttertoast.showToast(
  //                                 msg: "Invalid municipality selection or missing municipality.",
  //                                 toastLength: Toast.LENGTH_SHORT,
  //                                 gravity: ToastGravity.CENTER,
  //                               );
  //                               return;
  //                             }
  //                             String accountNumberAll = documentSnapshot['accountNumber'];
  //                             String locationGivenAll = documentSnapshot['address'];
  //                             Navigator.push(context, MaterialPageRoute(builder: (context) => MapScreenProp(propAddress: locationGivenAll, propAccNumber: accountNumberAll)));
  //                           },
  //                           labelText: 'Map',
  //                           fSize: 16,
  //                           faIcon: const FaIcon(Icons.map),
  //                           fgColor: Colors.green,
  //                           btSize: const Size(100, 38),
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             );
  //           },
  //         );
  //       }
  //       return const Center(child: CircularProgressIndicator());
  //     },
  //   );
  // }
  Widget firebasePropertyCard(List<QueryDocumentSnapshot<Object?>> properties) {
    if (isLoading) {
      // Display a loading spinner while fetching data
      return const Center(child: CircularProgressIndicator());
    }


    return  GestureDetector(
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
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final DocumentSnapshot documentSnapshot = properties[index];

              // Extract property details
              String wMeterNumber = documentSnapshot['water_meter_number'];
              String propPhoneNum = documentSnapshot['cellNumber'];
              String propertyAddress = documentSnapshot['address']; // Get address for lookup
              String previousReading = previousMonthReadings[propertyAddress] ?? "N/A"; // Retrieve previous reading
              String currentReading = currentMonthReadings[propertyAddress] ?? "N/A";
              String billMessage; // A check for if payment is outstanding or not
              if (documentSnapshot['eBill'] != '' &&
                  documentSnapshot['eBill'] != 'R0,000.00' &&
                  documentSnapshot['eBill'] != 'R0.00' &&
                  documentSnapshot['eBill'] != 'R0' &&
                  documentSnapshot['eBill'] != '0') {
                billMessage = 'Utilities bill outstanding: ${documentSnapshot['eBill']}';
              } else {
                billMessage = 'No outstanding payments';
              }

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Property Information',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Account Number: ${documentSnapshot['accountNumber']}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Street Address: ${documentSnapshot['address']}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Area Code: ${documentSnapshot['areaCode']}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Water Meter Number: ${documentSnapshot['water_meter_number']}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Previous Month ($previousMonth) Reading: $previousReading', // ✅ Add previous month's reading
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Water Meter Reading: $currentReading',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Phone Number: ${documentSnapshot['cellNumber']}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'First Name: ${documentSnapshot['firstName']}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Surname: ${documentSnapshot['lastName']}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'ID Number: ${documentSnapshot['idNumber']}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          'Water Meter Reading Photo',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Display the water meter image
                      FutureBuilder<String>(
                        future: fetchPropertyAddress(
                          propPhoneNum,
                          wMeterNumber,
                          districtId,
                          municipalityId,
                          isLocalMunicipality,
                        ).then((propertyAddress) {
                          fetchLatestUploadTimestamp(propertyAddress, propPhoneNum);
                          print('Property Address retrieved: $propertyAddress');
                          String imagePath = 'files/meters/$formattedMonth/$propPhoneNum/$propertyAddress/water/$wMeterNumber.jpg';
                          print('Constructed Image Path: $imagePath');
                          return _getImageW(context, imagePath,propertyAddress);
                        }),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.connectionState == ConnectionState.done) {
                            return GestureDetector(
                              onTap: () {
                                final imageProvider = NetworkImage(snapshot.data!);
                                showImageViewer(context, imageProvider);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 5),
                                height: 180,
                                child: Card(
                                  color: Colors.white54,
                                  semanticContainer: true,
                                  clipBehavior: Clip.antiAliasWithSaveLayer,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  elevation: 0,
                                  margin: const EdgeInsets.all(10.0),
                                  child: Center(
                                    child: Image.network(snapshot.data!, fit: BoxFit.cover),
                                  ),
                                ),
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Image not yet uploaded.'),
                                    SizedBox(height: 10),
                                    FaIcon(Icons.camera_alt),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            return Container(
                              height: 180,
                              margin: const EdgeInsets.all(10.0),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                        },
                      ),
                      Center(
                        child: Text(
                          latestImageTimestamps[propertyAddress] != null
                              ? "📅 Image uploaded on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(latestImageTimestamps[propertyAddress]!)}"
                              : "⚠️ No upload history available.",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          billMessage,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              BasicIconButtonGrey(
                                onPress: () {
                                  if (!isLocalUser && !isLocalMunicipality) {
                                    if (selectedMunicipality == null || selectedMunicipality == "Select Municipality") {
                                      Fluttertoast.showToast(
                                        msg: "Please select a municipality first!",
                                        toastLength: Toast.LENGTH_SHORT,
                                        gravity: ToastGravity.CENTER,
                                      );
                                      return; // Stop execution if no municipality is selected
                                    }
                                  }

                                  // Determine the appropriate municipality context
                                  String municipalityContext = isLocalMunicipality || isLocalUser
                                      ? municipalityId
                                      : selectedMunicipality!;

                                  if (municipalityContext.isEmpty) {
                                    Fluttertoast.showToast(
                                      msg: "Invalid municipality selection or missing municipality.",
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.CENTER,
                                    );
                                    return;
                                  }
                                  showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text("Application for service"),
                                          content: const Text("Upgrading or installing a new meter for a property requires a filled application for service document!\nYour options are:\n\n- Download the Application For Service document to save & fill manually.\n\n- Call Infrastructure, Planning & Survey to assist with this process."),
                                          actions: [
                                            Center(
                                              child: Column(
                                                children: [
                                                  Center(
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        BasicIconButtonGrey(
                                                          onPress: () async {
                                                            Fluttertoast.showToast(msg: "Entering contact number for Infrastructure, Planning & Survey!");
                                                            final Uri _tel = Uri.parse('tel:+27${0333923000}');
                                                            launchUrl(_tel);
                                                            Navigator.pop(context);
                                                          },
                                                          labelText: "Call", fSize: 12, faIcon: const FaIcon(Icons.phone), fgColor: Colors.green, btSize: const Size(50, 30),
                                                        ),
                                                        BasicIconButtonGrey(
                                                          onPress: () async {
                                                            Fluttertoast.showToast(msg: "Now directing to application for service document!");
                                                            final Uri _url = Uri.parse('http://www.msunduzi.gov.za/site/search/downloadencode/APPLICATION%20FOR%20SERVICES%20-%20INDIVIDUALS.pdf');
                                                            _launchURLExternal(_url);
                                                            Navigator.pop(context);
                                                          },
                                                          labelText: "Apply", fSize: 12, faIcon: const FaIcon(Icons.picture_as_pdf), fgColor: Colors.grey, btSize: const Size(50, 30),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  BasicIconButtonGrey(
                                                    onPress: () {
                                                      Navigator.pop(context);
                                                    },
                                                    labelText: "Cancel", fSize: 12, faIcon: const FaIcon(Icons.cancel), fgColor: Colors.red, btSize: const Size(50, 30),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                  );
                                },
                                labelText: 'Create Request',
                                fSize: 16,
                                faIcon: const FaIcon(Icons.build),
                                fgColor: Colors.orangeAccent,
                                btSize: const Size(100, 38),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),

                          const SizedBox(height: 5),
                          BasicIconButtonGrey(
                            onPress: () async {
                              if (!isLocalUser && !isLocalMunicipality) {
                                if (selectedMunicipality == null || selectedMunicipality == "Select Municipality") {
                                  Fluttertoast.showToast(
                                    msg: "Please select a municipality first!",
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.CENTER,
                                  );
                                  return; // Stop execution if no municipality is selected
                                }
                              }

                              // Determine the appropriate municipality context
                              String municipalityContext = isLocalMunicipality || isLocalUser
                                  ? municipalityId
                                  : selectedMunicipality!;

                              if (municipalityContext.isEmpty) {
                                Fluttertoast.showToast(
                                  msg: "Invalid municipality selection or missing municipality.",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.CENTER,
                                );
                                return;
                              }
                              String accountNumberAll = documentSnapshot['accountNumber'];
                              String locationGivenAll = documentSnapshot['address'];
                              Navigator.push(context, MaterialPageRoute(builder: (context) => MapScreenProp(propAddress: locationGivenAll, propAccNumber: accountNumberAll)));
                            },
                            labelText: 'Map',
                            fSize: 16,
                            faIcon: const FaIcon(Icons.map),
                            fgColor: Colors.green,
                            btSize: const Size(100, 38),
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
                  bottom: MediaQuery
                      .of(ctx)
                      .viewInsets
                      .bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(labelText: 'Account Number'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Street Address'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      keyboardType:
                      const TextInputType.numberWithOptions(),
                      controller: _areaCodeController,
                      decoration: const InputDecoration(labelText: 'Area Code',),
                    ),
                  ),
                  // Visibility(
                  //   visible: visHide,
                  //   child: TextField(
                  //     controller: _meterNumberController,
                  //     decoration: const InputDecoration(labelText: 'Meter Number'),
                  //   ),
                  // ),
                  // Visibility(
                  //   visible: visHide,
                  //   child: TextField(
                  //     controller: _meterReadingController,
                  //     decoration: const InputDecoration(labelText: 'Meter Reading'),
                  //   ),
                  // ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _waterMeterController,
                      decoration: const InputDecoration(labelText: 'Water Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _waterMeterReadingController,
                      decoration: const InputDecoration(labelText: 'Water Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _cellNumberController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
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
                      final String accountNumber = _accountNumberController.text;
                      final String address = _addressController.text;
                      final String areaCode = _areaCodeController.text;
                      // final String meterNumber = _meterNumberController.text;
                      // final String meterReading = _meterReadingController.text;
                      final String waterMeterNumber = _waterMeterController.text;
                      final String waterMeterReading = _waterMeterReadingController.text;
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

                        if(context.mounted)Navigator.of(context).pop();
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
      _waterMeterReadingController.text = documentSnapshot['water_meter_reading'];
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
                  bottom: MediaQuery
                      .of(ctx)
                      .viewInsets
                      .bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Meter at ${documentSnapshot?['address']}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Visibility(
                            visible: visShow,
                            child: const Icon(
                              Icons.notification_important,
                              color: Colors.red,)),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(labelText: 'Account Number'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Street Address'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      keyboardType:
                      const TextInputType.numberWithOptions(),
                      controller: _areaCodeController,
                      decoration: const InputDecoration(labelText: 'Area Code',),
                    ),
                  ),
                  // Visibility(
                  //   visible: visShow,
                  //   child: TextField(
                  //     controller: _meterNumberController,
                  //     decoration: const InputDecoration(labelText: 'Electricity Meter Number'),
                  //   ),
                  // ),
                  // Visibility(
                  //   visible: visShow,
                  //   child: TextField(
                  //     maxLength: 5,
                  //     maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  //     keyboardType: TextInputType.number,
                  //     controller: _meterReadingController,
                  //     decoration: const InputDecoration(labelText: 'Electricity Meter Reading'),
                  //   ),
                  // ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _waterMeterController,
                      decoration: const InputDecoration(labelText: 'Water Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      maxLength: 8,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      keyboardType: TextInputType.number,
                      controller: _waterMeterReadingController,
                      decoration: const InputDecoration(labelText: 'Water Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _cellNumberController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _idNumberController,
                      decoration: const InputDecoration(labelText: 'ID Number'),
                    ),
                  ),
                  const SizedBox(height: 20,),
                  ElevatedButton(
                    child: const Text('Update'),
                    onPressed: () async {
                      final String accountNumber = _accountNumberController.text;
                      final String address = _addressController.text;
                      final int areaCode = int.parse(_areaCodeController.text);
                      // final String meterNumber = _meterNumberController.text;
                      // final String meterReading = _meterReadingController.text;
                      final String waterMeterNumber = _waterMeterController.text;
                      final String waterMeterReading = _waterMeterReadingController.text;
                      final String cellNumber = _cellNumberController.text;
                      final String firstName = _firstNameController.text;
                      final String lastName = _lastNameController.text;
                      final String idNumber = _idNumberController.text;

                      if (accountNumber != null) {
                        await _propList
                            ?.doc(documentSnapshot!.id)
                            .update({
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
                          "userID" : userID,
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

                        if(context.mounted)Navigator.of(context).pop();

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
  //     _waterMeterReadingController.text = documentSnapshot['water_meter_reading'];
  //     _cellNumberController.text = documentSnapshot['cellNumber'];
  //     _firstNameController.text = documentSnapshot['firstName'];
  //     _lastNameController.text = documentSnapshot['lastName'];
  //     _idNumberController.text = documentSnapshot['idNumber'];
  //     userID = documentSnapshot['userID'];
  //   }
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
  //                 bottom: MediaQuery
  //                     .of(ctx)
  //                     .viewInsets
  //                     .bottom + 20),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Visibility(
  //                   visible: visHide,
  //                   child: TextField(
  //                     controller: _accountNumberController,
  //                     decoration: const InputDecoration(labelText: 'Account Number'),
  //                   ),
  //                 ),
  //                 Visibility(
  //                   visible: visHide,
  //                   child: TextField(
  //                     controller: _addressController,
  //                     decoration: const InputDecoration(labelText: 'Street Address'),
  //                   ),
  //                 ),
  //                 Visibility(
  //                   visible: visHide,
  //                   child: TextField(
  //                     keyboardType:
  //                     const TextInputType.numberWithOptions(),
  //                     controller: _areaCodeController,
  //                     decoration: const InputDecoration(labelText: 'Area Code',),
  //                   ),
  //                 ),
  //                 Visibility(
  //                   visible: visShow,
  //                   child: TextField(
  //                     controller: _meterNumberController,
  //                     decoration: const InputDecoration(labelText: 'Electricity Meter Number'),
  //                   ),
  //                 ),
  //                 Visibility(
  //                   visible: visShow,
  //                   child: TextField(
  //                     maxLength: 5,
  //                     maxLengthEnforcement: MaxLengthEnforcement.enforced,
  //                     keyboardType: TextInputType.number,
  //                     controller: _meterReadingController,
  //                     decoration: const InputDecoration(labelText: 'Electricity Meter Reading'),
  //                   ),
  //                 ),
  //                 Visibility(
  //                   visible: visHide,
  //                   child: TextField(
  //                     controller: _waterMeterController,
  //                     decoration: const InputDecoration(labelText: 'Water Meter Number'),
  //                   ),
  //                 ),
  //                 Visibility(
  //                   visible: visHide,
  //                   child: TextField(
  //                     maxLength: 8,
  //                     maxLengthEnforcement: MaxLengthEnforcement.enforced,
  //                     keyboardType: TextInputType.number,
  //                     controller: _waterMeterReadingController,
  //                     decoration: const InputDecoration(labelText: 'Water Meter Reading'),
  //                   ),
  //                 ),
  //                 Visibility(
  //                   visible: visHide,
  //                   child: TextField(
  //                     controller: _cellNumberController,
  //                     decoration: const InputDecoration(labelText: 'Phone Number'),
  //                   ),
  //                 ),
  //                 Visibility(
  //                   visible: visHide,
  //                   child: TextField(
  //                     controller: _firstNameController,
  //                     decoration: const InputDecoration(labelText: 'First Name'),
  //                   ),
  //                 ),
  //                 Visibility(
  //                   visible: visHide,
  //                   child: TextField(
  //                     controller: _lastNameController,
  //                     decoration: const InputDecoration(labelText: 'Last Name'),
  //                   ),
  //                 ),
  //                 Visibility(
  //                   visible: visHide,
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
  //                     final String accountNumber = _accountNumberController.text;
  //                     final String address = _addressController.text;
  //                     final int areaCode = int.parse(_areaCodeController.text);
  //                     final String meterNumber = _meterNumberController.text;
  //                     final String meterReading = _meterReadingController.text;
  //                     final String waterMeterNumber = _waterMeterController.text;
  //                     final String waterMeterReading = _waterMeterReadingController.text;
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
  //
  //                     Map<String, dynamic> updateDetails = {
  //                       "accountNumber": accountNumber,
  //                       "address": address,
  //                       "areaCode": areaCode,
  //                       "meter_number": meterNumber,
  //                       "meter_reading": meterReading,
  //                       "water_meter_Number": waterMeterNumber,
  //                       "water_meter_reading": waterMeterReading,
  //                       "cellNumber": cellNumber,
  //                       "firstName": firstName,
  //                       "lastName": lastName,
  //                       "idNumber": idNumber,
  //                       "userId": userID,
  //                     };
  //                     if (accountNumber.isNotEmpty) {
  //                       await documentSnapshot?.reference.update(updateDetails);
  //                       print("municipalityUserEmail: ${widget.municipalityUserEmail}");
  //                       // Log the update action using the municipalityUserEmail from the ImageZoomPage
  //                       await logEMeterReadingUpdate(documentSnapshot?['cellNumber'],address,
  //                           widget.municipalityUserEmail ?? "Unknown",districtId,municipalityId,
  //                           updateDetails);
  //
  //                       Navigator.pop(context);
  //                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //                         content: Text("Meter readings updated successfully"),
  //                         duration: Duration(seconds: 2),
  //                       ));
  //                     } else {
  //                       // Handle the case where account number is not entered
  //                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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
  //
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
  //                       if(context.mounted)Navigator.of(context).pop();
  //
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
      _waterMeterReadingController.text = documentSnapshot['water_meter_reading'];
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
                  bottom: MediaQuery
                      .of(ctx)
                      .viewInsets
                      .bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(labelText: 'Account Number'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Street Address'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      keyboardType:
                      const TextInputType.numberWithOptions(),
                      controller: _areaCodeController,
                      decoration: const InputDecoration(labelText: 'Area Code',),
                    ),
                  ),
                  // Visibility(
                  //   visible: visHide,
                  //   child: TextField(
                  //     controller: _meterNumberController,
                  //     decoration: const InputDecoration(labelText: 'Electricity Meter Number'),
                  //   ),
                  // ),
                  // Visibility(
                  //   visible: visHide,
                  //   child: TextField(
                  //     maxLength: 5,
                  //     maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  //     keyboardType: TextInputType.number,
                  //     controller: _meterReadingController,
                  //     decoration: const InputDecoration(labelText: 'Electricity Meter Reading'),
                  //   ),
                  // ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _waterMeterController,
                      decoration: const InputDecoration(labelText: 'Water Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      maxLength: 8,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      keyboardType: TextInputType.number,
                      controller: _waterMeterReadingController,
                      decoration: const InputDecoration(labelText: 'Water Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _cellNumberController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
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
                      final String accountNumber = _accountNumberController.text;
                      final String address = _addressController.text;
                      final int areaCode = int.parse(_areaCodeController.text);
                      // final String meterNumber = _meterNumberController.text;
                      // final String meterReading = _meterReadingController.text;
                      final String waterMeterNumber = _waterMeterController.text;
                      final String waterMeterReading = _waterMeterReadingController.text;
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
                        await documentSnapshot?.reference.update(updateDetails);

                        // Log the update action using the municipalityUserEmail from the ImageZoomPage
                        await logWMeterReadingUpdate(documentSnapshot?['cellNumber'],address,
                            widget.municipalityUserEmail ?? "Unknown",districtId,municipalityId,
                            updateDetails);

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Meter readings updated successfully"),
                          duration: Duration(seconds: 2),
                        ));
                      } else {
                        // Handle the case where account number is not entered
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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

                        if(context.mounted)Navigator.of(context).pop();

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

   if(context.mounted) {
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have successfully deleted an account')));
   }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      // Display a loading spinner while fetching data
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('All Properties', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.green,
        actions: <Widget>[
          Visibility(
            visible: false,
            child: IconButton(
              onPressed: () {
                // Generate Report here
              },
              icon: const Icon(Icons.file_copy_outlined, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 5),
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
                            selectedMunicipality == "Select Municipality") {
                          fetchPropertiesForAllMunicipalities();
                        } else {
                          municipalityId = newValue!;
                          fetchPropertiesByMunicipality(newValue);
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
            ),// Search bar
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: SearchBar(
              controller: _searchBarController,
              padding: const MaterialStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(horizontal: 16.0)),
              leading: const Icon(Icons.search),
              hintText: "Search",
            ),
          ),
          // Search bar end
          Expanded(
            child: firebasePropertyCard(_fetchedProperties),
          ),
        ],
      ),
    );
  }


  void reportGeneration(CollectionReference<Object?> propertiesDataStream){
    final excel.Workbook workbook = excel.Workbook();
    workbook.worksheets[0];

    final List<int> bytes = workbook.saveAsStream();
    File('Municipality Property Reports.xlsx').writeAsBytes(bytes);

    workbook.dispose();

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
      dropdownMonths = ['Select Month', month10,month11,month12,currentMonth,];
    } else if (currentMonth.contains(month2)) {
      dropdownMonths = ['Select Month', month11,month12,month1,currentMonth,];
    } else if (currentMonth.contains(month3)) {
      dropdownMonths = ['Select Month', month12,month1,month2,currentMonth,];
    } else if (currentMonth.contains(month4)) {
      dropdownMonths = ['Select Month', month1,month2,month3,currentMonth,];
    } else if (currentMonth.contains(month5)) {
      dropdownMonths = ['Select Month', month2,month3,month4,currentMonth,];
    } else if (currentMonth.contains(month6)) {
      dropdownMonths = ['Select Month', month3,month4,month5,currentMonth,];
    } else if (currentMonth.contains(month7)) {
      dropdownMonths = ['Select Month', month4,month5,month6,currentMonth,];
    } else if (currentMonth.contains(month8)) {
      dropdownMonths = ['Select Month', month5,month6,month7,currentMonth,];
    } else if (currentMonth.contains(month9)) {
      dropdownMonths = ['Select Month', month6,month7,month8,currentMonth,];
    } else if (currentMonth.contains(month10)) {
      dropdownMonths = ['Select Month', month7,month8,month9,currentMonth,];
    } else if (currentMonth.contains(month11)) {
      dropdownMonths = ['Select Month', month8,month9,month10,currentMonth,];
    } else if (currentMonth.contains(month12)) {
      dropdownMonths = ['Select Month', month9,month10,month11,currentMonth,];
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

  _launchURL(url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  _launchURLExternal(url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url,
          mode: LaunchMode.externalNonBrowserApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  ///pdf view loader getting file name onPress/onTap that passes pdf filename to this class.
  void openPDF(BuildContext context, File file) => Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
  );
}