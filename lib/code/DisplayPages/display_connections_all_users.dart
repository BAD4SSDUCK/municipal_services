import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_file/open_file.dart';
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
import 'package:municipal_services/code/MapTools/map_screen_prop.dart';
import 'package:municipal_services/code/PDFViewer/pdf_api.dart';
import 'package:municipal_services/code/PDFViewer/view_pdf.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';
import 'package:municipal_services/code/Reusable/push_notification_message.dart';
import 'package:municipal_services/code/NoticePages/notice_config_screen.dart';
//Connect from municipal side

class UsersConnectionsAll extends StatefulWidget {
  final String? municipalityUserEmail;
  final String? districtId;
  final String municipalityId;
  final bool isLocalMunicipality;
  final bool isLocalUser;
  const UsersConnectionsAll({super.key, this.municipalityUserEmail, this.districtId, required this.municipalityId, required this.isLocalMunicipality, required this.isLocalUser,});

  @override
  _UsersConnectionsAllState createState() => _UsersConnectionsAllState();
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

bool visibilityState1 = true;
bool visibilityState2 = false;
bool adminAcc = false;

String currentMonth = DateFormat.MMMM().format(DateTime.now()); // Example: February
String previousMonth = DateFormat.MMMM().format(DateTime.now().subtract(Duration(days: 30))); // Example: January
Map<String, String> previousMonthReadings = {}; // Store previous readings per address
Map<String, String> currentMonthReadings = {};

final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;

class FireStorageService extends ChangeNotifier{
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async{
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

// Future<Widget> _getImage(BuildContext context, String imageName) async{
//   Image image;
//   final value = await FireStorageService.loadImage(context, imageName);
//
//   final imageUrl = await storageRef.child(imageName).getDownloadURL();
//   ///Check what the app is running on
//   if(defaultTargetPlatform == TargetPlatform.android){
//     image =Image.network(
//       value.toString(),
//       fit: BoxFit.fill,
//       width: double.infinity,
//       height: double.infinity,
//     );
//   }else{
//     image =Image.network(
//       imageUrl,
//       fit: BoxFit.fitHeight,
//       width: double.infinity,
//       height: double.infinity,
//     );
//   }
//   ///android version display image from firebase
//   // image =Image.network(
//   //   value.toString(),
//   //   fit: BoxFit.fill,
//   //   width: double.infinity,
//   //   height: double.infinity,
//   // );
//   return image;
// }

Future<Widget> _getImageW(BuildContext context, String imageName2) async{
  Image image2;
  final value = await FireStorageService.loadImage(context, imageName2);

  final imageUrl = await storageRef.child(imageName2).getDownloadURL();

  ///Check what the app is running on
  if(defaultTargetPlatform == TargetPlatform.android){
    image2 =Image.network(
      value.toString(),
      fit: BoxFit.fill,
      width: double.infinity,
      height: double.infinity,
    );
  }else{
    image2 =Image.network(
      imageUrl,
      fit: BoxFit.fitHeight,
      width: double.infinity,
      height: double.infinity,
    );
  }
  return image2;
}

// final CollectionReference _propList =
// FirebaseFirestore.instance.collection('properties');

class _UsersConnectionsAllState extends State<UsersConnectionsAll> {
 CollectionReference? _propList;
 String? userEmail;
 String districtId='';
 String municipalityId='';
 List<String> usersTokens = [];
 List<String> usersNumbers = [];
 bool isLoading=false;
 bool isLocalMunicipality=false;
 List<String> municipalities = []; // To hold the list of municipality names
 String? selectedMunicipality = "Select Municipality";
 List<DocumentSnapshot> filteredProperties = [];
 bool isLocalUser=true;
 final FocusNode _focusNode = FocusNode();
 final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    _focusNode.requestFocus();
    getUsersTokenStream();
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
        setState(() {}); // Refresh UI after data is loaded
      }
    });

    _searchController.addListener(_onSearchChanged);
    checkAdmin();
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    searchText;
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

