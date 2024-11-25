import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:municipal_services/code/MapTools/map_screen_prop.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';

class FaultTaskScreenArchive extends StatefulWidget {
  const FaultTaskScreenArchive({super.key,});

  @override
  State<FaultTaskScreenArchive> createState() => _FaultTaskScreenArchiveState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

final User? user = auth.currentUser;
final uid = user?.uid;
final email = user?.email;
String userID = uid as String;
String userEmail = email as String;

final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;

class FireStorageService extends ChangeNotifier{
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async{
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

class _FaultTaskScreenArchiveState extends State<FaultTaskScreenArchive> {
  String districtId='';
  String municipalityId='';
  bool isLocalMunicipality=false;
  String selectedMunicipality = 'All Municipalities';
  List<String> municipalityOptions = [];
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

    if(_searchController.text == ""){

    }
    _searchController.addListener(_onSearchChanged);
    checkRole();
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    searchText;
    searchResultsList();
    super.dispose();
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

  final _accountNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _commentController = TextEditingController();
  final _deptHandlerController = TextEditingController();
  final _depAllocationController = TextEditingController();
  late bool _faultResolvedController;
  final _dateReportedController = TextEditingController();
  late final CollectionReference _faultData;
  // final CollectionReference _faultData =
  // FirebaseFirestore.instance.collection('faultReporting');

  String accountNumberRep = '';
  String locationGivenRep = '';
  int faultStage = 0;
  String reporterCellGiven = '';
  String searchText = '';

  String userRole = '';
  List _allUserRolesResults = [];
  bool visShow = true;
  bool visHide = false;
  bool cardShow1 = true;

  bool adminAcc = false;
  bool managerAcc = false;
  bool employeeAcc = false;
  bool visStage1 = false;
  bool visStage2 = false;
  bool visStage3 = false;
  bool visStage4 = false;
  bool visStage5 = false;

  // final CollectionReference _listUser =
  // FirebaseFirestore.instance.collection('users');

  User? user = FirebaseAuth.instance.currentUser;

  TextEditingController _searchController = TextEditingController();
  List _resultsList =[];
  List _allFaultResults = [];

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

  // getFaultStream() async {
  //   try {
  //     var data;
  //     if (isLocalMunicipality) {
  //       data = await FirebaseFirestore.instance
  //           .collection('localMunicipalities')
  //           .doc(municipalityId)
  //           .collection('faultReporting')
  //           .orderBy('dateReported', descending: true)
  //           .get();
  //     } else {
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
  //     _allFaultResults = data.docs;
  //     searchResultsList();
  //   } catch (e) {
  //     print('Error fetching fault stream: $e');
  //   }
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


  void checkRole() {
    getUsersStream();
    if(userRole == 'Admin'|| userRole == 'Administrator'){
      adminAcc = true;
      managerAcc = false;
      employeeAcc = false;
    } else if(userRole == 'Manager'){
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Fault Reports Archive',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        // actions: <Widget>[
        //   Visibility(
        //       visible: adminAcc,
        //       child:
        //       IconButton(
        //           onPressed: (){
        //
        //           },
        //           icon: const Icon(Icons.hourglass_bottom, color: Colors.white,)),),
        // ],
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
                  print('this is the input text ::: $searchText');
                });
              },
            ),
          ),
          /// Search bar end

          ///made the listview card a reusable widget
          // firebaseFaultCard(_faultData),

          Expanded(child: faultCard(),),

