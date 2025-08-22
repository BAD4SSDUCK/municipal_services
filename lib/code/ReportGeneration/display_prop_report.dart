import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as excel;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' show AnchorElement;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';
import 'package:municipal_services/code/PDFViewer/view_pdf.dart';
class ReportBuilderProps extends StatefulWidget {
  final String? municipalityUserEmail;
  final String? districtId;

  final bool isLocalMunicipality;
  final bool isLocalUser;
   const ReportBuilderProps({super.key, this.municipalityUserEmail,
  this.districtId,

  required this.isLocalMunicipality,
  required this.isLocalUser,});

  @override
  _ReportBuilderPropsState createState() => _ReportBuilderPropsState();
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
String eMeterNumber = ' ';
String accountNumberW = ' ';
String locationGivenW = ' ';
String wMeterNumber = ' ';

String propPhoneNum = ' ';

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

class _ReportBuilderPropsState extends State<ReportBuilderProps>with SingleTickerProviderStateMixin {
  String? userEmail;
  String districtId='';
  String municipalityId='';
  bool _isDataLoaded = false;
  bool isLocalMunicipality = false;
  bool isLocalUser=false;
  bool isLoading=true;
  final ScrollController _scrollControllerTab1 = ScrollController();
  final ScrollController _scrollControllerTab2 = ScrollController();
  final ScrollController _scrollControllerTab3 = ScrollController();
  final FocusNode _focusNodeTab1 = FocusNode();
  final FocusNode _focusNodeTab2 = FocusNode();
  final FocusNode _focusNodeTab3 = FocusNode();
  late TabController _tabController;
  bool handlesWater = false;
  bool handlesElectricity = false;
  bool _utilityTypesLoaded = false;
  Map<String, List<String>> municipalityUtilityMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Add a listener to switch focus when changing tabs
    _tabController.addListener(() {
      if (_tabController.index == 0) {
        _focusNodeTab1.requestFocus();
      } else if (_tabController.index == 1) {
        _focusNodeTab2.requestFocus();
      }else if(_tabController.index == 2) {
        _focusNodeTab3.requestFocus();
      }
    });

    // Initial focus request for Tab 1
    print("Requesting initial focus for Tab 1");
    _focusNodeTab1.requestFocus();

    // Listeners for scroll position
    _scrollControllerTab1.addListener(() {
    });
    _scrollControllerTab2.addListener(() {
    });
    _scrollControllerTab3.addListener(() {
    });
    fetchUserDetails().then((_) async {
      await fetchMunicipalityUtilityTypes(); // Ensures state is set
      if (isLocalUser) {
        await fetchPropertiesForLocalMunicipality();
      } else {
        await fetchMunicipalities();
      }
    });

    _searchController.addListener(_onSearchChanged);
  }


  @override
  void dispose() {
    _scrollControllerTab1.dispose();
    _scrollControllerTab2.dispose();
    _scrollControllerTab3.dispose();
    _focusNodeTab1.dispose();
    _focusNodeTab2.dispose();
    _focusNodeTab3.dispose();
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    searchText;
    _allPropResults;
    _allPropertyReport;
    super.dispose();
  }

