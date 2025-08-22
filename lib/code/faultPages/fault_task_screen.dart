import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:municipal_services/code/ImageUploading/image_zoom_fault_page.dart';
import 'package:municipal_services/code/ReportGeneration/display_fault_report.dart';
import 'package:municipal_services/code/faultPages/fault_task_screen_archive.dart';
import 'package:municipal_services/code/MapTools/map_screen.dart';
import 'package:municipal_services/code/MapTools/map_screen_prop.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';

class FaultTaskScreen extends StatefulWidget {
  final String? municipalityUserEmail;
  final String? districtId;
  final String municipalityId;
  final bool isLocalMunicipality;
  final bool isLocalUser;
  const FaultTaskScreen({
    super.key,
    this.municipalityUserEmail,
    this.districtId,
    required this.municipalityId,
    required this.isLocalMunicipality,
    required this.isLocalUser,
  });

  @override
  State<FaultTaskScreen> createState() => _FaultTaskScreenState();
}

final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;
final storageRef = FirebaseStorage.instance.ref();

final FirebaseAuth auth = FirebaseAuth.instance;

final User? user = auth.currentUser;
final uid = user?.uid;
final email = user?.email;
String userID = uid as String;
String myUserEmail = email as String;

class FireStorageService extends ChangeNotifier {
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async {
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

String imageName = '';
String dateReported = '';

LatLng addressLocation = LatLng(0, 0);
LatLng addressLocation2 = LatLng(0, 0);

class _FaultTaskScreenState extends State<FaultTaskScreen>
    with TickerProviderStateMixin {
  CollectionReference? _faultData;
  CollectionReference? _departmentData;
  String? userEmail;
  String districtId = '';
  String municipalityId = '';
  bool isLocalMunicipality = false;
  bool _isLoading = true;
  bool isLocalUser = true;
  List<String> municipalities = []; // To hold the list of municipality names
  String? selectedMunicipality = "Select Municipality";
  List<DocumentSnapshot> filteredProperties = [];
  final FocusNode faultFocusNode = FocusNode();
  final FocusNode noFaultFocusNode = FocusNode();
  final ScrollController _allFaultsScrollController = ScrollController();
  final ScrollController _unassignedFaultsScrollController = ScrollController();
  late TabController _tabController;
  StreamSubscription<QuerySnapshot>? _faultsSubscription;

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance.settings =
        const Settings(persistenceEnabled: false);
    faultFocusNode.requestFocus();
    noFaultFocusNode.requestFocus();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
    });
    _tabController.addListener(() {
      if (_tabController.index == 0) {
        faultFocusNode.requestFocus();
        print(
            "🔄 Tab switched to 'All Department Faults'. Resetting faults...");
      } else if (_tabController.index == 1) {
        noFaultFocusNode.requestFocus();
        print("🔍 Tab switched to 'Unassigned Faults'. Filtering...");
        filterUnassignedFaults();
      }
    });
    faultFocusNode.requestFocus();

    // Listeners for scroll position
    _allFaultsScrollController.addListener(() {});
    _unassignedFaultsScrollController.addListener(() {});
    fetchUserDetails().then((_) {
      print("initState - isLocalMunicipality: $isLocalMunicipality");
      print("initState - districtId: $districtId");
      print("initState - municipalityId: $municipalityId");
      if (!isLocalMunicipality && (selectedMunicipality == null || selectedMunicipality!.isEmpty)) {
        selectedMunicipality = "Select Municipality";
      }

      fetchMunicipalities(); // Fetch all municipalities under district
      setupRealTimeFaultListener(); // 👈 Add this line
      checkRole(); // Initialize role-based streams or settings
      // Fetch similar faults based on department
      if (myDepartment == "Water & Sanitation") {
        getSimilarFaultStreamWater();
        // } else if (myDepartment == "Waste Management") {
        //getSimilarFaultStreamWaste();
        //  } else if (myDepartment == "Roadworks") {
        // getSimilarFaultStreamRoad();
      }
    }).catchError((error) {
      print("Error in fetchUserDetails: $error");
    });

    _searchController.addListener(_onSearchChanged);

