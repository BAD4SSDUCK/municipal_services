import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:municipal_services/code/NoticePages/notice_config_arc_screen.dart';
import 'package:municipal_services/code/faultPages/fault_task_screen_archive.dart';
import 'package:municipal_services/code/MapTools/map_screen.dart';
import 'package:municipal_services/code/MapTools/map_screen_prop.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';
import 'package:municipal_services/code/Reusable/push_notification_message.dart';

class NoticeConfigScreen extends StatefulWidget {
  const NoticeConfigScreen({
    super.key,
    required this.userNumber,
    this.municipalityUserEmail,
    this.districtId,
    required this.municipalityId,
    required this.isLocalMunicipality,
    required this.isLocalUser,
  });

  final String userNumber;
  final String? municipalityUserEmail;
  final String? districtId;
  final String municipalityId;
  final bool isLocalMunicipality;
  final bool isLocalUser;

  @override
  State<NoticeConfigScreen> createState() => _NoticeConfigScreenState();
}

final FirebaseAuth auth = FirebaseAuth.instance;

final User? user = auth.currentUser;
final uid = user?.uid;
final email = user?.email;
String userID = uid as String;
String userEmail = email as String;

class _NoticeConfigScreenState extends State<NoticeConfigScreen>   with TickerProviderStateMixin {
  CollectionReference? _listUserTokens;
  CollectionReference? _listNotifications;
  String districtId = '';
  String municipalityId = '';
  List<String> usersAccountNumbers = [];
  bool isLocalMunicipality = false;
  bool _isLoading = false;
  bool isLocalUser = true;
  List<String> municipalities = []; // To hold the list of municipality names
  String? selectedMunicipality = "Select Municipality";
  List<DocumentSnapshot> filteredProperties = [];
  final FocusNode notifyAll = FocusNode();
  final FocusNode notifyTarget = FocusNode();
  final FocusNode notifyWard = FocusNode();
  final FocusNode notifySuburb = FocusNode();
  final FocusNode notifyStreet = FocusNode();
  final ScrollController _notifyAllScroller= ScrollController();
  final ScrollController _notifyTargetScroller = ScrollController();
  final ScrollController _notifyWardScroller = ScrollController();
  final ScrollController _notifySuburbScroller = ScrollController();
  final ScrollController _notifyStreetScroller = ScrollController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    notifyAll.requestFocus();
    notifyTarget.requestFocus();
    notifyWard.requestFocus();
    notifySuburb.requestFocus();
    notifyStreet.requestFocus();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 0) {
        notifyAll.requestFocus();
      } else if (_tabController.index == 1) {
        notifyTarget.requestFocus();
      }
      else if (_tabController.index==2){
        notifyWard.requestFocus();
      }
      else if (_tabController.index==3){
        notifySuburb.requestFocus();
      }
      else if (_tabController.index==4){
        notifyStreet.requestFocus();
      }
    });

    notifyAll.requestFocus();

    // Listeners for scroll position
    _notifyAllScroller.addListener(() {
    });
    _notifyTargetScroller.addListener(() {
    });
    _notifyWardScroller.addListener(() {
    });
    _notifySuburbScroller.addListener(() {
    });
    _notifyStreetScroller.addListener(() {
    });

    fetchUserDetails().then((_) {
      if (isLocalMunicipality) {
        // Local user, proceed with fetching data
        getUsersPropStream();
        getPropSuburbStream();
        _fetchData();
        _fetchTokenData();
      } else {
        // District user, wait for municipality selection
        print("Waiting for municipality selection...");
      }
    });

    // Listeners setup
    _searchWardController.addListener(_onWardChanged);
    _searchController.addListener(_onSearchChanged);
    _searchSuburbController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    notifyAll.dispose();
    notifyTarget.dispose();
    notifyWard.dispose();
    notifySuburb.dispose();
    notifyStreet.dispose();
    _notifyAllScroller.dispose();
    _notifyTargetScroller.dispose();
    _notifyWardScroller.dispose();
    _notifySuburbScroller.dispose();
    _notifyStreetScroller.dispose();
    _tabController.dispose();
    // Remove listeners first
    _searchWardController.removeListener(_onWardChanged);
    _searchController.removeListener(_onSearchChanged);
    _searchSuburbController.removeListener(_onSearchChanged);

    // Then dispose controllers
    _searchWardController.dispose();
    _searchController.dispose();
    _searchSuburbController.dispose();

    // Nullify variables to avoid unnecessary memory usage
    _headerController.clear();
    _messageController.clear();
    _allUserTokenResults.clear();
    _allUserPropResults.clear();
    _allUserResults.clear();
    usersNumbers.clear();
    usersTokens.clear();
    super.dispose();
  }

  // Future<void> fetchUserDetails() async {
  //   try {
  //     print("Fetching user details...");
  //     User? user = FirebaseAuth.instance.currentUser;
  //     if (user != null) {
  //       userEmail = user.email!;
  //       print("User email: $userEmail");
  //
  //       QuerySnapshot userSnapshot = await FirebaseFirestore.instance
  //           .collectionGroup('users')
  //           .where('email', isEqualTo: userEmail)
  //           .limit(1)
  //           .get();
  //
  //       if (userSnapshot.docs.isNotEmpty) {
  //         var userDoc = userSnapshot.docs.first;
  //         final userPathSegments = userDoc.reference.path.split('/');
  //
  //         if (userDoc['isLocalMunicipality'] ?? false) {
  //           isLocalMunicipality = true;
  //           municipalityId = "testLocal";
  //           print("User is part of a local municipality.");
  //         } else {
  //           districtId = userPathSegments[1];
  //           municipalityId = userPathSegments[3];
  //           print("Assigned districtId: $districtId, municipalityId: $municipalityId");
  //         }
  //
  //         if (isLocalMunicipality) {
  //           setState(() {
  //             _listUserTokens = FirebaseFirestore.instance
  //                 .collection('localMunicipalities')
  //                 .doc(municipalityId)
  //                 .collection('UserToken');
  //
  //             _listNotifications = FirebaseFirestore.instance
  //                 .collection('localMunicipalities')
  //                 .doc(municipalityId)
  //                 .collection('Notifications');
  //           });
  //         } else {
  //           setState(() {
  //             _listUserTokens = FirebaseFirestore.instance
  //                 .collection('districts')
  //                 .doc(districtId)
  //                 .collection('municipalities')
  //                 .doc(municipalityId)
  //                 .collection('UserToken');
  //
  //             _listNotifications = FirebaseFirestore.instance
  //                 .collection('districts')
  //                 .doc(districtId)
  //                 .collection('municipalities')
  //                 .doc(municipalityId)
  //                 .collection('Notifications');
  //           });
  //         }
  //       } else {
  //         print("No user document found for the provided email.");
  //       }
  //     } else {
  //       print("No current user found.");
  //     }
  //   } catch (e) {
  //     print('Error fetching user details: $e');
  //   }
  // }

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
            // District-based user
            districtId = userPathSegments[1];
            isLocalMunicipality = false;
            print("District User Detected: districtId = $districtId");
            print("Waiting for district user to select a municipality.");
          } else if (userPathSegments.contains('localMunicipalities')) {
            // Local municipality user
            municipalityId = userPathSegments[1];
            isLocalMunicipality = true;
            print(
                "Local Municipality User Detected: municipalityId = $municipalityId");
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

            // Set UserToken and Notification paths for local municipalities
            setState(() {
              _listUserTokens = FirebaseFirestore.instance
                  .collection('localMunicipalities')
                  .doc(municipalityId)
                  .collection('UserToken');

              _listNotifications = FirebaseFirestore.instance
                  .collection('localMunicipalities')
                  .doc(municipalityId)
                  .collection('Notifications');
            });
          } else {
            print(
                "District user detected, waiting for municipality selection.");
            // Allow the dropdown to be active and populated
            await fetchMunicipalities();

            // Set UserToken and Notification paths for district-based municipalities
            setState(() {
              _listUserTokens = FirebaseFirestore.instance
                  .collection('districts')
                  .doc(districtId)
                  .collection('municipalities')
                  .doc(municipalityId)
                  .collection('UserToken');

              _listNotifications = FirebaseFirestore.instance
                  .collection('districts')
                  .doc(districtId)
                  .collection('municipalities')
                  .doc(municipalityId)
                  .collection('Notifications');
            });
          }
        } else {
          print("Waiting for district user to select a municipality.");
        }
      } else {
        print('No user document found.');
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  // final CollectionReference _listUserTokens =
  // FirebaseFirestore.instance.collection('UserToken');
  //
  // final CollectionReference _listNotifications =
  // FirebaseFirestore.instance.collection('Notifications');

  final CollectionReference _listProps =
      FirebaseFirestore.instance.collection('properties');

  final _headerController = TextEditingController();
  final _messageController = TextEditingController();
  late final TextEditingController _searchBarController =
      TextEditingController();
  late bool _noticeReadController;

  List<String> usersRetrieve = [];
  List<String> usersNumbers = [];
  List<String> usersTokens = [];

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
  String searchText = '';

  bool visShow = true;
  bool visHide = false;
  bool adminAcc = false;

  int numTokens = 0;

  TextEditingController _searchController = TextEditingController();
  TextEditingController _searchWardController = TextEditingController();
  TextEditingController _searchSuburbController = TextEditingController();
  TextEditingController _searchStreetController = TextEditingController();
  final CollectionReference _propList =
      FirebaseFirestore.instance.collection('properties');

  List<String> dropdownWards = [
    'Select Ward',
    '01',
    '02',
    '03',
    '04',
    '05',
    '06',
    '07',
    '08',
    '09',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20',
    '21',
    '22',
    '23',
    '24',
    '25',
    '26',
    '27',
    '28',
    '29',
    '30',
    '31',
    '32',
    '33',
    '34',
    '35',
    '36',
    '37',
    '38',
    '39',
    '40',
  ];
  String dropdownValue = 'Select Ward';
  String dropdownSuburbValue = 'Select Suburb';
  List<String> dropdownSuburbs = ['Select Suburb'];
  String dropdownStreetValue = 'Select Street';
  List<String> dropdownStreets = ['Select Street'];
  String userNameProp = '';
  String userAddress = '';
  String userWardProp = '';
  String userValid = '';
  String userPhoneProp = '';
  String userPhoneToken = '';
  String userPhoneNumber = '';
  String userRole = '';

  List _allUserResults = [];
  List _allUserPropResults = [];
  List _allUserWardResults = [];
  List _allUserSuburbResults = [];
  List _allPropResults = [];
  List _allSuburbResults = [];
  List _allUserTokenResults = [];

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

              // Ensure selectedMunicipality is initialized
              selectedMunicipality = "Select Municipality";
            } else {
              print("No municipalities found");
              municipalities = []; // No municipalities found
              selectedMunicipality = "Select Municipality"; // Default value
            }
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
          _allPropResults = propertiesSnapshot.docs.cast<DocumentSnapshot>();
          _allUserPropResults =
              propertiesSnapshot.docs.cast<DocumentSnapshot>();
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
            _allPropResults = propertiesSnapshot.docs.cast<DocumentSnapshot>();
            _allUserPropResults =
                propertiesSnapshot.docs.cast<DocumentSnapshot>();
          });
        }
        //  print('Properties fetched for local municipality: $municipalityId');
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

      if (propertiesSnapshot.docs.isNotEmpty) {
        // Print the actual data to verify
        for (var doc in propertiesSnapshot.docs) {
          //   print('Fetched property: ${doc.data()}');
        }

        if (mounted) {
          setState(() {
            _allPropResults = propertiesSnapshot.docs.cast<DocumentSnapshot>();
            _allUserPropResults =
                propertiesSnapshot.docs.cast<DocumentSnapshot>();
            print(
                "Number of properties set to _allUserPropResults: ${_allUserPropResults.length}");
          });
        }
      } else {
        print("No properties found for $municipality.");
      }
    } catch (e) {
      print('Error fetching properties for $municipality: $e');
    }
  }

  Future<String?> getTokenByAccountNumber(String accountNumber) async {
    try {
      QuerySnapshot tokenSnapshot = await FirebaseFirestore.instance
          .collectionGroup('properties')
          .where('accountNumber', isEqualTo: accountNumber)
          .limit(1)
          .get();

      if (tokenSnapshot.docs.isNotEmpty) {
        var doc = tokenSnapshot.docs.first;
        return doc['token'];
      } else {
        print('No token found for account number: $accountNumber');
        return null;
      }
    } catch (e) {
      print('Error fetching token for account number $accountNumber: $e');
      return null;
    }
  }

  // Future<void> getUsersTokenStream() async {
  //   List<String> tokensList = []; // To store all tokens
  //   List<String> accountNumbersList = []; // To store all account numbers
  //
  //   try {
  //     print('Fetching users tokens from Firestore...');
  //
  //     QuerySnapshot propertiesSnapshot;
  //
  //     // Fetch properties based on the user's municipality type
  //     if (isLocalMunicipality) {
  //       propertiesSnapshot = await FirebaseFirestore.instance
  //           .collection('localMunicipalities')
  //           .doc(municipalityId)
  //           .collection('properties')
  //           .get();
  //       print("Fetching properties for local municipality: $municipalityId");
  //     } else {
  //       propertiesSnapshot = await FirebaseFirestore.instance
  //           .collection('districts')
  //           .doc(districtId)
  //           .collection('municipalities')
  //           .doc(municipalityId)
  //           .collection('properties')
  //           .get();
  //       print("Fetching properties for district: $districtId and municipality: $municipalityId");
  //     }
  //
  //     print('Number of properties found: ${propertiesSnapshot.docs.length}');
  //
  //     for (var doc in propertiesSnapshot.docs) {
  //       if (doc.exists) {
  //         var data = doc.data() as Map<String, dynamic>?;
  //
  //         if (data != null) {
  //           String? token = data['token'] as String?;
  //           String? accountNumber = data['accountNumber'] as String?;
  //
  //           if (token != null && accountNumber != null) {
  //             // Add each token and account number to the lists
  //             tokensList.add(token);
  //             accountNumbersList.add(accountNumber);
  //           }
  //         }
  //       }
  //     }
  //
  //     // Assign to usersTokens and usersNumbers lists
  //     if (tokensList.isNotEmpty && accountNumbersList.isNotEmpty) {
  //       usersTokens = tokensList;
  //       usersNumbers = accountNumbersList;
  //
  //       print('Users Tokens: $usersTokens');
  //       print('Users Numbers: $usersNumbers');
  //     } else {
  //       print('No users tokens or numbers found');
  //     }
  //   } catch (e) {
  //     print('Error fetching users tokens: $e');
  //   }
  // }
  Future<void> getUsersTokenStream(
      {String? selectedWard,
      String? selectedSuburb,
      String? selectedStreet}) async {
    List<String> tokensList = [];
    List<String> accountNumbersList = [];

    try {
      print('Fetching users tokens from Firestore...');

      QuerySnapshot propertiesSnapshot;

      // Fetch properties based on the user's municipality type
      if (isLocalMunicipality) {
        propertiesSnapshot = await FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(municipalityId)
            .collection('properties')
            .get();
        print("Fetching properties for local municipality: $municipalityId");
      } else {
        propertiesSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('properties')
            .get();
        print(
            "Fetching properties for district: $districtId and municipality: $municipalityId");
      }

      print('Number of properties found: ${propertiesSnapshot.docs.length}');

      for (var doc in propertiesSnapshot.docs) {
        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>?;

          if (data != null) {
            String? token = data['token'] as String?;
            String? accountNumber = data['accountNumber'] as String?;
            String? address = data['address'] as String?;
            String? ward = data['ward'] as String?;

            // If both token and accountNumber exist
            if (token != null && accountNumber != null) {
              bool matchesWard = true;
              bool matchesSuburb = true;
              bool matchesStreet = true;
              // Check if selectedWard is provided and matches the property's ward
              if (selectedWard != null &&
                  selectedWard != 'Select Ward' &&
                  ward != null) {
                matchesWard = ward == selectedWard;
              }

              // Extract suburb from address (after the first comma)
              if (selectedSuburb != null &&
                  selectedSuburb != 'Select Suburb' &&
                  address != null) {
                List<String> addressParts = address.split(',');
                if (addressParts.length > 1) {
                  String extractedSuburb = addressParts[1].trim();
                  matchesSuburb = extractedSuburb.contains(selectedSuburb);
                }
              }
              if (selectedStreet != null &&
                  selectedStreet != 'Select Street' &&
                  address != null) {
                List<String> addressParts = address.split(',');
                if (addressParts.isNotEmpty) {
                  String streetSegment = addressParts[0].trim();
                  String extractedStreet = streetSegment
                      .split(' ')
                      .skip(1)
                      .join(' '); // Skip the first word/number

                  matchesStreet = extractedStreet.contains(selectedStreet);
                }
              }
              // If the property matches both the selected ward and suburb (if applicable), add its token
              if (matchesWard && matchesSuburb && matchesStreet) {
                tokensList.add(token);
                accountNumbersList.add(accountNumber);
              }
            }
          }
        }
      }

      // Assign to usersTokens and usersNumbers lists
      if (tokensList.isNotEmpty && accountNumbersList.isNotEmpty) {
        usersTokens = tokensList;
        usersNumbers = accountNumbersList;

        print('Users Tokens: $usersTokens');
        print('Users Numbers: $usersNumbers');
      } else {
        print('No users tokens or numbers found for the selected filters.');
      }
    } catch (e) {
      print('Error fetching users tokens: $e');
    }
  }

  _onSearchChanged() async {
    searchResultsList();
  }

  searchResultsList() async {
    var showResults = [];
    String searchText = _searchController.text.toLowerCase();

    if (searchText.isNotEmpty) {
      await getUsersPropStream(); // Ensure data is fetched first

      for (var userPropSnapshot in _allUserPropResults) {
        var phoneNumber =
            userPropSnapshot['cellNumber'].toString().toLowerCase();
        var firstName = userPropSnapshot['firstName'].toString().toLowerCase();
        var lastName = userPropSnapshot['lastName'].toString().toLowerCase();
        var address = userPropSnapshot['address'].toString().toLowerCase();

        // Combine firstName and lastName into a fullName
        var fullName = '$firstName $lastName';

        // Check if the search text matches the phone number, full name, or address
        if (phoneNumber.contains(searchText) ||
            fullName.contains(searchText) ||
            address.contains(searchText)) {
          showResults.add(userPropSnapshot);
        }
      }
    } else {
      await getUsersPropStream();
      showResults =
          List.from(_allUserPropResults); // Show all results if search is empty
    }

    if (context.mounted) {
      setState(() {
        _allUserPropResults = showResults;
      });
    }
  }

  void countResult() async {
    _searchBarController.text = widget.userNumber;
    searchText = widget.userNumber;

    var query = _listUserTokens?.where("token");
    var snapshot = await query?.get();
    var count = snapshot?.size;
    numTokens = snapshot!.size;
    print('Records are ::: $count');
    print('num tokens are ::: $numTokens');
  }

  User? user = FirebaseAuth.instance.currentUser;

  void checkAdmin() {
    getUsersStream();
    if (userRole == 'Admin' || userRole == 'Administrator') {
      adminAcc = true;
    } else {
      adminAcc = false;
    }
  }

  Future<void> getUsersStream() async {
    CollectionReference usersCollection;
    if (isLocalMunicipality) {
      usersCollection = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('users');
    } else {
      usersCollection = FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('users');
    }

    var data = await usersCollection.get();
    setState(() {
      _allUserResults = data.docs;
    });
    getUserDetails();
  }

  void getUserDetails() async {
    for (var userSnapshot in _allUserResults) {
      var user = userSnapshot['email'].toString();
      var role = userSnapshot['userRole'].toString();
      if (user == userEmail) {
        userRole = role;
        adminAcc = (userRole == 'Admin' || userRole == 'Administrator');
      }
    }
  }

  // Future<void> getUsersPropStream() async {
  //   CollectionReference propertiesCollection;
  //   if (isLocalMunicipality) {
  //     propertiesCollection = FirebaseFirestore.instance
  //         .collection('localMunicipalities')
  //         .doc(municipalityId)
  //         .collection('properties');
  //   } else {
  //     propertiesCollection = FirebaseFirestore.instance
  //         .collection('districts')
  //         .doc(districtId)
  //         .collection('municipalities')
  //         .doc(municipalityId)
  //         .collection('properties');
  //   }
  //
  //   var data = await propertiesCollection.get();
  //   if (data.docs.isNotEmpty) {
  //     setState(() {
  //       _allPropResults = data.docs;
  //       _allUserPropResults = data.docs;
  //     });
  //   }
  // }

  Future<void> getUsersPropStream() async {
    if (isLocalMunicipality) {
      // Fetch properties for local municipality users
      await fetchPropertiesForLocalMunicipality();
    } else {
      // Fetch properties for the selected municipality (after a district user selects it)
      if (municipalityId.isNotEmpty) {
        await fetchPropertiesByMunicipality(municipalityId);
      } else if (selectedMunicipality != null &&
          selectedMunicipality != "Select Municipality") {
        await fetchPropertiesByMunicipality(selectedMunicipality!);
      } else {
        print(
            "No municipality selected for district user. Cannot fetch properties.");
      }
    }
  }

  Future<void> getPropSuburbStream() async {
    CollectionReference suburbsCollection;
    if (isLocalMunicipality) {
      suburbsCollection = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('suburbs');
    } else {
      suburbsCollection = FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('suburbs');
    }

    try {
      var data =
          await suburbsCollection.orderBy('suburb', descending: false).get();

      if (context.mounted) {
        setState(() {
          // Reset the dropdown list and add the fetched suburbs
          dropdownSuburbs = ['Select Suburb']; // Reset with default value
          dropdownSuburbs
              .addAll(data.docs.map((e) => e['suburb'] as String).toList());
        });
      }
      print('Suburbs fetched successfully: $dropdownSuburbs');
    } catch (e) {
      print('Error fetching suburbs: $e');
    }
  }

  Future<void> getStreetNames() async {
    // Clear any existing street names in the list
    dropdownStreets.clear();

    // Check if a municipality is selected
    if (selectedMunicipality == null ||
        selectedMunicipality!.isEmpty ||
        selectedMunicipality == "Select Municipality") {
      print('No municipality selected. Unable to fetch street names.');
      return;
    }

    // Fetch properties based on the selected municipality
    CollectionReference propertiesCollection;
    if (isLocalMunicipality) {
      // Local municipality
      propertiesCollection = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(
              municipalityId) // Using selected municipality's ID for local municipality
          .collection('properties');
    } else {
      // District municipality
      propertiesCollection = FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId) // Ensure districtId is set properly
          .collection('municipalities')
          .doc(municipalityId) // Using selected municipality's ID
          .collection('properties');
    }

    try {
      // Retrieve property documents and extract street names
      var propertiesSnapshot = await propertiesCollection.get();
      for (var property in propertiesSnapshot.docs) {
        String address = property['address'];

        // Split the address at commas, then remove any initial numbers from the street segment
        List<String> addressParts = address.split(',');
        if (addressParts.isNotEmpty) {
          // Extract the street segment and remove the first word if it’s a number
          String streetSegment = addressParts[0].trim();
          String streetName = streetSegment
              .split(' ')
              .skip(1)
              .join(' '); // Skip the first part (number) if it exists

          // Add the street name to the list if it's not empty
          if (streetName.isNotEmpty) {
            dropdownStreets.add(streetName);
          }
        }
      }

      // Remove duplicates and set initial dropdown value
      dropdownStreets = dropdownStreets.toSet().toList();
      setState(() {
        dropdownStreetValue = dropdownStreets.isNotEmpty
            ? dropdownStreets.first
            : 'Select Street';
      });
    } catch (e) {
      print('Error fetching street names: $e');
    }
  }

  Widget buildSuburbDropdown() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DropdownButton<String>(
        value: dropdownSuburbValue,
        icon: const Icon(Icons.arrow_downward),
        iconSize: 24,
        elevation: 16,
        style: const TextStyle(color: Colors.green),
        underline: Container(
          height: 2,
          color: Colors.greenAccent,
        ),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              dropdownSuburbValue = newValue;
            });
          }
        },
        items: dropdownSuburbs.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }

  getSuburbDetails() async {
    for (var suburbSnapshot in _allSuburbResults) {
      dropdownSuburbs.add(suburbSnapshot['suburb']);
      print('the suburbs are $dropdownSuburbs');
    }

    // Remove duplicates and set initial value for dropdown
    dropdownSuburbs = dropdownSuburbs.toSet().toList();
    setState(() {
      dropdownSuburbValue =
          dropdownSuburbs.isNotEmpty ? dropdownSuburbs.first : 'Select Suburb';
    });
  }

  searchWardsList() async {
    var showResults = [];
    if (_searchWardController.text != "Select Ward") {
      getUsersPropStream();
      for (var propSnapshot in _allUserPropResults) {
        ///Need to build a property model that retrieves property data entirely from the db
        var ward = propSnapshot['ward'].toString().toLowerCase();

        if (ward == (_searchController.text.toLowerCase())) {
          showResults.add(propSnapshot);
        }
      }
    } else {
      getUsersPropStream();
      showResults = List.from(_allUserPropResults);
    }
    if (_searchSuburbController.text != "Select Suburb") {
      getUsersPropStream();
      for (var propSnapshot in _allUserPropResults) {
        ///Need to build a property model that retrieves property data entirely from the db
        var suburb = propSnapshot['address'].toString().toLowerCase();

        if (suburb.contains(_searchSuburbController.text.toLowerCase())) {
          showResults.add(propSnapshot);
        }
      }
    } else {
      getUsersPropStream();
      showResults = List.from(_allUserPropResults);
    }
    if (context.mounted) {
      setState(() {
        _allUserPropResults = showResults;
      });
    }
  }

  _onWardChanged() async {
    searchWardsList();
  }

  Future<List<Map<String, dynamic>>> _fetchData() async {
    List<Map<String, dynamic>> combinedData = [];
    CollectionReference propertiesCollection;

    if (isLocalMunicipality) {
      propertiesCollection = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('properties');
    } else {
      propertiesCollection = FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('properties');
    }

    QuerySnapshot allUserPropSnapshot = await propertiesCollection.get();

    for (var doc in allUserPropSnapshot.docs) {
      String accountNumber = doc['accountNumber'];
      String propertyOwner = '${doc['firstName']} ${doc['lastName']}';
      String propertyAddress = doc['address'];
      String propertyWard = doc['ward'];
      String phoneNumber = doc['cellNumber'];
      String? token = doc['token']; // Token field in the properties collection

      // Determine registration status based on the presence of a token
      String registrationStatus = (token != null && token.isNotEmpty)
          ? 'User will receive notice'
          : 'User not registered in this app';

      // Add property data to combined list
      combinedData.add({
        'name': propertyOwner,
        'address': propertyAddress,
        'ward': propertyWard,
        'phoneNumber': phoneNumber,
        'accountNumber': accountNumber,
        'registered': registrationStatus,
        'token': token ?? 'No token data available',
      });
    }

    return combinedData;
  }


  Future<List<Map<String, dynamic>>> _fetchTokenData() async {
    List<Map<String, dynamic>> combinedData = [];
    CollectionReference propertiesCollection;

    if (isLocalMunicipality) {
      propertiesCollection = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('properties');
    } else {
      propertiesCollection = FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('properties');
    }

    QuerySnapshot propertiesSnapshot = await propertiesCollection.get();

    for (var propertyDoc in propertiesSnapshot.docs) {
      String accountNumber = propertyDoc['accountNumber'];
      String phoneNumber = propertyDoc['cellNumber'];
      String propertyOwner = '${propertyDoc['firstName']} ${propertyDoc['lastName']}';
      String propertyAddress = propertyDoc['address'];
      String propertyWard = propertyDoc['ward'];
      String? token = propertyDoc['token'];

      // Check if the property has a registered token
      if (token != null && token.isNotEmpty) {
        combinedData.add({
          'name': propertyOwner,
          'address': propertyAddress,
          'ward': propertyWard,
          'phoneNumber': phoneNumber,
          'accountNumber': accountNumber,
          'registered': 'User will receive notice',
          'token': token,
        });
      } else {
        combinedData.add({
          'name': propertyOwner,
          'address': propertyAddress,
          'ward': propertyWard,
          'phoneNumber': phoneNumber,
          'accountNumber': accountNumber,
          'registered': 'User not registered in this app',
          'token': 'No token data available',
        });
      }
    }

    return combinedData;
  }


  Widget buildMunicipalityDropdown() {
    if (isLocalMunicipality) {
      // Local municipality users don't need to select a municipality
      return SizedBox.shrink();
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 40),
          child: DropdownButton<String>(
            value: selectedMunicipality!.isEmpty ? null : selectedMunicipality,
            hint: const Text('Select Municipality'),
            isExpanded: true,
            onChanged: (String? newValue) {
              if (mounted) {
                setState(() {
                  selectedMunicipality = newValue;
                  municipalityId =
                      selectedMunicipality!; // Update municipalityId based on the selected municipality
                  getPropSuburbStream();
                  if (selectedMunicipality == null ||
                      selectedMunicipality == "Select Municipality") {
                    fetchPropertiesForAllMunicipalities();
                  } else {
                    fetchPropertiesByMunicipality(newValue!);
                    getStreetNames();
                  }
                });
              }
            },
            items: [
              const DropdownMenuItem<String>(
                value: "Select Municipality",
                child: Align(
                  alignment: Alignment.center,
                  child: Text("Please Select a Municipality First"),
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
      );
    }
  }

  Widget buildStreetDropdown() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DropdownButton<String>(
        value: dropdownStreetValue,
        icon: const Icon(Icons.arrow_downward),
        iconSize: 24,
        elevation: 16,
        style: const TextStyle(color: Colors.green),
        underline: Container(
          height: 2,
          color: Colors.greenAccent,
        ),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              dropdownStreetValue = newValue;
            });
          }
        },
        items: dropdownStreets.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Colors.grey[350],
        appBar: AppBar(
          title: const Text(
            'User Notifications',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: <Widget>[
            Visibility(
              visible: adminAcc,
              child: IconButton(
                  onPressed: () {
                    usersNumbers = [];
                    usersTokens = [];
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NoticeConfigArcScreen()));
                  },
                  icon: const Icon(
                    Icons.history_outlined,
                    color: Colors.white,
                  )),
            ),
          ],
          bottom: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      'Notify\nAll',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Tab(
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      'Target\nNotice',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Tab(
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      'Ward\nNotice',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Tab(
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      'Suburb\nNotice',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Tab(
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      'Street\nNotice',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ]),
        ),
        body: TabBarView(controller: _tabController, children: [
          ///Tab for all
          Column(
            children: [
              const SizedBox(
                height: 8,
              ),

              ///this onPress code bellow is used to set the message information and pop it up to the user in their notifications.
              ///button not needed as it will only be used when a new chat is sent or when an admin sends to a specific phone which will be a list of tokens per device
              buildMunicipalityDropdown(),
              BasicIconButtonGrey(
                onPress: () async {
                  _headerController.text = '';
                  _messageController.text = '';
                  _notifyAllUser();
                },
                labelText: 'Send Notice To All',
                fSize: 16,
                faIcon: const FaIcon(
                  Icons.notifications,
                ),
                fgColor: Colors.red,
                btSize: const Size(300, 50),
              ),

              const SizedBox(
                height: 5,
              ),

              ///made the listview card a reusable widget
              Expanded(
                child: userCard(),
              ),
            ],
          ),

          ///Tab for searching
          Column(
            children: [
              ///this onPress code bellow is used to set the message information and pop it up to the user in their notifications.
              ///button not needed as it will only be used when a new chat is sent or when an admin sends to a specific phone which will be a list of tokens per device
              buildMunicipalityDropdown(),

              /// Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                child: SearchBar(
                  controller: _searchController,
                  padding: const MaterialStatePropertyAll<EdgeInsets>(
                      EdgeInsets.symmetric(horizontal: 16.0)),
                  leading: const Icon(Icons.search),
                  hintText: "Search",
                  onChanged: (value) async {
                    if (context.mounted) {
                      setState(() {
                        searchText = value;
                        print('this is the input text ::: $searchText');
                      });
                    }
                  },
                ),
              ),

              /// Search bar end

              ///made the listview card a reusable widget
              Expanded(
                child: userTokenSearchCard(),
              ),
            ],
          ),

          ///Tab for wards
          Column(
            children: [
              ///this onPress code bellow is used to set the message information and pop it up to the user in their notifications.
              ///button not needed as it will only be used when a new chat is sent or when an admin sends to a specific phone which will be a list of tokens per device
              buildMunicipalityDropdown(),

              /// Warc select bar
              const SizedBox(
                height: 5,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                child: Column(children: [
                  SizedBox(
                    // width: 400,
                    height: 50,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: Center(
                        child: TextField(
                          controller: _searchWardController,

                          ///Input decoration here had to be manual because dropdown button uses suffix icon of the textfield
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
                            fillColor: Colors.white,
                            filled: true,
                            suffixIcon: DropdownButtonFormField<String>(
                              value: dropdownValue,
                              items: dropdownWards
                                  .map<DropdownMenuItem<String>>(
                                      (String value) {
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
                              onChanged: (String? newValue) async {
                                if (context.mounted) {
                                  setState(() {
                                    dropdownValue =
                                        newValue!; // Set the selected ward

                                    // Only proceed if data for the selected municipality has been loaded
                                    if (_allUserPropResults.isNotEmpty) {
                                      // Filter the properties by the selected ward and cast the result to the correct type
                                      List<DocumentSnapshot<Object?>>
                                          filteredByWard = _allUserPropResults
                                              .where((property) {
                                                return property['ward'] ==
                                                    dropdownValue;
                                              })
                                              .cast<DocumentSnapshot<Object?>>()
                                              .toList();

                                      // Update the filtered results and refresh the UI
                                      _allUserPropResults = filteredByWard;
                                      _searchWardController.text =
                                          dropdownValue;

                                      // Debugging output to verify filtering
                                      print(
                                          "Filtering properties by ward: $dropdownValue");
                                      print(
                                          "Number of properties after filtering: ${_allUserPropResults.length}");
                                    }
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
                ]),
              ),

              /// Search bar end

              const SizedBox(
                height: 5,
              ),

              BasicIconButtonGrey(
                onPress: () async {
                  _notifyWardUsers();
                },
                labelText: 'Notify Selected Ward',
                fSize: 16,
                faIcon: const FaIcon(
                  Icons.notifications,
                ),
                fgColor: Colors.red,
                btSize: const Size(300, 50),
              ),

              const SizedBox(
                height: 5,
              ),

              ///made the listview card a reusable widget
              Expanded(
                child: userWardCard(),
              ),
            ],
          ),

          ///Tab for suburb
          Column(
            children: [
              ///this onPress code bellow is used to set the message information and pop it up to the user in their notifications.
              ///button not needed as it will only be used when a new chat is sent or when an admin sends to a specific phone which will be a list of tokens per device
              buildMunicipalityDropdown(),

              /// Warc select bar
              const SizedBox(
                height: 5,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                child: Column(children: [
                  SizedBox(
                    // width: 400,
                    height: 50,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: Center(
                        child: TextField(
                          controller: _searchSuburbController,

                          ///Input decoration here had to be manual because dropdown button uses suffix icon of the textfield
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
                            fillColor: Colors.white,
                            filled: true,
                            suffixIcon: DropdownButtonFormField<String>(
                              value: dropdownSuburbValue,
                              items: dropdownSuburbs
                                  .map<DropdownMenuItem<String>>(
                                      (String value) {
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
                              onChanged: (String? newValue) async {
                                if (context.mounted) {
                                  setState(() {
                                    dropdownSuburbValue = newValue!;
                                    _searchSuburbController.text =
                                        dropdownSuburbValue;

                                    // Fetch filtered properties and tokens based on the selected suburb
                                    getUsersTokenStream(
                                        selectedSuburb: dropdownSuburbValue);
                                    getUsersPropStream();
                                    print(
                                        "Filtering properties by suburb: $dropdownSuburbValue");
                                    print(
                                        "Number of properties after filtering: ${_allUserPropResults.length}"); // This is assumed to fetch properties for display
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
                ]),
              ),

              /// Search bar end

              const SizedBox(
                height: 5,
              ),

              BasicIconButtonGrey(
                onPress: () async {
                  _notifySuburbUsers();
                },
                labelText: 'Notify Selected Suburb',
                fSize: 16,
                faIcon: const FaIcon(
                  Icons.notifications,
                ),
                fgColor: Colors.red,
                btSize: const Size(300, 50),
              ),

              const SizedBox(
                height: 5,
              ),

              ///made the listview card a reusable widget
              Expanded(
                child: userSuburbCard(),
              ),
            ],
          ),
          //Tab for streets
          Column(
            children: [
              buildMunicipalityDropdown(),

              /// Warc select bar
              const SizedBox(
                height: 5,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                child: Column(children: [
                  SizedBox(
                    // width: 400,
                    height: 50,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: Center(
                        child: TextField(
                          controller: _searchStreetController,

                          ///Input decoration here had to be manual because dropdown button uses suffix icon of the textfield
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
                            fillColor: Colors.white,
                            filled: true,
                            suffixIcon: DropdownButtonFormField<String>(
                              value: dropdownStreetValue,
                              items: dropdownStreets
                                  .map<DropdownMenuItem<String>>(
                                      (String value) {
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
                              onChanged: (String? newValue) async {
                                if (context.mounted) {
                                  setState(() {
                                    dropdownStreetValue = newValue!;
                                    _searchStreetController.text =
                                        dropdownStreetValue;

                                    // Fetch filtered properties and tokens based on the selected suburb
                                    getUsersTokenStream(
                                        selectedSuburb: dropdownStreetValue);
                                    getUsersPropStream();
                                    print(
                                        "Filtering properties by suburb: $dropdownStreetValue");
                                    print(
                                        "Number of properties after filtering: ${_allUserPropResults.length}"); // This is assumed to fetch properties for display
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
                ]),
              ),

              /// Search bar end

              const SizedBox(
                height: 5,
              ),

              BasicIconButtonGrey(
                onPress: () async {
                  _notifyStreetUsers();
                },
                labelText: 'Notify Selected Street',
                fSize: 16,
                faIcon: const FaIcon(
                  Icons.notifications,
                ),
                fgColor: Colors.red,
                btSize: const Size(300, 50),
              ),

              const SizedBox(
                height: 5,
              ),

              ///made the listview card a reusable widget
              Expanded(
                child: userStreetCard(),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  Widget tokenItemField(
      String tokenData,
      String userNameProp,
      String userAddress,
      String userPhoneProp,
      String userValidity,
      String userWardProp) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'User: $userNameProp',
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
                  'Phone: $tokenData',
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
                  'Register status: $userValidity',
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
        ],
      ),
    );
  }

  Widget tokenItemWardField(
      String tokenData,
      String userNameProp,
      String userAddress,
      String userPhoneProp,
      String userNumber,
      String userWardProp) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'User: $userNameProp',
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
                  'Phone: $tokenData',
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
                  'Ward: $userWardProp',
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

  //this widget is for displaying users phone numbers with the hidden stored device token
  Widget userCard() {
    if (_allPropResults.isNotEmpty) {

      return  GestureDetector(
        onTap: () {
          // Refocus when tapping within the tab content
          notifyAll.requestFocus();
        },
        child: KeyboardListener(
          focusNode: notifyAll,
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent) {
              final double pageScrollAmount =
                  _notifyAllScroller.position.viewportDimension;

              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                _notifyAllScroller.animateTo(
                  _notifyAllScroller.offset + 50,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                _notifyAllScroller.animateTo(
                  _notifyAllScroller.offset - 50,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
                _notifyAllScroller.animateTo(
                  _notifyAllScroller.offset + pageScrollAmount,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
                _notifyAllScroller.animateTo(
                  _notifyAllScroller.offset - pageScrollAmount,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                );
              }
            }
          },
          child: Scrollbar(
            controller: _notifyAllScroller,
            thickness: 12, // Customize the thickness of the scrollbar
            radius: const Radius.circular(8), // Rounded edges for the scrollbar
            thumbVisibility: true,
            trackVisibility: true, // Makes the track visible as well
            interactive: true,
            child: ListView.builder(
                controller: _notifyAllScroller,
                itemCount: _allPropResults.length,
                itemBuilder: (context, index) {
                  String accountNumber = _allPropResults[index]['accountNumber'];
                  userNameProp =
                      '${_allPropResults[index]['firstName']} ${_allPropResults[index]['lastName']}';
                  userAddress = _allPropResults[index]['address'];
                  userWardProp = _allPropResults[index]['ward'];
                  userPhoneNumber = _allPropResults[index]['cellNumber'];

                  String? token = _allPropResults[index]['token'];
                  if (token != null && token.isNotEmpty) {
                    userPhoneToken = token;
                    notifyToken = token;
                    userValid = 'User will receive notification';
                  } else {
                    userPhoneToken = '';
                    notifyToken = '';
                    userValid = 'User is not yet registered';
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
                            child: Text(
                              'Users Device Details',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          tokenItemField(userPhoneNumber, userNameProp, userAddress,
                              userPhoneNumber, userValid, userWardProp),
                          Visibility(
                            visible: false,
                            child: Text(
                              'User Token: $userPhoneToken',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(10.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget userTokenSearchCard() {
    print('User Properties Results: ${_allUserPropResults.length}');
    if (_allUserPropResults.isNotEmpty) {

      return GestureDetector(
        onTap: () {
          // Refocus when tapping within the tab content
          notifyTarget.requestFocus();
        },
        child: KeyboardListener(
          focusNode: notifyTarget,
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent) {
              final double pageScrollAmount =
                  _notifyTargetScroller.position.viewportDimension;

              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                _notifyTargetScroller.animateTo(
                  _notifyTargetScroller.offset + 50,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                _notifyTargetScroller.animateTo(
                  _notifyTargetScroller.offset - 50,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
                _notifyTargetScroller.animateTo(
                  _notifyTargetScroller.offset + pageScrollAmount,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
                _notifyTargetScroller.animateTo(
                  _notifyTargetScroller.offset - pageScrollAmount,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                );
              }
            }
          },
          child: Scrollbar(
            controller: _notifyTargetScroller,
            thickness: 12, // Customize the thickness of the scrollbar
            radius: const Radius.circular(8), // Rounded edges for the scrollbar
            thumbVisibility: true,
            trackVisibility: true, // Makes the track visible as well
            interactive: true,
            child: ListView.builder(
              controller: _notifyTargetScroller,
              itemCount: _allUserPropResults.length,
              itemBuilder: (context, index) {
                // Set user details from property results
                String accountNumber = _allPropResults[index]['accountNumber'];
                userNameProp =
                    '${_allUserPropResults[index]['firstName']} ${_allUserPropResults[index]['lastName']}';
                userAddress = _allUserPropResults[index]['address'];
                userWardProp = _allUserPropResults[index]['ward'];
                userPhoneNumber = _allUserPropResults[index]['cellNumber'];
                print('User $index: $userNameProp, Phone: $userPhoneNumber');
                // Ensure token is fetched for the corresponding property
                String? token = _allPropResults[index]['token'];
                if (token != null && token.isNotEmpty) {
                  userPhoneToken = token;
                  notifyToken = token;
                  userValid = 'User will receive notification';
                } else {
                  userPhoneToken = '';
                  notifyToken = '';
                  userValid = 'User is not yet registered';
                }

                // Check if the user matches the search query
                String searchText = _searchController.text.toLowerCase();
                bool matchesPhone = userPhoneNumber.contains(searchText);
                bool matchesName = userNameProp.toLowerCase().contains(searchText);
                bool matchesAddress = userAddress.toLowerCase().contains(searchText);
                // If there's no search query or if the user matches the search query, display the card
                if (_searchController.text.isEmpty ||
                    matchesPhone ||
                    matchesName ||
                    matchesAddress) {
                  return Card(
                    margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'Users Details',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 10),
                          tokenItemField(userPhoneNumber, userNameProp, userAddress,
                              userPhoneNumber, userValid, userWardProp),
                          Visibility(
                            visible: false,
                            child: Text(
                              'User Token: $notifyToken',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  BasicIconButtonGrey(
                                    onPress: () async {
                                      showDialog(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              shape: const RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.all(
                                                      Radius.circular(16))),
                                              title: const Text("Call User!"),
                                              content: const Text(
                                                  "Would you like to call the user directly?"),
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
                                                    String cellGiven =
                                                        userPhoneNumber;

                                                    final Uri _tel = Uri.parse(
                                                        'tel:${cellGiven.toString()}');
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
                                    labelText: 'Call User',
                                    fSize: 14,
                                    faIcon: const FaIcon(
                                      Icons.call,
                                    ),
                                    fgColor: Colors.green,
                                    btSize: const Size(100, 38),
                                  ),
                                  const SizedBox(
                                      width: 10), // Add spacing between buttons
                                  BasicIconButtonGrey(
                                    onPress: () async {
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
                                        print(
                                            "Error: Municipality context is empty.");
                                        Fluttertoast.showToast(
                                          msg:
                                              "Invalid municipality selection or missing municipality.",
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.CENTER,
                                        );
                                        return;
                                      }
                                      // Get the account number for the selected property
                                      String accountNumber =
                                          _allUserPropResults[index]['accountNumber'];

                                      // Fetch all tokens like in notifyAllUsers
                                      await getUsersTokenStream();

                                      // Look for the token for the specific account number
                                      for (int i = 0; i < usersTokens.length; i++) {
                                        if (usersNumbers[i] == accountNumber) {
                                          notifyToken = usersTokens[i];
                                          break;
                                        }
                                      }

                                      // Proceed to notify the user
                                      userPhoneNumber =
                                          _allUserPropResults[index]['cellNumber'];
                                      _notifyThisUser(_allUserPropResults[index]);
                                    },
                                    labelText: 'Notify',
                                    fSize: 14,
                                    faIcon: const FaIcon(Icons.edit),
                                    fgColor: Colors.blueAccent,
                                    btSize: const Size(100, 38),
                                  ),
                                  const SizedBox(
                                      width: 10), // Add spacing between buttons
                                  BasicIconButtonGrey(
                                    onPress: () async {
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
                                        print(
                                            "Error: Municipality context is empty.");
                                        Fluttertoast.showToast(
                                          msg:
                                              "Invalid municipality selection or missing municipality.",
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.CENTER,
                                        );
                                        return;
                                      }
                                      // Get the account number for the selected property
                                      String accountNumber =
                                          _allUserPropResults[index]['accountNumber'];

                                      // Fetch all tokens like in notifyAllUsers
                                      await getUsersTokenStream();

                                      // Look for the token for the specific account number
                                      for (int i = 0; i < usersTokens.length; i++) {
                                        if (usersNumbers[i] == accountNumber) {
                                          notifyToken = usersTokens[i];
                                          break;
                                        }
                                      }

                                      // Proceed to notify the user
                                      userPhoneNumber =
                                          _allUserPropResults[index]['cellNumber'];
                                      _disconnectThisUser(_allUserPropResults[index]);
                                    },
                                    labelText: 'Disconnect',
                                    fSize: 14,
                                    faIcon: const FaIcon(
                                      Icons.warning_amber,
                                    ),
                                    fgColor: Colors.amber,
                                    btSize: const Size(100, 38),
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
        ),
      );
    }
    print('No user properties available.');
    return const Padding(
      padding: EdgeInsets.all(10.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget userWardCard() {
    if (_allUserPropResults.isNotEmpty) {

      return GestureDetector(
        onTap: () {
          // Refocus when tapping within the tab content
          notifyWard.requestFocus();
        },
        child: KeyboardListener(
          focusNode: notifyWard,
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent) {
              final double pageScrollAmount =
                  _notifyWardScroller.position.viewportDimension;

              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                _notifyWardScroller.animateTo(
                  _notifyWardScroller.offset + 50,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                _notifyWardScroller.animateTo(
                  _notifyWardScroller.offset - 50,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
                _notifyWardScroller.animateTo(
                  _notifyWardScroller.offset + pageScrollAmount,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
                _notifyWardScroller.animateTo(
                  _notifyWardScroller.offset - pageScrollAmount,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                );
              }
            }
          },
          child: Scrollbar(
            controller: _notifyWardScroller,
            thickness: 12, // Customize the thickness of the scrollbar
            radius: const Radius.circular(8), // Rounded edges for the scrollbar
            thumbVisibility: true,
            trackVisibility: true, // Makes the track visible as well
            interactive: true,
            child: ListView.builder(
              controller: _notifyWardScroller,
              itemCount: _allUserPropResults.length,
              itemBuilder: (context, index) {
                var property = _allUserPropResults[index].data();

                // Ward filtering logic
                if (property['cellNumber'].contains('+27') &&
                    (property['ward'].toString() == dropdownValue.toString() ||
                        dropdownValue == 'Select Ward')) {
                  // Set variables for display
                  userNameProp = '${property['firstName']} ${property['lastName']}';
                  userAddress = property['address'];
                  userWardProp = property['ward'];
                  userPhoneNumber = property['cellNumber'];

                  // Return the card for the property
                  return Card(
                    margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'Users Device Details',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Display user details
                          tokenItemField(userPhoneNumber, userNameProp, userAddress,
                              userPhoneNumber, userValid, userWardProp),
                          const SizedBox(height: 15), // Add some space before buttons

                          // Interaction buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              BasicIconButtonGrey(
                                onPress: () async {
                                  showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(16))),
                                          title: const Text("Call User!"),
                                          content: const Text(
                                              "Would you like to call the user directly?"),
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
                                                String cellGiven = userPhoneNumber;

                                                final Uri _tel = Uri.parse(
                                                    'tel:${cellGiven.toString()}');
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
                                labelText: 'Call User',
                                fSize: 14,
                                faIcon: const FaIcon(
                                  Icons.call,
                                ),
                                fgColor: Colors.green,
                                btSize: const Size(100, 38),
                              ),
                              const SizedBox(
                                  width: 10), // Add spacing between buttons
                              BasicIconButtonGrey(
                                onPress: () async {
                                  if (!isLocalUser && !isLocalMunicipality) {
                                    if (selectedMunicipality == null ||
                                        selectedMunicipality ==
                                            "Select Municipality") {
                                      Fluttertoast.showToast(
                                        msg: "Please select a municipality first!",
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
                                    print("Error: Municipality context is empty.");
                                    Fluttertoast.showToast(
                                      msg:
                                          "Invalid municipality selection or missing municipality.",
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.CENTER,
                                    );
                                    return;
                                  }
                                  // Get the account number for the selected property
                                  String accountNumber =
                                      _allUserPropResults[index]['accountNumber'];

                                  // Fetch all tokens like in notifyAllUsers
                                  await getUsersTokenStream();

                                  // Look for the token for the specific account number
                                  for (int i = 0; i < usersTokens.length; i++) {
                                    if (usersNumbers[i] == accountNumber) {
                                      notifyToken = usersTokens[i];
                                      break;
                                    }
                                  }

                                  // Proceed to notify the user
                                  userPhoneNumber =
                                      _allUserPropResults[index]['cellNumber'];
                                  _notifyThisUser(_allUserPropResults[index]);
                                },
                                labelText: 'Notify',
                                fSize: 14,
                                faIcon: const FaIcon(Icons.edit),
                                fgColor: Colors.blueAccent,
                                btSize: const Size(100, 38),
                              ),
                              const SizedBox(
                                  width: 10), // Add spacing between buttons
                              BasicIconButtonGrey(
                                onPress: () async {
                                  if (!isLocalUser && !isLocalMunicipality) {
                                    if (selectedMunicipality == null ||
                                        selectedMunicipality ==
                                            "Select Municipality") {
                                      Fluttertoast.showToast(
                                        msg: "Please select a municipality first!",
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
                                    print("Error: Municipality context is empty.");
                                    Fluttertoast.showToast(
                                      msg:
                                          "Invalid municipality selection or missing municipality.",
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.CENTER,
                                    );
                                    return;
                                  }
                                  // Get the account number for the selected property
                                  String accountNumber =
                                      _allUserPropResults[index]['accountNumber'];

                                  // Fetch all tokens like in notifyAllUsers
                                  await getUsersTokenStream();

                                  // Look for the token for the specific account number
                                  for (int i = 0; i < usersTokens.length; i++) {
                                    if (usersNumbers[i] == accountNumber) {
                                      notifyToken = usersTokens[i];
                                      break;
                                    }
                                  }

                                  // Proceed to notify the user
                                  userPhoneNumber =
                                      _allUserPropResults[index]['cellNumber'];
                                  _disconnectThisUser(_allUserPropResults[index]);
                                },
                                labelText: 'Disconnect',
                                fSize: 14,
                                faIcon: const FaIcon(
                                  Icons.warning_amber,
                                ),
                                fgColor: Colors.amber,
                                btSize: const Size(100, 38),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return const SizedBox(); // Return an empty widget if ward doesn't match
                }
              },
            ),
          ),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Future<void> _notifySuburbUsers([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      username.text = documentSnapshot.id;
      title.text = documentSnapshot['title'];
      body.text = documentSnapshot['body'];
      _headerController.text = documentSnapshot['title'];
      _messageController.text = documentSnapshot['body'];
    }

    // Fetch tokens and user account numbers for the selected suburb
    await getUsersTokenStream(
        selectedSuburb:
            dropdownSuburbValue); // Adjust this method if needed to filter by suburb

    // Ensure we have tokens and numbers
    if (usersTokens.isEmpty || usersNumbers.isEmpty) {
      print('Error: No users tokens or numbers found for the selected suburb.');
      return;
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
                  'Notify Users in Selected Suburb',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoading)
                          const Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 20),
                              Text(
                                'Sending notifications, please wait...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        else ...[
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
                      ],
                    ),
                  ),
                ),
                actions: [
                  if (!_isLoading)
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
                        setState(() {
                          _isLoading = true;
                        });

                        DateTime now = DateTime.now();
                        String formattedDate =
                            DateFormat('yyyy-MM-dd – kk:mm').format(now);

                        print('Users Tokens: $usersTokens');
                        print('Users Numbers: $usersNumbers');

                        for (int i = 0; i < usersTokens.length; i++) {
                          final String tokenSelected = usersTokens[i];
                          final String userNumber = usersNumbers[i];
                          final String notificationTitle = title.text;
                          final String notificationBody = body.text;

                          print(
                              "Attempting to add notification for user: $userNumber");

                          if (notificationTitle.isNotEmpty &&
                              notificationBody.isNotEmpty) {
                            try {
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

                              print(
                                  'Adding notification to path: ${notificationsRef.path}');

                              await notificationsRef.add({
                                "token": tokenSelected,
                                "user": userNumber,
                                "title": notificationTitle,
                                "body": notificationBody,
                                "read": false,
                                "date": formattedDate,
                                "level": 'general',
                              });

                              print(
                                  'Notification successfully added for user: $userNumber');
                            } catch (error) {
                              print('Error adding notification: $error');
                              Fluttertoast.showToast(
                                msg:
                                    'Error adding notification for $userNumber',
                                gravity: ToastGravity.CENTER,
                              );
                            }

                            // Send push message
                            sendPushMessage(tokenSelected, notificationTitle,
                                notificationBody);
                            print('Notification sent to user: $userNumber');
                          } else {
                            Fluttertoast.showToast(
                              msg:
                                  'Please Fill Header and Message of the notification!',
                              gravity: ToastGravity.CENTER,
                            );
                          }
                        }

                        setState(() {
                          _isLoading = false;
                        });

                        // Clear input fields after sending
                        title.clear();
                        body.clear();
                        if (ctx.mounted)
                          Navigator.of(ctx).pop(); // Close the dialog
                      },
                    ),
                  if (!_isLoading)
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
                        Navigator.of(ctx).pop(); // Close the dialog
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

  Future<void> _notifyStreetUsers([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      username.text = documentSnapshot.id;
      title.text = documentSnapshot['title'];
      body.text = documentSnapshot['body'];
      _headerController.text = documentSnapshot['title'];
      _messageController.text = documentSnapshot['body'];
    }

    // Fetch tokens and user account numbers for the selected suburb
    await getUsersTokenStream(
        selectedStreet:
            dropdownStreetValue); // Adjust this method if needed to filter by suburb

    // Ensure we have tokens and numbers
    if (usersTokens.isEmpty || usersNumbers.isEmpty) {
      print('Error: No users tokens or numbers found for the selected suburb.');
      return;
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
                  'Notify Users in Selected Street',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoading)
                          const Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 20),
                              Text(
                                'Sending notifications, please wait...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        else ...[
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
                      ],
                    ),
                  ),
                ),
                actions: [
                  if (!_isLoading)
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
                        setState(() {
                          _isLoading = true;
                        });

                        DateTime now = DateTime.now();
                        String formattedDate =
                            DateFormat('yyyy-MM-dd – kk:mm').format(now);

                        print('Users Tokens: $usersTokens');
                        print('Users Numbers: $usersNumbers');

                        for (int i = 0; i < usersTokens.length; i++) {
                          final String tokenSelected = usersTokens[i];
                          final String userNumber = usersNumbers[i];
                          final String notificationTitle = title.text;
                          final String notificationBody = body.text;

                          print(
                              "Attempting to add notification for user: $userNumber");

                          if (notificationTitle.isNotEmpty &&
                              notificationBody.isNotEmpty) {
                            try {
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

                              print(
                                  'Adding notification to path: ${notificationsRef.path}');

                              await notificationsRef.add({
                                "token": tokenSelected,
                                "user": userNumber,
                                "title": notificationTitle,
                                "body": notificationBody,
                                "read": false,
                                "date": formattedDate,
                                "level": 'general',
                              });

                              print(
                                  'Notification successfully added for user: $userNumber');
                            } catch (error) {
                              print('Error adding notification: $error');
                              Fluttertoast.showToast(
                                msg:
                                    'Error adding notification for $userNumber',
                                gravity: ToastGravity.CENTER,
                              );
                            }

                            // Send push message
                            sendPushMessage(tokenSelected, notificationTitle,
                                notificationBody);
                            print('Notification sent to user: $userNumber');
                          } else {
                            Fluttertoast.showToast(
                              msg:
                                  'Please Fill Header and Message of the notification!',
                              gravity: ToastGravity.CENTER,
                            );
                          }
                        }

                        setState(() {
                          _isLoading = false;
                        });

                        // Clear input fields after sending
                        title.clear();
                        body.clear();
                        if (ctx.mounted)
                          Navigator.of(ctx).pop(); // Close the dialog
                      },
                    ),
                  if (!_isLoading)
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
                        Navigator.of(ctx).pop(); // Close the dialog
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

  // Widget userSuburbCard() {
  //   // Check if the list is not empty
  //   if (_allUserSuburbResults.isNotEmpty) {
  //     // Debugging: Log the length of the list to verify it has data
  //     print('Suburb results length: ${_allUserSuburbResults.length}');
  //
  //     return ListView.builder(
  //       itemCount: _allUserSuburbResults.length,
  //       itemBuilder: (context, index) {
  //         // Debugging: Log each user's details to verify
  //         print('User Suburb Details: ${_allUserSuburbResults[index]}');
  //
  //         // Set variables for display
  //         userNameProp =
  //         '${_allUserSuburbResults[index]['firstName']} ${_allUserSuburbResults[index]['lastName']}';
  //         userAddress = _allUserSuburbResults[index]['address'];
  //         userWardProp = _allUserSuburbResults[index]['ward'];
  //         userPhoneNumber = _allUserSuburbResults[index]['cellNumber'];
  //
  //         // Find the corresponding token
  //         // for (var tokenSnapshot in _allUserTokenResults) {
  //         //   if (tokenSnapshot.id == _allUserSuburbResults[index]['cellNumber']) {
  //         //     notifyToken = tokenSnapshot['token'];
  //         //     userValid = 'User will receive notification';
  //         //     break;
  //         //   } else {
  //         //     notifyToken = '';
  //         //     userValid = 'User is not yet registered';
  //         //   }
  //         // }
  //
  //         // Check phone number and suburb filter
  //         if (_allUserSuburbResults[index]['cellNumber'].contains('+27') &&
  //             (_allUserSuburbResults[index]['address'].toLowerCase().contains(
  //                 dropdownSuburbValue.toString().toLowerCase()) ||
  //                 dropdownSuburbValue == 'Select Suburb')) {
  //           // Return the card widget
  //           return Card(
  //             margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
  //             child: Padding(
  //               padding: const EdgeInsets.all(20.0),
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   const Center(
  //                     child: Text(
  //                       'Users Device Details',
  //                       style: TextStyle(
  //                           fontSize: 18, fontWeight: FontWeight.w700),
  //                     ),
  //                   ),
  //                   const SizedBox(
  //                     height: 10,
  //                   ),
  //                   // Show user details
  //                   tokenItemField(userPhoneNumber, userNameProp, userAddress,
  //                       userPhoneNumber, userValid, userWardProp),
  //                   // Invisible token information
  //                   Visibility(
  //                     visible: false,
  //                     child: Text(
  //                       'User Token: $notifyToken',
  //                       style: const TextStyle(
  //                           fontSize: 16, fontWeight: FontWeight.w400),
  //                     ),
  //                   ),
  //                   const SizedBox(
  //                     height: 10,
  //                   ),
  //                   // Action buttons
  //                   Column(
  //                     children: [
  //                       Row(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         crossAxisAlignment: CrossAxisAlignment.center,
  //                         children: [
  //                           BasicIconButtonGrey(
  //                             onPress: () async {
  //                               showDialog(
  //                                   barrierDismissible: false,
  //                                   context: context,
  //                                   builder: (context) {
  //                                     return AlertDialog(
  //                                       shape: const RoundedRectangleBorder(
  //                                           borderRadius: BorderRadius.all(
  //                                               Radius.circular(16))),
  //                                       title: const Text("Call User!"),
  //                                       content: const Text(
  //                                           "Would you like to call the user directly?"),
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
  //                                             String cellGiven = userPhoneNumber;
  //
  //                                             final Uri _tel = Uri.parse(
  //                                                 'tel:${cellGiven.toString()}');
  //                                             launchUrl(_tel);
  //
  //                                             Navigator.of(context).pop();
  //                                           },
  //                                           icon: const Icon(
  //                                             Icons.done,
  //                                             color: Colors.green,
  //                                           ),
  //                                         ),
  //                                       ],
  //                                     );
  //                                   });
  //                             },
  //                             labelText: 'Call User',
  //                             fSize: 14,
  //                             faIcon: const FaIcon(
  //                               Icons.call,
  //                             ),
  //                             fgColor: Colors.green,
  //                             btSize: const Size(50, 38),
  //                           ),
  //                           BasicIconButtonGrey(
  //                             onPress: () async {
  //                               // Notify user directly
  //                               userPhoneNumber = _allUserPropResults[index]['cellNumber'];
  //                               _notifyThisUser(_allUserPropResults[index]);
  //                             },
  //                             labelText: 'Notify',
  //                             fSize: 14,
  //                             faIcon: const FaIcon(Icons.edit),
  //                             fgColor: Theme.of(context).primaryColor,
  //                             btSize: const Size(50, 38),
  //                           ),
  //                         ],
  //                       ),
  //                       const SizedBox(
  //                         height: 5,
  //                       ),
  //                       BasicIconButtonGrey(
  //                         onPress: () async {
  //                           // Disconnect user
  //                           userPhoneNumber = _allUserPropResults[index]['cellNumber'];
  //                           await _disconnectThisUser(_allUserTokenResults[index]);
  //                         },
  //                         labelText: 'Disconnect',
  //                         fSize: 14,
  //                         faIcon: const FaIcon(
  //                           Icons.warning_amber,
  //                         ),
  //                         fgColor: Colors.amber,
  //                         btSize: const Size(50, 38),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           );
  //         } else {
  //           // Return an empty space if no match
  //           return const SizedBox();
  //         }
  //       },
  //     );
  //   }
  //
  //   // Show a loader if the list is still empty
  //   return const Padding(
  //     padding: EdgeInsets.all(10.0),
  //     child: Center(child: CircularProgressIndicator()),
  //   );
  // }
  Widget userSuburbCard() {
    if (_allUserPropResults.isNotEmpty) {

      return KeyboardListener(
        focusNode: notifySuburb,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            final double pageScrollAmount =
                _notifySuburbScroller.position.viewportDimension;

            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _notifySuburbScroller.animateTo(
                _notifySuburbScroller.offset + 50,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeIn,
              );
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _notifySuburbScroller.animateTo(
                _notifySuburbScroller.offset - 50,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeIn,
              );
            } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
              _notifySuburbScroller.animateTo(
                _notifySuburbScroller.offset + pageScrollAmount,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeIn,
              );
            } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
              _notifySuburbScroller.animateTo(
                _notifySuburbScroller.offset - pageScrollAmount,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeIn,
              );
            }
          }
        },
        child: Scrollbar(
          controller: _notifySuburbScroller,
          thickness: 12, // Customize the thickness of the scrollbar
          radius: const Radius.circular(8), // Rounded edges for the scrollbar
          thumbVisibility: true,
          trackVisibility: true, // Makes the track visible as well
          interactive: true,
          child: ListView.builder(
            controller: _notifySuburbScroller,
            itemCount: _allUserPropResults.length,
            itemBuilder: (context, index) {
              var property = _allUserPropResults[index].data();

              // Suburb filtering logic
              if (property['cellNumber'].contains('+27') &&
                  (property['address']
                          .toLowerCase()
                          .contains(dropdownSuburbValue.toLowerCase()) ||
                      dropdownSuburbValue == 'Select Suburb')) {
                // Set variables for display
                userNameProp = '${property['firstName']} ${property['lastName']}';
                userAddress = property['address'];
                userWardProp = property['ward'];
                userPhoneNumber = property['cellNumber'];

                // Return the card for the property
                return Card(
                  margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Users Device Details',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Display user details
                        tokenItemField(userPhoneNumber, userNameProp, userAddress,
                            userPhoneNumber, userValid, userWardProp),

                        const SizedBox(height: 15), // Add some space before buttons

                        // Interaction buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            BasicIconButtonGrey(
                              onPress: () async {
                                showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(16))),
                                        title: const Text("Call User!"),
                                        content: const Text(
                                            "Would you like to call the user directly?"),
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
                                              String cellGiven = userPhoneNumber;

                                              final Uri _tel = Uri.parse(
                                                  'tel:${cellGiven.toString()}');
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
                              labelText: 'Call User',
                              fSize: 14,
                              faIcon: const FaIcon(
                                Icons.call,
                              ),
                              fgColor: Colors.green,
                              btSize: const Size(100, 38),
                            ),
                            const SizedBox(
                                width: 10), // Add spacing between buttons
                            BasicIconButtonGrey(
                              onPress: () async {
                                if (!isLocalUser && !isLocalMunicipality) {
                                  if (selectedMunicipality == null ||
                                      selectedMunicipality ==
                                          "Select Municipality") {
                                    Fluttertoast.showToast(
                                      msg: "Please select a municipality first!",
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
                                  print("Error: Municipality context is empty.");
                                  Fluttertoast.showToast(
                                    msg:
                                        "Invalid municipality selection or missing municipality.",
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.CENTER,
                                  );
                                  return;
                                }
                                // Get the account number for the selected property
                                String accountNumber =
                                    _allUserPropResults[index]['accountNumber'];

                                // Fetch all tokens like in notifyAllUsers
                                await getUsersTokenStream();

                                // Look for the token for the specific account number
                                for (int i = 0; i < usersTokens.length; i++) {
                                  if (usersNumbers[i] == accountNumber) {
                                    notifyToken = usersTokens[i];
                                    break;
                                  }
                                }

                                // Proceed to notify the user
                                userPhoneNumber =
                                    _allUserPropResults[index]['cellNumber'];
                                _notifyThisUser(_allUserPropResults[index]);
                              },
                              labelText: 'Notify',
                              fSize: 14,
                              faIcon: const FaIcon(Icons.edit),
                              fgColor: Colors.blueAccent,
                              btSize: const Size(100, 38),
                            ),
                            const SizedBox(
                                width: 10), // Add spacing between buttons
                            BasicIconButtonGrey(
                              onPress: () async {
                                if (!isLocalUser && !isLocalMunicipality) {
                                  if (selectedMunicipality == null ||
                                      selectedMunicipality ==
                                          "Select Municipality") {
                                    Fluttertoast.showToast(
                                      msg: "Please select a municipality first!",
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
                                  print("Error: Municipality context is empty.");
                                  Fluttertoast.showToast(
                                    msg:
                                        "Invalid municipality selection or missing municipality.",
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.CENTER,
                                  );
                                  return;
                                }
                                // Get the account number for the selected property
                                String accountNumber =
                                    _allUserPropResults[index]['accountNumber'];

                                // Fetch all tokens like in notifyAllUsers
                                await getUsersTokenStream();

                                // Look for the token for the specific account number
                                for (int i = 0; i < usersTokens.length; i++) {
                                  if (usersNumbers[i] == accountNumber) {
                                    notifyToken = usersTokens[i];
                                    break;
                                  }
                                }

                                // Proceed to notify the user
                                userPhoneNumber =
                                    _allUserPropResults[index]['cellNumber'];
                                _disconnectThisUser(_allUserPropResults[index]);
                              },
                              labelText: 'Disconnect',
                              fSize: 14,
                              faIcon: const FaIcon(
                                Icons.warning_amber,
                              ),
                              fgColor: Colors.amber,
                              btSize: const Size(100, 38),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return const SizedBox(); // Return an empty widget if suburb doesn't match
              }
            },
          ),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget userStreetCard() {
    if (_allUserPropResults.isNotEmpty) {

      return KeyboardListener(
        focusNode: notifyStreet,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            final double pageScrollAmount =
                _notifyStreetScroller.position.viewportDimension;

            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _notifyStreetScroller.animateTo(
                _notifyStreetScroller.offset + 50,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeIn,
              );
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _notifyStreetScroller.animateTo(
                _notifyStreetScroller.offset - 50,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeIn,
              );
            } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
              _notifyStreetScroller.animateTo(
                _notifyStreetScroller.offset + pageScrollAmount,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeIn,
              );
            } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
              _notifyStreetScroller.animateTo(
                _notifyStreetScroller.offset - pageScrollAmount,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeIn,
              );
            }
          }
        },
        child: Scrollbar(
          controller: _notifyStreetScroller,
          thickness: 12, // Customize the thickness of the scrollbar
          radius: const Radius.circular(8), // Rounded edges for the scrollbar
          thumbVisibility: true,
          trackVisibility: true, // Makes the track visible as well
          interactive: true,
          child: ListView.builder(
            controller: _notifyStreetScroller,
            itemCount: _allUserPropResults.length,
            itemBuilder: (context, index) {
              var property = _allUserPropResults[index].data();

              // Street filtering logic
              String streetName = dropdownStreetValue.toLowerCase();
              String propertyStreet =
                  property['address'].split(',')[0].toLowerCase();

              if (property['cellNumber'].contains('+27') &&
                  (propertyStreet.contains(streetName) ||
                      dropdownStreetValue == 'Select Street')) {
                // Set variables for display
                userNameProp = '${property['firstName']} ${property['lastName']}';
                userAddress = property['address'];
                userWardProp = property['ward'];
                userPhoneNumber = property['cellNumber'];

                // Return the card for the property
                return Card(
                  margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'User Device Details',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Display user details
                        tokenItemField(userPhoneNumber, userNameProp, userAddress,
                            userPhoneNumber, userValid, userWardProp),

                        const SizedBox(height: 15), // Add some space before buttons

                        // Interaction buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            BasicIconButtonGrey(
                              onPress: () async {
                                showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(16))),
                                        title: const Text("Call User!"),
                                        content: const Text(
                                            "Would you like to call the user directly?"),
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
                                              String cellGiven = userPhoneNumber;
                                              final Uri _tel = Uri.parse(
                                                  'tel:${cellGiven.toString()}');
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
                              labelText: 'Call User',
                              fSize: 14,
                              faIcon: const FaIcon(
                                Icons.call,
                              ),
                              fgColor: Colors.green,
                              btSize: const Size(100, 38),
                            ),
                            const SizedBox(
                                width: 10), // Add spacing between buttons
                            BasicIconButtonGrey(
                              onPress: () async {
                                // Notification logic for street
                                if (!isLocalUser && !isLocalMunicipality) {
                                  if (selectedMunicipality == null ||
                                      selectedMunicipality ==
                                          "Select Municipality") {
                                    Fluttertoast.showToast(
                                      msg: "Please select a municipality first!",
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
                                  print("Error: Municipality context is empty.");
                                  Fluttertoast.showToast(
                                    msg:
                                        "Invalid municipality selection or missing municipality.",
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.CENTER,
                                  );
                                  return;
                                }

                                // Get the account number for the selected property
                                String accountNumber =
                                    _allUserPropResults[index]['accountNumber'];

                                // Fetch all tokens like in notifyAllUsers
                                await getUsersTokenStream();

                                // Look for the token for the specific account number
                                for (int i = 0; i < usersTokens.length; i++) {
                                  if (usersNumbers[i] == accountNumber) {
                                    notifyToken = usersTokens[i];
                                    break;
                                  }
                                }

                                // Proceed to notify the user
                                userPhoneNumber =
                                    _allUserPropResults[index]['cellNumber'];
                                _notifyThisUser(_allUserPropResults[index]);
                              },
                              labelText: 'Notify',
                              fSize: 14,
                              faIcon: const FaIcon(Icons.edit),
                              fgColor: Colors.blueAccent,
                              btSize: const Size(100, 38),
                            ),
                            const SizedBox(
                                width: 10), // Add spacing between buttons
                            BasicIconButtonGrey(
                              onPress: () async {
                                // Disconnect logic for street
                                if (!isLocalUser && !isLocalMunicipality) {
                                  if (selectedMunicipality == null ||
                                      selectedMunicipality ==
                                          "Select Municipality") {
                                    Fluttertoast.showToast(
                                      msg: "Please select a municipality first!",
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
                                  print("Error: Municipality context is empty.");
                                  Fluttertoast.showToast(
                                    msg:
                                        "Invalid municipality selection or missing municipality.",
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.CENTER,
                                  );
                                  return;
                                }

                                // Get the account number for the selected property
                                String accountNumber =
                                    _allUserPropResults[index]['accountNumber'];

                                // Fetch all tokens like in notifyAllUsers
                                await getUsersTokenStream();

                                // Look for the token for the specific account number
                                for (int i = 0; i < usersTokens.length; i++) {
                                  if (usersNumbers[i] == accountNumber) {
                                    notifyToken = usersTokens[i];
                                    break;
                                  }
                                }

                                // Proceed to disconnect the user
                                userPhoneNumber =
                                    _allUserPropResults[index]['cellNumber'];
                                _disconnectThisUser(_allUserPropResults[index]);
                              },
                              labelText: 'Disconnect',
                              fSize: 14,
                              faIcon: const FaIcon(
                                Icons.warning_amber,
                              ),
                              fgColor: Colors.amber,
                              btSize: const Size(100, 38),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return const SizedBox(); // Return an empty widget if street doesn't match
              }
            },
          ),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  //This class is for updating the notification
  Future<void> _notifyUpdateUser([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      username.text = documentSnapshot.id;
      title.text = documentSnapshot['title'];
      body.text = documentSnapshot['body'];
      _noticeReadController = documentSnapshot['read'];
      _headerController.text = documentSnapshot['title'];
      _messageController.text = documentSnapshot['body'];
    }

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    void _createBottomSheet() async {
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
                                decoration:
                                    const InputDecoration(labelText: 'Message'),
                              ),
                            ),
                            Visibility(
                              visible: visShow,
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.only(
                                    left: 0.0, right: 25.0),
                                child: Row(
                                  children: <Widget>[
                                    const Text(
                                      'Notice Has Been Read',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400),
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Checkbox(
                                      checkColor: Colors.white,
                                      fillColor:
                                          MaterialStateProperty.all<Color>(
                                              Colors.green),
                                      value: _noticeReadController,
                                      onChanged: (bool? value) async {
                                        if (context.mounted) {
                                          setState(() {
                                            _noticeReadController = value!;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            ElevatedButton(
                                child: const Text('Send Notification'),
                                onPressed: () async {
                                  DateTime now = DateTime.now();
                                  String formattedDate =
                                      DateFormat('yyyy-MM-dd – kk:mm')
                                          .format(now);

                                  final String tokenSelected = notifyToken;
                                  final String? userNumber =
                                      documentSnapshot?.id;
                                  final String notificationTitle = title.text;
                                  final String notificationBody = body.text;
                                  final String notificationDate = formattedDate;
                                  final bool readStatus = _noticeReadController;

                                  if (title.text != '' ||
                                      title.text.isNotEmpty ||
                                      body.text != '' ||
                                      body.text.isNotEmpty) {
                                    await _listNotifications
                                        ?.doc(documentSnapshot?.id)
                                        .update({
                                      "token": tokenSelected,
                                      "user": userNumber,
                                      "title": notificationTitle,
                                      "body": notificationBody,
                                      "read": readStatus,
                                      "date": notificationDate,
                                    });

                                    ///It can be changed to the firebase notification
                                    String titleText = title.text;
                                    String bodyText = body.text;

                                    ///gets users phone token to send notification to this phone
                                    if (userNumber != "") {
                                      DocumentSnapshot snap =
                                          await FirebaseFirestore.instance
                                              .collection("UserToken")
                                              .doc(userNumber)
                                              .get();
                                      String token = snap['token'];
                                      sendPushMessage(
                                          token, titleText, bodyText);
                                    }
                                  } else {
                                    Fluttertoast.showToast(
                                        msg:
                                            'Please fill Header and Message of the Notification!',
                                        gravity: ToastGravity.CENTER);
                                  }

                                  username.text = '';
                                  title.text = '';
                                  body.text = '';
                                  _headerController.text = '';
                                  _messageController.text = '';
                                  _noticeReadController = false;

                                  if (context.mounted)
                                    Navigator.of(context).pop();
                                })
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

  Future<void> _notifyAllUser([DocumentSnapshot? documentSnapshot]) async {
    _searchBarController.text = '';

    if (documentSnapshot != null) {
      username.text = documentSnapshot.id;
      title.text = documentSnapshot['title'];
      body.text = documentSnapshot['body'];
      _headerController.text = documentSnapshot['title'];
      _messageController.text = documentSnapshot['body'];
    }

    // Check if the district user has selected a municipality
    if (!isLocalMunicipality &&
        (selectedMunicipality == null ||
            selectedMunicipality == "Select Municipality")) {
      Fluttertoast.showToast(
        msg: 'Please select a municipality before sending the notification.',
        gravity: ToastGravity.CENTER,
      );
      return;
    }

    // Use selected municipality as the municipalityId for district users
    if (!isLocalMunicipality) {
      municipalityId = selectedMunicipality!;
    }

    // Fetch tokens and user account numbers
    await getUsersTokenStream();

    // Ensure we have tokens and numbers
    if (usersTokens.isEmpty || usersNumbers.isEmpty) {
      print('Error: No users tokens or numbers found.');
      return;
    }

    void _showDialog() async {
      await showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return StatefulBuilder(
            builder: (context, StateSetter setState) {
              return AlertDialog(
                backgroundColor: Colors.grey[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                title: const Text(
                  'Notify Users',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoading)
                          const Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 10),
                              Text(
                                'Sending notifications, please wait...',
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          )
                        else ...[
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
                      ],
                    ),
                  ),
                ),
                actions: [
                  if (!_isLoading)
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
                        setState(() {
                          _isLoading = true;
                        });

                        DateTime now = DateTime.now();
                        String formattedDate =
                            DateFormat('yyyy-MM-dd – kk:mm').format(now);

                        print('Users Tokens: $usersTokens');
                        print('Users Numbers: $usersNumbers');

                        for (int i = 0; i < usersTokens.length; i++) {
                          final String tokenSelected = usersTokens[i];
                          final String userNumber = usersNumbers[i];
                          final String notificationTitle = title.text;
                          final String notificationBody = body.text;

                          print(
                              "Attempting to add notification for user: $userNumber");

                          if (notificationTitle.isNotEmpty &&
                              notificationBody.isNotEmpty) {
                            try {
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

                              print(
                                  'Adding notification to path: ${notificationsRef.path}');

                              await notificationsRef.add({
                                "token": tokenSelected,
                                "user": userNumber,
                                "title": notificationTitle,
                                "body": notificationBody,
                                "read": false,
                                "date": formattedDate,
                                "level": 'general',
                              });

                              print(
                                  'Notification successfully added for user: $userNumber');
                            } catch (error) {
                              print('Error adding notification: $error');
                              Fluttertoast.showToast(
                                msg:
                                    'Error adding notification for $userNumber',
                                gravity: ToastGravity.CENTER,
                              );
                            }

                            // Send push message
                            sendPushMessage(tokenSelected, notificationTitle,
                                notificationBody);
                            print('Notification sent to user: $userNumber');
                          } else {
                            Fluttertoast.showToast(
                              msg:
                                  'Please Fill Header and Message of the notification!',
                              gravity: ToastGravity.CENTER,
                            );
                          }
                        }

                        setState(() {
                          _isLoading = false;
                        });

                        // Clear input fields after sending
                        title.clear();
                        body.clear();
                        if (ctx.mounted)
                          Navigator.of(ctx).pop(); // Close the dialog
                      },
                    ),
                  if (!_isLoading)
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
                        Navigator.of(ctx).pop(); // Close the dialog
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

  Future<void> _notifyWardUsers([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      username.text = documentSnapshot.id;
      title.text = documentSnapshot['title'];
      body.text = documentSnapshot['body'];
      _headerController.text = documentSnapshot['title'];
      _messageController.text = documentSnapshot['body'];
    }

    // Fetch tokens and user account numbers
    await getUsersTokenStream(
        selectedWard: dropdownValue); // dropdownValue stores the selected ward

    // Ensure we have tokens and numbers
    if (usersTokens.isEmpty || usersNumbers.isEmpty) {
      print('Error: No users tokens or numbers found.');
      return;
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
                  'Notify Users in Selected Ward',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoading)
                          const Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 20),
                              Text(
                                'Sending notifications, please wait...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        else ...[
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
                      ],
                    ),
                  ),
                ),
                actions: [
                  if (!_isLoading)
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
                        setState(() {
                          _isLoading = true;
                        });

                        DateTime now = DateTime.now();
                        String formattedDate =
                            DateFormat('yyyy-MM-dd – kk:mm').format(now);

                        print('Users Tokens: $usersTokens');
                        print('Users Numbers: $usersNumbers');

                        for (int i = 0; i < usersTokens.length; i++) {
                          final String tokenSelected = usersTokens[i];
                          final String userNumber = usersNumbers[i];
                          final String notificationTitle = title.text;
                          final String notificationBody = body.text;

                          print(
                              "Attempting to add notification for user: $userNumber");

                          if (notificationTitle.isNotEmpty &&
                              notificationBody.isNotEmpty) {
                            try {
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

                              print(
                                  'Adding notification to path: ${notificationsRef.path}');

                              await notificationsRef.add({
                                "token": tokenSelected,
                                "user": userNumber,
                                "title": notificationTitle,
                                "body": notificationBody,
                                "read": false,
                                "date": formattedDate,
                                "level": 'general',
                              });

                              print(
                                  'Notification successfully added for user: $userNumber');
                            } catch (error) {
                              print('Error adding notification: $error');
                              Fluttertoast.showToast(
                                msg:
                                    'Error adding notification for $userNumber',
                                gravity: ToastGravity.CENTER,
                              );
                            }

                            // Send push message
                            sendPushMessage(tokenSelected, notificationTitle,
                                notificationBody);
                            print('Notification sent to user: $userNumber');
                          } else {
                            Fluttertoast.showToast(
                              msg:
                                  'Please Fill Header and Message of the notification!',
                              gravity: ToastGravity.CENTER,
                            );
                          }
                        }

                        setState(() {
                          _isLoading = false;
                        });

                        // Clear input fields after sending
                        title.clear();
                        body.clear();
                        if (ctx.mounted)
                          Navigator.of(ctx).pop(); // Close the dialog
                      },
                    ),
                  if (!_isLoading)
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
                        Navigator.of(ctx).pop(); // Close the dialog
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
  //   void _createBottomSheet() async {
  //     await showModalBottomSheet(
  //       isScrollControlled: true,
  //       context: context,
  //       builder: (BuildContext ctx) {
  //         return StatefulBuilder(
  //           builder: (BuildContext context, StateSetter setState) {
  //             return SingleChildScrollView(
  //               child: Padding(
  //                 padding: EdgeInsets.only(
  //                   top: 20,
  //                   left: 20,
  //                   right: 20,
  //                   bottom: MediaQuery
  //                       .of(ctx)
  //                       .viewInsets
  //                       .bottom + 20,
  //                 ),
  //                 child: Column(
  //                   mainAxisSize: MainAxisSize.min,
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     const Center(
  //                       child: Text(
  //                         'Notify Users in Selected Ward',
  //                         style: TextStyle(
  //                             fontSize: 16, fontWeight: FontWeight.w700),
  //                       ),
  //                     ),
  //                     TextField(
  //                       controller: title,
  //                       decoration: const InputDecoration(
  //                         labelText: 'Message Header',
  //                       ),
  //                     ),
  //                     TextField(
  //                       controller: body,
  //                       decoration: const InputDecoration(
  //                         labelText: 'Message',
  //                       ),
  //                     ),
  //                     const SizedBox(height: 10),
  //                     ElevatedButton(
  //                       child: const Text('Send Notification'),
  //                       onPressed: () async {
  //                         DateTime now = DateTime.now();
  //                         String formattedDate = DateFormat(
  //                             'yyyy-MM-dd – kk:mm').format(now);
  //
  //                         // Debugging tokens and users
  //                         print('Users Tokens: $usersTokens');
  //                         print('Users Numbers: $usersNumbers');
  //
  //                         for (int i = 0; i < usersTokens.length; i++) {
  //                           final String tokenSelected = usersTokens[i];
  //                           final String userNumber = usersNumbers[i];
  //                           final String notificationTitle = title.text;
  //                           final String notificationBody = body.text;
  //
  //                           print(
  //                               "Attempting to add notification for user: $userNumber");
  //
  //                           if (notificationTitle.isNotEmpty &&
  //                               notificationBody.isNotEmpty) {
  //                             try {
  //                               // Set the correct path for your notification
  //                               String districtId = 'uMgungundlovu'; // Replace with dynamic districtId if needed
  //                               String municipalityId = 'uMshwathi'; // Replace with dynamic municipalityId if needed
  //                               CollectionReference notificationsRef = FirebaseFirestore
  //                                   .instance
  //                                   .collection('districts')
  //                                   .doc(districtId)
  //                                   .collection('municipalities')
  //                                   .doc(municipalityId)
  //                                   .collection('Notifications');
  //
  //                               // Print the exact path where notifications are added
  //                               print(
  //                                   'Adding notification to path: ${notificationsRef
  //                                       .path}');
  //
  //                               await notificationsRef.add({
  //                                 "token": tokenSelected,
  //                                 "user": userNumber,
  //                                 "title": notificationTitle,
  //                                 "body": notificationBody,
  //                                 "read": false,
  //                                 "date": formattedDate,
  //                                 "level": 'general',
  //                               });
  //
  //                               print(
  //                                   'Notification successfully added for user: $userNumber');
  //                             } catch (error) {
  //                               print('Error adding notification: $error');
  //                               Fluttertoast.showToast(
  //                                 msg: 'Error adding notification for $userNumber',
  //                                 gravity: ToastGravity.CENTER,
  //                               );
  //                             }
  //
  //                             // Send push message
  //                             sendPushMessage(tokenSelected, notificationTitle,
  //                                 notificationBody);
  //                             print('Notification sent to user: $userNumber');
  //                           } else {
  //                             Fluttertoast.showToast(
  //                               msg: 'Please Fill Header and Message of the notification!',
  //                               gravity: ToastGravity.CENTER,
  //                             );
  //                           }
  //                         }
  //
  //                         // Clear input fields after sending
  //                         title.clear();
  //                         body.clear();
  //                         if (context.mounted) Navigator.of(context).pop();
  //                       },
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             );
  //           },
  //         );
  //       },
  //     );
  //   }
  //
  //   _createBottomSheet();
  // }

  Future<void> _notifyThisUser([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      // Ensure the username and notifyToken are properly initialized
      username.text = documentSnapshot.id;
      notifyToken = documentSnapshot['token']; // Ensure this field is correct

      title.text =
          ''; // These are initialized as empty but will be filled by the user
      body.text = '';
    }
    // Ensure that municipalityId and districtId are valid
    if ((isLocalMunicipality || isLocalUser) && municipalityId.isEmpty) {
      print("Error: municipalityId is empty.");
      Fluttertoast.showToast(
        msg: "Invalid municipality selection or missing municipality.",
        gravity: ToastGravity.CENTER,
      );
      return;
    }

    // For district users, ensure municipalityId is set from selectedMunicipality
    if (!isLocalMunicipality && !isLocalUser && municipalityId.isEmpty) {
      if (selectedMunicipality != null &&
          selectedMunicipality != "Select Municipality") {
        municipalityId = selectedMunicipality!;
        print("Municipality ID set from selectedMunicipality: $municipalityId");
      } else {
        print(
            "Error: municipalityId is still empty after attempting to set from selectedMunicipality.");
        Fluttertoast.showToast(
          msg: "Please select a municipality.",
          gravity: ToastGravity.CENTER,
        );
        return;
      }
    }

    print(
        'Municipality ID: $municipalityId, District ID: $districtId'); // Add print here for debugging
    //   void _createBottomSheet() async {
    //     await showModalBottomSheet(
    //       isScrollControlled: true,
    //       context: context,
    //       builder: (BuildContext ctx) {
    //         return StatefulBuilder(
    //           builder: (BuildContext context, StateSetter setState) {
    //             return SingleChildScrollView(
    //               child: Padding(
    //                 padding: EdgeInsets.only(
    //                   top: 20,
    //                   left: 20,
    //                   right: 20,
    //                   bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
    //                 ),
    //                 child: Column(
    //                   mainAxisSize: MainAxisSize.min,
    //                   crossAxisAlignment: CrossAxisAlignment.start,
    //                   children: [
    //                     const Center(
    //                       child: Text(
    //                         'Notify Selected User',
    //                         style: TextStyle(
    //                           fontSize: 16,
    //                           fontWeight: FontWeight.w700,
    //                         ),
    //                       ),
    //                     ),
    //                     const SizedBox(height: 10),
    //                     TextField(
    //                       controller: title,
    //                       decoration: const InputDecoration(
    //                         labelText: 'Message Header',
    //                       ),
    //                     ),
    //                     const SizedBox(height: 10),
    //                     TextField(
    //                       controller: body,
    //                       decoration: const InputDecoration(
    //                         labelText: 'Message',
    //                       ),
    //                     ),
    //                     const SizedBox(height: 20),
    //                     ElevatedButton(
    //                       child: const Text('Send Notification'),
    //                       onPressed: () async {
    //                         print('Title: ${title.text}');
    //                         print('Body: ${body.text}');
    //                         print('Token: $notifyToken');
    //
    //                         DateTime now = DateTime.now();
    //                         String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);
    //
    //                         final String tokenSelected = notifyToken;
    //                         final String userNumber = documentSnapshot?['accountNumber'];
    //                         final String notificationTitle = title.text;
    //                         final String notificationBody = body.text;
    //
    //                         if (notificationTitle.isNotEmpty &&
    //                             notificationBody.isNotEmpty &&
    //                             tokenSelected.isNotEmpty) {
    //                           print('Sending notification to user: $userNumber');
    //
    //                           // Save the notification to Firestore or database
    //                           await _listNotifications?.add({
    //                             "token": tokenSelected,
    //                             "user": userNumber,
    //                             "title": notificationTitle,
    //                             "body": notificationBody,
    //                             "read": false,
    //                             "date": formattedDate,
    //                             "level": 'general',
    //                           });
    //
    //                           // Send push notification
    //                           sendPushMessage(tokenSelected, notificationTitle, notificationBody);
    //
    //                           // Show success message
    //                           Fluttertoast.showToast(
    //                             msg: 'Notification sent to the user!',
    //                             gravity: ToastGravity.CENTER,
    //                           );
    //
    //                           // Clear the fields and close the modal
    //                           title.clear();
    //                           body.clear();
    //                           if (context.mounted) Navigator.of(context).pop();
    //                         } else {
    //                           // Handle error if fields are empty
    //                           Fluttertoast.showToast(
    //                             msg: 'Please fill in both the title and message!',
    //                             gravity: ToastGravity.CENTER,
    //                           );
    //                         }
    //                       },
    //                     ),
    //                   ],
    //                 ),
    //               ),
    //             );
    //           },
    //         );
    //       },
    //     );
    //   }
    //
    //   _createBottomSheet();
    // }
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
                  'Notify Selected User',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
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
                      print('Title: ${title.text}');
                      print('Body: ${body.text}');
                      print('Token: $notifyToken');

                      DateTime now = DateTime.now();
                      String formattedDate =
                          DateFormat('yyyy-MM-dd – kk:mm').format(now);

                      final String tokenSelected = notifyToken;
                      final String userNumber =
                          documentSnapshot?['accountNumber'];
                      final String notificationTitle = title.text;
                      final String notificationBody = body.text;

                      if (notificationTitle.isNotEmpty &&
                          notificationBody.isNotEmpty &&
                          tokenSelected.isNotEmpty) {
                        print('Sending notification to user: $userNumber');

                        CollectionReference? notificationsRef;

                        // Choose correct Firestore path depending on municipality type
                        if (isLocalMunicipality) {
                          if (municipalityId.isNotEmpty) {
                            notificationsRef = FirebaseFirestore.instance
                                .collection('localMunicipalities')
                                .doc(municipalityId)
                                .collection('Notifications');
                          }
                        } else if (!isLocalMunicipality && !isLocalUser) {
                          if (districtId.isNotEmpty &&
                              municipalityId.isNotEmpty) {
                            notificationsRef = FirebaseFirestore.instance
                                .collection('districts')
                                .doc(districtId)
                                .collection('municipalities')
                                .doc(municipalityId)
                                .collection('Notifications');
                          }
                        }

                        if (notificationsRef != null) {
                          // Save notification to Firestore
                          await notificationsRef.add({
                            "token": tokenSelected,
                            "user": userNumber,
                            "title": notificationTitle,
                            "body": notificationBody,
                            "read": false,
                            "date": formattedDate,
                            "level": 'general',
                          });

                          // Send push notification
                          sendPushMessage(tokenSelected, notificationTitle,
                              notificationBody);

                          // Show success message
                          Fluttertoast.showToast(
                            msg: 'Notification sent to the user!',
                            gravity: ToastGravity.CENTER,
                          );

                          // Clear the fields and close the dialog
                          title.clear();
                          body.clear();
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        } else {
                          Fluttertoast.showToast(
                            msg:
                                'Error: Unable to save the notification. Path not set.',
                            gravity: ToastGravity.CENTER,
                          );
                        }
                      } else {
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

  Future<void> _disconnectThisUser([DocumentSnapshot? documentSnapshot]) async {
    // Prepare the text fields based on the documentSnapshot
    if (documentSnapshot != null) {
      username.text = documentSnapshot.id; // Account number from the document
      title.text = 'Utilities Disconnection Warning';
      body.text =
          'Please complete payment of your utilities. Failing to do so will result in utilities on your property being cut off in 14 days!';
    }
    if ((isLocalMunicipality || isLocalUser) && municipalityId.isEmpty) {
      print("Error: municipalityId is empty.");
      Fluttertoast.showToast(
        msg: "Invalid municipality selection or missing municipality.",
        gravity: ToastGravity.CENTER,
      );
      return;
    }

    // For district users, ensure municipalityId is set from selectedMunicipality
    if (!isLocalMunicipality && !isLocalUser && municipalityId.isEmpty) {
      if (selectedMunicipality != null &&
          selectedMunicipality != "Select Municipality") {
        municipalityId = selectedMunicipality!;
        print("Municipality ID set from selectedMunicipality: $municipalityId");
      } else {
        print(
            "Error: municipalityId is still empty after attempting to set from selectedMunicipality.");
        Fluttertoast.showToast(
          msg: "Please select a municipality.",
          gravity: ToastGravity.CENTER,
        );
        return;
      }
    }

    print(
        'Municipality ID: $municipalityId, District ID: $districtId'); // Add print here for debugging
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
                  width: MediaQuery.of(context).size.width * 0.6,
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
                      String formattedDate =
                          DateFormat('yyyy-MM-dd – kk:mm').format(now);

                      final String tokenSelected =
                          notifyToken; // Token of the user
                      final String userNumber =
                          documentSnapshot?['accountNumber'] ??
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
                          msg:
                              'The user has been sent the disconnection notice!',
                          gravity: ToastGravity.CENTER,
                        );

                        // Clear the input fields
                        title.clear();
                        body.clear();
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop(); // Close the dialog
                        }
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
  //   void _createBottomSheet() async {
  //     await showModalBottomSheet(
  //       isScrollControlled: true,
  //       context: context,
  //       builder: (BuildContext ctx) {
  //         return StatefulBuilder(
  //           builder: (BuildContext context, StateSetter setState) {
  //             return SingleChildScrollView(
  //               child: Padding(
  //                 padding: EdgeInsets.only(
  //                   top: 20,
  //                   left: 20,
  //                   right: 20,
  //                   bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
  //                 ),
  //                 child: Column(
  //                   mainAxisSize: MainAxisSize.min,
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     const Center(
  //                       child: Text(
  //                         'Notify User of Utilities Disconnection',
  //                         style: TextStyle(
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.w700,
  //                         ),
  //                       ),
  //                     ),
  //                     // Message header and body inputs
  //                     TextField(
  //                       controller: title,
  //                       decoration: const InputDecoration(
  //                         labelText: 'Message Header',
  //                       ),
  //                     ),
  //                     TextField(
  //                       controller: body,
  //                       decoration: const InputDecoration(
  //                         labelText: 'Message',
  //                       ),
  //                     ),
  //                     const SizedBox(height: 10),
  //                     ElevatedButton(
  //                       child: const Text('Send Notification'),
  //                       onPressed: () async {
  //                         DateTime now = DateTime.now();
  //                         String formattedDate =
  //                         DateFormat('yyyy-MM-dd – kk:mm').format(now);
  //
  //                         final String tokenSelected = notifyToken; // Token of the user
  //                         final String userNumber = documentSnapshot?['accountNumber'] ?? 'Unknown'; // User's account number
  //                         final String notificationTitle = title.text;
  //                         final String notificationBody = body.text;
  //
  //                         // Validate that the title and body are not empty
  //                         if (notificationTitle.isNotEmpty &&
  //                             notificationBody.isNotEmpty &&
  //                             tokenSelected.isNotEmpty) {
  //                           // Add notification to Firestore
  //                           await FirebaseFirestore.instance
  //                               .collection('districts')
  //                               .doc('uMgungundlovu') // Replace with dynamic district ID
  //                               .collection('municipalities')
  //                               .doc('uMshwathi') // Replace with dynamic municipality ID
  //                               .collection('Notifications')
  //                               .add({
  //                             "token": tokenSelected,
  //                             "user": userNumber,
  //                             "title": notificationTitle,
  //                             "body": notificationBody,
  //                             "read": false,
  //                             "date": formattedDate,
  //                             "level": 'severe',
  //                           });
  //
  //                           // Send push notification to the user's token
  //                           sendPushMessage(tokenSelected, notificationTitle, notificationBody);
  //
  //                           // Show success message
  //                           Fluttertoast.showToast(
  //                             msg: 'The user has been sent the disconnection notice!',
  //                             gravity: ToastGravity.CENTER,
  //                           );
  //
  //                           // Clear the input fields
  //                           title.clear();
  //                           body.clear();
  //                           if (context.mounted) Navigator.of(context).pop();
  //                         } else {
  //                           // Show error if required fields are empty
  //                           Fluttertoast.showToast(
  //                             msg: 'Please fill in both the title and message!',
  //                             gravity: ToastGravity.CENTER,
  //                           );
  //                         }
  //                       },
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             );
  //           },
  //         );
  //       },
  //     );
  //   }
  //
  //   _createBottomSheet();
  // }
}
