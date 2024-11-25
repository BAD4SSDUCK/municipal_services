import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:getwidget/components/button/gf_icon_button.dart';
import 'package:getwidget/getwidget.dart';

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
import 'package:url_launcher/url_launcher.dart';

import 'package:municipal_services/code/MapTools/map_screen_prop.dart';
import 'package:municipal_services/code/PDFViewer/view_pdf.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';
import 'package:municipal_services/code/Reusable/push_notification_message.dart';
import 'package:municipal_services/code/NoticePages/notice_config_screen.dart';

class ReportBuilderFaults extends StatefulWidget {
  const ReportBuilderFaults({
    super.key,
  });

  @override
  _ReportBuilderFaultsState createState() => _ReportBuilderFaultsState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
// final storageRef = FirebaseStorage.instance.ref();

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
String dateRange1 = ' ';
String dateRange2 = ' ';

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

class _ReportBuilderFaultsState extends State<ReportBuilderFaults> {
  String districtId = '';
  String municipalityId = '';
  String selectedMunicipality = 'All Municipalities';
  List<String> municipalityOptions = [];
  bool isLocalMunicipality = false;
  bool isLocalUser = false;
  bool isLoading = true;
  bool _isDataLoaded = false;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    fetchUserDetails().then((_) {
      if (isLocalUser) {
        fetchFaultsForLocalMunicipality();
      } else {
        fetchMunicipalities(); // Fetch municipalities after user details are loaded
        selectedMunicipality = "All Municipalities"; // Set the default value
      }
    });
    if (_searchController.text == "") {
      // getFaultStream();
    }
    // getPropertyStream();
    checkAdmin();
    _searchController.addListener(_onSearchChanged);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    searchText;
    _allFaultResults;
    _allFaultReport;
    super.dispose();
  }


  Future<void> fetchMunicipalities() async {
    try {
      if (districtId.isNotEmpty) {
        print("Fetching municipalities under district: $districtId");
        var municipalitiesSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .get();

        print("Municipalities fetched: ${municipalitiesSnapshot.docs.length}");
        if (mounted) {
          setState(() {
            municipalityOptions = [
              "All Municipalities"
            ]; // Ensure "All Municipalities" is the first option
            municipalityOptions.addAll(
                municipalitiesSnapshot.docs.map((doc) => doc.id).toList());

            selectedMunicipality =
                "All Municipalities"; // Set default selected value

            print("Municipalities list: $municipalityOptions");
            fetchFaultsForAllMunicipalities();
          });
        }
      } else {
        print("districtId is empty or null.");
        if (mounted) {
          setState(() {
            municipalityOptions = ["All Municipalities"];
            selectedMunicipality = "All Municipalities";
          });
        }
      }
    } catch (e) {
      print('Error fetching municipalities: $e');
    }
  }

  Future<void> fetchFaultsForAllMunicipalities() async {
    if (districtId.isEmpty) {
      print("Error: districtId is empty. Cannot fetch faults.");
      return;
    }

    List<QuerySnapshot> faultSnapshots = [];

    try {
      // First, retrieve all municipalities under the district
      var municipalitiesSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .get();

      // For each municipality, fetch faults from its faultReporting collection
      for (var municipalityDoc in municipalitiesSnapshot.docs) {
        var municipalityId = municipalityDoc.id;

        var faultsSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('faultReporting')
            .get();

        faultSnapshots.add(faultsSnapshot);
      }

      // Aggregate results
      List<QueryDocumentSnapshot> allFaults = [];
      for (var snapshot in faultSnapshots) {
        allFaults.addAll(snapshot.docs);
      }

      setState(() {
        _allFaultResults = allFaults;
        print("Fetched ${_allFaultResults.length} faults for all municipalities in district $districtId.");
      });
    } catch (e) {
      print("Error fetching faults for all municipalities: $e");
    }
  }



