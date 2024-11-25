import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:universal_html/html.dart' show AnchorElement;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as excel;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:municipal_services/code/PDFViewer/view_pdf.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';


class ReportBuilderCaptured extends StatefulWidget {
  final String? municipalityUserEmail;
  final String? districtId;

  final bool isLocalMunicipality;
  final bool isLocalUser;
  const ReportBuilderCaptured({super.key, this.municipalityUserEmail, this.districtId, required this.isLocalMunicipality, required this.isLocalUser,});

  @override
  _ReportBuilderCapturedState createState() => _ReportBuilderCapturedState();
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
bool imgUploadCheck = false;

final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;

class FireStorageService extends ChangeNotifier{
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async{
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

class _ReportBuilderCapturedState extends State<ReportBuilderCaptured> with SingleTickerProviderStateMixin{
  String? userEmail;
  String districtId='';
  String municipalityId='';
  bool _isDataLoaded = false;
  bool isLocalMunicipality = false;
  bool isLocalUser=false;
  bool isLoading=true;
  final ScrollController _scrollControllerTab1 = ScrollController();
  final ScrollController _scrollControllerTab2 = ScrollController();
  final FocusNode _focusNodeTab1 = FocusNode();
  final FocusNode _focusNodeTab2 = FocusNode();
  late TabController _tabController;
  List<String> municipalities = []; // To hold the list of municipality names
  String? selectedMunicipality = "All Municipalities";

  @override
  void initState() {

    _tabController = TabController(length: 2, vsync: this);

    // Add a listener to switch focus when changing tabs
    _tabController.addListener(() {
      if (_tabController.index == 0) {
        _focusNodeTab1.requestFocus();
      } else if (_tabController.index == 1) {
        _focusNodeTab2.requestFocus();
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
    fetchUserDetails().then((_) {
      if (isLocalUser) {
        // For local municipality users, fetch properties only for their municipality
        fetchPropertiesForLocalMunicipality();
      } else {
        // For district-level users, fetch properties for all municipalities
        fetchMunicipalities(); // Fetch municipalities after user details are loaded
      }
    });
    getUsersTokenStream();
    checkAdmin();
    _searchController.addListener(_onSearchChanged);
    super.initState();
  }

  @override
  void dispose() {
    _scrollControllerTab1.dispose();
    _scrollControllerTab2.dispose();
    _focusNodeTab1.dispose();
    _focusNodeTab2.dispose();
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

          // Fetch users in this district or municipality
          QuerySnapshot userCollectionSnapshot = await FirebaseFirestore.instance
              .collection(isLocalMunicipality ? 'localMunicipalities' : 'districts')
              .doc(isLocalMunicipality ? municipalityId : districtId)
              .collection('users')
              .get();
          if(mounted) {
            setState(() {
              _allUserRolesResults = userCollectionSnapshot.docs;
            });
            getUserDetails();
          }
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

  void checkAdmin() {
    fetchUserDetails();
    if(userRole == 'Admin'|| userRole == 'Administrator'){
      adminAcc = true;
    } else {
      adminAcc = false;
    }
  }


  // getUsersStream() async {
  //   var data = await FirebaseFirestore.instance
  //       .collection(isLocalMunicipality ? 'localMunicipalities' : 'districts')
  //       .doc(isLocalMunicipality ? municipalityId : districtId)
  //       .collection('users')
  //       .get();
  //   setState(() {
  //     _allUserRolesResults = data.docs;
  //   });
  //   getUserDetails();
  // }

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

  // Future<void> fetchPropertiesForAllMunicipalities() async {
  //   try {
  //     QuerySnapshot propertiesSnapshot;
  //
  //     // Check if no specific municipality is selected
  //     if (selectedMunicipality == null || selectedMunicipality == "All Municipalities") {
  //       // Fetch properties for all municipalities in the district
  //       print("Fetching properties for all municipalities under district: $districtId");
  //       propertiesSnapshot = await FirebaseFirestore.instance
  //           .collectionGroup('properties')
  //           .where('districtId', isEqualTo: districtId) // Ensure filtering by district
  //           .get();
  //
  //       if (mounted) {
  //         setState(() {
  //           _allPropResults = propertiesSnapshot.docs;
  //           print('Fetched ${_allPropResults.length} properties.');
  //         });
  //       }
  //     } else {
  //       // Fetch properties for the selected municipality
  //       print("Fetching properties for municipality: $selectedMunicipality");
  //       propertiesSnapshot = await FirebaseFirestore.instance
  //           .collection('districts')
  //           .doc(districtId)
  //           .collection('municipalities')
  //           .doc(selectedMunicipality)
  //           .collection('properties')
  //           .get();
  //
  //       if (mounted) {
  //         setState(() {
  //           _allPropResults = propertiesSnapshot.docs;
  //           print('Properties fetched for $selectedMunicipality: ${_allPropResults.length}');
  //         });
  //       }
  //     }
  //   } catch (e) {
  //     print('Error fetching properties: $e');
  //   }
  // }

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

  // Future<void> fetchPropertiesByMunicipality(String municipality) async {
  //   try {
  //     // Fetch properties for the selected municipality
  //     QuerySnapshot propertiesSnapshot = await FirebaseFirestore.instance
  //         .collection('districts')
  //         .doc(districtId)
  //         .collection('municipalities')
  //         .doc(municipality)
  //         .collection('properties')
  //         .get();
  //
  //     // Log the properties fetched
  //     print(
  //         'Properties fetched for $municipality: ${propertiesSnapshot.docs.length}');
  //     if (mounted) {
  //       setState(() {
  //         _allPropResults =
  //             propertiesSnapshot.docs; // Store filtered properties
  //         print(
  //             "Number of properties fetched: ${_allPropResults.length}"); // Debugging to ensure properties are set
  //       });
  //     }
  //   } catch (e) {
  //     print('Error fetching properties for $municipality: $e');
  //   }
  // }
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

  Future<void> fetchPropertiesByMunicipality(String municipality) async {
    try {
      if (municipality == "All Municipalities") {
        await fetchPropertiesForAllMunicipalities();
      } else {
        QuerySnapshot propertiesSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipality)
            .collection('properties')
            .get();

        setState(() {
          _allPropResults = propertiesSnapshot.docs;
        });
      }
    } catch (e) {
      print('Error fetching properties for $municipality: $e');
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

  String userAccNum = '';
  String userAddress = '';
  String userAreaCode = '';
  String userWardProp = '';
  String userNameProp = '';
  String userIDnum = '';
  String userPhoneNumber = '';
  // String EMeterNum =  '';
  // String EMeterRead =  '';
  // bool EMeterCap = false;
  String WMeterNum =  '';
  String WMeterRead =  '';
  bool WMeterCap = false;
  String userBill =  '';
  String userValid = '';
  String userPhoneToken = '';
  String userRole = '';
  List _allUserRolesResults = [];
  List _allUserTokenResults = [];
  List _allPropResults = [];
  bool visShow = true;
  bool visHide = false;
  bool adminAcc = false;
  int numTokens=0;

  String dropdownValue = 'Select Month';
  List<String> dropdownMonths = ['Select Month','January','February','March','April','May','June','July','August','September','October','November','December'];

  final TextEditingController _searchController = TextEditingController();
  List _allPropertyReport = [];

  getPropertyStream() async{
    var data =await FirebaseFirestore.instance
        .collection('districts')
        .doc(districtId)
        .collection('municipalities')
        .doc(municipalityId)
        .collection('properties')
        .get();

    setState(() {
      _allPropResults = data.docs;
    });
    searchResultsList();
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[350],
        appBar: AppBar(
          title: const Text('Report Generator',style: TextStyle(color: Colors.white),),
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.green,
          actions: <Widget>[
            Visibility(
              visible: false,
              child: IconButton(
                  onPressed: (){
                    ///Generate Report here
                    showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Generate Live Report"),
                            content: const Text("Generating a report will go through all properties and build an excel Spreadsheet!\n\nThis process will take time based on your internet speed.\n\nAre you ready to proceed? This may take a few minutes."),
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
                                  Fluttertoast.showToast(msg: "Now generating report\nPlease wait till prompted to open Spreadsheet!");
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
                  icon: const Icon(Icons.file_copy_outlined, color: Colors.white,)),),
          ],
          bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(
                  child: Container(alignment: Alignment.center,
                    child: const Text('Submitted\nCaptures', textAlign: TextAlign.center,),),
                ),
                Tab(
                  child: Container(alignment: Alignment.center,
                    child: const Text('Outstanding\nCaptures', textAlign: TextAlign.center,),),
                ),
              ]
          ),
        ),
          body: TabBarView(
            controller: _tabController,
            children: [
              ///Tab for captures
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10), // Add padding on both sides for better alignment
                    child: SizedBox(
                      width: double.infinity, // Makes the dropdown take the full width
                      child: DropdownButton<String>(
                        value: selectedMunicipality,
                        icon: const Icon(Icons.arrow_downward, color: Colors.grey),
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black), // Style for the selected item
                        isExpanded: true, // Expands the dropdown to fill the width
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedMunicipality = newValue!;
                            fetchPropertiesByMunicipality(selectedMunicipality!);
                          });
                        },
                        items: <String>['All Municipalities', ...municipalities]
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: const TextStyle(
                                fontSize: 16, // Adjust font size as needed
                                fontWeight: FontWeight.bold, // Make the text bold
                                color: Colors.black, // Adjust color as needed
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    ),
                  ),
                  const SizedBox(height: 8,),

                  BasicIconButtonGrey(
                  onPress: () async {
                    ///Generate Report here
                    showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Generate Captured Readings Report"),
                            content: const Text(
                                "Generating a report will go through properties that have taken readings for this month and build an excel Spreadsheet!\n\nThis process will take time based on your internet speed.\n\nAre you ready to proceed? This may take a few minutes."),
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
                                  capReportGeneration();
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
                  labelText: 'Generate Captures Report',
                  fSize: 16,
                  faIcon: const FaIcon(Icons.edit_note_outlined,),
                  fgColor: Colors.blue,
                  btSize: const Size(300, 50),
                ),
                const SizedBox(height: 4,),

                /// Search bar
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
                /// Search bar end

                Expanded(child: propertyCapCard(),),

                const SizedBox(height: 5,),
              ],
            ),

            ///Tab for un-captured
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10), // Add padding on both sides for better alignment
                  child: SizedBox(
                    width: double.infinity, // Makes the dropdown take the full width
                    child: DropdownButton<String>(
                      value: selectedMunicipality,
                      icon: const Icon(Icons.arrow_downward, color: Colors.grey),
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Colors.black), // Style for the selected item
                      isExpanded: true, // Expands the dropdown to fill the width
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedMunicipality = newValue!;
                          fetchPropertiesByMunicipality(selectedMunicipality!);
                        });
                      },
                      items: <String>['All Municipalities', ...municipalities]
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: 16, // Adjust font size as needed
                              fontWeight: FontWeight.bold, // Make the text bold
                              color: Colors.black, // Adjust color as needed
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  ),
                ),
                const SizedBox(height: 8,),
                BasicIconButtonGrey(
                  onPress: () async {
                    ///Generate Report here
                    showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Generate Outstanding Readings Report"),
                            content: const Text(
                                "Generating this report will go through all properties that have not captured readings for this month and build an excel Spreadsheet!\n\nThis process will take time based on your internet speed.\n\nAre you ready to proceed? This may take a few minutes."),
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
                                  noCapReportGeneration();
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
                  labelText: 'Generate Non-Captured Report',
                  fSize: 16,
                  faIcon: const FaIcon(Icons.edit_note_outlined,),
                  fgColor: Colors.red,
                  btSize: const Size(300, 50),
                ),
                const SizedBox(height: 4,),

                /// Search bar
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
                /// Search bar end

                Expanded(child: propertyNoCapCard(),),

                const SizedBox(height: 5,),
              ],
            ),
          ],
        ),
        /// Add new account, removed because it was not necessary for non-staff users.
          floatingActionButton: FloatingActionButton(
            onPressed: () => {
              ///Generate Report here
              showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Generate Overall Report"),
                      content: const Text("Generating a report will go through all properties and build an excel Spreadsheet!\n\nThis process will take time based on your internet speed.\n\nAre you ready to proceed? This may take a few minutes."),
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

  Widget tokenItemField(
      String accNumber,
      String userAddress,
      String userAreaCode,
      String userWardProp,
      String userNameProp,
      String userIDnum,
      String userPhoneNum,
      String userValidity,
      // String userEMeterNum,
      // String userEMeterRead,
      String userWMeterNum,
      String userWMeterRead,
      String userBill,) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8,),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Account Number: $accNumber',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Property: $userAddress',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Area Code:: $userAreaCode',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ward: $userWardProp',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Name: $userNameProp',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'ID Number: $userIDnum',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Phone: $userPhoneNum',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Register status: $userValidity',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          // Row(
          //   children: [
          //     Expanded(
          //       child: Text(
          //         'Meter Number: $userEMeterNum',
          //         style: const TextStyle(
          //           fontSize: 16,
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          // Row(
          //   children: [
          //     Expanded(
          //       child: Text(
          //         'Meter Reading: $userEMeterRead',
          //         style: const TextStyle(
          //           fontSize: 16,
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Water Meter Number: $userWMeterNum',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Water Meter Reading: $userWMeterRead',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),

          Row(
            children: [
              Expanded(
                child: Text(
                  userBill,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget propertyCard() {
    if (_allPropResults.isNotEmpty){
      return ListView.builder(
          itemCount: _allPropResults.length,
          itemBuilder: (context, index) {

            userAccNum = _allPropResults[index]['address'];
            userAddress = _allPropResults[index]['address'];
            userAreaCode = _allPropResults[index]['areaCode'].toString();
            userWardProp = _allPropResults[index]['ward'];
            userNameProp = '${_allPropResults[index]['firstName']} ${_allPropResults[index]['lastName']}';
            userIDnum = _allPropResults[index]['idNumber'];
            userPhoneNumber = _allPropResults[index]['cellNumber'];
            // EMeterNum = _allPropResults[index]['meter_number'];
            // EMeterRead = _allPropResults[index]['meter_reading'];
            // EMeterCap = _allPropResults[index]['imgStateE'];
            WMeterNum = _allPropResults[index]['water_meter_number'];
            WMeterRead = _allPropResults[index]['water_meter_reading'];
            WMeterCap = _allPropResults[index]['imgStateW'];
            userBill = _allPropResults[index]['eBill'];

            if(_allPropResults[index]['eBill'] != '' ||
                _allPropResults[index]['eBill'] != 'R0,000.00' ||
                _allPropResults[index]['eBill'] != 'R0.00' ||
                _allPropResults[index]['eBill'] != 'R0' ||
                _allPropResults[index]['eBill'] != '0'
            ){
              userBill = 'Utilities bill outstanding: ${_allPropResults[index]['eBill']}';
            } else {
              userBill = 'No outstanding payments';
            }

            for (var tokenSnapshot in _allUserTokenResults) {
              if (tokenSnapshot.id == _allPropResults[index]['cellNumber']) {
                userPhoneToken = tokenSnapshot['token'];
                notifyToken = tokenSnapshot['token'];
                userValid = 'User will receive notification';
                break;
              } else {
                userPhoneToken = '';
                notifyToken = '';
                userValid = 'User is not yet registered';
              }
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
                        child: Text('Property Details',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 10,),
                      tokenItemField(
                        userAccNum,
                        userAddress,
                        userAreaCode,
                        userWardProp,
                        userNameProp,
                        userIDnum,
                        userPhoneNumber,
                        userValid,
                        // EMeterNum,
                        // EMeterRead,
                        WMeterNum,
                        WMeterRead,
                        userBill,
                      ),
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
      );
    }
    return const Padding(
      padding: EdgeInsets.all(10.0),
      child: Center(
          child: CircularProgressIndicator()),
    );
  }

  Widget propertyCapCard() {
    if (_allPropResults.isNotEmpty){
      return GestureDetector(
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

                  userAccNum = _allPropResults[index]['address'];
                  userAddress = _allPropResults[index]['address'];
                  userAreaCode = _allPropResults[index]['areaCode'].toString();
                  userWardProp = _allPropResults[index]['ward'];
                  userNameProp = '${_allPropResults[index]['firstName']} ${_allPropResults[index]['lastName']}';
                  userIDnum = _allPropResults[index]['idNumber'];
                  userPhoneNumber = _allPropResults[index]['cellNumber'];
                  // EMeterNum = _allPropResults[index]['meter_number'];
                  // EMeterRead = _allPropResults[index]['meter_reading'];
                  // EMeterCap = _allPropResults[index]['imgStateE'];
                  WMeterNum = _allPropResults[index]['water_meter_number'];
                  WMeterRead = _allPropResults[index]['water_meter_reading'];
                  WMeterCap = _allPropResults[index]['imgStateW'];
                  userBill = _allPropResults[index]['eBill'];

                  if(_allPropResults[index]['eBill'] != '' ||
                      _allPropResults[index]['eBill'] != 'R0,000.00' ||
                      _allPropResults[index]['eBill'] != 'R0.00' ||
                      _allPropResults[index]['eBill'] != 'R0' ||
                      _allPropResults[index]['eBill'] != '0'
                  ){
                    userBill = 'Utilities bill outstanding: ${_allPropResults[index]['eBill']}';
                  } else {
                    userBill = 'No outstanding payments';
                  }

                  for (var tokenSnapshot in _allUserTokenResults) {
                    if (tokenSnapshot.id == _allPropResults[index]['cellNumber']) {
                      userPhoneToken = tokenSnapshot['token'];
                      notifyToken = tokenSnapshot['token'];
                      userValid = 'User will receive notification';
                      break;
                    } else {
                      userPhoneToken = '';
                      notifyToken = '';
                      userValid = 'User is not yet registered';
                    }
                  }

                  if( WMeterCap == true) {
                    return Card(
                      margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text('Property Details',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            tokenItemField(
                              userAccNum,
                              userAddress,
                              userAreaCode,
                              userWardProp,
                              userNameProp,
                              userIDnum,
                              userPhoneNumber,
                              userValid,
                              // EMeterNum,
                              // EMeterRead,
                              WMeterNum,
                              WMeterRead,
                              userBill,
                            ),
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

  Widget propertyNoCapCard() {
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

                  userAccNum = _allPropResults[index]['address'];
                  userAddress = _allPropResults[index]['address'];
                  userAreaCode = _allPropResults[index]['areaCode'].toString();
                  userWardProp = _allPropResults[index]['ward'];
                  userNameProp = '${_allPropResults[index]['firstName']} ${_allPropResults[index]['lastName']}';
                  userIDnum = _allPropResults[index]['idNumber'];
                  userPhoneNumber = _allPropResults[index]['cellNumber'];
                  // EMeterNum = _allPropResults[index]['meter_number'];
                  // EMeterRead = _allPropResults[index]['meter_reading'];
                  // EMeterCap = _allPropResults[index]['imgStateE'];
                  WMeterNum = _allPropResults[index]['water_meter_number'];
                  WMeterRead = _allPropResults[index]['water_meter_reading'];
                  WMeterCap = _allPropResults[index]['imgStateW'];
                  userBill = _allPropResults[index]['eBill'];

                  if(_allPropResults[index]['eBill'] != '' ||
                      _allPropResults[index]['eBill'] != 'R0,000.00' ||
                      _allPropResults[index]['eBill'] != 'R0.00' ||
                      _allPropResults[index]['eBill'] != 'R0' ||
                      _allPropResults[index]['eBill'] != '0'
                  ){
                    userBill = 'Utilities bill outstanding: ${_allPropResults[index]['eBill']}';
                  } else {
                    userBill = 'No outstanding payments';
                  }

                  for (var tokenSnapshot in _allUserTokenResults) {
                    if (tokenSnapshot.id == _allPropResults[index]['cellNumber']) {
                      userPhoneToken = tokenSnapshot['token'];
                      notifyToken = tokenSnapshot['token'];
                      userValid = 'User will receive notification';
                      break;
                    } else {
                      userPhoneToken = '';
                      notifyToken = '';
                      userValid = 'User is not yet registered';
                    }
                  }

                  if( WMeterCap == false) {
                    return Card(
                      margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text('Property Details',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            tokenItemField(
                              userAccNum,
                              userAddress,
                              userAreaCode,
                              userWardProp,
                              userNameProp,
                              userIDnum,
                              userPhoneNumber,
                              userValid,
                              // EMeterNum,
                              // EMeterRead,
                              WMeterNum,
                              WMeterRead,
                              userBill,
                            ),
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
    final excel.Workbook workbook = excel.Workbook();
    final excel.Worksheet sheet = workbook.worksheets[0];

    QuerySnapshot propertiesSnapshot;

    if (selectedMunicipality == "All Municipalities") {
      propertiesSnapshot = await FirebaseFirestore.instance
          .collectionGroup('properties')
          .where('districtId', isEqualTo: districtId)
          .get();
    } else {
      propertiesSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(selectedMunicipality!)
          .collection('properties')
          .get();
    }

    _allPropertyReport = propertiesSnapshot.docs;

    int excelRow = 2;
    int listRow = 0;

    sheet.getRangeByName('A1').setText('Account #');
    sheet.getRangeByName('B1').setText('Address');
    sheet.getRangeByName('C1').setText('Area Code');
    sheet.getRangeByName('D1').setText('Utilities Bill');
    // sheet.getRangeByName('E1').setText('Meter Number');
    // sheet.getRangeByName('F1').setText('Meter Reading');
    // sheet.getRangeByName('G1').setText('Electric Image Submitted');
    sheet.getRangeByName('H1').setText('Water Meter Number');
    sheet.getRangeByName('I1').setText('Water Meter Reading');
    sheet.getRangeByName('J1').setText('Water Image Submitted');
    sheet.getRangeByName('K1').setText('First Name');
    sheet.getRangeByName('L1').setText('Last Name');
    sheet.getRangeByName('M1').setText('ID Number');
    sheet.getRangeByName('N1').setText('Owner Phone Number');

    for(var reportSnapshot in _allPropertyReport){
      ///Property snapshot that retrieves property data entirely from the db
      while(excelRow <= _allPropertyReport.length+1) {

        print('Report Lists:::: ${_allPropertyReport[listRow]['address']}');
        String accountNum = _allPropertyReport[listRow]['accountNumber'].toString();
        String address = _allPropertyReport[listRow]['address'].toString();
        String eBill = _allPropertyReport[listRow]['eBill'].toString();
        String areaCode = _allPropertyReport[listRow]['areaCode'].toString();
        // String meterNumber = _allPropertyReport[listRow]['meter_number'].toString();
        // String meterReading = _allPropertyReport[listRow]['meter_reading'].toString();
        // String uploadedLatestE = _allPropertyReport[listRow]['imgStateE'].toString();
        String waterMeterNum = _allPropertyReport[listRow]['water_meter_number'].toString();
        String waterMeterReading = _allPropertyReport[listRow]['water_meter_reading'].toString();
        String uploadedLatestW = _allPropertyReport[listRow]['imgStateW'].toString();
        String firstName = _allPropertyReport[listRow]['firstName'].toString();
        String lastName = _allPropertyReport[listRow]['lastName'].toString();
        String idNumber = _allPropertyReport[listRow]['idNumber'].toString();
        String phoneNumber = _allPropertyReport[listRow]['cellNumber'].toString();

        sheet.getRangeByName('A$excelRow').setText(accountNum);
        sheet.getRangeByName('B$excelRow').setText(address);
        sheet.getRangeByName('C$excelRow').setText(areaCode);
        sheet.getRangeByName('D$excelRow').setText(eBill);
        // sheet.getRangeByName('E$excelRow').setText(meterNumber);
        // sheet.getRangeByName('F$excelRow').setText(meterReading);
        // sheet.getRangeByName('G$excelRow').setText(uploadedLatestE);
        sheet.getRangeByName('H$excelRow').setText(waterMeterNum);
        sheet.getRangeByName('I$excelRow').setText(waterMeterReading);
        sheet.getRangeByName('J$excelRow').setText(uploadedLatestW);
        sheet.getRangeByName('K$excelRow').setText(firstName);
        sheet.getRangeByName('L$excelRow').setText(lastName);
        sheet.getRangeByName('M$excelRow').setText(idNumber);
        sheet.getRangeByName('N$excelRow').setText(phoneNumber);

        excelRow+=1;
        listRow+=1;
      }
    }

    final List<int> bytes = workbook.saveAsStream();

    if(kIsWeb){
      AnchorElement(href: 'data:application/ocelot-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
          ..setAttribute('download', '$selectedMunicipality  Property Reports $formattedDate.xlsx')
          ..click();
    } else {
      final String path = (await getApplicationSupportDirectory()).path;
      //Create an empty file to write Excel data
      final String filename = Platform.isWindows ? '$path\\$selectedMunicipality  Property Reports $formattedDate.xlsx' : '$path/Municipality Property Reports $formattedDate.xlsx';
      final File file = File(filename);
      final List<int> bytes = workbook.saveAsStream();
      //Write Excel data
      await file.writeAsBytes(bytes, flush: true);
      //Launch the file (used open_file package)
      await OpenFile.open('$path/$selectedMunicipality  Property Reports $formattedDate.xlsx');
    }
    // File('Municipality Property Reports.xlsx').writeAsBytes(bytes);
    workbook.dispose();
  }

  Future<void> capReportGeneration() async {
    final excel.Workbook workbook = excel.Workbook();
    final excel.Worksheet sheet = workbook.worksheets[0];

    QuerySnapshot propertiesSnapshot;

    if (selectedMunicipality == "All Municipalities") {
      propertiesSnapshot = await FirebaseFirestore.instance
          .collectionGroup('properties')
          .where('districtId', isEqualTo: districtId)
          .get();
    } else {
      propertiesSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(selectedMunicipality!)
          .collection('properties')
          .get();
    }

    _allPropertyReport = propertiesSnapshot.docs;

    int excelRow = 2;
    int excelCap = 2;
    int listRow = 0;

    sheet.getRangeByName('A1').setText('Account #');
    sheet.getRangeByName('B1').setText('Address');
    sheet.getRangeByName('C1').setText('Area Code');
    sheet.getRangeByName('D1').setText('Utilities Bill');
    // sheet.getRangeByName('E1').setText('Meter Number');
    // sheet.getRangeByName('F1').setText('Meter Reading');
    // sheet.getRangeByName('G1').setText('Electric Image Submitted');
    sheet.getRangeByName('H1').setText('Water Meter Number');
    sheet.getRangeByName('I1').setText('Water Meter Reading');
    sheet.getRangeByName('J1').setText('Water Image Submitted');
    sheet.getRangeByName('K1').setText('First Name');
    sheet.getRangeByName('L1').setText('Last Name');
    sheet.getRangeByName('M1').setText('ID Number');
    sheet.getRangeByName('N1').setText('Owner Phone Number');

    for(var reportSnapshot in _allPropertyReport){
      ///Property snapshot that retrieves property data entirely from the db
      while(excelCap <= _allPropertyReport.length+1) {

        print('Report Lists:::: ${_allPropertyReport[listRow]['address']}');
        String accountNum = _allPropertyReport[listRow]['accountNumber'].toString();
        String address = _allPropertyReport[listRow]['address'].toString();
        String eBill = _allPropertyReport[listRow]['eBill'].toString();
        String areaCode = _allPropertyReport[listRow]['areaCode'].toString();
        // String meterNumber = _allPropertyReport[listRow]['meter_number'].toString();
        // String meterReading = _allPropertyReport[listRow]['meter_reading'].toString();
        // String uploadedLatestE = _allPropertyReport[listRow]['imgStateE'].toString();
        String waterMeterNum = _allPropertyReport[listRow]['water_meter_number'].toString();
        String waterMeterReading = _allPropertyReport[listRow]['water_meter_reading'].toString();
        String uploadedLatestW = _allPropertyReport[listRow]['imgStateW'].toString();
        String firstName = _allPropertyReport[listRow]['firstName'].toString();
        String lastName = _allPropertyReport[listRow]['lastName'].toString();
        String idNumber = _allPropertyReport[listRow]['idNumber'].toString();
        String phoneNumber = _allPropertyReport[listRow]['cellNumber'].toString();

        if( uploadedLatestW == 'true') {
          sheet.getRangeByName('A$excelRow').setText(accountNum);
          sheet.getRangeByName('B$excelRow').setText(address);
          sheet.getRangeByName('C$excelRow').setText(areaCode);
          sheet.getRangeByName('D$excelRow').setText(eBill);
          // sheet.getRangeByName('E$excelRow').setText(meterNumber);
          // sheet.getRangeByName('F$excelRow').setText(meterReading);
          // sheet.getRangeByName('G$excelRow').setText(uploadedLatestE);
          sheet.getRangeByName('H$excelRow').setText(waterMeterNum);
          sheet.getRangeByName('I$excelRow').setText(waterMeterReading);
          sheet.getRangeByName('J$excelRow').setText(uploadedLatestW);
          sheet.getRangeByName('K$excelRow').setText(firstName);
          sheet.getRangeByName('L$excelRow').setText(lastName);
          sheet.getRangeByName('M$excelRow').setText(idNumber);
          sheet.getRangeByName('N$excelRow').setText(phoneNumber);

          excelRow+=1;
          excelCap+=1;
          listRow+=1;
        } else {
          excelCap+=1;
          listRow+=1;
        }
      }
    }

    final List<int> bytes = workbook.saveAsStream();

    if(kIsWeb){
      AnchorElement(href: 'data:application/ocelot-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
          ..setAttribute('download', '$selectedMunicipality  Property Captured Reports $formattedDate.xlsx')
          ..click();
    } else {
      final String path = (await getApplicationSupportDirectory()).path;
      //Create an empty file to write Excel data
      final String filename = Platform.isWindows ? '$path\\$selectedMunicipality  Property Captured Reports $formattedDate.xlsx' : '$path/Municipality Property Captured Reports $formattedDate.xlsx';
      final File file = File(filename);
      final List<int> bytes = workbook.saveAsStream();
      //Write Excel data
      await file.writeAsBytes(bytes, flush: true);
      //Launch the file (used open_file package)
      await OpenFile.open('$path/$selectedMunicipality Property Captured Reports $formattedDate.xlsx');
    }
    // File('Municipality Property Reports.xlsx').writeAsBytes(bytes);
    workbook.dispose();
  }

  Future<void> noCapReportGeneration() async {
    final excel.Workbook workbook = excel.Workbook();
    final excel.Worksheet sheet = workbook.worksheets[0];

    QuerySnapshot propertiesSnapshot;

    if (selectedMunicipality == "All Municipalities") {
      propertiesSnapshot = await FirebaseFirestore.instance
          .collectionGroup('properties')
          .where('districtId', isEqualTo: districtId)
          .get();
    } else {
      propertiesSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(selectedMunicipality!)
          .collection('properties')
          .get();
    }

    _allPropertyReport = propertiesSnapshot.docs;

    int excelRow = 2;
    int excelCap = 2;
    int listRow = 0;

    sheet.getRangeByName('A1').setText('Account #');
    sheet.getRangeByName('B1').setText('Address');
    sheet.getRangeByName('C1').setText('Area Code');
    sheet.getRangeByName('D1').setText('Utilities Bill');
    // sheet.getRangeByName('E1').setText('Meter Number');
    // sheet.getRangeByName('F1').setText('Meter Reading');
    // sheet.getRangeByName('G1').setText('Electric Image Submitted');
    sheet.getRangeByName('H1').setText('Water Meter Number');
    sheet.getRangeByName('I1').setText('Water Meter Reading');
    sheet.getRangeByName('J1').setText('Water Image Submitted');
    sheet.getRangeByName('K1').setText('First Name');
    sheet.getRangeByName('L1').setText('Last Name');
    sheet.getRangeByName('M1').setText('ID Number');
    sheet.getRangeByName('N1').setText('Owner Phone Number');

    for(var reportSnapshot in _allPropertyReport){
      ///Property snapshot that retrieves property data entirely from the db
      while(excelCap <= _allPropertyReport.length+1) {

        print('Report Lists:::: ${_allPropertyReport[listRow]['address']}');
        String accountNum = _allPropertyReport[listRow]['accountNumber'].toString();
        String address = _allPropertyReport[listRow]['address'].toString();
        String eBill = _allPropertyReport[listRow]['eBill'].toString();
        String areaCode = _allPropertyReport[listRow]['areaCode'].toString();
        // String meterNumber = _allPropertyReport[listRow]['meter_number'].toString();
        // String meterReading = _allPropertyReport[listRow]['meter_reading'].toString();
        // String uploadedLatestE = _allPropertyReport[listRow]['imgStateE'].toString();
        String waterMeterNum = _allPropertyReport[listRow]['water_meter_number'].toString();
        String waterMeterReading = _allPropertyReport[listRow]['water_meter_reading'].toString();
        String uploadedLatestW = _allPropertyReport[listRow]['imgStateW'].toString();
        String firstName = _allPropertyReport[listRow]['firstName'].toString();
        String lastName = _allPropertyReport[listRow]['lastName'].toString();
        String idNumber = _allPropertyReport[listRow]['idNumber'].toString();
        String phoneNumber = _allPropertyReport[listRow]['cellNumber'].toString();

        if( uploadedLatestW == 'false') {
          sheet.getRangeByName('A$excelRow').setText(accountNum);
          sheet.getRangeByName('B$excelRow').setText(address);
          sheet.getRangeByName('C$excelRow').setText(areaCode);
          sheet.getRangeByName('D$excelRow').setText(eBill);
          // sheet.getRangeByName('E$excelRow').setText(meterNumber);
          // sheet.getRangeByName('F$excelRow').setText(meterReading);
          // sheet.getRangeByName('G$excelRow').setText(uploadedLatestE);
          sheet.getRangeByName('H$excelRow').setText(waterMeterNum);
          sheet.getRangeByName('I$excelRow').setText(waterMeterReading);
          sheet.getRangeByName('J$excelRow').setText(uploadedLatestW);
          sheet.getRangeByName('K$excelRow').setText(firstName);
          sheet.getRangeByName('L$excelRow').setText(lastName);
          sheet.getRangeByName('M$excelRow').setText(idNumber);
          sheet.getRangeByName('N$excelRow').setText(phoneNumber);

          excelRow+=1;
          excelCap+=1;
          listRow+=1;
        } else {
          excelCap+=1;
          listRow+=1;
        }
      }
    }

    final List<int> bytes = workbook.saveAsStream();

    if(kIsWeb){
      AnchorElement(href: 'data:application/ocelot-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
          ..setAttribute('download', '$selectedMunicipality  Property Non-Captured Reports $formattedDate.xlsx')
          ..click();
    } else {
      final String path = (await getApplicationSupportDirectory()).path;
      //Create an empty file to write Excel data
      final String filename = Platform.isWindows ? '$path\\$selectedMunicipality  Property Non-Captured Reports $formattedDate.xlsx' : '$path/Municipality Property Non-Captured Reports $formattedDate.xlsx';
      final File file = File(filename);
      final List<int> bytes = workbook.saveAsStream();
      //Write Excel data
      await file.writeAsBytes(bytes, flush: true);
      //Launch the file (used open_file package)
      await OpenFile.open('$path/$selectedMunicipality Property Non-Captured Reports $formattedDate.xlsx');
    }
    // File('Municipality Property Reports.xlsx').writeAsBytes(bytes);
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