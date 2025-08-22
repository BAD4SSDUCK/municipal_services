import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as excel;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:municipal_services/code/ImageUploading/image_upload_meter.dart';
import 'package:municipal_services/code/ImageUploading/image_upload_water.dart';
import 'package:municipal_services/code/ImageUploading/image_zoom_page.dart';
import 'package:municipal_services/code/DisplayPages/display_property_trend.dart';
import 'package:municipal_services/code/MapTools/map_screen_prop.dart';
import 'package:municipal_services/code/PDFViewer/pdf_api.dart';
import 'package:municipal_services/code/PDFViewer/view_pdf.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';
import 'package:municipal_services/code/Reusable/push_notification_message.dart';
import 'package:municipal_services/code/NoticePages/notice_config_screen.dart';
import 'package:municipal_services/code/ReportGeneration/display_prop_report.dart';
import 'package:provider/provider.dart';
import '../MapTools/map_screen_multi.dart';
import '../Models/prop_provider.dart';
import '../Models/property.dart';

//Reading details from municipal side
class UsersPropsAll extends StatefulWidget {
  final String? municipalityUserEmail;
  final String? districtId;
  final String municipalityId;
  final bool isLocalMunicipality;
  final bool isLocalUser;

  const UsersPropsAll({
    super.key,
    this.municipalityUserEmail,
    this.districtId,
    required this.municipalityId,
    required this.isLocalMunicipality,
    required this.isLocalUser,
  });

  @override
  _UsersPropsAllState createState() => _UsersPropsAllState();
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
String eMeterNumber = '';
String accountNumberW = '';
String locationGivenW = '';
String wMeterNumber = '';
String addressForTrend = '';
String propPhoneNum = '';
String imageName = '';
String addressSnap = '';
String imageElectricName = '';
late String billMessage;

///A check for if payment is outstanding or not

bool visibilityState1 = true;
bool visibilityState2 = false;
bool adminAcc = false;
bool visAdmin = false;
bool visManager = false;
bool visEmployee = false;
bool visCapture = false;
bool visDev = false;
bool imgUploadCheck = false;

String currentMonth =
    DateFormat.MMMM().format(DateTime.now()); // Example: February
String previousMonth = DateFormat.MMMM()
    .format(DateTime.now().subtract(Duration(days: 30))); // Example: January
Map<String, String> previousMonthReadings =
    {}; // Store previous readings per address
Map<String, String> currentMonthReadings = {};
Map<String, String> previousMonthElectricReadings =
    {}; // Store previous readings per address
Map<String, String> currentMonthElectricReadings = {};
final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;

class FireStorageService extends ChangeNotifier {
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async {
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

// Future<Widget> _getImage(BuildContext context, String imageName) async {
//   Image image;
//   final value = await FireStorageService.loadImage(context, imageName);
//
//   final imageUrl = await storageRef.child(imageName).getDownloadURL();
//
//   // if (imageUrl.contains('.jpg')||imageUrl.contains('.JPG')){
//   //   imgUploadCheck = true;
//   // } else {
//   //   imgUploadCheck = false;
//   // }
//
//   ///Check what the app is running on
//   if (defaultTargetPlatform == TargetPlatform.android) {
//     image = Image.network(
//       value.toString(),
//       fit: BoxFit.fill,
//       width: double.infinity,
//       height: double.infinity,
//     );
//   } else {
//     // print('The url is::: $imageUrl');
//     image = Image.network(
//       imageUrl,
//       fit: BoxFit.fitHeight,
//       width: double.infinity,
//       height: double.infinity,
//     );
//   }
//
//   ///android version display image from firebase
//   // image =Image.network(
//   //   value.toString(),
//   //   fit: BoxFit.fill,
//   //   width: double.infinity,
//   //   height: double.infinity,
//   // );
//   return image;
// }
// Future<String> _getImage(BuildContext context, String imagePath) async {
//   try {
//     String imageUrl =
//     await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
//     return imageUrl; // Returns the image URL
//   } catch (e) {
//     throw Exception('Failed to load image');
//   }
// }
// Future<Widget> _getImageW(BuildContext context, String imageName2) async {
//   Image image2;
//   final value = await FireStorageService.loadImage(context, imageName2);
//
//   final imageUrl = await storageRef.child(imageName2).getDownloadURL();
//
//   // if (imageUrl.contains('.jpg')||imageUrl.contains('.JPG')){
//   //   imgUploadCheck = true;
//   // } else {
//   //   imgUploadCheck = false;
//   // }
//
//   ///Check what the app is running on
//   if (defaultTargetPlatform == TargetPlatform.android) {
//     image2 = Image.network(
//       value.toString(),
//       fit: BoxFit.fill,
//       width: double.infinity,
//       height: double.infinity,
//     );
//   } else {
//     // print('The url is::: $imageUrl');
//     image2 = Image.network(
//       imageUrl,
//       fit: BoxFit.fitHeight,
//       width: double.infinity,
//       height: double.infinity,
//     );
//   }
//   return image2;
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
//     FirebaseFirestore.instance.collection('properties');

class _UsersPropsAllState extends State<UsersPropsAll>
    with SingleTickerProviderStateMixin {
  //CollectionReference? _propList;
  Query<Map<String, dynamic>>? _propList;
  Property? property;
  String? userEmail;
  String districtId = '';
  String municipalityId = '';
  bool isLocalMunicipality = false;
  bool isLoading = false;
  bool isLocalUser = true;
  List<String> municipalities = []; // To hold the list of municipality names
  String? selectedMunicipality = "Select Municipality";
  List<DocumentSnapshot> filteredProperties = [];
  final ScrollController _scrollControllerTab1 = ScrollController();
  final ScrollController _scrollControllerTab2 = ScrollController();
  final FocusNode _focusNodeTab1 = FocusNode();
  final FocusNode _focusNodeTab2 = FocusNode();
  late TabController _tabController;
  List<String> utilityTypes = [];
  bool handlesWater = false;
  bool handlesElectricity = false;
  String? previousWaterReading;
  String? currentWaterReading;
  String? previousElectricityReading;
  String? currentElectricityReading;
  DateTime? latestWaterUploadTimestamp;
  DateTime? latestElectricityUploadTimestamp;
  Map<String, List<String>> municipalityUtilityMap = {};

  @override
  void initState() {
    super.initState();
    print("Initializing UsersPropsAllState...");
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (_tabController.index == 0) {
        _focusNodeTab1.requestFocus();
      } else if (_tabController.index == 1) {
        _focusNodeTab2.requestFocus();
      }
    });

    _focusNodeTab1.requestFocus();

    _scrollControllerTab1.addListener(() {
      print(
          "Tab 1 ScrollController position: ${_scrollControllerTab1.position.pixels}");
    });
    _scrollControllerTab2.addListener(() {
      print(
          "Tab 2 ScrollController position: ${_scrollControllerTab2.position.pixels}");
    });

    fetchAllPreviousMonthReadings().then((_) {
      if (mounted) setState(() {});
    });
    fetchAllPreviousMonthElectricityReadings().then((_) {
      if (mounted) setState(() {});
    });

    fetchUserDetails().then((_) {
      print("After fetchUserDetails:");
      print("districtId: $districtId");
      print("municipalityId: $municipalityId");
      print("isLocalMunicipality: $isLocalMunicipality");

      fetchMunicipalityUtilityTypes(); // ✅ now runs AFTER IDs are set

      if (isLocalUser) {
        fetchPropertiesForLocalMunicipality();
      } else {
        fetchMunicipalities();
      }
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    print("Disposing UsersPropsAllState...");
    _scrollControllerTab1.dispose();
    _scrollControllerTab2.dispose();
    _focusNodeTab1.dispose();
    _focusNodeTab2.dispose();
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    searchText;
    _allPropResults;
    _allPropReport;
    searchResultsList();
    super.dispose();
  }

  var _isLoading = false;

  _onSearchChanged() async {
    if (_searchController.text.isEmpty) {
      if (mounted) {
        // If search is cleared, fetch and display all properties again
        setState(() {
          searchText = ''; // Clear search text
        });
      }
      if (isLocalUser) {
        await fetchPropertiesForLocalMunicipality();
      } else {
        await fetchPropertiesForAllMunicipalities();
      }
    } else {
      // Perform search
      searchResultsList();
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
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

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
            print(
                "Error: municipalityId is empty for the local municipality user.");
          }
        } else {
          print('No user document found.');
        }
      } else {
        print("No current user found.");
      }
    } catch (e) {
      print('Error fetching user details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchMunicipalityUtilityTypes() async {
    if (isLocalMunicipality) {
      // 🔹 Local municipality: fetch single utility type
      final docRef = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId);

      final snapshot = await docRef.get();
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final utilityTypes = List<String>.from(data['utilityType'] ?? []);
        handlesWater = utilityTypes.contains('water');
        handlesElectricity = utilityTypes.contains('electricity');
      }
    } else {
      // 🔹 District municipality: fetch utility types for all child municipalities
      final querySnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .get();

      bool foundWater = false;
      bool foundElectricity = false;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('utilityType')) {
          final types = List<String>.from(data['utilityType']);
          if (types.contains('water')) foundWater = true;
          if (types.contains('electricity')) foundElectricity = true;
        }
      }