 Future<void> getUsersTokenStream() async {
   Set<String> uniqueTokens = {}; // To store unique tokens
   Set<String> uniqueAccountNumbers = {}; // To store corresponding unique account numbers

   try {
     QuerySnapshot propertiesSnapshot = await FirebaseFirestore.instance.collectionGroup('properties').get();

     for (var doc in propertiesSnapshot.docs) {
       if (doc.exists) {
         var data = doc.data() as Map<String, dynamic>?;  // Safely cast the data

         if (data != null) {
           String? token = data['token'] as String?;
           String? accountNumber = data['accountNumber'] as String?;

           if (token != null && accountNumber != null) {
             if (!uniqueTokens.contains(token)) {
               uniqueTokens.add(token);
               uniqueAccountNumbers.add(accountNumber);
             }
           }
         }
       }
     }
      if(mounted) {
        setState(() {
          usersTokens = uniqueTokens.toList();
          usersNumbers = uniqueAccountNumbers.toList();
          isLoading = false; // Loading complete
        });
      }
   } catch (e) {
     print('Error fetching users tokens: $e');
     if(mounted) {
       setState(() {
         isLoading = false;
       });
     }
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

  final CollectionReference _listUserTokens =
  FirebaseFirestore.instance.collection('UserToken');
  //
  // final CollectionReference _listNotifications =
  // FirebaseFirestore.instance.collection('Notifications');
  CollectionReference? _listNotifications;
  final _headerController = TextEditingController();
  final _messageController = TextEditingController();
  late bool _noticeReadController;
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
  bool visShow = true;
  bool visHide = false;
  bool adminAcc = false;

  int numTokens=0;

  String dropdownValue = 'Select Month';
  List<String> dropdownMonths = ['Select Month','January','February','March','April','May','June','July','August','September','October','November','December'];

  final TextEditingController _searchController = TextEditingController();
  List _allPropertyResults = [];
  List _allPropertyReport = [];

 // Future<void> getPropertyStream() async {
 //   try {
 //     QuerySnapshot data;
 //     if (isLocalMunicipality) {
 //       data = await FirebaseFirestore.instance
 //           .collection('localMunicipalities')
 //           .doc(municipalityId)
 //           .collection('properties')
 //           .get();
 //     } else {
 //       data = await FirebaseFirestore.instance
 //           .collection('districts')
 //           .doc(districtId)
 //           .collection('municipalities')
 //           .doc(municipalityId)
 //           .collection('properties')
 //           .get();
 //     }
 //
 //     if (mounted) {
 //       setState(() {
 //         _allPropertyResults = data.docs;
 //       });
 //       searchResultsList();
 //     }
 //   } catch (e) {
 //     print('Error fetching property stream: $e');
 //   }
 // }

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
           if (municipalitiesSnapshot.docs.isNotEmpty) {
             municipalities = municipalitiesSnapshot.docs
                 .map((doc) =>
             doc.id) // Using document ID as the municipality name
                 .toList();
             print("Municipalities list: $municipalities");
           } else {
             print("No municipalities found");
             municipalities = []; // No municipalities found
           }

           // Ensure selectedMunicipality is "Select Municipality" by default
           selectedMunicipality = "Select Municipality";
           print("Selected Municipality: $selectedMunicipality");

           // Fetch properties for all municipalities initially
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
         _allPropertyResults =
             propertiesSnapshot.docs; // Store all fetched properties
         print('State updated, properties stored: ${_allPropertyResults.length}');
       });
     }
     print('Properties fetched: ${_allPropertyResults.length}');
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
           _allPropertyResults =
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
    if(userRole == 'Admin'|| userRole == 'Administrator'){
      adminAcc = true;
    } else {
      adminAcc = false;
    }
  }

 getUsersStream() async {
   try {
     // Use collectionGroup to query all 'users' subcollections across districts and municipalities
     QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
         .collectionGroup('users')
         .get();
     if (mounted) {
       setState(() {
         _allUserRolesResults = usersSnapshot.docs;
       });
     }
     getUserDetails();  // Call this after fetching the user data
   } catch (e) {
     print('Error fetching users: $e');
   }
 }

 getUserDetails() async {
   try {
     for (var userSnapshot in _allUserRolesResults) {
       if (userSnapshot.exists) {
         var userData = userSnapshot.data() as Map<String, dynamic>;
         String user = userData.containsKey('email') ? userData['email'].toString() : '';
         String role = userData.containsKey('userRole') ? userData['userRole'].toString() : 'Unknown';

         if (user == userEmail) {
           userRole = role;
           print('My Role is: $userRole');
           if (mounted) {
             setState(() {
               adminAcc = (userRole == 'Admin' || userRole == 'Administrator');
             });
             break;
           }// Stop loop if the matching user is found
         }
       }
     }
   } catch (e) {
     print('Error fetching user details: $e');
   }
 }


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
  void searchResultsList() {
    var showResults = [];
    if (_searchController.text != "") {
      for (var propSnapshot in _allPropertyResults) {
        var address = propSnapshot['address'].toString().toLowerCase();
        var number = propSnapshot['cellNumber'].toString().toLowerCase();
        if (address.contains(_searchController.text.toLowerCase()) || number.contains(_searchController.text)) {
          showResults.add(propSnapshot);
        }
      }
    } else {
      showResults = List.from(_allPropertyResults);
    }
    if(mounted) {
      setState(() {
        _allPropertyResults = showResults;
      });
    }
  }

 Future<void> openPropertyInvoice(String userNumber, String propertyAddress, String accountNumber, BuildContext context) async {
   String formattedAddress = propertyAddress.replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_');
   String month = DateFormat('MMMM').format(DateTime.now());
   String path = 'pdfs/$month/$userNumber/$formattedAddress/';

   try {
     final storageRef = FirebaseStorage.instance.ref().child(path);
     final listResult = await storageRef.listAll();

     if (listResult.items.isNotEmpty) {
       var item = listResult.items.first;  // Assuming we take the first found PDF
       String url = await item.getDownloadURL();

       // Download the PDF locally
       final directory = await getApplicationDocumentsDirectory();
       final filePath = '${directory.path}/${item.name}';
       final response = await Dio().download(url, filePath);

       if (response.statusCode == 200) {
         File pdfFile = File(filePath);
         openPDF(context, pdfFile);
       } else {
         Fluttertoast.showToast(msg: "Failed to open PDF.");
       }
     } else {
       Fluttertoast.showToast(msg: "No matching document found.");
     }
   } catch (e) {
     Fluttertoast.showToast(msg: "Error opening invoice: $e");
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



 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('All Registered Accounts',style: TextStyle(color: Colors.white),),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.green,
        actions: <Widget>[
          Visibility(
            visible: false,
            child: IconButton(
                onPressed: (){
                  ///Generate Report here
                  reportGeneration();
                },
                icon: const Icon(Icons.file_copy_outlined, color: Colors.white,)),),
        ],
      ),
      body: Column(
        children: [
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
            ),/// Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(10.0,10.0,10.0,10.0),
            child: SearchBar(
              controller: _searchController,
              padding: const MaterialStatePropertyAll<EdgeInsets>(
                  EdgeInsets.symmetric(horizontal: 16.0)),
              leading: const Icon(Icons.search),
              hintText: "Search",
              onChanged: (value) async{
                if(mounted) {
                  setState(() {
                    searchText = value;
                    print('this is the input text ::: $searchText');
                  });
                }
              },
            ),
          ),
          /// Search bar end

          // firebasePropertyCard(_propList),

          Expanded(
            child: propertyCard(),
          )

        ],
      ),
      /// Add new account, removed because it was not necessary for non-staff users.
      //   floatingActionButton: FloatingActionButton(
      //     onPressed: () => _create(),
      //     child: const Icon(Icons.add_home),
      //     backgroundColor: Colors.green,
      //   ),
      //   floatingActionButtonLocation: FloatingActionButtonLocation.endFloat

    );
  }

  Future<void> _notifyThisUser([DocumentSnapshot? documentSnapshot]) async {

    if (documentSnapshot != null) {
      username.text = documentSnapshot.id;
    }

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    void _createBottomSheet() async{
      Future<void> future = Future(() async => showModalBottomSheet(
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
                                      await _listNotifications?.add({
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
              })));
    }

    _createBottomSheet();

  }

 // Future<void> _disconnectThisUser([DocumentSnapshot? documentSnapshot]) async {
 //   if (documentSnapshot != null) {
 //     username.text = documentSnapshot['cellNumber'] ?? 'Unknown';
 //     title.text = 'Utilities Disconnection Warning';
 //     body.text = 'Please complete payment of your utilities on ${documentSnapshot['address'] ?? 'unknown address'}. Failing to do so will result in utilities on your property being cut off in 14 days!';
 //   }
 //
 //   /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
 //   void _createBottomSheet() async {
 //     Future<void> future = Future(() async => showModalBottomSheet(
 //         context: context,
 //         builder: await showModalBottomSheet(
 //             isScrollControlled: true,
 //             context: context,
 //             builder: (BuildContext ctx) {
 //               return StatefulBuilder(
 //                 builder: (BuildContext context, StateSetter setState) {
 //                   return SingleChildScrollView(
 //                     child: Padding(
 //                       padding: EdgeInsets.only(
 //                           top: 20,
 //                           left: 20,
 //                           right: 20,
 //                           bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
 //                       child: Column(
 //                         mainAxisSize: MainAxisSize.min,
 //                         crossAxisAlignment: CrossAxisAlignment.start,
 //                         children: [
 //                           Visibility(
 //                             visible: visShow,
 //                             child: TextField(
 //                               controller: title,
 //                               decoration: const InputDecoration(labelText: 'Message Header'),
 //                             ),
 //                           ),
 //                           Visibility(
 //                             visible: visShow,
 //                             child: TextField(
 //                               controller: body,
 //                               decoration: const InputDecoration(labelText: 'Message'),
 //                             ),
 //                           ),
 //                           const SizedBox(height: 10),
 //                           ElevatedButton(
 //                             child: const Text('Send Notification'),
 //                             onPressed: () async {
 //                               DateTime now = DateTime.now();
 //                               String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);
 //
 //                               final String? tokenSelected = documentSnapshot?['token'];
 //                               final String? userNumber = documentSnapshot?['cellNumber'];
 //                               final String notificationTitle = title.text;
 //                               final String notificationBody = body.text;
 //                               const bool readStatus = false;
 //
 //                               if (notificationTitle.isNotEmpty && notificationBody.isNotEmpty) {
 //                                 await _listNotifications?.add({
 //                                   "token": tokenSelected ?? "Unknown Token",
 //                                   "user": userNumber ?? "Unknown User",
 //                                   "title": notificationTitle,
 //                                   "body": notificationBody,
 //                                   "read": readStatus,
 //                                   "date": formattedDate,
 //                                   "level": 'severe',
 //                                 });
 //
 //                                 // Send push notification
 //                                 if (userNumber != null && userNumber.isNotEmpty) {
 //                                   String token = documentSnapshot?['token'] ?? '';
 //                                   sendPushMessage(token, notificationTitle, notificationBody);
 //                                   Fluttertoast.showToast(msg: 'The user has been sent a notification!', gravity: ToastGravity.CENTER);
 //                                 } else {
 //                                   Fluttertoast.showToast(msg: 'User token is missing!', gravity: ToastGravity.CENTER);
 //                                 }
 //                               } else {
 //                                 Fluttertoast.showToast(msg: 'Please fill in both the header and message fields.', gravity: ToastGravity.CENTER);
 //                               }
 //
 //                               // Clear text fields
 //                               username.text = '';
 //                               title.text = '';
 //                               body.text = '';
 //                               _headerController.text = '';
 //                               _messageController.text = '';
 //
 //                               if (context.mounted) Navigator.of(context).pop();
 //                             },
 //                           ),
 //                         ],
 //                       ),
 //                     ),
 //                   );
 //                 },
 //               );
 //             })));
 //   }
 //
 //   _createBottomSheet();
 // }
 Future<void> _disconnectThisUser([DocumentSnapshot? documentSnapshot]) async {
   // Prepare the text fields based on the documentSnapshot
   if (documentSnapshot != null) {
     username.text = documentSnapshot.id; // Account number from the document
     title.text = 'Utilities Disconnection Warning';
     body.text =
     'Please complete payment of your utilities. Failing to do so will result in utilities on your property being cut off in 14 days!';
   }
   void _showDialog() async {
     await showDialog(
       context: context,
       builder: (BuildContext ctx) {
         return StatefulBuilder(
           builder: (BuildContext context, StateSetter setState) {
             return AlertDialog(
               backgroundColor: Colors.grey[50],
               shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(20.0),
               ),
               title: const Text(
                 'Notify User of Utilities Disconnection',
                 style: TextStyle(
                   fontSize: 20,
                   fontWeight: FontWeight.bold,
                   color: Colors.black,
                 ),
               ),
               content: SizedBox(
                 width: MediaQuery
                     .of(context)
                     .size
                     .width * 0.6,
                 child: SingleChildScrollView(
                   child: Column(
                     mainAxisSize: MainAxisSize.min,
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text(
                         'Notification Details',
                         style: TextStyle(
                           fontSize: 16,
                           color: Colors.black,
                         ),
                       ),
                       const SizedBox(height: 10),
                       TextField(
                         controller: title,
                         style: const TextStyle(color: Colors.black),
                         decoration: const InputDecoration(
                           labelText: 'Message Header',
                           labelStyle: TextStyle(
                             color: Colors.black,
                           ),
                           border: OutlineInputBorder(),
                           focusedBorder: UnderlineInputBorder(
                             borderSide: BorderSide(color: Colors.black),
                           ),
                         ),
                       ),
                       const SizedBox(height: 15),
                       TextField(
                         controller: body,
                         style: const TextStyle(color: Colors.black),
                         decoration: const InputDecoration(
                           labelText: 'Message',
                           labelStyle: TextStyle(
                             color: Colors.black,
                           ),
                           border: OutlineInputBorder(),
                           focusedBorder: UnderlineInputBorder(
                             borderSide: BorderSide(color: Colors.black),
                           ),
                         ),
                         maxLines: 4,
                       ),
                     ],
                   ),
                 ),
               ),
               actions: [
                 ElevatedButton(
                   style: ElevatedButton.styleFrom(
                     foregroundColor: Colors.white,
                     backgroundColor: Colors.green,
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(10.0),
                     ),
                   ),
                   child: const Text('Send Notification'),
                   onPressed: () async {
                     DateTime now = DateTime.now();
                     String formattedDate = DateFormat('yyyy-MM-dd – kk:mm')
                         .format(now);

                     final String tokenSelected = notifyToken; // Token of the user
                     final String userNumber = documentSnapshot?['accountNumber'] ??
                         'Unknown'; // User's account number
                     final String notificationTitle = title.text;
                     final String notificationBody = body.text;

                     // Validate that the title and body are not empty
                     if (notificationTitle.isNotEmpty &&
                         notificationBody.isNotEmpty &&
                         tokenSelected.isNotEmpty) {
                       print('Sending notification to user: $userNumber');

                       // Choose correct Firestore path depending on municipality type
                       CollectionReference notificationsRef;
                       if (isLocalMunicipality) {
                         notificationsRef = FirebaseFirestore.instance
                             .collection('localMunicipalities')
                             .doc(municipalityId)
                             .collection('Notifications');
                       } else {
                         notificationsRef = FirebaseFirestore.instance
                             .collection('districts')
                             .doc(districtId)
                             .collection('municipalities')
                             .doc(municipalityId)
                             .collection('Notifications');
                       }

                       // Save notification to Firestore or database
                       await notificationsRef.add({
                         "token": tokenSelected,
                         "user": userNumber,
                         "title": notificationTitle,
                         "body": notificationBody,
                         "read": false,
                         "date": formattedDate,
                         "level": 'severe',
                       });

                       // Send push notification to the user's token
                       sendPushMessage(
                           tokenSelected, notificationTitle, notificationBody);

                       // Show success message
                       Fluttertoast.showToast(
                         msg: 'The user has been sent the disconnection notice!',
                         gravity: ToastGravity.CENTER,
                       );

                       // Clear the input fields
                       title.clear();
                       body.clear();
                       if (ctx.mounted) Navigator.of(ctx)
                           .pop(); // Close the dialog
                     } else {
                       // Show error if required fields are empty
                       Fluttertoast.showToast(
                         msg: 'Please fill in both the title and message!',
                         gravity: ToastGravity.CENTER,
                       );
                     }
                   },
                 ),
                 ElevatedButton(
                   style: ElevatedButton.styleFrom(
                     foregroundColor: Colors.white,
                     backgroundColor: Colors.red,
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(10.0),
                     ),
                   ),
                   child: const Text('Cancel'),
                   onPressed: () {
                     Navigator.of(ctx).pop();
                   },
                 ),
               ],
             );
           },
         );
       },
     );
   }

   _showDialog();
 }
 // Future<void> _disconnectThisUser({
 //   required String accountNumber,
 //   required String address,
 //   required String cellNumber,
 //   required String token,
 //   required String districtId,
 //   required String municipalityId,
 // }) async {
 //   DateTime now = DateTime.now();
 //   String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);
 //
 //   // Custom message for disconnection warning
 //   String messageBody = "Please complete payment of your utilities on $address. "
 //       "Failing to do so will result in utilities on your property being cut off in 14 days!";
 //   String title = "Utilities Disconnection Warning";
 //
 //   // Add the notification to the correct path in Firestore
 //   await FirebaseFirestore.instance
 //       .collection('districts')
 //       .doc(districtId)
 //       .collection('municipalities')
 //       .doc(municipalityId)
 //       .collection('Notifications')
 //       .add({
 //     'accountNumber': accountNumber,
 //     'address': address,
 //     'cellNumber': cellNumber,
 //     'date': formattedDate,
 //     'message': messageBody,
 //     'status': 'pending_disconnection',
 //     'title': title,
 //     'body': messageBody,
 //     'level': 'severe',
 //     'read': false,
 //     'token': token, // Assuming you fetch the token separately
 //     'user': cellNumber,
 //   });
 //
 //   Fluttertoast.showToast(
 //     msg: 'Disconnection warning sent to $accountNumber at $address',
 //     gravity: ToastGravity.CENTER,
 //   );
 //
 //   // Fetch the user's token if necessary
 //   DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
 //       .collection('users')
 //       .doc(cellNumber) // Assuming `cellNumber` is used as the user ID
 //       .get();
 //
 //   if (userSnapshot.exists) {
 //     String token = userSnapshot['token'];
 //
 //     // Call the bottom sheet to send the notification
 //     _createBottomSheet(token, cellNumber);
 //   } else {
 //     Fluttertoast.showToast(
 //       msg: "User token not found for $cellNumber",
 //       gravity: ToastGravity.CENTER,
 //     );
 //   }
 // }

