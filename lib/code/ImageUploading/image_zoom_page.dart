import 'dart:io';
import 'dart:convert';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:municipal_services/code/DisplayPages/dashboard_official.dart';
import 'package:municipal_services/code/DisplayPages/display_all_capture.dart';

import 'package:municipal_services/code/ImageUploading/image_upload_meter.dart';
import 'package:municipal_services/code/ImageUploading/image_upload_water.dart';
import 'package:municipal_services/code/MapTools/map_screen_prop.dart';
import 'package:municipal_services/code/MapTools/map_screen.dart';
import 'package:municipal_services/code/PDFViewer/pdf_api.dart';
import 'package:municipal_services/code/PDFViewer/view_pdf.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';

import '../DisplayPages/log_screen.dart';

class ImageZoomPage extends StatefulWidget {
  const ImageZoomPage({
    super.key,
    required this.imageName,
    required this.addressSnap,
    this.municipalityUserEmail,
    required this.isLocalMunicipality, // Add this to handle local municipality logic
    required this.districtId,
    required this.municipalityId,
    required this.isLocalUser,
  });

  final String imageName;
  final String addressSnap;
  final String? municipalityUserEmail;
  final bool isLocalMunicipality; // New property
  final String districtId; // Required for district municipalities
  final String municipalityId;
  final bool isLocalUser;