  Future<void> fetchUserDetails() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userEmail = user.email ?? '';
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
            districtId = userPathSegments[1];
            municipalityId = userPathSegments[3];
            isLocalMunicipality = false;
          } else if (userPathSegments.contains('localMunicipalities')) {
            municipalityId = userPathSegments[1];
            districtId = '';
            isLocalMunicipality = true;
          }

          isLocalUser = userData['isLocalUser'] ?? false;

          // Fetch properties based on the municipality type
          if (isLocalMunicipality) {
            await fetchPropertiesForLocalMunicipality();
          } else if (!isLocalMunicipality) {
            await fetchPropertiesForAllMunicipalities();
          }

          // Once data is fetched, update state to stop loading
          if (mounted) {
            setState(() {
              _isDataLoaded = true;
              isLoading = false;
            });
          }
        } else {
          print('No user document found.');
        }
      } else {
        print("No current user found.");
      }
    } catch (e) {
      print('Error fetching user details: $e');
      if (mounted) {
        setState(() {
          _isDataLoaded = true;
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchMunicipalityUtilityTypes() async {
    if (isLocalMunicipality) {
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
      final querySnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .get();

      bool foundWater = false;
      bool foundElectricity = false;

      municipalityUtilityMap = {}; // Reset it

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final munId = doc.id;

        if (data.containsKey('utilityType')) {
          final types = List<String>.from(data['utilityType']);
          municipalityUtilityMap[munId] = types;
        }
      }

      handlesWater = foundWater;
      handlesElectricity = foundElectricity;
    }

    print('🗺️ municipalityUtilityMap: $municipalityUtilityMap');


    _utilityTypesLoaded = true; // ✅ Mark as loaded

    if (mounted) setState(() {});
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
    var data = await FirebaseFirestore.instance
        .collection(isLocalMunicipality ? 'localMunicipalities' : 'districts')
        .doc(isLocalMunicipality ? municipalityId : districtId)
        .collection('users')
        .get();
    setState(() {
      _allUserRolesResults = data.docs;
    });
    getUserDetails();
  }


  getUserDetails() async {
    for (var userSnapshot in _allUserRolesResults) {
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

  String searchText = '';

  String formattedDate = DateFormat.MMMM().format(now);

  final CollectionReference _listUserTokens =
  FirebaseFirestore.instance.collection('UserToken');

  final CollectionReference _listNotifications =
  FirebaseFirestore.instance.collection('Notifications');

  final _headerController = TextEditingController();
  final _messageController = TextEditingController();

  List<String> usersNumbers = [];
  List<String> usersTokens = [];
  List<String> usersRetrieve = [];

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  TextEditingController username = TextEditingController();
  TextEditingController title = TextEditingController();
  TextEditingController body = TextEditingController();
  String? mtoken = " ";

  String title2 = "Outstanding Utilities Payment";
  String body2 =
      "Make sure you pay utilities before the end of this month or your services will be disconnected";
  String token = '';
  String notifyToken = '';

  String userAccNum = '';
  String userAddress = '';
  String userAreaCode = '';
  String userWardProp = '';
  String userNameProp = '';
  String userIDnum = '';
  String userPhoneNumber = '';
  String EMeterNum = '';
  String EMeterRead = '';
  String WMeterNum = '';
  String WMeterRead = '';
  String userBill = '';
  String userValid = '';
  String userPhoneToken = '';
  String userRole = '';
  List _allUserRolesResults = [];
  List _allUserTokenResults = [];
  List _allPropResults = [];
  List _allPropReport = [];
  bool visShow = true;
  bool visHide = false;
  bool adminAcc = false;

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
  List _allPropertyReport = [];
  List _regPropertyReport = [];
  List _nonRegPropertyReport = [];
  List<String> municipalities = []; // To hold the list of municipality names
  String? selectedMunicipality = "All Municipalities";

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
            selectedMunicipality = "All Municipalities";
            print("All Municipalities: $selectedMunicipality");

            // Fetch properties for all municipalities initially
            fetchPropertiesForAllMunicipalities();
          });
        }
      } else {
        print("districtId is empty or null.");
        if (mounted) {
          setState(() {
            municipalities = [];
            selectedMunicipality = "All Municipalities";
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

  getUsersTokenStream() async {
    try {
      QuerySnapshot propertiesSnapshot;

      // Fetch properties directly from the properties collection based on the current municipality
      if (isLocalMunicipality) {
        propertiesSnapshot = await FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(municipalityId)
            .collection('properties')
            .get();
      } else {
        propertiesSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('properties')
            .get();
      }

      if (mounted) {
        setState(() {
          _allUserTokenResults = propertiesSnapshot.docs; // This will now hold all property documents with tokens.
        });
      }

      searchResultsList();
    } catch (e) {
      print('Error fetching properties: $e');
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
        var accountNumber=propSnapshot['accountNumber'].toString().toLowerCase();

        if (address.contains(searchLower) ||
            fullName.contains(searchLower) || // Search full name instead of first and last separately
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


  @override
  Widget build(BuildContext context) {
    if (!_isDataLoaded) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
          backgroundColor: Colors.grey[350],
          appBar: AppBar(
            title: const Text(
              'Report Generator',
              style: TextStyle(color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: Colors.green,
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      'Report\nAll',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Tab(
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      'Registered\nApp Users',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Tab(
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      'Non-Registered\nApp Users',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              Column(
                children: [
                  const SizedBox(height: 8),
                   //Report All Tab
                  // Place the dropdown here above the button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child:DropdownButton<String>(
                      value: selectedMunicipality ?? "All Municipalities",
                      hint: const Text('All Municipalities'),
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedMunicipality = newValue;

                          // Check if "Select Municipality" was selected
                          if (selectedMunicipality == null || selectedMunicipality == "All Municipalities") {
                            // Fetch properties for all municipalities
                            fetchPropertiesForAllMunicipalities();
                          } else {
                            // Fetch properties for the selected municipality
                            fetchPropertiesByMunicipality(selectedMunicipality!);
                          }
                        });
                      },
                      items: [
                        const DropdownMenuItem<String>(
                          value: "All Municipalities",
                          child: Text("All Municipalities"),
                        ),
                        ...municipalities.map((String municipality) {
                          return DropdownMenuItem<String>(
                            value: municipality,
                            child: Text(municipality),
                          );
                        }).toList(),
                      ],
                    ),

                  ),

                  const SizedBox(height: 8),

                  // Generate Properties Report button
                  BasicIconButtonGrey(
                    onPress: () async {
                      showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Generate Overall Report"),
                              content: const Text(
                                  "Generating a report will go through all properties and build an excel Spreadsheet!\n\nThis process will take time based on your internet speed.\n\nAre you ready to proceed? This may take a few minutes."),
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
                                        "Now generating report\nPlease wait till prompted to open Spreadsheet!");
                                    reportGeneration();
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
                    labelText: 'Generate Properties Report',
                    fSize: 16,
                    faIcon: const FaIcon(Icons.edit_note_outlined),
                    fgColor: Colors.blue,
                    btSize: const Size(300, 50),
                  ),
                  const SizedBox(height: 4,),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                    child: SearchBar(
                      controller: _searchController,
                      padding: const MaterialStatePropertyAll<EdgeInsets>(
                          EdgeInsets.symmetric(horizontal: 16.0)),
                      leading: const Icon(Icons.search),
                      hintText: "Search",
                      onChanged: (value) async {
                        setState(() {
                          searchText = value;
                        });
                      },
                    ),
                  ),
                  Expanded(child: propertyCard()),
                  const SizedBox(height: 5,),
                ],
              ),
              Column(        //Registered App Users Tab
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child:DropdownButton<String>(
                      value: selectedMunicipality ?? "All Municipalities",
                      hint: const Text('All Municipalities'),
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedMunicipality = newValue;

                          // Check if "Select Municipality" was selected
                          if (selectedMunicipality == null || selectedMunicipality == "All Municipalities") {
                            // Fetch properties for all municipalities
                            fetchPropertiesForAllMunicipalities();
                          } else {
                            // Fetch properties for the selected municipality
                            fetchPropertiesByMunicipality(selectedMunicipality!);
                          }
                        });
                      },
                      items: [
                        const DropdownMenuItem<String>(
                          value: "All Municipalities",
                          child: Text("All Municipalities"),
                        ),
                        ...municipalities.map((String municipality) {
                          return DropdownMenuItem<String>(
                            value: municipality,
                            child: Text(municipality),
                          );
                        }).toList(),
                      ],
                    ),

                  ),

                  const SizedBox(height: 8,),
                  BasicIconButtonGrey(
                    onPress: () async {
                      showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Generate Report of App Users"),
                              content: const Text(
                                  "Generating a report will go through properties with users who are active on this municipal services app and build an excel Spreadsheet!\n\nThis process will take time based on your internet speed.\n\nAre you ready to proceed? This may take a few minutes."),
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
                                        msg: "Now generating report\nPlease wait till prompted to open Spreadsheet!");
                                    registeredReportGeneration();
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
                    labelText: 'Generate Registered Report',
                    fSize: 16,
                    faIcon: const FaIcon(Icons.edit_note_outlined,),
                    fgColor: Colors.blue,
                    btSize: const Size(300, 50),
                  ),
                  const SizedBox(height: 4,),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10.0,10.0,10.0,10.0),
                    child: SearchBar(
                      controller: _searchController,
                      padding: const MaterialStatePropertyAll<EdgeInsets>(
                          EdgeInsets.symmetric(horizontal: 16.0)),
                      leading: const Icon(Icons.search),
                      hintText: "Search",
                      onChanged: (value) async{
                        setState(() {
                          searchText = value;
                          // print('this is the input text ::: $searchText');
                        });
                      },
                    ),
                  ),
                  Expanded(child: userValidCard()),
                  const SizedBox(height: 5,),
                ],
              ),
              Column(  //Non-Registered App Users Tab
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child:DropdownButton<String>(
                      value: selectedMunicipality ?? "All Municipalities",
                      hint: const Text('All Municipalities'),
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedMunicipality = newValue;

                          // Check if "Select Municipality" was selected
                          if (selectedMunicipality == null || selectedMunicipality == "All Municipalities") {
                            // Fetch properties for all municipalities
                            fetchPropertiesForAllMunicipalities();
                          } else {
                            // Fetch properties for the selected municipality
                            fetchPropertiesByMunicipality(selectedMunicipality!);
                          }
                        });
                      },
                      items: [
                        const DropdownMenuItem<String>(
                          value: "All Municipalities",
                          child: Text("All Municipalities"),
                        ),
                        ...municipalities.map((String municipality) {
                          return DropdownMenuItem<String>(
                            value: municipality,
                            child: Text(municipality),
                          );
                        }).toList(),
                      ],
                    ),

                  ),
                  const SizedBox(height: 8,),
                  BasicIconButtonGrey(
                    onPress: () async {
                      showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Generate Report of Inactive Users"),
                              content: const Text(
                                  "Generating a report will go through properties with users not using this municipal services app and build an excel Spreadsheet!\n\nThis process will take time based on your internet speed.\n\nAre you ready to proceed? This may take a few minutes."),
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
                                        msg: "Now generating report\nPlease wait till prompted to open Spreadsheet!");
                                    nonRegisteredReportGeneration();
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
                    labelText: 'Generate Non-registered Report',
                    fSize: 16,
                    faIcon: const FaIcon(Icons.edit_note_outlined,),
                    fgColor: Colors.blue,
                    btSize: const Size(300, 50),
                  ),
                  const SizedBox(height: 4,),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10.0,10.0,10.0,10.0),
                    child: SearchBar(
                      controller: _searchController,
                      padding: const MaterialStatePropertyAll<EdgeInsets>(
                          EdgeInsets.symmetric(horizontal: 16.0)),
                      leading: const Icon(Icons.search),
                      hintText: "Search",
                      onChanged: (value) async{
                        setState(() {
                          searchText = value;
                          // print('this is the input text ::: $searchText');
                        });
                      },
                    ),
                  ),
                  Expanded(child: userInValidCard()),
                  const SizedBox(height: 5,),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => {
              showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Generate Live Report"),
                      content: const Text(
                          "Generating a report will go through all properties and build an excel Spreadsheet!\n\nThis process will take time based on your internet speed.\n\nAre you ready to proceed? This may take a few minutes."),
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
                                msg: "Now generating report\nPlease wait till prompted to open Spreadsheet!");
                            reportGeneration();
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.done,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    );
                  })
            },
            backgroundColor: Colors.green,
            child: const Icon(Icons.file_copy_outlined, color: Colors.white,),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat

      ),
    );
  }

  Widget propertyCard() {
    if (!_utilityTypesLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_allPropResults.isNotEmpty){
      return  GestureDetector(
        onTap: () {
          // Refocus when tapping within the tab content
          _focusNodeTab1.requestFocus();
        },
        child: KeyboardListener(
          focusNode: _focusNodeTab1,
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent) {
              final double pageScrollAmount = _scrollControllerTab1.position.viewportDimension;

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
                itemCount: _allPropResults.length,
                itemBuilder: (context, index) {
                  final munId = _allPropResults[index]['municipalityId'];
                  final utilTypes = municipalityUtilityMap[munId] ?? [];

                  final bool showWater = utilTypes.contains('water');
                  final bool showElectricity = utilTypes.contains('electricity');
                  var property = _allPropResults[index];
                  final data = property.data() as Map<String, dynamic>;
                  userAccNum = _allPropResults[index]['accountNumber'];
                  userAddress = _allPropResults[index]['address'];
                  userAreaCode = _allPropResults[index]['areaCode'].toString();
                  userWardProp = _allPropResults[index]['ward'];
                  userNameProp = '${_allPropResults[index]['firstName']} ${_allPropResults[index]['lastName']}';
                  userIDnum = _allPropResults[index]['idNumber'];
                  userPhoneNumber = _allPropResults[index]['cellNumber'];
                  final EMeterNum = data.containsKey('meter_number') ? data['meter_number'] : 'N/A';
                  final EMeterRead = data.containsKey('meter_reading') ? data['meter_reading'] : 'N/A';
                  WMeterNum = _allPropResults[index]['water_meter_number'];
                  WMeterRead = _allPropResults[index]['water_meter_reading'];
                  userBill = _allPropResults[index]['eBill'];
                  // Check if the property has a token
                  if (property['token'] != null && property['token'].isNotEmpty) {
                    userValid = 'User is registered';
                  } else {
                    userValid = 'User is not yet registered';
                  }

                  // Display outstanding bill information
                  if (property['eBill'] != '' && property['eBill'] != 'R0,000.00' && property['eBill'] != 'R0.00' && property['eBill'] != 'R0') {
                    userBill = 'Utilities bill outstanding: ${property['eBill']}';
                  } else {
                    userBill = 'No outstanding payments';
                  }



                  return Card(
                    margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text('Users Device Details',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 10,),
                          Text('Account Number: $userAccNum',style: const TextStyle(fontSize: 16)),
                          Text('Property: $userAddress',style: const TextStyle(fontSize: 16)),
                          Text('Area Code: $userAreaCode',style: const TextStyle(fontSize: 16)),
                          Text('Ward: $userWardProp',style: const TextStyle(fontSize: 16)),
                          Text('Full Name: $userNameProp',style: const TextStyle(fontSize: 16)),
                          Text('ID Number: $userIDnum',style: const TextStyle(fontSize: 16)),
                          Text('Phone: $userPhoneNumber',style: const TextStyle(fontSize: 16)),
                          Text('Register status: $userValid',style: const TextStyle(fontSize: 16)),

                          if (showElectricity) ...[
                            const SizedBox(height: 10),
                            Text('Electricity Meter Number: $EMeterNum',style: const TextStyle(fontSize: 16)),
                            Text('Electricity Meter Reading: $EMeterRead',style: const TextStyle(fontSize: 16)),
                          ],

                          if (showWater) ...[
                            const SizedBox(height: 10),
                            Text('Water Meter Number: $WMeterNum',style: const TextStyle(fontSize: 16)),
                            Text('Water Meter Reading: $WMeterRead',style: const TextStyle(fontSize: 16)),
                          ],

                          const SizedBox(height: 10),
                          Text(userBill),
                          Visibility(
                            visible: false,
                            child: Text('User Token: $userPhoneToken',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                          ),
                          const SizedBox(height: 5,),
                        ],
                      ),
                    ),
                  );

                }
            ),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(10.0),
      child: Center(
          child: CircularProgressIndicator()),
    );
  }

  Widget userValidCard() {
    if (!_utilityTypesLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_allPropResults.isNotEmpty){
      return GestureDetector(
        onTap: () {
          // Refocus when tapping within the tab content
          _focusNodeTab2.requestFocus();
        },
        child: KeyboardListener(
          focusNode: _focusNodeTab2,
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent) {
              final double pageScrollAmount = _scrollControllerTab2.position.viewportDimension;

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
                itemCount: _allPropResults.length,
                itemBuilder: (context, index) {
                  final munId = _allPropResults[index]['municipalityId'];
                  final utilTypes = municipalityUtilityMap[munId] ?? [];

                  final bool showWater = utilTypes.contains('water');
                  final bool showElectricity = utilTypes.contains('electricity');
                  var property = _allPropResults[index];
                  final data = property.data() as Map<String, dynamic>;
                  userAccNum = _allPropResults[index]['accountNumber'];
                  userAddress = _allPropResults[index]['address'];
                  userAreaCode = _allPropResults[index]['areaCode'].toString();
                  userWardProp = _allPropResults[index]['ward'];
                  userNameProp = '${_allPropResults[index]['firstName']} ${_allPropResults[index]['lastName']}';
                  userIDnum = _allPropResults[index]['idNumber'];
                  userPhoneNumber = _allPropResults[index]['cellNumber'];
                  final EMeterNum = data.containsKey('meter_number') ? data['meter_number'] : 'N/A';
                  final EMeterRead = data.containsKey('meter_reading') ? data['meter_reading'] : 'N/A';
                  WMeterNum = _allPropResults[index]['water_meter_number'];
                  WMeterRead = _allPropResults[index]['water_meter_reading'];
                  userBill = _allPropResults[index]['eBill'];

                  String userValid = 'User is not yet registered';

                  // Check if the user is registered based on the token
                  if (property['token'] != null && property['token'].isNotEmpty) {
                    userValid = 'User is registered';
                  }

                  // Display outstanding bill information
                  if (userBill != '' && userBill != 'R0,000.00' && userBill != 'R0.00' && userBill != 'R0' && userBill != '0') {
                    userBill = 'Utilities bill outstanding: $userBill';
                  } else {
                    userBill = 'No outstanding payments';
                  }

                  // Show the card only if the user is registered
                  if (userValid == 'User is registered') {
                      return Card(
                        margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(
                                child: Text('Users Device Details',
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 10,),
                              Text('Account Number: $userAccNum',style: const TextStyle(fontSize: 16)),
                              Text('Property: $userAddress',style: const TextStyle(fontSize: 16)),
                              Text('Area Code: $userAreaCode',style: const TextStyle(fontSize: 16)),
                              Text('Ward: $userWardProp',style: const TextStyle(fontSize: 16)),
                              Text('Full Name: $userNameProp',style: const TextStyle(fontSize: 16)),
                              Text('ID Number: $userIDnum',style: const TextStyle(fontSize: 16)),
                              Text('Phone: $userPhoneNumber',style: const TextStyle(fontSize: 16)),
                              Text('Register status: $userValid',style: const TextStyle(fontSize: 16)),

                              if (showElectricity) ...[
                                const SizedBox(height: 10),
                                Text('Electricity Meter Number: $EMeterNum',style: const TextStyle(fontSize: 16)),
                                Text('Electricity Meter Reading: $EMeterRead',style: const TextStyle(fontSize: 16)),
                              ],

                              if (showWater) ...[
                                const SizedBox(height: 10),
                                Text('Water Meter Number: $WMeterNum',style: const TextStyle(fontSize: 16)),
                                Text('Water Meter Reading: $WMeterRead',style: const TextStyle(fontSize: 16)),
                              ],
                              Visibility(
                                visible: false,
                                child: Text('User Token: $userPhoneToken',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w400),
                                ),
                              ),
                              const SizedBox(height: 5,),
                            ],
                          ),
                        ),
                      );
                  } else {
                    // Return an empty SizedBox for unregistered users
                    return const SizedBox();
                  }
                },
            ),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(10.0),
      child: Center(
          child: CircularProgressIndicator()),
    );
  }

  Widget userInValidCard() {
    if (!_utilityTypesLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_allPropResults.isNotEmpty){
      return GestureDetector(
        onTap: () {
          // Refocus when tapping within the tab content
          _focusNodeTab3.requestFocus();
        },
        child: KeyboardListener(
          focusNode: _focusNodeTab3,
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent) {
              final double pageScrollAmount = _scrollControllerTab3.position.viewportDimension;

              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                _scrollControllerTab3.animateTo(
                  _scrollControllerTab3.offset + 50,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                _scrollControllerTab3.animateTo(
                  _scrollControllerTab3.offset - 50,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
                _scrollControllerTab3.animateTo(
                  _scrollControllerTab3.offset + pageScrollAmount,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
                _scrollControllerTab3.animateTo(
                  _scrollControllerTab3.offset - pageScrollAmount,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                );
              }
            }
          },
          child: Scrollbar(
            controller: _scrollControllerTab3,
            thickness: 12, // Customize the thickness of the scrollbar
            radius: const Radius.circular(8), // Rounded edges for the scrollbar
            thumbVisibility: true,
            trackVisibility: true, // Makes the track visible as well
            interactive: true,
            child: ListView.builder(
                controller: _scrollControllerTab3,
                itemCount: _allPropResults.length,
                itemBuilder: (context, index) {
                  final munId = _allPropResults[index]['municipalityId'];
                  final utilTypes = municipalityUtilityMap[munId] ?? [];

                  final bool showWater = utilTypes.contains('water');
                  final bool showElectricity = utilTypes.contains('electricity');
                  var property = _allPropResults[index];
                  final data = property.data() as Map<String, dynamic>;
                  userAccNum = _allPropResults[index]['accountNumber'];
                  userAddress = _allPropResults[index]['address'];
                  userAreaCode = _allPropResults[index]['areaCode'].toString();
                  userWardProp = _allPropResults[index]['ward'];
                  userNameProp = '${_allPropResults[index]['firstName']} ${_allPropResults[index]['lastName']}';
                  userIDnum = _allPropResults[index]['idNumber'];
                  userPhoneNumber = _allPropResults[index]['cellNumber'];
                  final EMeterNum = property.get('meter_number');
                  final EMeterRead = property.get('meter_reading');
                  final WMeterNum = data.containsKey('water_meter_number') ? data['water_meter_number'] : 'N/A';
                  final WMeterRead = data.containsKey('water_meter_reading') ? data['water_meter_reading'] : 'N/A';
                  userBill = _allPropResults[index]['eBill'];

                  String userValid = 'User is not yet registered';

                  // Check if the user is registered based on the token
                  if (property['token'] != null && property['token'].isNotEmpty) {
                    userValid = 'User is registered';
                  }

                  // Display outstanding bill information
                  if (userBill != '' && userBill != 'R0,000.00' && userBill != 'R0.00' && userBill != 'R0' && userBill != '0') {
                    userBill = 'Utilities bill outstanding: $userBill';
                  } else {
                    userBill = 'No outstanding payments';
                  }

                  // Show the card only if the user is registered
                  if (userValid == 'User is not yet registered') {
                    return Card(
                      margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text('Users Device Details',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            Text('Account Number: $userAccNum',style: const TextStyle(fontSize: 16)),
                            Text('Property: $userAddress',style: const TextStyle(fontSize: 16)),
                            Text('Area Code: $userAreaCode',style: const TextStyle(fontSize: 16)),
                            Text('Ward: $userWardProp',style: const TextStyle(fontSize: 16)),
                            Text('Full Name: $userNameProp',style: const TextStyle(fontSize: 16)),
                            Text('ID Number: $userIDnum',style: const TextStyle(fontSize: 16)),
                            Text('Phone: $userPhoneNumber',style: const TextStyle(fontSize: 16)),
                            Text('Register status: $userValid',style: const TextStyle(fontSize: 16)),

                            if (showElectricity) ...[
                              const SizedBox(height: 10),
                              Text('Electricity Meter Number: $EMeterNum',style: const TextStyle(fontSize: 16)),
                              Text('Electricity Meter Reading: $EMeterRead',style: const TextStyle(fontSize: 16)),
                            ],

                            if (showWater) ...[
                              const SizedBox(height: 10),
                              Text('Water Meter Number: $WMeterNum',style: const TextStyle(fontSize: 16)),
                              Text('Water Meter Reading: $WMeterRead',style: const TextStyle(fontSize: 16)),
                            ],
                            Visibility(
                              visible: false,
                              child: Text('User Token: $userPhoneToken',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                            ),
                            const SizedBox(height: 5,),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox();
                  }
                }
            ),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(10.0),
      child: Center(
          child: CircularProgressIndicator()),
    );
  }


  Future<void> reportGeneration() async {
    print("Starting report generation...");

    // Refresh utility flags to ensure they are populated
    await fetchMunicipalityUtilityTypes();

    print("handlesWater: $handlesWater, handlesElectricity: $handlesElectricity");
    final excel.Workbook workbook = excel.Workbook();
    final excel.Worksheet sheet = workbook.worksheets[0];

    QuerySnapshot propertiesSnapshot;

    if (selectedMunicipality == null || selectedMunicipality == "All Municipalities") {
      // Fetch properties for all municipalities in the district
      print("Generating report for all municipalities in district: $districtId");
      propertiesSnapshot = await FirebaseFirestore.instance
          .collectionGroup('properties')
          .where('districtId', isEqualTo: districtId)  // Ensure filtering by district
          .get();
    } else {
      // Fetch properties for the selected municipality
      print("Generating report for municipality: $selectedMunicipality");
      propertiesSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(selectedMunicipality)
          .collection('properties')
          .get();
    }

    _allPropertyReport = propertiesSnapshot.docs;

    String column = "A";
    int excelRow = 2;
    int listRow = 0;

    // Add headers
    sheet.getRangeByName('A1').setText('Account #');
    sheet.getRangeByName('B1').setText('Address');
    sheet.getRangeByName('C1').setText('Area Code');
    sheet.getRangeByName('D1').setText('Utilities Bill');
    if (handlesElectricity) {
      sheet.getRangeByName('E1').setText('Electricity Meter Number');
      sheet.getRangeByName('F1').setText('Electricity Meter Reading');
      sheet.getRangeByName('G1').setText('Electricity Image Submitted');
    }
    if (handlesWater) {
      sheet.getRangeByName('H1').setText('Water Meter Number');
      sheet.getRangeByName('I1').setText('Water Meter Reading');
      sheet.getRangeByName('J1').setText('Water Image Submitted');
    }

    sheet.getRangeByName('K1').setText('First Name');
    sheet.getRangeByName('L1').setText('Last Name');
    sheet.getRangeByName('M1').setText('ID Number');
    sheet.getRangeByName('N1').setText('Owner Phone Number');

    for (int i = 0; i < _allPropertyReport.length; i++) {
      var reportSnapshot = _allPropertyReport[i];

      String accountNum = reportSnapshot['accountNumber']?.toString() ?? '';
      String address = reportSnapshot['address']?.toString() ?? '';
      String eBill = reportSnapshot['eBill']?.toString() ?? '';
      String areaCode = reportSnapshot['areaCode']?.toString() ?? '';

      if (handlesElectricity) {
        String electricityMeterNum = reportSnapshot['meter_number']?.toString() ?? '';
        String electricityMeterReading = reportSnapshot['meter_reading']?.toString() ?? '';
        String uploadedLatestE = reportSnapshot['imgStateE']?.toString() ?? '';

        sheet.getRangeByName('E$excelRow').setText(electricityMeterNum);
        sheet.getRangeByName('F$excelRow').setText(electricityMeterReading);
        sheet.getRangeByName('G$excelRow').setText(uploadedLatestE);
      }

      if (handlesWater) {
        String waterMeterNum = reportSnapshot['water_meter_number']?.toString() ?? '';
        String waterMeterReading = reportSnapshot['water_meter_reading']?.toString() ?? '';
        String uploadedLatestW = reportSnapshot['imgStateW']?.toString() ?? '';

        sheet.getRangeByName('H$excelRow').setText(waterMeterNum);
        sheet.getRangeByName('I$excelRow').setText(waterMeterReading);
        sheet.getRangeByName('J$excelRow').setText(uploadedLatestW);
      }

      String firstName = reportSnapshot['firstName']?.toString() ?? '';
      String lastName = reportSnapshot['lastName']?.toString() ?? '';
      String idNumber = reportSnapshot['idNumber']?.toString() ?? '';
      String phoneNumber = reportSnapshot['cellNumber']?.toString() ?? '';

      sheet.getRangeByName('A$excelRow').setText(accountNum);
      sheet.getRangeByName('B$excelRow').setText(address);
      sheet.getRangeByName('C$excelRow').setText(areaCode);
      sheet.getRangeByName('D$excelRow').setText(eBill);
      sheet.getRangeByName('K$excelRow').setText(firstName);
      sheet.getRangeByName('L$excelRow').setText(lastName);
      sheet.getRangeByName('M$excelRow').setText(idNumber);
      sheet.getRangeByName('N$excelRow').setText(phoneNumber);

      excelRow += 1;
    }


    final List<int> bytes = workbook.saveAsStream();

    if (kIsWeb) {
      AnchorElement(href: 'data:application/ocelot-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
        ..setAttribute('download', '$selectedMunicipality Property Reports $formattedDate.xlsx')
        ..click();
    } else {
      final String path = (await getApplicationSupportDirectory()).path;
      final String filename = Platform.isWindows ? '$path\\$selectedMunicipality  Property Reports $formattedDate.xlsx' : '$path/$selectedMunicipality Property Reports $formattedDate.xlsx';
      final File file = File(filename);
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open(filename);
    }

    workbook.dispose();
  }

  Future<void> registeredReportGeneration() async {
    final excel.Workbook workbook = excel.Workbook();
    final excel.Worksheet sheet = workbook.worksheets[0];

    QuerySnapshot propertiesSnapshot;

    if (selectedMunicipality == null || selectedMunicipality == "All Municipalities") {
      // Fetch properties for all municipalities in the district
      print("Generating report for all municipalities in district: $districtId");
      propertiesSnapshot = await FirebaseFirestore.instance
          .collectionGroup('properties')
          .where('districtId', isEqualTo: districtId) // Ensure filtering by district
          .get();
    } else {
      // Fetch properties for the selected municipality
      print("Generating report for municipality: $selectedMunicipality");
      propertiesSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(selectedMunicipality)
          .collection('properties')
          .get();
    }
    print('Total properties fetched: ${propertiesSnapshot.docs.length}');
    // Step 2: Filter the properties to include only registered users (those with a non-empty token)
    List<QueryDocumentSnapshot> registeredProperties = propertiesSnapshot.docs.where((doc) {
      return doc['token'] != null && doc['token'].toString().isNotEmpty;
    }).toList();

    print('Total registered properties: ${registeredProperties.length}');

    if (registeredProperties.isEmpty) {
      print("No registered properties found.");
      return; // Exit if no registered properties are found
    }

    // Step 3: Prepare for the Excel sheet population
    sheet.getRangeByName('A1').setText('Account #');
    sheet.getRangeByName('B1').setText('Address');
    sheet.getRangeByName('C1').setText('Area Code');
    sheet.getRangeByName('D1').setText('Utilities Bill');
    sheet.getRangeByName('H1').setText('Water Meter Number');
    sheet.getRangeByName('I1').setText('Water Meter Reading');
    sheet.getRangeByName('J1').setText('Water Image Submitted');
    sheet.getRangeByName('K1').setText('First Name');
    sheet.getRangeByName('L1').setText('Last Name');
    sheet.getRangeByName('M1').setText('ID Number');
    sheet.getRangeByName('N1').setText('Owner Phone Number');

    int excelRow = 2; // Start from the second row (headers are in the first row)

    // Step 4: Populate the Excel sheet with registered properties
    for (var reportSnapshot in registeredProperties) {
      String accountNum = reportSnapshot['accountNumber']?.toString() ?? '';
      String address = reportSnapshot['address']?.toString() ?? '';
      String eBill = reportSnapshot['eBill']?.toString() ?? '';
      String areaCode = reportSnapshot['areaCode']?.toString() ?? '';
      String waterMeterNum = reportSnapshot['water_meter_number']?.toString() ?? '';
      String waterMeterReading = reportSnapshot['water_meter_reading']?.toString() ?? '';
      String uploadedLatestW = reportSnapshot['imgStateW']?.toString() ?? '';
      String firstName = reportSnapshot['firstName']?.toString() ?? '';
      String lastName = reportSnapshot['lastName']?.toString() ?? '';
      String idNumber = reportSnapshot['idNumber']?.toString() ?? '';
      String phoneNumber = reportSnapshot['cellNumber']?.toString() ?? '';

      print('Populating Excel row $excelRow: $accountNum, $address');

      // Populate the Excel sheet for each registered property
      sheet.getRangeByName('A$excelRow').setText(accountNum);
      sheet.getRangeByName('B$excelRow').setText(address);
      sheet.getRangeByName('C$excelRow').setText(areaCode);
      sheet.getRangeByName('D$excelRow').setText(eBill);
      sheet.getRangeByName('H$excelRow').setText(waterMeterNum);
      sheet.getRangeByName('I$excelRow').setText(waterMeterReading);
      sheet.getRangeByName('J$excelRow').setText(uploadedLatestW);
      sheet.getRangeByName('K$excelRow').setText(firstName);
      sheet.getRangeByName('L$excelRow').setText(lastName);
      sheet.getRangeByName('M$excelRow').setText(idNumber);
      sheet.getRangeByName('N$excelRow').setText(phoneNumber);

      excelRow += 1; // Move to the next row
    }

    // Step 5: Generate the file name for the report
    String reportFileName = selectedMunicipality == null || selectedMunicipality == "All Municipalities"
        ? '(registered users) All Municipalities Property Reports $formattedDate.xlsx'
        : '(registered users) $selectedMunicipality Property Reports $formattedDate.xlsx';

    // Step 6: Save and download the report
    final List<int> bytes = workbook.saveAsStream();

    if (kIsWeb) {
      AnchorElement(
          href:
          'data:application/ocelot-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
        ..setAttribute('download', reportFileName)
        ..click();
    } else {
      final String path = (await getApplicationSupportDirectory()).path;
      final String filename = Platform.isWindows
          ? '$path\\$reportFileName'
          : '$path/$reportFileName';
      final File file = File(filename);
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open(filename);
    }

    workbook.dispose(); // Dispose of the workbook to free up memory
  }

  Future<void> nonRegisteredReportGeneration() async {
    final excel.Workbook workbook = excel.Workbook();
    final excel.Worksheet sheet = workbook.worksheets[0];

    QuerySnapshot propertiesSnapshot;

    // Fetch properties for the selected municipality or all municipalities
    if (selectedMunicipality == null || selectedMunicipality == "All Municipalities") {
      print("Generating report for all municipalities in district: $districtId");
      propertiesSnapshot = await FirebaseFirestore.instance
          .collectionGroup('properties')
          .where('districtId', isEqualTo: districtId)
          .get();
    } else {
      print("Generating report for municipality: $selectedMunicipality");
      propertiesSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(selectedMunicipality)
          .collection('properties')
          .get();
    }

    // Filter properties that have an empty or null 'token' (i.e., non-registered users)
    List<QueryDocumentSnapshot> nonRegisteredProperties = propertiesSnapshot.docs.where((doc) {
      return doc['token'] == null || doc['token'].toString().isEmpty;
    }).toList();

    if (nonRegisteredProperties.isEmpty) {
      print("No non-registered properties found.");
      return; // Exit if no non-registered properties are found
    }

    print('Total non-registered properties: ${nonRegisteredProperties.length}');


    // Prepare the headers for the Excel sheet
    sheet.getRangeByName('A1').setText('Account #');
    sheet.getRangeByName('B1').setText('Address');
    sheet.getRangeByName('C1').setText('Area Code');
    sheet.getRangeByName('D1').setText('Utilities Bill');
    sheet.getRangeByName('H1').setText('Water Meter Number');
    sheet.getRangeByName('I1').setText('Water Meter Reading');
    sheet.getRangeByName('J1').setText('Water Image Submitted');
    sheet.getRangeByName('K1').setText('First Name');
    sheet.getRangeByName('L1').setText('Last Name');
    sheet.getRangeByName('M1').setText('ID Number');
    sheet.getRangeByName('N1').setText('Owner Phone Number');

    // Populate the Excel sheet with non-registered properties
    int excelRow = 2; // Start from row 2 since the headers are in row 1

    for (var reportSnapshot in nonRegisteredProperties) {
      String accountNum = reportSnapshot['accountNumber']?.toString() ?? '';
      String address = reportSnapshot['address']?.toString() ?? '';
      String eBill = reportSnapshot['eBill']?.toString() ?? '';
      String areaCode = reportSnapshot['areaCode']?.toString() ?? '';
      String waterMeterNum = reportSnapshot['water_meter_number']?.toString() ?? '';
      String waterMeterReading = reportSnapshot['water_meter_reading']?.toString() ?? '';
      String uploadedLatestW = reportSnapshot['imgStateW']?.toString() ?? '';
      String firstName = reportSnapshot['firstName']?.toString() ?? '';
      String lastName = reportSnapshot['lastName']?.toString() ?? '';
      String idNumber = reportSnapshot['idNumber']?.toString() ?? '';
      String phoneNumber = reportSnapshot['cellNumber']?.toString() ?? '';

      // Log to make sure data is being processed correctly
      print('Populating Excel row $excelRow for property: $address');

      // Populate Excel sheet
      sheet.getRangeByName('A$excelRow').setText(accountNum);
      sheet.getRangeByName('B$excelRow').setText(address);
      sheet.getRangeByName('C$excelRow').setText(areaCode);
      sheet.getRangeByName('D$excelRow').setText(eBill);
      sheet.getRangeByName('H$excelRow').setText(waterMeterNum);
      sheet.getRangeByName('I$excelRow').setText(waterMeterReading);
      sheet.getRangeByName('J$excelRow').setText(uploadedLatestW);
      sheet.getRangeByName('K$excelRow').setText(firstName);
      sheet.getRangeByName('L$excelRow').setText(lastName);
      sheet.getRangeByName('M$excelRow').setText(idNumber);
      sheet.getRangeByName('N$excelRow').setText(phoneNumber);

      excelRow += 1; // Move to the next row
    }

    final List<int> bytes = workbook.saveAsStream();

    // Save the file and download it
    String reportFileName = '(non-registered users) $selectedMunicipality Property Reports $formattedDate.xlsx';

    if (kIsWeb) {
      AnchorElement(
          href: 'data:application/ocelot-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
        ..setAttribute('download', reportFileName)
        ..click();
    } else {
      final String path = (await getApplicationSupportDirectory()).path;
      final String filename = Platform.isWindows
          ? '$path\\$reportFileName'
          : '$path/$reportFileName';
      final File file = File(filename);
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open(filename);
    }

    workbook.dispose(); // Clean up the workbook to free resources
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

  void openPDF(BuildContext context, File file) => Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
  );
}