// Show the bottom sheet and handle notification sending
  void _createBottomSheet(String token, String cellNumber) async {
    Future<void> future = Future(() async => showModalBottomSheet(
      isScrollControlled: true,
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
                            decoration: const InputDecoration(labelText: 'Message Header'),
                          ),
                        ),
                        Visibility(
                          visible: visShow,
                          child: TextField(
                            controller: body,
                            decoration: const InputDecoration(labelText: 'Message'),
                          ),
                        ),
                        const SizedBox(height: 10,),
                        ElevatedButton(
                            child: const Text('Send Notification'),
                            onPressed: () async {
                              DateTime now = DateTime.now();
                              String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);

                              if (title.text.isNotEmpty || body.text.isNotEmpty) {
                                await FirebaseFirestore.instance.collection('notifications').add({
                                  'token': token,
                                  'user': cellNumber,
                                  'title': title.text,
                                  'body': body.text,
                                  'read': false,
                                  'date': formattedDate,
                                  'level': 'severe',
                                });

                                sendPushMessage(token, title.text, body.text);
                                Fluttertoast.showToast(msg: 'Notification sent!', gravity: ToastGravity.CENTER);

                                title.clear();
                                body.clear();

                                if (context.mounted) Navigator.of(context).pop();
                              } else {
                                Fluttertoast.showToast(msg: 'Please fill out both title and message', gravity: ToastGravity.CENTER);
                              }
                            }
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
      ),
    ));
  }

