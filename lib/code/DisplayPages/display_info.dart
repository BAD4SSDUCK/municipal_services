import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:municipal_services/code/ImageUploading/image_upload_meter.dart';
import 'package:municipal_services/code/ImageUploading/image_upload_water.dart';
import 'package:municipal_services/code/MapTools/map_screen.dart';
import 'package:municipal_services/code/PDFViewer/pdf_api.dart';
import 'package:municipal_services/code/PDFViewer/view_pdf.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';
import 'package:municipal_services/code/DisplayPages/display_property_trend.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Models/prop_provider.dart';
import '../Models/property.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';

//View Details user side
class UsersTableViewPage extends StatefulWidget {
  final Property property;
  final String userNumber;
  final String propertyAddress;
  final String accountNumber;
  final String? districtId;
  final String municipalityId;
  final bool isLocalMunicipality;

  const UsersTableViewPage({
    super.key,
    required this.property,
    required this.userNumber,
    required this.propertyAddress,
    required this.accountNumber,
    required this.districtId,
    required this.municipalityId,
    required this.isLocalMunicipality,
  });

  @override
  _UsersTableViewPageState createState() => _UsersTableViewPageState();
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
String addressForTrend = ' ';

String propPhoneNum = ' ';

bool visibilityState1 = true;
bool visibilityState2 = false;

bool imgUploadCheck = false;
DateTime? latestUploadTimestamp; // Variable to store the latest timestamp
final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;

class FireStorageService extends ChangeNotifier {
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async {
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

// Future<String> _getImage(BuildContext context, String? imagePath) async {
//   if (imagePath == null) {
//     throw Exception('Image path cannot be null');
//   }
//   try {
//     String imageUrl =
//         await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
//     return imageUrl; // Returns the image URL
//   } catch (e) {
//     print('Failed to load image: $e');
//     throw Exception('Failed to load image');
//   }
// }



// Method that fetches the image URL from Firebase Storage
Future<String> _getImageW(BuildContext context, String? imagePath) async {
  if (imagePath == null) {
    throw Exception('Image path cannot be null');
  }
  try {
    String imageUrl =
        await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    return imageUrl; // Returns the image URL
  } catch (e) {
    print('Failed to load image: $e');
    throw Exception('Failed to load image');
  }
}

class _UsersTableViewPageState extends State<UsersTableViewPage> {
  Stream<QuerySnapshot>? _propertyStream;
  CollectionReference? _propList;
  String? propertyAddress;

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

  var _isLoading = false;
  bool _isLoadingProp = true;
  String currentMonth = DateFormat.MMMM().format(DateTime.now()); // Example: February
  String previousMonth = DateFormat.MMMM().format(DateTime.now().subtract(Duration(days: 30))); // Example: January
  String? previousMonthReading;
  String?currentMonthReading;
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool _isLoadingAd = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _loadRewardedAd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final propertyProvider = Provider.of<PropertyProvider>(
          context, listen: false);
      if (propertyProvider.selectedProperty == null) {
        print('Error: Selected property is null. Retrying fetch...');
        if (mounted) {
          setState(() {
            _isLoadingProp =
            true; // Trigger a loading state while fetching data
          });
        }
        // Attempt to load the selected property
        propertyProvider.loadSelectedPropertyAccountNo().then((_) {
          if (propertyProvider.selectedProperty != null) {
            initializeFirestoreReferences(context);
            fetchPropertyDetails();
          }
          if (mounted) {
            setState(() {
              _isLoadingProp = false;
            });
          }
        });
      } else {
        // If the property is already available, initialize Firestore and fetch details
        initializeFirestoreReferences(context);
        fetchPropertyDetails();
        if (mounted) {
          setState(() {
            _isLoadingProp = false;
          });
        }
      }
    });
    propPhoneNum = widget.property.cellNum;
    wMeterNumber = widget.property.waterMeterNum;
    // Adjust the query to listen only to the selected property
    _fetchLatestUploadTimestamp();
    fetchMeterReadings().then((readings) {
      if (mounted) {
        setState(() {
          previousMonthReading = readings["previous"];  // Extract previous month reading
          currentMonthReading = readings["current"];    // Extract current month reading
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void initializeFirestoreReferences(BuildContext context) async {
    final propertyProvider = Provider.of<PropertyProvider>(
        context, listen: false);
    Property? selectedProperty = propertyProvider.selectedProperty;

    if (selectedProperty != null) {
      if (selectedProperty.isLocalMunicipality) {
        _propList = FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(selectedProperty.municipalityId)
            .collection('properties');
      } else {
        _propList = FirebaseFirestore.instance
            .collection('districts')
            .doc(selectedProperty.districtId)
            .collection('municipalities')
            .doc(selectedProperty.municipalityId)
            .collection('properties');
      }

      _propertyStream = _propList!
          .where('accountNumber', isEqualTo: selectedProperty.accountNo)
          .snapshots();
      if (mounted) {
        setState(() {
          _isLoadingProp =
          false; // Firestore references initialized, stop loading
        });
      }
    } else {
      print("Error: Selected property is null.");
    }
  }


  Future<void> fetchPropertyDetails() async {
    try {
      var propertyQuery = await _propList!
          .where('cellNumber', isEqualTo: widget.userNumber)
          .limit(1)
          .get();

      if (propertyQuery.docs.isNotEmpty) {
        Map<String, dynamic>? propertyData = propertyQuery.docs.first
            .data() as Map<String, dynamic>?;
        if (mounted) {
          setState(() {
            propertyAddress =
                propertyData?['address'] ?? 'Address not available';
          });
        }
      } else {
        print('No matching property found for the given user number.');
      }
    } catch (e) {
      print('Error fetching property details: $e');
    }
  }

  void _onSubmit() {
    setState(() => _isLoading = true);
    Future.delayed(
      const Duration(seconds: 5),
          () => setState(() => _isLoading = false),
    );
  }

  String formattedMonth =
  DateFormat.MMMM().format(now); //format for full Month by name
  String formattedDateMonth =
  DateFormat.MMMMd().format(now); //format for Day Month only

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

  Future<void> updateImgCheckW(bool imgCheck,
      [DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      await _propList?.doc(documentSnapshot.id).update({
        "imgStateW": imgCheck,
      });
    }
  }

  // Ensures the document for logging exists with an initial timestamp.
// Ensures the document for the user's action log exists.
  Future<void> ensureDocumentExists(String? districtId,
      // Nullable districtId to support local municipalities
      String municipalityId,
      String userId,
      String propertyAddress,) async {
    DocumentReference actionLogDocRef;

    if (districtId != null && districtId.isNotEmpty) {
      // District-based municipality
      actionLogDocRef = FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('actionLogs')
          .doc(userId)
          .collection(propertyAddress)
          .doc('actions');
    } else {
      // Local municipality
      actionLogDocRef = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('actionLogs')
          .doc(userId)
          .collection(propertyAddress)
          .doc('actions');
    }

    // Ensure the document exists by adding an initial record if necessary
    await actionLogDocRef.set(
        {'created': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }


// Logs the electricity meter reading updates.
//   Future<void> logEMeterReadingUpdate(
//       String districtId,
//       String municipalityId,
//       String userId,
//       String propertyAddress,
//       Map<String, dynamic> details,
//       ) async {
//     FirebaseAuth auth = FirebaseAuth.instance;
//     User? user = auth.currentUser;
//
//     if (user != null && user.phoneNumber != null) {
//       String userPhoneNumber = user.phoneNumber ?? "Unknown";
//
//       // Ensure the action log document exists before adding actions
//       await ensureDocumentExists(districtId, municipalityId, userPhoneNumber, propertyAddress);
//
//       // Action log reference (auto-generate a document ID for each action)
//       DocumentReference actionLogRef = FirebaseFirestore.instance
//           .collection('districts')
//           .doc(districtId)
//           .collection('municipalities')
//           .doc(municipalityId)
//           .collection('actionLogs')
//           .doc(userPhoneNumber)
//           .collection(propertyAddress)
//           .doc();  // Auto-generate a document ID for each action
//
//       // Add the meter reading update action
//       await actionLogRef.set({
//         'actionType': 'Electricity Meter Reading Update',
//         'uploader': userPhoneNumber,
//         'details': details,
//         'address': propertyAddress,
//         'timestamp': FieldValue.serverTimestamp(),
//         'description': '$userPhoneNumber updated electricity meter readings at $propertyAddress',
//       });
//     } else {
//       print("User is not authenticated or phone number is not available.");
//     }
//   }

// Logs the water meter reading updates.
  Future<void> logWMeterReadingUpdate(String? districtId,
      // Nullable to support local municipalities
      String municipalityId,
      String userId,
      String propertyAddress,
      Map<String, dynamic> details,) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    if (user != null && user.phoneNumber != null) {
      String userPhoneNumber = user.phoneNumber ?? "Unknown";

      await ensureDocumentExists(
          districtId, municipalityId, userPhoneNumber, propertyAddress);

      DocumentReference actionLogRef;

      if (districtId != null && districtId.isNotEmpty) {
        // District-based municipality
        actionLogRef = FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('actionLogs')
            .doc(userPhoneNumber)
            .collection(propertyAddress)
            .doc(); // Auto-generate document ID for each action
      } else {
        // Local municipality
        actionLogRef = FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(municipalityId)
            .collection('actionLogs')
            .doc(userPhoneNumber)
            .collection(propertyAddress)
            .doc(); // Auto-generate document ID for each action
      }

      // Add the meter reading update action
      await actionLogRef.set({
        'actionType': 'Water Meter Reading Update',
        'uploader': userPhoneNumber,
        'details': details,
        'address': propertyAddress,
        'timestamp': FieldValue.serverTimestamp(),
        'description': '$userPhoneNumber updated water meter readings at $propertyAddress',
      });
    } else {
      print("User is not authenticated or phone number is not available.");
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


  Future<void> _fetchLatestUploadTimestamp() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    if (user != null) {
      Timestamp? timestamp = await getLatestUploadTimestamp(
        widget.districtId,
        widget.municipalityId,
        user.phoneNumber ?? "",
        widget.propertyAddress,
      );

      if (mounted) {
        setState(() {
          latestUploadTimestamp = timestamp?.toDate();
        });
      }
      print("📅 Latest Upload Timestamp Updated: $latestUploadTimestamp");
    }
  }

  Future<Map<String, String>> fetchMeterReadings() async {
    try {
      DateTime now = DateTime.now();
      DateTime prevMonthDate = now.subtract(const Duration(days: 30));
      String currentMonth = DateFormat.MMMM().format(now); // Example: "February"
      String previousMonth = DateFormat.MMMM().format(prevMonthDate); // Example: "January"
      String currentYear = DateFormat('yyyy').format(now); // Example: "2025"
      String previousYear = DateFormat('yyyy').format(now.subtract(const Duration(days: 365))); // Example: "2024"

      // Determine the correct year for previous month
      String prevMonthYear = (previousMonth == "December" && now.month == 1) ? previousYear : currentYear;
      print("📅 Fetching meter readings for:");
      print("🔹 Previous Month: $previousMonth ($prevMonthYear)");
      print("🔹 Current Month: $currentMonth ($currentYear)");

      Map<String, String> readings = {
        "previous": "N/A",
        "current": "N/A",
      };

      Future<DocumentSnapshot> fetchReading(String year, String month) async {
        DocumentReference propertyDoc;

        if (widget.isLocalMunicipality) {
          propertyDoc = FirebaseFirestore.instance
              .collection('localMunicipalities')
              .doc(widget.municipalityId)
              .collection('consumption')
              .doc(year)
              .collection(month)
              .doc(widget.propertyAddress);
        } else {
          propertyDoc = FirebaseFirestore.instance
              .collection('districts')
              .doc(widget.districtId)
              .collection('municipalities')
              .doc(widget.municipalityId)
              .collection('consumption')
              .doc(year)
              .collection(month)
              .doc(widget.propertyAddress);
        }

        return await propertyDoc.get();
      }

      // Fetch Previous Month Reading
      DocumentSnapshot prevMonthSnapshot = await fetchReading(prevMonthYear, previousMonth);
      if (prevMonthSnapshot.exists) {
        var data = prevMonthSnapshot.data() as Map<String, dynamic>;
        readings["previous"] = data['water_meter_reading'] ?? "N/A";
        print("✅ Previous Month Reading: ${readings["previous"]}");
      } else {
        print("❌ No Previous Month Reading Found");
      }

      // Fetch Current Month Reading
      DocumentSnapshot currentMonthSnapshot = await fetchReading(currentYear, currentMonth);
      if (currentMonthSnapshot.exists) {
        var data = currentMonthSnapshot.data() as Map<String, dynamic>;
        readings["current"] = data['water_meter_reading'] ?? "N/A";
        print("✅ Current Month Reading: ${readings["current"]}");
      } else {
        print("❌ No Current Month Reading Found");
      }

      return readings;
    } catch (e) {
      print("🚨 Error fetching meter readings: $e");
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
        previousMonthReading = readings["previous"] ?? "N/A";
        currentMonthReading = readings["current"] ?? "N/A";
      });
    }
    print("📊 Updated Readings - Previous: $previousMonthReading | Current: $currentMonthReading");
  }

  void _loadRewardedAd() {
    if (kIsWeb) return;
    print("🔄 Loading a new rewarded ad...");
    if (mounted) {
      setState(() {
        _isLoadingAd = true; // Mark as loading
      });
    }
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917', // Test Ad Unit
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          if(mounted) {
            setState(() {
              _rewardedAd = ad;
              _isAdLoaded = true;
              _isLoadingAd = false; // Mark as loaded
              print("✅ Rewarded Ad Loaded");
            });
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          print("❌ Failed to Load Rewarded Ad: $error");
          if(mounted) {
            setState(() {
              _isAdLoaded = false;
              _isLoadingAd = false; // Mark as done loading
              _rewardedAd = null;
            });
          }
        },
      ),
    );
  }


  Future<void> _showRewardedAd() async {
    if (kIsWeb) {
      print("🌐 Web detected, skipping ad and downloading statement directly.");
      _fetchAndOpenStatement();
      return;
    }
    if (_isLoadingAd) {
      Fluttertoast.showToast(msg: "🔄 Ad is still loading... Please wait.");
      return; // Prevent access until loading completes
    }

    if (_rewardedAd == null || !_isAdLoaded) {
      print("⚠️ Ad not loaded, opening statement directly.");
      _fetchAndOpenStatement();
      _loadRewardedAd(); // Reload the ad even if it failed
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        print("✅ Ad Dismissed. Opening statement.");
        ad.dispose();
        _fetchAndOpenStatement(); // Open the statement AFTER the ad is closed
        _loadRewardedAd(); // Load a new ad for next attempt
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print("❌ Failed to Show Ad: $error. Opening statement.");
        ad.dispose();
        _fetchAndOpenStatement(); // Open the statement since ad failed
        _loadRewardedAd(); // Reload the ad
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      print("🎉 User watched ad, unlocking statement.");
    });
        if(mounted) {
          setState(() {
            _rewardedAd = null;
            _isAdLoaded = false;
          });
        }
  }


  void _fetchAndOpenStatement() async {
    Fluttertoast.showToast(
        msg: "Now opening your statement!\nPlease wait a few seconds!");

    // Handle any necessary updates
    String previousMonth = DateFormat('MMMM').format(DateTime.now().subtract(Duration(days: 30)));
    String formattedAddress = widget.propertyAddress.trim();

    print('Attempting to list files in path: pdfs/$previousMonth/${widget.userNumber}/$formattedAddress/');

    final storageRef = FirebaseStorage.instance
        .ref()
        .child("pdfs/$previousMonth/${widget.userNumber}/$formattedAddress");

    try {
      final listResult = await storageRef.listAll();

      print('Files found in directory: ${listResult.items.length}');

      if (listResult.items.isEmpty) {
        Fluttertoast.showToast(msg: "No files found in the directory.");
        return;
      }

      bool found = false;
      String? webPdfUrl;
      File? mobilePdfFile;

      for (var item in listResult.items) {
        if (item.name.contains(widget.accountNumber)) {
          print('Found matching file: ${item.name}');
          webPdfUrl = await item.getDownloadURL();
          print('Download URL: $webPdfUrl');

          if (!kIsWeb) {
            final directory = await getApplicationDocumentsDirectory();
            final filePath = '${directory.path}/${item.name}';
            final response = await Dio().download(webPdfUrl, filePath);

            if (response.statusCode == 200) {
              mobilePdfFile = File(filePath);
              Fluttertoast.showToast(msg: "Successful!");
            } else {
              Fluttertoast.showToast(msg: "Failed to download PDF.");
            }
          }
          found = true;
          break;
        }
      }

      if (!found) {
        Fluttertoast.showToast(msg: "No matching invoice found.");
        return;
      }

      openPDF(context, mobilePdfFile, webPdfUrl);
    } catch (e) {
      print('Error opening PDF: $e');
      Fluttertoast.showToast(msg: "Unable to open statement.");
    }
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

                      if (accountNumber.isNotEmpty) {
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
                          "idNumber": idNumber,
                          "districtId": widget.districtId,
                          "municipalityId": widget.municipalityId
                        });

                        CollectionReference consumptionRef;

                        if (widget.districtId != null &&
                            widget.districtId!.isNotEmpty) {
                          consumptionRef = FirebaseFirestore.instance
                              .collection('districts')
                              .doc(widget.districtId)
                              .collection('municipalities')
                              .doc(widget.municipalityId)
                              .collection('consumption');
                        } else {
                          consumptionRef = FirebaseFirestore.instance
                              .collection('localMunicipalities')
                              .doc(widget.municipalityId)
                              .collection('consumption');
                        }

                        await consumptionRef
                            .doc(formattedMonth)
                            .collection('properties')
                            .doc(address)
                            .set({
                          "address": address,
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
                  bottom: MediaQuery
                      .of(ctx)
                      .viewInsets
                      .bottom + 20),
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

                        CollectionReference consumptionRef;

                        if (widget.districtId != null &&
                            widget.districtId!.isNotEmpty) {
                          consumptionRef = FirebaseFirestore.instance
                              .collection('districts')
                              .doc(widget.districtId)
                              .collection('municipalities')
                              .doc(widget.municipalityId)
                              .collection('consumption');
                        } else {
                          consumptionRef = FirebaseFirestore.instance
                              .collection('localMunicipalities')
                              .doc(widget.municipalityId)
                              .collection('consumption');
                        }

                        await consumptionRef
                            .doc(formattedMonth)
                            .collection('properties')
                            .doc(address)
                            .set({
                          "address": address,
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
  //                     //   await _propList.doc(documentSnapshot!.id).update({
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
  //                     //     "user id": userID,
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
  //                     // if (accountNumber.isNotEmpty) {
  //                     //   await _propList
  //                     //       .doc(documentSnapshot!.id)
  //                     //       .update(updateDetails);
  //                     if (meterReading.isNotEmpty) {
  //                       await FirebaseFirestore.instance
  //                           .collection('districts')
  //                           .doc(widget.districtId)
  //                           .collection('municipalities')
  //                           .doc(widget.municipalityId)
  //                           .collection('properties')
  //                           .doc(documentSnapshot?.id)
  //                           .update({
  //                         "meter_reading": meterReading,
  //                       });
  //
  //                       String formattedMonth =
  //                       DateFormat.MMMM().format(DateTime.now());
  //                       String address = documentSnapshot?['address'];
  //
  //                       await FirebaseFirestore.instance
  //                           .collection('districts')
  //                           .doc(widget.districtId)
  //                           .collection('municipalities')
  //                           .doc(widget.municipalityId)
  //                           .collection('consumption')
  //                           .doc(formattedMonth)
  //                           .collection('address')
  //                           .doc(address)
  //                           .set({
  //                         "address": address,
  //                         "meter_reading": meterReading,
  //                       }, SetOptions(merge: true));
  //
  //                       await logEMeterReadingUpdate(
  //                           widget.districtId,
  //                           widget.municipalityId,
  //                           userID,
  //                           address,
  //                           updateDetails);
  //
  //                       Navigator.pop(context); // Close the modal
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
  //                           .doc(widget.districtId)
  //                           .collection('municipalities')
  //                           .doc(widget.municipalityId)
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
  //                       // if (context.mounted) {
  //                       //   showDialog(
  //                       //       barrierDismissible: false,
  //                       //       context: context,
  //                       //       builder: (context) {
  //                       //         return AlertDialog(
  //                       //           title: const Text("Upload Electricity Meter"),
  //                       //           content: const Text(
  //                       //               "Uploading a new image will replace current image!\n\nAre you sure?"),
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
  //                       //                 Fluttertoast.showToast(
  //                       //                     msg:
  //                       //                         "Uploading a new image\nwill replace current image!");
  //                       //                 Navigator.push(
  //                       //                     context,
  //                       //                     MaterialPageRoute(
  //                       //                         builder: (context) =>
  //                       //                             ImageUploadMeter(
  //                       //                               userNumber: cellNumber,
  //                       //                               meterNumber: meterNumber,
  //                       //                             )));
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
                  bottom: MediaQuery
                      .of(ctx)
                      .viewInsets
                      .bottom + 20),
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
                  //   child: TextFormField(
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

                      // if (accountNumber != null) {
                      //   await _propList.doc(documentSnapshot!.id).update({
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
                      //     "user id": userID,
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
                      // if (accountNumber.isNotEmpty) {
                      //   await _propList
                      //       .doc(documentSnapshot!.id)
                      //       .update(updateDetails);
                      CollectionReference consumptionRef;
                      if (waterMeterReading.isNotEmpty) {
                        // Update properties and consumption based on the municipality type
                        if (widget.districtId!.isNotEmpty) {
                          _propList = FirebaseFirestore.instance
                              .collection('districts')
                              .doc(widget.districtId)
                              .collection('municipalities')
                              .doc(widget.municipalityId)
                              .collection('properties');
                          consumptionRef = FirebaseFirestore.instance
                              .collection('districts')
                              .doc(widget.districtId)
                              .collection('municipalities')
                              .doc(widget.municipalityId)
                              .collection('consumption');
                        } else {
                          _propList = FirebaseFirestore.instance
                              .collection('localMunicipalities')
                              .doc(widget.municipalityId)
                              .collection('properties');
                          consumptionRef = FirebaseFirestore.instance
                              .collection('localMunicipalities')
                              .doc(widget.municipalityId)
                              .collection('consumption');
                        }

                        // Update the properties collection
                        await _propList?.doc(documentSnapshot?.id).update({
                          "water_meter_reading": waterMeterReading,
                        });

                        // Update the consumption collection
                        String formattedMonth = DateFormat.MMMM().format(
                            DateTime.now());
                        await consumptionRef.doc(formattedMonth).collection(
                            'properties').doc(address).set({
                          "water_meter_reading": waterMeterReading,
                        }, SetOptions(merge: true));

                        // Log the update action
                        await logWMeterReadingUpdate(
                          widget.districtId,
                          widget.municipalityId,
                          userID,
                          widget.propertyAddress,
                          updateDetails,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Meter readings updated successfully"),
                              duration: Duration(seconds: 2),
                            ));
                        Navigator.of(context).pop(); // Close the modal
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Please fill in all required fields."),
                              duration: Duration(seconds: 2),
                            ));
                        // await FirebaseFirestore.instance
                        //     .collection('consumption')
                        //     .doc(formattedMonth)
                        //     .collection('address')
                        //     .doc(address)
                        //     .set({
                        //   "address": address,
                        //   "meter reading": meterReading,
                        //   "water meter reading": waterMeterReading,
                        // });
                        _resetTextFields();


                        if (context.mounted) Navigator.of(context).pop();

                        //Added open the image upload straight after inputting the meter reading
                        if (context.mounted) {
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
                                        Fluttertoast.showToast(
                                            msg:
                                            "Uploading a new image\nwill replace current image!");
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ImageUploadWater(
                                                  userNumber: documentSnapshot?[
                                                  'cellNumber'],
                                                  meterNumber: documentSnapshot?[
                                                  'water_meter_number'],
                                                  propertyAddress:
                                                  widget.propertyAddress,
                                                  districtId: widget
                                                      .districtId ?? '',
                                                  municipalityId:
                                                  widget.municipalityId,
                                                  isLocalMunicipality: widget
                                                      .isLocalMunicipality,
                                                ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.done,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                );
                              });
                        }
                      }
                    },
                  )
                ],
              ),
            ),
          );
        });
  }
  DateTime testDate = DateTime(2024, 3, 28);
  void _resetTextFields() {
    _accountNumberController.text = '';
    _addressController.text = '';
    _areaCodeController.text = '';
    _waterMeterController.text = '';
    _waterMeterReadingController.text = '';
    _cellNumberController.text = '';
    _firstNameController.text = '';
    _lastNameController.text = '';
    _idNumberController.text = '';
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
          'Account Management',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingProp // Check if data is still loading
          ? const Center(
          child: CircularProgressIndicator()) // Show a loading indicator
          : Padding(
        padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _propertyStream, //_propList.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              var documentSnapshot = snapshot.data!.docs.first;
              return ListView.builder(

                ///this call is to display all details for all users but is only displaying for the current user account.
                ///it can be changed to display all users for the staff to see if the role is set to all later on.
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final DocumentSnapshot documentSnapshot =
                  snapshot.data!.docs[index];

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

                  ///Check for only user information, this displays only for the users details and not all users in the database.
                  if (snapshot.data!.docs[index]['cellNumber'] == phoneNum) {
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
                              'Previous Month ($previousMonth) Reading: $previousMonthReading',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              'Water Meter Reading for $currentMonth: $currentMonthReading',
                              style: const TextStyle(
                                               fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
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
                              'Surname: ${documentSnapshot['lastName']}',
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

                            //     const Center(
                            //       child: Text(
                            //         'Electricity Meter Reading Photo',
                            //         style: TextStyle(
                            //             fontSize: 16, fontWeight: FontWeight.w700),
                            //       ),
                            //     ),
                            //     const SizedBox(
                            //       height: 5,
                            //     ),
                            // Column(
                            //   children: [
                            //     Row(
                            //       mainAxisAlignment: MainAxisAlignment.center,
                            //       crossAxisAlignment: CrossAxisAlignment.center,
                            //       children: [
                            //         Expanded(  // Wrap the button in Expanded to adjust its size
                            //           child: BasicIconButtonGrey(
                            //             onPress: () async {
                            //               eMeterNumber = documentSnapshot['meter_number'];
                            //               propPhoneNum = documentSnapshot['cellNumber'];
                            //               showDialog(
                            //                 barrierDismissible: false,
                            //                 context: context,
                            //                 builder: (context) {
                            //                   return AlertDialog(
                            //                     title: const Text("Upload Electricity Meter"),
                            //                     content: const Text(
                            //                         "Uploading a new image will replace current image!\n\nAre you sure?"
                            //                     ),
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
                            //                           Navigator.pop(context);
                            //                           Fluttertoast.showToast(
                            //                               msg: "Uploading a new image\nwill replace current image!"
                            //                           );
                            //                           Navigator.push(
                            //                             context,
                            //                             MaterialPageRoute(
                            //                                 builder: (context) => ImageUploadMeter(
                            //                                   userNumber: propPhoneNum,
                            //                                   meterNumber: eMeterNumber,
                            //                                 )
                            //                             ),
                            //                           );
                            //                         },
                            //                         icon: const Icon(
                            //                           Icons.done,
                            //                           color: Colors.green,
                            //                         ),
                            //                       ),
                            //                     ],
                            //                   );
                            //                 },
                            //               );
                            //             },
                            //             labelText: 'Electricity',
                            //             fSize: 15,
                            //             faIcon: const FaIcon(Icons.camera_alt),
                            //             fgColor: Colors.black38,
                            //             btSize: const Size(50, 38),
                            //           ),
                            //         ),
                            //         SizedBox(width: 10),  // Add some spacing between the buttons
                            //         Expanded(  // Also wrap this button in Expanded or Flexible
                            //           child: BasicIconButtonGrey(
                            //             onPress: () async {
                            //               _updateE(documentSnapshot);
                            //             },
                            //             labelText: 'Capture',
                            //             fSize: 15,
                            //             faIcon: const FaIcon(Icons.edit),
                            //             fgColor: Theme.of(context).primaryColor,
                            //             btSize: const Size(50, 38),
                            //           ),
                            //         ),
                            //       ],
                            //     ),
                            //   ],
                            // ),
                            // const SizedBox(height: 5),
                            //     FutureBuilder<String>(
                            //         future: fetchPropertyAddress(widget.districtId, widget.municipalityId,
                            //                 propPhoneNum, eMeterNumber)
                            //             .then((propertyAddress) => _getImage(
                            //                 context,
                            //                 'files/meters/$formattedMonth/${widget.property.cellNum}/${widget.property.address.replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_')}/electricity/${widget.property.meterNum}.jpg')),
                            //         builder: (context, snapshot) {
                            //           if (snapshot.hasData &&
                            //               snapshot.connectionState ==
                            //                   ConnectionState.done) {
                            //             return GestureDetector(
                            //               onTap: () {
                            //                 final imageProvider =
                            //                     NetworkImage(snapshot.data!);
                            //                 showImageViewer(context, imageProvider);
                            //               },
                            //               child: Container(
                            //                 margin:
                            //                     const EdgeInsets.only(bottom: 5),
                            //                 height: 180,
                            //                 child: Card(
                            //                   color: Colors.white54,
                            //                   semanticContainer: true,
                            //                   clipBehavior:
                            //                       Clip.antiAliasWithSaveLayer,
                            //                   shape: RoundedRectangleBorder(
                            //                     borderRadius:
                            //                         BorderRadius.circular(10.0),
                            //                   ),
                            //                   elevation: 0,
                            //                   margin: const EdgeInsets.all(10.0),
                            //                   child: Center(
                            //                     // Ensuring the image is centered within the card
                            //                     child: Image.network(snapshot.data!,
                            //                         fit: BoxFit.cover),
                            //                   ),
                            //                 ),
                            //               ),
                            //             );
                            //           } else if (snapshot.hasError) {
                            //             return const Padding(
                            //               padding: EdgeInsets.all(20.0),
                            //               child: Center(
                            //                 child: Column(
                            //                   mainAxisSize: MainAxisSize.min,
                            //                   children: [
                            //                     Text('Image not yet uploaded.'),
                            //                     SizedBox(height: 10),
                            //                     FaIcon(Icons.camera_alt),
                            //                   ],
                            //                 ),
                            //               ),
                            //             );
                            //           } else {
                            //             return Container(
                            //               height: 180,
                            //               margin: const EdgeInsets.all(10.0),
                            //               child: const Center(
                            //                   child: CircularProgressIndicator()),
                            //             );
                            //           }
                            //         }),

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
                            //     height: 180,
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
                            //                 context, 'files/meters/$formattedMonth/$propPhoneNum/electricity/$eMeterNumber.jpg'),
                            //             builder: (context, snapshot) {
                            //               if (snapshot.hasError) {
                            //
                            //                 imgUploadCheck = false;
                            //                 updateImgCheckE(imgUploadCheck,documentSnapshot);
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
                            const SizedBox(
                              height: 10,
                            ),
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
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        // Adding some space between the buttons
                                        child: ElevatedButton.icon(
                                          onPressed: DateTime.now().day >= 28
                                              ? null // Fully disables button functionality
                                              : () async {
                                            wMeterNumber =
                                            documentSnapshot['water_meter_number'];
                                            propPhoneNum =
                                            documentSnapshot['cellNumber'];
                                            showDialog(
                                              barrierDismissible: false,
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      "Upload Water Meter"),
                                                  content: const Text(
                                                      "Uploading a new image will replace the current image!\n\nAre you sure?"),
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
                                                          msg: "Uploading a new image\nwill replace current image!",
                                                        );

                                                        Navigator.pop(context);

                                                        // ✅ Wait for the ImageUploadWater screen to return a result
                                                        bool? uploadCompleted = await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => ImageUploadWater(
                                                              userNumber: propPhoneNum,
                                                              meterNumber: wMeterNumber,
                                                              propertyAddress: widget.propertyAddress,
                                                              districtId: widget.districtId ?? '',
                                                              municipalityId: widget.municipalityId,
                                                              isLocalMunicipality: widget.isLocalMunicipality,
                                                            ),
                                                          ),
                                                        );

                                                        // ✅ Only refresh the timestamp if the upload was successful
                                                        if (uploadCompleted == true) {
                                                          await _fetchLatestUploadTimestamp();
                                                          await _fetchLatestWaterMeterReading();

                                                        }
                                                      },
                                                      icon: const Icon(
                                                        Icons.done,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
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
                                    ),
                                    // BasicIconButtonGrey(
                                    //   onPress: () async {
                                    //     _updateW(documentSnapshot).then((_) {
                                    //       // After the meter reading update, navigate to the image upload page
                                    //       Navigator.push(
                                    //         context,
                                    //         MaterialPageRoute(
                                    //           builder: (context) => ImageUploadWater(
                                    //             userNumber: documentSnapshot['cellNumber'], // Pass the user's phone number
                                    //             meterNumber: documentSnapshot['water_meter_number'], // Pass the meter number
                                    //             propertyAddress: documentSnapshot['address'], // Pass the property address
                                    //             districtId: widget.districtId ?? '',// Pass the districtId
                                    //             municipalityId: widget.municipalityId, isLocalMunicipality: widget.isLocalMunicipality, // Pass the municipalityId
                                    //           ),
                                    //         ),
                                    //       );
                                    //     });
                                    //   },
                                    //   labelText: 'Capture',
                                    //   fSize: 15,
                                    //   faIcon: const FaIcon(
                                    //     Icons.edit,
                                    //   ),
                                    //   fgColor: Theme.of(context).primaryColor,
                                    //   btSize: const Size(100, 38),
                                    // ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                // FutureBuilder<String>(
                                //     future: fetchPropertyAddress(widget.districtId, widget.municipalityId, propPhoneNum, eMeterNumber)
                                //         .then((propertyAddress) => _getImageW(
                                //         context,
                                //         'files/meters/$formattedMonth/${widget.property.cellNum}/${widget.property.address.replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_')}/water/${widget.property.waterMeterNum}.jpg'
                                //     )),
                                //     builder: (context, snapshot) {
                                //       if (snapshot.connectionState == ConnectionState.waiting) {
                                //         return Container(
                                //           height: 180,
                                //           margin: const EdgeInsets.all(10.0),
                                //           child: const Center(child: CircularProgressIndicator()),
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
                                //       } else if (snapshot.hasData) {
                                //         return GestureDetector(
                                //           onTap: () {
                                //             final imageProvider = NetworkImage(snapshot.data!);
                                //             showImageViewer(context, imageProvider);
                                //           },
                                //           child: Container(
                                //             margin: const EdgeInsets.only(bottom: 5),
                                //             height: 180,
                                //             child: Card(
                                //               color: Colors.white54,
                                //               semanticContainer: true,
                                //               clipBehavior: Clip.antiAliasWithSaveLayer,
                                //               shape: RoundedRectangleBorder(
                                //                 borderRadius: BorderRadius.circular(10.0),
                                //               ),
                                //               elevation: 0,
                                //               margin: const EdgeInsets.all(10.0),
                                //               child: Center(
                                //                 child: Image.network(
                                //                   snapshot.data!,
                                //                   fit: BoxFit.cover,
                                //                 ),
                                //               ),
                                //             ),
                                //           ),
                                //         );
                                //       } else {
                                //         return const Padding(
                                //           padding: EdgeInsets.all(20.0),
                                //           child: Column(
                                //             mainAxisSize: MainAxisSize.min,
                                //             children: [
                                //               Text('No image available.'),
                                //               SizedBox(height: 10),
                                //               FaIcon(Icons.camera_alt),
                                //             ],
                                //           ),
                                //         );
                                //       }
                                //     }
                                // ),

                                InkWell(
                                  // onTap: () {
                                  //   wMeterNumber = documentSnapshot['water_meter_number']; // Correct meter number
                                  //   propPhoneNum = documentSnapshot['cellNumber']; // Correct phone number
                                  //   showDialog(
                                  //       barrierDismissible: false,
                                  //       context: context,
                                  //       builder: (context) {
                                  //         return AlertDialog(
                                  //           title: const Text("Upload Water Meter Image"),
                                  //           content: const Text(
                                  //               "Uploading a new image will replace current image!\n\nAre you sure?"
                                  //           ),
                                  //           actions: [
                                  //             IconButton(
                                  //               onPressed: () {
                                  //                 Navigator.pop(context);
                                  //               },
                                  //               icon: const Icon(
                                  //                 Icons.cancel,
                                  //                 color: Colors.red,
                                  //               ),
                                  //             ),
                                  //             IconButton(
                                  //               onPressed: () async {
                                  //                 Fluttertoast.showToast(
                                  //                     msg: "Uploading a new image\nwill replace current image!"
                                  //                 );
                                  //
                                  //                 // Navigate to ImageUploadWater, passing the correct phone number and meter number
                                  //                 Navigator.push(
                                  //                   context,
                                  //                   MaterialPageRoute(
                                  //                     builder: (context) => ImageUploadWater(
                                  //                       userNumber: propPhoneNum, // Pass correct user phone number
                                  //                       meterNumber: wMeterNumber, // Pass correct meter number
                                  //                       propertyAddress: widget.propertyAddress,
                                  //                       districtId: widget.districtId ?? '',
                                  //                       municipalityId: widget.municipalityId, isLocalMunicipality: widget.isLocalMunicipality,
                                  //                     ),
                                  //                   ),
                                  //                 ).then((_) {
                                  //                   // Once the image is uploaded, update the meter reading
                                  //                   _updateW(documentSnapshot);
                                  //                 });
                                  //               },
                                  //               icon: const Icon(
                                  //                 Icons.done,
                                  //                 color: Colors.green,
                                  //               ),
                                  //             ),
                                  //           ],
                                  //         );
                                  //       });
                                  // },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 5),
                                    height: 180,
                                    child: Center(
                                      child: Card(
                                        color: Colors.grey,
                                        semanticContainer: true,
                                        clipBehavior:
                                        Clip.antiAliasWithSaveLayer,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(10.0),
                                        ),
                                        elevation: 0,
                                        margin: const EdgeInsets.all(10.0),
                                        child: FutureBuilder<String?>(
                                            future: _getImageW(

                                              /// Firebase image location must be changed to display image based on the meter number
                                                context,
                                                'files/meters/$formattedMonth/${documentSnapshot['cellNumber']}/${documentSnapshot['address']}/water/${documentSnapshot['water_meter_number']}.jpg'),
                                            //$meterNumber
                                            builder: (context, snapshot) {
                                              if (snapshot.hasError) {
                                                imgUploadCheck = false;
                                                updateImgCheckW(imgUploadCheck,
                                                    documentSnapshot);

                                                return const Padding(
                                                  padding: EdgeInsets.all(20.0),
                                                  child: Column(
                                                    mainAxisSize:
                                                    MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'Image not yet uploaded.',
                                                      ),
                                                      SizedBox(
                                                        height: 10,
                                                      ),
                                                      FaIcon(Icons.camera_alt),
                                                    ],
                                                  ),
                                                );
                                              }
                                              if (snapshot.connectionState ==
                                                  ConnectionState.done) {
                                                imgUploadCheck = true;
                                                updateImgCheckW(imgUploadCheck,
                                                    documentSnapshot);

                                                if (snapshot.data != null) {
                                                  return Image.network(
                                                    snapshot
                                                        .data!,
                                                    // Assuming _getImageW returns a URL
                                                    fit: BoxFit.cover,
                                                  );
                                                } else {
                                                  return const Text(
                                                      'No image available.');
                                                }
                                              }
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const Padding(
                                                  padding: EdgeInsets.all(5.0),
                                                  child:
                                                  CircularProgressIndicator(),
                                                );
                                              }
                                              return Container();
                                            }),
                                      ),
                                    ),
                                  ),
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
                                    ),textAlign: TextAlign.center,
                                  ),
                                ),

                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  billMessage,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400),
                                ),

                                const SizedBox(
                                  height: 10,
                                ),
                                Column(
                                  children: [
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        addressForTrend =
                                        documentSnapshot['address'];

                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PropertyTrend(
                                                    addressTarget:
                                                    addressForTrend,
                                                    districtId: widget
                                                        .districtId ?? '',
                                                    municipalityId: widget
                                                        .municipalityId,
                                                    isLocalMunicipality: widget
                                                        .isLocalMunicipality,),
                                            ));
                                      },
                                      labelText: 'History',
                                      fSize: 16,
                                      faIcon: const FaIcon(
                                        Icons.stacked_line_chart,
                                      ),
                                      fgColor: Colors.purple,
                                      btSize: const Size(100, 38),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      children: [
                                        Stack(
                                          children: [
                                            BasicIconButtonGrey(
                                              onPress: () async {
                                                // Fluttertoast.showToast(
                                                //     msg:
                                                //     "Now opening your statement!\nPlease wait a few seconds!");
                                                //
                                                // _onSubmit(); // Handle any necessary updates
                                                // // Get the previous month instead of the current one
                                                // String previousMonth = DateFormat('MMMM').format(DateTime.now().subtract(Duration(days: 30)));
                                                //
                                                // // Ensure the address is trimmed and formatted consistently
                                                // String formattedAddress = widget.propertyAddress.trim(); // Trim any extra spaces
                                                //
                                                // // Print statements to debug the exact path being used
                                                // print('Attempting to list files in path: pdfs/$previousMonth/${widget.userNumber}/$formattedAddress/');
                                                //
                                                // // Reference the storage path based on the formatted address
                                                // final storageRef = FirebaseStorage.instance
                                                //     .ref()
                                                //     .child("pdfs/$previousMonth/${widget.userNumber}/$formattedAddress");
                                                //
                                                // try {
                                                //   final listResult = await storageRef.listAll();
                                                //
                                                //   // Log the number of files found
                                                //   print('Files found in directory: ${listResult.items.length}');
                                                //
                                                //   // If no files are found, inform the user
                                                //   if (listResult.items.isEmpty) {
                                                //     Fluttertoast.showToast(msg: "No files found in the directory.");
                                                //     return;
                                                //   }
                                                //
                                                //   bool found = false;
                                                //   String? webPdfUrl;
                                                //   File? mobilePdfFile;
                                                //
                                                //   for (var item in listResult.items) {
                                                //     if (item.name.contains(widget.accountNumber)) {
                                                //       print('Found matching file: ${item.name}');
                                                //
                                                //       // ✅ Get the download URL for web
                                                //       webPdfUrl = await item.getDownloadURL();
                                                //       print('Download URL: $webPdfUrl');
                                                //
                                                //       if (!kIsWeb) {
                                                //         // ✅ Mobile: Download the PDF locally
                                                //         final directory = await getApplicationDocumentsDirectory();
                                                //         final filePath = '${directory.path}/${item.name}';
                                                //         final response = await Dio().download(webPdfUrl, filePath);
                                                //
                                                //         if (response.statusCode == 200) {
                                                //           mobilePdfFile = File(filePath);
                                                //           Fluttertoast.showToast(msg: "Successful!");
                                                //         } else {
                                                //           Fluttertoast.showToast(msg: "Failed to download PDF.");
                                                //         }
                                                //       }
                                                //
                                                //       found = true;
                                                //       break;
                                                //     }
                                                //   }
                                                //
                                                //   if (!found) {
                                                //     Fluttertoast.showToast(msg: "No matching invoice found.");
                                                //     return;
                                                //   }
                                                //
                                                //   // ✅ Open PDF: Mobile (file) | Web (URL)
                                                //   openPDF(context, mobilePdfFile, webPdfUrl);
                                                // } catch (e) {
                                                //   print('Error opening PDF: $e');
                                                //   Fluttertoast.showToast(msg: "Unable to open statement.");
                                               // }
                                                _showRewardedAd();
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
                                                      const EdgeInsets.all(
                                                          2.0),
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
                                            accountNumber = documentSnapshot[
                                            'accountNumber'];
                                            locationGiven =
                                            documentSnapshot['address'];

                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        MapScreen(
                                                          isLocalMunicipality: documentSnapshot['isLocalMunicipality'],
                                                          // Pass isLocalMunicipality
                                                          districtId: documentSnapshot['districtId'] ??
                                                              '',
                                                          // Pass districtId
                                                          municipalityId: documentSnapshot['municipalityId'] ??
                                                              '',)
                                                  //MapPage()
                                                ));
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
                                  ],
                                ),

                                ///No need for a delete button but this is what a delete would look like
                                // GestureDetector(
                                //   onTap: () {
                                //     showDialog(
                                //         barrierDismissible: false,
                                //         context: context,
                                //         builder: (context) {
                                //           return AlertDialog(
                                //             title: const Text(
                                //                 "Deleting Property Information"),
                                //             content: const Text(
                                //                 "Deleting this property will remove it entirely! Are you sure?"),
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
                                //                   ScaffoldMessenger.of(
                                //                       this.context)
                                //                       .showSnackBar(
                                //                     const SnackBar(
                                //                       content: Text(
                                //                           'Property was deleted!'),
                                //                     ),
                                //                   );
                                //                   _delete(documentSnapshot.id);
                                //                   Navigator.pop(context);
                                //                 },
                                //                 icon: const Icon(
                                //                   Icons.done,
                                //                   color: Colors.green,
                                //                 ),
                                //               ),
                                //             ],
                                //           );
                                //         });
                                //  },
                                //   child: Row(
                                //     children: [
                                //       Icon(
                                //         Icons.delete,
                                //         color: Colors.red[700],
                                //       ),
                                //     ],
                                //   ),
                                // ),
                              ],
                            ),
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
              child: Center(
                child: Card(
                  margin: EdgeInsets.all(10),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'No properties registered on this number yet.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            );
            // return const Padding(
            //   padding: EdgeInsets.all(10.0),
            //   child: Center(
            //       child: CircularProgressIndicator()),
            // );
          },
        ),
      ),

      /// Add new account, removed because it was not necessary for non-staff users.
      //   floatingActionButton: FloatingActionButton(
      //     onPressed: () => _create(),
      //     child: const Icon(Icons.add),
      //   ),
      //   floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat
    );
  }

  Future<void> downloadPDF(String url, String fileName) async {
    try {
      // Get the application documents directory
      Directory dir = await getApplicationDocumentsDirectory();

      // Create a file path under that directory
      String filePath = '${dir.path}/$fileName';

      // Use Dio to download the file
      Dio dio = Dio();
      await dio.download(url, filePath);

      // Optionally, you can open the file here or just notify user of download completion
      print("Downloaded the file at $filePath");
      Fluttertoast.showToast(msg: "Download Successful!");
    } catch (e) {
      print("Error downloading the file: $e");
      Fluttertoast.showToast(msg: "Download failed: $e");
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

  //pdf view loader getting file name onPress/onTap that passes pdf filename to this class.
  void openPDF(BuildContext context, File? file, String? webUrl) {
    if (kIsWeb) {
      // ✅ Web: Open the PDF in a new browser tab
      if (webUrl != null && webUrl.isNotEmpty) {
        html.window.open(webUrl, "_blank");
      } else {
        Fluttertoast.showToast(msg: "Failed to open PDF: No URL available.");
      }
    } else {
      // ✅ Mobile: Open the PDF using a viewer
      if (file != null) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
        );
      } else {
        Fluttertoast.showToast(msg: "Failed to open PDF file.");
      }
    }
  }
}
