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
import 'package:municipal_services/code/DisplayPages/display_all_meters.dart';
import 'package:municipal_services/code/DisplayPages/display_info_all_users.dart';

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
    required this.imageElectricName,
  });

  final String imageName;
  final String imageElectricName;
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
String eMeterNumber = ' ';
String accountNumberW = ' ';
String locationGivenW = ' ';
String wMeterNumber = ' ';
String propPhoneNum = ' ';

bool visibilityState1 = true;
bool visibilityState2 = false;
bool imgUploadCheck = false;
bool handlesWater = false;
bool handlesElectricity = false;
String? previousElectricityReading;
String? currentElectricityReading;
String? previousWaterReading;
String? currentWaterReading;
final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;
DateTime? latestWaterUploadTimestamp;
DateTime? latestElectricityUploadTimestamp;
Timestamp? _electricityUploadTimestamp;
bool _hasFetchedElectricityTimestamp = false;
String? _electricityImageUrl;
Map<String, String> imageCacheMap = {}; // Stores property image URLs
Set<String> fetchedTimestamps = {};

class FireStorageService extends ChangeNotifier {
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async {
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

// Future<String> _getImageW(BuildContext context, String imagePath) async {
//   try {
//     final ref = FirebaseStorage.instance.ref().child(imagePath);
//     final imageUrl = await ref.getDownloadURL();
//     print('Image URL: $imageUrl');
//     return imageUrl;
//   } catch (e) {
//     print('Error fetching image: $e');
//     throw Exception('Error fetching image: $e');
//   }
// }
//
// Future<String> _getImageE(BuildContext context, String imagePath) async {
//   try {
//     final ref = FirebaseStorage.instance.ref().child(imagePath);
//     final imageUrl = await ref.getDownloadURL();
//     print('Image URL: $imageUrl');
//     return imageUrl;
//   } catch (e) {
//     print('Error fetching image: $e');
//     throw Exception('Error fetching image: $e');
//   }
// }
Future<String> _getImageW(
    BuildContext context, String? imagePath, String propertyAddress) async {
  if (imagePath == null) throw Exception('Image path cannot be null');

  final cacheKey = "${propertyAddress}_water";

  if (imageCacheMap.containsKey(cacheKey)) {
    print("🔄 Using cached water image for $propertyAddress");
    return imageCacheMap[cacheKey]!;
  }

  try {
    final imageUrl =
        await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    imageCacheMap[cacheKey] = imageUrl;
    return imageUrl;
  } catch (e) {
    print('Failed to load water image for $propertyAddress: $e');
    throw Exception('Failed to load image');
  }
}

Future<String> _getImageE(
    BuildContext context, String? imagePath, String propertyAddress) async {
  if (imagePath == null) throw Exception('Image path cannot be null');

  final cacheKey = "${propertyAddress}_electricity";

  if (imageCacheMap.containsKey(cacheKey)) {
    print("🔄 Using cached electricity image for $propertyAddress");
    return imageCacheMap[cacheKey]!;
  }

  try {
    final imageUrl =
        await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    imageCacheMap[cacheKey] = imageUrl;
    return imageUrl;
  } catch (e) {
    print('Failed to load electricity image for $propertyAddress: $e');
    throw Exception('Failed to load image');
  }
}

// Future<String> fetchPropertyAddress(String phoneNumber, String meterNumber,
//     bool isLocalMunicipality, String districtId, String municipalityId) async {
//   try {
//     QuerySnapshot querySnapshot;
//
//     if (isLocalMunicipality) {
//       // Query for local municipalities
//       querySnapshot = await FirebaseFirestore.instance
//           .collection('localMunicipalities')
//           .doc(municipalityId)
//           .collection('properties')
//           .where('cellNumber', isEqualTo: phoneNumber)
//           .where('water_meter_number',
//               isEqualTo: meterNumber) // Filter by meter number
//           .limit(1)
//           .get();
//     } else {
//       // Query for district municipalities
//       querySnapshot = await FirebaseFirestore.instance
//           .collection('districts')
//           .doc(districtId)
//           .collection('municipalities')
//           .doc(municipalityId)
//           .collection('properties')
//           .where('cellNumber', isEqualTo: phoneNumber)
//           .where('water_meter_number',
//               isEqualTo: meterNumber) // Filter by meter number
//           .limit(1)
//           .get();
//     }
//
//     if (querySnapshot.docs.isNotEmpty) {
//       // Correctly return the address of the matched property
//       return querySnapshot.docs.first['address'];
//     } else {
//       throw Exception('No property found for this meter number.');
//     }
//   } catch (e) {
//     print('Error fetching property address: $e');
//     throw Exception('Failed to fetch property address.');
//   }
// }

class _ImageZoomPageState extends State<ImageZoomPage> {
  // text fields' controllers
  final _accountNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaCodeController = TextEditingController();
  final _meterNumberController = TextEditingController();
  final _meterReadingController = TextEditingController();
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
  String currentMonth =
      DateFormat.MMMM().format(DateTime.now()); // Example: February
  String previousMonth = DateFormat.MMMM()
      .format(DateTime.now().subtract(const Duration(days: 30)));
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
  String? waterImageUrl;
  String? electricityImageUrl;

  @override
  void initState() {
    super.initState();

    print('ImageZoomPage Init:');
    print('Municipality Email: ${widget.municipalityUserEmail}');
    print('District ID: ${widget.districtId}');
    print('Municipality ID: ${widget.municipalityId}');

    fetchUserDetails().then((_) {
      fetchMunicipalityUtilityTypes().then((_) {
        if (!mounted) return;
        if (handlesWater) {
          _fetchLatestWaterMeterReading();
          fetchWaterImageAndTimestamp(); // new method we defined
        }

        if (handlesElectricity) {
          _fetchLatestElectricityMeterReading();
          fetchElectricityImageAndTimestamp(); // new method we defined
        }
      });
    });
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
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print(
          'Fetching properties for ${widget.isLocalMunicipality ? "local" : "district"} municipality.');

      // Determine the correct Firestore path
      if (widget.isLocalMunicipality) {
        _propList = FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(widget.municipalityId)
            .collection('properties');
        print(
            'Query Path: localMunicipalities/${widget.municipalityId}/properties');
      } else {
        _propList = FirebaseFirestore.instance
            .collection('districts')
            .doc(widget.districtId)
            .collection('municipalities')
            .doc(widget.municipalityId)
            .collection('properties');
        print(
            'Query Path: districts/${widget.districtId}/municipalities/${widget.municipalityId}/properties');
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
        String retrievedEmeterNumber=data['meter_number']??"";

        if (mounted) {
          setState(() {
            propPhoneNum = retrievedPhoneNumber;
            wMeterNumber = retrievedMeterNumber;
            eMeterNumber=retrievedEmeterNumber;
            print('✅ Property phone number retrieved: $propPhoneNum');
          });
        } else {
          print("No current user found.");
        }
      }
    }
  }

  Future<void> fetchMunicipalityUtilityTypes() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc;

      print("🔍 Checking utility types for:");
      print("📍 isLocalMunicipality: ${widget.isLocalMunicipality}");
      print("🏛️ municipalityId: ${widget.municipalityId}");
      print("🏙️ districtId: ${widget.districtId}");

      if (widget.isLocalMunicipality) {
        doc = await FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(widget.municipalityId)
            .get();
      } else {
        doc = await FirebaseFirestore.instance
            .collection('districts')
            .doc(widget.districtId)
            .collection('municipalities')
            .doc(widget.municipalityId)
            .get();
      }

      if (doc.exists) {
        final data = doc.data();
        if (data != null && mounted) {
          final List<dynamic> utilityTypeList = data['utilityType'] ?? [];

          handlesWater = utilityTypeList.contains('water');
          handlesElectricity = utilityTypeList.contains('electricity');

          setState(() {}); // Update UI after state is changed

          print("📦 Document data: $data");
          print("💧 handlesWater = $handlesWater");
          print("⚡ handlesElectricity = $handlesElectricity");
        } else {
          print("⚠️ Municipality document exists but has no data.");
        }
      } else {
        print("⚠️ Municipality document not found.");
      }
    } catch (e) {
      print("❌ Error fetching utility type: $e");
    }
  }

  // Future<void> fetchReadingsAndImages() async {
  //   if (handlesWater) {
  //     await _fetchLatestUploadTimestamp("water");
  //     final waterReadings = await fetchMeterReadings();
  //     final resolvedAddress = await fetchPropertyAddress(
  //       propPhoneNum,
  //       wMeterNumber,
  //       widget.isLocalMunicipality,
  //       widget.districtId,
  //       widget.municipalityId,
  //     );
  //     final waterPath = 'files/meters/$formattedMonth/$propPhoneNum/$resolvedAddress/water/$wMeterNumber.jpg';
  //     final waterUrl = await _getImageW(context, waterPath);
  //
  //     if (mounted) {
  //       setState(() {
  //         previousWaterReading = waterReadings["previous"];
  //         currentWaterReading = waterReadings["current"];
  //         waterImageUrl = waterUrl;
  //       });
  //     }
  //   }
  //
  //   if (handlesElectricity) {
  //     await _fetchLatestUploadTimestamp("electricity");
  //     final elecReadings = await fetchElectricityReadings();
  //     final elecPath = 'files/meters/$formattedMonth/$propPhoneNum/${widget.addressSnap}/electricity/$eMeterNumber.jpg';
  //     final elecUrl = await _getImageE(context, elecPath);
  //
  //     if (mounted) {
  //       setState(() {
  //         previousElectricityReading = elecReadings["previous"];
  //         currentElectricityReading = elecReadings["current"];
  //         electricityImageUrl = elecUrl;
  //       });
  //     }
  //   }
  // }

  Future<void> updateImgCheckE(bool imgCheck,
      [DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      await _propList?.doc(documentSnapshot.id).update({
        "imgStateE": imgCheck,
      });
    }
  }

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

  Future<void> ensureDocumentExists(String cellNumber, String districtId,
      String municipalityId, String propertyAddress) async {
    print(
        'ensureDocumentExists called with: cellNumber = $cellNumber, districtId = $districtId, municipalityId = $municipalityId, propertyAddress = $propertyAddress'); // Add this to check if method is called

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
  }

  Future<void> logEMeterReadingUpdate(
      String cellNumber,
      String propertyAddress,
      String municipalityUserEmail,
      String districtId,
      String municipalityId,
      Map<String, dynamic> details) async {
    print(
        'logEMeterReadingUpdate called'); // Add this to check if the method is invoked

    // Sanitize the property address to ensure it's valid for Firestore paths

    // Ensure the document exists before logging
    try {
      await ensureDocumentExists(
          cellNumber, districtId, municipalityId, propertyAddress);
      print('ensureDocumentExists success');
    } catch (e) {
      print('Error in ensureDocumentExists: $e');
    }

    // Construct the correct path for logging
    DocumentReference actionLogRef = FirebaseFirestore.instance
        .collection('districts')
        .doc(districtId)
        .collection('municipalities')
        .doc(municipalityId)
        .collection('actionLogs')
        .doc(cellNumber)
        .collection(propertyAddress)
        .doc(); // Auto-generate document ID for the action

    try {
      await actionLogRef.set({
        'actionType': 'Electricity Meter Reading Update',
        'uploader': municipalityUserEmail,
        'details': details,
        'address': propertyAddress,
        'timestamp': FieldValue.serverTimestamp(),
        'description':
            '$municipalityUserEmail updated electricity meter readings for property at $propertyAddress',
      });
      print('Action log entry created successfully');
    } catch (e) {
      print('Error creating action log entry: $e');
    }
  }

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

  Future<Timestamp?> getLatestWaterUploadTimestamp(
    String? districtId,
    String municipalityId,
    String userPhoneNumber,
    String propertyAddress,
  ) async {
    try {
      final baseRef = (districtId != null && districtId.isNotEmpty)
          ? FirebaseFirestore.instance
              .collection('districts')
              .doc(districtId)
              .collection('municipalities')
          : FirebaseFirestore.instance.collection('localMunicipalities');

      final querySnapshot = await baseRef
          .doc(municipalityId)
          .collection('actionLogs')
          .doc(userPhoneNumber)
          .collection(propertyAddress)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();
      print("🔍 Water log docs:");
      for (var doc in querySnapshot.docs) {
        print("- actionType: ${doc['actionType']}");
        print("- timestamp: ${doc['timestamp']}");
      }

      for (var doc in querySnapshot.docs) {
        if (doc['actionType'] == "Upload Water Meter Image") {
          return doc['timestamp'];
        }
      }

      print("⚠️ No water meter image timestamp found for $propertyAddress");
      return null;
    } catch (e) {
      print("❌ Error fetching water timestamp: $e");
      return null;
    }
  }

  Future<Timestamp?> getLatestElectricityUploadTimestamp(
    String? districtId,
    String municipalityId,
    String userPhoneNumber,
    String propertyAddress,
  ) async {
    try {
      final baseRef = (districtId != null && districtId.isNotEmpty)
          ? FirebaseFirestore.instance
              .collection('districts')
              .doc(districtId)
              .collection('municipalities')
          : FirebaseFirestore.instance.collection('localMunicipalities');

      final logPath = baseRef
          .doc(municipalityId)
          .collection('actionLogs')
          .doc(userPhoneNumber)
          .collection(propertyAddress);

      print("📄 Querying electricity actionLogs at: ${logPath.path}");

      final querySnapshot =
          await logPath.orderBy('timestamp', descending: true).limit(5).get();

      if (querySnapshot.docs.isEmpty) {
        print("❌ No documents found at that path.");
        return null;
      }

      for (var doc in querySnapshot.docs) {
        print("🔍 Checking electricity log doc:");
        print("- actionType: ${doc['actionType']}");
        print("- timestamp: ${doc['timestamp']}");
        final data = doc.data();
        print("🔍 Checking doc: ${data['actionType']}");

        if (data['actionType'] == "Upload Electricity Meter Image") {
          print("✅ Matched electricity upload log!");
          return data['timestamp'];
        }
      }

      print("! No matching electricity upload log found for $userPhoneNumber");
      return null;
    } catch (e) {
      print("❌ Error fetching electricity timestamp: $e");
      return null;
    }
  }

  Future<String> fetchWaterPropertyAddress(
    String userNumber,
    String waterMeterNumber,
    String districtId,
    String municipalityId,
    bool isLocalMunicipality,
  ) async {
    print("Fetching WATER property address with:");
    print("User Number: $userNumber");
    print("Water Meter Number: $waterMeterNumber");

    CollectionReference propertiesRef = isLocalMunicipality
        ? FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(municipalityId)
            .collection('properties')
        : FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('properties');

    try {
      QuerySnapshot querySnapshot = await propertiesRef
          .where('cellNumber', isEqualTo: userNumber)
          .where('water_meter_number', isEqualTo: waterMeterNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        print("Property found (water): ${doc.data()}");
        String address = doc['address'];
        print("Sanitized Address (water): $address");
        return address;
      } else {
        throw Exception(
            "No property found for user number: $userNumber and water meter number: $waterMeterNumber");
      }
    } catch (e) {
      print("Error fetching WATER property details: $e");
      return "Unknown Address";
    }
  }

  Future<String> fetchElectricityPropertyAddress(
    String userNumber,
    String electricityMeterNumber,
    String districtId,
    String municipalityId,
    bool isLocalMunicipality,
  ) async {
    print("Fetching ELECTRICITY property address with:");
    print("User Number: $userNumber");
    print("Electricity Meter Number: $electricityMeterNumber");

    CollectionReference propertiesRef = isLocalMunicipality
        ? FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(municipalityId)
            .collection('properties')
        : FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('properties');

    try {
      QuerySnapshot querySnapshot = await propertiesRef
          .where('cellNumber', isEqualTo: userNumber)
          .where('meter_number', isEqualTo: electricityMeterNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        print("Property found (electricity): ${doc.data()}");
        String address = doc['address'];
        print("Sanitized Address (electricity): $address");
        return address;
      } else {
        throw Exception(
            "No property found for user number: $userNumber and electricity meter number: $electricityMeterNumber");
      }
    } catch (e) {
      print("Error fetching ELECTRICITY property details: $e");
      return "Unknown Address";
    }
  }

  Future<void> fetchWaterImageAndTimestamp() async {
    final address = await fetchWaterPropertyAddress(
      propPhoneNum,
      wMeterNumber,
      widget.districtId,
      widget.municipalityId,
      widget.isLocalMunicipality,
    );

    final timestamp = await getLatestWaterUploadTimestamp(
      widget.districtId,
      widget.municipalityId,
      propPhoneNum,
      address,
    );
    latestWaterUploadTimestamp = timestamp?.toDate();

    final path =
        'files/meters/$formattedMonth/$propPhoneNum/$address/water/$wMeterNumber.jpg';
    waterImageUrl = await _getImageW(context, path, address);

    if (mounted) setState(() {});
  }

  Future<void> fetchElectricityImageAndTimestamp() async {
    print("⚡ Fetching electricity image and timestamp...");

    try {
      if (propPhoneNum.isNotEmpty) {
        final timestamp = await getLatestElectricityUploadTimestamp(
          widget.districtId,
          widget.municipalityId,
          propPhoneNum,
          widget.addressSnap,
        );

        if (timestamp != null) {
          setState(() {
            _electricityUploadTimestamp = timestamp;
            _hasFetchedElectricityTimestamp = true;
          });
          print(
              "✅ Electricity upload timestamp found: $_electricityUploadTimestamp");
          _electricityImageUrl = await _getImageE(
            context,
            widget.imageElectricName,
            widget.addressSnap,
          );
          print("✅ Electricity image URL fetched.");
        } else {
          setState(() {
            _electricityUploadTimestamp = null;
            _hasFetchedElectricityTimestamp = true;
          });
          print("❌ No electricity timestamp found.");
        }
      }
    } catch (e) {
      print("❌ Error fetching electricity image or timestamp: $e");
    }
  }

  // Future<Map<String, dynamic>> _fetchImageAndTimestamp(
  //     BuildContext context,
  //     String propPhoneNum,
  //     String meterNumber,
  //     String utilityType,
  //     ) async {
  //   String propertyAddress;
  //
  //   if (utilityType == "water") {
  //     propertyAddress = await fetchWaterPropertyAddress(
  //       propPhoneNum,
  //       meterNumber,
  //       widget.districtId,
  //       widget.municipalityId,
  //       widget.isLocalMunicipality,
  //     );
  //   } else if (utilityType == "electricity") {
  //     propertyAddress = await fetchElectricityPropertyAddress(
  //       propPhoneNum,
  //       meterNumber,
  //       widget.districtId,
  //       widget.municipalityId,
  //       widget.isLocalMunicipality,
  //     );
  //   } else {
  //     throw Exception("Unknown utility type: $utilityType");
  //   }
  //
  //   print("Sanitized Address ($utilityType): $propertyAddress");
  //
  //   Timestamp? timestamp;
  //   if (utilityType == "water") {
  //     timestamp = await getLatestWaterUploadTimestamp(
  //       widget.districtId,
  //       widget.municipalityId,
  //       propPhoneNum,
  //       propertyAddress,
  //     );
  //   } else if (utilityType == "electricity") {
  //     timestamp = await getLatestElectricityUploadTimestamp(
  //       widget.districtId,
  //       widget.municipalityId,
  //       propPhoneNum,
  //       propertyAddress,
  //     );
  //   }
  //
  //   String imagePath =
  //       'files/meters/$formattedMonth/$propPhoneNum/$propertyAddress/$utilityType/$meterNumber.jpg';
  //
  //   String imageUrl;
  //   if (utilityType == "water") {
  //     imageUrl = await _getImageW(context, imagePath);
  //   } else {
  //     imageUrl = await _getImageE(context, imagePath);
  //   }
  //
  //   return {
  //     'imageUrl': imageUrl,
  //     'propertyAddress': propertyAddress,
  //     'timestamp': timestamp,
  //   };
  // }

  // Future<Timestamp?> getLatestUploadTimestamp(
  //   String? districtId,
  //   String municipalityId,
  //   String userPhoneNumber,
  //   String propertyAddress,
  //   String actionType, // 🔌 e.g., "Upload Electricity Meter Image"
  // ) async {
  //   try {
  //     print("📁 Fetching timestamp from path:");
  //     print(
  //         "🗂️ Base: ${districtId != null && districtId.isNotEmpty ? 'districts/$districtId/municipalities/$municipalityId' : 'localMunicipalities/$municipalityId'}");
  //     print("📞 Phone (doc): $userPhoneNumber");
  //     print("🏠 Property (collection): $propertyAddress");
  //     print("🪪 Action Type: $actionType");
  //     QuerySnapshot querySnapshot;
  //
  //     final baseRef = (districtId != null && districtId.isNotEmpty)
  //         ? FirebaseFirestore.instance
  //             .collection('districts')
  //             .doc(districtId)
  //             .collection('municipalities')
  //         : FirebaseFirestore.instance.collection('localMunicipalities');
  //
  //     querySnapshot = await baseRef
  //         .doc(municipalityId)
  //         .collection('actionLogs')
  //         .doc(userPhoneNumber)
  //         .collection(propertyAddress)
  //         .where('actionType', isEqualTo: actionType) // ✅ Filter by actionType
  //         .orderBy('timestamp', descending: true)
  //         .limit(1)
  //         .get();
  //
  //     if (querySnapshot.docs.isNotEmpty) {
  //       return querySnapshot.docs.first['timestamp'];
  //     } else {
  //       return null;
  //     }
  //   } catch (e) {
  //     print("❌ Error fetching timestamp for $actionType: $e");
  //     return null;
  //   }
  // }
  //
  // Future<void> _fetchLatestUploadTimestamp(String utilityType) async {
  //   FirebaseAuth auth = FirebaseAuth.instance;
  //   User? user = auth.currentUser;
  //
  //   if (user != null) {
  //     // 🔄 Make sure this matches what you use in `logEMeterReadingUpdate`
  //     String actionType = utilityType == "water"
  //         ? "Upload Water Meter Image"
  //         : "Upload Electricity Meter Image";
  //
  //     if (propPhoneNum.isEmpty) {
  //       print("⚠️ propPhoneNum is empty — cannot fetch upload timestamp.");
  //       return;
  //     }
  //
  //     Timestamp? timestamp = await getLatestUploadTimestamp(
  //       widget.districtId,
  //       widget.municipalityId,
  //       propPhoneNum,
  //       widget.addressSnap,
  //       actionType,
  //     );
  //
  //     if (mounted) {
  //       setState(() {
  //         if (utilityType == "water") {
  //           latestWaterUploadTimestamp = timestamp?.toDate();
  //         } else if (utilityType == "electricity") {
  //           latestElectricityUploadTimestamp = timestamp?.toDate();
  //         }
  //       });
  //     }
  //
  //     print("📅 Latest $utilityType upload timestamp: $timestamp");
  //   }
  // }

  Future<Map<String, String>> fetchMeterReadings() async {
    try {
      DateTime now = DateTime.now();
      DateTime prevMonthDate = now.subtract(const Duration(days: 30));

      String currentMonth = DateFormat.MMMM().format(now); // e.g. "May"
      String previousMonth =
          DateFormat.MMMM().format(prevMonthDate); // e.g. "April"
      String currentYear = DateFormat('yyyy').format(now);
      String previousYear = DateFormat('yyyy').format(prevMonthDate);

      // Adjust year if previous month is Dec and current is Jan
      String prevMonthYear = (previousMonth == "December" && now.month == 1)
          ? previousYear
          : currentYear;

      print("📅 Fetching WATER readings...");
      print("🔹 Previous: $previousMonth ($prevMonthYear)");
      print("🔹 Current: $currentMonth ($currentYear)");
      print("🏠 addressSnap: '${widget.addressSnap}'");

      Map<String, String> readings = {
        "previous": "N/A",
        "current": "N/A",
      };

      if (widget.addressSnap.trim().isEmpty) {
        print("❌ addressSnap is null or empty!");
        return readings;
      }

      Future<DocumentSnapshot> fetchReading(String year, String month) async {
        final docPath = widget.isLocalMunicipality
            ? "localMunicipalities/${widget.municipalityId}/consumption/$year/$month/${widget.addressSnap}"
            : "districts/${widget.districtId}/municipalities/${widget.municipalityId}/consumption/$year/$month/${widget.addressSnap}";
        print("📄 Fetching doc from: $docPath");

        return await FirebaseFirestore.instance.doc(docPath).get();
      }

      // Previous month
      final prevSnap = await fetchReading(prevMonthYear, previousMonth);
      if (prevSnap.exists) {
        final data = prevSnap.data() as Map<String, dynamic>;
        readings["previous"] = data['water_meter_reading']?.toString() ?? "N/A";
        print("✅ Previous water reading: ${readings["previous"]}");
      } else {
        print("❌ No previous water reading found.");
      }

      // Current month
      final currSnap = await fetchReading(currentYear, currentMonth);
      if (currSnap.exists) {
        final data = currSnap.data() as Map<String, dynamic>;
        readings["current"] = data['water_meter_reading']?.toString() ?? "N/A";
        print("✅ Current water reading: ${readings["current"]}");
      } else {
        print("❌ No current water reading found.");
      }

      return readings;
    } catch (e) {
      print("🚨 Error in fetchMeterReadings(): $e");
      return {
        "previous": "N/A",
        "current": "N/A",
      };
    }
  }

  Future<void> _fetchLatestWaterMeterReading() async {
    Map<String, String> readings = await fetchMeterReadings();

    if (mounted) {
      setState(() {
        previousWaterReading = readings["previous"] ?? "N/A";
        currentWaterReading = readings["current"] ?? "N/A";
      });
    }
    print(
        "📊 Updated Readings - Previous: $previousWaterReading | Current: $currentWaterReading");
  }

  Future<Map<String, String>> fetchElectricityReadings() async {
    try {
      DateTime now = DateTime.now();
      DateTime prevMonthDate = now.subtract(const Duration(days: 30));

      String currentMonth = DateFormat.MMMM().format(now); // e.g. "May"
      String previousMonth =
          DateFormat.MMMM().format(prevMonthDate); // e.g. "April"
      String currentYear = DateFormat('yyyy').format(now);
      String previousYear = DateFormat('yyyy').format(prevMonthDate);

      String prevMonthYear = (previousMonth == "December" && now.month == 1)
          ? previousYear
          : currentYear;

      print("📅 Fetching ELECTRICITY readings...");
      print("🔌 Previous: $previousMonth ($prevMonthYear)");
      print("🔌 Current: $currentMonth ($currentYear)");
      print("🏠 addressSnap: '${widget.addressSnap}'");

      Map<String, String> readings = {
        "previous": "N/A",
        "current": "N/A",
      };

      if (widget.addressSnap.trim().isEmpty) {
        print("❌ addressSnap is null or empty!");
        return readings;
      }

      Future<DocumentSnapshot> fetchReading(String year, String month) async {
        final docPath = widget.isLocalMunicipality
            ? "localMunicipalities/${widget.municipalityId}/consumption/$year/$month/${widget.addressSnap}"
            : "districts/${widget.districtId}/municipalities/${widget.municipalityId}/consumption/$year/$month/${widget.addressSnap}";
        print("📄 Fetching doc from: $docPath");

        return await FirebaseFirestore.instance.doc(docPath).get();
      }

      final prevSnap = await fetchReading(prevMonthYear, previousMonth);
      if (prevSnap.exists) {
        final data = prevSnap.data() as Map<String, dynamic>;
        readings["previous"] = data['meter_reading']?.toString() ?? "N/A";
        print("✅ Previous electricity reading: ${readings["previous"]}");
      } else {
        print("❌ No previous electricity reading found.");
      }

      final currSnap = await fetchReading(currentYear, currentMonth);
      if (currSnap.exists) {
        final data = currSnap.data() as Map<String, dynamic>;
        readings["current"] = data['meter_reading']?.toString() ?? "N/A";
        print("✅ Current electricity reading: ${readings["current"]}");
      } else {
        print("❌ No current electricity reading found.");
      }

      return readings;
    } catch (e) {
      print("🚨 Error in fetchElectricityReadings(): $e");
      return {
        "previous": "N/A",
        "current": "N/A",
      };
    }
  }

  Future<void> _fetchLatestElectricityMeterReading() async {
    Map<String, String> readings = await fetchElectricityReadings();

    if (mounted) {
      setState(() {
        previousElectricityReading = readings["previous"] ?? "N/A";
        currentElectricityReading = readings["current"] ?? "N/A";
      });
    }

    print(
        "⚡ Updated Electricity Readings - Previous: $previousElectricityReading | Current: $currentElectricityReading");
  }

  Future<void> _create([DocumentSnapshot? documentSnapshot]) async {
    _accountNumberController.text = '';
    _addressController.text = '';
    _areaCodeController.text = '';
    _meterNumberController.text = '';
    _meterReadingController.text = '';
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
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _meterNumberController,
                      decoration:
                          const InputDecoration(labelText: 'Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _meterReadingController,
                      decoration:
                          const InputDecoration(labelText: 'Meter Reading'),
                    ),
                  ),
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
                      final String meterNumber = _meterNumberController.text;
                      final String meterReading = _meterReadingController.text;
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
                          "meter_number": meterNumber,
                          "meter_reading": meterReading,
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
                        _meterNumberController.text = '';
                        _meterReadingController.text = '';
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
      _meterNumberController.text = documentSnapshot['meter_number'];
      _meterReadingController.text = documentSnapshot['meter_reading'];
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
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _meterNumberController,
                      decoration: const InputDecoration(
                          labelText: 'Electricity Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      maxLength: 5,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      keyboardType: TextInputType.number,
                      controller: _meterReadingController,
                      decoration: const InputDecoration(
                          labelText: 'Electricity Meter Reading'),
                    ),
                  ),
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
                      final String meterNumber = _meterNumberController.text;
                      final String meterReading = _meterReadingController.text;
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
                          "meter_number": meterNumber,
                          "meter_reading": meterReading,
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
                        _meterNumberController.text = '';
                        _meterReadingController.text = '';
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

  Future<void> _updateE([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      _accountNumberController.text = documentSnapshot['accountNumber'];
      _addressController.text = documentSnapshot['address'];
      _areaCodeController.text = documentSnapshot['areaCode'].toString();
      _meterNumberController.text = documentSnapshot['meter_number'];
      _meterReadingController.text = documentSnapshot['meter_reading'];
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
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _meterNumberController,
                      decoration: const InputDecoration(
                          labelText: 'Electricity Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      maxLength: 5,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      keyboardType: TextInputType.number,
                      controller: _meterReadingController,
                      decoration: const InputDecoration(
                          labelText: 'Electricity Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _waterMeterController,
                      decoration: const InputDecoration(
                          labelText: 'Water Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
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
                      final String meterNumber = _meterNumberController.text;
                      final String meterReading = _meterReadingController.text;
                      final String waterMeterNumber =
                          _waterMeterController.text;
                      final String waterMeterReading =
                          _waterMeterReadingController.text;
                      final String cellNumber = _cellNumberController.text;
                      final String firstName = _firstNameController.text;
                      final String lastName = _lastNameController.text;
                      final String idNumber = _idNumberController.text;

                      Map<String, dynamic> updateDetails = {
                        "accountNumber": accountNumber,
                        "address": address,
                        "areaCode": areaCode,
                        "meter_number": meterNumber,
                        "meter_reading": meterReading,
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
                        await logEMeterReadingUpdate(
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
                        await FirebaseFirestore.instance
                            .collection('consumption')
                            .doc(formattedMonth)
                            .collection('address')
                            .doc(address)
                            .set({
                          "address": address,
                          "meter_reading": meterReading,
                          "water_meter_reading": waterMeterReading,
                        });

                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _areaCodeController.text = '';
                        _meterNumberController.text = '';
                        _meterReadingController.text = '';
                        _waterMeterController.text = '';
                        _waterMeterReadingController.text = '';
                        _cellNumberController.text = '';
                        _firstNameController.text = '';
                        _lastNameController.text = '';
                        _idNumberController.text = '';

                        if (context.mounted) Navigator.of(context).pop();
                        Fluttertoast.showToast(msg: "Reading updated!");
                      }
                    },
                  )
                ],
              ),
            ),
          );
        });
  }

  Future<void> _updateW([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      _accountNumberController.text = documentSnapshot['accountNumber'];
      _addressController.text = documentSnapshot['address'];
      _areaCodeController.text = documentSnapshot['areaCode'].toString();
      _meterNumberController.text = documentSnapshot['meter_number'];
      _meterReadingController.text = documentSnapshot['meter_reading'];
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
                Visibility(
                  visible: visibilityState2,
                  child: TextField(
                    controller: _meterNumberController,
                    decoration: const InputDecoration(
                        labelText: 'Electricity Meter Number'),
                  ),
                ),
                Visibility(
                  visible: visibilityState2,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: _meterReadingController,
                    decoration: const InputDecoration(
                        labelText: 'Electricity Meter Reading'),
                  ),
                ),
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
                      final String meterNumber = _meterNumberController.text;
                      final String meterReading = _meterReadingController.text;
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
                        "meter_number": meterNumber,
                        "meter_reading": meterReading,
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
                        _meterNumberController.text = '';
                        _meterReadingController.text = '';
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
                    eMeterNumber = documentSnapshot['meter_number'];

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
                            if(handlesWater)...[
                            Text(
                              'Water Account Number: ${documentSnapshot['accountNumber']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            ],
                            const SizedBox(
                              height: 10,
                            ),
                            if(handlesElectricity)...[
                              Text(
                                'Electricity Account Number: ${documentSnapshot['electricityAccountNumber']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                            const SizedBox(
                              height: 10,
                            ),
                            if (handlesElectricity) ...[
                              const Center(
                                child: Text(
                                  'Electricity Meter Reading Photo',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 5),
                              if (_electricityImageUrl != null)
                                GestureDetector(
                                  onTap: () {
                                    final imageProvider =
                                        NetworkImage(_electricityImageUrl!);
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
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      elevation: 0,
                                      margin: const EdgeInsets.all(10.0),
                                      child: Center(
                                        child: Image.network(
                                            _electricityImageUrl!,
                                            fit: BoxFit.cover),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                const Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                            'No electricity meter image uploaded yet.'),
                                        SizedBox(height: 10),
                                        FaIcon(Icons.flash_on),
                                      ],
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 10),
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: DateTime.now().day >= 28
                                      ? null
                                      : () async {
                                          eMeterNumber =
                                              documentSnapshot['meter_number'];
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
                                                    "Upload Electricity Meter"),
                                                content: const Text(
                                                    "Uploading a new image will replace current image!\n\nAre you sure?"),
                                                actions: [
                                                  IconButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    icon: const Icon(
                                                        Icons.cancel,
                                                        color: Colors.red),
                                                  ),
                                                  IconButton(
                                                    onPressed: () async {
                                                      Fluttertoast.showToast(
                                                          msg:
                                                              "Uploading a new image\nwill replace current image!");
                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              ImageUploadMeter(
                                                            userNumber:
                                                                propPhoneNum,
                                                            meterNumber:
                                                                eMeterNumber,
                                                            municipalityUserEmail:
                                                                widget
                                                                    .municipalityUserEmail,
                                                            propertyAddress:
                                                                propertyAddress,
                                                            districtId: widget
                                                                .districtId,
                                                            municipalityId: widget
                                                                .municipalityId,
                                                            isLocalMunicipality:
                                                                widget
                                                                    .isLocalMunicipality,
                                                            isLocalUser: widget
                                                                .isLocalUser,
                                                          ),
                                                        ),
                                                      ).then(
                                                        (uploadCompleted) async {
                                                          if (uploadCompleted ==
                                                              true) {
                                                            print(
                                                                "✅ Upload completed. Refreshing electricity image and timestamp...");
                                                            imageCacheMap.remove(
                                                                "${propertyAddress}_electricity");
                                                            await fetchElectricityImageAndTimestamp(); // NEW unified method
                                                            await _fetchLatestElectricityMeterReading(); // Optional: also refresh reading
                                                            if (mounted) {
                                                              setState(() {});
                                                            }
                                                          } else {
                                                            print(
                                                                "⚠️ Upload was not completed.");
                                                          }
                                                        },
                                                      );
                                                    },
                                                    icon: const Icon(Icons.done,
                                                        color: Colors.green),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                  icon: FaIcon(
                                    Icons.camera_alt,
                                    color: DateTime.now().day >= 28
                                        ? Colors.grey.shade500
                                        : Colors.black,
                                  ),
                                  label: Text(
                                    DateTime.now().day >= 28
                                        ? 'Meter uploads can only be\ndone before the 28th'
                                        : 'Update electricity meter\nimage and reading',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.tenorSans(
                                      color: DateTime.now().day >= 28
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(200, 50),
                                    backgroundColor: DateTime.now().day >= 28
                                        ? Colors.grey.shade600
                                        : Colors.white70,
                                    foregroundColor: DateTime.now().day >= 28
                                        ? Colors.white
                                        : Colors.black,
                                    disabledForegroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        Colors.grey.shade600,
                                    side: BorderSide(
                                      width: 1,
                                      color: DateTime.now().day >= 28
                                          ? Colors.grey.shade700
                                          : Colors.black38,
                                    ),
                                    shadowColor: DateTime.now().day >= 28
                                        ? Colors.transparent
                                        : Colors.black,
                                    elevation: DateTime.now().day >= 28 ? 0 : 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (_hasFetchedElectricityTimestamp) ...[
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Center(
                                    child: Text(
                                      _electricityUploadTimestamp != null
                                          ? "⚡ Electricity image uploaded on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_electricityUploadTimestamp!.toDate())}"
                                          : "⚡ No electricity upload history available.",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.blueGrey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              const SizedBox(height: 5),
                              Text(
                                'Electricity Meter Number: ${documentSnapshot['meter_number']}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Previous Month Electricity ($previousMonth) Reading: ${previousElectricityReading ?? "N/A"}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Current Month Electricity ($currentMonth) Reading: ${currentElectricityReading ?? "N/A"}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                            ],
                            const SizedBox(
                              height: 5,
                            ),
                            if (handlesWater) ...[
                              const Center(
                                child: Text(
                                  'Water Meter Reading Photo',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 5),
                              if (waterImageUrl != null)
                                GestureDetector(
                                  onTap: () {
                                    final imageProvider =
                                        NetworkImage(waterImageUrl!);
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
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      elevation: 0,
                                      margin: const EdgeInsets.all(10.0),
                                      child: Center(
                                        child: Image.network(
                                          waterImageUrl!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                const Padding(
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
                                ),
                              const SizedBox(height: 10),
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: DateTime.now().day >= 28
                                      ? null
                                      : () async {
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
                                                        color: Colors.red),
                                                  ),
                                                  IconButton(
                                                    onPressed: () async {
                                                      Fluttertoast.showToast(
                                                          msg:
                                                              "Uploading a new image\nwill replace current image!");
                                                      Navigator.pop(context);

                                                      bool? uploadCompleted =
                                                          await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              ImageUploadWater(
                                                            userNumber:
                                                                propPhoneNum,
                                                            meterNumber:
                                                                wMeterNumber,
                                                            municipalityUserEmail:
                                                                widget
                                                                    .municipalityUserEmail,
                                                            propertyAddress:
                                                                propertyAddress,
                                                            districtId: widget
                                                                .districtId,
                                                            municipalityId: widget
                                                                .municipalityId,
                                                            isLocalMunicipality:
                                                                widget
                                                                    .isLocalMunicipality,
                                                            isLocalUser: widget
                                                                .isLocalUser,
                                                          ),
                                                        ),
                                                      );

                                                      if (uploadCompleted ==
                                                          true) {
                                                        print(
                                                            "✅ Upload completed successfully! Refreshing water image and timestamp...");
                                                        imageCacheMap.remove(
                                                            "${propertyAddress}_water");
                                                        await fetchWaterImageAndTimestamp(); // 🔁 NEW unified method
                                                        await _fetchLatestWaterMeterReading(); // Optional: refresh reading as well

                                                        if (mounted) {
                                                          setState(() {});
                                                        }
                                                      } else {
                                                        print(
                                                            "⚠️ Upload was not completed.");
                                                      }
                                                    },
                                                    icon: const Icon(Icons.done,
                                                        color: Colors.green),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                  icon: FaIcon(
                                    Icons.camera_alt,
                                    color: DateTime.now().day >= 28
                                        ? Colors.grey.shade500
                                        : Colors.black,
                                  ),
                                  label: Text(
                                    DateTime.now().day >= 28
                                        ? 'Meter uploads can only be\ndone before the 28th'
                                        : 'Update water meter\nimage and reading',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.tenorSans(
                                      color: DateTime.now().day >= 28
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(200, 50),
                                    backgroundColor: DateTime.now().day >= 28
                                        ? Colors.grey.shade600
                                        : Colors.white70,
                                    foregroundColor: DateTime.now().day >= 28
                                        ? Colors.white
                                        : Colors.black,
                                    disabledForegroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        Colors.grey.shade600,
                                    side: BorderSide(
                                      width: 1,
                                      color: DateTime.now().day >= 28
                                          ? Colors.grey.shade700
                                          : Colors.black38,
                                    ),
                                    shadowColor: DateTime.now().day >= 28
                                        ? Colors.transparent
                                        : Colors.black,
                                    elevation: DateTime.now().day >= 28 ? 0 : 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Center(
                                child: Text(
                                  latestWaterUploadTimestamp != null
                                      ? "💧 Water image uploaded on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(latestWaterUploadTimestamp!)}"
                                      : "💧 No water upload history available.",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.blueGrey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Water Meter Number: ${documentSnapshot['water_meter_number']}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Previous Month Water ($previousMonth) Reading: ${previousWaterReading ?? "N/A"}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Current Month Water ($currentMonth) Reading: ${currentWaterReading ?? "N/A"}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                            ],
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
          },
        ),
      ),
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