          const SizedBox(height: 5,),
        ],
      ),
    );
  }

  //this widget is for displaying the fault report list all together
  Widget faultCard(){
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

              if (_allFaultResults[index]['faultResolved'] == true) {
                return Card(margin: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Fault Information',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 10,),
                        Text(
                          'Reference Number: ${_allFaultResults[index]['ref']}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5,),
                        Column(
                          children: [
                            if(_allFaultResults[index]['accountNumber'] != "")...[
                              Text(
                                'Reporter Account Number: ${_allFaultResults[index]['accountNumber']}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(height: 5,),
                            ] else
                              ...[
                              ],
                          ],
                        ),
                        Text(
                          'Street Address of Fault: ${_allFaultResults[index]['address']}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5,),
                        Text(
                          'Date of Fault Report: ${_allFaultResults[index]['dateReported']}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5,),
                        Column(
                          children: [
                            if(_allFaultResults[index]['faultStage'] == 1)...[
                              Text(
                                'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.deepOrange),
                              ),
                              const SizedBox(height: 5,),
                            ] else
                              if(_allFaultResults[index]['faultStage'] == 2) ...[
                                Text(
                                  'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.orange),
                                ),
                                const SizedBox(height: 5,),
                              ] else
                                if(_allFaultResults[index]['faultStage'] == 3) ...[
                                  Text(
                                    'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.orangeAccent),
                                  ),
                                  const SizedBox(height: 5,),
                                ] else
                                  if(_allFaultResults[index]['faultStage'] == 4) ...[
                                    Text(
                                      'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.lightGreen),
                                    ),
                                    const SizedBox(height: 5,),
                                  ] else
                                    if(_allFaultResults[index]['faultStage'] == 5) ...[
                                      Text(
                                        'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.lightGreen),
                                      ),
                                      const SizedBox(height: 5,),
                                    ] else
                                      ...[
                                      ],
                          ],
                        ),
                        Text(
                          'Fault Type: ${_allFaultResults[index]['faultType']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5,),
                        Column(
                          children: [
                            if(_allFaultResults[index]['faultDescription'] != "")...[
                              Text(
                                'Fault Description: ${_allFaultResults[index]['faultDescription']}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(height: 5,),
                            ] else
                              ...[
                              ],
                          ],
                        ),
                        Column(
                          children: [
                            if(_allFaultResults[index]['adminComment'] != "")...[
                              Text(
                                'Admin Comment: ${_allFaultResults[index]['adminComment']}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(height: 5,),
                            ] else
                              ...[
                              ],
                          ],
                        ),
                        Column(
                          children: [
                            if(_allFaultResults[index]['reallocationComment'] != "")...[
                              Text(
                                'Reason fault reallocated: ${_allFaultResults[index]['reAllocationComment']}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(height: 5,),
                            ] else
                              ...[
                              ],
                          ],
                        ),
                        Column(
                          children: [
                            if(_allFaultResults[index]['managerAllocated'] != "")...[
                              Text(
                                'Manager of fault: ${_allFaultResults[index]['managerAllocated']}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(height: 5,),
                            ] else
                              ...[
                              ],
                          ],
                        ),

                        Column(
                          children: [
                            if(_allFaultResults[index]['attendeeAllocated'] != "")...[
                              Text(
                                'Attendee Allocated: ${_allFaultResults[index]['attendeeAllocated']}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(height: 5,),
                            ] else
                              ...[
                              ],
                          ],
                        ),
                        Column(
                          children: [
                            if(_allFaultResults[index]['attendeeCom1'] != "")...[
                              Text(
                                'Attendee Comment: ${_allFaultResults[index]['attendeeCom1']}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(height: 5,),
                            ] else
                              ...[
                              ],
                          ],
                        ),
                        Column(
                          children: [
                            if(_allFaultResults[index]['managerCom1'] != "")...[
                              Text(
                                'Manager Comment: ${_allFaultResults[index]['managerCom1']}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(height: 5,),
                            ] else
                              ...[
                              ],
                          ],
                        ),
                        Column(
                          children: [
                            if(_allFaultResults[index]['attendeeCom2'] != "")...[
                              Text(
                                'Attendee Followup Comment: ${_allFaultResults[index]['attendeeCom2']}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(height: 5,),
                            ] else
                              ...[
                              ],
                          ],
                        ),
                        Column(
                          children: [
                            if(_allFaultResults[index]['managerCom2'] != "")...[
                              Text(
                                'Manager Final/Additional Comment: ${_allFaultResults[index]['managerCom2']}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(height: 5,),
                            ] else
                              ...[
                              ],
                          ],
                        ),
                        Column(
                          children: [
                            if(_allFaultResults[index]['attendeeCom3'] != "")...[
                              Text(
                                'Attendee Final Comment: ${_allFaultResults[index]['attendeeCom3']}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(height: 5,),
                            ] else
                              ...[
                              ],
                          ],
                        ),
                        Column(
                          children: [
                            if(_allFaultResults[index]['managerCom3'] != "")...[
                              Text(
                                'Manager Final Comment: ${_allFaultResults[index]['managerCom3']}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(height: 5,),
                            ] else
                              ...[
                              ],
                          ],
                        ),
                        Text(
                          'Resolve State: $status',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 20,),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                BasicIconButtonGrey(
                                  onPress: () async {
                                    accountNumberRep = _allFaultResults[index]['accountNumber'];
                                    locationGivenRep = _allFaultResults[index]['address'];

                                    Navigator.push(context, MaterialPageRoute(
                                        builder: (context) => MapScreenProp(propAddress: locationGivenRep, propAccNumber: accountNumberRep,)
                                    ));
                                  },
                                  labelText: 'Location',
                                  fSize: 14,
                                  faIcon: const FaIcon(Icons.map,),
                                  fgColor: Colors.green,
                                  btSize: const Size(50, 38),
                                ),
                                const SizedBox(width: 5,),
                                BasicIconButtonGrey(
                                  onPress: () async {
                                    showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (context) {
                                          return
                                            AlertDialog(
                                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                                              title: const Text("Call Reporter!"),
                                              content: const Text("Would you like to call the individual who logged the fault?"),
                                              actions: [
                                                IconButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  icon: const Icon(Icons.cancel, color: Colors.red,),
                                                ),
                                                IconButton(
                                                  onPressed: () {
                                                    reporterCellGiven = _allFaultResults[index]['reporterContact'];

                                                    final Uri _tel = Uri.parse('tel:${reporterCellGiven.toString()}');
                                                    launchUrl(_tel);

                                                    Navigator.of(context).pop();
                                                  },
                                                  icon: const Icon(Icons.done, color: Colors.green,),
                                                ),
                                              ],
                                            );
                                        });
                                  },
                                  labelText: 'Call User',
                                  fSize: 14,
                                  faIcon: const FaIcon(Icons.call,),
                                  fgColor: Colors.orange,
                                  btSize: const Size(50, 38),
                                ),
                                const SizedBox(width: 5,),
                              ],
                            ),
                            Column(
                              children: [
                                Visibility(
                                  visible: adminAcc,
                                  child: Center(
                                    child: BasicIconButtonGrey(
                                      onPress: () async {
                                        _updateReport(_allFaultResults[index]);
                                      },
                                      labelText: 'Remove from archive',
                                      fSize: 14,
                                      faIcon: const FaIcon(Icons.replay_circle_filled,),
                                      fgColor: Colors.blue,
                                      btSize: const Size(50, 38),
                                    ),
                                  ),
                                ),
                              ],
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
      );
    }
    return const Padding(
      padding: EdgeInsets.all(10.0),
      child: Center(
          child: CircularProgressIndicator()),
    );

  }

  Future<Widget> _getImage(BuildContext context, String imageName) async{
    Image image;
    final value = await FireStorageService.loadImage(context, imageName);
    image =Image.network(
      value.toString(),
      fit: BoxFit.fill,
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8,),
      child: Row(
        children: [
          const SizedBox(width: 6,),
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

  //this widget is for displaying the fault report list all together
  Widget firebaseFaultCard(CollectionReference<Object?> faultDataStream){
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: faultDataStream.orderBy('dateReported', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                streamSnapshot.data!.docs[index];

                if(((documentSnapshot['address'].trim()).toLowerCase()).contains((_searchController.text.trim()).toLowerCase())){
                  if(streamSnapshot.data!.docs[index]['faultResolved'] == true || documentSnapshot['faultStage'] >= 5){
                    return Card(
                      margin: const EdgeInsets.fromLTRB(10.0,0.0,10.0,10.0),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'Fault Information',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            Column(
                              children: [
                                if(documentSnapshot['accountNumber'] != "")...[
                                  Text(
                                    'Reporter Account Number: ${documentSnapshot['accountNumber']}',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5,),
                                ] else ...[

                                ],
                              ],
                            ),
                            Text(
                              'Street Address of Fault: ${documentSnapshot['address']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Fault Type: ${documentSnapshot['faultType']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Column(
                              children: [
                                if(documentSnapshot['faultDescription'] != "")...[
                                  Text(
                                    'Fault Description: ${documentSnapshot['faultDescription']}',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5,),
                                ] else ...[

                                ],
                              ],
                            ),
                            Column(
                              children: [
                                if(documentSnapshot['handlerCom1'] != "")...[
                                  Text(
                                    'Handler Comment: ${documentSnapshot['handlerCom1']}',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5,),
                                ] else ...[

                                ],
                              ],
                            ),
                            Column(
                              children: [
                                if(documentSnapshot['adminComment'] != "")...[
                                  Text(
                                    'Admin Comment: ${documentSnapshot['adminComment']}',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5,),
                                ] else ...[

                                ],
                              ],
                            ),
                            Column(
                              children: [
                                if(documentSnapshot['handlerCom2'] != "")...[
                                  Text(
                                    'Handler Final Comment: ${documentSnapshot['handlerCom2']}',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5,),
                                ] else ...[

                                ],
                              ],
                            ),
                            Column(
                              children: [
                                if(documentSnapshot['depComment2'] != "")...[
                                  Text(
                                    'Department Final Comment: ${documentSnapshot['depComment2']}',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5,),
                                ] else ...[

                                ],
                              ],
                            ),
                            Text(
                              'Resolve State: ${documentSnapshot['faultResolved'].toString()}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Date of Fault Report: ${documentSnapshot['dateReported']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            InkWell(
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 5),
                                height: 180,
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
                                    child: FutureBuilder(
                                        future: _getImage(
                                          ///Firebase image location must be changed to display image based on the address
                                            context, 'files/faultImages/${documentSnapshot['dateReported']}/${documentSnapshot['address']}'),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasError) {
                                            return const Padding(
                                              padding: EdgeInsets.all(20.0),
                                              child: Text('Image not uploaded for Fault.',),
                                            ); //${snapshot.error} if error needs to be displayed instead
                                          }
                                          if (snapshot.connectionState ==
                                              ConnectionState.done) {
                                            return Container(
                                              child: snapshot.data,
                                            );
                                          }
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Container(
                                              child: const CircularProgressIndicator(),);
                                          }
                                          return Container();
                                        }
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20,),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        accountNumberRep = documentSnapshot['accountNumber'];
                                        locationGivenRep = documentSnapshot['address'];

                                        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        //     content: Text('$accountNumber $locationGiven ')));

                                        Navigator.push(context,
                                            MaterialPageRoute(
                                                builder: (context) => MapScreenProp(propAddress: locationGivenRep, propAccNumber: accountNumberRep,)
                                            ));
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[350],
                                        fixedSize: const Size(160, 10),),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.map,
                                            color: Colors.green[700],
                                          ),
                                          const SizedBox(width: 2,),
                                          const Text('Location', style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,),),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 5,),
                                    ElevatedButton(
                                      onPressed: () {
                                        faultStage = documentSnapshot['faultStage'];
                                        _updateReport(documentSnapshot);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[350],
                                        fixedSize: const Size(110, 10),),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                          const SizedBox(width: 2,),
                                          const Text('Update', style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,),),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 5,),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (context) {
                                          return
                                            AlertDialog(
                                              shape: const RoundedRectangleBorder(
                                                  borderRadius:
                                                  BorderRadius.all(Radius.circular(16))),
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
                                                    reporterCellGiven = documentSnapshot['reporterContact'];

                                                    final Uri _tel = Uri.parse('tel:${reporterCellGiven.toString()}');
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
                                    fixedSize: const Size(150, 10),),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.call,
                                        color: Colors.orange[700],
                                      ),
                                      const SizedBox(width: 2,),
                                      const Text('Call Reporter', style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,),),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5,),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox();
                  }
                }
              },
            );
          } else {
            return const Padding(
              padding: EdgeInsets.all(10.0),
              child: Center(
                  child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }

  //This class is for updating the report stages by the manager and the handler to comment through phases of the report
  Future<void> _updateReport([DocumentSnapshot? documentSnapshot]) async {

      _faultResolvedController = documentSnapshot?['faultResolved'];


    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    void _createBottomSheet() async{
      showModalBottomSheet(
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
                              child: const Text('Re-open Fault'),
                            ),
                            Visibility(
                              visible: visShow,
                              child:
                              Container(
                                height: 50,
                                padding: const EdgeInsets.only(left: 0.0, right: 25.0),
                                child: Row(
                                  children: <Widget>[
                                    const Text('Fault Resolved?', style: TextStyle(fontSize: 16, fontWeight:FontWeight.w400 ),),
                                    const SizedBox(width: 5,),
                                    Checkbox(
                                      checkColor: Colors.white,
                                      fillColor: MaterialStateProperty.all<Color>(
                                          Colors.green),
                                      value: _faultResolvedController,
                                      onChanged: (bool? value) async {
                                        setState(() {
                                          _faultResolvedController = value!;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            ElevatedButton(
                              child: const Text('Set Resolve Status'),
                              onPressed: () async {
                                final bool faultResolved = _faultResolvedController;

                                if (_faultResolvedController != true) {
                                  await _faultData
                                      .doc(documentSnapshot?.id).update({
                                    "faultResolved": faultResolved,
                                    "faultStage": 1,
                                  });
                                  Fluttertoast.showToast(msg: 'Fault has been moved to unresolved fault stage 1', gravity: ToastGravity.CENTER);
                                }

                                _faultResolvedController = false;

                                if(context.mounted)Navigator.of(context).pop();

                              },
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

}