  Future<void> fetchFaultsForLocalMunicipality() async {
    if (municipalityId.isEmpty) {
      print("Error: municipalityId is empty. Cannot fetch faults.");
      return;
    }

    try {
      print("Fetching faults for local municipality: $municipalityId");

      // Fetch properties only for the specific municipality the user belongs to
      QuerySnapshot faultSnapshot = await FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId) // The local municipality ID for the user
          .collection('faultReporting')
          .get();

      // Check if any properties were fetched
      if (faultSnapshot.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _allFaultResults = faultSnapshot.docs; // Store fetched properties
          });
        }
        print('Faults fetched for local municipality: $municipalityId');
        print('Number of faults fetched: ${faultSnapshot.docs.length}');
      } else {
        print("No faults found for local municipality: $municipalityId");
      }
    } catch (e) {
      print('Error fetching faults for local municipality: $e');
    }
  }

  Future<void> fetchFaultsByMunicipality(String municipality) async {
    try {
      // Fetch properties for the selected municipality
      QuerySnapshot faultSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipality)
          .collection('faultReporting')
          .get();

      // Log the properties fetched
      print('Faults fetched for $municipality: ${faultSnapshot.docs.length}');
      if (mounted) {
        setState(() {
          _allFaultResults = faultSnapshot.docs; // Store filtered properties
          print(
              "Number of Faults fetched: ${_allFaultResults}"); // Debugging to ensure properties are set
        });
      }
    } catch (e) {
      print('Error fetching faults for $municipality: $e');
    }
  }

  Future<void> fetchUserDetails() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userEmail = user.email ?? '';
        print("User email initialized: $userEmail");

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

          print("districtId assigned: $districtId");

          // Call appropriate fetch based on user type
          if (isLocalMunicipality) {
            await fetchFaultsForLocalMunicipality();
          } else {
            await fetchFaultsForAllMunicipalities();
          }
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
      setState(() {
        _isDataLoaded = true;
        isLoading = false;
      });
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

  // getUsersStream() async{
  //   var data = await FirebaseFirestore.instance.collection('districts')
  //       .doc(districtId)
  //       .collection('municipalities')
  //       .doc(municipalityId)
  //       .collection('users').get();
  //   setState(() {
  //     _allUserRolesResults = data.docs;
  //   });
  //   getUserDetails();
  // }
  getUsersStream() async {
    try {
      QuerySnapshot usersSnapshot;

      // Fetch properties directly from the properties collection based on the current municipality
      if (isLocalMunicipality) {
        usersSnapshot = await FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(municipalityId)
            .collection('users')
            .get();
      } else {
        usersSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('users')
            .get();
      }

      if (mounted) {
        setState(() {
          _allUserRolesResults = usersSnapshot
              .docs; // This will now hold all property documents with tokens.
        });
      }

      searchResultsList();
    } catch (e) {
      print('Error fetching properties: $e');
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

  String accountNumberRep = '';
  String locationGivenRep = '';
  int faultStage = 0;
  String reporterCellGiven = '';
  String searchText = '';

  String formattedDate = DateFormat.MMMM().format(now);
  String formattedDateTime = DateFormat('yyyy-MM-dd – kk:mm').format(now);
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

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
  List _allFaultResults = [];
  List _allFaultReport = [];

  // getFaultStream() async{
  //   var data = await FirebaseFirestore.instance.collection('districts')
  //       .doc(districtId)
  //       .collection('municipalities')
  //       .doc(municipalityId)
  //       .collection('faultReporting').get();
  //
  //   CollectionReference collection = FirebaseFirestore.instance.collection('districts')
  //       .doc(districtId)
  //       .collection('municipalities')
  //       .doc(municipalityId)
  //       .collection('faultReporting');
  //
  //   DateTime dateParseString = DateTime.parse(formattedDateTime);
  //   DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.parse(formattedDateTime));
  //
  //   if(startDate != dateParseString){
  //     _allFaultResults = [];
  //
  //     QuerySnapshot querySnapshot = await collection
  //         .where('dateReported', isGreaterThanOrEqualTo: startDate.toUtc())
  //         .where('dateReported', isLessThanOrEqualTo: endDate.toUtc())
  //         .get();
  //
  //     List<DocumentSnapshot> documents = querySnapshot.docs;
  //     setState(() {
  //       _allFaultResults = documents;
  //     });
  //   } else {
  //     setState(() {
  //       _allFaultResults = data.docs;
  //     });
  //   }
  //
  //   searchResultsList();
  // }
  // getFaultStream() async {
  //   Query collection;
  //
  //   if (selectedMunicipality == 'All') {
  //     // Fetch faults across all municipalities
  //     collection = FirebaseFirestore.instance.collectionGroup('faultReporting').where('districtId', isEqualTo: districtId);
  //   } else {
  //     // Fetch faults from the selected municipality
  //     collection = FirebaseFirestore.instance.collection('districts')
  //         .doc(districtId)
  //         .collection('municipalities')
  //         .doc(selectedMunicipality)
  //         .collection('faultReporting');
  //   }
  //
  //   var querySnapshot = await collection.get();
  //   setState(() {
  //     _allFaultResults = querySnapshot.docs;
  //   });
  //   searchResultsList();
  // }

  _onSearchChanged() async {
    if (_searchController.text.isEmpty) {
      if (mounted) {
        // If search is cleared, fetch and display all properties again
        setState(() {
          searchText = ''; // Clear search text
        });
      }
      if (isLocalUser) {
        await fetchFaultsForLocalMunicipality();
      } else {
        await fetchFaultsForAllMunicipalities();
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
      for (var propSnapshot in _allFaultResults) {
        var address = propSnapshot['address'].toString().toLowerCase();
        String referenceNum = propSnapshot['ref']?.toString().toLowerCase() ?? '';
        var cellNumber = propSnapshot['reporterContact'].toString().toLowerCase();
        var accountNumber=propSnapshot['accountNumber'].toString().toLowerCase();

        if (address.contains(searchLower) ||
            referenceNum.contains(searchLower) || // Search full name instead of first and last separately
            cellNumber.contains(searchLower) ||
            accountNumber.contains(searchLower)) {
          showResults.add(propSnapshot);
        }
      }
      if (mounted) {
        setState(() {
          _allFaultResults = showResults; // Update state with filtered results
        });
      }
    } else {
      // If the search is cleared, reload the full property list
      if (isLocalUser) {
        await fetchFaultsForLocalMunicipality();
      } else {
        await fetchFaultsForAllMunicipalities();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[350],
        appBar: AppBar(
          title: const Text(
            'Fault Report Generator',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.green,
          actions: <Widget>[
            Visibility(
              visible: false,
              child: IconButton(
                  onPressed: () {
                    ///Generate Report here
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
                  icon: const Icon(
                    Icons.file_copy_outlined,
                    color: Colors.white,
                  )),
            ),
          ],
        ),
        body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DropdownButton<String>(
                    value: selectedMunicipality,
                    hint: const Text('All Municipalities'),
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedMunicipality = newValue!;
                        if (selectedMunicipality == "All Municipalities") {
                          fetchFaultsForAllMunicipalities();
                        } else {
                          fetchFaultsByMunicipality(selectedMunicipality);
                        }
                      });
                    },
                    items: municipalityOptions.map((String municipality) {
                      return DropdownMenuItem<String>(
                        value: municipality,
                        child: Text(municipality),
                      );
                    }).toList(),
                  ),
                ),

                ///For date range entry
                Padding(
                  padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                    decoration: const BoxDecoration(
                      shape: BoxShape.rectangle,
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green, // Custom background color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10), // Rounded corners
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Padding for a larger button
                              ),
                              onPressed: () {
                                showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2101),
                                  builder: (BuildContext context, Widget? child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: Colors.green, // Header background color
                                          onPrimary: Colors.white, // Header text color
                                          onSurface: Colors.black, // Body text color
                                        ),
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.green, // Button text color
                                          ),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                ).then((pickedDate) {
                                  if (pickedDate != null && pickedDate != startDate) {
                                    setState(() {
                                      startDate = pickedDate;
                                    });
                                  }
                                });
                              },
                              child: const Text(
                                'Start Date',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal,color: Colors.black),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              ),
                              onPressed: () {
                                showDatePicker(
                                  context: context,
                                  initialDate: endDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2101),
                                  builder: (BuildContext context, Widget? child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: Colors.green,
                                          onPrimary: Colors.white,
                                          onSurface: Colors.black,
                                        ),
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.green,
                                          ),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                ).then((pickedDate) {
                                  if (pickedDate != null && pickedDate != endDate) {
                                    setState(() {
                                      endDate = pickedDate;
                                    });
                                  }
                                });
                              },
                              child: const Text(
                                'End Date',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal,color: Colors.black),
                              ),
                            ),

                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Center(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 25),
                                      child: Text(
                                        "${startDate.toLocal()}".split(' ')[0],
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 25),
                                      child: Text(
                                        "${endDate.toLocal()}".split(' ')[0],
                                        style: const TextStyle(
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            dateRange1 = startDate.toString();
                            dateRange2 = endDate.toString();

                            DateTime dateTimeString1 = DateTime.parse(dateRange1);

                            showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text("Generate Live Report"),
                                    content: const Text(
                                        "Generating a report will go through all faults filtered between the start and end dates you have given.\n\nAre you ready to proceed? This may take some time."),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            fixedSize: const Size(200, 40),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.summarize,
                                color: Colors.green[700],
                              ),
                              const SizedBox(
                                width: 2,
                              ),
                              const Text(
                                'Generate Report',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                /// Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                  child: SearchBar(
                    controller: _searchController,
                    padding: const MaterialStatePropertyAll<EdgeInsets>(
                        EdgeInsets.symmetric(horizontal: 16.0)),
                    leading: const Icon(Icons.search),
                    hintText: "Search by Reference Number...",
                    onChanged: (value) async {
                      setState(() {
                        searchText = value;
                        // print('this is the input text ::: $searchText');
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

        // floatingActionButton: FloatingActionButton(
        //   onPressed: () => {
        //     ///Generate Report here
        //     showDialog(
        //         barrierDismissible: false,
        //         context: context,
        //         builder: (context) {
        //           return AlertDialog(
        //             title: const Text("Generate Live Report"),
        //             content: const Text(
        //                 "Generating a report will go through all properties and build an excel Spreadsheet!\n\nThis process will take time based on your internet speed.\n\nAre you ready to proceed? This may take a few minutes."),
        //             actions: [
        //               Center(
        //                 child: Column(
        //                   children: [
        //                     BasicIconButtonGrey(
        //                       onPress: () {
        //                         Navigator.pop(context);
        //                       },
        //                       labelText: "Cancel",
        //                       fSize: 12,
        //                       faIcon: const FaIcon(Icons.cancel),
        //                       fgColor: Colors.red,
        //                       btSize: const Size(50, 10),
        //                     ),
        //                     // BasicIconButtonGrey(
        //                     //   onPress: () async {
        //                     //     Fluttertoast.showToast(
        //                     //         msg: "Now generating report\nPlease wait till prompted to open Spreadsheet!");
        //                     //     reportGenerationWaste();
        //                     //     Navigator.pop(context);
        //                     //   },
        //                     //   labelText: "Roadworks", fSize: 12, faIcon: const FaIcon(Icons.add_road), fgColor: Colors.black54, btSize: const Size(50,10),
        //                     // ),
        //                     // BasicIconButtonGrey(
        //                     //   onPress: () async {
        //                     //     Fluttertoast.showToast(
        //                     //         msg: "Now generating report\nPlease wait till prompted to open Spreadsheet!");
        //                     //     reportGenerationWaste();
        //                     //     Navigator.pop(context);
        //                     //   },
        //                     //   labelText: "Waste Management", fSize: 12, faIcon: const FaIcon(Icons.recycling), fgColor: Colors.brown, btSize: const Size(50,10),
        //                     // ),
        //                     BasicIconButtonGrey(
        //                       onPress: () async {
        //                         Fluttertoast.showToast(
        //                             msg:
        //                                 "Now generating report\nPlease wait till prompted to open Spreadsheet!");
        //                         reportGenerationWater();
        //                         Navigator.pop(context);
        //                       },
        //                       labelText: "Water & Sanitation",
        //                       fSize: 12,
        //                       faIcon: const FaIcon(Icons.water_drop_outlined),
        //                       fgColor: Colors.blue,
        //                       btSize: const Size(50, 10),
        //                     ),
        //                     // BasicIconButtonGrey(
        //                     //   onPress: () async {
        //                     //     Fluttertoast.showToast(
        //                     //         msg: "Now generating report\nPlease wait till prompted to open Spreadsheet!");
        //                     //     reportGenerationElectricity();
        //                     //     Navigator.pop(context);
        //                     //   },
        //                     //   labelText: "Electricity", fSize: 12, faIcon: const FaIcon(Icons.power), fgColor: Colors.yellow, btSize: const Size(50,10),
        //                     // ),
        //                     BasicIconButtonGrey(
        //                       onPress: () async {
        //                         Fluttertoast.showToast(
        //                             msg:
        //                                 "Now generating report\nPlease wait till prompted to open Spreadsheet!");
        //                         reportGeneration();
        //                         Navigator.pop(context);
        //                       },
        //                       labelText: "All",
        //                       fSize: 12,
        //                       faIcon: const FaIcon(Icons.check_circle),
        //                       fgColor: Colors.green,
        //                       btSize: const Size(50, 10),
        //                     ),
        //                   ],
        //                 ),
        //               ),
        //             ],
        //           );
        //         })
        //   },
        //   backgroundColor: Colors.green,
        //   child: const Icon(
        //     Icons.file_copy_outlined,
        //     color: Colors.white,
        //   ),
        // ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat);
  }

  Widget faultCard() {
    if (_allFaultResults.isNotEmpty) {

      return KeyboardListener(
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
            itemCount: _allFaultResults.length,
            itemBuilder: (context, index) {
              String status;
              if (_allFaultResults[index]['faultResolved'] == false) {
                status = "Pending";
              } else {
                status = "Completed";
              }

              return Card(
                margin: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Fault Information',
                          style:
                              TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                          if (_allFaultResults[index]['accountNumber'] != "") ...[
                            Text(
                              'Reporter Account Number: ${_allFaultResults[index]['accountNumber']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
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
                          if (_allFaultResults[index]['faultStage'] == 1) ...[
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
                          ] else if (_allFaultResults[index]['faultStage'] ==
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
                          ] else if (_allFaultResults[index]['faultStage'] ==
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
                          ] else if (_allFaultResults[index]['faultStage'] ==
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
                          ] else if (_allFaultResults[index]['faultStage'] ==
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
                          if (_allFaultResults[index]['faultDescription'] !=
                              "") ...[
                            Text(
                              'Fault Description: ${_allFaultResults[index]['faultDescription']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
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
                          if (_allFaultResults[index]['adminComment'] != "") ...[
                            Text(
                              'Admin Comment: ${_allFaultResults[index]['adminComment']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
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
                          if (_allFaultResults[index]['reallocationComment'] !=
                              "") ...[
                            Text(
                              'Reason fault reallocated: ${_allFaultResults[index]['reallocationComment']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
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
                          if (_allFaultResults[index]['managerAllocated'] !=
                              "") ...[
                            Text(
                              'Manager of fault: ${_allFaultResults[index]['managerAllocated']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
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
                          if (_allFaultResults[index]['attendeeAllocated'] !=
                              "") ...[
                            Text(
                              'Attendee Allocated: ${_allFaultResults[index]['attendeeAllocated']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
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
                          if (_allFaultResults[index]['attendeeCom1'] != "") ...[
                            Text(
                              'Attendee Comment: ${_allFaultResults[index]['attendeeCom1']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
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
                          if (_allFaultResults[index]['managerCom1'] != "") ...[
                            Text(
                              'Manager Comment: ${_allFaultResults[index]['managerCom1']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
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
                          if (_allFaultResults[index]['attendeeCom2'] != "") ...[
                            Text(
                              'Attendee Followup Comment: ${_allFaultResults[index]['attendeeCom2']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
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
                          if (_allFaultResults[index]['managerCom2'] != "") ...[
                            Text(
                              'Manager Final/Additional Comment: ${_allFaultResults[index]['managerCom2']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
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
                          if (_allFaultResults[index]['attendeeCom3'] != "") ...[
                            Text(
                              'Attendee Final Comment: ${_allFaultResults[index]['attendeeCom3']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
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
                          if (_allFaultResults[index]['managerCom3'] != "") ...[
                            Text(
                              'Manager Final Comment: ${_allFaultResults[index]['managerCom3']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
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
                        height: 20,
                      ),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  accountNumberRep =
                                      _allFaultResults[index]['accountNumber'];
                                  locationGivenRep =
                                      _allFaultResults[index]['address'];

                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => MapScreenProp(
                                                propAddress: locationGivenRep,
                                                propAccNumber: accountNumberRep,
                                              )));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[350],
                                  fixedSize: const Size(140, 10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.map,
                                      color: Colors.green[700],
                                    ),
                                    const SizedBox(
                                      width: 2,
                                    ),
                                    const Text(
                                      'Location',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(16))),
                                          title: const Text("Call Reporter!"),
                                          content: const Text(
                                              "Would you like to call the individual who logged the fault?"),
                                          actions: [
                                            IconButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              icon: const Icon(
                                                Icons.cancel,
                                                color: Colors.red,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                reporterCellGiven =
                                                    _allFaultResults[index]
                                                        ['reporterContact'];

                                                final Uri _tel = Uri.parse(
                                                    'tel:${reporterCellGiven.toString()}');
                                                launchUrl(_tel);

                                                Navigator.of(context).pop();
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[350],
                                  fixedSize: const Size(140, 10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.call,
                                      color: Colors.orange[700],
                                    ),
                                    const SizedBox(
                                      width: 2,
                                    ),
                                    const Text(
                                      'Call User',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                width: 5,
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
      );
    }
    return const Padding(
      padding: EdgeInsets.all(10.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  // Future<void> reportGeneration() async {
  //   final excel.Workbook workbook = excel.Workbook();
  //   final excel.Worksheet sheet = workbook.worksheets[0];
  //
  //   var data = await FirebaseFirestore.instance.collection('districts')
  //       .doc(districtId)
  //       .collection('municipalities')
  //       .doc(municipalityId)
  //       .collection('faultReporting').get();
  //
  //   _allFaultReport = data.docs;
  //
  //   String column = "A";
  //   int excelRow = 2;
  //   int listRow = 0;
  //
  //   sheet.getRangeByName('A1').setText('Ref #');
  //   sheet.getRangeByName('B1').setText('Resolve Status');
  //   sheet.getRangeByName('C1').setText('Fault Type');
  //   sheet.getRangeByName('D1').setText('Account #');
  //   sheet.getRangeByName('E1').setText('Address');
  //   sheet.getRangeByName('F1').setText('Report Date');
  //   sheet.getRangeByName('G1').setText('Department Allocated');
  //   sheet.getRangeByName('H1').setText('Fault Description');
  //   sheet.getRangeByName('I1').setText('Fault Stage');
  //   sheet.getRangeByName('J1').setText('Reporters Phone Number');
  //   sheet.getRangeByName('K1').setText('Attendee Allocated');
  //   sheet.getRangeByName('L1').setText('Manager Allocated');
  //   sheet.getRangeByName('M1').setText('Admin Comment');
  //   sheet.getRangeByName('N1').setText('Attendee Com1');
  //   sheet.getRangeByName('O1').setText('Manager Com1');
  //   sheet.getRangeByName('P1').setText('Attendee Com2');
  //   sheet.getRangeByName('Q1').setText('Manager Com2');
  //   sheet.getRangeByName('R1').setText('Attendee Com3');
  //   sheet.getRangeByName('S1').setText('Manager Com3');
  //   sheet.getRangeByName('T1').setText('Department SwitchComment');
  //   sheet.getRangeByName('U1').setText('Reallocation Comment');
  //   sheet.getRangeByName('V1').setText('Manager ReturnCom');
  //   sheet.getRangeByName('W1').setText('Attendee ReturnCom');
  //
  //   for(var reportSnapshot in _allFaultReport){
  //     ///Need to build a property model that retrieves property data entirely from the db
  //     while(excelRow <= _allFaultReport.length+1) {
  //       print('Report Lists:::: ${_allFaultReport[listRow]['address']}');
  //
  //       // if(_allFaultReport[listRow]['dateReported'].toString().contains(dateRange1)){
  //       //   String referenceNum      = _allFaultReport[listRow]['ref'].toString();
  //       //   String resolveStatus     = _allFaultReport[listRow]['faultResolved'].toString();
  //       //   String faultType         = _allFaultReport[listRow]['faultType'].toString();
  //       //   String accountNum        = _allFaultReport[listRow]['accountNumber'].toString();
  //       //   String address           = _allFaultReport[listRow]['address'].toString();
  //       //   String faultDate         = _allFaultReport[listRow]['dateReported'].toString();
  //       //   String depAllocated      = _allFaultReport[listRow]['depAllocated'].toString();
  //       //   String faultDescription  = _allFaultReport[listRow]['faultDescription'].toString();
  //       //   String faultStage        = _allFaultReport[listRow]['faultStage'].toString();
  //       //   String phoneNumber       = _allFaultReport[listRow]['reporterContact'].toString();
  //       //   String attendeeAlloc     = _allFaultReport[listRow]['attendeeAllocated'].toString();
  //       //   String managerAlloc      = _allFaultReport[listRow]['managerAllocated'].toString();
  //       //   String adminCom          = _allFaultReport[listRow]['adminComment'].toString();
  //       //   String attendeeCom1      = _allFaultReport[listRow]['attendeeCom1'].toString();
  //       //   String managerCom1       = _allFaultReport[listRow]['managerCom1'].toString();
  //       //   String attendeeCom2      = _allFaultReport[listRow]['attendeeCom2'].toString();
  //       //   String managerCom2       = _allFaultReport[listRow]['managerCom2'].toString();
  //       //   String attendeeCom3      = _allFaultReport[listRow]['attendeeCom3'].toString();
  //       //   String managerCom3       = _allFaultReport[listRow]['managerCom3'].toString();
  //       //   String deptSwitchCom     = _allFaultReport[listRow]['departmentSwitchComment'].toString();
  //       //   String reallocCom        = _allFaultReport[listRow]['reallocationComment'].toString();
  //       //   String managerReturnCom  = _allFaultReport[listRow]['managerReturnCom'].toString();
  //       //   String attendeeReturnCom = _allFaultReport[listRow]['attendeeReturnCom'].toString();
  //       //
  //       //   sheet.getRangeByName('A$excelRow').setText(referenceNum);
  //       //   sheet.getRangeByName('B$excelRow').setText(resolveStatus);
  //       //   sheet.getRangeByName('C$excelRow').setText(faultType);
  //       //   sheet.getRangeByName('D$excelRow').setText(accountNum);
  //       //   sheet.getRangeByName('E$excelRow').setText(address);
  //       //   sheet.getRangeByName('F$excelRow').setText(faultDate);
  //       //   sheet.getRangeByName('G$excelRow').setText(depAllocated);
  //       //   sheet.getRangeByName('H$excelRow').setText(faultDescription);
  //       //   sheet.getRangeByName('I$excelRow').setText(faultStage);
  //       //   sheet.getRangeByName('J$excelRow').setText(phoneNumber);
  //       //   sheet.getRangeByName('K$excelRow').setText(attendeeAlloc);
  //       //   sheet.getRangeByName('L$excelRow').setText(managerAlloc);
  //       //   sheet.getRangeByName('M$excelRow').setText(adminCom);
  //       //   sheet.getRangeByName('N$excelRow').setText(attendeeCom1);
  //       //   sheet.getRangeByName('O$excelRow').setText(managerCom1);
  //       //   sheet.getRangeByName('P$excelRow').setText(attendeeCom2);
  //       //   sheet.getRangeByName('Q$excelRow').setText(managerCom2);
  //       //   sheet.getRangeByName('R$excelRow').setText(attendeeCom3);
  //       //   sheet.getRangeByName('S$excelRow').setText(managerCom3);
  //       //   sheet.getRangeByName('T$excelRow').setText(deptSwitchCom);
  //       //   sheet.getRangeByName('U$excelRow').setText(reallocCom);
  //       //   sheet.getRangeByName('V$excelRow').setText(managerReturnCom);
  //       //   sheet.getRangeByName('W$excelRow').setText(attendeeReturnCom);
  //       //
  //       //   excelRow+=1;
  //       //   listRow+=1;
  //       // }
  //
  //       String referenceNum      = _allFaultReport[listRow]['ref'].toString();
  //       String resolveStatus     = _allFaultReport[listRow]['faultResolved'].toString();
  //       String faultType         = _allFaultReport[listRow]['faultType'].toString();
  //       String accountNum        = _allFaultReport[listRow]['accountNumber'].toString();
  //       String address           = _allFaultReport[listRow]['address'].toString();
  //       String faultDate         = _allFaultReport[listRow]['dateReported'].toString();
  //       String depAllocated      = _allFaultReport[listRow]['depAllocated'].toString();
  //       String faultDescription  = _allFaultReport[listRow]['faultDescription'].toString();
  //       String faultStage        = _allFaultReport[listRow]['faultStage'].toString();
  //       String phoneNumber       = _allFaultReport[listRow]['reporterContact'].toString();
  //       String attendeeAlloc     = _allFaultReport[listRow]['attendeeAllocated'].toString();
  //       String managerAlloc      = _allFaultReport[listRow]['managerAllocated'].toString();
  //       String adminCom          = _allFaultReport[listRow]['adminComment'].toString();
  //       String attendeeCom1      = _allFaultReport[listRow]['attendeeCom1'].toString();
  //       String managerCom1       = _allFaultReport[listRow]['managerCom1'].toString();
  //       String attendeeCom2      = _allFaultReport[listRow]['attendeeCom2'].toString();
  //       String managerCom2       = _allFaultReport[listRow]['managerCom2'].toString();
  //       String attendeeCom3      = _allFaultReport[listRow]['attendeeCom3'].toString();
  //       String managerCom3       = _allFaultReport[listRow]['managerCom3'].toString();
  //       String deptSwitchCom     = _allFaultReport[listRow]['departmentSwitchComment'].toString();
  //       String reallocCom        = _allFaultReport[listRow]['reallocationComment'].toString();
  //       String managerReturnCom  = _allFaultReport[listRow]['managerReturnCom'].toString();
  //       String attendeeReturnCom = _allFaultReport[listRow]['attendeeReturnCom'].toString();
  //
  //       sheet.getRangeByName('A$excelRow').setText(referenceNum);
  //       sheet.getRangeByName('B$excelRow').setText(resolveStatus);
  //       sheet.getRangeByName('C$excelRow').setText(faultType);
  //       sheet.getRangeByName('D$excelRow').setText(accountNum);
  //       sheet.getRangeByName('E$excelRow').setText(address);
  //       sheet.getRangeByName('F$excelRow').setText(faultDate);
  //       sheet.getRangeByName('G$excelRow').setText(depAllocated);
  //       sheet.getRangeByName('H$excelRow').setText(faultDescription);
  //       sheet.getRangeByName('I$excelRow').setText(faultStage);
  //       sheet.getRangeByName('J$excelRow').setText(phoneNumber);
  //       sheet.getRangeByName('K$excelRow').setText(attendeeAlloc);
  //       sheet.getRangeByName('L$excelRow').setText(managerAlloc);
  //       sheet.getRangeByName('M$excelRow').setText(adminCom);
  //       sheet.getRangeByName('N$excelRow').setText(attendeeCom1);
  //       sheet.getRangeByName('O$excelRow').setText(managerCom1);
  //       sheet.getRangeByName('P$excelRow').setText(attendeeCom2);
  //       sheet.getRangeByName('Q$excelRow').setText(managerCom2);
  //       sheet.getRangeByName('R$excelRow').setText(attendeeCom3);
  //       sheet.getRangeByName('S$excelRow').setText(managerCom3);
  //       sheet.getRangeByName('T$excelRow').setText(deptSwitchCom);
  //       sheet.getRangeByName('U$excelRow').setText(reallocCom);
  //       sheet.getRangeByName('V$excelRow').setText(managerReturnCom);
  //       sheet.getRangeByName('W$excelRow').setText(attendeeReturnCom);
  //
  //       excelRow+=1;
  //       listRow+=1;
  //     }
  //   }
  //
  //   final List<int> bytes = workbook.saveAsStream();
  //
  //   if(kIsWeb){
  //     AnchorElement(href: 'data:application/ocelot-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
  //         ..setAttribute('download', 'Municiaplity Faults Report $formattedDate.xlsx')
  //         ..click();
  //
  //   } else {
  //     final String path = (await getApplicationSupportDirectory()).path;
  //     final String filename = Platform.isWindows ? '$path\\Municipality Faults Report $formattedDate.xlsx' : '$path/Msunduzi Faults Report $formattedDate.xlsx';
  //     final File file = File(filename);
  //     final List<int> bytes = workbook.saveAsStream();
  //     await file.writeAsBytes(bytes, flush: true);
  //     await OpenFile.open('$path/Municipality Faults Report $formattedDate.xlsx');
  //   }
  //
  //   workbook.dispose();
  //
  // }
  Future<void> reportGeneration() async {
    final excel.Workbook workbook = excel.Workbook();
    final excel.Worksheet sheet = workbook.worksheets[0];

    // Set up headers in the Excel sheet
    sheet.getRangeByName('A1').setText('Ref #');
    sheet.getRangeByName('B1').setText('Resolve Status');
    sheet.getRangeByName('C1').setText('Fault Type');
    sheet.getRangeByName('D1').setText('Account #');
    sheet.getRangeByName('E1').setText('Address');
    sheet.getRangeByName('F1').setText('Report Date');
    sheet.getRangeByName('G1').setText('Department Allocated');
    sheet.getRangeByName('H1').setText('Fault Description');
    sheet.getRangeByName('I1').setText('Fault Stage');
    sheet.getRangeByName('J1').setText('Reporters Phone Number');
    sheet.getRangeByName('K1').setText('Attendee Allocated');
    sheet.getRangeByName('L1').setText('Manager Allocated');
    sheet.getRangeByName('M1').setText('Admin Comment');
    sheet.getRangeByName('N1').setText('Attendee Com1');
    sheet.getRangeByName('O1').setText('Manager Com1');
    sheet.getRangeByName('P1').setText('Attendee Com2');
    sheet.getRangeByName('Q1').setText('Manager Com2');
    sheet.getRangeByName('R1').setText('Attendee Com3');
    sheet.getRangeByName('S1').setText('Manager Com3');
    sheet.getRangeByName('T1').setText('Department Switch Comment');
    sheet.getRangeByName('U1').setText('Reallocation Comment');
    sheet.getRangeByName('V1').setText('Manager Return Comment');
    sheet.getRangeByName('W1').setText('Attendee Return Comment');

    // Fetch fault reports based on selected municipality
    List<DocumentSnapshot> faultReports = [];

    if (selectedMunicipality == 'All Municipalities') {
      // Fetch all faults across each municipality within the district
      var municipalitiesSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .get();

      for (var municipality in municipalitiesSnapshot.docs) {
        var municipalityId = municipality.id;

        QuerySnapshot faultsSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('faultReporting')
            .get();

        faultReports.addAll(faultsSnapshot.docs);
      }
    } else {
      // Fetch faults from the selected municipality only
      QuerySnapshot specificFaultsSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(selectedMunicipality)
          .collection('faultReporting')
          .get();
      faultReports = specificFaultsSnapshot.docs;
    }

    // Populate Excel sheet with data
    int row = 2; // Start from the second row (after headers)
    for (var report in faultReports) {
      String referenceNum = report['ref'] ?? '';
      String resolveStatus = report['faultResolved'] ? 'Resolved' : 'Pending';
      String faultType = report['faultType'] ?? '';
      String accountNum = report['accountNumber'] ?? '';
      String address = report['address'] ?? '';
      String faultDate = report['dateReported'] ?? '';
      String depAllocated = report['depAllocated'] ?? '';
      String faultDescription = report['faultDescription'] ?? '';
      String faultStage = report['faultStage']?.toString() ?? '';
      String phoneNumber = report['reporterContact'] ?? '';
      String attendeeAlloc = report['attendeeAllocated'] ?? '';
      String managerAlloc = report['managerAllocated'] ?? '';
      String adminCom = report['adminComment'] ?? '';
      String attendeeCom1 = report['attendeeCom1'] ?? '';
      String managerCom1 = report['managerCom1'] ?? '';
      String attendeeCom2 = report['attendeeCom2'] ?? '';
      String managerCom2 = report['managerCom2'] ?? '';
      String attendeeCom3 = report['attendeeCom3'] ?? '';
      String managerCom3 = report['managerCom3'] ?? '';
      String deptSwitchCom = report['departmentSwitchComment'] ?? '';
      String reallocCom = report['reallocationComment'] ?? '';
      String managerReturnCom = report['managerReturnCom'] ?? '';
      String attendeeReturnCom = report['attendeeReturnCom'] ?? '';

      // Set data in each cell of the row
      sheet.getRangeByName('A$row').setText(referenceNum);
      sheet.getRangeByName('B$row').setText(resolveStatus);
      sheet.getRangeByName('C$row').setText(faultType);
      sheet.getRangeByName('D$row').setText(accountNum);
      sheet.getRangeByName('E$row').setText(address);
      sheet.getRangeByName('F$row').setText(faultDate);
      sheet.getRangeByName('G$row').setText(depAllocated);
      sheet.getRangeByName('H$row').setText(faultDescription);
      sheet.getRangeByName('I$row').setText(faultStage);
      sheet.getRangeByName('J$row').setText(phoneNumber);
      sheet.getRangeByName('K$row').setText(attendeeAlloc);
      sheet.getRangeByName('L$row').setText(managerAlloc);
      sheet.getRangeByName('M$row').setText(adminCom);
      sheet.getRangeByName('N$row').setText(attendeeCom1);
      sheet.getRangeByName('O$row').setText(managerCom1);
      sheet.getRangeByName('P$row').setText(attendeeCom2);
      sheet.getRangeByName('Q$row').setText(managerCom2);
      sheet.getRangeByName('R$row').setText(attendeeCom3);
      sheet.getRangeByName('S$row').setText(managerCom3);
      sheet.getRangeByName('T$row').setText(deptSwitchCom);
      sheet.getRangeByName('U$row').setText(reallocCom);
      sheet.getRangeByName('V$row').setText(managerReturnCom);
      sheet.getRangeByName('W$row').setText(attendeeReturnCom);

      row++;
    }

    // Save and open the Excel file
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    if (kIsWeb) {
      AnchorElement(
          href:
              'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,${base64.encode(bytes)}')
        ..setAttribute('download', '$selectedMunicipality Faults Report ${formattedDate}.xlsx')
        ..click();
    } else {
      final String path = (await getApplicationSupportDirectory()).path;
      final String filename = Platform.isWindows
          ? '$path\\ $selectedMunicipality Faults_Report_${formattedDate}.xlsx'
          : '$path/$selectedMunicipality Faults_Report_${formattedDate}.xlsx';
      final File file = File(filename);
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open(file.path);
    }
  }

  // Future<void> reportGenerationElectricity() async {
  //   final excel.Workbook workbook = excel.Workbook();
  //   final excel.Worksheet sheet = workbook.worksheets[0];
  //
  //   var data = await FirebaseFirestore.instance.collection('districts')
  //       .doc(districtId)
  //       .collection('municipalities')
  //       .doc(municipalityId)
  //       .collection('faultReporting').get();
  //
  //   _allFaultReport = data.docs;
  //
  //   String column = "A";
  //   int excelRowFill = 2;
  //   int excelRow = 2;
  //   int listRow = 0;
  //
  //   sheet.getRangeByName('A1').setText('Ref #');
  //   sheet.getRangeByName('B1').setText('Resolve Status');
  //   sheet.getRangeByName('C1').setText('Fault Type');
  //   sheet.getRangeByName('D1').setText('Account #');
  //   sheet.getRangeByName('E1').setText('Address');
  //   sheet.getRangeByName('F1').setText('Report Date');
  //   sheet.getRangeByName('G1').setText('Department Allocated');
  //   sheet.getRangeByName('H1').setText('Fault Description');
  //   sheet.getRangeByName('I1').setText('Fault Stage');
  //   sheet.getRangeByName('J1').setText('Reporters Phone Number');
  //   sheet.getRangeByName('K1').setText('Attendee Allocated');
  //   sheet.getRangeByName('L1').setText('Manager Allocated');
  //   sheet.getRangeByName('M1').setText('Admin Comment');
  //   sheet.getRangeByName('N1').setText('Attendee Com1');
  //   sheet.getRangeByName('O1').setText('Manager Com1');
  //   sheet.getRangeByName('P1').setText('Attendee Com2');
  //   sheet.getRangeByName('Q1').setText('Manager Com2');
  //   sheet.getRangeByName('R1').setText('Attendee Com3');
  //   sheet.getRangeByName('S1').setText('Manager Com3');
  //   sheet.getRangeByName('T1').setText('Department SwitchComment');
  //   sheet.getRangeByName('U1').setText('Reallocation Comment');
  //   sheet.getRangeByName('V1').setText('Manager ReturnCom');
  //   sheet.getRangeByName('W1').setText('Attendee ReturnCom');
  //
  //     for (var reportSnapshot in _allFaultReport) {
  //       ///Need to build a property model that retrieves property data entirely from the db
  //       while (excelRow <= _allFaultReport.length + 1) {
  //         if (_allFaultReport[listRow]['faultType'].toString() == 'Electricity') {
  //
  //           print('Report Lists:::: ${_allFaultReport[listRow]['address']}');
  //
  //           String referenceNum      = _allFaultReport[listRow]['ref'].toString();
  //           String resolveStatus     = _allFaultReport[listRow]['faultResolved'].toString();
  //           String faultType         = _allFaultReport[listRow]['faultType'].toString();
  //           String accountNum        = _allFaultReport[listRow]['accountNumber'].toString();
  //           String address           = _allFaultReport[listRow]['address'].toString();
  //           String faultDate         = _allFaultReport[listRow]['dateReported'].toString();
  //           String depAllocated      = _allFaultReport[listRow]['depAllocated'].toString();
  //           String faultDescription  = _allFaultReport[listRow]['faultDescription'].toString();
  //           String faultStage        = _allFaultReport[listRow]['faultStage'].toString();
  //           String phoneNumber       = _allFaultReport[listRow]['reporterContact'].toString();
  //           String attendeeAlloc     = _allFaultReport[listRow]['attendeeAllocated'].toString();
  //           String managerAlloc      = _allFaultReport[listRow]['managerAllocated'].toString();
  //           String adminCom          = _allFaultReport[listRow]['adminComment'].toString();
  //           String attendeeCom1      = _allFaultReport[listRow]['attendeeCom1'].toString();
  //           String managerCom1       = _allFaultReport[listRow]['managerCom1'].toString();
  //           String attendeeCom2      = _allFaultReport[listRow]['attendeeCom2'].toString();
  //           String managerCom2       = _allFaultReport[listRow]['managerCom2'].toString();
  //           String attendeeCom3      = _allFaultReport[listRow]['attendeeCom3'].toString();
  //           String managerCom3       = _allFaultReport[listRow]['managerCom3'].toString();
  //           String deptSwitchCom     = _allFaultReport[listRow]['departmentSwitchComment'].toString();
  //           String reallocCom        = _allFaultReport[listRow]['reallocationComment'].toString();
  //           String managerReturnCom  = _allFaultReport[listRow]['managerReturnCom'].toString();
  //           String attendeeReturnCom = _allFaultReport[listRow]['attendeeReturnCom'].toString();
  //
  //           sheet.getRangeByName('A$excelRowFill').setText(referenceNum);
  //           sheet.getRangeByName('B$excelRowFill').setText(resolveStatus);
  //           sheet.getRangeByName('C$excelRowFill').setText(faultType);
  //           sheet.getRangeByName('D$excelRowFill').setText(accountNum);
  //           sheet.getRangeByName('E$excelRowFill').setText(address);
  //           sheet.getRangeByName('F$excelRowFill').setText(faultDate);
  //           sheet.getRangeByName('G$excelRowFill').setText(depAllocated);
  //           sheet.getRangeByName('H$excelRowFill').setText(faultDescription);
  //           sheet.getRangeByName('I$excelRowFill').setText(faultStage);
  //           sheet.getRangeByName('J$excelRowFill').setText(phoneNumber);
  //           sheet.getRangeByName('K$excelRowFill').setText(attendeeAlloc);
  //           sheet.getRangeByName('L$excelRowFill').setText(managerAlloc);
  //           sheet.getRangeByName('M$excelRowFill').setText(adminCom);
  //           sheet.getRangeByName('N$excelRowFill').setText(attendeeCom1);
  //           sheet.getRangeByName('O$excelRowFill').setText(managerCom1);
  //           sheet.getRangeByName('P$excelRowFill').setText(attendeeCom2);
  //           sheet.getRangeByName('Q$excelRowFill').setText(managerCom2);
  //           sheet.getRangeByName('R$excelRowFill').setText(attendeeCom3);
  //           sheet.getRangeByName('S$excelRowFill').setText(managerCom3);
  //           sheet.getRangeByName('T$excelRowFill').setText(deptSwitchCom);
  //           sheet.getRangeByName('U$excelRowFill').setText(reallocCom);
  //           sheet.getRangeByName('V$excelRowFill').setText(managerReturnCom);
  //           sheet.getRangeByName('W$excelRowFill').setText(attendeeReturnCom);
  //
  //           excelRowFill += 1;
  //           excelRow += 1;
  //           listRow += 1;
  //         } else {
  //           // excelRow += 1;
  //           listRow += 1;
  //         }
  //     }
  //   }
  //
  //   final List<int> bytes = workbook.saveAsStream();
  //
  //   if(kIsWeb){
  //     AnchorElement(href: 'data:application/ocelot-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
  //         ..setAttribute('download', 'Municipality Faults Electricity Report $formattedDate.xlsx')
  //         ..click();
  //
  //   } else {
  //     final String path = (await getApplicationSupportDirectory()).path;
  //     final String filename = Platform.isWindows ? '$path\\Municipality  Faults Electricity Report $formattedDate.xlsx' : '$path/Msunduzi Faults Electricity Report $formattedDate.xlsx';
  //     final File file = File(filename);
  //     final List<int> bytes = workbook.saveAsStream();
  //     await file.writeAsBytes(bytes, flush: true);
  //     await OpenFile.open('$path/Municipality Faults Electricity Report $formattedDate.xlsx');
  //   }
  //
  //   workbook.dispose();
  //
  // }

  Future<void> reportGenerationWater() async {
    final excel.Workbook workbook = excel.Workbook();
    final excel.Worksheet sheet = workbook.worksheets[0];

    var data = await FirebaseFirestore.instance
        .collection('districts')
        .doc(districtId)
        .collection('municipalities')
        .doc(municipalityId)
        .collection('faultReporting')
        .get();

    _allFaultReport = data.docs;

    String column = "A";
    int excelRowFill = 2;
    int excelRow = 2;
    int listRow = 0;

    sheet.getRangeByName('A1').setText('Ref #');
    sheet.getRangeByName('B1').setText('Resolve Status');
    sheet.getRangeByName('C1').setText('Fault Type');
    sheet.getRangeByName('D1').setText('Account #');
    sheet.getRangeByName('E1').setText('Address');
    sheet.getRangeByName('F1').setText('Report Date');
    sheet.getRangeByName('G1').setText('Department Allocated');
    sheet.getRangeByName('H1').setText('Fault Description');
    sheet.getRangeByName('I1').setText('Fault Stage');
    sheet.getRangeByName('J1').setText('Reporters Phone Number');
    sheet.getRangeByName('K1').setText('Attendee Allocated');
    sheet.getRangeByName('L1').setText('Manager Allocated');
    sheet.getRangeByName('M1').setText('Admin Comment');
    sheet.getRangeByName('N1').setText('Attendee Com1');
    sheet.getRangeByName('O1').setText('Manager Com1');
    sheet.getRangeByName('P1').setText('Attendee Com2');
    sheet.getRangeByName('Q1').setText('Manager Com2');
    sheet.getRangeByName('R1').setText('Attendee Com3');
    sheet.getRangeByName('S1').setText('Manager Com3');
    sheet.getRangeByName('T1').setText('Department SwitchComment');
    sheet.getRangeByName('U1').setText('Reallocation Comment');
    sheet.getRangeByName('V1').setText('Manager ReturnCom');
    sheet.getRangeByName('W1').setText('Attendee ReturnCom');

    for (var reportSnapshot in _allFaultReport) {
      ///Need to build a property model that retrieves property data entirely from the db
      while (excelRow <= _allFaultReport.length + 1) {
        if (_allFaultReport[listRow]['faultType'].toString() ==
            'Water & Sanitation') {
          print('Report Lists:::: ${_allFaultReport[listRow]['address']}');

          String referenceNum = _allFaultReport[listRow]['ref'].toString();
          String resolveStatus =
              _allFaultReport[listRow]['faultResolved'].toString();
          String faultType = _allFaultReport[listRow]['faultType'].toString();
          String accountNum =
              _allFaultReport[listRow]['accountNumber'].toString();
          String address = _allFaultReport[listRow]['address'].toString();
          String faultDate =
              _allFaultReport[listRow]['dateReported'].toString();
          String depAllocated =
              _allFaultReport[listRow]['depAllocated'].toString();
          String faultDescription =
              _allFaultReport[listRow]['faultDescription'].toString();
          String faultStage = _allFaultReport[listRow]['faultStage'].toString();
          String phoneNumber =
              _allFaultReport[listRow]['reporterContact'].toString();
          String attendeeAlloc =
              _allFaultReport[listRow]['attendeeAllocated'].toString();
          String managerAlloc =
              _allFaultReport[listRow]['managerAllocated'].toString();
          String adminCom = _allFaultReport[listRow]['adminComment'].toString();
          String attendeeCom1 =
              _allFaultReport[listRow]['attendeeCom1'].toString();
          String managerCom1 =
              _allFaultReport[listRow]['managerCom1'].toString();
          String attendeeCom2 =
              _allFaultReport[listRow]['attendeeCom2'].toString();
          String managerCom2 =
              _allFaultReport[listRow]['managerCom2'].toString();
          String attendeeCom3 =
              _allFaultReport[listRow]['attendeeCom3'].toString();
          String managerCom3 =
              _allFaultReport[listRow]['managerCom3'].toString();
          String deptSwitchCom =
              _allFaultReport[listRow]['departmentSwitchComment'].toString();
          String reallocCom =
              _allFaultReport[listRow]['reallocationComment'].toString();
          String managerReturnCom =
              _allFaultReport[listRow]['managerReturnCom'].toString();
          String attendeeReturnCom =
              _allFaultReport[listRow]['attendeeReturnCom'].toString();

          sheet.getRangeByName('A$excelRowFill').setText(referenceNum);
          sheet.getRangeByName('B$excelRowFill').setText(resolveStatus);
          sheet.getRangeByName('C$excelRowFill').setText(faultType);
          sheet.getRangeByName('D$excelRowFill').setText(accountNum);
          sheet.getRangeByName('E$excelRowFill').setText(address);
          sheet.getRangeByName('F$excelRowFill').setText(faultDate);
          sheet.getRangeByName('G$excelRowFill').setText(depAllocated);
          sheet.getRangeByName('H$excelRowFill').setText(faultDescription);
          sheet.getRangeByName('I$excelRowFill').setText(faultStage);
          sheet.getRangeByName('J$excelRowFill').setText(phoneNumber);
          sheet.getRangeByName('K$excelRowFill').setText(attendeeAlloc);
          sheet.getRangeByName('L$excelRowFill').setText(managerAlloc);
          sheet.getRangeByName('M$excelRowFill').setText(adminCom);
          sheet.getRangeByName('N$excelRowFill').setText(attendeeCom1);
          sheet.getRangeByName('O$excelRowFill').setText(managerCom1);
          sheet.getRangeByName('P$excelRowFill').setText(attendeeCom2);
          sheet.getRangeByName('Q$excelRowFill').setText(managerCom2);
          sheet.getRangeByName('R$excelRowFill').setText(attendeeCom3);
          sheet.getRangeByName('S$excelRowFill').setText(managerCom3);
          sheet.getRangeByName('T$excelRowFill').setText(deptSwitchCom);
          sheet.getRangeByName('U$excelRowFill').setText(reallocCom);
          sheet.getRangeByName('V$excelRowFill').setText(managerReturnCom);
          sheet.getRangeByName('W$excelRowFill').setText(attendeeReturnCom);

          excelRowFill += 1;
          excelRow += 1;
          listRow += 1;
        } else {
          excelRow += 1;
          listRow += 1;
        }
      }
    }

    final List<int> bytes = workbook.saveAsStream();

    if (kIsWeb) {
      AnchorElement(
          href:
              'data:application/ocelot-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
        ..setAttribute('download',
            'Municipality  Faults Water & Sanitation Report $formattedDate.xlsx')
        ..click();
    } else {
      final String path = (await getApplicationSupportDirectory()).path;
      final String filename = Platform.isWindows
          ? '$path\\Municipality Faults Water & Sanitation Report $formattedDate.xlsx'
          : '$path/Msunduzi Faults Water & Sanitation Report $formattedDate.xlsx';
      final File file = File(filename);
      final List<int> bytes = workbook.saveAsStream();
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open(
          '$path/Municipality Faults Water & Sanitation Report $formattedDate.xlsx');
    }

    workbook.dispose();
  }

  // Future<void> reportGenerationWaste() async {
  //   final excel.Workbook workbook = excel.Workbook();
  //   final excel.Worksheet sheet = workbook.worksheets[0];
  //
  //   var data = await FirebaseFirestore.instance.collection('districts')
  //       .doc(districtId)
  //       .collection('municipalities')
  //       .doc(municipalityId)
  //       .collection('faultReporting').get();
  //
  //   _allFaultReport = data.docs;
  //
  //   String column = "A";
  //   int excelRowFill = 2;
  //   int excelRow = 2;
  //   int listRow = 0;
  //
  //   sheet.getRangeByName('A1').setText('Ref #');
  //   sheet.getRangeByName('B1').setText('Resolve Status');
  //   sheet.getRangeByName('C1').setText('Fault Type');
  //   sheet.getRangeByName('D1').setText('Account #');
  //   sheet.getRangeByName('E1').setText('Address');
  //   sheet.getRangeByName('F1').setText('Report Date');
  //   sheet.getRangeByName('G1').setText('Department Allocated');
  //   sheet.getRangeByName('H1').setText('Fault Description');
  //   sheet.getRangeByName('I1').setText('Fault Stage');
  //   sheet.getRangeByName('J1').setText('Reporters Phone Number');
  //   sheet.getRangeByName('K1').setText('Attendee Allocated');
  //   sheet.getRangeByName('L1').setText('Manager Allocated');
  //   sheet.getRangeByName('M1').setText('Admin Comment');
  //   sheet.getRangeByName('N1').setText('Attendee Com1');
  //   sheet.getRangeByName('O1').setText('Manager Com1');
  //   sheet.getRangeByName('P1').setText('Attendee Com2');
  //   sheet.getRangeByName('Q1').setText('Manager Com2');
  //   sheet.getRangeByName('R1').setText('Attendee Com3');
  //   sheet.getRangeByName('S1').setText('Manager Com3');
  //   sheet.getRangeByName('T1').setText('Department SwitchComment');
  //   sheet.getRangeByName('U1').setText('Reallocation Comment');
  //   sheet.getRangeByName('V1').setText('Manager ReturnCom');
  //   sheet.getRangeByName('W1').setText('Attendee ReturnCom');
  //
  //   for (var reportSnapshot in _allFaultReport) {
  //     ///Need to build a property model that retrieves property data entirely from the db
  //     while (excelRow <= _allFaultReport.length + 1) {
  //       if (_allFaultReport[listRow]['faultType'].toString() == 'Waste Management') {
  //
  //         print('Report Lists:::: ${_allFaultReport[listRow]['address']}');
  //
  //         String referenceNum      = _allFaultReport[listRow]['ref'].toString();
  //         String resolveStatus     = _allFaultReport[listRow]['faultResolved'].toString();
  //         String faultType         = _allFaultReport[listRow]['faultType'].toString();
  //         String accountNum        = _allFaultReport[listRow]['accountNumber'].toString();
  //         String address           = _allFaultReport[listRow]['address'].toString();
  //         String faultDate         = _allFaultReport[listRow]['dateReported'].toString();
  //         String depAllocated      = _allFaultReport[listRow]['depAllocated'].toString();
  //         String faultDescription  = _allFaultReport[listRow]['faultDescription'].toString();
  //         String faultStage        = _allFaultReport[listRow]['faultStage'].toString();
  //         String phoneNumber       = _allFaultReport[listRow]['reporterContact'].toString();
  //         String attendeeAlloc     = _allFaultReport[listRow]['attendeeAllocated'].toString();
  //         String managerAlloc      = _allFaultReport[listRow]['managerAllocated'].toString();
  //         String adminCom          = _allFaultReport[listRow]['adminComment'].toString();
  //         String attendeeCom1      = _allFaultReport[listRow]['attendeeCom1'].toString();
  //         String managerCom1       = _allFaultReport[listRow]['managerCom1'].toString();
  //         String attendeeCom2      = _allFaultReport[listRow]['attendeeCom2'].toString();
  //         String managerCom2       = _allFaultReport[listRow]['managerCom2'].toString();
  //         String attendeeCom3      = _allFaultReport[listRow]['attendeeCom3'].toString();
  //         String managerCom3       = _allFaultReport[listRow]['managerCom3'].toString();
  //         String deptSwitchCom     = _allFaultReport[listRow]['departmentSwitchComment'].toString();
  //         String reallocCom        = _allFaultReport[listRow]['reallocationComment'].toString();
  //         String managerReturnCom  = _allFaultReport[listRow]['managerReturnCom'].toString();
  //         String attendeeReturnCom = _allFaultReport[listRow]['attendeeReturnCom'].toString();
  //
  //         sheet.getRangeByName('A$excelRowFill').setText(referenceNum);
  //         sheet.getRangeByName('B$excelRowFill').setText(resolveStatus);
  //         sheet.getRangeByName('C$excelRowFill').setText(faultType);
  //         sheet.getRangeByName('D$excelRowFill').setText(accountNum);
  //         sheet.getRangeByName('E$excelRowFill').setText(address);
  //         sheet.getRangeByName('F$excelRowFill').setText(faultDate);
  //         sheet.getRangeByName('G$excelRowFill').setText(depAllocated);
  //         sheet.getRangeByName('H$excelRowFill').setText(faultDescription);
  //         sheet.getRangeByName('I$excelRowFill').setText(faultStage);
  //         sheet.getRangeByName('J$excelRowFill').setText(phoneNumber);
  //         sheet.getRangeByName('K$excelRowFill').setText(attendeeAlloc);
  //         sheet.getRangeByName('L$excelRowFill').setText(managerAlloc);
  //         sheet.getRangeByName('M$excelRowFill').setText(adminCom);
  //         sheet.getRangeByName('N$excelRowFill').setText(attendeeCom1);
  //         sheet.getRangeByName('O$excelRowFill').setText(managerCom1);
  //         sheet.getRangeByName('P$excelRowFill').setText(attendeeCom2);
  //         sheet.getRangeByName('Q$excelRowFill').setText(managerCom2);
  //         sheet.getRangeByName('R$excelRowFill').setText(attendeeCom3);
  //         sheet.getRangeByName('S$excelRowFill').setText(managerCom3);
  //         sheet.getRangeByName('T$excelRowFill').setText(deptSwitchCom);
  //         sheet.getRangeByName('U$excelRowFill').setText(reallocCom);
  //         sheet.getRangeByName('V$excelRowFill').setText(managerReturnCom);
  //         sheet.getRangeByName('W$excelRowFill').setText(attendeeReturnCom);
  //
  //         excelRowFill += 1;
  //         excelRow += 1;
  //         listRow += 1;
  //       } else {
  //         excelRow += 1;
  //         listRow += 1;
  //       }
  //     }
  //   }
  //
  //   final List<int> bytes = workbook.saveAsStream();
  //
  //   if(kIsWeb){
  //     AnchorElement(href: 'data:application/ocelot-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
  //       ..setAttribute('download', 'Municipality Faults Water & Sanitation Report $formattedDate.xlsx')
  //       ..click();
  //
  //   } else {
  //     final String path = (await getApplicationSupportDirectory()).path;
  //     final String filename = Platform.isWindows ? '$path\\Municipality  Faults Water & Sanitation Report $formattedDate.xlsx' : '$path/Msunduzi Faults Water & Sanitation Report $formattedDate.xlsx';
  //     final File file = File(filename);
  //     final List<int> bytes = workbook.saveAsStream();
  //     await file.writeAsBytes(bytes, flush: true);
  //     await OpenFile.open('$path/Municipality Faults Water & Sanitation Report $formattedDate.xlsx');
  //   }
  //
  //   workbook.dispose();
  //
  // }
  //
  // Future<void> reportGenerationRoadworks() async {
  //   final excel.Workbook workbook = excel.Workbook();
  //   final excel.Worksheet sheet = workbook.worksheets[0];
  //
  //   var data =await FirebaseFirestore.instance.collection('districts')
  //       .doc(districtId)
  //       .collection('municipalities')
  //       .doc(municipalityId)
  //       .collection('faultReporting').get();
  //
  //   _allFaultReport = data.docs;
  //
  //   String column = "A";
  //   int excelRowFill = 2;
  //   int excelRow = 2;
  //   int listRow = 0;
  //
  //   sheet.getRangeByName('A1').setText('Ref #');
  //   sheet.getRangeByName('B1').setText('Resolve Status');
  //   sheet.getRangeByName('C1').setText('Fault Type');
  //   sheet.getRangeByName('D1').setText('Account #');
  //   sheet.getRangeByName('E1').setText('Address');
  //   sheet.getRangeByName('F1').setText('Report Date');
  //   sheet.getRangeByName('G1').setText('Department Allocated');
  //   sheet.getRangeByName('H1').setText('Fault Description');
  //   sheet.getRangeByName('I1').setText('Fault Stage');
  //   sheet.getRangeByName('J1').setText('Reporters Phone Number');
  //   sheet.getRangeByName('K1').setText('Attendee Allocated');
  //   sheet.getRangeByName('L1').setText('Manager Allocated');
  //   sheet.getRangeByName('M1').setText('Admin Comment');
  //   sheet.getRangeByName('N1').setText('Attendee Com1');
  //   sheet.getRangeByName('O1').setText('Manager Com1');
  //   sheet.getRangeByName('P1').setText('Attendee Com2');
  //   sheet.getRangeByName('Q1').setText('Manager Com2');
  //   sheet.getRangeByName('R1').setText('Attendee Com3');
  //   sheet.getRangeByName('S1').setText('Manager Com3');
  //   sheet.getRangeByName('T1').setText('Department SwitchComment');
  //   sheet.getRangeByName('U1').setText('Reallocation Comment');
  //   sheet.getRangeByName('V1').setText('Manager ReturnCom');
  //   sheet.getRangeByName('W1').setText('Attendee ReturnCom');
  //
  //   for (var reportSnapshot in _allFaultReport) {
  //     ///Need to build a property model that retrieves property data entirely from the db
  //     while (excelRow <= _allFaultReport.length + 1) {
  //       if (_allFaultReport[listRow]['faultType'].toString() == 'Roadworks') {
  //
  //         print('Report Lists:::: ${_allFaultReport[listRow]['address']}');
  //
  //         String referenceNum      = _allFaultReport[listRow]['ref'].toString();
  //         String resolveStatus     = _allFaultReport[listRow]['faultResolved'].toString();
  //         String faultType         = _allFaultReport[listRow]['faultType'].toString();
  //         String accountNum        = _allFaultReport[listRow]['accountNumber'].toString();
  //         String address           = _allFaultReport[listRow]['address'].toString();
  //         String faultDate         = _allFaultReport[listRow]['dateReported'].toString();
  //         String depAllocated      = _allFaultReport[listRow]['depAllocated'].toString();
  //         String faultDescription  = _allFaultReport[listRow]['faultDescription'].toString();
  //         String faultStage        = _allFaultReport[listRow]['faultStage'].toString();
  //         String phoneNumber       = _allFaultReport[listRow]['reporterContact'].toString();
  //         String attendeeAlloc     = _allFaultReport[listRow]['attendeeAllocated'].toString();
  //         String managerAlloc      = _allFaultReport[listRow]['managerAllocated'].toString();
  //         String adminCom          = _allFaultReport[listRow]['adminComment'].toString();
  //         String attendeeCom1      = _allFaultReport[listRow]['attendeeCom1'].toString();
  //         String managerCom1       = _allFaultReport[listRow]['managerCom1'].toString();
  //         String attendeeCom2      = _allFaultReport[listRow]['attendeeCom2'].toString();
  //         String managerCom2       = _allFaultReport[listRow]['managerCom2'].toString();
  //         String attendeeCom3      = _allFaultReport[listRow]['attendeeCom3'].toString();
  //         String managerCom3       = _allFaultReport[listRow]['managerCom3'].toString();
  //         String deptSwitchCom     = _allFaultReport[listRow]['departmentSwitchComment'].toString();
  //         String reallocCom        = _allFaultReport[listRow]['reallocationComment'].toString();
  //         String managerReturnCom  = _allFaultReport[listRow]['managerReturnCom'].toString();
  //         String attendeeReturnCom = _allFaultReport[listRow]['attendeeReturnCom'].toString();
  //
  //         sheet.getRangeByName('A$excelRowFill').setText(referenceNum);
  //         sheet.getRangeByName('B$excelRowFill').setText(resolveStatus);
  //         sheet.getRangeByName('C$excelRowFill').setText(faultType);
  //         sheet.getRangeByName('D$excelRowFill').setText(accountNum);
  //         sheet.getRangeByName('E$excelRowFill').setText(address);
  //         sheet.getRangeByName('F$excelRowFill').setText(faultDate);
  //         sheet.getRangeByName('G$excelRowFill').setText(depAllocated);
  //         sheet.getRangeByName('H$excelRowFill').setText(faultDescription);
  //         sheet.getRangeByName('I$excelRowFill').setText(faultStage);
  //         sheet.getRangeByName('J$excelRowFill').setText(phoneNumber);
  //         sheet.getRangeByName('K$excelRowFill').setText(attendeeAlloc);
  //         sheet.getRangeByName('L$excelRowFill').setText(managerAlloc);
  //         sheet.getRangeByName('M$excelRowFill').setText(adminCom);
  //         sheet.getRangeByName('N$excelRowFill').setText(attendeeCom1);
  //         sheet.getRangeByName('O$excelRowFill').setText(managerCom1);
  //         sheet.getRangeByName('P$excelRowFill').setText(attendeeCom2);
  //         sheet.getRangeByName('Q$excelRowFill').setText(managerCom2);
  //         sheet.getRangeByName('R$excelRowFill').setText(attendeeCom3);
  //         sheet.getRangeByName('S$excelRowFill').setText(managerCom3);
  //         sheet.getRangeByName('T$excelRowFill').setText(deptSwitchCom);
  //         sheet.getRangeByName('U$excelRowFill').setText(reallocCom);
  //         sheet.getRangeByName('V$excelRowFill').setText(managerReturnCom);
  //         sheet.getRangeByName('W$excelRowFill').setText(attendeeReturnCom);
  //
  //         excelRowFill += 1;
  //         excelRow += 1;
  //         listRow += 1;
  //       } else {
  //         excelRow += 1;
  //         listRow += 1;
  //       }
  //     }
  //   }
  //
  //   final List<int> bytes = workbook.saveAsStream();
  //
  //   if(kIsWeb){
  //     AnchorElement(href: 'data:application/ocelot-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
  //       ..setAttribute('download', 'Municipality Faults Water & Sanitation Report $formattedDate.xlsx')
  //       ..click();
  //
  //   } else {
  //     final String path = (await getApplicationSupportDirectory()).path;
  //     final String filename = Platform.isWindows ? '$path\\Municipality Faults Water & Sanitation Report $formattedDate.xlsx' : '$path/Msunduzi Faults Water & Sanitation Report $formattedDate.xlsx';
  //     final File file = File(filename);
  //     final List<int> bytes = workbook.saveAsStream();
  //     await file.writeAsBytes(bytes, flush: true);
  //     await OpenFile.open('$path/Municipality  Faults Water & Sanitation Report $formattedDate.xlsx');
  //   }
  //
  //   workbook.dispose();
  //
  // }

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

  List<ReportData> getReportData() {
    final List<ReportData> reportData = [];

    int allReportRow = 1;

    for (var reportSnapshot in _allFaultReport) {
      ///Need to build a property model that retrieves property data entirely from the db
      while (allReportRow <= _allFaultReport.length + 1) {
        reportData.add(ReportData(
          _allFaultReport[allReportRow]['ref'].toString(),
          _allFaultReport[allReportRow]['faultResolved'] as bool,
          _allFaultReport[allReportRow]['faultType'].toString(),
          _allFaultReport[allReportRow]['accountNumber'].toString(),
          _allFaultReport[allReportRow]['address'].toString(),
          _allFaultReport[allReportRow]['dateReported'].toString(),
          _allFaultReport[allReportRow]['depAllocated'].toString(),
          _allFaultReport[allReportRow]['faultDescription'].toString(),
          _allFaultReport[allReportRow]['faultStage'].toString(),
          _allFaultReport[allReportRow]['reporterContact'].toString(),
          _allFaultReport[allReportRow]['attendeeAllocated'].toString(),
          _allFaultReport[allReportRow]['managerAllocated'].toString(),
          _allFaultReport[allReportRow]['adminComment'].toString(),
          _allFaultReport[allReportRow]['attendeeCom1'].toString(),
          _allFaultReport[allReportRow]['managerCom1'].toString(),
          _allFaultReport[allReportRow]['attendeeCom2'].toString(),
          _allFaultReport[allReportRow]['managerCom2'].toString(),
          _allFaultReport[allReportRow]['attendeeCom3'].toString(),
          _allFaultReport[allReportRow]['managerCom3'].toString(),
          _allFaultReport[allReportRow]['departmentSwitchComment'].toString(),
          _allFaultReport[allReportRow]['reallocationComment'].toString(),
          _allFaultReport[allReportRow]['managerReturnCom'].toString(),
          _allFaultReport[allReportRow]['attendeeReturnCom'].toString(),
        ));
        allReportRow += 1;
      }
    }
    return reportData;
  }
}

class ReportData {
  ReportData(
      this.ref,
      this.faultResolved,
      this.faultType,
      this.accountNumber,
      this.address,
      this.dateReported,
      this.depAllocated,
      this.faultDescription,
      this.faultStage,
      this.reporterContact,
      this.attendeeAllocated,
      this.managerAllocated,
      this.adminComment,
      this.attendeeCom1,
      this.managerCom1,
      this.attendeeCom2,
      this.managerCom2,
      this.attendeeCom3,
      this.managerCom3,
      this.departmentSwitchComment,
      this.reallocationComment,
      this.managerReturnCom,
      this.attendeeReturnCom);

  final String ref;
  final bool faultResolved;
  final String faultType;
  final String accountNumber;
  final String address;
  final String dateReported;
  final String depAllocated;
  final String faultDescription;
  final String faultStage;
  final String reporterContact;
  final String attendeeAllocated;
  final String managerAllocated;
  final String adminComment;
  final String attendeeCom1;
  final String managerCom1;
  final String attendeeCom2;
  final String managerCom2;
  final String attendeeCom3;
  final String managerCom3;
  final String departmentSwitchComment;
  final String reallocationComment;
  final String managerReturnCom;
  final String attendeeReturnCom;
}