    // Loading indicator management
    _isLoading = true;
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    faultFocusNode.dispose();
    noFaultFocusNode.dispose();
    _allFaultsScrollController.dispose();
    _unassignedFaultsScrollController.dispose();
    _faultsSubscription?.cancel();
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    searchText;
    myUserRole;
    myDepartment;
    adminAcc;
    managerAcc;
    employeeAcc;
    visStage1;
    visStage2;
    visStage3;
    visStage4;
    visStage5;
    super.dispose();
  }

  Future<void> fetchUserDetails() async {
    try {
      print("Fetching user details...");
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        userEmail = user.email ?? ''; // Set userEmail safely
        print("User email initialized: $userEmail");

        // Fetch user document using collectionGroup query
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

          // Determine if user belongs to a district-based or local municipality
          if (userPathSegments.contains('districts')) {
            // District-based municipality
            districtId = userPathSegments[1];
            municipalityId = "";
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

          // Log fetched details
          print("After fetchUserDetails:");
          print("districtId: $districtId");
          print("municipalityId: $municipalityId");
          print("isLocalMunicipality: $isLocalMunicipality");
          print("isLocalUser: $isLocalUser");

          // Fetch fault data depending on municipality type
          if (isLocalMunicipality) {
            _faultData = FirebaseFirestore.instance
                .collection('localMunicipalities')
                .doc(municipalityId)
                .collection('faultReporting');
            print(
                "Fetching fault data for local municipality: $municipalityId");
          } else {
            _faultData = FirebaseFirestore.instance
                .collection('districts')
                .doc(districtId)
                .collection('municipalities')
                .doc(municipalityId)
                .collection('faultReporting');
            print(
                "Fetching fault data for district: $districtId, municipality: $municipalityId");
          }

          // After fetching fault data, you can now proceed with any additional logic or streams:
          if (!isLocalMunicipality) {
            await fetchFaultsForAllMunicipalities(); // Fetch faults for all municipalities in the district
          } else {
            await fetchFaultsForLocalMunicipality(); // Fetch faults for the local municipality
          }
        } else {
          print('No user document found.');
        }
      } else {
        print("No current user found.");
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  final _accountNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _commentController = TextEditingController();
  final _deptManagerController = TextEditingController();
  final _depAllocationController = TextEditingController();
  late bool _faultResolvedController;
  final _dateReportedController = TextEditingController();

  // final CollectionReference _faultData =
  // FirebaseFirestore.instance.collection('faultReporting');
  //
  // final CollectionReference _departmentData =
  // FirebaseFirestore.instance.collection('departments');

  String accountNumberRep = '';
  String locationGivenRep = '';
  int faultStage = 0;
  String reporterCellGiven = '';
  String searchText = '';
  String dropdownValue = 'Filter Fault Stage';

  User? user = FirebaseAuth.instance.currentUser;

  TextEditingController _searchController = TextEditingController();
  List _allFaultResults = [];
  List _unassignedFaultResults = [];
  List _similarFaultResults = [];
  List _closeFaultResults = [];
  List<String> _allUserNames = ["Assign User..."];
  List<String> _allUserByNames = ["Assign User..."];
  List<String> _managerUserNames = ["Assign User..."];
  List<String> _employeesUserNames = ["Assign User..."];
  List<String> _deptName = ["Select Department..."];

  String myUserRole = '';
  String myDepartment = '';
  String autoManager = '';
  List _allUserRolesResults = [];
  List _allUserResults = [];
  bool visShow = true;
  bool visHide = false;

  bool visNotification = false;

  bool adminAcc = false;
  bool managerAcc = false;
  bool employeeAcc = false;
  bool visStage1 = false;
  bool visStage2 = false;
  bool visStage3 = false;
  bool visStage4 = false;
  bool visStage5 = false;
  List unassignedResults = [];

  final CollectionReference _listUser =
      FirebaseFirestore.instance.collection('users');

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

        if (municipalitiesSnapshot.docs.isNotEmpty && mounted) {
          if(mounted) {
            setState(() {
              municipalities = municipalitiesSnapshot.docs
                  .map((doc) =>
              doc.id) // Using document ID as the municipality name
                  .toList();

              print("Municipalities list: $municipalities");
              selectedMunicipality =
              "Select Municipality"; // Ensure dropdown default value
            });
          }
        } else {
          if(mounted) {
            setState(() {
              municipalities = []; // Clear if nothing found
              print("No municipalities found");
            });
          }
        }
      } else {
        print("districtId is empty or null.");
      }
    } catch (e) {
      print('Error fetching municipalities: $e');
    }
  }

  Future<List<QueryDocumentSnapshot<Object?>>>
      fetchFaultsForAllMunicipalities() async {
    try {
      if (districtId.isEmpty) {
        print("Error: District ID is empty.");
        return [];
      }

      print(
          "Fetching faults for all municipalities under district: $districtId");

      // Step 1: Fetch all municipalities under the district
      QuerySnapshot municipalitiesSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .get();

      List<QueryDocumentSnapshot> municipalities = municipalitiesSnapshot.docs;

      if (municipalities.isEmpty) {
        print("No municipalities found under district: $districtId");
        return [];
      }

      List<QueryDocumentSnapshot<Object?>> allFaults = [];

      // Step 2: Fetch faults for each municipality
      for (var municipality in municipalities) {
        String municipalityId = municipality.id;
        print("Fetching faults for municipality: $municipalityId");

        QuerySnapshot faultsSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('faultReporting')
            .orderBy('dateReported', descending: true)
            .get();

        allFaults.addAll(faultsSnapshot.docs);
      }

      print("✅ Fetched ${allFaults.length} faults from all municipalities.");
      return allFaults;
    } catch (e) {
      print("Error fetching faults for all municipalities: $e");
      return [];
    }
  }

  void resetFaultsList() async {
    print("🔄 Resetting faults list...");

    List<QueryDocumentSnapshot<Object?>> fetchedFaults = [];

    if (isLocalMunicipality) {
      fetchedFaults = await fetchFaultsForLocalMunicipality();
    } else if (!isLocalMunicipality &&
        selectedMunicipality == "Select Municipality") {
      fetchedFaults = await fetchFaultsForAllMunicipalities();
    } else {
      fetchedFaults = await fetchFaultsByMunicipality(selectedMunicipality!);
    }

    print("✅ Restored full fault list. Total faults: ${fetchedFaults.length}");

    if (mounted) {
      setState(() {
        _allFaultResults = fetchedFaults;
      });
    }
  }

  void setupRealTimeFaultListener() {
    if (_faultsSubscription != null) {
      _faultsSubscription!.cancel(); // Cancel previous listener
    }

    if (isLocalMunicipality) {
      _faultsSubscription = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('faultReporting')
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _allFaultResults = snapshot.docs;
          });
        }
      });
    } else if (!isLocalMunicipality &&
        selectedMunicipality == "Select Municipality") {
      _faultsSubscription = FirebaseFirestore.instance
          .collectionGroup('faultReporting')
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _allFaultResults = snapshot.docs;
          });
        }
      });
    } else if (!isLocalMunicipality && selectedMunicipality != null) {
      _faultsSubscription = FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(selectedMunicipality!)
          .collection('faultReporting')
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _allFaultResults = snapshot.docs;
          });
        }
      });
    }
  }

  void filterUnassignedFaults() async {
    print("🔍 ENTERED filterUnassignedFaults()");

    List<QueryDocumentSnapshot<Object?>> fetchedFaults = [];

    if (isLocalMunicipality) {
      print("🏢 Fetching faults for Local Municipality...");
      fetchedFaults = await fetchFaultsForLocalMunicipality();
    } else if (!isLocalMunicipality && selectedMunicipality == "Select Municipality") {
      print("🌍 Fetching faults for ALL municipalities...");
      fetchedFaults = await fetchFaultsForAllMunicipalities();
    } else {
      print("🏙️ Fetching faults for selected municipality: $selectedMunicipality...");
      fetchedFaults = await fetchFaultsByMunicipality(selectedMunicipality!);
    }

    print("✅ Fetched ${fetchedFaults.length} total faults.");

    // Apply filter: Keep only Stage 1 faults
    List<QueryDocumentSnapshot<Object?>> unassignedFaults = fetchedFaults.where((faultSnapshot) {
      try {
        var data = faultSnapshot.data() as Map<String, dynamic>;
        bool isStage1 = data.containsKey('faultStage') && data['faultStage'] == 1;
        print("🔎 Checking fault: ${data['ref']} - Stage: ${data['faultStage']} - Match: $isStage1");
        return isStage1;
      } catch (e) {
        print("⚠️ Error filtering unassigned faults: $e");
        return false;
      }
    }).toList();

    print("✅ FINAL Unassigned Faults Count: ${unassignedFaults.length}");

    if (mounted) {
      setState(() {
        _allFaultResults = unassignedFaults;
      });
    }
  }


  Future<List<QueryDocumentSnapshot<Object?>>>
      fetchFaultsForLocalMunicipality() async {
    if (municipalityId.isEmpty) {
      print("Error: municipalityId is empty. Cannot fetch properties.");
      return [];
    }

    try {
      print("Fetching faults for local municipality: $municipalityId");

      QuerySnapshot propertiesSnapshot = await FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('faultReporting')
          .get();

      print(
          "✅ Fetched ${propertiesSnapshot.docs.length} faults for local municipality.");
      return propertiesSnapshot.docs;
    } catch (e) {
      print("Error fetching faults for local municipality: $e");
      return [];
    }
  }

  Future<List<QueryDocumentSnapshot<Object?>>> fetchFaultsByMunicipality(
      String municipalityId) async {
    try {
      print("Fetching faults for selected municipality: $municipalityId");

      QuerySnapshot faultSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('faultReporting')
          .get();

      print(
          "✅ Fetched ${faultSnapshot.docs.length} faults for municipality: $municipalityId");
      return faultSnapshot.docs;
    } catch (e) {
      print("Error fetching faults for municipality: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[350],
        appBar: AppBar(
          title: const Text(
            'Faults Reported',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: <Widget>[
            Visibility(
              visible: adminAcc || managerAcc,
              child: Row(
                children: [
                  Text(
                    "Report Generator",
                    style: GoogleFonts.jacquesFrancois(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        fontSize: 14),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ReportBuilderFaults()),
                      );
                    },
                    icon: const Icon(
                      Icons.file_copy_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16), // Spacing between buttons
            Visibility(
              visible: adminAcc,
              child: Row(
                children: [
                  Text(
                    "Completed Faults Archive",
                    style: GoogleFonts.jacquesFrancois(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        fontSize: 14),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const FaultTaskScreenArchive()),
                      );
                    },
                    icon: const Icon(
                      Icons.history_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            onTap: (index) {
              if (index == 0) {
                // "All Faults" tab
                resetFaultsList(); // No filter
              }
              if (index == 1) {
                // "Unassigned Faults" tab
                filterUnassignedFaults(); // Apply filter for stage 1 faults
              }
            },
            tabs: const [
              Tab(
                text: 'All Department Faults',
                icon: FaIcon(Icons.handyman),
              ),
              Tab(
                text: 'Unassigned Faults',
                icon: FaIcon(Icons.pending_actions),
              ),
            ],
          ),
        ),
        body: TabBarView(controller: _tabController, children: [
          ///Tab for all faults
          Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              // Dropdown for district-level users only
              if (!widget.isLocalMunicipality && !widget.isLocalUser)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 40),
                      child: DropdownButton<String>(
                        value: selectedMunicipality,
                        hint: const Text('Select Municipality'),
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          if (newValue != null && mounted) {
                            setState(() {
                              selectedMunicipality = newValue;
                            });

                            print("🔄 Municipality changed: $selectedMunicipality");

                            // ✅ Re-subscribe to correct fault stream
                            setupRealTimeFaultListener();
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
                      )),
                ),

              const SizedBox(height: 10),
              Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 450,
                      height: 50,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: Center(
                          child: TextField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                  )),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                  )),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                  )),
                              disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                  )),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              fillColor: Colors.purple[20],
                              filled: true,
                              suffixIcon: DropdownButtonFormField<String>(
                                value: dropdownValue,
                                items: <String>[
                                  'Filter Fault Stage',
                                  'Stage 1',
                                  'Stage 2',
                                  'Stage 3',
                                  'Stage 4',
                                  'Stage 5'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 0.0, horizontal: 20.0),
                                      child: Text(
                                        value,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (mounted) {
                                    setState(() {
                                      dropdownValue = newValue!;
                                      stageResultsList();
                                    });
                                  }
                                },
                                icon: const Padding(
                                  padding: EdgeInsets.only(left: 10, right: 10),
                                  child: Icon(Icons.arrow_circle_down_sharp),
                                ),
                                iconEnabledColor: Colors.green,
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 18),
                                dropdownColor: Colors.grey[50],
                                isExpanded: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 5.0),
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

              /// Search bar end
              Expanded(
                child: faultCard(),
              ),
              const SizedBox(
                height: 5,
              ),
            ],
          ),
          ///Tab for unassigned faults
          Column(
            children: [
              if (!widget.isLocalMunicipality && !widget.isLocalUser)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 40),
                      child: DropdownButton<String>(
                        value: selectedMunicipality,
                        hint: const Text('Select Municipality'),
                        isExpanded: true,
                        onChanged: (String? newValue) async {
                          if (mounted) {
                            print("🔍 Municipality changed to: $newValue");

                            // Update selected municipality
                            if(mounted) {
                              setState(() {
                                selectedMunicipality = newValue!;
                              });
                            }
                            List<QueryDocumentSnapshot<Object?>> fetchedFaults = [];

                            if (selectedMunicipality == "Select Municipality") {
                              print("🔄 Fetching all faults for all municipalities...");
                              fetchedFaults = await fetchFaultsForAllMunicipalities();
                            } else {
                              print("🏙️ Fetching faults for selected municipality: $selectedMunicipality...");
                              fetchedFaults = await fetchFaultsByMunicipality(selectedMunicipality!);
                            }

                            print("✅ Fetched ${fetchedFaults.length} faults for $selectedMunicipality");

                            if (mounted) {
                              setState(() {
                                _allFaultResults = fetchedFaults;
                              });

                              // 🛑 Ensure filtering runs AFTER the faults are fully updated
                              Future.delayed(Duration.zero, () {
                                print("🔥 Triggering Immediate Filtering for Unassigned Faults...");
                                filterUnassignedFaults();
                              });
                            }
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
                      )),
                ),
              /// Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 5.0),
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
              /// Search bar end
              Expanded(
                child: unassignedFaultCard(),
              ),
              const SizedBox(
                height: 5,
              ),
            ],
          ),
        ]),
      ),
    );
  }

  void getDBDept(CollectionReference dept) async {
    dept.get().then((querySnapshot) async {
      for (var result in querySnapshot.docs) {
        if (_deptName.length - 1 < querySnapshot.docs.length) {
          _deptName.add(result['deptName']);
        }
      }
    });
  }

  ///Looping department collection

  // getFaultStream() async {
  //   try {
  //   //  print("Fetching fault data for district: $districtId, municipality: $municipalityId");
  //
  //     QuerySnapshot data;
  //
  //     if (isLocalMunicipality) {
  //       if (municipalityId.isEmpty) {
  //         print("Error: Municipality ID is empty for local municipality.");
  //         return;
  //       }
  //
  //       // Fetch faults for local municipality
  //       data = await FirebaseFirestore.instance
  //           .collection('localMunicipalities')
  //           .doc(municipalityId)
  //           .collection('faultReporting')
  //           .orderBy('dateReported', descending: true)
  //           .get();
  //     } else {
  //       if (districtId.isEmpty || municipalityId.isEmpty) {
  //         print("Error: District ID or Municipality ID is empty for district-based municipality.");
  //         return;
  //       }
  //
  //       // Fetch faults for district-based municipality
  //       data = await FirebaseFirestore.instance
  //           .collection('districts')
  //           .doc(districtId)
  //           .collection('municipalities')
  //           .doc(municipalityId)
  //           .collection('faultReporting')
  //           .orderBy('dateReported', descending: true)
  //           .get();
  //     }
  //
  //     if (data.docs.isEmpty) {
  //       print("No faults found for this query.");
  //     }
  //
  //     if (mounted) {
  //       setState(() {
  //         _allFaultResults = data.docs;
  //       });
  //    //   print("Updated _allFaultResults with ${_allFaultResults.length} faults");
  //     }
  //
  //    // print("Number of faults retrieved: ${_allFaultResults.length}");
  //     searchResultsList();
  //   } catch (e) {
  //     print("Error fetching fault data: $e");
  //   }
  // }

  getSimilarFaultStreamWater() async {
    try {
      // Fetch all faults first
      QuerySnapshot data;
      if (isLocalMunicipality) {
        if (municipalityId.isNotEmpty) {
          data = await FirebaseFirestore.instance
              .collection('localMunicipalities')
              .doc(municipalityId)
              .collection('faultReporting')
              .orderBy('dateReported', descending: true)
              .get();
        } else {
          print('Error: municipalityId is empty for local municipality.');
          return;
        }
      } else {
        if (districtId.isNotEmpty && municipalityId.isNotEmpty) {
          data = await FirebaseFirestore.instance
              .collection('districts')
              .doc(districtId)
              .collection('municipalities')
              .doc(municipalityId)
              .collection('faultReporting')
              .orderBy('dateReported', descending: true)
              .get();
        } else {
          print(
              'Error: District ID or Municipality ID is empty for district-based municipality.');
          return;
        }
      }

      // Process the results
      _similarFaultResults = data.docs;

      // Query specifically for Water & Sanitation faults
      QuerySnapshot queryWaterSnapshot;
      if (isLocalMunicipality && municipalityId.isNotEmpty) {
        queryWaterSnapshot = await FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(municipalityId)
            .collection('faultReporting')
            .where('faultType', isEqualTo: 'Water & Sanitation')
            .get();
      } else if (districtId.isNotEmpty && municipalityId.isNotEmpty) {
        queryWaterSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('faultReporting')
            .where('faultType', isEqualTo: 'Water & Sanitation')
            .get();
      } else {
        print("Error: Invalid municipality or district IDs.");
        return;
      }

      // Process Water & Sanitation results
      _similarFaultResults = queryWaterSnapshot.docs;
      if (_similarFaultResults.isEmpty) {
        print('No Water & Sanitation faults found');
      }

      for (var fault in queryWaterSnapshot.docs) {
        print('Water Fault fetched: ${fault.data()}');
        // You can now process each fault to calculate distances or other logic as needed
      }
        if(mounted) {
          setState(() {
            _similarFaultResults = queryWaterSnapshot.docs;
          });
        }
    } catch (e) {
      print('Error fetching Water & Sanitation faults: $e');
    }
  }

  // getSimilarFaultStreamWaste() async {
  //   try {
  //     QuerySnapshot data;
  //
  //     if (isLocalMunicipality) {
  //       if (municipalityId.isNotEmpty) {
  //         data = await FirebaseFirestore.instance
  //             .collection('localMunicipalities')
  //             .doc(municipalityId)
  //             .collection('faultReporting')
  //             .orderBy('dateReported', descending: true)
  //             .get();
  //       } else {
  //         print("Error: municipalityId is empty for local municipality.");
  //         return;
  //       }
  //     } else {
  //       if (districtId.isNotEmpty && municipalityId.isNotEmpty) {
  //         data = await FirebaseFirestore.instance
  //             .collection('districts')
  //             .doc(districtId)
  //             .collection('municipalities')
  //             .doc(municipalityId)
  //             .collection('faultReporting')
  //             .orderBy('dateReported', descending: true)
  //             .get();
  //       } else {
  //         print(
  //             "Error: District ID or Municipality ID is empty for district-based municipality.");
  //         return;
  //       }
  //     }
  //
  //     _similarFaultResults = data.docs;
  //
  //     // Fetching specifically for Waste Management faults
  //     QuerySnapshot queryWasteSnapshot;
  //     if (isLocalMunicipality && municipalityId.isNotEmpty) {
  //       queryWasteSnapshot = await FirebaseFirestore.instance
  //           .collection('localMunicipalities')
  //           .doc(municipalityId)
  //           .collection('faultReporting')
  //           .where('faultType', isEqualTo: 'Waste Management')
  //           .get();
  //     } else if (districtId.isNotEmpty && municipalityId.isNotEmpty) {
  //       queryWasteSnapshot = await FirebaseFirestore.instance
  //           .collection('districts')
  //           .doc(districtId)
  //           .collection('municipalities')
  //           .doc(municipalityId)
  //           .collection('faultReporting')
  //           .where('faultType', isEqualTo: 'Waste Management')
  //           .get();
  //     } else {
  //       print("Error: Invalid municipality or district IDs.");
  //       return;
  //     }
  //
  //     _similarFaultResults = queryWasteSnapshot.docs;
  //     if (_similarFaultResults.isEmpty) {
  //       print('No Waste Management faults found');
  //     }
  //
  //     // Additional logic like calculating distances or handling the data can be added here
  //
  //     setState(() {
  //       _similarFaultResults = queryWasteSnapshot.docs;
  //     });
  //   } catch (e) {
  //     print('Error fetching Waste Management faults: $e');
  //   }
  // }

  // getSimilarFaultStreamElectricity() async{
  //   var data = await FirebaseFirestore.instance
  //       .collection('districts')
  //       .doc(districtId)
  //       .collection('municipalities')
  //       .doc(municipalityId)
  //       .collection('faultReporting')
  //       .orderBy('dateReported', descending: true)
  //       .get();
  //
  //   _similarFaultResults = data.docs;
  //   addressLocation=LatLng(0,0);
  //   addressLocation2=LatLng(0,0);
  //
  //   /// Example query to get faults of the water & sanitation type
  //   var queryElectricity = FirebaseFirestore.instance
  //       .collection('districts')
  //       .doc(districtId)
  //       .collection('municipalities')
  //       .doc(municipalityId)
  //       .collection('faultReporting')
  //       .where('faultType', isEqualTo: 'Electricity');
  //
  //   var queryElectricitySnapshot = await queryElectricity.get();
  //
  //   // Iterate through the documents and compare distances
  //   for (var i = 0; i < queryElectricitySnapshot.docs.length; i++) {
  //
  //     var address1 = queryElectricitySnapshot.docs[i]['address'];
  //     addressConvert(address1);
  //
  //     var fault1 = queryElectricitySnapshot.docs[i];
  //     var fault1Coordinates = addressLocation;
  //     // GeoPoint(
  //     //   fault1['latitude'] as double,
  //     //   fault1['longitude'] as double,
  //     // );
  //
  //     // Compare distances using geolocator
  //     for (var j = i + 1; j < queryElectricitySnapshot.docs.length; j++) {
  //       var address2 = queryElectricitySnapshot.docs[i]['address'];
  //       addressConvert2(address2);
  //
  //       var fault2 = queryElectricitySnapshot.docs[j];
  //       var fault2Coordinates = addressLocation2;
  //       // GeoPoint(
  //       //   fault2['latitude'] as double,
  //       //   fault2['longitude'] as double,
  //       // );
  //
  //       if (fault1Coordinates != fault2Coordinates){
  //         // Calculate distance
  //         double distance = await calculateDistance(
  //           fault1Coordinates.latitude,
  //           fault1Coordinates.longitude,
  //           fault2Coordinates.latitude,
  //           fault2Coordinates.longitude,
  //         );
  //
  //         // Check if distance is within 5 meters
  //         if (distance <= 5.0) {
  //           // Flag or process the faults as needed
  //           if(address1 != address2) {
  //             _closeFaultResults.add(address2);
  //
  //             print('Fault at $address1 is within 5 meters of ''Fault at $address2');
  //           }
  //         }
  //       }
  //     }
  //   }
  // }

  // getSimilarFaultStreamRoad() async {
  //   try {
  //     QuerySnapshot data;
  //
  //     if (isLocalMunicipality) {
  //       if (municipalityId.isNotEmpty) {
  //         data = await FirebaseFirestore.instance
  //             .collection('localMunicipalities')
  //             .doc(municipalityId)
  //             .collection('faultReporting')
  //             .orderBy('dateReported', descending: true)
  //             .get();
  //       } else {
  //         print("Error: municipalityId is empty for local municipality.");
  //         return;
  //       }
  //     } else {
  //       if (districtId.isNotEmpty && municipalityId.isNotEmpty) {
  //         data = await FirebaseFirestore.instance
  //             .collection('districts')
  //             .doc(districtId)
  //             .collection('municipalities')
  //             .doc(municipalityId)
  //             .collection('faultReporting')
  //             .orderBy('dateReported', descending: true)
  //             .get();
  //       } else {
  //         print(
  //             "Error: District ID or Municipality ID is empty for district-based municipality.");
  //         return;
  //       }
  //     }
  //
  //     _similarFaultResults = data.docs;
  //
  //     // Fetching specifically for Roadworks faults
  //     QuerySnapshot queryRoadworksSnapshot;
  //     if (isLocalMunicipality && municipalityId.isNotEmpty) {
  //       queryRoadworksSnapshot = await FirebaseFirestore.instance
  //           .collection('localMunicipalities')
  //           .doc(municipalityId)
  //           .collection('faultReporting')
  //           .where('faultType', isEqualTo: 'Roadworks')
  //           .get();
  //     } else if (districtId.isNotEmpty && municipalityId.isNotEmpty) {
  //       queryRoadworksSnapshot = await FirebaseFirestore.instance
  //           .collection('districts')
  //           .doc(districtId)
  //           .collection('municipalities')
  //           .doc(municipalityId)
  //           .collection('faultReporting')
  //           .where('faultType', isEqualTo: 'Roadworks')
  //           .get();
  //     } else {
  //       print("Error: Invalid municipality or district IDs.");
  //       return;
  //     }
  //
  //     _similarFaultResults = queryRoadworksSnapshot.docs;
  //     if (_similarFaultResults.isEmpty) {
  //       print('No Roadworks faults found');
  //     }
  //
  //     // Additional logic like calculating distances or handling the data can be added here
  //
  //     setState(() {
  //       _similarFaultResults = queryRoadworksSnapshot.docs;
  //     });
  //   } catch (e) {
  //     print('Error fetching Roadworks faults: $e');
  //   }
  // }

  Future<double> calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) async {
    try {
      double distanceInMeters = await Geolocator.distanceBetween(
        lat1,
        lon1,
        lat2,
        lon2,
      );
      print('Distance in meters ::: $distanceInMeters');
      return distanceInMeters;
    } catch (e) {
      print('Error calculating distance: $e');
      return 0.0;
    }
  }

  void toggleVisibilityNotification() {
    if(mounted) {
      setState(() {
        visNotification = !visNotification;
      });
    }
  }

  void addressConvert(String address) async {
    ///Location change here for address conversion into lat long
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        List<Location> locations = await locationFromAddress(address);

        if (locations.isNotEmpty) {
          Location location = locations.first;

          double latitude = location.latitude;
          double longitude = location.longitude;

          addressLocation = LatLng(latitude, longitude);
          print('$addressLocation this is the change');
        }
      } catch (e) {
        print('Address incorrect with no latlng to calculate');
      }
    } else {
      ///for web version
      const apiKey = 'AIzaSyCsOGfD-agV8u68pCfeCManNNoSs4csIbY';
      final encodedAddress = Uri.encodeComponent(address);
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey&libraries=maps,drawing,visualization,places,routes&callback=initMap';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];

          double latitude = location['lat'];
          double longitude = location['lng'];

          addressLocation = LatLng(latitude, longitude);
          print('$addressLocation this is the change');
        }
      } else {
        print('Address incorrect with no latlng to calculate');
      }
    }
  }

  void addressConvert2(String address) async {
    ///Location change here for address conversion into lat long
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        List<Location> locations = await locationFromAddress(address);

        if (locations.isNotEmpty) {
          Location location = locations.first;

          double latitude = location.latitude;
          double longitude = location.longitude;

          addressLocation2 = LatLng(latitude, longitude);
          print('$addressLocation2 this is the change');
        }
      } catch (e) {
        print('Address incorrect with no latlng to calculate');
      }
    } else {
      ///for web version
      const apiKey = 'AIzaSyCsOGfD-agV8u68pCfeCManNNoSs4csIbY';
      final encodedAddress = Uri.encodeComponent(address);
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey&libraries=maps,drawing,visualization,places,routes&callback=initMap';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];

          double latitude = location['lat'];
          double longitude = location['lng'];

          addressLocation2 = LatLng(latitude, longitude);
          print('$addressLocation2 this is the change');
        }
      } else {
        print('Address incorrect with no latlng to calculate');
      }
    }
  }

  _onSearchChanged() async {
    searchResultsList();
    searchUnallocatedResultsList();
  }

  searchResultsList() async {
    var showResults = [];
    int dropdownNo = 1;

    // If there is a search text, fetch the relevant faults based on the user's role and selection
    if (_searchController.text != "") {
      if (isLocalMunicipality) {
        await fetchFaultsForLocalMunicipality(); // Fetch faults for the local municipality
      } else if (!isLocalMunicipality &&
          selectedMunicipality == "Select Municipality") {
        await fetchFaultsForAllMunicipalities(); // Fetch faults for all municipalities in the district
      } else {
        await fetchFaultsByMunicipality(
            selectedMunicipality!); // Fetch faults for the selected municipality
      }

      // Filtering logic
      for (var faultSnapshot in _allFaultResults) {
        var address = faultSnapshot['address'].toString().toLowerCase();
        var stage = faultSnapshot['faultStage'];

        if (dropdownValue == 'Filter Fault Stage') {
          if (address.contains(_searchController.text.toLowerCase())) {
            showResults.add(faultSnapshot);
          }
        } else if (dropdownValue == 'Stage 1' && stage == 1) {
          if (address.contains(_searchController.text.toLowerCase())) {
            showResults.add(faultSnapshot);
          }
        } else if (dropdownValue == 'Stage 2' && stage == 2) {
          if (address.contains(_searchController.text.toLowerCase())) {
            showResults.add(faultSnapshot);
          }
        } else if (dropdownValue == 'Stage 3' && stage == 3) {
          if (address.contains(_searchController.text.toLowerCase())) {
            showResults.add(faultSnapshot);
          }
        } else if (dropdownValue == 'Stage 4' && stage == 4) {
          if (address.contains(_searchController.text.toLowerCase())) {
            showResults.add(faultSnapshot);
          }
        } else if (dropdownValue == 'Stage 5' && stage == 5) {
          if (address.contains(_searchController.text.toLowerCase())) {
            showResults.add(faultSnapshot);
          }
        }
      }
    } else if (dropdownValue != 'Filter Fault Stage') {
      if (isLocalMunicipality) {
        await fetchFaultsForLocalMunicipality();
      } else if (!isLocalMunicipality &&
          selectedMunicipality == "Select Municipality") {
        await fetchFaultsForAllMunicipalities();
      } else {
        await fetchFaultsByMunicipality(selectedMunicipality!);
      }

      // Filtering logic for when there is no search text but the dropdown filter is active
      for (var faultSnapshot in _allFaultResults) {
        var address = faultSnapshot['address'].toString().toLowerCase();
        var stage = faultSnapshot['faultStage'];

        if (dropdownValue == 'Stage 1' && stage == 1) {
          showResults.add(faultSnapshot);
        } else if (dropdownValue == 'Stage 2' && stage == 2) {
          showResults.add(faultSnapshot);
        } else if (dropdownValue == 'Stage 3' && stage == 3) {
          showResults.add(faultSnapshot);
        } else if (dropdownValue == 'Stage 4' && stage == 4) {
          showResults.add(faultSnapshot);
        } else if (dropdownValue == 'Stage 5' && stage == 5) {
          showResults.add(faultSnapshot);
        }
      }
    } else {
      if (isLocalMunicipality) {
        await fetchFaultsForLocalMunicipality();
      } else if (!isLocalMunicipality &&
          selectedMunicipality == "Select Municipality") {
        await fetchFaultsForAllMunicipalities();
      } else {
        await fetchFaultsByMunicipality(selectedMunicipality!);
      }

      showResults = List.from(_allFaultResults);
    }

    // Update the state with the filtered results
    if (mounted) {
      setState(() {
        _allFaultResults = showResults;
      });
    }
  }

  searchUnallocatedResultsList() async {
    var showResults = [];
    int dropdownNo = 1;

    // If there is search text, fetch relevant faults
    if (_searchController.text != "") {
      // You may add specific search functionality for unallocated faults here if needed
    } else if (dropdownValue != 'Filter Fault Stage') {
      // Fetch unallocated faults based on user's role
      if (isLocalMunicipality) {
        await fetchFaultsForLocalMunicipality(); // Fetch faults for the local municipality
      } else if (!isLocalMunicipality &&
          selectedMunicipality == "Select Municipality") {
        await fetchFaultsForAllMunicipalities(); // Fetch faults for all municipalities in the district
      } else {
        await fetchFaultsByMunicipality(
            selectedMunicipality!); // Fetch faults for the selected municipality
      }

      // Filter results based on the selected dropdown stage
      for (var faultSnapshot in _unassignedFaultResults) {
        var address = faultSnapshot['address'].toString().toLowerCase();
        var stage = faultSnapshot['faultStage'];

        if (dropdownValue == 'Stage 1' && stage == 1) {
          if (address.contains(_searchController.text.toLowerCase())) {
            showResults.add(faultSnapshot);
          } else {
            showResults.add(faultSnapshot);
          }
        } else if (dropdownValue == 'Stage 2' && stage == 2) {
          if (address.contains(_searchController.text.toLowerCase())) {
            showResults.add(faultSnapshot);
          } else {
            showResults.add(faultSnapshot);
          }
        } else if (dropdownValue == 'Stage 3' && stage == 3) {
          if (address.contains(_searchController.text.toLowerCase())) {
            showResults.add(faultSnapshot);
          } else {
            showResults.add(faultSnapshot);
          }
        } else if (dropdownValue == 'Stage 4' && stage == 4) {
          if (address.contains(_searchController.text.toLowerCase())) {
            showResults.add(faultSnapshot);
          } else {
            showResults.add(faultSnapshot);
          }
        } else if (dropdownValue == 'Stage 5' && stage == 5) {
          if (address.contains(_searchController.text.toLowerCase())) {
            showResults.add(faultSnapshot);
          } else {
            showResults.add(faultSnapshot);
          }
        } else {
          showResults = List.from(
              _unassignedFaultResults); // Default to all unassigned faults if no dropdown filter
        }
      }
    }

    // Update the state with the filtered results
    if (mounted) {
      setState(() {
        _unassignedFaultResults = showResults;
      });
    }
  }

  Future<void> stageResultsList() async {
    var showResults = [];

    if (dropdownValue != 'Filter Fault Stage') {
      // Fetch faults based on the user's role and selection
      if (isLocalMunicipality) {
        await fetchFaultsForLocalMunicipality();
      } else if (!isLocalMunicipality &&
          selectedMunicipality == "Select Municipality") {
        await fetchFaultsForAllMunicipalities();
      } else {
        await fetchFaultsByMunicipality(selectedMunicipality!);
      }

      // Filter results based on the selected stage
      for (var faultSnapshot in _allFaultResults) {
        var stage = faultSnapshot['faultStage'];

        if (dropdownValue == 'Stage 1' && stage == 1) {
          showResults.add(faultSnapshot);
        } else if (dropdownValue == 'Stage 2' && stage == 2) {
          showResults.add(faultSnapshot);
        } else if (dropdownValue == 'Stage 3' && stage == 3) {
          showResults.add(faultSnapshot);
        } else if (dropdownValue == 'Stage 4' && stage == 4) {
          showResults.add(faultSnapshot);
        } else if (dropdownValue == 'Stage 5' && stage == 5) {
          showResults.add(faultSnapshot);
        }
      }
    } else {
      // ✅ FIX: If resetting filter, fetch all faults again to restore the full list
      if (isLocalMunicipality) {
        showResults = await fetchFaultsForLocalMunicipality();
      } else if (!isLocalMunicipality &&
          selectedMunicipality == "Select Municipality") {
        showResults = await fetchFaultsForAllMunicipalities();
      } else {
        showResults = await fetchFaultsByMunicipality(selectedMunicipality!);
      }
    }

    if (mounted) {
      // ✅ Update the state with either the filtered or restored full dataset
      setState(() {
        _allFaultResults = showResults;
      });
    }
  }

  void checkRole() {
    getUsersStream();
    if (myUserRole == 'Admin' || myUserRole == 'Administrator') {
      adminAcc = true;
      managerAcc = false;
      employeeAcc = false;
    } else if (myUserRole == 'Manager') {
      adminAcc = false;
      managerAcc = true;
      employeeAcc = false;
    } else {
      adminAcc = false;
      managerAcc = false;
      employeeAcc = true;
    }
  }

  getUsersStream() async {
    QuerySnapshot data;

    try {
      if (isLocalMunicipality) {
        // Fetch users for local municipality
        if (municipalityId.isEmpty) {
          print("Error: Municipality ID is empty for local municipality.");
          return;
        }

        data = await FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(municipalityId)
            .collection('users')
            .get();
      } else {
        // District-based user: fetch users from all municipalities under the district
        if (municipalityId.isEmpty) {
          print(
              "No specific municipalityId found, fetching users from all municipalities under district: $districtId");

          // Use collectionGroup to search across all municipalities under the district
          data = await FirebaseFirestore.instance
              .collectionGroup(
                  'users') // Search across all municipalities' users under the district
              .where('districtId', isEqualTo: districtId)
              .get();
        } else {
          // Fetch users for the specific municipality
          data = await FirebaseFirestore.instance
              .collection('districts')
              .doc(districtId)
              .collection('municipalities')
              .doc(municipalityId)
              .collection('users')
              .get();
        }
      }

      if (data.docs.isEmpty) {
        print("No users found for this query.");
      }

      _allUserRolesResults = data.docs;
      getUserDetails(); // Process the user details after fetching
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  getUserDetails() async {
    try {
      for (var userSnapshot in _allUserRolesResults) {
        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;

        // Safely retrieve user fields
        var userEmail = userData['email'] ?? '';
        var role = userData['userRole'] ?? 'Unknown';
        var userName = userData['userName'] ?? 'Unknown';
        var firstName = userData['firstName'] ?? 'Unknown';
        var lastName = userData['lastName'] ?? 'Unknown';
        var userDepartment = userData['deptName'] ?? 'Unknown';

        // Add user data to lists
        _allUserNames.add(userName);
        _allUserByNames.add('$firstName $lastName');

        // Check if the current user is the logged-in user
        if (userEmail == myUserEmail) {
          myUserRole = role;
          myDepartment = userDepartment;

          print('My Role is::: $myUserRole');
          print('My Department is::: $myDepartment');

          // Assign role-based access
          if (myUserRole == 'Admin' || myUserRole == 'Administrator') {
            adminAcc = true;
            managerAcc = false;
            employeeAcc = false;
          } else if (myUserRole == 'Manager') {
            adminAcc = false;
            managerAcc = true;
            employeeAcc = false;
          } else {
            adminAcc = false;
            managerAcc = false;
            employeeAcc = true;
          }

          // Fetch similar faults based on department
          fetchSimilarFaultsBasedOnDepartment();
        }
      }

      getUserDepartmentDetails(); // Additional method to fetch department details
    } catch (e) {
      print("Error in getUserDetails: $e");
    }
  }

  void fetchSimilarFaultsBasedOnDepartment() {
    if (myDepartment == "Water & Sanitation") {
      getSimilarFaultStreamWater();
      // } else if (myDepartment == "Waste Management") {
      //   getSimilarFaultStreamWaste();
      // } else if (myDepartment == "Roadworks") {
      //   getSimilarFaultStreamRoad();
    } else if (myDepartment == "Service Provider") {
      getSimilarFaultStreamWater();
      // getSimilarFaultStreamWaste();
      // getSimilarFaultStreamRoad();
    }
  }

  getUserDepartmentDetails() async {
    try {
      QuerySnapshot data;

      if (isLocalMunicipality) {
        // Handle for local municipality users
        if (municipalityId.isNotEmpty) {
          data = await FirebaseFirestore.instance
              .collection('localMunicipalities')
              .doc(municipalityId)
              .collection('users')
              .get();
        } else {
          print("Error: Municipality ID is empty for local municipality.");
          return;
        }
      } else {
        // Handle for district-based municipality users
        if (districtId.isNotEmpty) {
          // Since municipalityId might be empty, we avoid it in this query
          data = await FirebaseFirestore.instance
              .collectionGroup('users')
              .where('districtId', isEqualTo: districtId)
              .get();
        } else {
          print("Error: District ID is empty.");
          return;
        }
      }

      _allUserResults = data.docs;

      for (var userSnapshot in _allUserResults) {
        var userEmail = userSnapshot['email'].toString();
        var role = userSnapshot.data().containsKey('userRole')
            ? userSnapshot['userRole'].toString()
            : 'Unknown';
        var userName = userSnapshot.data().containsKey('userName')
            ? userSnapshot['userName'].toString()
            : 'Unknown';
        var firstName = userSnapshot['firstName'].toString();
        var lastName = userSnapshot['lastName'].toString();
        var userDepartment = userSnapshot.data().containsKey('deptName')
            ? userSnapshot['deptName'].toString()
            : 'Unknown';

        if (role == 'Manager') {
          if (userDepartment == myDepartment) {
            _managerUserNames.add(userName);
            autoManager = userName;
          }
        } else if (role == 'Employee') {
          if (userDepartment == myDepartment) {
            _employeesUserNames.add(userName);
          }
        }
      }
      _employeesUserNames = _employeesUserNames.toSet().toList();

      print("User details fetched successfully.");
    } catch (e) {
      print("Error fetching user department details: $e");
    }
  }

  Future<Widget> _getImage(BuildContext context, String imageName) async {
    Image image;
    final value = await FireStorageService.loadImage(context, imageName);

    final imageUrl = await storageRef.child(imageName).getDownloadURL();

    ///Check what the app is running on
    if (defaultTargetPlatform == TargetPlatform.android) {
      image = Image.network(
        value.toString(),
        fit: BoxFit.fill,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      // print('The url is::: $imageUrl');
      image = Image.network(
        imageUrl,
        fit: BoxFit.fitHeight,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return image;
  }

  //this widget is for displaying a property field of information with an icon next to it, NB. the icon is to make it look good
  //it is called within a listview page widget
  Widget faultItemField(String faultDat) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 6,
          ),
          Text(
            faultDat,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  String getFaultStageText(int stage) {
    switch (stage) {
      case 1:
        return "Initial Report";
      case 2:
        return "In Progress";
      case 3:
        return "Escalated";
      case 4:
        return "Resolved";
      case 5:
        return "Closed";
      default:
        return "Unknown";
    }
  }

  Color getFaultStageColor(int stage) {
    switch (stage) {
      case 1:
        return Colors.deepOrange;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.orangeAccent;
      case 4:
        return Colors.greenAccent;
      case 5:
        return Colors.lightGreen;
      default:
        return Colors.grey;
    }
  }

  void _callReporter(Map<String, dynamic> fault) {
    String reporterPhone = fault['reporterContact'] ?? '';

    if (reporterPhone.isNotEmpty) {
      final Uri tel = Uri.parse('tel:$reporterPhone');
      launchUrl(tel);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No reporter contact found')),
      );
    }
  }

  // void _updateReport(Map<String, dynamic> fault) {
  //   // Logic to update the fault report (can include form submission, editing fields, etc.)
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => UpdateFaultScreen(
  //         faultData: fault,
  //       ),
  //     ),
  //   );
  // }

  Widget faultCard() {
    if (_allFaultResults.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          // Refocus when tapping within the tab content
          faultFocusNode.requestFocus();
        },
        child: KeyboardListener(
          focusNode: faultFocusNode,
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent) {
              final double pageScrollAmount =
                  _allFaultsScrollController.position.viewportDimension;

              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                _allFaultsScrollController.animateTo(
                  _allFaultsScrollController.offset + 50,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                _allFaultsScrollController.animateTo(
                  _allFaultsScrollController.offset - 50,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
                _allFaultsScrollController.animateTo(
                  _allFaultsScrollController.offset + pageScrollAmount,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
                _allFaultsScrollController.animateTo(
                  _allFaultsScrollController.offset - pageScrollAmount,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                );
              }
            }
          },
          child: Scrollbar(
            controller: _allFaultsScrollController,
            thickness: 12, // Customize the thickness of the scrollbar
            radius: const Radius.circular(8), // Rounded edges for the scrollbar
            thumbVisibility: true,
            trackVisibility: true, // Makes the track visible as well
            interactive: true,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _allFaultsScrollController,
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _allFaultResults.length,
                    itemBuilder: (context, index) {
                      if (index >= _allFaultResults.length) {
                        // Ensure index does not exceed the bounds
                        return const SizedBox();
                      }

                      var fault =
                          (_allFaultResults[index] as QueryDocumentSnapshot)
                              .data() as Map<String, dynamic>;
                      if (fault.isEmpty) {
                        return const SizedBox(); // Skip empty faults
                      }
                      String status = (fault['faultResolved'] == false)
                          ? "Pending"
                          : "Completed";
                      bool showNotification =
                          (fault['attendeeAllocated'] == '' ||
                              fault['faultStage'] == 1 ||
                              fault['faultResolved'] == false);

                      var faultAddress = (fault['address'] != null &&
                              fault['address'].isNotEmpty)
                          ? fault['address']
                          : 'No address provided';
                      var faultType = (fault['faultType'] != null &&
                              fault['faultType'].isNotEmpty)
                          ? fault['faultType']
                          : 'No fault type provided';

                      // Convert dateReported to a formatted string if it's a Timestamp
                      var dateReported;
                      if (fault['dateReported'] is Timestamp) {
                        dateReported = DateFormat('yyyy-MM-dd – kk:mm').format(
                          fault['dateReported'].toDate(),
                        );
                      } else {
                        dateReported =
                            fault['dateReported']; // If it's already a string
                      }

                      // Clean the address to remove invalid characters
                      String cleanedAddress =
                          faultAddress.replaceAll(RegExp(r'[\/:*?"<>|]'), '');

                      // Render card only if the fault is related to the user's department
                      if (myDepartment == fault['faultType']) {
                        return Card(
                          margin:
                              const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment
                                        .center, // Align items vertically in the center
                                    children: [
                                      Visibility(
                                        visible: showNotification,
                                        child: const Column(
                                          // Use Column to stack notification and text vertically
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.notification_important,
                                                color: Colors.red),
                                            SizedBox(width: 5),
                                            Text(
                                              'Attention needed!',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Centralize "Fault Information" again
                                      const Expanded(
                                        child: Center(
                                          // This centers the "Fault Information" text
                                          child: Text(
                                            'Fault Information',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            textAlign: TextAlign
                                                .center, // Ensure text is centered
                                          ),
                                        ),
                                      ),
                                      Visibility(
                                        visible: visNotification,
                                        child: const Icon(
                                          Icons.notification_important,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 10),
                                Text(
                                  'Reference Number: ${fault['ref']}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: 5),
                                if (fault['accountNumber'] != "") ...[
                                  Text(
                                    'Reporter Account Number: ${fault['accountNumber']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5),
                                ],

                                Text(
                                  'Street Address of Fault: $faultAddress',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: 5),

                                Text(
                                  'Fault Type: $faultType',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Date of Fault Report: $dateReported',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: 5),

                                if (fault['faultDescription'] != "") ...[
                                  Text(
                                    'Fault Description: ${fault['faultDescription']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5),
                                ],

                                if (fault['managerAllocated'] != "") ...[
                                  Text(
                                    'Manager Allocated: ${fault['managerAllocated']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5),
                                ],

                                if (fault['attendeeAllocated'] != "") ...[
                                  Text(
                                    'Attendee Allocated: ${fault['attendeeAllocated']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5),
                                ],

                                // Comments Section (Manager and Attendee Comments)
                                if (fault['managerCom1'] != "") ...[
                                  Text(
                                    'Manager Comment: ${fault['managerCom1']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5),
                                ],
                                if (fault['attendeeCom1'] != "") ...[
                                  Text(
                                    'Attendee Comment: ${fault['attendeeCom1']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5),
                                ],
                                if (fault['managerCom2'] != "") ...[
                                  Text(
                                    'Manager Follow-up Comment: ${fault['managerCom2']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5),
                                ],
                                if (fault['attendeeCom2'] != "") ...[
                                  Text(
                                    'Attendee Follow-up Comment: ${fault['attendeeCom2']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5),
                                ],
                                if (fault['managerReturnCom'] != "") ...[
                                  Text(
                                    'Reason for return: ${fault['managerReturnCom']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5),
                                ],
                                if (fault['adminComment'] != null &&
                                    fault['adminComment'].isNotEmpty) ...[
                                  Text(
                                    'Admin Comment: ${fault['adminComment']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5),
                                ],

                                Text(
                                  'Resolve State: $status',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: 5),

                                Text(
                                  'Fault Stage: ${fault['faultStage'].toString()}',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: getFaultStageColor(
                                          fault['faultStage'])),
                                ),
                                const SizedBox(height: 5),
                                Center(
                                  child: Column(
                                    children: [
                                      // First Row with "View Fault Image", "Location", "Call User"
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: 10.0, // Space between buttons
                                        runSpacing:
                                            10.0, // Space between rows when wrapped
                                        children: [
                                          BasicIconButtonGrey(
                                            onPress: () async {
                                              try {
                                                if (!isLocalUser &&
                                                    !isLocalMunicipality) {
                                                  if (selectedMunicipality ==
                                                          null ||
                                                      selectedMunicipality ==
                                                          "Select Municipality") {
                                                    Fluttertoast.showToast(
                                                      msg:
                                                          "Please select a municipality first!",
                                                      toastLength:
                                                          Toast.LENGTH_SHORT,
                                                      gravity:
                                                          ToastGravity.CENTER,
                                                    );
                                                    return;
                                                  }
                                                }

                                                String municipalityContext =
                                                    isLocalMunicipality ||
                                                            isLocalUser
                                                        ? municipalityId
                                                        : selectedMunicipality!;

                                                if (municipalityContext
                                                    .isEmpty) {
                                                  Fluttertoast.showToast(
                                                    msg:
                                                        "Invalid municipality selection or missing municipality.",
                                                    toastLength:
                                                        Toast.LENGTH_SHORT,
                                                    gravity:
                                                        ToastGravity.CENTER,
                                                  );
                                                  return;
                                                }
                                                String dateReported =
                                                    fault['dateReported'];

                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ImageZoomFaultPage(
                                                      imageName: cleanedAddress,
                                                      dateReported:
                                                          dateReported,
                                                      municipalityId:
                                                          selectedMunicipality ??
                                                              '',
                                                      isLocalMunicipality:
                                                          isLocalMunicipality,
                                                      districtId: districtId,
                                                      isLocalUser: isLocalUser,
                                                    ),
                                                  ),
                                                );
                                              } catch (e) {
                                                Fluttertoast.showToast(
                                                  msg:
                                                      "Error: Unable to view fault image.",
                                                  toastLength:
                                                      Toast.LENGTH_SHORT,
                                                  gravity: ToastGravity.CENTER,
                                                );
                                              }
                                            },
                                            labelText: 'View Fault Image',
                                            fSize: 14,
                                            faIcon: const FaIcon(Icons.zoom_in),
                                            fgColor: Colors.grey,
                                            btSize: const Size(100, 38),
                                          ),
                                          BasicIconButtonGrey(
                                            onPress: () async {
                                              try {
                                                if (!isLocalUser &&
                                                    !isLocalMunicipality) {
                                                  if (selectedMunicipality ==
                                                          null ||
                                                      selectedMunicipality ==
                                                          "Select Municipality") {
                                                    Fluttertoast.showToast(
                                                      msg:
                                                          "Please select a municipality first!",
                                                      toastLength:
                                                          Toast.LENGTH_SHORT,
                                                      gravity:
                                                          ToastGravity.CENTER,
                                                    );
                                                    return;
                                                  }
                                                }

                                                String municipalityContext =
                                                    isLocalMunicipality ||
                                                            isLocalUser
                                                        ? municipalityId
                                                        : selectedMunicipality!;

                                                if (municipalityContext
                                                    .isEmpty) {
                                                  Fluttertoast.showToast(
                                                    msg:
                                                        "Invalid municipality selection or missing municipality.",
                                                    toastLength:
                                                        Toast.LENGTH_SHORT,
                                                    gravity:
                                                        ToastGravity.CENTER,
                                                  );
                                                  return;
                                                }

                                                accountNumberRep =
                                                    fault['accountNumber'];
                                                locationGivenRep =
                                                    fault['address'];

                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        MapScreenProp(
                                                      propAddress:
                                                          locationGivenRep,
                                                      propAccNumber:
                                                          accountNumberRep,
                                                    ),
                                                  ),
                                                );
                                              } catch (e) {
                                                Fluttertoast.showToast(
                                                  msg:
                                                      "Error: Unable to view location.",
                                                  toastLength:
                                                      Toast.LENGTH_SHORT,
                                                  gravity: ToastGravity.CENTER,
                                                );
                                              }
                                            },
                                            labelText: 'Location',
                                            fSize: 14,
                                            faIcon: const FaIcon(Icons.map),
                                            fgColor: Colors.green,
                                            btSize: const Size(50, 38),
                                          ),
                                          BasicIconButtonGrey(
                                            onPress: () async {
                                              try {
                                                if (!isLocalUser &&
                                                    !isLocalMunicipality) {
                                                  if (selectedMunicipality ==
                                                          null ||
                                                      selectedMunicipality ==
                                                          "Select Municipality") {
                                                    Fluttertoast.showToast(
                                                      msg:
                                                          "Please select a municipality first!",
                                                      toastLength:
                                                          Toast.LENGTH_SHORT,
                                                      gravity:
                                                          ToastGravity.CENTER,
                                                    );
                                                    return;
                                                  }
                                                }

                                                String reporterContact =
                                                    fault['reporterContact'];
                                                showDialog(
                                                  barrierDismissible: false,
                                                  context: context,
                                                  builder: (context) {
                                                    return AlertDialog(
                                                      shape:
                                                          const RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    16)),
                                                      ),
                                                      title: const Text(
                                                          "Call Reporter!"),
                                                      content: const Text(
                                                          "Would you like to call the individual who logged the fault?"),
                                                      actions: [
                                                        IconButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          icon: const Icon(
                                                              Icons.cancel,
                                                              color:
                                                                  Colors.red),
                                                        ),
                                                        IconButton(
                                                          onPressed: () {
                                                            final Uri tel =
                                                                Uri.parse(
                                                                    'tel:$reporterContact');
                                                            launchUrl(tel);
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          icon: const Icon(
                                                              Icons.done,
                                                              color:
                                                                  Colors.green),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              } catch (e) {
                                                Fluttertoast.showToast(
                                                  msg:
                                                      "Error: Unable to call reporter.",
                                                  toastLength:
                                                      Toast.LENGTH_SHORT,
                                                  gravity: ToastGravity.CENTER,
                                                );
                                              }
                                            },
                                            labelText: 'Call User',
                                            fSize: 14,
                                            faIcon: const FaIcon(Icons.call),
                                            fgColor: Colors.orange,
                                            btSize: const Size(50, 38),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                          height:
                                              10), // Add space between the rows
                                      // Second Row with "Reassign", "Update", and "Reallocate Department"
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: 10.0,
                                        runSpacing: 10.0,
                                        children: [
                                          if (adminAcc) ...[
                                            BasicIconButtonGrey(
                                              onPress: () async {
                                                if (!isLocalUser &&
                                                    !isLocalMunicipality) {
                                                  if (selectedMunicipality ==
                                                          null ||
                                                      selectedMunicipality ==
                                                          "Select Municipality") {
                                                    Fluttertoast.showToast(
                                                      msg:
                                                          "Please select a municipality first!",
                                                      toastLength:
                                                          Toast.LENGTH_SHORT,
                                                      gravity:
                                                          ToastGravity.CENTER,
                                                    );
                                                    return;
                                                  }
                                                }

                                                String municipalityContext =
                                                    isLocalMunicipality ||
                                                            isLocalUser
                                                        ? municipalityId
                                                        : selectedMunicipality!;

                                                if (municipalityContext
                                                    .isEmpty) {
                                                  Fluttertoast.showToast(
                                                    msg:
                                                        "Invalid municipality selection or missing municipality.",
                                                    toastLength:
                                                        Toast.LENGTH_SHORT,
                                                    gravity:
                                                        ToastGravity.CENTER,
                                                  );
                                                  return;
                                                }
                                                _reassignFault(
                                                    _allFaultResults[index]);
                                              },
                                              labelText: 'Reassign',
                                              fSize: 14,
                                              faIcon:
                                                  const FaIcon(Icons.update),
                                              fgColor: Theme.of(context)
                                                  .primaryColor,
                                              btSize: const Size(50, 38),
                                            ),
                                          ],
                                          BasicIconButtonGrey(
                                            onPress: () async {
                                              if (!isLocalUser &&
                                                  !isLocalMunicipality) {
                                                if (selectedMunicipality ==
                                                        null ||
                                                    selectedMunicipality ==
                                                        "Select Municipality") {
                                                  Fluttertoast.showToast(
                                                    msg:
                                                        "Please select a municipality first!",
                                                    toastLength:
                                                        Toast.LENGTH_SHORT,
                                                    gravity:
                                                        ToastGravity.CENTER,
                                                  );
                                                  return;
                                                }
                                              }

                                              String municipalityContext =
                                                  isLocalMunicipality ||
                                                          isLocalUser
                                                      ? municipalityId
                                                      : selectedMunicipality!;

                                              if (municipalityContext.isEmpty) {
                                                Fluttertoast.showToast(
                                                  msg:
                                                      "Invalid municipality selection or missing municipality.",
                                                  toastLength:
                                                      Toast.LENGTH_SHORT,
                                                  gravity: ToastGravity.CENTER,
                                                );
                                                return;
                                              }
                                              if (_allFaultResults[index] !=
                                                  null) {
                                                faultStage =
                                                    _allFaultResults[index]
                                                        ['faultStage'];
                                                _updateReport(
                                                    _allFaultResults[index]);
                                              } else {
                                                Fluttertoast.showToast(
                                                  msg:
                                                      'Error: No fault data available for update.',
                                                  gravity: ToastGravity.CENTER,
                                                );
                                              }
                                            },
                                            labelText: 'Update',
                                            fSize: 14,
                                            faIcon: const FaIcon(Icons.edit),
                                            fgColor: Colors.blue,
                                            btSize: const Size(50, 38),
                                          ),
                                          // if (adminAcc) ...[
                                          //   BasicIconButtonGrey(
                                          //     onPress: () {
                                          //       if (!isLocalUser &&
                                          //           !isLocalMunicipality) {
                                          //         if (selectedMunicipality ==
                                          //                 null ||
                                          //             selectedMunicipality ==
                                          //                 "Select Municipality") {
                                          //           Fluttertoast.showToast(
                                          //             msg:
                                          //                 "Please select a municipality first!",
                                          //             toastLength:
                                          //                 Toast.LENGTH_SHORT,
                                          //             gravity:
                                          //                 ToastGravity.CENTER,
                                          //           );
                                          //           return;
                                          //         }
                                          //       }
                                          //
                                          //       String municipalityContext =
                                          //           isLocalMunicipality ||
                                          //                   isLocalUser
                                          //               ? municipalityId
                                          //               : selectedMunicipality!;
                                          //
                                          //       if (municipalityContext.isEmpty) {
                                          //         Fluttertoast.showToast(
                                          //           msg:
                                          //               "Invalid municipality selection or missing municipality.",
                                          //           toastLength:
                                          //               Toast.LENGTH_SHORT,
                                          //           gravity: ToastGravity.CENTER,
                                          //         );
                                          //         return;
                                          //       }
                                          //       _reassignDept(
                                          //           _allFaultResults[index]);
                                          //     },
                                          //     labelText: 'Reallocate Department',
                                          //     fSize: 14,
                                          //     faIcon: const FaIcon(
                                          //         Icons.compare_arrows),
                                          //     fgColor: Colors.blue,
                                          //     btSize: const Size(50, 38),
                                          //   ),
                                          // ],
                                        ],
                                      ),
                                    ],
                                  ),
                                )
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
    return const Center(child: CircularProgressIndicator());
  }

  // Widget faultCard() {
  //   if (_allFaultResults.isNotEmpty) {
  //     return _isLoading
  //         ? const Center(
  //       child: CircularProgressIndicator(),
  //     )
  //         : ListView.builder(
  //       itemCount: _allFaultResults.length,
  //       itemBuilder: (context, index) {
  //         if (index >= _allFaultResults.length) {
  //           // Ensure index does not exceed the bounds
  //           return const SizedBox();
  //         }
  //
  //         var fault = _allFaultResults[index];
  //         String status =
  //         (fault['faultResolved'] == false) ? "Pending" : "Completed";
  //         bool showNotification = (fault['attendeeAllocated'] == '' ||
  //             fault['faultStage'] == 1 ||
  //             fault['faultResolved'] == false);
  //
  //         var faultAddress =
  //         (fault['address'] != null && fault['address'].isNotEmpty)
  //             ? fault['address']
  //             : 'No address provided';
  //         var faultType = (fault['faultType'] != null &&
  //             fault['faultType'].isNotEmpty)
  //             ? fault['faultType']
  //             : 'No fault type provided';
  //
  //         // Convert dateReported to a formatted string if it's a Timestamp
  //         var dateReported;
  //         if (fault['dateReported'] is Timestamp) {
  //           dateReported = DateFormat('yyyy-MM-dd – kk:mm').format(
  //             fault['dateReported'].toDate(),
  //           );
  //         } else {
  //           dateReported =
  //           fault['dateReported']; // If it's already a string
  //         }
  //
  //         // Clean the address to remove invalid characters
  //         String cleanedAddress =
  //         faultAddress.replaceAll(RegExp(r'[\/:*?"<>|]'), '');
  //
  //         // Render card only if the fault is related to the user's department
  //         if (myDepartment == fault['faultType']) {
  //           return Card(
  //             margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
  //             child: Padding(
  //               padding: const EdgeInsets.all(20.0),
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Center(
  //                     child: Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         Visibility(
  //                           visible: showNotification,
  //                           child: const Row(
  //                             mainAxisAlignment: MainAxisAlignment.end,
  //                             children: [
  //                               Icon(
  //                                 Icons.notification_important,
  //                                 color: Colors.red,
  //                               ),
  //                               SizedBox(width: 5),
  //                               Text(
  //                                 'Attention needed!',
  //                                 style: TextStyle(
  //                                     fontSize: 14,
  //                                     color: Colors.red,
  //                                     fontWeight: FontWeight.bold),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                         const Text(
  //                           'Fault Information',
  //                           style: TextStyle(
  //                               fontSize: 16,
  //                               fontWeight: FontWeight.w700),
  //                         ),
  //                         Visibility(
  //                           visible: visNotification,
  //                           child: const Icon(
  //                             Icons.notification_important,
  //                             color: Colors.red,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   const SizedBox(height: 10),
  //                   Text(
  //                     'Reference Number: ${_allFaultResults[index]['ref']}',
  //                     style: const TextStyle(
  //                         fontSize: 16, fontWeight: FontWeight.w400),
  //                   ),
  //                   const SizedBox(height: 5),
  //                   if (_allFaultResults[index]['accountNumber'] !=
  //                       "") ...[
  //                     Text(
  //                       'Reporter Account Number: ${_allFaultResults[index]['accountNumber']}',
  //                       style: const TextStyle(
  //                           fontSize: 16, fontWeight: FontWeight.w400),
  //                     ),
  //                     const SizedBox(height: 5),
  //                   ],
  //
  //                   // Fault Address
  //                   Text(
  //                     'Street Address of Fault: ${faultAddress}',
  //                     style: const TextStyle(
  //                         fontSize: 16, fontWeight: FontWeight.w400),
  //                   ),
  //                   const SizedBox(height: 5),
  //
  //                   // Fault Type
  //                   Text(
  //                     'Fault Type: ${faultType}',
  //                     style: const TextStyle(
  //                         fontSize: 16, fontWeight: FontWeight.w400),
  //                   ),
  //                   const SizedBox(height: 5),
  //                   Text(
  //                     'Date of Fault Report: ${_allFaultResults[index]['dateReported']}',
  //                     style: const TextStyle(
  //                         fontSize: 16, fontWeight: FontWeight.w400),
  //                   ),
  //                   const SizedBox(height: 5),
  //
  //                   // Fault Description
  //                   Column(
  //                     children: [
  //                       if (fault['faultDescription'] != "") ...[
  //                         Text(
  //                           'Fault Description: ${fault['faultDescription']}',
  //                           style: const TextStyle(
  //                               fontSize: 16,
  //                               fontWeight: FontWeight.w400),
  //                         ),
  //                         const SizedBox(height: 5),
  //                       ]
  //                     ],
  //                   ),
  //
  //                   // Manager Allocated
  //                   Column(
  //                     children: [
  //                       if (fault['managerAllocated'] != "") ...[
  //                         Text(
  //                           'Manager Allocated: ${fault['managerAllocated']}',
  //                           style: const TextStyle(
  //                               fontSize: 16,
  //                               fontWeight: FontWeight.w400),
  //                         ),
  //                         const SizedBox(height: 5),
  //                       ]
  //                     ],
  //                   ),
  //
  //                   // Attendee Allocated
  //                   Column(
  //                     children: [
  //                       if (fault['attendeeAllocated'] != "") ...[
  //                         Text(
  //                           'Attendee Allocated: ${fault['attendeeAllocated']}',
  //                           style: const TextStyle(
  //                               fontSize: 16,
  //                               fontWeight: FontWeight.w400),
  //                         ),
  //                         const SizedBox(height: 5),
  //                       ]
  //                     ],
  //                   ),
  //
  //                   // Manager and Attendee Comments
  //                   Column(
  //                     children: [
  //                       if (fault['managerCom1'] != "") ...[
  //                         Text(
  //                           'Manager Comment: ${fault['managerCom1']}',
  //                           style: const TextStyle(
  //                               fontSize: 16,
  //                               fontWeight: FontWeight.w400),
  //                         ),
  //                         const SizedBox(height: 5),
  //                       ]
  //                     ],
  //                   ),
  //                   Column(
  //                     children: [
  //                       if (fault['attendeeCom1'] != "") ...[
  //                         Text(
  //                           'Attendee Comment: ${fault['attendeeCom1']}',
  //                           style: const TextStyle(
  //                               fontSize: 16,
  //                               fontWeight: FontWeight.w400),
  //                         ),
  //                         const SizedBox(height: 5),
  //                       ]
  //                     ],
  //                   ),
  //
  //                   // Follow-up Comments (if any)
  //                   Column(
  //                     children: [
  //                       if (fault['managerCom2'] != "") ...[
  //                         Text(
  //                           'Manager Follow-up Comment: ${fault['managerCom2']}',
  //                           style: const TextStyle(
  //                               fontSize: 16,
  //                               fontWeight: FontWeight.w400),
  //                         ),
  //                         const SizedBox(height: 5),
  //                       ]
  //                     ],
  //                   ),
  //                   Column(
  //                     children: [
  //                       if (fault['attendeeCom2'] != "") ...[
  //                         Text(
  //                           'Attendee Follow-up Comment: ${fault['attendeeCom2']}',
  //                           style: const TextStyle(
  //                               fontSize: 16,
  //                               fontWeight: FontWeight.w400),
  //                         ),
  //                         const SizedBox(height: 5),
  //                       ]
  //                     ],
  //                   ),
  //
  //                   // Final Comments (if any)
  //                   Column(
  //                     children: [
  //                       if (fault['managerCom3'] != "") ...[
  //                         Text(
  //                           'Manager Final Comment: ${fault['managerCom3']}',
  //                           style: const TextStyle(
  //                               fontSize: 16,
  //                               fontWeight: FontWeight.w400),
  //                         ),
  //                         const SizedBox(height: 5),
  //                       ]
  //                     ],
  //                   ),
  //                   Column(
  //                     children: [
  //                       if (fault['attendeeCom3'] != "") ...[
  //                         Text(
  //                           'Attendee Final Comment: ${fault['attendeeCom3']}',
  //                           style: const TextStyle(
  //                               fontSize: 16,
  //                               fontWeight: FontWeight.w400),
  //                         ),
  //                         const SizedBox(height: 5),
  //                       ]
  //                     ],
  //                   ),
  //                   Column(
  //                     children: [
  //                       if (fault['managerReturnCom'] != "") ...[
  //                         Text(
  //                           'Reason for return: ${fault['managerReturnCom']}',
  //                           style: const TextStyle(
  //                               fontSize: 16,
  //                               fontWeight: FontWeight.w400),
  //                         ),
  //                         const SizedBox(height: 5),
  //                       ]
  //                     ],
  //                   ),
  //                   Column(
  //                     children: [
  //                       if (fault['adminComment'] != null &&
  //                           fault['adminComment'].isNotEmpty) ...[
  //                         Text(
  //                           'Admin Comment: ${fault['adminComment']}',
  //                           style: const TextStyle(
  //                               fontSize: 16,
  //                               fontWeight: FontWeight.w400),
  //                         ),
  //                         const SizedBox(height: 5),
  //                       ]
  //                     ],
  //                   ),
  //
  //                   // Resolve State
  //                   Text(
  //                     'Resolve State: $status',
  //                     style: const TextStyle(
  //                         fontSize: 16, fontWeight: FontWeight.w400),
  //                   ),
  //                   const SizedBox(height: 5),
  //
  //                   // Fault Stage Color based on stage
  //                   Text(
  //                     'Fault Stage: ${fault['faultStage'].toString()}',
  //                     style: TextStyle(
  //                         fontSize: 16,
  //                         fontWeight: FontWeight.w500,
  //                         color: getFaultStageColor(fault['faultStage'])),
  //                   ),
  //                   const SizedBox(height: 5),
  //
  //                   // Buttons for viewing image, location, and calling user
  //                   Center(
  //                     child: Column(
  //                       mainAxisAlignment: MainAxisAlignment.center,
  //                       crossAxisAlignment: CrossAxisAlignment.center,
  //                       children: [
  //                         Row(
  //                           mainAxisAlignment: MainAxisAlignment.center,
  //                           crossAxisAlignment: CrossAxisAlignment.center,
  //                           children: [
  //                             BasicIconButtonGrey(
  //                               onPress: () async {
  //                                 String dateReported =
  //                                 fault['dateReported'];
  //
  //                                 Navigator.push(
  //                                   context,
  //                                   MaterialPageRoute(
  //                                     builder: (context) =>
  //                                         ImageZoomFaultPage(
  //                                             imageName: cleanedAddress,
  //                                             dateReported: dateReported),
  //                                   ),
  //                                 );
  //                               },
  //                               labelText: 'View Fault Image',
  //                               fSize: 14,
  //                               faIcon: const FaIcon(Icons.zoom_in),
  //                               fgColor: Colors.grey,
  //                               btSize: const Size(100, 38),
  //                             ),
  //                             BasicIconButtonGrey(
  //                               onPress: () async {
  //                                 accountNumberRep =
  //                                 _allFaultResults[index]
  //                                 ['accountNumber'];
  //                                 locationGivenRep =
  //                                 _allFaultResults[index]['address'];
  //
  //                                 Navigator.push(
  //                                     context,
  //                                     MaterialPageRoute(
  //                                         builder: (context) =>
  //                                             MapScreenProp(
  //                                               propAddress:
  //                                               locationGivenRep,
  //                                               propAccNumber:
  //                                               accountNumberRep,
  //                                             )));
  //                               },
  //                               labelText: 'Location',
  //                               fSize: 14,
  //                               faIcon: const FaIcon(Icons.map),
  //                               fgColor: Colors.green,
  //                               btSize: const Size(50, 38),
  //                             ),
  //                             BasicIconButtonGrey(
  //                               onPress: () async {
  //                                 showDialog(
  //                                   barrierDismissible: false,
  //                                   context: context,
  //                                   builder: (context) {
  //                                     return AlertDialog(
  //                                       shape:
  //                                       const RoundedRectangleBorder(
  //                                           borderRadius:
  //                                           BorderRadius.all(
  //                                               Radius.circular(
  //                                                   16))),
  //                                       title:
  //                                       const Text("Call Reporter!"),
  //                                       content: const Text(
  //                                           "Would you like to call the individual who logged the fault?"),
  //                                       actions: [
  //                                         IconButton(
  //                                           onPressed: () {
  //                                             Navigator.of(context).pop();
  //                                           },
  //                                           icon: const Icon(
  //                                             Icons.cancel,
  //                                             color: Colors.red,
  //                                           ),
  //                                         ),
  //                                         IconButton(
  //                                           onPressed: () {
  //                                             reporterCellGiven =
  //                                             _allFaultResults[index]
  //                                             ['reporterContact'];
  //                                             final Uri tel = Uri.parse(
  //                                                 'tel:${reporterCellGiven
  //                                                     .toString()}');
  //                                             launchUrl(tel);
  //                                             Navigator.of(context).pop();
  //                                           },
  //                                           icon: const Icon(
  //                                             Icons.done,
  //                                             color: Colors.green,
  //                                           ),
  //                                         ),
  //                                       ],
  //                                     );
  //                                   },
  //                                 );
  //                               },
  //                               labelText: 'Call User',
  //                               fSize: 14,
  //                               faIcon: const FaIcon(Icons.call),
  //                               fgColor: Colors.orange,
  //                               btSize: const Size(50, 38),
  //                             ),
  //                           ],
  //                         ),
  //                         Row(
  //                           mainAxisAlignment: MainAxisAlignment.center,
  //                           crossAxisAlignment: CrossAxisAlignment.center,
  //                           children: [
  //                             if (adminAcc) ...[
  //                               BasicIconButtonGrey(
  //                                 onPress: () async {
  //                                   _reassignFault(
  //                                       _allFaultResults[index]);
  //                                 },
  //                                 labelText: 'Reassign',
  //                                 fSize: 14,
  //                                 faIcon: const FaIcon(Icons.update),
  //                                 fgColor: Theme
  //                                     .of(context)
  //                                     .primaryColor,
  //                                 btSize: const Size(50, 38),
  //                               ),
  //                             ],
  //                             BasicIconButtonGrey(
  //                               onPress: () async {
  //                                 if (_allFaultResults[index] != null) {
  //                                   faultStage = _allFaultResults[index]
  //                                   ['faultStage'];
  //                                   _updateReport(_allFaultResults[
  //                                   index]); // Ensure documentSnapshot is not null here
  //                                 } else {
  //                                   Fluttertoast.showToast(
  //                                       msg:
  //                                       'Error: No fault data available for update.',
  //                                       gravity: ToastGravity.CENTER);
  //                                 }
  //                               },
  //                               labelText: 'Update',
  //                               fSize: 14,
  //                               faIcon: const FaIcon(Icons.edit),
  //                               fgColor: Colors.blue,
  //                               btSize: const Size(50, 38),
  //                             ),
  //                             if (adminAcc) ...[
  //                               Center(
  //                                 child: BasicIconButtonGrey(
  //                                   onPress: () {
  //                                     _reassignDept(
  //                                         _allFaultResults[index]);
  //                                   },
  //                                   labelText: 'Reallocate Department',
  //                                   fSize: 14,
  //                                   faIcon: const FaIcon(
  //                                       Icons.compare_arrows),
  //                                   fgColor: Colors.blue,
  //                                   btSize: const Size(50, 38),
  //                                 ),
  //                               ),
  //                             ],
  //                           ],
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           );
  //         } else {
  //           return const SizedBox();
  //         }
  //       },
  //     );
  //   }
  //   return const Center(
  //     child: CircularProgressIndicator(),
  //   );
  // }

  Widget unassignedFaultCard() {
    // Ensure faults are properly extracted before filtering
    List unassignedResults = _unassignedFaultResults;

    // If no faults found, show message
    if (unassignedResults.isEmpty) {
      return const Center(
        child: Text(
          "No unassigned faults found.",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        noFaultFocusNode.requestFocus();
      },
      child: KeyboardListener(
        focusNode: noFaultFocusNode,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            final double pageScrollAmount =
                _unassignedFaultsScrollController.position.viewportDimension;

            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _unassignedFaultsScrollController.animateTo(
                _unassignedFaultsScrollController.offset + 50,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeIn,
              );
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _unassignedFaultsScrollController.animateTo(
                _unassignedFaultsScrollController.offset - 50,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeIn,
              );
            } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
              _unassignedFaultsScrollController.animateTo(
                _unassignedFaultsScrollController.offset + pageScrollAmount,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeIn,
              );
            } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
              _unassignedFaultsScrollController.animateTo(
                _unassignedFaultsScrollController.offset - pageScrollAmount,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeIn,
              );
            }
          }
        },
        child: Scrollbar(
          controller: _unassignedFaultsScrollController,
          thickness: 12,
          radius: const Radius.circular(8),
          thumbVisibility: true,
          trackVisibility: true,
          interactive: true,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _unassignedFaultsScrollController,
                  shrinkWrap: true,
                  itemCount: unassignedResults.length,
                  itemBuilder: (context, index) {
                    // if (index >= unassignedResults.length) {
                    //   return const SizedBox();
                    // }

                    // Extract fault data correctly
                    var faultData =
                        unassignedResults[index].data() as Map<String, dynamic>;

                    String status = (faultData['faultResolved'] == false)
                        ? "Pending"
                        : "Completed";
                    bool showNotification =
                        (faultData['attendeeAllocated'] == '' ||
                            faultData['faultStage'] == 1 ||
                            faultData['faultResolved'] == false);

                    var faultAddress = (faultData['address'] != null &&
                            faultData['address'].isNotEmpty)
                        ? faultData['address']
                        : 'No address provided';
                    var faultType = (faultData['faultType'] != null &&
                            faultData['faultType'].isNotEmpty)
                        ? faultData['faultType']
                        : 'No fault type provided';

                    var dateReported;
                    if (faultData['dateReported'] is Timestamp) {
                      dateReported = DateFormat('yyyy-MM-dd – kk:mm').format(
                        faultData['dateReported'].toDate(),
                      );
                    } else {
                      dateReported = faultData['dateReported'];
                    }

                    String cleanedAddress =
                        faultAddress.replaceAll(RegExp(r'[\/:*?"<>|]'), '');

                    return Card(
                      margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Visibility(
                                    visible: showNotification,
                                    child: const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.notification_important,
                                            color: Colors.red),
                                        SizedBox(width: 5),
                                        Text(
                                          'Attention needed!',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Expanded(
                                    child: Center(
                                      child: Text(
                                        'Fault Information',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  Visibility(
                                    visible: visNotification,
                                    child: const Icon(
                                      Icons.notification_important,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Reference Number: ${faultData['ref']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5),
                            if (faultData['accountNumber'] != "") ...[
                              Text(
                                'Reporter Account Number: ${faultData['accountNumber']}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(height: 5),
                            ],
                            Text(
                              'Street Address of Fault: $faultAddress',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Fault Type: $faultType',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Date of Fault Report: $dateReported',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5),
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

  Future<void> _updateReport([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      // Print and verify the values of districtId, municipalityId, and documentSnapshot.id
      print("districtId: $districtId");
      print("municipalityId: $municipalityId");
      print("documentSnapshot.id: ${documentSnapshot.id}");

      // Ensure districtId and municipalityId are non-empty for non-local municipality cases
      String municipalityContext = isLocalMunicipality || isLocalUser
          ? municipalityId
          : selectedMunicipality!;

      if (municipalityContext.isEmpty) {
        print("Error: municipalityContext is empty.");
        return;
      }

      DocumentReference faultDocRef;

      // Construct path based on municipality type
      if (isLocalMunicipality) {
        faultDocRef = FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(municipalityContext)
            .collection('faultReporting')
            .doc(documentSnapshot.id);
      } else {
        faultDocRef = FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipalityContext)
            .collection('faultReporting')
            .doc(documentSnapshot.id);
      }

      print('Updating document path: ${faultDocRef.path}');

      print('Updating document path: ${faultDocRef.path}');
      // Initialize dropdown values and fields
      String dropdownValue = 'Water and Sanitation';
      dropdownValue = documentSnapshot['faultType'];
      String? dropdownValue3 = _employeesUserNames.isNotEmpty &&
              _employeesUserNames.contains(_employeesUserNames.first)
          ? _employeesUserNames.first
          : null;

      print('Updating fault with ID: ${documentSnapshot.id}');

      // Set the visibility of stages based on the current fault stage
      int stageNum = documentSnapshot['faultStage'];
      visStage1 = stageNum == 1;
      visStage2 = stageNum == 2;
      visStage3 = stageNum == 3;
      visStage4 = stageNum == 4;
      visStage5 = stageNum == 5;

      print('Fault Stage: $stageNum');

      // Populate fields with current fault data
      _accountNumberController.text = documentSnapshot['accountNumber'];
      _addressController.text = documentSnapshot['address'];
      _descriptionController.text = documentSnapshot['faultDescription'];
      _commentController.text = '';
      _depAllocationController.text = documentSnapshot['depAllocated'];
      _faultResolvedController = documentSnapshot['faultResolved'];

      // Display the update dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Update Fault',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Display admin comment if available
                        if (documentSnapshot['adminComment'] != null &&
                            documentSnapshot['adminComment'].isNotEmpty) ...[
                          Text(
                            'Admin Comment: ${documentSnapshot['adminComment']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Approve and Complete button for admin in Stage 4
                        if (faultStage == 4 && adminAcc)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.orange,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 15),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () async {
                                  await _returnFaultToAdmin(documentSnapshot);
                                },
                                child: const Text('Admin Options'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 15),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        // Manager updating in Stage 3
                        if (faultStage == 3 && managerAcc) ...[
                          TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              labelText:
                                  'Add Comment before Moving to Stage 4...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () async {
                              if (_commentController.text.isNotEmpty) {
                                final currentUser = FirebaseAuth.instance.currentUser;
                                String currentEmail = currentUser?.email ?? '';

                                final docSnapshot = await faultDocRef.get();
                                final currentData = docSnapshot.data() as Map<String, dynamic>;

                                await faultDocRef.update({
                                  "managerCom2": _commentController.text,
                                  "faultResolved": false,
                                  "managerEmail": currentEmail,
                                  "adminEmail": currentData["adminEmail"] ?? "",
                                  "employeeEmail": currentData["employeeEmail"] ?? "",
                                  "faultStage": 4,
                                });

                                _commentController.clear();
                                dropdownValue = 'Select Department...';
                                dropdownValue3 = 'Assign User...';
                                _faultResolvedController = false;
                                visStage1 = visStage2 =
                                    visStage3 = visStage4 = visStage5 = false;

                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              } else {
                                _showToast(
                                    'Please provide a comment before updating the fault.');
                              }
                            },
                            child: const Text('Update'),
                          ),
                        ],

                        // Employee updating in Stage 2
                        if (faultStage == 2 && employeeAcc) ...[
                          TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              labelText:
                                  'Add Comment to Confirm Fault Assignment...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () async {
                              if (_commentController.text.isNotEmpty) {
                                final currentUser = FirebaseAuth.instance.currentUser;
                                String currentEmail = currentUser?.email ?? '';

// Fetch current document data to preserve admin/manager email
                                final docSnapshot = await faultDocRef.get();
                                final currentData = docSnapshot.data() as Map<String, dynamic>;

                                await faultDocRef.update({
                                  "attendeeCom1": _commentController.text,
                                  "employeeEmail": currentEmail,
                                  "managerEmail": currentData["managerEmail"] ?? "",
                                  "adminEmail": currentData["adminEmail"] ?? "",
                                  "faultStage": 3,
                                });
                                _commentController.clear();
                                dropdownValue = 'Select Department...';
                                dropdownValue3 = 'Assign User...';
                                _faultResolvedController = false;
                                visStage1 = visStage2 =
                                    visStage3 = visStage4 = visStage5 = false;

                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              } else {
                                _showToast(
                                    'Please provide a comment before confirming assignment.');
                              }
                            },
                            child: const Text('Confirm Assignment'),
                          ),
                        ],

                        // Admin assigning department in Stage 1
                        if (faultStage == 1 && adminAcc) ...[
                          DropdownButtonFormField<String>(
                            value: dropdownValue,
                            decoration: InputDecoration(
                              labelText: 'Water and Sanitation',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            items: <String>[
                              //  'Select Department...',
                              'Water & Sanitation',
                              // 'Roadworks',
                              // 'Waste Management'
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if(mounted) {
                                setState(() {
                                  dropdownValue = newValue!;
                                  getUserDepartmentDetails();
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: dropdownValue3,
                            decoration: InputDecoration(
                              labelText: 'Assign User',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            items: _employeesUserNames
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if(mounted) {
                                setState(() {
                                  dropdownValue3 = newValue!;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              labelText: 'Comment...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 15),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () async {
                                    if (_commentController.text.isNotEmpty &&
                                        dropdownValue3 != null &&
                                        dropdownValue3 != 'Assign User...' &&
                                        dropdownValue == 'Water & Sanitation') {
                                      try {
                                        await faultDocRef.update({
                                          "depAllocated": dropdownValue,
                                          "attendeeAllocated": dropdownValue3,
                                          "adminComment":
                                              _commentController.text,
                                          "faultStage": 2,
                                        });
                                        print(
                                            "Update successful: Fault stage updated to 2.");

                                        // ✅ Step 2: Get current admin email
                                        final currentUser = FirebaseAuth.instance.currentUser;
                                        final currentAdminEmail = currentUser?.email ?? "";

                                        // ✅ Step 3: Lookup assigned employee's email
                                        String? assignedEmployeeEmail;
                                        try {
                                          final employeeSnapshot = await FirebaseFirestore.instance
                                              .collection(isLocalMunicipality
                                              ? 'localMunicipalities/$municipalityContext/users'
                                              : 'districts/$districtId/municipalities/$municipalityContext/users')
                                              .where('userName', isEqualTo: dropdownValue3)
                                              .limit(1)
                                              .get();

                                          if (employeeSnapshot.docs.isNotEmpty) {
                                            assignedEmployeeEmail = employeeSnapshot.docs.first['email'];
                                          }
                                        } catch (e) {
                                          print("Error fetching employee email: $e");
                                        }

                                        // ✅ Step 4: Update fault document with emails
                                        await faultDocRef.update({
                                          "adminEmail": currentAdminEmail,
                                          if (assignedEmployeeEmail != null)
                                            "employeeEmail": assignedEmployeeEmail,
                                        });

                                      } catch (e) {
                                        print("Update failed: $e");
                                      }

                                      _commentController.clear();
                                      dropdownValue = 'Water & Sanitation';
                                      dropdownValue3 = null;
                                      _faultResolvedController = false;
                                      visStage1 = visStage2 = visStage3 =
                                          visStage4 = visStage5 = false;

                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    } else {
                                      _showToast(
                                          'Please allocate the fault and provide a comment.');
                                    }
                                  },
                                  child: const Text('Assign'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 15),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Cancel'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }

  // Utility function to show toast
  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      gravity: ToastGravity.CENTER,
    );
  }

  Future<void> _reassignFault([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot == null) return;
    String municipalityContext = isLocalMunicipality || isLocalUser
        ? municipalityId
        : selectedMunicipality!;

    if (municipalityContext.isEmpty) {
      print("Error: municipalityContext is empty.");
      return;
    }
    // Create the DocumentReference based on municipality type
    DocumentReference faultDocRef;
    if (isLocalMunicipality) {
      faultDocRef = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityContext)
          .collection('faultReporting')
          .doc(documentSnapshot.id);
    } else {
      faultDocRef = FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityContext)
          .collection('faultReporting')
          .doc(documentSnapshot.id);
    }

    print('Reassigning fault with ID: ${documentSnapshot.id}');
    print('Fault document path: ${faultDocRef.path}');

    // Initialize dropdowns and text field for reallocation
    String dropdownValue = 'Water and Sanitation';
    dropdownValue = documentSnapshot['faultType'];
    String? dropdownValue3 = _employeesUserNames.isNotEmpty &&
            _employeesUserNames.contains(_employeesUserNames.first)
        ? _employeesUserNames.first
        : null;
    _commentController.clear();

    //This checks the current state of the fault stage 5 is resolve stage
    int stageNum = documentSnapshot['faultStage'];
    if (stageNum == 1) {
      visStage1 = true;
      visStage2 = false;
      visStage3 = false;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 2) {
      visStage1 = false;
      visStage2 = true;
      visStage3 = false;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 3) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = true;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 4) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = false;
      visStage4 = true;
      visStage5 = false;
    } else if (stageNum == 5) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = false;
      visStage4 = false;
      visStage5 = true;
    }

    // Creating an alert dialog instead of a bottom sheet
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              // Customizing the background color
              backgroundColor: Colors.grey[50],

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),

              title: const Text(
                'Reassign Fault',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Customize title font color
                ),
              ),

              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.6, // Set the width
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customize visibility and text
                      Visibility(
                        visible: adminAcc,
                        child: const Text(
                          'Reassign To',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black, // Customize font color
                          ),
                        ),
                      ),

                      // Custom dropdown
                      Visibility(
                        visible: adminAcc,
                        child: DropdownButtonFormField<String>(
                          dropdownColor: Colors.grey[50],
                          // Customize dropdown background color
                          value: dropdownValue3,
                          items: _employeesUserNames
                              .toSet()
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors
                                      .black, // Customize dropdown text color
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if(mounted) {
                              setState(() {
                                dropdownValue3 = newValue!;
                              });
                            }
                          },
                        ),
                      ),

                      // Custom TextField for reason input
                      Visibility(
                        visible: adminAcc,
                        child: TextField(
                          style: const TextStyle(color: Colors.black),
                          // Customize input text color
                          keyboardType: TextInputType.text,
                          controller: _commentController,
                          decoration: const InputDecoration(
                            labelText: 'Reason for reallocation...',
                            labelStyle: TextStyle(
                              color: Colors.black, // Customize label text color
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                // Custom button styles
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      // Customize text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text('Reassign'),
                    onPressed: () async {
                      final String userComment = _commentController.text;
                      final String? attendeeAllocated = dropdownValue3;

                      if (attendeeAllocated == null ||
                          attendeeAllocated == 'Assign User...') {
                        Fluttertoast.showToast(
                          msg:
                              'Please allocate the fault to a new fault attendee!',
                          gravity: ToastGravity.CENTER,
                        );
                        return;
                      }

                      if (userComment.isEmpty) {
                        Fluttertoast.showToast(
                          msg:
                              'Please provide reasoning for your reallocation!',
                          gravity: ToastGravity.CENTER,
                        );
                        return;
                      }

                      try {
                        await faultDocRef.update({
                          "reallocationComment": userComment,
                          "attendeeAllocated": attendeeAllocated,
                          "faultResolved": false,
                          "faultStage": 2,
                        });
                        print(
                            "Reassignment successful: Fault updated to stage 2.");
                        Fluttertoast.showToast(
                          msg: 'Fault reassigned successfully!',
                          gravity: ToastGravity.CENTER,
                        );
                        await fetchFaultsForAllMunicipalities();
                        if (mounted) {
                          // Or the specific function you use
                          setState(() {});
                        }
                      } catch (e) {
                        print("Error during reassignment: $e");
                        Fluttertoast.showToast(
                          msg: 'Failed to reassign the fault.',
                          gravity: ToastGravity.CENTER,
                        );
                      }

                      // Clear fields after update
                      _commentController.clear();
                      _depAllocationController.text = '';
                      dropdownValue = 'Select Department...';
                      dropdownValue3 = 'Assign User...';
                      _faultResolvedController = false;

                      visStage1 =
                          visStage2 = visStage3 = visStage4 = visStage5 = false;

                      Navigator.of(context).pop(); // Close the dialog
                    }),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                    // Customize text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _managersReassignWorker(
      [DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot == null) return;
    String municipalityContext = isLocalMunicipality || isLocalUser
        ? municipalityId
        : selectedMunicipality!;

    if (municipalityContext.isEmpty) {
      print("Error: municipalityContext is empty.");
      return;
    }
    // Create the DocumentReference based on municipality type
    DocumentReference faultDocRef;
    if (isLocalMunicipality) {
      faultDocRef = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityContext)
          .collection('faultReporting')
          .doc(documentSnapshot.id);
    } else {
      faultDocRef = FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityContext)
          .collection('faultReporting')
          .doc(documentSnapshot.id);
    }

    print('Reassigning fault with ID: ${documentSnapshot.id}');
    print('Fault document path: ${faultDocRef.path}');

    // Initialize dropdowns and text field for reallocation
    String dropdownValue = 'Water and Sanitation';
    dropdownValue = documentSnapshot['faultType'];
    String? dropdownValue2 = _employeesUserNames.isNotEmpty &&
            _employeesUserNames.contains(_employeesUserNames.first)
        ? _employeesUserNames.first
        : null;

    // Check the current state of the fault stage 5 is resolve stage
    int stageNum = documentSnapshot['faultStage'];
    if (stageNum == 1) {
      visStage1 = true;
      visStage2 = false;
      visStage3 = false;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 2) {
      visStage1 = false;
      visStage2 = true;
      visStage3 = false;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 3) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = true;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 4) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = false;
      visStage4 = true;
      visStage5 = false;
    } else if (stageNum == 5) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = false;
      visStage4 = false;
      visStage5 = true;
    }

    // Populate initial values
    _accountNumberController.text = documentSnapshot['accountNumber'];
    _addressController.text = documentSnapshot['address'];
    _descriptionController.text = documentSnapshot['faultDescription'];
    _deptManagerController.text = documentSnapshot['managerAllocated'];
    _commentController.text = '';
    _depAllocationController.text = documentSnapshot['depAllocated'];
    _faultResolvedController = documentSnapshot['faultResolved'];
    _dateReportedController.text = documentSnapshot['dateReported'];

    // Show AlertDialog instead of a BottomSheet
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[50],
              // Match background color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0), // Rounded corners
              ),
              title: const Text(
                'Reassign Fault Worker',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Title font color
                ),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.6, // Set width
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Visibility(
                        visible: (visStage1) && employeeAcc,
                        child: const Text(
                          'Only Administrators may assign this fault.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black, // Text font color
                          ),
                        ),
                      ),
                      Visibility(
                        visible: managerAcc,
                        child: const Text(
                          'Return fault to administrator',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black, // Text font color
                          ),
                        ),
                      ),
                      Visibility(
                        visible: adminAcc && visStage1,
                        child: DropdownButtonFormField<String>(
                          dropdownColor: Colors.grey[50], // Dropdown background
                          value: dropdownValue2,
                          items: _employeesUserNames
                              .toSet()
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black, // Dropdown text color
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if(mounted) {
                              setState(() {
                                dropdownValue2 = newValue!;
                              });
                            }
                          },
                        ),
                      ),
                      Visibility(
                        visible: employeeAcc,
                        child: const Text(
                          'Return fault to manager',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black, // Text font color
                          ),
                        ),
                      ),
                      Visibility(
                        visible: (visStage2 || visStage3) &&
                            (managerAcc || employeeAcc),
                        child: TextField(
                          style: const TextStyle(color: Colors.black),
                          // Input text color
                          keyboardType: TextInputType.text,
                          controller: _commentController,
                          decoration: const InputDecoration(
                            labelText: 'Reason for return',
                            labelStyle: TextStyle(
                              color: Colors.black, // Label text color
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                // Custom button styles for manager's return fault button
                Visibility(
                  visible: (visStage2 || visStage3 || visStage4 || visStage5) &&
                      managerAcc,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      // Customize text and background color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text('Return Fault'),
                    onPressed: () async {
                      final String userComment = _commentController.text;

                      if (userComment.isNotEmpty) {
                        await faultDocRef.update({
                          "managerReturnCom": userComment,
                          "faultStage": 1,
                        });
                      } else {
                        Fluttertoast.showToast(
                          msg:
                              'Please explain why you want to return this fault to the admin.',
                          gravity: ToastGravity.CENTER,
                        );
                      }

                      _resetFormFields();
                      Navigator.of(context).pop(); // Close the dialog
                    },
                  ),
                ),
                // Custom button styles for employee's return fault button
                Visibility(
                  visible: (visStage3 || visStage4) && employeeAcc,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.orange,
                      // Customize text and background color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text('Return to manager'),
                    onPressed: () async {
                      final String userComment = _commentController.text;

                      if (userComment.isNotEmpty) {
                        await faultDocRef.update({
                          "attendeeReturnCom": userComment,
                          "faultStage": 2,
                        });
                      } else {
                        Fluttertoast.showToast(
                          msg:
                              'Please explain why you want to return this fault to your manager.',
                          gravity: ToastGravity.CENTER,
                        );
                      }

                      _resetFormFields();
                      Navigator.of(context).pop(); // Close the dialog
                    },
                  ),
                ),
                // Cancel button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                    // Customize text and background color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _resetFormFields() {
    _commentController.text = '';
    _depAllocationController.text = '';
    _dateReportedController.text = '';
    dropdownValue = 'Select Department...';
    _faultResolvedController = false;

    visStage1 = false;
    visStage2 = false;
    visStage3 = false;
    visStage4 = false;
    visStage5 = false;
  }

  Future<void> _returnFaultToAdmin([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot == null) return;
    String municipalityContext = isLocalMunicipality || isLocalUser
        ? municipalityId
        : selectedMunicipality!;

    if (municipalityContext.isEmpty) {
      print("Error: municipalityContext is empty.");
      return;
    }
    // Create the DocumentReference based on municipality type
    DocumentReference faultDocRef;
    if (isLocalMunicipality) {
      faultDocRef = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityContext)
          .collection('faultReporting')
          .doc(documentSnapshot.id);
    } else {
      faultDocRef = FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityContext)
          .collection('faultReporting')
          .doc(documentSnapshot.id);
    }

    print('Reassigning fault with ID: ${documentSnapshot.id}');
    print('Fault document path: ${faultDocRef.path}');

    // Initialize dropdowns and text field for reallocation
    String dropdownValue = 'Water and Sanitation';
    dropdownValue = documentSnapshot['faultType'];
    String? dropdownValue2 = _employeesUserNames.isNotEmpty &&
            _employeesUserNames.contains(_employeesUserNames.first)
        ? _employeesUserNames.first
        : null;

    // Check the current state of the fault stage 5 is resolve stage
    int stageNum = documentSnapshot['faultStage'];
    if (stageNum == 1) {
      visStage1 = true;
      visStage2 = false;
      visStage3 = false;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 2) {
      visStage1 = false;
      visStage2 = true;
      visStage3 = false;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 3) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = true;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 4) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = false;
      visStage4 = true;
      visStage5 = false;
    } else if (stageNum == 5) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = false;
      visStage4 = false;
      visStage5 = true;
    }

    // Populate initial values
    _accountNumberController.text = documentSnapshot['accountNumber'];
    _addressController.text = documentSnapshot['address'];
    _descriptionController.text = documentSnapshot['faultDescription'];
    _deptManagerController.text = documentSnapshot['managerAllocated'];
    _depAllocationController.text = documentSnapshot['depAllocated'];
    _faultResolvedController = documentSnapshot['faultResolved'];
    _dateReportedController.text = documentSnapshot['dateReported'];

    // Show AlertDialog instead of a BottomSheet
    final TextEditingController _commentController = TextEditingController();

    // Show AlertDialog for fault actions
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[50],
              // Custom background color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0), // Rounded corners
              ),
              title: const Text(
                'Fault Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Customize title font color
                ),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.6, // Set width
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reason for returning fault OR Approval comment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black, // Text font color
                        ),
                      ),
                      const SizedBox(height: 10),
                      // TextField for adding the reason to return the fault
                      TextField(
                        controller: _commentController,
                        style: const TextStyle(color: Colors.black),
                        // Input text color
                        decoration: const InputDecoration(
                          labelText: 'Provide a comment',
                          labelStyle: TextStyle(
                            color: Colors.black, // Label text color
                          ),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.black), // Focused border color
                          ),
                        ),
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                // Custom button styles for Return to Stage 3
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.orange,
                    // Customize text and background color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: () async {
                    final String userComment = _commentController.text;

                    if (userComment.isNotEmpty) {
                      // Update the fault stage to 3 and save the manager's comment
                      final docSnapshot = await faultDocRef.get();
                      final currentData = docSnapshot.data() as Map<String, dynamic>;

                      await faultDocRef.update({
                        "managerReturnCom": userComment,
                        "employeeEmail": currentData["employeeEmail"] ?? "",
                        "managerEmail": currentData["managerEmail"] ?? "",
                        "adminEmail": currentData["adminEmail"] ?? "",
                        "faultStage": 3,
                      });


                      // Close the dialog after successful update
                      Navigator.of(context).pop();
                    } else {
                      Fluttertoast.showToast(
                        msg:
                            'Please provide a comment before returning the fault to Stage 3.',
                        gravity: ToastGravity.CENTER,
                      );
                    }
                  },
                  child: const Text('Return to Stage 3'),
                ),

                // Custom button styles for Approve & Complete
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    // Customize text and background color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: () async {
                    final String adminComment = _commentController.text;

                    if (adminComment.isNotEmpty) {
                      // Update the fault to mark as completed and move to Stage 5
                      // Get current user email and write to fault doc as adminEmail
                      final currentUser = FirebaseAuth.instance.currentUser;
                      final currentEmail = currentUser?.email ?? "";

                      final docSnapshot = await faultDocRef.get();
                      final currentData = docSnapshot.data() as Map<String, dynamic>;

                      await faultDocRef.update({
                        "adminComment": adminComment,
                        "faultResolved": true,
                        "adminEmail": currentEmail,
                        "employeeEmail": currentData["employeeEmail"] ?? "",
                        "managerEmail": currentData["managerEmail"] ?? "",
                        "faultStage": 5,
                      });

                      // Close the dialog after successful update
                      Navigator.of(context).pop();
                    } else {
                      Fluttertoast.showToast(
                        msg:
                            'Please provide a comment before completing the fault.',
                        gravity: ToastGravity.CENTER,
                      );
                    }
                  },
                  child: const Text('Approve & Complete'),
                ),

                // Custom button styles for Cancel
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                    // Customize text and background color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context)
                        .pop(); // Close the dialog without any action
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _reassignDept([DocumentSnapshot? documentSnapshot]) async {
    // Ensure that documentSnapshot is not null
    if (documentSnapshot == null) {
      print("Error: DocumentSnapshot is null.");
      Fluttertoast.showToast(
        msg: "Error: Fault data is missing.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
      return;
    }

    // Check that the document ID is not empty
    if (documentSnapshot.id.isEmpty) {
      print("Error: Document ID is empty.");
      Fluttertoast.showToast(
        msg: "Error: Fault document has no valid ID.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
      return;
    }

    // Get the municipalityId from the dropdown if necessary
    String? selectedMunicipalityId = isLocalMunicipality || isLocalUser
        ? municipalityId
        : selectedMunicipality; // Fetch from dropdown if necessary

    if (selectedMunicipalityId == null || selectedMunicipalityId.isEmpty) {
      print("Error: Municipality ID is empty or null.");
      Fluttertoast.showToast(
        msg: "Please select a municipality first!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
      return;
    }

    String? dropdownValue; // Initialize dropdownValue as null
    _commentController.text = '';

    // Fetch the departments collection from the nested path
    CollectionReference deptRef;

    // Handle local vs district municipality
    if (isLocalMunicipality) {
      deptRef = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(selectedMunicipalityId)
          .collection('departments');
    } else {
      deptRef = FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(selectedMunicipalityId)
          .collection('departments');
    }

    List<String> deptList = [];
    try {
      // Fetch department list from Firestore
      QuerySnapshot querySnapshot = await deptRef.get();
      print(
          'Documents in departments collection: ${querySnapshot.docs.length}');

      for (var result in querySnapshot.docs) {
        print(
            'Department Name: ${result['deptName']}'); // Ensure 'deptName' field exists
        deptList.add(result['deptName']);
      }

      if (deptList.isEmpty) {
        print('No departments found.');
      } else {
        print('Department list length: ${deptList.length}');
      }
    } catch (e) {
      print('Error fetching departments: $e');
    }

    // Show AlertDialog for department reassignment
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              title: const Text(
                'Reassign to Department',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Visibility(
                        visible: adminAcc,
                        child: const Text(
                          'Department Allocation',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ),
                      Visibility(
                        visible: adminAcc,
                        child: DropdownButtonFormField<String>(
                          dropdownColor: Colors.grey[50],
                          hint: const Text(
                            'Select Department...',
                            style: TextStyle(color: Colors.black),
                          ),
                          value: dropdownValue,
                          items: deptList
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if(mounted) {
                              setState(() {
                                dropdownValue = newValue!;
                              });
                            }
                          },
                        ),
                      ),
                      Visibility(
                        visible: adminAcc,
                        child: TextField(
                          style: const TextStyle(color: Colors.black),
                          keyboardType: TextInputType.text,
                          controller: _commentController,
                          decoration: const InputDecoration(
                            labelText: 'Reason for changing department...',
                            labelStyle: TextStyle(color: Colors.black),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                          ),
                        ),
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
                  child: const Text('Send to Department'),
                  onPressed: () async {
                    final String userComment = _commentController.text;
                    final String? depSelected = dropdownValue;

                    // Initialize _faultData with correct path
                    CollectionReference _faultData = isLocalMunicipality
                        ? FirebaseFirestore.instance
                            .collection('localMunicipalities')
                            .doc(selectedMunicipalityId)
                            .collection('faultReporting')
                        : FirebaseFirestore.instance
                            .collection('districts')
                            .doc(districtId)
                            .collection('municipalities')
                            .doc(selectedMunicipalityId)
                            .collection('faultReporting');

                    if (depSelected != null && userComment.isNotEmpty) {
                      await _faultData.doc(documentSnapshot.id).update({
                        "departmentSwitchComment": userComment,
                        "faultType": depSelected,
                        "depAllocated": depSelected,
                        "faultResolved": false,
                        "faultStage": 1,
                      });
                    } else if (userComment.isEmpty) {
                      Fluttertoast.showToast(
                        msg:
                            'Please provide reasoning for switching department!',
                        gravity: ToastGravity.CENTER,
                      );
                    } else {
                      Fluttertoast.showToast(
                        msg:
                            'Please select the department you wish to transfer this fault to!',
                        gravity: ToastGravity.CENTER,
                      );
                    }

                    _resetFormFields();
                    Navigator.of(context).pop(); // Close the dialog
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
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