  @override
  _ImageZoomPageState createState() => _ImageZoomPageState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

final User? user = auth.currentUser;
final uid = user?.uid;
final phone = user?.phoneNumber;
String userID = uid as String;
String phoneNum = phone as String;
DateTime now = DateTime.now();

String accountNumber = ' ';
String locationGiven = ' ';
// String eMeterNumber = ' ';
String accountNumberW = ' ';
String locationGivenW = ' ';
String wMeterNumber = ' ';
String propPhoneNum = ' ';

bool visibilityState1 = true;
bool visibilityState2 = false;
bool imgUploadCheck = false;

final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;

class FireStorageService extends ChangeNotifier {
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async {
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

Future<String> _getImageW(BuildContext context, String imagePath) async {
  try {
    final ref = FirebaseStorage.instance.ref().child(imagePath);
    final imageUrl = await ref.getDownloadURL();
    print('Image URL: $imageUrl');
    return imageUrl;
  } catch (e) {
    print('Error fetching image: $e');
    throw Exception('Error fetching image: $e');
  }
}

Future<String> fetchPropertyAddress(String phoneNumber, String meterNumber,
    bool isLocalMunicipality, String districtId, String municipalityId) async {
  try {
    QuerySnapshot querySnapshot;

    if (isLocalMunicipality) {
      // Query for local municipalities
      querySnapshot = await FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('properties')
          .where('cellNumber', isEqualTo: phoneNumber)
          .where('water_meter_number',
              isEqualTo: meterNumber) // Filter by meter number
          .limit(1)
          .get();
    } else {
      // Query for district municipalities
      querySnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('properties')
          .where('cellNumber', isEqualTo: phoneNumber)
          .where('water_meter_number',
              isEqualTo: meterNumber) // Filter by meter number
          .limit(1)
          .get();
    }

    if (querySnapshot.docs.isNotEmpty) {
      // Correctly return the address of the matched property
      return querySnapshot.docs.first['address'];
    } else {
      throw Exception('No property found for this meter number.');
    }
  } catch (e) {
    print('Error fetching property address: $e');
    throw Exception('Failed to fetch property address.');
  }
}

class _ImageZoomPageState extends State<ImageZoomPage> {
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

  final _userIDController = userID;
  String? userEmail;
  String districtId = '';
  String municipalityId = '';
  bool isLocalUser = true;
  bool isLocalMunicipality = false;
  String? selectedMunicipality; // For district users to select a municipality
  List<String> municipalities = []; // List of municipalities
  bool isLoading = true;
  String formattedMonth =
      DateFormat.MMMM().format(now); //format for full Month by name
  String formattedDateMonth =
      DateFormat.MMMMd().format(now); //format for Day Month only
  bool _meterReadingUpdatedFirst = false;
  bool _imageUploadedFirst = false;
  String currentMonth = DateFormat.MMMM().format(DateTime.now()); // Example: February
  String previousMonth = DateFormat.MMMM().format(DateTime.now().subtract(Duration(days: 30)));
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
  DateTime? latestUploadTimestamp; // Variable to store timestamp
  CollectionReference? _propList;
  @override
  void initState() {
    super.initState();
    fetchUserDetails();
    fetchMeterReadings();
    print('ImageZoomPage Init:');
    print('Municipality Email: ${widget.municipalityUserEmail}');
    print('District ID: ${widget.districtId}');
    print('Municipality ID: ${widget.municipalityId}');
  }

  @override
  void dispose() {
    super.dispose();
  }

  DateTime testDate = DateTime(2024, 3, 28);
  bool _hasFetchedTimestamp = false; // Prevent multiple calls
  String? previousMonthReading = "N/A"; // Holds previous month reading
  String? currentMonthReading = "N/A"; // Holds current month reading

  Future<void> fetchUserDetails() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Fetching properties for ${widget.isLocalMunicipality ? "local" : "district"} municipality.');

        // Determine the correct Firestore path
        if (widget.isLocalMunicipality) {
          _propList = FirebaseFirestore.instance
              .collection('localMunicipalities')
              .doc(widget.municipalityId)
              .collection('properties');
          print('Query Path: localMunicipalities/${widget.municipalityId}/properties');
        } else {
          _propList = FirebaseFirestore.instance
              .collection('districts')
              .doc(widget.districtId)
              .collection('municipalities')
              .doc(widget.municipalityId)
              .collection('properties');
          print('Query Path: districts/${widget.districtId}/municipalities/${widget.municipalityId}/properties');
        }

        final snapshot = await _propList!
            .where('address', isEqualTo: widget.addressSnap)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          var document = snapshot.docs.first;
          var data = document.data() as Map<String, dynamic>;

          String retrievedPhoneNumber = data['cellNumber'] ?? "";
          String retrievedMeterNumber = data['water_meter_number'] ?? "";

          if (mounted) {
            setState(() {
              propPhoneNum = retrievedPhoneNumber;
              wMeterNumber = retrievedMeterNumber;
              print('✅ Property phone number retrieved: $propPhoneNum');
            });

            // Call fetchLatestUploadTimestamp only ONCE after getting the phone number
            if (!_hasFetchedTimestamp && propPhoneNum.isNotEmpty) {
              _hasFetchedTimestamp = true;
              fetchLatestUploadTimestamp();
            }
          }
          print('Test Query Result: ${snapshot.docs.first.data()}');
        } else {
          print('⚠️ No matching property found with address: ${widget.addressSnap}');
        }
      } else {
        print("No current user found.");
      }
    } catch (e) {
      print('❌ Error fetching user details: $e');
    }
  }

  // Future<void> updateImgCheckE(bool imgCheck,
  //     [DocumentSnapshot? documentSnapshot]) async {
  //   if (documentSnapshot != null) {
  //     await _propList?.doc(documentSnapshot.id).update({
  //       "imgStateE": imgCheck,
  //     });
  //   }
  // }

  Future<void> updateImgCheckW(bool imgCheck,
      [DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      try {
        await _propList?.doc(documentSnapshot.id).update({
          "imgStateW": imgCheck,
        });
        print(
            'Updated imgStateW to $imgCheck for document: ${documentSnapshot.id}');
      } catch (e) {
        print('Error updating imgStateW: $e');
      }
    }
  }

  // Future<void> ensureDocumentExists(String cellNumber, String districtId, String municipalityId, String propertyAddress) async {
  //   print('ensureDocumentExists called with: cellNumber = $cellNumber, districtId = $districtId, municipalityId = $municipalityId, propertyAddress = $propertyAddress');  // Add this to check if method is called
  //
  //   DocumentReference actionLogRef;
  //
  //   if (widget.isLocalMunicipality) {
  //     actionLogRef = FirebaseFirestore.instance
  //         .collection('localMunicipalities')
  //         .doc(widget.municipalityId)
  //         .collection('actionLogs')
  //         .doc(cellNumber)
  //         .collection(widget.addressSnap)
  //         .doc();
  //   } else {
  //     actionLogRef = FirebaseFirestore.instance
  //         .collection('districts')
  //         .doc(widget.districtId)
  //         .collection('municipalities')
  //         .doc(widget.municipalityId)
  //         .collection('actionLogs')
  //         .doc(cellNumber)
  //         .collection(widget.addressSnap)
  //         .doc();
  //   }
  //
  // }

  // Future<void> logEMeterReadingUpdate(
  //     String cellNumber,
  //     String propertyAddress,
  //     String municipalityUserEmail,
  //     String districtId,
  //     String municipalityId,
  //     Map<String, dynamic> details) async {
  //
  //   print('logEMeterReadingUpdate called');  // Add this to check if the method is invoked
  //
  //   // Sanitize the property address to ensure it's valid for Firestore paths
  //
  //   // Ensure the document exists before logging
  //   try {
  //     await ensureDocumentExists(cellNumber, districtId, municipalityId, propertyAddress);
  //     print('ensureDocumentExists success');
  //   } catch (e) {
  //     print('Error in ensureDocumentExists: $e');
  //   }
  //
  //   // Construct the correct path for logging
  //   DocumentReference actionLogRef = FirebaseFirestore.instance
  //       .collection('districts')
  //       .doc(districtId)
  //       .collection('municipalities')
  //       .doc(municipalityId)
  //       .collection('actionLogs')
  //       .doc(cellNumber)
  //       .collection(propertyAddress)
  //       .doc();  // Auto-generate document ID for the action
  //
  //   try {
  //     await actionLogRef.set({
  //       'actionType': 'Electricity Meter Reading Update',
  //       'uploader': municipalityUserEmail,
  //       'details': details,
  //       'address': propertyAddress,
  //       'timestamp': FieldValue.serverTimestamp(),
  //       'description': '$municipalityUserEmail updated electricity meter readings for property at $propertyAddress',
  //     });
  //     print('Action log entry created successfully');
  //   } catch (e) {
  //     print('Error creating action log entry: $e');
  //   }
  //
  // }

  Future<void> logWMeterReadingUpdate(
      String cellNumber,
      String propertyAddress,
      String municipalityUserEmail,
      String districtId,
      String municipalityId,
      Map<String, dynamic> details) async {
    print(
        'logWMeterReadingUpdate called with: cellNumber = $cellNumber, propertyAddress = $propertyAddress, municipalityUserEmail = $municipalityUserEmail');
    // Ensure the document exists before logging
    //await ensureDocumentExists(cellNumber, districtId, municipalityId, propertyAddress);

    DocumentReference actionLogRef;

    if (widget.isLocalMunicipality) {
      actionLogRef = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(widget.municipalityId)
          .collection('actionLogs')
          .doc(cellNumber)
          .collection(widget.addressSnap)
          .doc();
    } else {
      actionLogRef = FirebaseFirestore.instance
          .collection('districts')
          .doc(widget.districtId)
          .collection('municipalities')
          .doc(widget.municipalityId)
          .collection('actionLogs')
          .doc(cellNumber)
          .collection(widget.addressSnap)
          .doc();
    }
    print(
        'Logging action for water meter reading update. MunicipalityUserEmail: ${widget.municipalityUserEmail}');

    try {
      await actionLogRef.set({
        'actionType': 'Water Meter Reading Update',
        'uploader': municipalityUserEmail.isNotEmpty
            ? municipalityUserEmail
            : 'Unknown',
        'details': details,
        'address': propertyAddress,
        'timestamp': FieldValue.serverTimestamp(),
        'description':
            '$municipalityUserEmail updated water meter readings for property at $propertyAddress',
      });
      print('Action logged successfully in path: ${actionLogRef.path}');
    } catch (e) {
      print('Error logging water meter reading update: $e');
    }
  }


  Future<void> fetchLatestUploadTimestamp() async {
    if (propPhoneNum.isEmpty) return; // Ensure phone number is set

    print("🔍 Fetching latest timestamp in ImageZoomPage...");
    print("➡️ Using Phone Number: $propPhoneNum");
    print("➡️ District ID: ${widget.districtId}");
    print("➡️ Municipality ID: ${widget.municipalityId}");
    print("➡️ Property Address (Formatted): ${widget.addressSnap}");

    Timestamp? fetchedTimestamp = await getLatestUploadTimestamp(
      widget.districtId,
      widget.municipalityId,
      propPhoneNum,
      widget.addressSnap,
    );

    if (fetchedTimestamp != null) {
      DateTime newTimestamp = fetchedTimestamp.toDate();

      // Ensure the timestamp is updated correctly
      if (mounted) {
        setState(() {
          latestUploadTimestamp = newTimestamp;
          print("📅 Latest Upload Timestamp Updated: $latestUploadTimestamp");
        });
      }
    }
  }

  Future<Timestamp?> getLatestUploadTimestamp(
      String? districtId, String municipalityId, String userPhoneNumber, String propertyAddress) async {
    try {
      QuerySnapshot querySnapshot;

      if (districtId != null && districtId.isNotEmpty) {
        // District-based municipality
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
        // Local municipality
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
        return null; // No records found
      }
    } catch (e) {
      print("❌ Error fetching timestamp: $e");
      return null;
    }
  }

  Future<void> fetchMeterReadings() async {
    try {
      int currentYear = DateTime.now().year;
      int previousYear = currentYear - 1;

      String currentMonth = DateFormat.MMMM().format(DateTime.now()); // Example: March
      String prevMonth = DateFormat.MMMM().format(DateTime.now().subtract(Duration(days: 30))); // Example: February

      // If it's January, use December of the previous year
      String prevMonthYear = (currentMonth == "January") ? previousYear.toString() : currentYear.toString();
      String currentMonthYear = currentYear.toString(); // Always use the current year for current readings

      String propertyAddress = widget.addressSnap.trim(); // Get the property address

      // Initialize Firestore references based on municipality type
      CollectionReference consumptionCollection;
      if (widget.isLocalMunicipality) {
        consumptionCollection = FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(widget.municipalityId)
            .collection('consumption');
      } else {
        consumptionCollection = FirebaseFirestore.instance
            .collection('districts')
            .doc(widget.districtId)
            .collection('municipalities')
            .doc(widget.municipalityId)
            .collection('consumption');
      }

      // Fetch **Previous Month's Reading**
      DocumentSnapshot prevReadingDoc = await consumptionCollection
          .doc(prevMonthYear) // Year folder
          .collection(prevMonth) // Month collection
          .doc(propertyAddress) // Property address document
          .get();

      String prevReading = prevReadingDoc.exists
          ? (prevReadingDoc.data() as Map<String, dynamic>)['water_meter_reading'] ?? "N/A"
          : "N/A";

      print("📊 Previous Month ($prevMonthYear/$prevMonth) Reading: $prevReading");

      // Fetch **Current Month's Reading**
      DocumentSnapshot currentReadingDoc = await consumptionCollection
          .doc(currentMonthYear) // Year folder
          .collection(currentMonth) // Month collection
          .doc(propertyAddress) // Property address document
          .get();

      String currentReading = currentReadingDoc.exists
          ? (currentReadingDoc.data() as Map<String, dynamic>)['water_meter_reading'] ?? "N/A"
          : "N/A";

      print("📊 Current Month ($currentMonthYear/$currentMonth) Reading: $currentReading");

      // ✅ Update UI with fetched readings
      if (mounted) {
        setState(() {
          previousMonthReading = prevReading;
          currentMonthReading = currentReading;
        });
      }
    } catch (e) {
      print("❌ Error fetching meter readings: $e");
    }
  }

  Future<void> _fetchLatestWaterMeterReadingMunicipal() async {
    await fetchMeterReadings(); // Call the existing method to get readings

    if (mounted) {
      setState(() {
        // No need to manually update variables, `fetchMeterReadings()` already updates state
      });
    }
    print("📊 Updated Municipal Readings - Previous: $previousMonthReading | Current: $currentMonthReading");
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
  //                     //   await FirebaseFirestore.instance
  //                     //       .collection('consumption').doc(formattedMonth)
  //                     //       .collection('address').doc(address).set({
  //                     //     "address": address,
  //                     //     "meter reading": meterReading,
  //                     //     "water meter reading": waterMeterReading,
  //                     //   });
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
  //
  //                       // Log the update action using the municipalityUserEmail from the ImageZoomPage
  //                       await logEMeterReadingUpdate(
  //                           documentSnapshot?['cellNumber'],address,
  //                           widget.municipalityUserEmail ?? "Unknown",
  //                           districtId,
  //                           municipalityId,
  //                           updateDetails);
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
  //                           .collection('consumption')
  //                           .doc(formattedMonth)
  //                           .collection('address')
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
  //                       if (context.mounted) Navigator.of(context).pop();
  //
  //                       ///Added open the image upload straight after inputting the meter reading
  //                       // if(context.mounted) {
  //                       //   showDialog(
  //                       //       barrierDismissible: false,
  //                       //       context: context,
  //                       //       builder: (context) {
  //                       //         return AlertDialog(
  //                       //           title: const Text("Upload Electricity Meter"),
  //                       //           content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
  //                       //           actions: [
  //                       //             IconButton(
  //                       //               onPressed: () {
  //                       //                 Navigator.pop(context);
  //                       //               },
  //                       //               icon: const Icon(
  //                       //                 Icons.cancel,
  //                       //                 color: Colors.red,
  //                       //               ),
  //                       //             ),
  //                       //             IconButton(
  //                       //               onPressed: () async {
  //                       //                 Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
  //                       //                 Navigator.push(context,
  //                       //                     MaterialPageRoute(builder: (context) => ImageUploadMeter(userNumber: cellNumber, meterNumber: meterNumber,)));
  //                       //               },
  //                       //               icon: const Icon(
  //                       //                 Icons.done,
  //                       //                 color: Colors.green,
  //                       //               ),
  //                       //             ),
  //                       //           ],
  //                       //         );
  //                       //       });
  //                       // }
  //
  //                       Fluttertoast.showToast(msg: "Reading updated!");
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
                    decoration:
                        const InputDecoration(labelText: 'Water Meter Number'),
                  ),
                ),
                Visibility(
                  visible: visibilityState1,
                  child: TextField(
                    maxLength: 8,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    keyboardType: TextInputType.number,
                    controller: _waterMeterReadingController,
                    decoration:
                        const InputDecoration(labelText: 'Water Meter Reading'),
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
                    decoration: const InputDecoration(labelText: 'First Name'),
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
                      //
                      //   await FirebaseFirestore.instance
                      //       .collection('consumption').doc(formattedMonth)
                      //       .collection('address').doc(address).set({
                      //     "address": address,
                      //     "meter reading": meterReading,
                      //     "water meter reading": waterMeterReading,
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
                        await logWMeterReadingUpdate(
                            documentSnapshot?['cellNumber'],
                            address,
                            widget.municipalityUserEmail ?? "Unknown",
                            districtId,
                            municipalityId,
                            updateDetails);

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

                        //Added open the image upload straight after inputting the meter reading
                      }
                    })
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _delete(String users) async {
    await _propList?.doc(users).delete();
    Fluttertoast.showToast(msg: "You have successfully deleted an account!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text(
          'Readings Management',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _propList?.snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
            if (streamSnapshot.connectionState == ConnectionState.waiting) {
              print('Waiting for data...');
              return const Center(child: CircularProgressIndicator());
            }

            if (streamSnapshot.hasError) {
              print('Error fetching data: ${streamSnapshot.error}');
              return const Center(child: Text('Error fetching data.'));
            }

            if (!streamSnapshot.hasData || streamSnapshot.data!.docs.isEmpty) {
              print('No data found for the selected property.');
              return const Center(child: Text('No data found.'));
            }

            // If we reach this point, data is available
            print('Data fetched successfully, rendering UI.');
            {
              return ListView.builder(
                ///this call is to display all details for all users but is only displaying for the current user account.
                ///it can be changed to display all users for the staff to see if the role is set to all later on.
                itemCount: streamSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final DocumentSnapshot documentSnapshot =
                      streamSnapshot.data!.docs[index];

                  // eMeterNumber = documentSnapshot['meter_number'];
                  if (documentSnapshot['address'] == widget.addressSnap) {
                    // Assign the water meter number only if the correct property is found
                    wMeterNumber = documentSnapshot['water_meter_number'];
                    propPhoneNum = documentSnapshot['cellNumber'];

                    print('Correct water meter number: $wMeterNumber');
                    print('Property phone number: $propPhoneNum');
                    // Future.microtask(() {
                    //   fetchLatestUploadTimestamp();
                    // });
                  }

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

                  ///Check for only user information, this displays only for the users details and not all users in the database.
                  if (streamSnapshot.data!.docs[index]['address'] ==
                      widget.addressSnap) {
                    return Card(
                      margin: const EdgeInsets.only(
                          left: 10, right: 10, top: 0, bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                'Property Information for ${documentSnapshot['address']}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Text(
                              'Account Number: ${documentSnapshot['accountNumber']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            // const SizedBox(height: 5,),
                            // Text(
                            //   'Street Address: ${documentSnapshot['address']}',
                            //   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            // ),
                            // const SizedBox(height: 5,),
                            // Text(
                            //   'Area Code: ${documentSnapshot['area code']}',
                            //   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            // ),
                            const SizedBox(
                              height: 10,
                            ),
                            // const Center(
                            //   child: Text(
                            //     'Electricity Meter Reading Photo',
                            //     style: TextStyle(
                            //         fontSize: 16, fontWeight: FontWeight.w700),
                            //   ),
                            // ),
                            const SizedBox(
                              height: 5,
                            ),
                            // FutureBuilder<String>(
                            //     future: fetchPropertyAddress(
                            //         propPhoneNum, eMeterNumber,districtId,municipalityId)
                            //         .then((propertyAddress) => _getImage(
                            //         context,
                            //         'files/meters/$formattedMonth/$propPhoneNum/$propertyAddress/electricity/$eMeterNumber.jpg')),
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
                            //             margin:
                            //                 const EdgeInsets.only(bottom: 5),
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
                            //           child: Center(
                            //             child: Column(
                            //               mainAxisSize: MainAxisSize.min,
                            //               children: [
                            //                 Text('Image not yet uploaded.'),
                            //                 SizedBox(height: 10),
                            //                 FaIcon(Icons.camera_alt),
                            //               ],
                            //             ),
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
                            //     barrierDismissible: false,
                            //     context: context,
                            //     builder: (context) {
                            //       return AlertDialog(
                            //         title: const Text("Upload Electricity Meter"),
                            //         content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
                            //         actions: [
                            //           IconButton(
                            //             onPressed: () {
                            //               Navigator.pop(context);
                            //             },
                            //             icon: const Icon(
                            //               Icons.cancel,
                            //               color: Colors.red,
                            //             ),
                            //           ),
                            //           IconButton(
                            //             onPressed: () async {
                            //               Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
                            //               Navigator.push(context,
                            //                   MaterialPageRoute(builder: (context) => ImageUploadMeter(userNumber: propPhoneNum, meterNumber: eMeterNumber,)));
                            //             },
                            //             icon: const Icon(
                            //               Icons.done,
                            //               color: Colors.green,
                            //             ),
                            //           ),
                            //         ],
                            //       );
                            //     });
                            //   },
                            //   child: Container(
                            //     margin: const EdgeInsets.only(bottom: 5),
                            //     // height: 180,
                            //     child: Center(
                            //       child: Card(
                            //         color: Colors.grey,
                            //         semanticContainer: true,
                            //         clipBehavior: Clip.antiAliasWithSaveLayer,
                            //         shape: RoundedRectangleBorder(
                            //           borderRadius: BorderRadius.circular(10.0),
                            //         ),
                            //         elevation: 0,
                            //         margin: const EdgeInsets.all(10.0),
                            //         child: FutureBuilder(
                            //             future: _getImage(
                            //               ///Firebase image location must be changed to display image based on the meter number
                            //                 context, widget.imageName),
                            //             builder: (context, snapshot) {
                            //               if (snapshot.hasError) {
                            //
                            //                 // imgUploadCheck = false;
                            //                 // updateImgCheckE(imgUploadCheck,documentSnapshot);
                            //
                            //                 return const Padding(
                            //                   padding: EdgeInsets.all(20.0),
                            //                     child: Column(
                            //                       mainAxisSize: MainAxisSize.min,
                            //                       children: [
                            //                         Text('Image not yet uploaded.',),
                            //                         SizedBox(height: 10,),
                            //                         FaIcon(Icons.camera_alt,),
                            //                       ],
                            //                     ),
                            //                 );
                            //               }
                            //               if (snapshot.connectionState == ConnectionState.done) {
                            //
                            //                 imgUploadCheck = true;
                            //                 updateImgCheckE(imgUploadCheck,documentSnapshot);
                            //
                            //                 return Container(
                            //                   child: snapshot.data,
                            //                 );
                            //               }
                            //               if (snapshot.connectionState == ConnectionState.waiting) {
                            //                 return Container(
                            //                   child: const Padding(
                            //                     padding: EdgeInsets.all(5.0),
                            //                     child: CircularProgressIndicator(),
                            //                   ),);
                            //               }
                            //               return Container();
                            //             }
                            //         ),
                            //       ),
                            //     ),
                            //   ),
                            // ),

                            // Center(
                            //   child: BasicIconButtonGrey(
                            //     onPress: () async {
                            //       eMeterNumber =
                            //           documentSnapshot['meter_number'];
                            //       propPhoneNum =
                            //           documentSnapshot['cellNumber'];
                            //       showDialog(
                            //           barrierDismissible: false,
                            //           context: context,
                            //           builder: (context) {
                            //             return AlertDialog(
                            //               title: const Text(
                            //                   "Upload Electricity Meter"),
                            //               content: const Text(
                            //                   "Uploading a new image will replace current image!\n\nAre you sure?"),
                            //               actions: [
                            //                 IconButton(
                            //                   onPressed: () {
                            //                     Navigator.pop(context);
                            //                   },
                            //                   icon: const Icon(
                            //                     Icons.cancel,
                            //                     color: Colors.red,
                            //                   ),
                            //                 ),
                            //                 IconButton(
                            //                   onPressed: () async {
                            //                     Fluttertoast.showToast(
                            //                         msg:
                            //                             "Uploading a new image\nwill replace current image!");
                            //                     Navigator.push(
                            //                         context,
                            //                         MaterialPageRoute(
                            //                             builder: (context) =>
                            //                                 ImageUploadMeter(
                            //                                   userNumber:
                            //                                       propPhoneNum,
                            //                                   meterNumber:
                            //                                       eMeterNumber,
                            //                                 municipalityUserEmail: userEmail,
                            //                                 )));
                            //                   },
                            //                   icon: const Icon(
                            //                     Icons.done,
                            //                     color: Colors.green,
                            //                   ),
                            //                 ),
                            //               ],
                            //             );
                            //           });
                            //     },
                            //     labelText: 'Photograph Electricity',
                            //     fSize: 16,
                            //     faIcon: const FaIcon(
                            //       Icons.camera_alt,
                            //     ),
                            //     fgColor: Colors.black38,
                            //     btSize: const Size(100, 38),
                            //   ),
                            // ),
                            //
                            // const SizedBox(
                            //   height: 5,
                            // ),
                            // Text(
                            //   'Electric Meter Number: ${documentSnapshot['meter_number']}',
                            //   style: const TextStyle(
                            //       fontSize: 16, fontWeight: FontWeight.w400),
                            // ),
                            // const SizedBox(
                            //   height: 5,
                            // ),
                            // Text(
                            //   'Electric Meter Reading: ${documentSnapshot['meter_reading']}',
                            //   style: const TextStyle(
                            //       fontSize: 16, fontWeight: FontWeight.w400),
                            // ),
                            // Center(
                            //   child: BasicIconButtonGrey(
                            //     onPress: () async {
                            //       _updateE(documentSnapshot);
                            //     },
                            //     labelText: 'Capture Electricity Reading',
                            //     fSize: 16,
                            //     faIcon: const FaIcon(
                            //       Icons.edit,
                            //     ),
                            //     fgColor: Theme.of(context).primaryColor,
                            //     btSize: const Size(100, 38),
                            //   ),
                            // ),
                            //
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
                            FutureBuilder<String>(
                              future: fetchPropertyAddress(
                                propPhoneNum,
                                wMeterNumber,
                                widget
                                    .isLocalMunicipality, // The boolean indicating if it's a local municipality
                                widget.districtId,
                                widget.municipalityId,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Container(
                                    height: 180,
                                    margin: const EdgeInsets.all(10.0),
                                    child: const Center(
                                        child: CircularProgressIndicator()),
                                  );
                                } else if (snapshot.hasData) {
                                  final String propertyAddress = snapshot.data!;
                                  print('Property Address: $propertyAddress');

                                  final String imagePath =
                                      'files/meters/$formattedMonth/$propPhoneNum/$propertyAddress/water/$wMeterNumber.jpg';

                                  return FutureBuilder<String>(
                                    future: _getImageW(context, imagePath),
                                    builder: (context, imageSnapshot) {
                                      if (imageSnapshot.hasData &&
                                          imageSnapshot.connectionState ==
                                              ConnectionState.done) {
                                        return GestureDetector(
                                          onTap: () {
                                            final imageProvider = NetworkImage(
                                                imageSnapshot.data!);
                                            showImageViewer(
                                                context, imageProvider);
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 5),
                                            height: 180,
                                            child: Card(
                                              color: Colors.white54,
                                              semanticContainer: true,
                                              clipBehavior:
                                                  Clip.antiAliasWithSaveLayer,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              elevation: 0,
                                              margin:
                                                  const EdgeInsets.all(10.0),
                                              child: Center(
                                                child: Image.network(
                                                    imageSnapshot.data!,
                                                    fit: BoxFit.cover),
                                              ),
                                            ),
                                          ),
                                        );
                                      } else if (imageSnapshot.hasError) {
                                        return const Padding(
                                          padding: EdgeInsets.all(20.0),
                                          child: Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                    'No image uploaded for this meter yet.'),
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
                                              child:
                                                  CircularProgressIndicator()),
                                        );
                                      }
                                    },
                                  );
                                } else if (snapshot.hasError) {
                                  return const Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: Center(
                                      child: Text(
                                          'Error fetching property details.'),
                                    ),
                                  );
                                }

                                return const Center(
                                    child: CircularProgressIndicator());
                              },
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: Text(
                                latestUploadTimestamp != null
                                    ? "📅 Image uploaded on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(latestUploadTimestamp!)}"
                                    : "⚠️ No upload history available.",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // InkWell(
                            //   ///onTap allows to open image upload page if user taps on the image.
                            //   ///Can be later changed to display the picture zoomed in if user taps on it.
                            //   onTap: () {
                            //     wMeterNumber = documentSnapshot['water meter number'];
                            //     propPhoneNum = documentSnapshot['cell number'];
                            //     showDialog(
                            //     barrierDismissible: false,
                            //     context: context,
                            //     builder: (context) {
                            //       return AlertDialog(
                            //         title: const Text("Upload Water Meter Image"),
                            //         content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
                            //         actions: [
                            //           IconButton(
                            //             onPressed: () {
                            //               Navigator.pop(context);
                            //             },
                            //             icon: const Icon(
                            //               Icons.cancel,
                            //               color: Colors.red,
                            //             ),
                            //           ),
                            //           IconButton(
                            //             onPressed: () async {
                            //               propPhoneNum = documentSnapshot['water meter number'];
                            //               Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
                            //               Navigator.push(context,
                            //                   MaterialPageRoute(builder: (context) => ImageUploadWater(userNumber: propPhoneNum, meterNumber: wMeterNumber, propertyAddress: addressSnap,districtId: districtId,municipalityId: municipalityId,)));
                            //             },
                            //             icon: const Icon(
                            //               Icons.done,
                            //               color: Colors.green,
                            //             ),
                            //           ),
                            //         ],
                            //       );
                            //     });
                            //   },
                            //   child: Container(
                            //     margin: const EdgeInsets.only(bottom: 5),
                            //     // height: 180,
                            //     child: Center(
                            //       child: Card(
                            //         color: Colors.grey,
                            //         semanticContainer: true,
                            //         clipBehavior: Clip.antiAliasWithSaveLayer,
                            //         shape: RoundedRectangleBorder(
                            //           borderRadius: BorderRadius.circular(10.0),
                            //         ),
                            //         elevation: 0,
                            //         margin: const EdgeInsets.all(10.0),
                            //         child: FutureBuilder<String?>(
                            //             future: _getImageW(
                            //               ///Firebase image location must be changed to display image based on the meter number
                            //                 context, 'files/meters/$formattedMonth/$propPhoneNum/$addressSnap/water/$wMeterNumber.jpg'),//$meterNumber
                            //             builder: (context, snapshot) {
                            //               if (snapshot.hasError) {
                            //
                            //                 imgUploadCheck = false;
                            //                 updateImgCheckW(imgUploadCheck,documentSnapshot);
                            //
                            //                 return const Padding(
                            //                   padding: EdgeInsets.all(20.0),
                            //                   child: Column(
                            //                     mainAxisSize: MainAxisSize.min,
                            //                     children: [
                            //                       Text('Image not yet uploaded.',),
                            //                       SizedBox(height: 10,),
                            //                       FaIcon(Icons.camera_alt,),
                            //                     ],
                            //                   ),
                            //                 );
                            //               }
                            //               if (snapshot.connectionState == ConnectionState.done) {
                            //                 imgUploadCheck = true;
                            //                 updateImgCheckW(imgUploadCheck, documentSnapshot);
                            //
                            //                 if (snapshot.data != null) {
                            //                   return Image.network(
                            //                     snapshot.data!, // Assuming _getImageW returns a URL
                            //                     fit: BoxFit.cover,
                            //                   );
                            //                 } else {
                            //                   return const Text('No image available.');
                            //                 }
                            //               }
                            //               if (snapshot.connectionState == ConnectionState.waiting) {
                            //                 return const Padding(
                            //                   padding: EdgeInsets.all(5.0),
                            //                   child: CircularProgressIndicator(),
                            //                 );
                            //               }
                            //               return Container();
                            //             }
                            //         ),
                            //       ),
                            //     ),
                            //   ),
                            // ),

                            Center(
                              child: ElevatedButton.icon(
                                onPressed: DateTime.now().day >= 28
                                    ? null // Fully disables button functionality
                                    : () async {
                                  wMeterNumber =
                                      documentSnapshot['water_meter_number'];
                                  propPhoneNum = documentSnapshot['cellNumber'];
                                  String propertyAddress =
                                      documentSnapshot['address'];

                                  showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title:
                                              const Text("Upload Water Meter"),
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
                                                Fluttertoast.showToast(
                                                    msg:
                                                        "Uploading a new image\nwill replace current image!");

                                                print(
                                                    "Navigating to ImageUploadWater:");
                                                print(
                                                    "User Email: ${widget.municipalityUserEmail}");
                                                print(
                                                    "District ID: ${widget.districtId}");
                                                print(
                                                    "Municipality ID: ${widget.municipalityId}");
                                                Navigator.pop(context);
                                                bool? uploadCompleted = await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ImageUploadWater(
                                                      userNumber: propPhoneNum,
                                                      meterNumber: wMeterNumber,
                                                      municipalityUserEmail: widget
                                                          .municipalityUserEmail,
                                                      propertyAddress:
                                                          propertyAddress, // Pass property address
                                                      districtId: widget
                                                          .districtId, // Pass districtId
                                                      municipalityId:
                                                          widget.municipalityId,
                                                      isLocalMunicipality: widget
                                                          .isLocalMunicipality,
                                                      isLocalUser:
                                                          widget.isLocalUser,
                                                    ),
                                                  ),);
                                                if (uploadCompleted == true) {
                                                  print("✅ Upload completed successfully! Refreshing timestamp...");

                                                  /// **Ensure UI Refresh**
                                                  await fetchLatestUploadTimestamp();
                                                  await _fetchLatestWaterMeterReadingMunicipal();
                                                  if (mounted) {
                                                    setState(() {}); // Force rebuild
                                                  }
                                                } else {
                                                  print("⚠️ Upload was not completed.");
                                                }
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
                                icon: FaIcon(
                                  Icons.camera_alt,
                                  color: DateTime.now().day >= 28 ? Colors.grey.shade500 : Colors.black, // Icon fades when disabled
                                ),
                                label: Text(
                                  DateTime.now().day >= 28
                                      ? 'Meter uploads can only be\ndone before the 28th'
                                      : 'Update water meter\nimage and reading',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.tenorSans(
                                    color: DateTime.now().day >= 28 ? Colors.white : Colors.black, // White text when disabled
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(200, 50), // Match other buttons
                                  backgroundColor: DateTime.now().day >= 28
                                      ? Colors.grey.shade600 // Dark grey when disabled
                                      : Colors.white70, // Normal white background when enabled
                                  foregroundColor: DateTime.now().day >= 28
                                      ? Colors.white // White text/icon when disabled
                                      : Colors.black, // Black text/icon when enabled
                                  disabledForegroundColor: Colors.white, // Ensure text stays white when disabled
                                  disabledBackgroundColor: Colors.grey.shade600, // Ensure background stays dark grey when disabled
                                  side: BorderSide(
                                    width: 1,
                                    color: DateTime.now().day >= 28 ? Colors.grey.shade700 : Colors.black38, // Darker border when disabled
                                  ),
                                  shadowColor: DateTime.now().day >= 28 ? Colors.transparent : Colors.black, // Remove shadow when disabled
                                  elevation: DateTime.now().day >= 28 ? 0 : 3, // No elevation for disabled button
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              'Water Meter Number: ${documentSnapshot['water_meter_number']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              'Previous Month ($previousMonth) Reading: ${previousMonthReading ?? "N/A"}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Current Month ($currentMonth) Reading: ${currentMonthReading ?? "N/A"}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),


                            // Center(
                            //   child: BasicIconButtonGrey(
                            //     onPress: () async {
                            //       _updateW(documentSnapshot);
                            //     },
                            //     labelText: 'Capture Water Reading',
                            //     fSize: 16,
                            //     faIcon: const FaIcon(
                            //       Icons.edit,
                            //     ),
                            //     fgColor: Colors.black,
                            //     btSize: const Size(100, 38),
                            //   ),
                            // ),

                            Center(
                              child: Column(
                                children: [
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing:
                                        8, // Adjust the spacing between the buttons as needed
                                    runSpacing: 4, // Spacing between rows
                                    children: [
                                      BasicIconButtonGrey(
                                        onPress: () async {
                                          String accountNumber =
                                              documentSnapshot['accountNumber'];
                                          String locationGiven =
                                              documentSnapshot['address'];
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      MapScreenProp(
                                                        propAddress:
                                                            locationGiven,
                                                        propAccNumber:
                                                            accountNumber,
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
                                      BasicIconButtonGrey(
                                        onPress: () async {
                                          String userId =
                                              documentSnapshot['cellNumber'];
                                          String districtId = documentSnapshot[
                                              'districtId']; // Get the districtId
                                          String municipalityId =
                                              documentSnapshot[
                                                  'municipalityId'];
                                          String propertyAddress = documentSnapshot[
                                              'address']; // Fetch the property address

                                          // Format the property address for Firestore path

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => LogScreen(
                                                userId: userId,
                                                districtId: districtId,
                                                municipalityId: municipalityId,
                                                propertyAddress:
                                                    propertyAddress,
                                                isLocalMunicipality:
                                                    widget.isLocalMunicipality,
                                              ),
                                            ),
                                          );
                                        },
                                        labelText: 'Update Logs',
                                        fSize: 16,
                                        faIcon: const FaIcon(Icons.update),
                                        fgColor: Colors.blue,
                                        btSize: const Size(100, 38),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  }

                  ///end of single user information display.
                  else {
                    return const SizedBox(
                      height: 0,
                      width: 0,
                    );
                  }
                },
              );
            }
            return const Padding(
              padding: EdgeInsets.all(10.0),
              child: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),

      //   floatingActionButton: FloatingActionButton(
      //     onPressed: () {},
      //     child: const Icon(Icons.add),
      //   ),
      //   floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat
    );
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
