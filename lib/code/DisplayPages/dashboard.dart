import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'package:get/get.dart';
import 'package:municipal_services/code/DisplayPages/prop_selection.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:municipal_services/main.dart';
import 'package:municipal_services/code/Chat/chat_screen.dart';
import 'package:municipal_services/code/DisplayPages/display_info.dart';
import 'package:municipal_services/code/DisplayPages/display_pdf_list.dart';
import 'package:municipal_services/code/DisplayPages/display_info_all_users.dart';
import 'package:municipal_services/code/Reusable/nav_drawer.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';
import 'package:municipal_services/code/Reusable/main_menu_reusable_button.dart';
import 'package:municipal_services/code/Reusable/menu_reusable_elevated_button.dart';
import 'package:municipal_services/code/ImageUploading/image_upload_fault.dart';
import 'package:municipal_services/code/faultPages/fault_report_screen.dart';
import 'package:municipal_services/code/Chat/chat_list.dart';
import 'package:municipal_services/code/MapTools/location_controller.dart';
import 'package:municipal_services/code/MapTools/map_screen.dart';
import 'package:municipal_services/code/NoticePages/notice_user_screen.dart';
import 'package:municipal_services/code/PDFViewer/view_pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Chat/chats_notifier.dart';
import '../Models/notify_provider.dart';
import '../Models/prop_provider.dart';
import '../Models/property.dart';
import '../Models/property_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../faultPages/fault_report_water.dart';

//Main Menu for users
final StreamController<String?> selectNotificationStream =
    StreamController<String?>.broadcast();
const String navigationActionId = 'id_3';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // ignore: avoid_print
  print('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    // ignore: avoid_print
    print(
        'notification action tapped with input: ${notificationResponse.input}');
  }
}

class MainMenu extends StatefulWidget {
  final Property property;
  final int propertyCount;
  final bool isLocalMunicipality;

  const MainMenu({
    super.key,
    required this.property,
    required this.propertyCount,
    required this.isLocalMunicipality,
  });

  @override
  State<StatefulWidget> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  final user = FirebaseAuth.instance.currentUser!;
  late String userPhoneNumber;
  final CollectionReference _propList =
  FirebaseFirestore.instance.collection('properties');
  final CollectionReference _tokenList =
  FirebaseFirestore.instance.collection('UserToken');
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  Timer? timer;
  String? mtoken = " ";
  late Property currentProperty;
  PropertyService propertyService = PropertyService();
  List<Property>? userProperties;
  bool isLoading = true;
  CollectionReference? _chatsList;
  String districtId = '';
  String municipalityId = '';
  String? selectedPropertyAccountNumber;
  bool isLocalMunicipality = false;
  bool hasUnreadMessages = false;
  StreamSubscription<QuerySnapshot>? unreadRegularMessagesSubscription;
  StreamSubscription<QuerySnapshot>? unreadFinanceMessagesSubscription;
  StreamSubscription<QuerySnapshot>? unreadCouncillorMessagesSubscription;
  bool hasUnreadFinanceMessages = false;
  bool hasUnreadCouncillorMessages = false;
  bool isCouncillor = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    userPhoneNumber = user.phoneNumber!;
    initializeData().then((_) {
      if (_chatsList != null && selectedPropertyAccountNumber != null) {
        // Proceed with other initialization or UI updates
        print('Initialization complete with valid data.');
      } else {
        print(
            'Error: _chatsList or selectedPropertyAccountNumber is not initialized.');
      }
      if (mounted) {
        setState(() {
          isLoading =
          false; // Data is loaded, user can now interact with the menu
        });
      }
      print("🚀 Initializing Version Fetch...");
      getVersionStream();
      checkForUnreadMessages();
      checkForUnreadFinanceMessages();
    });
    //migrateConsumptionDataTo2024();

    setupNotificationListener();
    checkForUnreadCouncilMessages();
    fetchUserProperties();
    currentProperty = widget.property;
    if (user == null) {
      // Handle the case where there is no user logged in.
      print('No user logged in.');
      // Redirect to login or handle accordingly
    } else {
      // Continue with initialization that requires a logged-in user.
      requestPermission();
      getToken();
      initInfo();
      // getVersionStream();
      addChatCustomId(accountNumber);
      // timer = Timer.periodic(const Duration(minutes: 1), (Timer t) => getVersionStream());
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    unreadRegularMessagesSubscription?.cancel();
    unreadFinanceMessagesSubscription?.cancel();
    unreadCouncillorMessagesSubscription?.cancel();
    super.dispose();
  }

  Future<void> initializeData() async {
    setState(() {
      isLoading = true;
    });
    await loadSelectedPropertyAccountNumber();
    await _initializeCollectionReferences();
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> storeSelectedPropertyDetails(Property property) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLocalMunicipality', property.isLocalMunicipality);
    await prefs.setString('municipalityId', property.municipalityId);
    await prefs.setString('selectedPropertyAccountNo', property.accountNo);
  }

  Future<void> fetchUserProperties() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    userProperties =
    await propertyService.fetchPropertiesForUser(widget.property.cellNum);