// Send push notification to user
  void sendPushMessage(String token, String title, String body) {
    // Implement push notification logic here
    // e.g., using Firebase Cloud Messaging (FCM) or another notification service
    print('Sending push notification to token: $token');
  }


  Widget firebasePropertyCard(CollectionReference<Object?> propertiesDataStream) {
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
                  var propertyData = _allPropertyResults[index].data() as Map<String, dynamic>;

                  String accountNumber = propertyData['accountNumber'];
                  String address = propertyData['address'];
                  String meterNumber = propertyData['meter_number'];
                  String waterMeterNumber = propertyData['water_meter_number'];
                  String cellNumber = propertyData['cellNumber'];
                  String billMessage;///A check for if payment is outstanding or not
                  if(documentSnapshot['eBill'] != '' ||
                      documentSnapshot['eBill'] != 'R0,000.00' ||
                      documentSnapshot['eBill'] != 'R0.00' ||
                      documentSnapshot['eBill'] != 'R0' ||
                      documentSnapshot['eBill'] != '0'
                  ){
                    billMessage = 'Utilities bill outstanding: ${documentSnapshot['eBill']}';
                  } else {
                    billMessage = 'No outstanding payments';
                  }

                  if(((documentSnapshot['address'].trim()).toLowerCase()).contains((_searchController.text.trim()).toLowerCase())){
                    return Card(
                      margin: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 10),
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
                            const SizedBox(height: 10,),
                            Text(
                              'Account Number: ${documentSnapshot['accountNumber']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Street Address: ${documentSnapshot['address']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Area Code: ${documentSnapshot['areaCode']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            // Text(
                            //   'Meter Number: ${documentSnapshot['meter_number']}',
                            //   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            // ),
                            // const SizedBox(height: 5,),
                            // Text(
                            //   'Meter Reading: ${documentSnapshot['meter_reading']}',
                            //   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            // ),
                            // const SizedBox(height: 5,),
                            Text(
                              'Water Meter Number: ${documentSnapshot['water_meter_number']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Water Meter Reading: ${documentSnapshot['water_meter_reading']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Phone Number: ${documentSnapshot['cellNumber']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 30,),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                   /* BasicIconButtonGrey(
                                      onPress: () async {
                                        Fluttertoast.showToast(msg: "Now opening the statement!\nPlease wait a few seconds!");

                                        // Extract values directly from the _allPropResults[index]
                                        String userNumber = _allPropertyResults[index]['cellNumber'];
                                        String propertyAddress = _allPropertyResults[index]['address'];
                                        String accountNumber = _allPropertyResults[index]['accountNumber'];

                                        print('User Number: $userNumber');
                                        print('Property Address: $propertyAddress');
                                        print('Account Number: $accountNumber');

                                        // Call the method to open the invoice PDF
                                        try {
                                          await openPropertyInvoice(userNumber, propertyAddress, accountNumber, context);
                                          Fluttertoast.showToast(msg: "Successful!");
                                        } catch (e) {
                                          Fluttertoast.showToast(msg: "Unable to open statement: $e");
                                        }
                                      },
                                      labelText: 'Invoice',
                                      fSize: 16,
                                      faIcon: const FaIcon(Icons.picture_as_pdf,),
                                      fgColor: Colors.orangeAccent,
                                      btSize: const Size(100, 38),
                                    ),*/
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        accountNumberAll = documentSnapshot['accountNumber'];
                                        locationGivenAll = documentSnapshot['address'];

                                        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        //     content: Text('$accountNumber $locationGiven ')));

                                        Navigator.push(context,
                                            MaterialPageRoute(builder: (context) => MapScreenProp(propAddress: locationGivenAll, propAccNumber: accountNumberAll,)
                                              //MapPage()
                                            ));
                                      },
                                      labelText: 'Map',
                                      fSize: 16,
                                      faIcon: const FaIcon(Icons.map,),
                                      fgColor: Colors.green,
                                      btSize: const Size(100, 38),
                                    ),
                                    const SizedBox(width: 5,),
                                  ],
                                ),
                                const SizedBox(height: 5,),
                                Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        BasicIconButtonGrey(
                                          onPress: () async {
                                            String cell = documentSnapshot['cellNumber'];

                                            Fluttertoast.showToast(msg: "The owner must be given a notification",);

                                            showDialog(
                                                barrierDismissible: false,
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: const Text("Notify Utilities Disconnection"),
                                                    content: const Text("This will notify the owner of the property of their water or electricity being disconnected in 14 days!\n\nAre you sure?"),
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
                                                          await _disconnectThisUser(
                                                             // Pass the correct municipalityId
                                                          );
                                                          Navigator.pop(context);
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
                                          labelText: 'Disconnection',
                                          fSize: 16,
                                          faIcon: const FaIcon(Icons.warning_amber,),
                                          fgColor: Colors.amber,
                                          btSize: const Size(100, 38),
                                        ),

                                      ],
                                    ),
                                  ],
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
                      decoration: const InputDecoration(labelText: 'Account Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Street Address'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      keyboardType:
                      const TextInputType.numberWithOptions(),
                      controller: _areaCodeController,
                      decoration: const InputDecoration(labelText: 'Area Code',),
                    ),
                  ),
                  // Visibility(
                  //   visible: visibilityState1,
                  //   child: TextField(
                  //     controller: _meterNumberController,
                  //     decoration: const InputDecoration(labelText: 'Meter Number'),
                  //   ),
                  // ),
                  // Visibility(
                  //   visible: visibilityState1,
                  //   child: TextField(
                  //     controller: _meterReadingController,
                  //     decoration: const InputDecoration(labelText: 'Meter Reading'),
                  //   ),
                  // ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _waterMeterController,
                      decoration: const InputDecoration(labelText: 'Water Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _waterMeterReadingController,
                      decoration: const InputDecoration(labelText: 'Water Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _cellNumberController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
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
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(labelText: 'Account Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Street Address'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      keyboardType:
                      const TextInputType.numberWithOptions(),
                      controller: _areaCodeController,
                      decoration: const InputDecoration(labelText: 'Area Code',),
                    ),
                  ),
                  // Visibility(
                  //   visible: visibilityState2,
                  //   child: TextField(
                  //     controller: _meterNumberController,
                  //     decoration: const InputDecoration(labelText: 'Electricity Meter Number'),
                  //   ),
                  // ),
                  // Visibility(
                  //   visible: visibilityState1,
                  //   child: TextField(
                  //     maxLength: 5,
                  //     maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  //     keyboardType: TextInputType.number,
                  //     controller: _meterReadingController,
                  //     decoration: const InputDecoration(labelText: 'Electricity Meter Reading'),
                  //   ),
                  // ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _waterMeterController,
                      decoration: const InputDecoration(labelText: 'Water Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      maxLength: 8,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      keyboardType: TextInputType.number,
                      controller: _waterMeterReadingController,
                      decoration: const InputDecoration(labelText: 'Water Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _cellNumberController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
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

                      if (accountNumber.isNotEmpty) {
                        await FirebaseFirestore.instance
                            .collection('districts')
                            .doc(districtId)
                            .collection('municipalities')
                            .doc(municipalityId)
                            .collection('properties')
                            .doc(documentSnapshot!.id)
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

                        if(context.mounted)Navigator.of(context).pop();
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

  Future<void> _updateE([DocumentSnapshot? documentSnapshot]) async {
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
                    visible: visibilityState2,
                    child: TextField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(labelText: 'Account Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Street Address'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      keyboardType:
                      const TextInputType.numberWithOptions(),
                      controller: _areaCodeController,
                      decoration: const InputDecoration(labelText: 'Area Code',),
                    ),
                  ),
                  // Visibility(
                  //   visible: visibilityState2,
                  //   child: TextField(
                  //     controller: _meterNumberController,
                  //     decoration: const InputDecoration(labelText: 'Electricity Meter Number'),
                  //   ),
                  // ),
                  // Visibility(
                  //   visible: visibilityState1,
                  //   child: TextField(
                  //     maxLength: 5,
                  //     maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  //     keyboardType: TextInputType.number,
                  //     controller: _meterReadingController,
                  //     decoration: const InputDecoration(labelText: 'Electricity Meter Reading'),
                  //   ),
                  // ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _waterMeterController,
                      decoration: const InputDecoration(labelText: 'Water Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      maxLength: 8,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      keyboardType: TextInputType.number,
                      controller: _waterMeterReadingController,
                      decoration: const InputDecoration(labelText: 'Water Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _cellNumberController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
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

  Future<void> _updateW(String districtId, String municipalityId,[DocumentSnapshot? documentSnapshot]) async {
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
                    visible: visibilityState2,
                    child: TextField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(labelText: 'Account Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Street Address'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      keyboardType:
                      const TextInputType.numberWithOptions(),
                      controller: _areaCodeController,
                      decoration: const InputDecoration(labelText: 'Area Code',),
                    ),
                  ),
                  // Visibility(
                  //   visible: visibilityState2,
                  //   child: TextField(
                  //     controller: _meterNumberController,
                  //     decoration: const InputDecoration(labelText: 'Electricity Meter Number'),
                  //   ),
                  // ),
                  // Visibility(
                  //   visible: visibilityState2,
                  //   child: TextField(
                  //     maxLength: 5,
                  //     maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  //     keyboardType: TextInputType.number,
                  //     controller: _meterReadingController,
                  //     decoration: const InputDecoration(labelText: 'Electricity Meter Reading'),
                  //   ),
                  // ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _waterMeterController,
                      decoration: const InputDecoration(labelText: 'Water Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      maxLength: 8,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      keyboardType: TextInputType.number,
                      controller: _waterMeterReadingController,
                      decoration: const InputDecoration(labelText: 'Water Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _cellNumberController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
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
                        await FirebaseFirestore.instance
                            .collection('districts')
                            .doc(districtId)
                            .collection('municipalities')
                            .doc(municipalityId)
                            .collection('properties')
                            .doc(documentSnapshot!.id)
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

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have successfully deleted an account')));
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
                var propertyData = _allPropertyResults[index].data() as Map<String, dynamic>;

                String accountNumber = propertyData['accountNumber'];
                String address = propertyData['address'];
                String waterMeterNumber = propertyData['water_meter_number'];
                String cellNumber = propertyData['cellNumber'];
                bool isLocalMunicipality = propertyData['isLocalMunicipality'] ?? false;
                String districtId = propertyData['districtId'] ?? '';
                String municipalityId = propertyData['municipalityId'] ?? '';
                String bill=propertyData['eBill'];
                String billMessage;

                // Check if payment is outstanding
                if (_allPropertyResults[index]['eBill'] != '' ||
                    _allPropertyResults[index]['eBill'] != 'R0,000.00' ||
                    _allPropertyResults[index]['eBill'] != 'R0.00' ||
                    _allPropertyResults[index]['eBill'] != 'R0' ||
                    _allPropertyResults[index]['eBill'] != '0') {
                  billMessage = 'Utilities bill outstanding: ${_allPropertyResults[index]['eBill']}';
                } else {
                  billMessage = 'No outstanding payments';
                }

                return Card(
                  margin: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 10),
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
                          'Account Number: $accountNumber',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Street Address: $address',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Area Code: ${_allPropertyResults[index]['areaCode']}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Water Meter Number: $waterMeterNumber',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Previous Month ($previousMonth) Reading: ${previousMonthReadings[_allPropertyResults[index]['address']] ?? "N/A"}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Water Meter Reading for $currentMonth: ${currentMonthReadings[_allPropertyResults[index]['address']] ?? "N/A"}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Phone Number: $cellNumber',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          'Outstanding amount: $bill',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 30),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                               /* BasicIconButtonGrey(
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
                                    Fluttertoast.showToast(
                                        msg: "Now opening the statement!\nPlease wait a few seconds!");

                                    try {
                                      await openPropertyInvoice(cellNumber, address, accountNumber, context);
                                      Fluttertoast.showToast(msg: "Successful!");
                                    } catch (e) {
                                      Fluttertoast.showToast(msg: "Unable to open statement: $e");
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
                                    accountNumberAll = accountNumber;
                                    locationGivenAll = address;

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MapScreenProp(
                                          propAddress: locationGivenAll,
                                          propAccNumber: accountNumberAll,
                                        ),
                                      ),
                                    );
                                  },
                                  labelText: 'Map',
                                  fSize: 16,
                                  faIcon: const FaIcon(Icons.map),
                                  fgColor: Colors.green,
                                  btSize: const Size(100, 38),
                                ),
                                const SizedBox(width: 5),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
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
                                        Fluttertoast.showToast(
                                            msg: "The owner must be given a notification");

                                        showDialog(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: const Text("Notify Utilities Disconnection"),
                                              content: const Text(
                                                  "This will notify the owner of the property of their water or electricity being disconnected in 14 days!\n\nAre you sure?"),
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
                                                    DateTime now = DateTime.now();
                                                    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm')
                                                        .format(now);

                                                    String token = usersTokens[index]; // Use the token for this specific property

                                                    // Add the disconnection notice to Firestore based on whether it's local or district municipality
                                                    CollectionReference notificationsRef;

                                                    if (isLocalMunicipality) {
                                                      notificationsRef = FirebaseFirestore.instance
                                                          .collection('localMunicipalities')
                                                          .doc(municipalityId)
                                                          .collection('Notifications');
                                                    } else {
                                                      notificationsRef = FirebaseFirestore.instance
                                                          .collection('districts')
                                                          .doc(districtId)
                                                          .collection('municipalities')
                                                          .doc(municipalityId)
                                                          .collection('Notifications');
                                                    }

                                                    // Adding debug print statements
                                                    print('Notification Path: ${notificationsRef.path}');
                                                    print('Token used: $token');
                                                    print('Sending notification to accountNumber: $accountNumber');
                                                    print('Property Address: $address');

                                                    try {
                                                      DocumentReference notificationDocRef =
                                                      await notificationsRef.add({
                                                        'token': token,
                                                        'user': accountNumber,
                                                        'title': 'Utilities Disconnection Warning',
                                                        'body':
                                                        'Please complete payment of your utilities on property $address. Failing to do so will result in utilities on your property being cut off in 14 days!',
                                                        'read': false,
                                                        'date': formattedDate,
                                                        'level': 'severe',
                                                      });

                                                      String generatedNotificationId = notificationDocRef.id;
                                                      print(
                                                          'Notification added to Firestore with auto-generated ID: $generatedNotificationId at path: ${notificationsRef.path}/$generatedNotificationId');

                                                      // Send push notification
                                                      sendPushMessage(
                                                          token,
                                                          'Utilities Disconnection Warning',
                                                          'Please complete payment of your utilities on property $address. Failing to do so will result in utilities on your property being cut off in 14 days!');

                                                      Fluttertoast.showToast(
                                                          msg: 'Disconnection notice sent!',
                                                          gravity: ToastGravity.CENTER);

                                                      Navigator.pop(context); // Close dialog
                                                    } catch (e) {
                                                      print('Error adding notification to Firestore: $e');
                                                      Fluttertoast.showToast(
                                                          msg: 'Error sending notification: $e');
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
                                      labelText: 'Disconnection',
                                      fSize: 16,
                                      faIcon: const FaIcon(Icons.warning_amber),
                                      fgColor: Colors.amber,
                                      btSize: const Size(100, 38),
                                    ),
                                  ],
                                ),
                              ],
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

  Future<void> reportGeneration() async {
    final excel.Workbook workbook = excel.Workbook();
    final excel.Worksheet sheet = workbook.worksheets[0];

    List<DocumentSnapshot> allPropertyDocs = [];

    // Get all districts
    var districtsSnapshot = await FirebaseFirestore.instance.collection('districts').get();

    // Iterate through each district
    for (var districtDoc in districtsSnapshot.docs) {
      // Get all municipalities in the district
      var municipalitiesSnapshot = await districtDoc.reference.collection('municipalities').get();

      // Iterate through each municipality
      for (var municipalityDoc in municipalitiesSnapshot.docs) {
        // Get all properties in the municipality
        var propertiesSnapshot = await municipalityDoc.reference.collection('properties').get();
        allPropertyDocs.addAll(propertiesSnapshot.docs);
      }
    }

    // Set state with all properties
    if(mounted) {
      setState(() {
        _allPropertyReport = allPropertyDocs;
      });
    }
    // Populate Excel sheet with property data
    int rowIndex = 1;
    for (var reportSnapshot in _allPropertyReport) {
      var address = reportSnapshot['address'].toString();
      sheet.getRangeByName('A$rowIndex').setText(address);
      rowIndex++;
    }

    final Directory? directory = await getExternalStorageDirectory();
    final String? path = directory?.path;
    final File file = File('$path/Msunduzi_Property_Reports.xlsx');

    final List<int> bytes = workbook.saveAsStream();
    await file.writeAsBytes(bytes, flush: true);
    await OpenFile.open('$path/Msunduzi_Property_Reports.xlsx');

    File('Msunduzi_Property_Reports.xlsx').writeAsBytes(bytes);

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

  ///pdf view loader getting file name onPress/onTap that passes pdf filename to this class.
  void openPDF(BuildContext context, File file) => Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
  );
}