      handlesWater = foundWater;
      handlesElectricity = foundElectricity;
    }

    print("💧 [UsersPropsAll] handlesWater = $handlesWater");
    print("⚡ [UsersPropsAll] handlesElectricity = $handlesElectricity");

    if (mounted) setState(() {});
  }

  void _onSubmit() {
    setState(() => _isLoading = true);
    Future.delayed(
      const Duration(seconds: 5),
      () => setState(() => _isLoading = false),
    );
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
    if (isLocalMunicipality) {
      var data = await FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('users')
          .get();
      if (mounted) {
        setState(() {
          _allUserRolesResults = data.docs;
        });
      }
    } else {
      var data = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('users')
          .get();
      if (mounted) {
        setState(() {
          _allUserRolesResults = data.docs;
        });
      }
    }

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

        if (userRole == 'Admin' || userRole == 'Administrator') {
          visAdmin = true;
          visManager = false;
          visEmployee = false;
          visCapture = false;
        } else if (userRole == 'Manager') {
          visAdmin = false;
          visManager = true;
          visEmployee = false;
          visCapture = false;
        } else if (userRole == 'Employee') {
          visAdmin = false;
          visManager = false;
          visEmployee = true;
          visCapture = false;
        } else if (userRole == 'Capturer') {
          visAdmin = false;
          visManager = false;
          visEmployee = false;
          visCapture = true;
        }
        if (userDept == 'Developer') {
          visDev = true;
        }
      }
    }
  }

  Future<void> openPropertyInvoice(
      String userNumber,
      String propertyAddress,
      String accountNumber,
      String municipalityContext,
      BuildContext context) async {
    String formattedAddress = propertyAddress.replaceAll(
        ' ', '_'); // Make address Firebase-compatible
    String month = DateFormat('MMMM').format(DateTime.now());
    String path = 'pdfs/$month/$userNumber/$formattedAddress/';

    try {
      // Create a reference to the appropriate path based on municipality
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('municipalities/$municipalityContext/$path');

      final listResult = await storageRef.listAll();

      if (listResult.items.isNotEmpty) {
        var item;

        try {
          item = listResult.items.firstWhere(
            (element) => element.name.contains(accountNumber),
          );
        } catch (e) {
          item = null; // Handle the case where no matching item is found
        }

        if (item != null) {
          String url = await item.getDownloadURL();

          // Download the PDF locally
          final directory = await getApplicationDocumentsDirectory();
          final filePath = '${directory.path}/${item.name}';
          final response = await Dio().download(url, filePath);

          if (response.statusCode == 200) {
            File pdfFile = File(filePath);
            openPDF(context, pdfFile);
            Fluttertoast.showToast(msg: "Download Successful!");
          } else {
            Fluttertoast.showToast(msg: "Failed to download the PDF.");
          }
        } else {
          Fluttertoast.showToast(msg: "No matching document found.");
        }
      } else {
        Fluttertoast.showToast(msg: "No documents found for this account.");
      }
    } catch (e) {
      print("Error opening invoice: $e");
      Fluttertoast.showToast(msg: "Error opening invoice: $e");
    }
  }

  // text fields' controllers
  final _accountNumberController = TextEditingController();
  final _electricityAccountController=TextEditingController();
  final _addressController = TextEditingController();
  final _areaCodeController = TextEditingController();
  final _wardController = TextEditingController();
  final _meterNumberController = TextEditingController();
  final _meterReadingController = TextEditingController();
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
  //     FirebaseFirestore.instance.collection('Notifications');
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

  String userNameProp = '';
  String userAddress = '';
  String userWardProp = '';
  String userValid = '';
  String userPhoneProp = '';
  String userPhoneToken = '';
  String userPhoneNumber = '';
  String userRole = '';
  String userDept = '';
  List _allUserRolesResults = [];
  List _allUserTokenResults = [];
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
  List _allPropResults = [];
  List _allPropReport = [];

  // Future<void> getPropertyStream() async {
  //   if (_propList == null) {
  //     print("Error: _propList is null, skipping fetch.");
  //     return;
  //   }
  //
  //   try {
  //     var data = await _propList!.get();
  //     if (mounted) {
  //       setState(() {
  //         _allPropResults = data.docs;
  //         _allPropReport = data.docs;
  //       });
  //     }
  //   } catch (e) {
  //     print("Error fetching properties: $e");
  //   }
  //   searchResultsList();
  // }

  getUsersTokenStream() async {
    if (isLocalMunicipality) {
      var data = await FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('UserToken')
          .get();
      if (mounted) {
        setState(() {
          _allUserTokenResults = data.docs;
        });
      }
    } else {
      var data = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('UserToken')
          .get();
      if (mounted) {
        setState(() {
          _allUserTokenResults = data.docs;
        });
      }
    }

    searchResultsList();
  }

  searchResultsList() async {
    var showResults = [];
    if (_searchController.text.isNotEmpty) {
      var searchLower = _searchController.text.toLowerCase();

      // Perform the search by filtering _allPropResults
      for (var propSnapshot in _allPropResults) {
        var address = propSnapshot['address'].toString().toLowerCase();
        var firstName = propSnapshot['firstName'].toString().toLowerCase();
        var lastName = propSnapshot['lastName'].toString().toLowerCase();
        var fullName = '$firstName $lastName';
        var cellNumber = propSnapshot['cellNumber'].toString().toLowerCase();
        var accountNumber = propSnapshot
                .data()
                .toString()
                .contains('electricityAccountNumber')
            ? propSnapshot['electricityAccountNumber'].toString().toLowerCase()
            : propSnapshot['accountNumber'].toString().toLowerCase();

        if (address.contains(searchLower) ||
            fullName.contains(
                searchLower) || // Search full name instead of first and last separately
            cellNumber.contains(searchLower) ||
            accountNumber.contains(searchLower)) {
          showResults.add(propSnapshot);
        }
      }
      if (mounted) {
        setState(() {
          _allPropResults = showResults; // Update state with filtered results
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
            municipalities = [];
            municipalityUtilityMap.clear();

            for (var doc in municipalitiesSnapshot.docs) {
              final municipalityId = doc.id;
              final data = doc.data();

              municipalities.add(municipalityId);

              // Extract utilityType if available
              if (data.containsKey('utilityType')) {
                final List<String> utilityTypes =
                    List<String>.from(data['utilityType']);
                municipalityUtilityMap[municipalityId] = utilityTypes;
                print("✅ $municipalityId utilityTypes: $utilityTypes");
              } else {
                municipalityUtilityMap[municipalityId] = [];
                print("⚠️ $municipalityId has no utilityType field.");
              }
            }

            print("Municipality list: $municipalities");
            print("Utility map: $municipalityUtilityMap");

            // Set dropdown default
            selectedMunicipality = "Select Municipality";

            // Fetch all properties for district-wide view
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
      print('❌ Error fetching municipalities: $e');
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
          _allPropResults =
              propertiesSnapshot.docs; // Store all fetched properties
          print('State updated, properties stored: ${_allPropResults.length}');
        });
      }
      print('Properties fetched: ${_allPropResults.length}');
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
  //     String propertyAddress,
  //     String municipalityUserEmail,
  //     String districtId,
  //     String municipalityId,
  //     Map<String, dynamic> details) async {
  //
  //   print('logEMeterReadingUpdate called');  // Add this to check if the method is invoked
  //
  //
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
  //   DocumentReference actionLogDocRef = FirebaseFirestore.instance
  //       .collection('districts')
  //       .doc(districtId)
  //       .collection('municipalities')
  //       .doc(municipalityId)
  //       .collection('actionLogs')
  //       .doc(cellNumber)
  //       .collection(propertyAddress)
  //       .doc('actions');  // Auto-generate document ID for the action
  //
  //   try {
  //     await actionLogDocRef.set({
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

  Future<void> fetchAllPreviousMonthReadings() async {
    try {
      int currentYear = DateTime.now().year;
      int previousYear = currentYear - 1;

      String currentMonth =
          DateFormat.MMMM().format(DateTime.now()); // Example: March
      String prevMonth = DateFormat.MMMM().format(DateTime.now()
          .subtract(const Duration(days: 30))); // Example: February

      String prevMonthYear = (currentMonth == "January")
          ? previousYear.toString()
          : currentYear.toString();
      String currentMonthYear = currentYear
          .toString(); // Always use the current year for current readings

      previousMonthReadings.clear(); // Clear previous data
      currentMonthReadings.clear(); // Clear current month data

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
            previousMonthReadings[data['address']] =
                data['water_meter_reading'] ?? "N/A";
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
            currentMonthReadings[data['address']] =
                data['water_meter_reading'] ?? "N/A";
          }
        }
      } else {
        // ✅ District Municipality: Fetch readings for ALL municipalities under the district
        CollectionReference municipalitiesCollection = FirebaseFirestore
            .instance
            .collection('districts')
            .doc(widget.districtId)
            .collection('municipalities');

        QuerySnapshot municipalitiesSnapshot =
            await municipalitiesCollection.get();

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
              previousMonthReadings[data['address']] =
                  data['water_meter_reading'] ?? "N/A";
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
              currentMonthReadings[data['address']] =
                  data['water_meter_reading'] ?? "N/A";
            }
          }
        }
      }

      if (mounted) {
        setState(() {}); // Refresh UI
      }

      print(
          "✅ Fetch complete: Previous Month ($prevMonthYear/$prevMonth), Current Month ($currentMonthYear/$currentMonth)");
    } catch (e) {
      print("❌ Error fetching previous and current month readings: $e");
    }
  }

  Future<void> fetchAllPreviousMonthElectricityReadings() async {
    try {
      int currentYear = DateTime.now().year;
      int previousYear = currentYear - 1;

      String currentMonth =
          DateFormat.MMMM().format(DateTime.now()); // Example: March
      String prevMonth = DateFormat.MMMM().format(DateTime.now()
          .subtract(const Duration(days: 30))); // Example: February

      String prevMonthYear = (currentMonth == "January")
          ? previousYear.toString()
          : currentYear.toString();
      String currentMonthYear = currentYear
          .toString(); // Always use the current year for current readings

      previousMonthElectricReadings.clear(); // Clear previous data
      currentMonthElectricReadings.clear(); // Clear current month data

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
            previousMonthElectricReadings[data['address']] =
                data['meter_reading'] ?? "N/A";
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
            currentMonthElectricReadings[data['address']] =
                data['meter_reading'] ?? "N/A";
          }
        }
      } else {
        // ✅ District Municipality: Fetch readings for ALL municipalities under the district
        CollectionReference municipalitiesCollection = FirebaseFirestore
            .instance
            .collection('districts')
            .doc(widget.districtId)
            .collection('municipalities');

        QuerySnapshot municipalitiesSnapshot =
            await municipalitiesCollection.get();

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
              previousMonthElectricReadings[data['address']] =
                  data['meter_reading'] ?? "N/A";
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
              currentMonthElectricReadings[data['address']] =
                  data['meter_reading'] ?? "N/A";
            }
          }
        }
      }

      if (mounted) {
        setState(() {}); // Refresh UI
      }

      print(
          "✅ Fetch complete: Previous Month ($prevMonthYear/$prevMonth), Current Month ($currentMonthYear/$currentMonth)");
    } catch (e) {
      print("❌ Error fetching previous and current month readings: $e");
    }
  }

  // Future<void> handleImageUpload(BuildContext context, String userNumber, String meterNumber) async {
  //   showDialog(
  //       barrierDismissible: false,
  //       context: context,
  //       builder: (context) {
  //         return AlertDialog(
  //           title: const Text("Upload Electricity Meter"),
  //           content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
  //           actions: [
  //             IconButton(
  //               onPressed: () => Navigator.pop(context),
  //               icon: const Icon(Icons.cancel, color: Colors.red),
  //             ),
  //             IconButton(
  //               onPressed: () async {
  //                 Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
  //                 Navigator.pop(context);
  //                 Navigator.push(context, MaterialPageRoute(builder: (context) => ImageUploadMeter(userNumber:propPhoneNum, meterNumber: meterNumber,municipalityUserEmail: userEmail,  )));
  //               },
  //               icon: const Icon(Icons.done, color: Colors.green),
  //             ),
  //           ],
  //         );
  //       }
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[350],
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(180.0),
          child: AppBar(
            title: const Padding(
              padding: EdgeInsets.only(top: 20), // Add padding to title
              child: Text(
                'Registered Accounts',
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
                              icon: const Icon(Icons.map, color: Colors.white),
                              onPressed: () {
                                // if (!isLocalUser && !isLocalMunicipality) {
                                //   if (selectedMunicipality == null || selectedMunicipality == "Select Municipality") {
                                //     Fluttertoast.showToast(
                                //       msg: "Please select a municipality first!",
                                //       toastLength: Toast.LENGTH_SHORT,
                                //       gravity: ToastGravity.CENTER,
                                //     );
                                //     return; // Stop execution if no municipality is selected
                                //   }
                                // }
                                //
                                // // Determine the appropriate municipality context
                                // String municipalityContext = isLocalMunicipality || isLocalUser
                                //     ? municipalityId
                                //     : selectedMunicipality!;
                                //
                                // if (municipalityContext.isEmpty) {
                                //   Fluttertoast.showToast(
                                //     msg: "Invalid municipality selection or missing municipality.",
                                //     toastLength: Toast.LENGTH_SHORT,
                                //     gravity: ToastGravity.CENTER,
                                //   );
                                //   return;
                                // }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MapScreenMulti(),
                                  ),
                                );
                              },
                            ),
                            const Text(
                              'Map',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                                fontSize: 15,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
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
                            const Text(
                              'Reports',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                                fontSize: 15,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Only show the dropdown if the user is not part of a local municipality and is not a local user
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
                                  if (_tabController.index == 0) {
                                    _focusNodeTab1.requestFocus();
                                  } else if (_tabController.index == 1) {
                                    _focusNodeTab2.requestFocus();
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
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: const [
                        Tab(
                          child: Text(
                            'All\nProperties',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Tab(
                          child: Text(
                            'Outstanding\nCaptures',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                  child: SearchBar(
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
                ),
                Expanded(child: propertyCard()),
                const SizedBox(height: 5),
              ],
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                  child: SearchBar(
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
                ),
                Expanded(child: noCapPropertyCard()),
                const SizedBox(height: 5),
              ],
            ),
          ],
        ),
        floatingActionButton: Visibility(
          visible: visDev,
          child: FloatingActionButton(
            onPressed: () => _create(),
            backgroundColor: Colors.green,
            child: const Icon(Icons.add_home, color: Colors.white),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      ),
    );
  }

  Widget propertyCard() {
    if (isLoading) {
      // Display a loading spinner while fetching data
      return const Center(child: CircularProgressIndicator());
    }
    print("Rendering ${_allPropResults.length} properties");
    return GestureDetector(
      onTap: () {
        // Refocus when tapping within the tab content
        _focusNodeTab1.requestFocus();
      },
      child: KeyboardListener(
        focusNode: _focusNodeTab1,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            final double pageScrollAmount =
                _scrollControllerTab1.position.viewportDimension;

            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _scrollControllerTab1.animateTo(
                _scrollControllerTab1.offset + 50,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeIn,
              );
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _scrollControllerTab1.animateTo(
                _scrollControllerTab1.offset - 50,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeIn,
              );
            } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
              _scrollControllerTab1.animateTo(
                _scrollControllerTab1.offset + pageScrollAmount,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeIn,
              );
            } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
              _scrollControllerTab1.animateTo(
                _scrollControllerTab1.offset - pageScrollAmount,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeIn,
              );
            }
          }
        },
        child: Scrollbar(
          controller: _scrollControllerTab1,
          thickness: 12, // Customize the thickness of the scrollbar
          radius: const Radius.circular(8), // Rounded edges for the scrollbar
          thumbVisibility: true,
          trackVisibility: true, // Makes the track visible as well
          interactive: true,
          child: ListView.builder(
            controller: _scrollControllerTab1,
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _allPropResults.length,
            itemBuilder: (context, index) {
              final munId = _allPropResults[index]['municipalityId'];
              final utilTypes = municipalityUtilityMap[munId] ?? [];

              final bool showWater = utilTypes.contains('water');
              final bool showElectricity = utilTypes.contains('electricity');

              print(
                  "🏙️ $munId | 💧 water: $showWater | ⚡ electricity: $showElectricity");

              if (_allPropResults[index]['eBill'] != '' ||
                  _allPropResults[index]['eBill'] != 'R0,000.00' ||
                  _allPropResults[index]['eBill'] != 'R0.00' ||
                  _allPropResults[index]['eBill'] != 'R0' ||
                  _allPropResults[index]['eBill'] != '0') {
                billMessage =
                    'Utilities bill outstanding: ${_allPropResults[index]['eBill']}';
              } else {
                billMessage = 'No outstanding payments';
              }
              return Card(
                  margin: const EdgeInsets.only(
                      left: 10, right: 10, top: 0, bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Street Address: ${_allPropResults[index]['address']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5),
                        if (showWater) ...[
                          Text(
                            'Water Account Number: ${_allPropResults[index]['accountNumber']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                        ],
                        const SizedBox(height: 5),
                        if (showElectricity) ...[
                          Text(
                            'Electricity Account Number: ${_allPropResults[index]['electricityAccountNumber']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                        ],
                        const SizedBox(height: 5),
                        Text(
                          'Area Code: ${_allPropResults[index]['areaCode']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5),
                        if (showWater) ...[
                          const SizedBox(height: 5),
                          Text(
                            'Water Meter Number: ${_allPropResults[index]['water_meter_number']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Previous Month ($previousMonth) Water Reading: ${previousMonthReadings[_allPropResults[index]['address']] ?? "N/A"}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Current Month Water Reading for $currentMonth: ${currentMonthReadings[_allPropResults[index]['address']] ?? "N/A"}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                        ],
                        if (showElectricity) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Electricity Meter Number: ${_allPropResults[index]['meter_number'] ?? "N/A"}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Previous Month ($previousMonth) Electricity Reading: ${previousMonthElectricReadings[_allPropResults[index]['address']] ?? "N/A"}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Current Month Electricity Reading for $currentMonth: ${currentMonthElectricReadings[_allPropResults[index]['address']] ?? "N/A"}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                        ],
                        const SizedBox(height: 5),
                        Text(
                          'Phone Number: ${_allPropResults[index]['cellNumber']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          'First Name: ${_allPropResults[index]['firstName']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          'Surname: ${_allPropResults[index]['lastName']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          'ID Number: ${_allPropResults[index]['idNumber']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          billMessage,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        const Center(
                          child: Text(
                            'Meter Photo',
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
                                    _allPropResults[index]['cellNumber'];
                                String? address =
                                    _allPropResults[index]['address'];
                                String? meterNumber = _allPropResults[index]
                                    ['water_meter_number'];
                                String? eMeterNumber =
                                    _allPropResults[index]['meter_number'];
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

                                // Prepare the image path
                                imageName =
                                    'files/meters/$formattedDate/$cellNumber/$address/water/$meterNumber.jpg';
                                addressSnap = address;
                                imageElectricName =
                                    'files/meters/$formattedDate/$cellNumber/$address/electricity/$eMeterNumber.jpg';
                                // Log the details for debugging
                                print(
                                    "Navigating to ImageZoomPage with details:");
                                print("imageName: $imageName");
                                print("addressSnap: $addressSnap");
                                print(
                                    "municipalityContext: $municipalityContext");
                                print("municipality email: $userEmail");
                                // Navigate to the ImageZoomPage
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ImageZoomPage(
                                      imageName: imageName,
                                      imageElectricName: imageElectricName,
                                      addressSnap: addressSnap,
                                      municipalityUserEmail: userEmail,
                                      isLocalMunicipality: isLocalMunicipality,
                                      districtId: districtId,
                                      municipalityId: municipalityContext,
                                      isLocalUser: isLocalUser,
                                    ),
                                  ),
                                );
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
                            labelText: 'View Uploaded Image',
                            fSize: 16,
                            faIcon: const FaIcon(Icons.zoom_in),
                            fgColor: Colors.blue,
                            btSize: const Size(100, 38),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Center(
                          child: BasicIconButtonGrey(
                            onPress: () async {
                              try {
                                // Skip municipality selection if user is from a local municipality or assigned to a single district municipality
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

                                // Ensure property details are available
                                String? address =
                                    _allPropResults[index]['address'];
                                String? accountNumber =
                                    _allPropResults[index]['accountNumber'];
                                String? cellNumber =
                                    _allPropResults[index]['cellNumber'];

                                if (address == null ||
                                    accountNumber == null ||
                                    cellNumber == null) {
                                  Fluttertoast.showToast(
                                    msg:
                                        "Error: Property information is missing.",
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.CENTER,
                                  );
                                  return;
                                }
                                String selectedMunicipalityId =
                                    isLocalMunicipality || isLocalUser
                                        ? municipalityId
                                        : selectedMunicipality!;

                                // 🔍 Fetch utility type for the selected municipality
                                DocumentReference docRef = isLocalMunicipality
                                    ? FirebaseFirestore.instance
                                        .collection('localMunicipalities')
                                        .doc(selectedMunicipalityId)
                                    : FirebaseFirestore.instance
                                        .collection('districts')
                                        .doc(districtId)
                                        .collection('municipalities')
                                        .doc(selectedMunicipalityId);

                                DocumentSnapshot snapshot = await docRef.get();
                                List<String> utilityTypes = List<String>.from(
                                    snapshot['utilityType'] ?? []);
                                bool localHandlesWater =
                                    utilityTypes.contains("water");
                                bool localHandlesElectricity =
                                    utilityTypes.contains("electricity");
                                // Perform desired action based on button type
                                print(
                                    "Navigating to PropertyTrend with details:");
                                print("Address: $address");
                                print("District ID: $districtId");
                                print(
                                    "Municipality Context: $municipalityContext");
                                print(
                                    "💧 Water = $localHandlesWater | ⚡ Electricity = $localHandlesElectricity");

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PropertyTrend(
                                      addressTarget: address,
                                      districtId: districtId,
                                      municipalityId: municipalityContext,
                                      isLocalMunicipality: isLocalMunicipality,
                                      isLocalUser: isLocalUser,
                                      handlesWater: localHandlesWater,
                                      handlesElectricity:
                                          localHandlesElectricity,
                                    ),
                                  ),
                                );
                              } catch (e) {
                                print("Error in 'History' button: $e");
                                Fluttertoast.showToast(
                                  msg:
                                      "Error: Unable to open property history.",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.CENTER,
                                );
                              }
                            },
                            labelText: 'History',
                            fSize: 16,
                            faIcon: const FaIcon(Icons.stacked_line_chart),
                            fgColor: Colors.purple,
                            btSize: const Size(100, 38),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Stack(
                              children: [
                                /*BasicIconButtonGrey(
                                    onPress: () async {
                                      try {
                                        // Ensure the municipality context is valid for non-local users
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
                                        // Ensure property details are available
                                        String? address = _allPropResults[index]['address'];
                                        String? accountNumber = _allPropResults[index]['accountNumber'];
                                        String? cellNumber = _allPropResults[index]['cellNumber'];

                                        if (address == null || accountNumber == null || cellNumber == null) {
                                          Fluttertoast.showToast(
                                            msg: "Error: Property information is missing.",
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.CENTER,
                                          );
                                          return;
                                        }

                                        // Prepare the path
                                        String month = DateFormat('MMMM').format(DateTime.now());
                                        String path = 'pdfs/$month/$cellNumber/$address/';
                                        print("Constructed path: $path");

                                        final storageRef = FirebaseStorage.instance.ref().child(path);
                                        final listResult = await storageRef.listAll();

                                        if (listResult.items.isNotEmpty) {
                                          Reference? matchingFile;

                                          try {
                                            matchingFile = listResult.items.firstWhere(
                                                  (item) => item.name.contains(accountNumber),
                                            );
                                          } catch (e) {
                                            matchingFile = null;
                                          }

                                          if (matchingFile != null) {
                                            final url = await matchingFile.getDownloadURL();
                                            print('Found file URL: $url');

                                            final directory = await getApplicationDocumentsDirectory();
                                            final filePath = '${directory.path}/${matchingFile.name}';

                                            try {
                                              // Download using Dio
                                              final response = await Dio().download(url, filePath);
                                              if (response.statusCode == 200) {
                                                File pdfFile = File(filePath);
                                                if (context.mounted) {
                                                  openPDF(context, pdfFile);
                                                  Fluttertoast.showToast(msg: "Download Successful!");
                                                }
                                              } else {
                                                print("Failed to download the PDF. Status code: ${response.statusCode}");
                                                Fluttertoast.showToast(msg: "Failed to download the statement.");
                                              }
                                            } catch (e) {
                                              print("Error during download: $e");
                                              Fluttertoast.showToast(msg: "Unable to download statement.");
                                            }
                                          } else {
                                            print('No matching file found for account number: $accountNumber');
                                            Fluttertoast.showToast(
                                              msg: "Statement not found for this account.",
                                              toastLength: Toast.LENGTH_SHORT,
                                              gravity: ToastGravity.CENTER,
                                            );
                                          }
                                        } else {
                                          print('No files found at path: ${storageRef.fullPath}');
                                          Fluttertoast.showToast(
                                            msg: "No statements available for this account.",
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.CENTER,
                                          );
                                        }
                                      } catch (e) {
                                        print("Error in button logic: $e");
                                        Fluttertoast.showToast(msg: "Error: Unable to download statement.");
                                      }
                                    },
                                    labelText: 'Invoice',
                                    fSize: 16,
                                    faIcon: const FaIcon(
                                      Icons.picture_as_pdf,
                                    ),
                                    fgColor: Colors.orangeAccent,
                                    btSize: const Size(100, 38),
                                  ),*/
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
                                          padding: const EdgeInsets.all(2.0),
                                          child:
                                              const CircularProgressIndicator(
                                            color: Colors.purple,
                                            strokeWidth: 3,
                                          ),
                                        ),
                                      ],
                                    )),
                              ],
                            ),
                            BasicIconButtonGrey(
                              onPress: () async {
                                try {
                                  // Ensure the municipality context is valid for district users
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
                                  // Ensure property details are available
                                  String? address =
                                      _allPropResults[index]['address'];
                                  String? accountNumber =
                                      _allPropResults[index]['accountNumber'];

                                  if (address == null ||
                                      accountNumber == null) {
                                    Fluttertoast.showToast(
                                      msg:
                                          "Error: Property information is missing.",
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.CENTER,
                                    );
                                    return;
                                  }

                                  // Log details for debugging
                                  print("Navigating to MapScreenProp with:");
                                  print("Address: $address");
                                  print("Account Number: $accountNumber");
                                  print(
                                      "Municipality Context: $municipalityContext");

                                  // Navigate to the MapScreenProp with property details
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MapScreenProp(
                                        propAddress: address,
                                        propAccNumber: accountNumber,
                                      ),
                                    ),
                                  );
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
                      ],
                    ),
                  ));
            },
          ),
        ),
      ),
    );
  }

  // Widget propertyCard() {
  //   // Check if _propList has been initialized and properties are loaded
  //   if (_propList == null) {
  //     return const Center(child: CircularProgressIndicator()); // Show loader
  //   }
  //
  //   // Check if there are properties in _allPropResults
  //   if (_allPropResults.isEmpty) {
  //     return const Center(child: Text("No properties found.")); // Show message if no properties
  //   }
  //
  //   // Debugging print to confirm properties are being fetched
  //   print("Rendering ${_allPropResults.length} properties");
  //     return ListView.builder(
  //       ///this call is to display all details for all users but is only displaying for the current user account.
  //       ///it can be changed to display all users for the staff to see if the role is set to all later on.
  //       itemCount: _allPropResults.length,
  //       itemBuilder: (context, index) {
  //         property = Property(
  //           accountNo: _allPropResults[index]['accountNumber'],
  //           address: _allPropResults[index]['address'],
  //           areaCode: _allPropResults[index]['areaCode'],
  //           cellNum: _allPropResults[index]['cellNumber'],
  //           eBill: _allPropResults[index]['eBill'],
  //           firstName: _allPropResults[index]['firstName'],
  //           lastName: _allPropResults[index]['lastName'],
  //           id: _allPropResults[index]['idNumber'],
  //           // imgStateE: _allPropResults[index]['imgStateE'],
  //           imgStateW: _allPropResults[index]['imgStateW'],
  //           // meterNum: _allPropResults[index]['meter_number'],
  //           // meterReading: _allPropResults[index]['meter_reading'],
  //           waterMeterNum: _allPropResults[index]['water_meter_number'],
  //           waterMeterReading: _allPropResults[index]['water_meter_reading'],
  //           uid: _allPropResults[index]['userID'],
  //           districtId: districtId,
  //           municipalityId: municipalityId,
  //           isLocalMunicipality: _allPropResults[index]['isLocalMunicipality'],
  //         );
  //
  //         // eMeterNumber = _allPropResults[index]['meter_number'];
  //         wMeterNumber = _allPropResults[index]['water_meter_number'];
  //         propPhoneNum = _allPropResults[index]['cellNumber'];
  //
  //         if (_allPropResults[index]['eBill'] != '' ||
  //             _allPropResults[index]['eBill'] != 'R0,000.00' ||
  //             _allPropResults[index]['eBill'] != 'R0.00' ||
  //             _allPropResults[index]['eBill'] != 'R0' ||
  //             _allPropResults[index]['eBill'] != '0') {
  //           billMessage =
  //               'Utilities bill outstanding: ${_allPropResults[index]['eBill']}';
  //         } else {
  //           billMessage = 'No outstanding payments';
  //         }
  //
  //         return Card(
  //           margin:
  //               const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 10),
  //           child: Padding(
  //             padding: const EdgeInsets.all(20.0),
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 const Center(
  //                   child: Text(
  //                     'Property Information',
  //                     style:
  //                         TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  //                   ),
  //                 ),
  //                 const SizedBox(
  //                   height: 10,
  //                 ),
  //                 Text(
  //                   'Account Number: ${_allPropResults[index]['accountNumber']}',
  //                   style: const TextStyle(
  //                       fontSize: 16, fontWeight: FontWeight.w400),
  //                 ),
  //                 const SizedBox(
  //                   height: 5,
  //                 ),
  //                 Text(
  //                   'Street Address: ${_allPropResults[index]['address']}',
  //                   style: const TextStyle(
  //                       fontSize: 16, fontWeight: FontWeight.w400),
  //                 ),
  //                 const SizedBox(
  //                   height: 5,
  //                 ),
  //                 Text(
  //                   'Area Code: ${_allPropResults[index]['areaCode']}',
  //                   style: const TextStyle(
  //                       fontSize: 16, fontWeight: FontWeight.w400),
  //                 ),
  //                 const SizedBox(
  //                   height: 5,
  //                 ),
  //                 // Text(
  //                 //   'Meter Number: ${_allPropResults[index]['meter_number']}',
  //                 //   style: const TextStyle(
  //                 //       fontSize: 16, fontWeight: FontWeight.w400),
  //                 // ),
  //                 // const SizedBox(
  //                 //   height: 5,
  //                 // ),
  //                 // Text(
  //                 //   'Meter Reading: ${_allPropResults[index]['meter_reading']}',
  //                 //   style: const TextStyle(
  //                 //       fontSize: 16, fontWeight: FontWeight.w400),
  //                 // ),
  //                 // const SizedBox(
  //                 //   height: 5,
  //                 // ),
  //                 Text(
  //                   'Water Meter Number: ${_allPropResults[index]['water_meter_number']}',
  //                   style: const TextStyle(
  //                       fontSize: 16, fontWeight: FontWeight.w400),
  //                 ),
  //                 const SizedBox(
  //                   height: 5,
  //                 ),
  //                 Text(
  //                   'Water Meter Reading: ${_allPropResults[index]['water_meter_reading']}',
  //                   style: const TextStyle(
  //                       fontSize: 16, fontWeight: FontWeight.w400),
  //                 ),
  //                 const SizedBox(
  //                   height: 5,
  //                 ),
  //                 Text(
  //                   'Phone Number: ${_allPropResults[index]['cellNumber']}',
  //                   style: const TextStyle(
  //                       fontSize: 16, fontWeight: FontWeight.w400),
  //                 ),
  //                 const SizedBox(
  //                   height: 5,
  //                 ),
  //                 Text(
  //                   'First Name: ${_allPropResults[index]['firstName']}',
  //                   style: const TextStyle(
  //                       fontSize: 16, fontWeight: FontWeight.w400),
  //                 ),
  //                 const SizedBox(
  //                   height: 5,
  //                 ),
  //                 Text(
  //                   'Surname: ${_allPropResults[index]['lastName']}',
  //                   style: const TextStyle(
  //                       fontSize: 16, fontWeight: FontWeight.w400),
  //                 ),
  //                 const SizedBox(
  //                   height: 5,
  //                 ),
  //                 Text(
  //                   'ID Number: ${_allPropResults[index]['idNumber']}',
  //                   style: const TextStyle(
  //                       fontSize: 16, fontWeight: FontWeight.w400),
  //                 ),
  //                 const SizedBox(
  //                   height: 20,
  //                 ),
  //
  //                 const Center(
  //                   child: Text(
  //                     'Water Meter Photo',
  //                     style:
  //                         TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  //                   ),
  //                 ),
  //                 const SizedBox(
  //                   height: 5,
  //                 ),
  //                 Center(
  //                   child: BasicIconButtonGrey(
  //                     onPress: () async {
  //                       String address = _allPropResults[index]['address'];
  //                       imageName =
  //                           'files/meters/$formattedDate/${_allPropResults[index]['cellNumber']}/water/${_allPropResults[index]['water_meter_number']}.jpg';
  //                       addressSnap =
  //                           address; // Correct the address to pass to ImageZoomPage
  //                       Provider.of<PropertyProvider>(context, listen: false)
  //                           .selectProperty(property!);
  //                       Navigator.push(
  //                           context,
  //                           MaterialPageRoute(
  //                               builder: (context) => ImageZoomPage(
  //                                     imageName: imageName,
  //                                     addressSnap: addressSnap,
  //                                     municipalityUserEmail: widget.municipalityUserEmail,
  //                                     isLocalMunicipality: isLocalMunicipality,
  //                                     districtId: districtId,
  //                                     municipalityId: municipalityId,
  //                                   )));
  //                       print('ImageZoomPage received municipalityUserEmail: ${widget.municipalityUserEmail}');
  //
  //                     },
  //                     labelText: 'View Uploaded Image',
  //                     fSize: 16,
  //                     faIcon: const FaIcon(
  //                       Icons.zoom_in,
  //                     ),
  //                     fgColor: Colors.blue,
  //                     btSize: const Size(100, 38),
  //                   ),
  //                 ),
  //                 // Column(
  //                 //   children: [
  //                 //     Row(
  //                 //       mainAxisAlignment: MainAxisAlignment.center,
  //                 //       crossAxisAlignment: CrossAxisAlignment.center,
  //                 //       children: [
  //                 //         BasicIconButtonGrey(
  //                 //           onPress: () async {
  //                 //             eMeterNumber = _allPropertyResults[index]['meter number'];
  //                 //             propPhoneNum = _allPropertyResults[index]['cell number'];
  //                 //             showDialog(
  //                 //                 barrierDismissible: false,
  //                 //                 context: context,
  //                 //                 builder: (context) {
  //                 //                   return AlertDialog(
  //                 //                     title: const Text("Upload Electricity Meter"),
  //                 //                     content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
  //                 //                     actions: [
  //                 //                       IconButton(
  //                 //                         onPressed: () {
  //                 //                           Navigator.pop(context);
  //                 //                         },
  //                 //                         icon: const Icon(
  //                 //                           Icons.cancel,
  //                 //                           color: Colors.red,
  //                 //                         ),
  //                 //                       ),
  //                 //                       IconButton(
  //                 //                         onPressed: () async {
  //                 //                           Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
  //                 //                           Navigator.push(context,
  //                 //                               MaterialPageRoute(builder: (context) => ImageUploadMeter(userNumber: propPhoneNum, meterNumber: eMeterNumber,)));
  //                 //                         },
  //                 //                         icon: const Icon(
  //                 //                           Icons.done,
  //                 //                           color: Colors.green,
  //                 //                         ),
  //                 //                       ),
  //                 //                     ],
  //                 //                   );
  //                 //                 });
  //                 //           },
  //                 //           labelText: 'Photo',
  //                 //           fSize: 16,
  //                 //           faIcon: const FaIcon(Icons.camera_alt,),
  //                 //           fgColor: Colors.black38,
  //                 //           btSize: const Size(100, 38),
  //                 //         ),
  //                 //         BasicIconButtonGrey(
  //                 //           onPress: () async {
  //                 //             _updateE(_allPropertyResults[index]);
  //                 //           },
  //                 //           labelText: 'Capture',
  //                 //           fSize: 16,
  //                 //           faIcon: const FaIcon(Icons.edit,),
  //                 //           fgColor: Theme.of(context).primaryColor,
  //                 //           btSize: const Size(100, 38),
  //                 //         ),
  //                 //       ],
  //                 //     )
  //                 //   ],
  //                 // ),
  //                 ///Image display item needs to get the reference from the firestore using the users uploaded meter connection
  //                 // InkWell(
  //                 //   ///onTap allows to open image upload page if user taps on the image.
  //                 //   ///Can be later changed to display the picture zoomed in if user taps on it.
  //                 //   onTap: () {
  //                 //     eMeterNumber = _allPropertyResults[index]['meter number'];
  //                 //     propPhoneNum = _allPropertyResults[index]['cell number'];
  //                 //     showDialog(
  //                 //         barrierDismissible: false,
  //                 //         context: context,
  //                 //         builder: (context) {
  //                 //           return AlertDialog(
  //                 //             title: const Text("Upload Electricity Meter"),
  //                 //             content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
  //                 //             actions: [
  //                 //               IconButton(
  //                 //                 onPressed: () {
  //                 //                   Navigator.pop(context);
  //                 //                 },
  //                 //                 icon: const Icon(
  //                 //                   Icons.cancel,
  //                 //                   color: Colors.red,
  //                 //                 ),
  //                 //               ),
  //                 //               IconButton(
  //                 //                 onPressed: () async {
  //                 //                   Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
  //                 //                   Navigator.push(context,
  //                 //                       MaterialPageRoute(builder: (context) => ImageUploadMeter(userNumber: propPhoneNum, meterNumber: eMeterNumber,)));
  //                 //                 },
  //                 //                 icon: const Icon(
  //                 //                   Icons.done,
  //                 //                   color: Colors.green,
  //                 //                 ),
  //                 //               ),
  //                 //             ],
  //                 //           );
  //                 //         });
  //                 //   },
  //                 //
  //                 //   child: Center(
  //                 //     child: Container(
  //                 //       margin: const EdgeInsets.only(bottom: 5),
  //                 //       // height: 300,
  //                 //       // width: 300,
  //                 //       child: Center(
  //                 //         child: Card(
  //                 //           color: Colors.grey,
  //                 //           semanticContainer: true,
  //                 //           clipBehavior: Clip.antiAliasWithSaveLayer,
  //                 //           shape: RoundedRectangleBorder(
  //                 //             borderRadius: BorderRadius.circular(10.0),
  //                 //           ),
  //                 //           elevation: 0,
  //                 //           margin: const EdgeInsets.all(10.0),
  //                 //           child: FutureBuilder(
  //                 //               future: _getImage(
  //                 //                 ///Firebase image location must be changed to display image based on the meter number
  //                 //                   context, 'files/meters/$formattedDate/${_allPropertyResults[index]['cell number']}/electricity/${_allPropertyResults[index]['meter number']}.jpg'),
  //                 //               builder: (context, snapshot) {
  //                 //                 if (snapshot.hasError) {
  //                 //                   // imgUploadCheck = false;
  //                 //                   // updateImgCheckE(imgUploadCheck,_allPropertyResults[index]);
  //                 //                   return const Padding(
  //                 //                     padding: EdgeInsets.all(20.0),
  //                 //                     child: Column(
  //                 //                       mainAxisSize: MainAxisSize.min,
  //                 //                       children: [
  //                 //                         Text('Image not yet uploaded.',),
  //                 //                         SizedBox(height: 10,),
  //                 //                         FaIcon(Icons.camera_alt,),
  //                 //                       ],
  //                 //                     ),
  //                 //                   );
  //                 //                 }
  //                 //                 if (snapshot.connectionState == ConnectionState.done) {
  //                 //                   // imgUploadCheck = true;
  //                 //                   // updateImgCheckE(imgUploadCheck,_allPropertyResults[index]);
  //                 //                   return Column(
  //                 //                     mainAxisSize: MainAxisSize.min,
  //                 //                     children: [
  //                 //                       SizedBox(
  //                 //                         height: 300,
  //                 //                         width: 300,
  //                 //                         child: snapshot.data,
  //                 //                       ),
  //                 //                     ],
  //                 //                   );
  //                 //                 }
  //                 //                 if (snapshot.connectionState == ConnectionState.waiting) {
  //                 //                   return Container(
  //                 //                     child: const Padding(
  //                 //                       padding: EdgeInsets.all(5.0),
  //                 //                       child: CircularProgressIndicator(),
  //                 //                     ),);
  //                 //                 }
  //                 //                 return Container();
  //                 //               }
  //                 //           ),
  //                 //         ),
  //                 //       ),
  //                 //     ),
  //                 //   ),
  //                 // ),
  //                 // const SizedBox(height: 10,),
  //                 //
  //                 // const Center(
  //                 //   child: Text(
  //                 //     'Water Meter Reading Photo',
  //                 //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  //                 //   ),
  //                 // ),
  //                 // const SizedBox(height: 5,),
  //                 // Center(
  //                 //   child: BasicIconButtonGrey(
  //                 //     onPress: () async {
  //                 //       imageName = 'files/meters/$formattedDate/${_allPropResults[index]['cellNumber']}/${_allPropResults[index]['address']}/water/${_allPropResults[index]['water_meter_number']}.jpg';
  //                 //       addressSnap = _allPropResults[index]['address'];
  //                 //
  //                 //       Navigator.push(context,
  //                 //           MaterialPageRoute(builder: (context) => ImageZoomPage(imageName: imageName, addressSnap: addressSnap)));
  //                 //
  //                 //     },
  //                 //     labelText: 'View Uploaded Image',
  //                 //     fSize: 16,
  //                 //     faIcon: const FaIcon(Icons.zoom_in,),
  //                 //     fgColor: Colors.blue,
  //                 //     btSize: const Size(100, 38),
  //                 //   ),
  //                 // ),
  //                 //
  //                 // Column(
  //                 //   children: [
  //                 //     Row(
  //                 //       mainAxisAlignment: MainAxisAlignment.center,
  //                 //       crossAxisAlignment: CrossAxisAlignment.center,
  //                 //       children: [
  //                 //         BasicIconButtonGrey(
  //                 //           onPress: () async {
  //                 //             wMeterNumber = _allPropResults[index]['water_meter_number'];
  //                 //             propPhoneNum = _allPropResults[index]['cellNumber'];
  //                 //             addressSnap=_allPropResults[index]['address'];
  //                 //             showDialog(
  //                 //                 barrierDismissible: false,
  //                 //                 context: context,
  //                 //                 builder: (context) {
  //                 //                   return AlertDialog(
  //                 //                     title: const Text("Upload Water Meter"),
  //                 //                     content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
  //                 //                     actions: [
  //                 //                       IconButton(
  //                 //                         onPressed: () {
  //                 //                           Navigator.pop(context);
  //                 //                         },
  //                 //                         icon: const Icon(
  //                 //                           Icons.cancel,
  //                 //                           color: Colors.red,
  //                 //                         ),
  //                 //                       ),
  //                 //                       IconButton(
  //                 //                         onPressed: () async {
  //                 //                           Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
  //                 //                           Navigator.push(context,
  //                 //                               MaterialPageRoute(builder: (context) => ImageUploadWater(userNumber: propPhoneNum, meterNumber: wMeterNumber, propertyAddress: addressSnap, districtId: districtId ,municipalityId: municipalityId,)));
  //                 //                         },
  //                 //                         icon: const Icon(
  //                 //                           Icons.done,
  //                 //                           color: Colors.green,
  //                 //                         ),
  //                 //                       ),
  //                 //                     ],
  //                 //                   );
  //                 //                 });
  //                 //           },
  //                 //           labelText: 'Photo',
  //                 //           fSize: 16,
  //                 //           faIcon: const FaIcon(Icons.camera_alt,),
  //                 //           fgColor: Colors.black38,
  //                 //           btSize: const Size(100, 38),
  //                 //         ),
  //                 //         BasicIconButtonGrey(
  //                 //           onPress: () async {
  //                 //             _updateW(_allPropResults[index]);
  //                 //           },
  //                 //           labelText: 'Capture',
  //                 //           fSize: 16,
  //                 //           faIcon: const FaIcon(Icons.edit,),
  //                 //           fgColor: Theme.of(context).primaryColor,
  //                 //           btSize: const Size(100, 38),
  //                 //         ),
  //                 //       ],
  //                 //     )
  //                 //   ],
  //                 // ),
  //                 // InkWell(
  //                 //   ///onTap allows to open image upload page if user taps on the image.
  //                 //   ///Can be later changed to display the picture zoomed in if user taps on it.
  //                 //   onTap: () {
  //                 //     wMeterNumber = _allPropResults[index]['water meter number'];
  //                 //     propPhoneNum = _allPropResults[index]['cell number'];
  //                 //     addressSnap=_allPropResults[index]['address'];
  //                 //     showDialog(
  //                 //         barrierDismissible: false,
  //                 //         context: context,
  //                 //         builder: (context) {
  //                 //           return AlertDialog(
  //                 //             title: const Text("Upload Water Meter"),
  //                 //             content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
  //                 //             actions: [
  //                 //               IconButton(
  //                 //                 onPressed: () {
  //                 //                   Navigator.pop(context);
  //                 //                 },
  //                 //                 icon: const Icon(
  //                 //                   Icons.cancel,
  //                 //                   color: Colors.red,
  //                 //                 ),
  //                 //               ),
  //                 //               IconButton(
  //                 //                 onPressed: () async {
  //                 //                   Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
  //                 //                   Navigator.push(context,
  //                 //                       MaterialPageRoute(builder: (context) => ImageUploadWater(userNumber: propPhoneNum, meterNumber: wMeterNumber, propertyAddress: addressSnap,districtId: districtId,municipalityId: municipalityId,)));
  //                 //                 },
  //                 //                 icon: const Icon(
  //                 //                   Icons.done,
  //                 //                   color: Colors.green,
  //                 //                 ),
  //                 //               ),
  //                 //             ],
  //                 //           );
  //                 //         });
  //                 //   },
  //                 //
  //                 //   child: Center(
  //                 //     child: Container(
  //                 //       margin: const EdgeInsets.only(bottom: 5),
  //                 //       // height: 300,
  //                 //       // width: 300,
  //                 //       child: Center(
  //                 //         child: Card(
  //                 //           color: Colors.grey,
  //                 //           semanticContainer: true,
  //                 //           clipBehavior: Clip.antiAliasWithSaveLayer,
  //                 //           shape: RoundedRectangleBorder(
  //                 //             borderRadius: BorderRadius.circular(10.0),
  //                 //           ),
  //                 //           elevation: 0,
  //                 //           margin: const EdgeInsets.all(10.0),
  //                 //           child: FutureBuilder<String?>(
  //                 //               future: _getImageW(
  //                 //                 ///Firebase image location must be changed to display image based on the meter number
  //                 //                   context, 'files/meters/$formattedDate/${_allPropResults[index]['cellNumber']}/${_allPropResults[index]['address']}/water/${_allPropResults[index]['water_meter_number']}.jpg'),//$meterNumber
  //                 //               builder: (context, snapshot) {
  //                 //                 if (snapshot.hasError) {
  //                 //                   imgUploadCheck = false;
  //                 //                   updateImgCheckW(imgUploadCheck,_allPropResults[index]);
  //                 //                   return const Padding(
  //                 //                     padding: EdgeInsets.all(20.0),
  //                 //                     child: Column(
  //                 //                       mainAxisSize: MainAxisSize.min,
  //                 //                       children: [
  //                 //                         Text('Image not yet uploaded.',),
  //                 //                         SizedBox(height: 10,),
  //                 //                         FaIcon(Icons.camera_alt,),
  //                 //                       ],
  //                 //                     ),
  //                 //                   );
  //                 //                 }
  //                 //                 if  (snapshot.connectionState == ConnectionState.done) {
  //                 //                   imgUploadCheck = true;
  //                 //                   updateImgCheckW(imgUploadCheck, _allPropResults[index]);
  //                 //
  //                 //                   if (snapshot.data != null) {
  //                 //                     return Image.network(
  //                 //                       snapshot.data!, // Assuming _getImageW returns a URL
  //                 //                       fit: BoxFit.cover,
  //                 //                     );
  //                 //                   } else {
  //                 //                     return const Text('No image available.');
  //                 //                   }
  //                 //                 }
  //                 //                 if (snapshot.connectionState == ConnectionState.waiting) {
  //                 //                   return const Padding(
  //                 //                     padding: EdgeInsets.all(5.0),
  //                 //                     child: CircularProgressIndicator(),
  //                 //                   );
  //                 //                 }
  //                 //                 return Container();
  //                 //               }
  //                 //           ),
  //                 //         ),
  //                 //       ),
  //                 //     ),
  //                 //   ),
  //                 // ),
  //
  //                 const SizedBox(
  //                   height: 10,
  //                 ),
  //                 Text(
  //                   billMessage,
  //                   style: const TextStyle(
  //                       fontSize: 16, fontWeight: FontWeight.w400),
  //                 ),
  //
  //                 const SizedBox(
  //                   height: 10,
  //                 ),
  //                 Column(
  //                   children: [
  //                     BasicIconButtonGrey(
  //                       onPress: () async {
  //                         Provider.of<PropertyProvider>(context, listen: false)
  //                             .selectProperty(property!);
  //                         addressForTrend = _allPropResults[index]['address'];
  //
  //                         Navigator.push(
  //                             context,
  //                             MaterialPageRoute(
  //                                 builder: (context) => PropertyTrend(
  //                                       addressTarget: addressForTrend,
  //                                       districtId: districtId,
  //                                       municipalityId: municipalityId,
  //                                       isLocalMunicipality:
  //                                           isLocalMunicipality,
  //                                     )));
  //                       },
  //                       labelText: 'History',
  //                       fSize: 16,
  //                       faIcon: const FaIcon(
  //                         Icons.stacked_line_chart,
  //                       ),
  //                       fgColor: Colors.purple,
  //                       btSize: const Size(100, 38),
  //                     ),
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.center,
  //                       crossAxisAlignment: CrossAxisAlignment.center,
  //                       children: [
  //                         Stack(
  //                           children: [
  //                             BasicIconButtonGrey(
  //                               onPress: () async {
  //                                 Provider.of<PropertyProvider>(context,
  //                                         listen: false)
  //                                     .selectProperty(property!);
  //                                 //   Fluttertoast.showToast(msg: "Now opening the statement!\nPlease wait a few seconds!");
  //                                 //   _onSubmit(); // Handle any necessary updates
  //                                 //
  //                                 //   final storageRef = FirebaseStorage.instance.ref()
  //                                 //       .child("pdfs/$formattedDate/${_allPropResults[index]['userNumber']}/${_allPropResults[index]['propertyAddress']}");
  //                                 //   final listResult = await storageRef.listAll();
  //                                 //
  //                                 //   bool found = false;
  //                                 //   for (var item in listResult.items) {
  //                                 //     if (item.name.contains(_allPropResults[index]['account number'])) {
  //                                 //       final url = await item.getDownloadURL();
  //                                 //       print('The URL for download is ::: $url');
  //                                 //
  //                                 //       // Download the PDF locally
  //                                 //       final directory = await getApplicationDocumentsDirectory();
  //                                 //       final filePath = '${directory.path}/${item.name}';
  //                                 //       final response = await Dio().download(url, filePath);
  //                                 //
  //                                 //       if (response.statusCode == 200) {
  //                                 //         Fluttertoast.showToast(msg: "Statement opened successfully!");
  //                                 //         File pdfFile = File(filePath);
  //                                 //
  //                                 //         // Open the PDF in the viewer
  //                                 //         openPDF(context, pdfFile);
  //                                 //       } else {
  //                                 //         Fluttertoast.showToast(msg: "Failed to open PDF.");
  //                                 //       }
  //                                 //
  //                                 //       found = true;
  //                                 //       break; // Exit loop after successful operation
  //                                 //     }
  //                                 //   }
  //                                 //   if (!found) {
  //                                 //     Fluttertoast.showToast(msg: "No matching document found.");
  //                                 //   }
  //                                 // },
  //                                 Fluttertoast.showToast(
  //                                     msg:
  //                                         "Now opening the statement!\nPlease wait a few seconds!");
  //
  //                                 // Extract values directly from the _allPropResults[index]
  //                                 String userNumber =
  //                                     _allPropResults[index]['cellNumber'];
  //                                 String propertyAddress =
  //                                     _allPropResults[index]['address'];
  //                                 String accountNumber =
  //                                     _allPropResults[index]['accountNumber'];
  //
  //                                 print('User Number: $userNumber');
  //                                 print('Property Address: $propertyAddress');
  //                                 print('Account Number: $accountNumber');
  //
  //                                 // Call the method to open the invoice PDF
  //                                 try {
  //                                   await openPropertyInvoice(
  //                                       userNumber,
  //                                       propertyAddress,
  //                                       accountNumber,
  //                                       context);
  //                                   Fluttertoast.showToast(msg: "Successful!");
  //                                 } catch (e) {
  //                                   Fluttertoast.showToast(
  //                                       msg: "Unable to open statement: $e");
  //                                 }
  //                               },
  //                               labelText: 'Invoice',
  //                               fSize: 16,
  //                               faIcon: const FaIcon(
  //                                 Icons.picture_as_pdf,
  //                               ),
  //                               fgColor: Colors.orangeAccent,
  //                               btSize: const Size(100, 38),
  //                             ),
  //                             const SizedBox(
  //                               width: 5,
  //                             ),
  //                             Visibility(
  //                                 visible: _isLoading,
  //                                 child: Column(
  //                                   mainAxisAlignment: MainAxisAlignment.center,
  //                                   children: [
  //                                     const SizedBox(
  //                                       height: 15,
  //                                       width: 130,
  //                                     ),
  //                                     Container(
  //                                       width: 24,
  //                                       height: 24,
  //                                       padding: const EdgeInsets.all(2.0),
  //                                       child: const CircularProgressIndicator(
  //                                         color: Colors.purple,
  //                                         strokeWidth: 3,
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 )),
  //                           ],
  //                         ),
  //                         BasicIconButtonGrey(
  //                           onPress: () async {
  //                             Provider.of<PropertyProvider>(context,
  //                                     listen: false)
  //                                 .selectProperty(property!);
  //                             accountNumberAll =
  //                                 _allPropResults[index]['accountNumber'];
  //                             locationGivenAll =
  //                                 _allPropResults[index]['address'];
  //
  //                             Navigator.push(
  //                                 context,
  //                                 MaterialPageRoute(
  //                                     builder: (context) => MapScreenProp(
  //                                           propAddress: locationGivenAll,
  //                                           propAccNumber: accountNumberAll,
  //                                         )));
  //                           },
  //                           labelText: 'Map',
  //                           fSize: 16,
  //                           faIcon: const FaIcon(
  //                             Icons.map,
  //                           ),
  //                           fgColor: Colors.green,
  //                           btSize: const Size(100, 38),
  //                         ),
  //                         const SizedBox(
  //                           width: 5,
  //                         ),
  //                       ],
  //                     ),
  //                     const SizedBox(
  //                       height: 5,
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         );
  //       },
  //     );
  //   //}
  //   return const Center(
  //     child: CircularProgressIndicator(),
  //   );
  // }

  Widget noCapPropertyCard() {
    if (isLoading) {
      // Display a loading spinner while fetching data
      return const Center(child: CircularProgressIndicator());
    }

    if (_allPropResults.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          // Refocus when tapping within the tab content
          _focusNodeTab2.requestFocus();
        },
        child: KeyboardListener(
          focusNode: _focusNodeTab2,
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent) {
              final double pageScrollAmount =
                  _scrollControllerTab2.position.viewportDimension;

              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                _scrollControllerTab2.animateTo(
                  _scrollControllerTab2.offset + 50,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                _scrollControllerTab2.animateTo(
                  _scrollControllerTab2.offset - 50,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
                _scrollControllerTab2.animateTo(
                  _scrollControllerTab2.offset + pageScrollAmount,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
                _scrollControllerTab2.animateTo(
                  _scrollControllerTab2.offset - pageScrollAmount,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                );
              }
            }
          },
          child: Scrollbar(
            controller: _scrollControllerTab2,
            thickness: 12, // Customize the thickness of the scrollbar
            radius: const Radius.circular(8), // Rounded edges for the scrollbar
            thumbVisibility: true,
            trackVisibility: true, // Makes the track visible as well
            interactive: true,
            child: ListView.builder(
              controller: _scrollControllerTab2,
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _allPropResults.length,

              ///this call is to display all details for all users but is only displaying for the current user account.
              ///it can be changed to display all users for the staff to see if the role is set to all later on.
              itemBuilder: (context, index) {
                final munId = _allPropResults[index]['municipalityId'];
                final utilTypes = municipalityUtilityMap[munId] ?? [];

                final bool showWater = utilTypes.contains('water');
                final bool showElectricity = utilTypes.contains('electricity');
                eMeterNumber = _allPropResults[index]['meter_number'];
                wMeterNumber = _allPropResults[index]['water_meter_number'];
                propPhoneNum = _allPropResults[index]['cellNumber'];

                if (_allPropResults[index]['eBill'] != '' ||
                    _allPropResults[index]['eBill'] != 'R0,000.00' ||
                    _allPropResults[index]['eBill'] != 'R0.00' ||
                    _allPropResults[index]['eBill'] != 'R0' ||
                    _allPropResults[index]['eBill'] != '0') {
                  billMessage =
                      'Utilities bill outstanding: ${_allPropResults[index]['eBill']}';
                } else {
                  billMessage = 'No outstanding payments';
                }

                if (_allPropResults[index]['imgStateE'] == false ||
                    _allPropResults[index]['imgStateW'] == false) {
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
                          if(handlesWater)...[
                          Text(
                            'Water Account Number: ${_allPropResults[index]['accountNumber']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          ],
                          const SizedBox(
                            height: 5,
                          ),
                          if(handlesElectricity)...[
                            Text(
                              'Electricity Account Number: ${_allPropResults[index]['electricityAccountNumber']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                          ],
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Street Address: ${_allPropResults[index]['address']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Area Code: ${_allPropResults[index]['areaCode']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          if (showWater) ...[
                            const SizedBox(height: 5),
                            Text(
                              'Water Meter Number: ${_allPropResults[index]['water_meter_number']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Previous Month ($previousMonth) Water Reading: ${previousMonthReadings[_allPropResults[index]['address']] ?? "N/A"}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Current Month Water Reading for $currentMonth: ${currentMonthReadings[_allPropResults[index]['address']] ?? "N/A"}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                          ],
                          if (showElectricity) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Electricity Meter Number: ${_allPropResults[index]['meter_number'] ?? "N/A"}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Previous Month ($previousMonth) Electricity Reading: ${previousMonthElectricReadings[_allPropResults[index]['address']] ?? "N/A"}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Current Month Electricity Reading for $currentMonth: ${currentMonthElectricReadings[_allPropResults[index]['address']] ?? "N/A"}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                          ],
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Phone Number: ${_allPropResults[index]['cellNumber']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            'First Name: ${_allPropResults[index]['firstName']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Surname: ${_allPropResults[index]['lastName']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            'ID Number: ${_allPropResults[index]['idNumber']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          const Center(
                            child: Text(
                              'Water Meter Photo',
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
                                  if (!isLocalUser) {
                                    // Ensure that the user selects a municipality first
                                    if (selectedMunicipality == null ||
                                        selectedMunicipality ==
                                            "Select Municipality") {
                                      Fluttertoast.showToast(
                                        msg:
                                            "Please select a municipality first!",
                                        toastLength: Toast.LENGTH_SHORT,
                                        gravity: ToastGravity.CENTER,
                                      );
                                      return; // Stop further execution if no municipality is selected
                                    }
                                  }

                                  // Determine the municipality context based on the user type
                                  String municipalityContext = isLocalUser
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
                                      _allPropResults[index]['cellNumber'];
                                  String? address =
                                      _allPropResults[index]['address'];
                                  String? meterNumber = _allPropResults[index]
                                      ['water_meter_number'];
                                  String? eMeterNumber =
                                      _allPropResults[index]['meter_number'];
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

                                  // Prepare the image path
                                  imageName =
                                      'files/meters/$formattedDate/$cellNumber/$address/water/$meterNumber.jpg';
                                  addressSnap = address;
                                  imageElectricName =
                                      'files/meters/$formattedDate/$cellNumber/$address/electricity/$eMeterNumber.jpg';
                                  // Log the details for debugging
                                  print(
                                      "Navigating to ImageZoomPage with details:");
                                  print("imageName: $imageName");
                                  print("addressSnap: $addressSnap");
                                  print(
                                      "municipalityContext: $municipalityContext");
                                  print("municipality email: $userEmail");
                                  // Navigate to the ImageZoomPage
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ImageZoomPage(
                                        imageName: imageName,
                                        addressSnap: addressSnap,
                                        municipalityUserEmail: userEmail,
                                        isLocalMunicipality:
                                            isLocalMunicipality,
                                        districtId: districtId,
                                        municipalityId: municipalityContext,
                                        isLocalUser: isLocalUser,
                                        imageElectricName: imageElectricName,
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  print(
                                      "Error in 'View Uploaded Image' button: $e");
                                  Fluttertoast.showToast(
                                    msg:
                                        "Error: Unable to view uploaded image.",
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.CENTER,
                                  );
                                }
                              },
                              labelText: 'View Uploaded Image',
                              fSize: 16,
                              faIcon: const FaIcon(Icons.zoom_in),
                              fgColor: Colors.blue,
                              btSize: const Size(100, 38),
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
                              BasicIconButtonGrey(
                                onPress: () async {
                                  try {
                                    // Select the property and store it using Provider.
                                    Provider.of<PropertyProvider>(context,
                                            listen: false)
                                        .selectProperty(property!,
                                            handlesWater: handlesWater,
                                            handlesElectricity:
                                                handlesElectricity);

                                    addressForTrend =
                                        _allPropResults[index]['address'];
                                    String selectedMunicipalityId =
                                        isLocalMunicipality || isLocalUser
                                            ? municipalityId
                                            : selectedMunicipality!;

                                    // 🔍 Fetch utility type for the selected municipality
                                    DocumentReference docRef =
                                        isLocalMunicipality
                                            ? FirebaseFirestore.instance
                                                .collection(
                                                    'localMunicipalities')
                                                .doc(selectedMunicipalityId)
                                            : FirebaseFirestore.instance
                                                .collection('districts')
                                                .doc(districtId)
                                                .collection('municipalities')
                                                .doc(selectedMunicipalityId);

                                    DocumentSnapshot snapshot =
                                        await docRef.get();
                                    List<String> utilityTypes =
                                        List<String>.from(
                                            snapshot['utilityType'] ?? []);
                                    bool localHandlesWater =
                                        utilityTypes.contains("water");
                                    bool localHandlesElectricity =
                                        utilityTypes.contains("electricity");
                                    print("Navigating to PropertyTrend:");
                                    print("Address Target: $addressForTrend");
                                    print("District ID: $districtId");
                                    print("Municipality ID: $municipalityId");
                                    print(
                                        "Is Local Municipality: $isLocalMunicipality");
                                    print(
                                        "💧 Water = $localHandlesWater | ⚡ Electricity = $localHandlesElectricity");

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PropertyTrend(
                                          addressTarget: addressForTrend,
                                          districtId: districtId,
                                          municipalityId: municipalityId,
                                          isLocalMunicipality:
                                              isLocalMunicipality,
                                          handlesWater: localHandlesWater,
                                          handlesElectricity:
                                              localHandlesElectricity,
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    print("Error in History Button: $e");
                                    Fluttertoast.showToast(
                                      msg:
                                          "Error navigating to property history.",
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.CENTER,
                                    );
                                  }
                                },
                                labelText: 'History',
                                fSize: 16,
                                faIcon: const FaIcon(Icons.stacked_line_chart),
                                fgColor: Colors.purple,
                                btSize: const Size(100, 38),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Stack(
                                    children: [
                                      /*  BasicIconButtonGrey(
                                          onPress: () async {
                                            final Property? property =
                                                Provider.of<PropertyProvider>(context, listen: false).selectedProperty;

                                            print("Selected Property: $property");

                                            if (property == null) {
                                              Fluttertoast.showToast(
                                                msg: "Error: Property information is missing.",
                                                toastLength: Toast.LENGTH_SHORT,
                                                gravity: ToastGravity.CENTER,
                                              );
                                              return;
                                            }

                                            String? accountNumberPDF = property.accountNo;
                                            String? cellNumber = property.cellNum;
                                            String? address = property.address;

                                            print('Account Number: $accountNumberPDF');
                                            print('Cell Number: $cellNumber');
                                            print('Address: $address');

                                            if (accountNumberPDF == null || cellNumber == null || address == null) {
                                              Fluttertoast.showToast(
                                                msg: "Incomplete property details. Cannot download statement.",
                                                toastLength: Toast.LENGTH_SHORT,
                                                gravity: ToastGravity.CENTER,
                                              );
                                              return;
                                            }

                                            // Proceed with the invoice download logic...
                                          },
                                          labelText: 'Invoice',
                                          fSize: 16,
                                          faIcon: const FaIcon(
                                            Icons.picture_as_pdf,
                                          ),
                                          fgColor: Colors.orangeAccent,
                                          btSize: const Size(100, 38),
                                        ),*/
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
                                          )),
                                    ],
                                  ),
                                  BasicIconButtonGrey(
                                    onPress: () async {
                                      Provider.of<PropertyProvider>(context,
                                              listen: false)
                                          .selectProperty(property!,
                                              handlesWater: handlesWater,
                                              handlesElectricity:
                                                  handlesElectricity);
                                      accountNumberAll = _allPropResults[index]
                                          ['account number'];
                                      locationGivenAll =
                                          _allPropResults[index]['address'];

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
                } else {
                  return const SizedBox();
                }
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

  Future<void> updateImgCheckE(bool imgCheck,
      [DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      await documentSnapshot.reference.update({
        "imgStateE": imgCheck,
      });
    }
    imgCheck = false;
  }

  Future<void> updateImgCheckW(bool imgCheck,
      [DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      await documentSnapshot.reference.update({
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
                                  .selectProperty(property!,
                                      handlesWater: handlesWater,
                                      handlesElectricity: handlesElectricity);
                              DateTime now = DateTime.now();
                              String formattedDate =
                                  DateFormat('yyyy-MM-dd – kk:mm').format(now);

                              final String tokenSelected = notifyToken;
                              final String? userNumber = documentSnapshot?.id;
                              final String notificationTitle = title.text;
                              final String notificationBody = body.text;
                              final String notificationDate = formattedDate;
                              const bool readStatus = false;

                              if (title.text != '' ||
                                  title.text.isNotEmpty ||
                                  body.text != '' ||
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

                                ///It can be changed to the firebase notification
                                String titleText = title.text;
                                String bodyText = body.text;

                                ///gets users phone token to send notification to this phone
                                if (userNumber != "") {
                                  DocumentSnapshot snap =
                                      await FirebaseFirestore.instance
                                          .collection('districts')
                                          .doc(districtId)
                                          .collection('municipalities')
                                          .doc(municipalityId)
                                          .collection('UserToken')
                                          .doc(userNumber)
                                          .get();
                                  String token = snap['token'];
                                  print(
                                      'The phone number is retrieved as ::: $userNumber');
                                  print('The token is retrieved as ::: $token');
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
    CollectionReference<Object?> propertiesDataStream,
    String districtId,
    String municipalityId,
    bool isLocalUser, // Pass this to handle user type
    String? selectedMunicipality, // To filter by municipality
  ) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: isLocalUser
            ? FirebaseFirestore.instance
                .collection('districts')
                .doc(districtId)
                .collection('municipalities')
                .doc(municipalityId)
                .collection('properties')
                .snapshots()
            : FirebaseFirestore.instance
                .collectionGroup('properties') // Retrieve all properties
                .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            List<DocumentSnapshot> filteredDocs = streamSnapshot.data!.docs;

            if (!isLocalUser &&
                selectedMunicipality != null &&
                selectedMunicipality.isNotEmpty) {
              filteredDocs = filteredDocs.where((doc) {
                var docMunicipalityId = doc.reference.parent.parent!.id;
                return docMunicipalityId == selectedMunicipality;
              }).toList();
            }
            return ListView.builder(
              ///this call is to display all details for all users but is only displaying for the current user account.
              ///it can be changed to display all users for the staff to see if the role is set to all later on.
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                    streamSnapshot.data!.docs[index];

                eMeterNumber = documentSnapshot['meter_number'];
                wMeterNumber = documentSnapshot['water_meter number'];
                propPhoneNum = documentSnapshot['cellNumber'];

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
                          if (handlesWater) ...[
                            Text(
                              'Water Account Number: ${documentSnapshot['accountNumber']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                          ],
                          const SizedBox(
                            height: 5,
                          ),
                          if (handlesElectricity) ...[
                            Text(
                              'Electricity Account Number: ${documentSnapshot['electricityAccountNumber']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                          ],
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
                          if (handlesWater) ...[
                            Text(
                              'Water Meter Number: ${documentSnapshot['water_meter_number']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              'Previous Month Water ($previousMonth) Reading: $previousWaterReading',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              'Water Meter Reading for $currentMonth: $currentWaterReading',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                          ],
                          if (handlesElectricity) ...[
                            Text(
                              'Electricity Meter Number: ${documentSnapshot['meter_number']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              'Previous Month Electricity ($previousMonth) Reading: $previousElectricityReading ',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              'Electricity Meter Reading for $currentMonth: $currentElectricityReading',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
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

                          // const Center(
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
                          //             eMeterNumber =
                          //                 documentSnapshot['meter number'];
                          //             propPhoneNum =
                          //                 documentSnapshot['cell number'];
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
                          //         BasicIconButtonGrey(
                          //           onPress: () async {
                          //             Provider.of<PropertyProvider>(context, listen: false)
                          //                 .selectProperty(property!);
                          //             // This will handle the image upload
                          //             await handleImageUpload(context, propPhoneNum, eMeterNumber);
                          //           },
                          //           labelText: 'Photo',
                          //           fSize: 16,
                          //           faIcon: const FaIcon(Icons.camera_alt),
                          //           fgColor: Colors.black38,
                          //           btSize: const Size(100, 38),
                          //         ),
                          //         BasicIconButtonGrey(
                          //           onPress: () async {
                          //             // This will handle updating the meter reading
                          //             await _updateE(documentSnapshot);
                          //           },
                          //           labelText: 'Capture',
                          //           fSize: 16,
                          //           faIcon: const FaIcon(Icons.edit),
                          //           fgColor: Theme.of(context).primaryColor,
                          //           btSize: const Size(100, 38),
                          //         ),
                          //       ],
                          //     ),
                          // const SizedBox(height: 5),
                          // FutureBuilder<String>(
                          //     future: _getImage(context,
                          //         'files/meters/$formattedMonth/$propPhoneNum/electricity/$eMeterNumber.jpg'),
                          //     builder: (context, snapshot) {
                          //       if (snapshot.hasData &&
                          //           snapshot.connectionState ==
                          //               ConnectionState.done) {
                          //         return GestureDetector(
                          //           onTap: () {
                          //             final imageProvider =
                          //             NetworkImage(snapshot.data!);
                          //             showImageViewer(context, imageProvider);
                          //           },
                          //           child: Container(
                          //             margin:
                          //             const EdgeInsets.only(bottom: 5),
                          //             height: 180,
                          //             child: Card(
                          //               color: Colors.white54,
                          //               semanticContainer: true,
                          //               clipBehavior:
                          //               Clip.antiAliasWithSaveLayer,
                          //               shape: RoundedRectangleBorder(
                          //                 borderRadius:
                          //                 BorderRadius.circular(10.0),
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
                          //             child: Center(
                          //               child: Column(
                          //                 mainAxisSize: MainAxisSize.min,
                          //                 children: [
                          //                   Text('Image not yet uploaded.'),
                          //                   SizedBox(height: 10),
                          //                   FaIcon(Icons.camera_alt),
                          //                 ],
                          //               ),
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
                          //         barrierDismissible: false,
                          //         context: context,
                          //         builder: (context) {
                          //           return AlertDialog(
                          //             title: const Text(
                          //                 "Upload Electricity Meter"),
                          //             content: const Text(
                          //                 "Uploading a new image will replace current image!\n\nAre you sure?"),
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
                          //                   Fluttertoast.showToast(
                          //                       msg:
                          //                           "Uploading a new image\nwill replace current image!");
                          //                   Navigator.push(
                          //                       context,
                          //                       MaterialPageRoute(
                          //                           builder: (context) =>
                          //                               ImageUploadMeter(
                          //                                 userNumber:
                          //                                     propPhoneNum,
                          //                                 meterNumber:
                          //                                     eMeterNumber,
                          //                               )));
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
                          //
                          //                   ///Firebase image location must be changed to display image based on the meter number
                          //                   context,
                          //                   'files/meters/$formattedDate/$propPhoneNum/electricity/$eMeterNumber.jpg'),
                          //               builder: (context,
                          //                   AsyncSnapshot<dynamic> snapshot) {
                          //                 if (snapshot.hasError) {
                          //                   imgUploadCheck = false;
                          //                   updateImgCheckE(imgUploadCheck,
                          //                       documentSnapshot);
                          //                   return const Padding(
                          //                     padding: EdgeInsets.all(20.0),
                          //                     child: Column(
                          //                       mainAxisSize: MainAxisSize.min,
                          //                       children: [
                          //                         Text(
                          //                           'Image not yet uploaded.',
                          //                         ),
                          //                         SizedBox(
                          //                           height: 10,
                          //                         ),
                          //                         FaIcon(
                          //                           Icons.camera_alt,
                          //                         ),
                          //                       ],
                          //                     ),
                          //                   );
                          //                 }
                          //                 if (snapshot.connectionState ==
                          //                     ConnectionState.done) {
                          //                   // imgUploadCheck = true;
                          //                   updateImgCheckE(imgUploadCheck,
                          //                       documentSnapshot);
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
                          //                 if (snapshot.connectionState ==
                          //                     ConnectionState.waiting) {
                          //                   return Container(
                          //                     child: const Padding(
                          //                       padding: EdgeInsets.all(5.0),
                          //                       child:
                          //                           CircularProgressIndicator(),
                          //                     ),
                          //                   );
                          //                 }
                          //                 return Container();
                          //               }),
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
                                  BasicIconButtonGrey(
                                    onPress: () async {
                                      Provider.of<PropertyProvider>(context,
                                              listen: false)
                                          .selectProperty(property!,
                                              handlesWater: handlesWater,
                                              handlesElectricity:
                                                  handlesElectricity);
                                      wMeterNumber = documentSnapshot[
                                          'water_meter_number'];
                                      propPhoneNum =
                                          documentSnapshot['cellNumber'];
                                      String propertyAddress =
                                          documentSnapshot['address']
                                              .replaceAll(
                                                  RegExp(r'[/\\?%*:|"<>]'),
                                                  '_');
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
                                                            property!,
                                                            handlesWater:
                                                                handlesWater,
                                                            handlesElectricity:
                                                                handlesElectricity);
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
                                          .selectProperty(property!,
                                              handlesWater: handlesWater,
                                              handlesElectricity:
                                                  handlesElectricity);
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
                          //         'files/meters/$formattedMonth/$propPhoneNum/water/$wMeterNumber.jpg'),
                          //     builder: (context, snapshot) {
                          //       if (snapshot.hasData &&
                          //           snapshot.connectionState ==
                          //               ConnectionState.done) {
                          //         return GestureDetector(
                          //           onTap: () {
                          //             final imageProvider =
                          //             NetworkImage(snapshot.data!);
                          //             showImageViewer(
                          //                 context, imageProvider);
                          //           },
                          //           child: Container(
                          //             margin: const EdgeInsets.only(
                          //                 bottom: 5),
                          //             height: 180,
                          //             child: Card(
                          //               color: Colors.white54,
                          //               semanticContainer: true,
                          //               clipBehavior:
                          //               Clip.antiAliasWithSaveLayer,
                          //               shape: RoundedRectangleBorder(
                          //                 borderRadius:
                          //                 BorderRadius.circular(10.0),
                          //               ),
                          //               elevation: 0,
                          //               margin:
                          //               const EdgeInsets.all(10.0),
                          //               child: Center(
                          //                 // Ensuring the image is centered within the card
                          //                 child: Image.network(
                          //                     snapshot.data!,
                          //                     fit: BoxFit.cover),
                          //               ),
                          //             ),
                          //           ),
                          //         );
                          //       } else if (snapshot.hasError) {
                          //         return const Padding(
                          //           padding: EdgeInsets.all(20.0),
                          //           child: Center(
                          //             child: Center(
                          //               child: Column(
                          //                 mainAxisSize: MainAxisSize.min,
                          //                 children: [
                          //                   Text('Image not yet uploaded.'),
                          //                   SizedBox(height: 10),
                          //                   FaIcon(Icons.camera_alt),
                          //                 ],
                          //               ),
                          //             ),
                          //           ),
                          //         );
                          //       } else {
                          //         return Container(
                          //           height: 180,
                          //           margin: const EdgeInsets.all(10.0),
                          //           child: const Center(
                          //               child:
                          //               CircularProgressIndicator()),
                          //         );
                          //       }
                          //     }),
                          InkWell(
                            ///onTap allows to open image upload page if user taps on the image.
                            ///Can be later changed to display the picture zoomed in if user taps on it.
                            onTap: () {
                              wMeterNumber =
                                  documentSnapshot['water_meter_number'];
                              propPhoneNum = documentSnapshot['cellNumber'];
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
                                                          userNumber:
                                                              propPhoneNum,
                                                          meterNumber:
                                                              wMeterNumber,
                                                          propertyAddress:
                                                              addressSnap,
                                                          districtId:
                                                              districtId,
                                                          municipalityId:
                                                              municipalityId,
                                                          isLocalMunicipality:
                                                              isLocalMunicipality,
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
                                            'files/meters/$formattedDate/$propPhoneNum/$addressSnap/water/$wMeterNumber.jpg'),
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
                                  /* BasicIconButtonGrey(
                                    onPress: () async {
                                      try {
                                        // Ensure the district-level user selects a municipality
                                        if (!isLocalUser) {
                                          if (selectedMunicipality == null ||
                                              selectedMunicipality == "Select Municipality") {
                                            Fluttertoast.showToast(
                                              msg: "Please select a municipality first!",
                                              toastLength: Toast.LENGTH_SHORT,
                                              gravity: ToastGravity.CENTER,
                                            );
                                            return; // Stop further execution if no municipality is selected
                                          }
                                        }

                                        // Determine the correct municipality context
                                        String municipalityContext = isLocalUser
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

                                        // Ensure property details are available
                                        if (property == null) {
                                          Fluttertoast.showToast(
                                            msg: "Error: Property information is missing.",
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.CENTER,
                                          );
                                          return;
                                        }

                                        // Extract relevant property details
                                        String userNumber = property!.cellNum;
                                        String propertyAddress = property!.address;
                                        String accountNumber = property!.accountNo;

                                        print('The account number is: $accountNumber');

                                        Fluttertoast.showToast(
                                          msg: "Now downloading your statement!\nPlease wait a few seconds!",
                                        );

                                        _onSubmit(); // Display loading indicator

                                        // Open the invoice with the correct context
                                        await openPropertyInvoice(
                                          userNumber,
                                          propertyAddress,
                                          accountNumber,
                                          municipalityContext,
                                          context,
                                        );
                                      } catch (e) {
                                        print("Error in 'Invoice' button: $e");
                                        Fluttertoast.showToast(
                                          msg: "Error: Unable to download invoice.",
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.CENTER,
                                        );
                                      }
                                    },
                                    labelText: 'Invoice',
                                    fSize: 16,
                                    faIcon: const FaIcon(Icons.picture_as_pdf),
                                    fgColor: Colors.orangeAccent,
                                    btSize: const Size(100, 38),
                                  ),*/
                                  BasicIconButtonGrey(
                                    onPress: () async {
                                      final propData = _allPropResults[index].data() as Map<String, dynamic>;

                                      // Select appropriate account number
                                      final selectedAccountNumber = handlesElectricity && !handlesWater
                                          ? (propData['electricityAccountNumber'] ?? '')
                                          : (propData['accountNumber'] ?? '');

                                      final selectedAddress = propData['address'] ?? '';
                                      Provider.of<PropertyProvider>(context,
                                              listen: false)
                                          .selectProperty(property!,
                                              handlesWater: handlesWater,
                                              handlesElectricity:
                                                  handlesElectricity);
                                      // accountNumberAll =
                                      //     documentSnapshot['accountNumber'];
                                      // locationGivenAll =
                                      //     documentSnapshot['address'];
                                      accountNumberAll = selectedAccountNumber;
                                      locationGivenAll = selectedAddress;
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

  CollectionReference<Map<String, dynamic>> getPropertiesCollection() {
    if (isLocalMunicipality) {
      // If the user belongs to a standalone local municipality
      return FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('properties');
    } else if (!isLocalUser) {
      // District-level user can access all properties across municipalities using collectionGroup
      // Note: collectionGroup() is called on FirebaseFirestore instance, not on a DocumentReference
      return FirebaseFirestore.instance.collectionGroup('properties')
          as CollectionReference<Map<String, dynamic>>;
    } else {
      // Municipality-level user can only access properties for their specific municipality
      return FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('properties');
    }
  }

  Future<void> _create([DocumentSnapshot? documentSnapshot]) async {
    _accountNumberController.text = '';
    _addressController.text = '';
    _areaCodeController.text = '';
    _wardController.text = '';
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
                  if(handlesWater)...[
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _accountNumberController,
                      decoration:
                          const InputDecoration(labelText: 'Water Account Number'),
                    ),
                  ),
                  ],
                  if(handlesElectricity)...[
                    Visibility(
                      visible: visibilityState1,
                      child: TextField(
                        controller: _electricityAccountController,
                        decoration:
                        const InputDecoration(labelText: 'Electricity Account Number'),
                      ),
                    ),
                  ],
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
                      keyboardType: const TextInputType.numberWithOptions(),
                      controller: _wardController,
                      decoration: const InputDecoration(
                        labelText: 'Ward Number',
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
                    visible: visibilityState1,
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
                      final String electricityAccountNumber=_electricityAccountController.text;
                      final String address = _addressController.text;
                      final String areaCode = _areaCodeController.text;
                      final String ward = _wardController.text;
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

                      CollectionReference<Map<String, dynamic>> propList =
                          getPropertiesCollection();
                      await propList.add({
                        "accountNumber": accountNumber,
                        "address": address,
                        "areaCode": areaCode,
                        "electricityAccountNumber":electricityAccountNumber,
                        "ward": ward,
                        "water_meter_number": waterMeterNumber,
                        "water_meter_reading": waterMeterReading,
                        "meter_number": meterNumber,
                        "meter_reading": meterReading,
                        "cellNumber": cellNumber,
                        "firstName": firstName,
                        "lastName": lastName,
                        "idNumber": idNumber,
                      });

                      // await _propList?.add({
                      //   "accountNumber": accountNumber,
                      //   "address": address,
                      //   "areaCode": areaCode,
                      //   "ward": ward,
                      //   // "meter_number": meterNumber,
                      //   // "meter_reading": meterReading,
                      //   "water_meter_number": waterMeterNumber,
                      //   "water_meter_reading": waterMeterReading,
                      //   "cellNumber": cellNumber,
                      //   "firstName": firstName,
                      //   "lastName": lastName,
                      //   "idNumber": idNumber,
                      // });
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
                    },
                  )
                ],
              ),
            ),
          );
        });
  }

  DocumentReference<Map<String, dynamic>> getDocumentReference(
      String documentId) {
    if (isLocalMunicipality) {
      // For standalone local municipalities
      return FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('properties')
          .doc(documentId);
    } else {
      // For district-based municipalities
      return FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('properties')
          .doc(documentId);
    }
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
                      DocumentReference<Map<String, dynamic>> documentRef =
                          getDocumentReference(documentSnapshot!.id);
                      await documentRef.update({
                        "accountNumber": accountNumber,
                        "address": address,
                        "areaCode": areaCode,
                        "water_meter_number": waterMeterNumber,
                        "water_meter_reading": waterMeterReading,
                        "meter_number": meterNumber,
                        "meter_reading": meterReading,
                        "cellNumber": cellNumber,
                        "firstName": firstName,
                        "lastName": lastName,
                        "idNumber": idNumber,
                        "userID": userID,
                      });
                      // await _propList?.doc(documentSnapshot!.id).update({
                      //   "accountNumber": accountNumber,
                      //   "address": address,
                      //   "areaCode": areaCode,
                      //   // "meter_number": meterNumber,
                      //   // "meter_reading": meterReading,
                      //   "water_meter_number": waterMeterNumber,
                      //   "water_meter_reading": waterMeterReading,
                      //   "cellNumber": cellNumber,
                      //   "firstName": firstName,
                      //   "lastName": lastName,
                      //   "idNumber": idNumber,
                      //   "userID": userID,
                      // });

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
  //     // _meterNumberController.text = documentSnapshot['meter_number'];
  //     // _meterReadingController.text = documentSnapshot['meter_reading'];
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
  //                     Provider.of<PropertyProvider>(context, listen: false)
  //                         .selectProperty(property!);
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
  //                     // await _propList.doc(documentSnapshot!.id).update({
  //                     //   "account number": accountNumber,
  //                     //   "address": address,
  //                     //   "area code": areaCode,
  //                     //   "meter number": meterNumber,
  //                     //   "meter reading": meterReading,
  //                     //   "water meter number": waterMeterNumber,
  //                     //   "water meter reading": waterMeterReading,
  //                     //   "cell number": cellNumber,
  //                     //   "first name": firstName,
  //                     //   "last name": lastName,
  //                     //   "id number": idNumber,
  //                     //   "user id": userID,
  //                     // });
  //                     //
  //                     // final CollectionReference _propMonthReadings =
  //                     //     FirebaseFirestore.instance
  //                     //         .collection('consumption')
  //                     //         .doc(formattedMonth)
  //                     //         .collection('address')
  //                     //         .doc(address) as CollectionReference<Object?>;
  //                     //
  //                     // if (_propMonthReadings.id != address ||
  //                     //     _propMonthReadings.id == '') {
  //                     //   await _propMonthReadings.add({
  //                     //     "address": address,
  //                     //     "meter reading": meterReading,
  //                     //     "water meter reading": waterMeterReading,
  //                     //   });
  //                     // } else {
  //                     //   await _propMonthReadings.doc(address).update({
  //                     //     "address": address,
  //                     //     "meter reading": meterReading,
  //                     //     "water meter reading": waterMeterReading,
  //                     //   });
  //                     // }
  //                     Map<String, dynamic> updateDetails = {
  //                       "accountNumber": accountNumber,
  //                       "address": address,
  //                       "areaCode": areaCode,
  //                       "meterNumber": meterNumber,
  //                       "meterReading": meterReading,
  //                       "waterMeterNumber": waterMeterNumber,
  //                       "waterMeterReading": waterMeterReading,
  //                       "cellNumber": cellNumber,
  //                       "firstName": firstName,
  //                       "lastName": lastName,
  //                       "idNumber": idNumber,
  //                       "userId": userID,
  //                     };
  //                     if (accountNumber.isNotEmpty) {
  //                       await documentSnapshot?.reference.update(updateDetails);
  //                       print("municipalityUserEmail: ${widget.municipalityUserEmail}");
  //                       print('Calling logEMeterReadingUpdate...');
  //
  //                       // Log the update action using the municipalityUserEmail from the ImageZoomPage
  //                       await logEMeterReadingUpdate(
  //                           documentSnapshot?['cellNumber'] ?? '', // cellNumber
  //                           address, // address
  //                           widget.municipalityUserEmail ?? "Unknown", // municipalityUserEmail
  //                           districtId, // districtId
  //                          municipalityId, // municipalityId
  //                           updateDetails // Map<String, dynamic> details
  //                       );
  //
  //                       Navigator.pop(context);
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                           const SnackBar(
  //                             content: Text(
  //                                 "Meter readings updated successfully"),
  //                             duration: Duration(seconds: 2),
  //                           ));
  //                     } else {
  //                       // Handle the case where account number is not entered
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                           const SnackBar(
  //                             content: Text(
  //                                 "Please fill in all required fields."),
  //                             duration: Duration(seconds: 2),
  //                           ));
  //                       await FirebaseFirestore.instance
  //                           .collection('districts')
  //                           .doc(districtId)
  //                           .collection('municipalities')
  //                           .doc(municipalityId)
  //                           .collection('consumption')
  //                           .doc(formattedMonth)
  //                           .collection('address')
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
                          .selectProperty(property!,
                              handlesWater: handlesWater,
                              handlesElectricity: handlesElectricity);
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

                      // await _propList.doc(documentSnapshot!.id).update({
                      //   "account number": accountNumber,
                      //   "address": address,
                      //   "area code": areaCode,
                      //   "meter number": meterNumber,
                      //   "meter reading": meterReading,
                      //   "water meter number": waterMeterNumber,
                      //   "water meter reading": waterMeterReading,
                      //   "cell number": cellNumber,
                      //   "first name": firstName,
                      //   "last name": lastName,
                      //   "id number": idNumber,
                      //   "user id": userID,
                      // });
                      Map<String, dynamic> updateDetails = {
                        "accountNumber": accountNumber,
                        "address": address,
                        "areaCode": areaCode,
                        "meter_number": meterNumber,
                        "meter_reading": meterReading,
                        "water meter number": waterMeterNumber,
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
                            documentSnapshot?['cellNumber'] ?? '', // cellNumber
                            address, // propertyAddress
                            widget.municipalityUserEmail ??
                                "Unknown", // municipalityUserEmail
                            districtId, // districtId
                            municipalityId, // municipalityId
                            updateDetails // Map<String, dynamic> details
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
                            .collection(isLocalMunicipality
                                ? 'localMunicipalities'
                                : 'districts')
                            .doc(isLocalMunicipality
                                ? municipalityId
                                : districtId)
                            .collection('municipalities')
                            .doc(municipalityId)
                            .collection('consumption')
                            .doc(formattedMonth)
                            .collection('address')
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

  // Future<void> _delete(String users) async {
  //   await _propList?.doc(users).delete();
  //
  //   if (context.mounted) {
  //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //         content: Text('You have successfully deleted an account')));
  //   }
  // }
  Future<void> _delete(String documentId) async {
    try {
      // Ensure _propList is of type CollectionReference, not Query
      if (_propList is CollectionReference) {
        await (_propList as CollectionReference).doc(documentId).delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('You have successfully deleted an account'),
          ));
        }
      } else {
        throw Exception(
            'Invalid reference type: _propList must be a CollectionReference');
      }
    } catch (e) {
      print('Error deleting document: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to delete the account'),
        ));
      }
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