    if (userProperties == null || userProperties!.isEmpty) {
      print("No properties found for this user.");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    if (selectedPropertyAccountNumber != null) {
      currentProperty = userProperties!.firstWhere(
            (property) => property.accountNo == selectedPropertyAccountNumber,
        orElse: () => userProperties!.first,
      );
    } else {
      currentProperty = userProperties!.first;
    }

    await storeSelectedPropertyDetails(currentProperty);
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permissions');
    } else {
      print('User declined or has not accepted permissions');
    }
  }

  Future<void> _initializeCollectionReferences() async {
    try {
      // Check if property data is available
      if (widget.property != null) {
        // Set `municipalityId` and other necessary fields
        municipalityId = widget.property.municipalityId;
        districtId = (widget.property.isLocalMunicipality
            ? null
            : widget.property.districtId)!;
        isLocalMunicipality = widget.property.isLocalMunicipality;

        if (isLocalMunicipality) {
          // Local municipality case
          _chatsList = FirebaseFirestore.instance
              .collection('localMunicipalities')
              .doc(municipalityId)
              .collection('chatRoom');
        } else if (districtId != null) {
          // District municipality case
          _chatsList = FirebaseFirestore.instance
              .collection('districts')
              .doc(districtId)
              .collection('municipalities')
              .doc(municipalityId)
              .collection('chatRoom');
        }

        print('Chat collection reference initialized: $_chatsList');
      }
    } catch (e) {
      print('Error initializing CollectionReference: $e');
    }
  }

  Future<void> loadSelectedPropertyAccountNumber() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      selectedPropertyAccountNumber =
          prefs.getString('selectedPropertyAccountNo');
      bool? isLocalMunicipality = prefs.getBool('isLocalMunicipality');

      print(
          "Loaded selected property account number: $selectedPropertyAccountNumber");
      print("Loaded municipality type: $isLocalMunicipality");

      if (selectedPropertyAccountNumber != null &&
          isLocalMunicipality != null) {
        // Now you can use these values to set up the initial data
        if (isLocalMunicipality) {
          // Handle local municipality case
          currentProperty = (await propertyService.fetchPropertyByAccountNo(
              selectedPropertyAccountNumber!, isLocalMunicipality))!;
        } else {
          // Handle district case
          currentProperty = (await propertyService.fetchPropertyByAccountNo(
              selectedPropertyAccountNumber!, isLocalMunicipality))!;
        }
      }
    } catch (e) {
      print("Error loading selected property account number: $e");
    }
  }

  void getToken() async {
    await FirebaseMessaging.instance.getToken().then(
          (token) {
        setState(() {
          mtoken = token;
          print("My token is $mtoken");
        });
        saveToken(token!);
        //saveChatPhoneNumber(token);
      },
    );
  }

  void saveToken(String token) async {
    if (widget.property.isLocalMunicipality) {
      await FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(widget.property.municipalityId)
          .collection('UserToken')
          .doc(user.phoneNumber)
          .set({'token': token});
    } else {
      await FirebaseFirestore.instance
          .collection('districts')
          .doc(widget.property.districtId)
          .collection('municipalities')
          .doc(widget.property.municipalityId)
          .collection('UserToken')
          .doc(user.phoneNumber)
          .set({'token': token});
    }

    // Update token for all properties associated with this user
    final propListRef = widget.property.isLocalMunicipality
        ? FirebaseFirestore.instance
        .collection('localMunicipalities')
        .doc(widget.property.municipalityId)
        .collection('properties')
        : FirebaseFirestore.instance
        .collection('districts')
        .doc(widget.property.districtId)
        .collection('municipalities')
        .doc(widget.property.municipalityId)
        .collection('properties');

    propListRef.get().then((querySnapshot) async {
      for (var result in querySnapshot.docs) {
        if (result['cellNumber'] == user.phoneNumber) {
          await propListRef.doc(result.id).update({'token': token});
        }
      }
    });
  }

  void checkForUnreadMessages() async {
    if (!mounted) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedPropertyAccountNumber =
    prefs.getString('selectedPropertyAccountNo');

    if (selectedPropertyAccountNumber == null) {
      print('Error: selectedPropertyAccountNumber is null.');
      return;
    }

    try {
      QuerySnapshot localMunicipalitySnapshot = await FirebaseFirestore.instance
          .collectionGroup('properties')
          .where('accountNumber', isEqualTo: selectedPropertyAccountNumber)
          .get();

      if (localMunicipalitySnapshot.docs.isNotEmpty) {
        DocumentSnapshot propertyDoc = localMunicipalitySnapshot.docs.first;
        bool isLocalMunicipality = propertyDoc.get('isLocalMunicipality');
        String municipalityId = propertyDoc.get('municipalityId');
        String? districtId =
        propertyDoc.data().toString().contains('districtId')
            ? propertyDoc.get('districtId')
            : null;
        String phoneNumber = propertyDoc.get('cellNumber');

        CollectionReference chatsCollection;
        if (isLocalMunicipality) {
          chatsCollection = FirebaseFirestore.instance
              .collection('localMunicipalities')
              .doc(municipalityId)
              .collection('chatRoom')
              .doc(phoneNumber)
              .collection('accounts')
              .doc(selectedPropertyAccountNumber)
              .collection('chats');
        } else {
          chatsCollection = FirebaseFirestore.instance
              .collection('districts')
              .doc(districtId!)
              .collection('municipalities')
              .doc(municipalityId)
              .collection('chatRoom')
              .doc(phoneNumber)
              .collection('accounts')
              .doc(selectedPropertyAccountNumber)
              .collection('chats');
        }

        unreadRegularMessagesSubscription?.cancel();

        unreadRegularMessagesSubscription = chatsCollection
            .where('sendBy',
            isNotEqualTo: FirebaseAuth.instance.currentUser?.phoneNumber)
            .snapshots()
            .listen((snapshot) {
          bool hasUnread = false;
          for (var doc in snapshot.docs) {
            var data = doc.data() as Map<String, dynamic>;
            if (data['isReadByRegularUser'] == false) {
              hasUnread = true;
              print(
                  "Unread Message Data (sendBy and isReadByRegularUser check): $data");
            }
          }
          if (mounted) {
            setState(() {
              hasUnreadMessages = hasUnread;
            });
            print("Updated hasUnreadMessages to: $hasUnreadMessages");
          }
        });
      }
    } catch (e) {
      print('Error checking for unread messages: $e');
    }
  }

  void checkForUnreadFinanceMessages() async {
    if (!mounted) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedPropertyAccountNumber =
    prefs.getString('selectedPropertyAccountNo');

    if (selectedPropertyAccountNumber == null) {
      print('Error: selectedPropertyAccountNumber is null.');
      return;
    }

    try {
      QuerySnapshot localMunicipalitySnapshot = await FirebaseFirestore.instance
          .collectionGroup('properties')
          .where('accountNumber', isEqualTo: selectedPropertyAccountNumber)
          .get();

      if (localMunicipalitySnapshot.docs.isNotEmpty) {
        DocumentSnapshot propertyDoc = localMunicipalitySnapshot.docs.first;
        bool isLocalMunicipality = propertyDoc.get('isLocalMunicipality');
        String municipalityId = propertyDoc.get('municipalityId');
        String? districtId =
        propertyDoc.data().toString().contains('districtId')
            ? propertyDoc.get('districtId')
            : null;
        String phoneNumber = propertyDoc.get('cellNumber');

        CollectionReference financeChatsCollection;
        if (isLocalMunicipality) {
          financeChatsCollection = FirebaseFirestore.instance
              .collection('localMunicipalities')
              .doc(municipalityId)
              .collection('chatRoomFinance')
              .doc(phoneNumber)
              .collection('accounts')
              .doc(selectedPropertyAccountNumber)
              .collection('chats');
        } else {
          financeChatsCollection = FirebaseFirestore.instance
              .collection('districts')
              .doc(districtId!)
              .collection('municipalities')
              .doc(municipalityId)
              .collection('chatRoomFinance')
              .doc(phoneNumber)
              .collection('accounts')
              .doc(selectedPropertyAccountNumber)
              .collection('chats');
        }

        unreadFinanceMessagesSubscription?.cancel();

        unreadFinanceMessagesSubscription = financeChatsCollection
            .where('sendBy',
            isNotEqualTo: FirebaseAuth.instance.currentUser?.phoneNumber)
            .snapshots()
            .listen((snapshot) {
          bool hasUnread = false;
          for (var doc in snapshot.docs) {
            var data = doc.data() as Map<String, dynamic>;
            if (data['isReadByRegularUser'] == false) {
              hasUnread = true;
              print(
                  "Unread Finance Message Data (sendBy and isReadByRegularUser check): $data");
            }
          }
          if (mounted) {
            setState(() {
              hasUnreadFinanceMessages = hasUnread;
            });
            print(
                "Updated hasUnreadFinanceMessages to: $hasUnreadFinanceMessages");
          }
        });
      }
    } catch (e) {
      print('Error checking for unread finance messages: $e');
    }
  }

  Future<void> setupNotificationListener() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final selectedPropertyAccountNumber =
    prefs.getString('selectedPropertyAccountNo');

    print("Selected Property Account Number: $selectedPropertyAccountNumber");

    if (selectedPropertyAccountNumber != null) {
      try {
        // Fetch the property details based on the account number
        QuerySnapshot propertySnapshot = await FirebaseFirestore.instance
            .collectionGroup('properties')
            .where('accountNumber', isEqualTo: selectedPropertyAccountNumber)
            .get();

        if (propertySnapshot.docs.isNotEmpty) {
          DocumentSnapshot propertyDoc = propertySnapshot.docs.first;

          // Extract the relevant details
          municipalityId = propertyDoc['municipalityId'] ?? '';
          districtId = propertyDoc['districtId'] ?? '';
          isLocalMunicipality = propertyDoc['isLocalMunicipality'] ?? false;

          print("Retrieved Municipality ID: $municipalityId");
          print("Retrieved District ID: $districtId");
          print("Is Local Municipality: $isLocalMunicipality");

          CollectionReference? notificationsRef;

          // Determine the notifications path based on municipality type
          if (isLocalMunicipality) {
            notificationsRef = FirebaseFirestore.instance
                .collection('localMunicipalities')
                .doc(municipalityId)
                .collection('Notifications');
            print("Using Local Municipality Notifications path.");
          } else if (districtId.isNotEmpty) {
            notificationsRef = FirebaseFirestore.instance
                .collection('districts')
                .doc(districtId)
                .collection('municipalities')
                .doc(municipalityId)
                .collection('Notifications');
            print("Using District Municipality Notifications path.");
          } else {
            print(
                'Error: Unable to determine municipality type or IDs are missing.');
            return;
          }

          // Set up a listener for unread notifications for this property
          notificationsRef
              .where('user', isEqualTo: selectedPropertyAccountNumber)
              .where('read', isEqualTo: false)
              .snapshots()
              .listen((snapshot) {
            final hasUnreadNotices = snapshot.docs.isNotEmpty;
            NotificationProvider().updateUnreadNoticesStatus(hasUnreadNotices);
          });
        } else {
          print(
              "Error: No property found for account number $selectedPropertyAccountNumber.");
        }
      } catch (e) {
        print("Error fetching property details: $e");
      }
    } else {
      print('Error: selectedPropertyAccountNumber is null');
    }
  }

  Future<bool> checkIfCouncillor() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? selectedPropertyAccountNumber =
      prefs.getString('selectedPropertyAccountNo');

      if (selectedPropertyAccountNumber == null) {
        print('Error: selectedPropertyAccountNumber is null.');
        return false;
      }

      QuerySnapshot propertySnapshot = await FirebaseFirestore.instance
          .collectionGroup('properties')
          .where('accountNumber', isEqualTo: selectedPropertyAccountNumber)
          .get();

      if (propertySnapshot.docs.isNotEmpty) {
        DocumentSnapshot propertyDoc = propertySnapshot.docs.first;
        bool isLocalMunicipality = propertyDoc.get('isLocalMunicipality');
        String municipalityId = propertyDoc.get('municipalityId');
        String? districtId =
        propertyDoc.data().toString().contains('districtId')
            ? propertyDoc.get('districtId')
            : null;

        // Check the councillor collection
        QuerySnapshot councillorSnapshot = isLocalMunicipality
            ? await FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(municipalityId)
            .collection('councillors')
            .where('councillorPhone',
            isEqualTo: FirebaseAuth.instance.currentUser?.phoneNumber)
            .get()
            : await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId!)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('councillors')
            .where('councillorPhone',
            isEqualTo: FirebaseAuth.instance.currentUser?.phoneNumber)
            .get();

        if (councillorSnapshot.docs.isNotEmpty) {
          print("User is a councillor.");
          return true;
        }
      }

      print("User is not a councillor.");
      return false;
    } catch (e) {
      print('Error checking if user is a councillor: $e');
      return false;
    }
  }


  Future<void> checkForUnreadCouncilMessages() async {
    String? userPhone = FirebaseAuth.instance.currentUser?.phoneNumber;

    if (userPhone == null) {
      print("Error: Current user's phone number is null.");
      return;
    }

    // Determine if the user is a councillor
    checkIfCouncillor().then((isCouncillor) {
      SharedPreferences.getInstance().then((prefs) {
        String? selectedPropertyAccountNumber = prefs.getString(
            'selectedPropertyAccountNo');
        if (selectedPropertyAccountNumber == null) {
          print('Error: selectedPropertyAccountNumber is null.');
          return;
        }

        FirebaseFirestore.instance
            .collectionGroup('properties')
            .where('accountNumber', isEqualTo: selectedPropertyAccountNumber)
            .get()
            .then((propertySnapshot) {
          if (propertySnapshot.docs.isNotEmpty) {
            DocumentSnapshot propertyDoc = propertySnapshot.docs.first;
            bool isLocalMunicipality = propertyDoc.get('isLocalMunicipality');
            String municipalityId = propertyDoc.get('municipalityId');
            String? districtId = propertyDoc.data().toString().contains(
                'districtId')
                ? propertyDoc.get('districtId')
                : null;

            CollectionReference councillorChatsCollection = isLocalMunicipality
                ? FirebaseFirestore.instance
                .collection('localMunicipalities')
                .doc(municipalityId)
                .collection('chatRoomCouncillor')
                : FirebaseFirestore.instance
                .collection('districts')
                .doc(districtId!)
                .collection('municipalities')
                .doc(municipalityId)
                .collection('chatRoomCouncillor');

            unreadCouncillorMessagesSubscription?.cancel();
            unreadCouncillorMessagesSubscription =
                councillorChatsCollection.snapshots().listen(
                      (councillorSnapshot) async {
                    bool hasUnread = false;

                    if (isCouncillor) {
                      String councillorPhoneNumber = FirebaseAuth.instance
                          .currentUser?.phoneNumber ?? '';
                      councillorChatsCollection
                          .doc(councillorPhoneNumber)
                          .collection('userChats')
                          .snapshots()
                          .listen((userChatSnapshot) {
                        for (var userChatDoc in userChatSnapshot.docs) {
                          userChatDoc.reference.collection('messages')
                              .snapshots()
                              .listen((messagesSnapshot) {
                            bool localUnread = false; // Temporary variable for this chat
                            for (var messageDoc in messagesSnapshot.docs) {
                              if (messageDoc['isReadByCouncillor'] == false) {
                                localUnread = true;
                                hasUnread = true;
                                break;
                              }
                            }

                            // Update the global unread state only if necessary
                            if (!localUnread) {
                              hasUnread = false;
                            }

                            if (mounted) {
                              setState(() {
                                hasUnreadCouncillorMessages = hasUnread;
                              });
                              print(
                                  "Real-time badge updated: $hasUnreadCouncillorMessages");
                            }
                          });
                        }
                      });
                    } else {
                      for (var councillorDoc in councillorSnapshot.docs) {
                        councillorDoc.reference.collection('userChats')
                            .snapshots()
                            .listen((userChatSnapshot) {
                          for (var userChatDoc in userChatSnapshot.docs) {
                            userChatDoc.reference.collection('messages')
                                .snapshots()
                                .listen((messagesSnapshot) {
                              bool localUnread = false; // Temporary variable for this chat
                              for (var messageDoc in messagesSnapshot.docs) {
                                if (messageDoc['isReadByUser'] == false) {
                                  localUnread = true;
                                  hasUnread = true;
                                  break;
                                }
                              }

                              // Update the global unread state only if necessary
                              if (!localUnread) {
                                hasUnread = false;
                              }

                              if (mounted) {
                                setState(() {
                                  hasUnreadCouncillorMessages = hasUnread;
                                });
                                print(
                                    "Real-time badge updated: $hasUnreadCouncillorMessages");
                              }
                            });
                          }
                        });
                      }
                    }
                  },
                );
          }
        });
      });
    });
  }

  // Future<void> migrateConsumptionDataTo2024() async {
  //   try {
  //     // 🔹 Define Firestore reference (fetch all districts)
  //     QuerySnapshot districtsSnapshot = await FirebaseFirestore.instance.collection('districts').get();
  //
  //     for (var districtDoc in districtsSnapshot.docs) {
  //       String districtId = districtDoc.id;
  //
  //       // 🔹 Get municipalities under each district
  //       QuerySnapshot municipalitiesSnapshot = await districtDoc.reference.collection('municipalities').get();
  //
  //       for (var municipalityDoc in municipalitiesSnapshot.docs) {
  //         String municipalityId = municipalityDoc.id;
  //
  //         // 🔹 Get all monthly documents in the old structure
  //         QuerySnapshot oldConsumptionData = await municipalityDoc.reference.collection('consumption').get();
  //
  //         for (var monthDoc in oldConsumptionData.docs) {
  //           String month = monthDoc.id; // Example: "March"
  //
  //           // 🔹 Get all addresses under each month
  //           QuerySnapshot addressSnapshot = await monthDoc.reference.collection('address').get();
  //
  //           for (var addressDoc in addressSnapshot.docs) {
  //             String propertyAddress = addressDoc.id;
  //             Map<String, dynamic> oldData = addressDoc.data() as Map<String, dynamic>;
  //
  //             // 🔹 Move data to the new "2024" structure
  //             DocumentReference newDocRef = FirebaseFirestore.instance
  //                 .collection('districts')
  //                 .doc(districtId)
  //                 .collection('municipalities')
  //                 .doc(municipalityId)
  //                 .collection('consumption')
  //                 .doc("2024") // ✅ New Yearly Folder
  //                 .collection(month)
  //                 .doc(propertyAddress);
  //
  //             await newDocRef.set(oldData, SetOptions(merge: true));
  //
  //             print("✅ Migrated: $propertyAddress from $month to 2024 folder");
  //
  //             // (Optional) 🔥 Delete old data after migration
  //             await addressDoc.reference.delete();
  //           }
  //
  //           // (Optional) 🔥 Delete old month document if empty
  //           QuerySnapshot checkIfEmpty = await monthDoc.reference.collection('address').get();
  //           if (checkIfEmpty.docs.isEmpty) {
  //             await monthDoc.reference.delete();
  //           }
  //         }
  //       }
  //     }
  //
  //     print("🎉 Migration to 2024 completed successfully!");
  //   } catch (e) {
  //     print("🚨 Migration failed: $e");
  //   }
  // }




  // void saveToken(String token) async {
  //   await FirebaseFirestore.instance.collection("UserToken").doc(user.phoneNumber).set({
  //     'token': token,
  //   });
  //
  //   _propList.get().then((querySnapshot) async {
  //     for (var result in querySnapshot.docs) {
  //       if (_tokenList.where(_tokenList.id).toString() == user.phoneNumber || result['cell number'] == user.phoneNumber) {
  //         await _propList.doc(result.id).update({
  //           'token': token,
  //         });
  //       }
  //     }
  //   });
  // }

  // void saveChatPhoneNumber(String mobile) async {
  //   await FirebaseFirestore.instance.collection("chatRoom").doc(
  //       user.phoneNumber).set({
  //     'chatRoom': user.phoneNumber,
  //   });
  // }

  // Future<void> saveChatRoomId(String chatRoomId) async {
  //   try {
  //     await _chatsList?.doc(chatRoomId).set({
  //       'chatRoomId': chatRoomId,
  //       'createdAt': FieldValue.serverTimestamp(),
  //       'users': [user.phoneNumber]
  //     });
  //   } catch (e) {
  //     print('Error creating or updating chat room: $e');
  //   }
  // }

  void initInfo() {
    var androidInitialize =
    const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings =
    InitializationSettings(android: androidInitialize);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) {
          switch (notificationResponse.notificationResponseType) {
            case NotificationResponseType.selectedNotification:
              selectNotificationStream.add(notificationResponse.payload);
              break;
            case NotificationResponseType.selectedNotificationAction:
              if (notificationResponse.actionId == navigationActionId) {
                selectNotificationStream.add(notificationResponse.payload);
              }
              break;
          }
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("..........onMessage..........");
      print(
          "onMessage: ${message.notification?.title}/${message.notification
              ?.body}}");

      BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
        message.notification!.body.toString(),
        htmlFormatBigText: true,
        contentTitle: message.notification!.title.toString(),
        htmlFormatContentTitle: true,
      );
      AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'User',
        'User',
        importance: Importance.high,
        styleInformation: bigTextStyleInformation,
        priority: Priority.high,
        playSound: true,
      );
      NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(0, message.notification?.title,
          message.notification?.body, platformChannelSpecifics,
          payload: message.data['body']);
    });
  }

  bool visShow = true;
  bool visHide = false;
  bool visLocked = false;
  bool visFeatureMode = false;
  bool visPremium = true;

  List _allVersionResults = [];

  final CollectionReference _chatRoom =
  FirebaseFirestore.instance.collection('chatRoom');

  // void addChatCustomId() async {
  //   String? addChatID = user.phoneNumber;
  //   final chatSnapshot = FirebaseFirestore.instance.collection("chatRoom").doc(addChatID);
  //   if (chatSnapshot.isBlank!) {
  //   } else {
  //     _chatRoom.add(addChatID);
  //   }
  // }
  // addChatCustomId() async {
  //   String? addChatID = user.phoneNumber;
  //   final chatSnapshot = await FirebaseFirestore.instance
  //       .collection("chatRoom")
  //       .doc(addChatID)
  //       .get();
  //   if (!chatSnapshot.exists) {
  //     await _chatRoom.doc(addChatID).set({
  //       'chatRoomId': addChatID,
  //       'createdAt': FieldValue.serverTimestamp(),
  //       'users': [user.phoneNumber]
  //     });
  //   } else {
  //     print('Chat room already exists');
  //   }
  // }

  addChatCustomId(String accountNumber) async {
    const int maxRetries = 5; // Maximum number of retries
    int retryCount = 0;
    bool success = false;

    while (!success && retryCount < maxRetries) {
      try {
        if (widget.property.isLocalMunicipality) {
          // Path for local municipality
          final chatSnapshot = await FirebaseFirestore.instance
              .collection('localMunicipalities')
              .doc(widget.property.municipalityId)
              .collection('chatRoom')
              .doc(accountNumber)
              .get();
        } else {
          // Path for district-based municipality
          final chatSnapshot = await FirebaseFirestore.instance
              .collection('districts')
              .doc(widget.property.districtId)
              .collection('municipalities')
              .doc(widget.property.municipalityId)
              .collection('chatRoom')
              .doc(accountNumber)
              .get();
        }

        success = true; // If no error occurs, mark success as true
      } catch (e) {
        if (e is FirebaseException && e.code == 'unavailable') {
          retryCount++;
          print('Firestore service unavailable. Retrying attempt: $retryCount');

          // Wait for some time before retrying, using exponential backoff
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        } else {
          // If it's an unexpected error, log it and break out of the loop
          print('An unexpected error occurred: $e');
          break;
        }
      }
    }

    if (!success) {
      print('Failed to connect to Firestore after $maxRetries retries.');
      // Handle error state in the UI (e.g., show a message to the user)
    }
  }

  void getVersionStream() async {
    print("📢 Fetching version data...");

    print("🛠️ Checking IDs before Firestore query...");
    print("🔍 isLocalMunicipality: $isLocalMunicipality");
    print("🏙️ municipalityId: $municipalityId");
    print("🌍 districtId: $districtId");

    // Ensure IDs are not empty
    if (municipalityId.isEmpty || (!isLocalMunicipality && districtId.isEmpty)) {
      print("❌ Error: Either municipalityId or districtId is empty!");
      return;
    }

    try {
      var data = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('version')
          .get(const GetOptions(source: Source.server));

      if (mounted) {
        setState(() {
          _allVersionResults = data.docs;
        });

        print("✅ Fetched ${_allVersionResults.length} version documents.");
        getVersionDetails();
      }
    } catch (e) {
      print("❌ Failed to fetch version data: $e");
    }
  }



  void getVersionDetails() async {
    print("🔍 Checking version details...");

    if (_allVersionResults.isEmpty) {
      print("❌ Error: No version documents found!");
      return;
    }

    String activeVersion = _allVersionResults[0]['version'].toString(); // Ensure correct index
    print("📌 Active Version from Firestore: $activeVersion");

    // Fetch version document
    try {
      var versionDoc = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('version')
          .doc('current')
          .collection('current-version')
          .doc('current')
          .get(const GetOptions(source: Source.server)); // Forces fresh fetch


      if (!versionDoc.exists) {
        print("❌ No 'current' document found in Firestore.");
        return;
      }

      String fetchedVersion = versionDoc.data()?['version'] ?? "Unknown";
      print("✅ Retrieved version from Firestore: $fetchedVersion");

      // Match version and set visibility
      if (fetchedVersion == 'Unpaid') {
        visLocked = true;
        visFeatureMode = true;
        visPremium = true;
      } else if (fetchedVersion == 'Paid') {
        visLocked = false;
        visFeatureMode = false;
        visPremium = true;
      } else if (fetchedVersion == 'Premium') {
        visLocked = false;
        visFeatureMode = false;
        visPremium = false;
      } else {
        print("❌ No matching version found in Firestore.");
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("🚨 Error fetching version details: $e");
    }
  }




//   @override
//   Widget build(BuildContext context) {
//     Get.put(LocationController());
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.portraitUp,
//       DeviceOrientation.portraitDown,
//     ]);
//
//     return Container(
//       decoration: const BoxDecoration(
//         image: DecorationImage(
//           image: AssetImage("assets/images/greyscale.jpg"),
//           fit: BoxFit.cover,
//         ),
//       ),
//       child: Scaffold(
//         key: _scaffoldKey,
//         backgroundColor: Colors.transparent,
//         appBar: AppBar(
//           title: Text(
//             'Signed in from: ${user.phoneNumber!}',
//             style: GoogleFonts.turretRoad(
//               color: Colors.white,
//               fontWeight: FontWeight.w900,
//               fontSize: 19,
//             ),
//             overflow: TextOverflow.ellipsis,
//           ),
//           backgroundColor: Colors.black87,
//           iconTheme: const IconThemeData(color: Colors.white),
//           leading: Stack(
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.menu),
//                 onPressed: () {
//                   _scaffoldKey.currentState?.openDrawer(); // Use the global key to open the drawer
//                 },
//               ),
//               if (hasUnreadCouncillorMessages)
//                 Positioned(
//                   top: 8,
//                   right: 8,
//                   child: Container(
//                     padding: const EdgeInsets.all(3),
//                     decoration: const BoxDecoration(
//                       color: Colors.red,
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Text(
//                       '!',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 10,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//         drawer: const NavDrawer(),
//         body: SingleChildScrollView(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: <Widget>[
//               Column(
//                 children: <Widget>[
//                   const SizedBox(height: 30),
//                   const ResponsiveLogo(),
//                   SizedBox(height: 20.h),
//                   if (userProperties != null && userProperties!.length > 1)
//                     ElevatedIconButton(
//                       onPress: () async {
//                         final selectedProperty = await Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => PropertySelectionScreen(
//                               properties: userProperties!,
//                               userPhoneNumber: userPhoneNumber,
//                               isLocalMunicipality: widget.isLocalMunicipality,
//                             ),
//                           ),
//                         );
//
//                         if (selectedProperty != null) {
//                           setState(() {
//                             currentProperty = selectedProperty;
//                           });
//                         }
//                       },
//                       labelText: 'Select\nProperty',
//                       fSize: 18,
//                       faIcon: const FaIcon(FontAwesomeIcons.houseUser),
//                       fgColor: Colors.deepPurple,
//                         btSize: Size(130.w, 120.h)
//                     ),
//                   Column(
//                     children: [
//                       Center(
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             Expanded(
//                               child: Stack(
//                                 children: [
//                                   ElevatedIconButton(
//                                     onPress: () async {
//                                       SharedPreferences prefs =
//                                           await SharedPreferences.getInstance();
//                                       String? selectedPropertyAccountNumber =
//                                           prefs.getString(
//                                               'selectedPropertyAccountNo');
//
//                                       if (selectedPropertyAccountNumber ==
//                                           null) {
//                                         print(
//                                             'Error: selectedPropertyAccountNumber is null.');
//                                         return;
//                                       }
//
//                                       try {
//                                         QuerySnapshot
//                                             localMunicipalitySnapshot =
//                                             await FirebaseFirestore.instance
//                                                 .collectionGroup('properties')
//                                                 .where('accountNumber',
//                                                     isEqualTo:
//                                                         selectedPropertyAccountNumber)
//                                                 .get();
//
//                                         if (localMunicipalitySnapshot
//                                             .docs.isNotEmpty) {
//                                           DocumentSnapshot propertyDoc =
//                                               localMunicipalitySnapshot
//                                                   .docs.first;
//                                           bool isLocalMunicipality = propertyDoc
//                                               .get('isLocalMunicipality');
//                                           String municipalityId =
//                                               propertyDoc.get('municipalityId');
//                                           String? districtId = propertyDoc
//                                                   .data()
//                                                   .toString()
//                                                   .contains('districtId')
//                                               ? propertyDoc.get('districtId')
//                                               : null;
//                                           String phoneNumber =
//                                               propertyDoc.get('cellNumber');
//
//                                           CollectionReference<Object?>?
//                                               chatCollectionRef;
//                                           if (isLocalMunicipality) {
//                                             chatCollectionRef =
//                                                 FirebaseFirestore.instance
//                                                     .collection(
//                                                         'localMunicipalities')
//                                                     .doc(municipalityId)
//                                                     .collection('chatRoom');
//                                           } else if (districtId != null) {
//                                             chatCollectionRef =
//                                                 FirebaseFirestore
//                                                     .instance
//                                                     .collection('districts')
//                                                     .doc(districtId)
//                                                     .collection(
//                                                         'municipalities')
//                                                     .doc(municipalityId)
//                                                     .collection('chatRoom');
//                                           }
//
//                                           if (chatCollectionRef != null) {
//                                             Navigator.push(
//                                               context,
//                                               MaterialPageRoute(
//                                                 builder: (context) => Chat(
//                                                   chatRoomId: phoneNumber,
//                                                   userName:
//                                                       selectedPropertyAccountNumber,
//                                                   chatCollectionRef:
//                                                       chatCollectionRef!,
//                                                   refreshChatList:
//                                                       checkForUnreadMessages,
//                                                   // Callback to refresh badge
//                                                   isLocalMunicipality:
//                                                       isLocalMunicipality,
//                                                   districtId: districtId ?? '',
//                                                   municipalityId:
//                                                       municipalityId,
//                                                 ),
//                                               ),
//                                             );
//                                           }
//                                         }
//                                       } catch (e) {
//                                         print(
//                                             'Error retrieving property details: $e');
//                                       }
//                                     },
//                                     labelText: 'Admin \nChat',
//                                     fSize: 18,
//                                     faIcon:
//                                         const FaIcon(FontAwesomeIcons.message),
//                                     fgColor: Colors.blue,
//                                       btSize: Size(130.w, 120.h)
//                                   ),
//                                   if (hasUnreadMessages)
//                                     Positioned(
//                                       right: 0,
//                                       top: 0,
//                                       child: Container(
//                                         padding: const EdgeInsets.all(3),
//                                         decoration: BoxDecoration(
//                                           color: Colors.red,
//                                           borderRadius:
//                                               BorderRadius.circular(8),
//                                         ),
//                                         constraints: const BoxConstraints(
//                                           minWidth: 16,
//                                           minHeight: 16,
//                                         ),
//                                         child: const Text(
//                                           '!',
//                                           style: TextStyle(
//                                             color: Colors.white,
//                                             fontSize: 12,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                           textAlign: TextAlign.center,
//                                         ),
//                                       ),
//                                     ),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(width: 40),
//                             Expanded(
//                               child: ElevatedIconButton(
//                                 onPress: () async {
//                                   // Fetch selected property information, especially for local municipality
//                                   if (currentProperty.isLocalMunicipality) {
//                                     // Local municipality logic
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) =>
//                                             UsersTableViewPage(
//                                           property: currentProperty,
//                                           userNumber: currentProperty.cellNum,
//                                           accountNumber:
//                                               currentProperty.accountNo,
//                                           propertyAddress:
//                                               currentProperty.address,
//                                           districtId: '',
//                                           // No districtId for local municipalities
//                                           municipalityId:
//                                               currentProperty.municipalityId,
//                                           isLocalMunicipality: currentProperty
//                                               .isLocalMunicipality,
//                                         ),
//                                       ),
//                                     );
//                                   } else {
//                                     // District-based municipality logic
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) =>
//                                             UsersTableViewPage(
//                                           property: currentProperty,
//                                           userNumber: currentProperty.cellNum,
//                                           accountNumber:
//                                               currentProperty.accountNo,
//                                           propertyAddress:
//                                               currentProperty.address,
//                                           districtId:
//                                               currentProperty.districtId,
//                                           municipalityId:
//                                               currentProperty.municipalityId,
//                                           isLocalMunicipality: currentProperty
//                                               .isLocalMunicipality,
//                                         ),
//                                       ),
//                                     );
//                                   }
//                                 },
//                                 labelText: 'View \nDetails',
//                                 fSize: 16,
//                                 faIcon: const FaIcon(
//                                     FontAwesomeIcons.houseCircleExclamation),
//                                 fgColor: Colors.green,
//                                   btSize: Size(130.w, 120.h)
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Center(
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             Expanded(
//                               child: Consumer<NotificationProvider>(
//                                 builder:
//                                     (context, notificationProvider, child) {
//                                   return Stack(
//                                     children: [
//                                       ElevatedIconButton(
//                                         onPress: () async {
//                                           // Fetch the selected property account number from SharedPreferences
//                                           SharedPreferences prefs =
//                                               await SharedPreferences
//                                                   .getInstance();
//                                           String?
//                                               selectedPropertyAccountNumber =
//                                               prefs.getString(
//                                                   'selectedPropertyAccountNo');
//
//                                           // Check if the account number exists
//                                           if (selectedPropertyAccountNumber ==
//                                               null) {
//                                             print(
//                                                 'Error: selectedPropertyAccountNumber is null.');
//                                             Fluttertoast.showToast(
//                                                 msg: "No property selected.");
//                                             return;
//                                           }
//
//                                           try {
//                                             // Search for the property in both localMunicipalities and district properties
//                                             QuerySnapshot propertySnapshot =
//                                                 await FirebaseFirestore.instance
//                                                     .collectionGroup(
//                                                         'properties')
//                                                     .where('accountNumber',
//                                                         isEqualTo:
//                                                             selectedPropertyAccountNumber)
//                                                     .get();
//
//                                             if (propertySnapshot
//                                                 .docs.isNotEmpty) {
//                                               DocumentSnapshot propertyDoc =
//                                                   propertySnapshot.docs.first;
//
//                                               // Retrieve the 'isLocalMunicipality', 'municipalityId', and 'districtId' (if applicable)
//                                               bool isLocalMunicipality =
//                                                   propertyDoc.get(
//                                                           'isLocalMunicipality')
//                                                       as bool;
//                                               String municipalityId =
//                                                   propertyDoc
//                                                           .get('municipalityId')
//                                                       as String;
//                                               String? districtId = propertyDoc
//                                                       .data()
//                                                       .toString()
//                                                       .contains('districtId')
//                                                   ? propertyDoc.get(
//                                                       'districtId') as String
//                                                   : null;
//
//                                               // Pass the correct data to the NoticeScreen based on whether it's a local or district property
//                                               Navigator.push(
//                                                 context,
//                                                 MaterialPageRoute(
//                                                   builder: (context) =>
//                                                       NoticeScreen(
//                                                     selectedPropertyAccountNumber:
//                                                         selectedPropertyAccountNumber,
//                                                     isLocalMunicipality:
//                                                         isLocalMunicipality,
//                                                     municipalityId:
//                                                         municipalityId,
//                                                     districtId:
//                                                         districtId, // Can be null for local municipalities
//                                                   ),
//                                                 ),
//                                               );
//                                             } else {
//                                               print(
//                                                   'Error: No property found for account number $selectedPropertyAccountNumber.');
//                                               Fluttertoast.showToast(
//                                                   msg:
//                                                       "No property found for selected account.");
//                                             }
//                                           } catch (e) {
//                                             print(
//                                                 'Error retrieving property details: $e');
//                                             Fluttertoast.showToast(
//                                                 msg:
//                                                     "Failed to load property details.");
//                                           }
//                                         },
//                                         labelText: 'Notices',
//                                         fSize: 16,
//                                         faIcon: const FaIcon(
//                                             Icons.notifications_on),
//                                         fgColor: Colors.red,
//                                           btSize: Size(130.w, 120.h)
//                                       ),
//                                       // Show notification badge if there are unread notices
//                                       if (notificationProvider.hasUnreadNotices)
//                                         Positioned(
//                                           right: 0,
//                                           top: 0,
//                                           child: Container(
//                                             padding: const EdgeInsets.all(3),
//                                             decoration: BoxDecoration(
//                                               color: Colors.red,
//                                               borderRadius:
//                                                   BorderRadius.circular(8),
//                                             ),
//                                             constraints: const BoxConstraints(
//                                               minWidth: 16,
//                                               minHeight: 16,
//                                             ),
//                                             child: const Text(
//                                               '!',
//                                               style: TextStyle(
//                                                 color: Colors.white,
//                                                 fontSize: 12,
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                               textAlign: TextAlign.center,
//                                             ),
//                                           ),
//                                         ),
//                                     ],
//                                   );
//                                 },
//                               ),
//                             ),
//                             const SizedBox(width: 40),
//                             Expanded(
//                               child: Stack(
//                                 children: [
//                                   ElevatedIconButton(
//                                     onPress: () async {
//                                       // Fetch selected property account number from SharedPreferences
//                                       SharedPreferences prefs =
//                                           await SharedPreferences.getInstance();
//                                       String? selectedPropertyAccountNumber =
//                                           prefs.getString(
//                                               'selectedPropertyAccountNo');
//
//                                       // Check if the account number exists
//                                       if (selectedPropertyAccountNumber ==
//                                           null) {
//                                         print(
//                                             'Error: selectedPropertyAccountNumber is null.');
//                                         Fluttertoast.showToast(
//                                             msg: "No property selected.");
//                                         return;
//                                       }
//
//                                       try {
//                                         // Search for the property in both localMunicipalities and district properties
//                                         QuerySnapshot propertySnapshot =
//                                             await FirebaseFirestore.instance
//                                                 .collectionGroup('properties')
//                                                 .where('accountNumber',
//                                                     isEqualTo:
//                                                         selectedPropertyAccountNumber)
//                                                 .get();
//
//                                         if (propertySnapshot.docs.isNotEmpty) {
//                                           DocumentSnapshot propertyDoc =
//                                               propertySnapshot.docs.first;
//
//                                           // Retrieve the 'isLocalMunicipality', 'municipalityId', and 'districtId' (if applicable)
//                                           bool isLocalMunicipality = propertyDoc
//                                                   .get('isLocalMunicipality')
//                                               as bool;
//                                           String municipalityId = propertyDoc
//                                               .get('municipalityId') as String;
//                                           String? districtId = propertyDoc
//                                                   .data()
//                                                   .toString()
//                                                   .contains('districtId')
//                                               ? propertyDoc.get('districtId')
//                                                   as String
//                                               : null;
//
//                                           // Pass the correct data to the UsersPdfListViewPage based on whether it's a local or district property
//                                           Navigator.push(
//                                             context,
//                                             MaterialPageRoute(
//                                               builder: (context) =>
//                                                   UsersPdfListViewPage(
//                                                 userNumber: propertyDoc
//                                                     .get('cellNumber'),
//                                                 propertyAddress:
//                                                     propertyDoc.get('address'),
//                                                 accountNumber: propertyDoc
//                                                     .get('accountNumber'),
//                                                 isLocalMunicipality:
//                                                     isLocalMunicipality,
//                                                 municipalityId: municipalityId,
//                                                 districtId:
//                                                     districtId, // Can be null for local municipalities
//                                               ),
//                                             ),
//                                           );
//                                         } else {
//                                           print(
//                                               'Error: No property found for account number $selectedPropertyAccountNumber.');
//                                           Fluttertoast.showToast(
//                                               msg:
//                                                   "No property found for selected account.");
//                                         }
//                                       } catch (e) {
//                                         print(
//                                             'Error retrieving property details: $e');
//                                         Fluttertoast.showToast(
//                                             msg:
//                                                 "Failed to load property details.");
//                                       }
//                                     },
//                                     labelText: 'View\nInvoice',
//                                     fSize: 17,
//                                     faIcon: const FaIcon(
//                                         FontAwesomeIcons.solidFilePdf),
//                                     fgColor: Colors.redAccent,
//                                       btSize: Size(130.w, 120.h)
//                                   ),
//                                   if (hasUnreadFinanceMessages)
//                                     Positioned(
//                                       left: 0,
//                                       top: 0,
//                                       child: Container(
//                                         padding: const EdgeInsets.all(3),
//                                         decoration: BoxDecoration(
//                                           color: Colors.red,
//                                           borderRadius:
//                                               BorderRadius.circular(8),
//                                         ),
//                                         constraints: const BoxConstraints(
//                                           minWidth: 16,
//                                           minHeight: 16,
//                                         ),
//                                         child: const Text(
//                                           '!',
//                                           style: TextStyle(
//                                             color: Colors.white,
//                                             fontSize: 12,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                           textAlign: TextAlign.center,
//                                         ),
//                                       ),
//                                     ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Center(
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             ElevatedIconButton(
//                               onPress: () {
//                                 showDialog(
//                                   barrierDismissible: false,
//                                   context: context,
//                                   builder: (context) {
//                                     return AlertDialog(
//                                       shape: const RoundedRectangleBorder(
//                                           borderRadius: BorderRadius.all(
//                                               Radius.circular(18))),
//                                       title: const Text("Logout"),
//                                       content: const Text(
//                                           "Are you sure you want to logout?"),
//                                       actions: [
//                                         IconButton(
//                                           onPressed: () {
//                                             Navigator.pop(context);
//                                           },
//                                           icon: const Icon(Icons.cancel,
//                                               color: Colors.red),
//                                         ),
//                                         IconButton(
//                                           onPressed: () async {
//                                             await FirebaseAuth.instance
//                                                 .signOut();
//                                             Navigator.pop(context);
//                                           },
//                                           icon: const Icon(Icons.done,
//                                               color: Colors.green),
//                                         ),
//                                       ],
//                                     );
//                                   },
//                                 );
//                               },
//                               labelText: 'Logout',
//                               fSize: 18,
//                               faIcon: const FaIcon(Icons.logout),
//                               fgColor: Colors.red,
//                                 btSize: Size(130.w, 120.h)
//                             ),
//                             const SizedBox(width: 40),
//                             ElevatedIconButton(
//                               onPress: () {
//                                 if (currentProperty != null) {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (context) =>
//                                           WaterSanitationReportMenu(
//                                         currentProperty: currentProperty,
//                                         isLocalMunicipality:
//                                             currentProperty.isLocalMunicipality,
//                                         municipalityId:
//                                             currentProperty.municipalityId,
//                                         districtId: currentProperty
//                                                 .isLocalMunicipality
//                                             ? null
//                                             : currentProperty
//                                                 .districtId, // null if local
//                                       ),
//                                     ),
//                                   );
//                                 } else {
//                                   print('Error: No property selected.');
//                                   Fluttertoast.showToast(
//                                       msg: "No property selected.");
//                                 }
//                               },
//                               labelText: 'Report \nFaults',
//                               fSize: 17,
//                               faIcon: const FaIcon(Icons.report_problem),
//                               fgColor: Colors.orangeAccent,
//                                 btSize: Size(130.w, 120.h)
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 30),
//                       Column(
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         children: <Widget>[
//                           Text(
//                             'Copyright Cyberfox ',
//                             style: GoogleFonts.saira(
//                               color: Colors.white,
//                               backgroundColor: Colors.white10,
//                               fontWeight: FontWeight.normal,
//                               fontStyle: FontStyle.italic,
//                               fontSize: 16,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 20),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

  Future<void> _navigateToChat(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? selectedPropertyAccountNumber = prefs.getString(
          'selectedPropertyAccountNo');

      if (selectedPropertyAccountNumber == null) {
        print('Error: selectedPropertyAccountNumber is null.');
        Fluttertoast.showToast(msg: "No property selected.");
        return;
      }

      QuerySnapshot propertySnapshot = await FirebaseFirestore.instance
          .collectionGroup('properties')
          .where('accountNumber', isEqualTo: selectedPropertyAccountNumber)
          .get();

      if (propertySnapshot.docs.isEmpty) {
        print(
            'Error: No property found for account number $selectedPropertyAccountNumber.');
        Fluttertoast.showToast(msg: "Property not found.");
        return;
      }

      DocumentSnapshot propertyDoc = propertySnapshot.docs.first;
      bool isLocalMunicipality = propertyDoc.get('isLocalMunicipality');
      String municipalityId = propertyDoc.get('municipalityId');
      String? districtId = propertyDoc.data().toString().contains('districtId')
          ? propertyDoc.get('districtId')
          : null;
      String phoneNumber = propertyDoc.get('cellNumber');

      CollectionReference chatCollectionRef;

      if (isLocalMunicipality) {
        chatCollectionRef = FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(municipalityId)
            .collection('chatRoom');
      } else if (districtId != null) {
        chatCollectionRef = FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('chatRoom');
      } else {
        print("Error: Could not determine chat collection reference.");
        Fluttertoast.showToast(msg: "Chat room not found.");
        return;
      }

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              Chat(
                chatRoomId: phoneNumber,
                userName: selectedPropertyAccountNumber,
                chatCollectionRef: chatCollectionRef,
                refreshChatList: checkForUnreadMessages,
                // Callback to refresh badge
                isLocalMunicipality: isLocalMunicipality,
                districtId: districtId ?? '',
                municipalityId: municipalityId,
              ),
        ),
      );
    } catch (e) {
      print('Error retrieving property details: $e');
      Fluttertoast.showToast(msg: "Failed to load chat.");
    }
  }

  Future<void> _navigateToViewDetails(BuildContext context) async {
    if (currentProperty == null) {
      print("Error: No property selected.");
      Fluttertoast.showToast(msg: "No property selected.");
      return;
    }

    // Determine the correct navigation path based on property type
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UsersTableViewPage(
              property: currentProperty,
              userNumber: currentProperty.cellNum,
              accountNumber: currentProperty.accountNo,
              propertyAddress: currentProperty.address,
              districtId: currentProperty.isLocalMunicipality
                  ? ''
                  : currentProperty.districtId,
              municipalityId: currentProperty.municipalityId,
              isLocalMunicipality: currentProperty.isLocalMunicipality,
            ),
      ),
    );
  }

  Future<void> _navigateToNotices(BuildContext context) async {
    // Fetch the selected property account number from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedPropertyAccountNumber = prefs.getString(
        'selectedPropertyAccountNo');

    // Check if the account number exists
    if (selectedPropertyAccountNumber == null) {
      print('Error: selectedPropertyAccountNumber is null.');
      Fluttertoast.showToast(msg: "No property selected.");
      return;
    }

    try {
      // Search for the property in both localMunicipalities and district properties
      QuerySnapshot propertySnapshot = await FirebaseFirestore.instance
          .collectionGroup('properties')
          .where('accountNumber', isEqualTo: selectedPropertyAccountNumber)
          .get();

      if (propertySnapshot.docs.isNotEmpty) {
        DocumentSnapshot propertyDoc = propertySnapshot.docs.first;

        // Retrieve the property details
        bool isLocalMunicipality = propertyDoc.get(
            'isLocalMunicipality') as bool;
        String municipalityId = propertyDoc.get('municipalityId') as String;
        String? districtId = propertyDoc.data().toString().contains(
            'districtId')
            ? propertyDoc.get('districtId') as String
            : null;

        // Navigate to the Notices screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                NoticeScreen(
                  selectedPropertyAccountNumber: selectedPropertyAccountNumber,
                  isLocalMunicipality: isLocalMunicipality,
                  municipalityId: municipalityId,
                  districtId: districtId, // Can be null for local municipalities
                ),
          ),
        );
      } else {
        print(
            'Error: No property found for account number $selectedPropertyAccountNumber.');
        Fluttertoast.showToast(msg: "No property found for selected account.");
      }
    } catch (e) {
      print('Error retrieving property details: $e');
      Fluttertoast.showToast(msg: "Failed to load property details.");
    }
  }

  Future<void> _navigateToViewInvoice(BuildContext context) async {
    try {
      // Fetch the selected property account number from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? selectedPropertyAccountNumber = prefs.getString(
          'selectedPropertyAccountNo');

      if (selectedPropertyAccountNumber == null) {
        print('Error: selectedPropertyAccountNumber is null.');
        Fluttertoast.showToast(msg: "No property selected.");
        return;
      }

      // Search for the property in both localMunicipalities and district properties
      QuerySnapshot propertySnapshot = await FirebaseFirestore.instance
          .collectionGroup('properties')
          .where('accountNumber', isEqualTo: selectedPropertyAccountNumber)
          .get();

      if (propertySnapshot.docs.isNotEmpty) {
        DocumentSnapshot propertyDoc = propertySnapshot.docs.first;

        // Retrieve the required property details
        bool isLocalMunicipality = propertyDoc.get(
            'isLocalMunicipality') as bool;
        String municipalityId = propertyDoc.get('municipalityId') as String;
        String? districtId = propertyDoc.data().toString().contains(
            'districtId')
            ? propertyDoc.get('districtId') as String
            : null;

        // Navigate to the UsersPdfListViewPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                UsersPdfListViewPage(
                  userNumber: propertyDoc.get('cellNumber'),
                  propertyAddress: propertyDoc.get('address'),
                  accountNumber: propertyDoc.get('accountNumber'),
                  isLocalMunicipality: isLocalMunicipality,
                  municipalityId: municipalityId,
                  districtId: districtId, // Can be null for local municipalities
                ),
          ),
        );
      } else {
        print(
            'Error: No property found for account number $selectedPropertyAccountNumber.');
        Fluttertoast.showToast(msg: "No property found for selected account.");
      }
    } catch (e) {
      print('Error retrieving property details: $e');
      Fluttertoast.showToast(msg: "Failed to load property details.");
    }
  }

  Future<void> _navigateToReportFault(BuildContext context) async {
    if (currentProperty != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              WaterSanitationReportMenu(
                currentProperty: currentProperty,
                isLocalMunicipality: currentProperty.isLocalMunicipality,
                municipalityId: currentProperty.municipalityId,
                districtId: currentProperty.isLocalMunicipality
                    ? null
                    : currentProperty.districtId, // null if local
              ),
        ),
      );
    } else {
      print('Error: No property selected.');
      Fluttertoast.showToast(msg: "No property selected.");
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              icon: const Icon(Icons.cancel, color: Colors.red),
            ),
            IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pop(context); // Close dialog
                // Optionally navigate to login screen if needed
              },
              icon: const Icon(Icons.done, color: Colors.green),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    Get.put(LocationController());
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return ScreenUtilInit(
      designSize: const Size(375, 812), // Default mobile reference size
      minTextAdapt: true,
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/greyscale.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                'Signed in from: ${user.phoneNumber!}',
                style: GoogleFonts.turretRoad(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 19.sp, // Scalable font size
                ),
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: Colors.black87,
              iconTheme: const IconThemeData(color: Colors.white),
              leading: Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                  if (hasUnreadCouncillorMessages)
                    Positioned(
                      top: 8.h,
                      right: 7.w,
                      child: Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            drawer: const NavDrawer(),
            body: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      SizedBox(height: 30.h),
                      const ResponsiveLogo(),
                      SizedBox(height: 20.h),

                      // Property Selection Button
                      if (userProperties != null && userProperties!.length > 1)
                        ElevatedIconButton(
                          onPress: () async {
                            final selectedProperty = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PropertySelectionScreen(
                                      properties: userProperties!,
                                      userPhoneNumber: userPhoneNumber,
                                      isLocalMunicipality: widget
                                          .isLocalMunicipality,
                                    ),
                              ),
                            );

                            if (selectedProperty != null) {
                              setState(() {
                                currentProperty = selectedProperty;
                              });
                            }
                          },
                          labelText: 'Select\nProperty',
                          fSize: 18.sp,
                          faIcon: const FaIcon(FontAwesomeIcons.houseUser),
                          fgColor: Colors.deepPurple,
                          btSize: Size(130.w, 120.h),
                        ),

                      SizedBox(height: 20.h),

                      // Button Layout
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: MediaQuery
                            .of(context)
                            .size
                            .width < 600 ? 2 : 3,
                        // 2 columns on mobile, 3 on web
                        mainAxisSpacing: 20.h,
                        crossAxisSpacing: 20.w,
                        childAspectRatio: 1,
                        // Ensures square buttons
                        children: [

                          // Admin Chat
                          _buildButton(
                            label: 'Queries',
                            icon: FontAwesomeIcons.message,
                            color: Colors.blue,
                            size: Size(130.w, 120.h),
                            onTap: () async {
                              await _navigateToChat(context);
                            },
                            showBadge: hasUnreadMessages,
                            lockFeature: visLocked || visFeatureMode ||
                                visPremium, // 🔒 Lock this menu
                          ),

                          // View Details
                          _buildButton(
                            label: 'View \nDetails',
                            icon: FontAwesomeIcons.houseCircleExclamation,
                            color: Colors.green,
                            size: Size(130.w, 120.h),
                            onTap: () async {
                              await _navigateToViewDetails(context);
                            },
                          ),

                          // Notices
                          Consumer<NotificationProvider>(
                            builder: (context, notificationProvider, child) {
                              return _buildButton(
                                label: 'Notices',
                                icon: Icons.notifications_on,
                                color: Colors.red,
                                size: Size(130.w, 120.h),
                                onTap: () async {
                                  await _navigateToNotices(context);
                                },
                                showBadge: notificationProvider
                                    .hasUnreadNotices,
                                // ✅ Keeps the logic inside the Consumer
                                lockFeature: visLocked || visFeatureMode ||
                                    visPremium, // 🔒 Lock this menu
                              );
                            },
                          ),

                          // View Invoice
                          _buildButton(
                            label: 'View\nInvoice',
                            icon: FontAwesomeIcons.solidFilePdf,
                            color: Colors.redAccent,
                            size: Size(130.w, 120.h),
                            onTap: () async {
                              await _navigateToViewInvoice(context);
                            },
                            showBadge: hasUnreadFinanceMessages,
                          ),

                          // Logout
                          _buildButton(
                            label: 'Logout',
                            icon: Icons.logout,
                            color: Colors.red,
                            size: Size(130.w, 120.h),
                            onTap: () async {
                              await _handleLogout(context);
                            },
                          ),

                          // Report Faults
                          _buildButton(
                            label: 'Report \nFaults',
                            icon: Icons.report_problem,
                            color: Colors.orangeAccent,
                            size: Size(130.w, 120.h),
                            onTap: () async {
                              await _navigateToReportFault(context);
                            },
                            lockFeature: visLocked || visFeatureMode ||
                                visPremium, // 🔒 Lock this menu
                          ),
                        ],
                      ),

                      SizedBox(height: 30.h),

                      // Footer
                      Text(
                        'Copyright Cyberfox ',
                        style: GoogleFonts.saira(
                          color: Colors.white,
                          backgroundColor: Colors.white10,
                          fontWeight: FontWeight.normal,
                          fontStyle: FontStyle.italic,
                          fontSize: 16.sp,
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// **Reusable Button Builder**
  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    required Size size,
    required VoidCallback onTap,
    bool showBadge = false,
    bool lockFeature = false, // 🔒 Added Lock Feature Parameter
  }) {
    return Stack(
      children: [
        ElevatedIconButton(
          onPress: lockFeature
              ? () {
            Fluttertoast.showToast(
              msg: "Feature Locked!",
              gravity: ToastGravity.CENTER,
            );
          }
              : onTap,
          labelText: label,
          fSize: 17.sp,
          faIcon: FaIcon(
            icon,
            color: lockFeature
                ? Colors.grey.shade500
                : color, // Dim icon when locked
          ),
          fgColor: lockFeature ? Colors.grey.shade500 : color,
          // Dim text when locked
          btSize: size,
        ),
        if (lockFeature) // 🔒 Add small lock icon inside the button
          Positioned(
            top: size.height * 0.70,
            right: size.height*0.70,
            child: const Icon(
              Icons.lock,
              color: Colors.black,
              size: 22,
            ),
          ),
        if (showBadge) // 🔴 Show notification badge
          Positioned(
            right: 5,
            top: 5,
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: BoxConstraints(
                minWidth: 16.w,
                minHeight: 16.h,
              ),
              child: Text(
                '!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}


  void openPDF(BuildContext context, File file) => Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
    );

class ResponsiveLogo extends StatelessWidget {
  const ResponsiveLogo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the screen width and height
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Set a base logo size that scales based on the screen dimensions
    double logoWidth = screenWidth * 0.5; // Set to 50% of screen width
    double logoHeight =
        logoWidth * (687 / 550); // Maintain new aspect ratio (550x687)

    return Center(
      child: Container(
        width: logoWidth,
        height: logoHeight,
        child: FittedBox(
          fit: BoxFit.contain, // Ensures the image scales within the container
          child: Image.asset('assets/images/umdm.png'),
        ),
      ),
    );
  }
}
