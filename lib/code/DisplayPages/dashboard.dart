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
  StreamSubscription<QuerySnapshot>? unreadCouncilMessagesSubscription;
  bool hasUnreadFinanceMessages = false;
  bool hasUnreadCouncilMessages=false;

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
      checkForUnreadMessages();
      checkForUnreadFinanceMessages();

    });
    setupNotificationListener();
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
    unreadCouncilMessagesSubscription?.cancel();
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
    final selectedPropertyAccountNumber = prefs.getString('selectedPropertyAccountNo');

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
            print('Error: Unable to determine municipality type or IDs are missing.');
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
          print("Error: No property found for account number $selectedPropertyAccountNumber.");
        }
      } catch (e) {
        print("Error fetching property details: $e");
      }
    } else {
      print('Error: selectedPropertyAccountNumber is null');
    }
  }





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
    }, onDidReceiveBackgroundNotificationResponse: notificationTapBackground);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("..........onMessage..........");
      print(
          "onMessage: ${message.notification?.title}/${message.notification?.body}}");

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

  // bool visShow = true;
  // bool visHide = false;
  // bool visLocked = false;
  // bool visFeatureMode = false;
  // bool visPremium = true;
  //
  // List _allVersionResults = [];

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

  // void getVersionStream() async {
  //   try {
  //     var data = await FirebaseFirestore.instance.collection('version').get();
  //     if (mounted) {  // Check if the widget is still in the widget tree
  //       setState(() {
  //         _allVersionResults = data.docs;
  //       });
  //       getVersionDetails();  // Make sure any further method calls inside this block also respect the lifecycle
  //     }
  //   } catch (e) {
  //     print('Failed to fetch version data: $e');
  //   }
  // }
  // void getVersionStream() async {
  //   try {
  //     var data = await FirebaseFirestore.instance
  //         .collection('districts')
  //         .doc(widget.property.districtId)
  //         .collection('municipalities')
  //         .doc(widget.property.municipalityId)
  //         .collection('version')
  //         .get();
  //     if (mounted) {  // Check if the widget is still in the widget tree
  //       setState(() {
  //         _allVersionResults = data.docs;
  //       });
  //       getVersionDetails();  // Make sure any further method calls inside this block also respect the lifecycle
  //     }
  //   } catch (e) {
  //     print('Failed to fetch version data: $e');
  //   }
  // }

  // void getVersionDetails() async {
  //   String activeVersion = _allVersionResults[2]['version'].toString();
  //   var versionData = await FirebaseFirestore.instance.collection('version').doc('current').collection('current-version').where('version', isEqualTo: activeVersion).get();
  //   String currentVersion = versionData.docs[0].data()['version'];
  //
  //   for (var versionSnapshot in _allVersionResults) {
  //     var version = versionSnapshot['version'].toString();
  //
  //     if (currentVersion == version) {
  //       if (currentVersion == 'Unpaid') {
  //         visLocked = true;
  //         visFeatureMode = true;
  //         visPremium = true;
  //       } else if (currentVersion == 'Paid') {
  //         visLocked = false;
  //         visFeatureMode = false;
  //         visPremium = true;
  //       } else if (currentVersion == 'Premium') {
  //         visLocked = false;
  //         visFeatureMode = false;
  //         visPremium = false;
  //       }
  //     }
  //   }
  // }
  // void getVersionDetails() async {
  //   String activeVersion = _allVersionResults[2]['version'].toString();
  //   var versionData = await FirebaseFirestore.instance
  //       .collection('districts')
  //       .doc(widget.property.districtId)
  //       .collection('municipalities')
  //       .doc(widget.property.municipalityId)
  //       .collection('version')
  //       .doc('current')
  //       .collection('current-version')
  //       .where('version', isEqualTo: activeVersion)
  //       .get();
  //   String currentVersion = versionData.docs[0].data()['version'];
  //
  //   for (var versionSnapshot in _allVersionResults) {
  //     var version = versionSnapshot['version'].toString();
  //
  //     if (currentVersion == version) {
  //       if (currentVersion == 'Unpaid') {
  //         visLocked = true;
  //         visFeatureMode = true;
  //         visPremium = true;
  //       } else if (currentVersion == 'Paid') {
  //         visLocked = false;
  //         visFeatureMode = false;
  //         visPremium = true;
  //       } else if (currentVersion == 'Premium') {
  //         visLocked = false;
  //         visFeatureMode = false;
  //         visPremium = false;
  //       }
  //     }
  //   }
  // }
  Stream<bool> getUnreadMessagesStream(String userPhone, bool isCouncillor) {
    if (isCouncillor) {
      // Stream for councillors (messages sent to them)
      return FirebaseFirestore.instance
          .collectionGroup('chatRoomCouncillor')
          .snapshots()
          .asyncMap((snapshot) async {
        for (var councillorDoc in snapshot.docs) {
          QuerySnapshot userChatsSnapshot =
          await councillorDoc.reference.collection('userChats').get();

          for (var userChatDoc in userChatsSnapshot.docs) {
            QuerySnapshot unreadMessages = await userChatDoc.reference
                .collection('messages')
                .where('isReadByCouncillor', isEqualTo: false)
                .where('sendBy', isNotEqualTo: userPhone)
                .get();

            if (unreadMessages.docs.isNotEmpty) {
              return true; // Unread messages for the councillor
            }
          }
        }
        return false; // No unread messages
      });
    } else {
      // Stream for regular users (messages sent to them)
      return FirebaseFirestore.instance
          .collectionGroup('chatRoomCouncillor')
          .snapshots()
          .asyncMap((snapshot) async {
        for (var chatDoc in snapshot.docs) {
          QuerySnapshot unreadMessages = await chatDoc.reference
              .collection('messages')
              .where('isReadByUser', isEqualTo: false)
              .where('sendBy', isNotEqualTo: userPhone) // Check messages not sent by the user
              .get();

          if (unreadMessages.docs.isNotEmpty) {
            return true; // Unread messages for the regular user
          }
        }
        return false; // No unread messages
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    Get.put(LocationController());
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Determine whether the user is a councillor
    Future<bool> checkIfCouncillor() async {
      return await isUserCouncillor(
        user.phoneNumber!,
        municipalityId, // Pass the appropriate value
        districtId, // Pass the appropriate value
        isLocalMunicipality, // Pass the appropriate value
      );
    }

    return FutureBuilder<bool>(
        future: checkIfCouncillor(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        // Show a basic app bar while checking
        return AppBar(
          title: const Text('Loading...'),
          backgroundColor: Colors.black87,
        );
      }

      bool isCouncillor = snapshot.data!;

      return Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/greyscale.jpg"),
            fit: BoxFit.cover,
          ),
        ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Signed in from: ${user.phoneNumber!}',
            style: GoogleFonts.turretRoad(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 19,
            ),
          ),
          backgroundColor: Colors.black87,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: StreamBuilder<bool>(
            stream: getUnreadMessagesStream(user.phoneNumber!, isCouncillor),
            builder: (context, unreadSnapshot) {
              bool hasUnreadMessages = unreadSnapshot.data ?? false;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                  if (hasUnreadMessages)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: const Text(
                          '!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        drawer: NavDrawer(  userPhone: user.phoneNumber!, // Pass the user's phone number
          isCouncillor: isCouncillor,),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Column(
                children: <Widget>[
                  const SizedBox(height: 30),
                  const ResponsiveLogo(),
                  const SizedBox(height: 20),
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
                      fSize: 18,
                      faIcon: const FaIcon(FontAwesomeIcons.houseUser),
                      fgColor: Colors.deepPurple,
                      btSize: const Size(130, 120),
                    ),
                  Column(
                    children: [
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  ElevatedIconButton(
                                    onPress: () async {
                                      SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                      String? selectedPropertyAccountNumber =
                                      prefs.getString(
                                          'selectedPropertyAccountNo');

                                      if (selectedPropertyAccountNumber ==
                                          null) {
                                        print(
                                            'Error: selectedPropertyAccountNumber is null.');
                                        return;
                                      }

                                      try {
                                        QuerySnapshot
                                        localMunicipalitySnapshot =
                                        await FirebaseFirestore.instance
                                            .collectionGroup('properties')
                                            .where('accountNumber',
                                            isEqualTo:
                                            selectedPropertyAccountNumber)
                                            .get();

                                        if (localMunicipalitySnapshot
                                            .docs.isNotEmpty) {
                                          DocumentSnapshot propertyDoc =
                                              localMunicipalitySnapshot
                                                  .docs.first;
                                          bool isLocalMunicipality = propertyDoc
                                              .get('isLocalMunicipality');
                                          String municipalityId =
                                          propertyDoc.get('municipalityId');
                                          String? districtId = propertyDoc
                                              .data()
                                              .toString()
                                              .contains('districtId')
                                              ? propertyDoc.get('districtId')
                                              : null;
                                          String phoneNumber =
                                          propertyDoc.get('cellNumber');

                                          CollectionReference<Object?>?
                                          chatCollectionRef;
                                          if (isLocalMunicipality) {
                                            chatCollectionRef =
                                                FirebaseFirestore.instance
                                                    .collection(
                                                    'localMunicipalities')
                                                    .doc(municipalityId)
                                                    .collection('chatRoom');
                                          } else if (districtId != null) {
                                            chatCollectionRef =
                                                FirebaseFirestore
                                                    .instance
                                                    .collection('districts')
                                                    .doc(districtId)
                                                    .collection(
                                                    'municipalities')
                                                    .doc(municipalityId)
                                                    .collection('chatRoom');
                                          }

                                          if (chatCollectionRef != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    Chat(
                                                      chatRoomId: phoneNumber,
                                                      userName:
                                                      selectedPropertyAccountNumber,
                                                      chatCollectionRef:
                                                      chatCollectionRef!,
                                                      refreshChatList:
                                                      checkForUnreadMessages,
                                                      // Callback to refresh badge
                                                      isLocalMunicipality:
                                                      isLocalMunicipality,
                                                      districtId: districtId ??
                                                          '',
                                                      municipalityId:
                                                      municipalityId,
                                                    ),
                                              ),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        print(
                                            'Error retrieving property details: $e');
                                      }
                                    },
                                    labelText: 'Admin \nChat',
                                    fSize: 18,
                                    faIcon:
                                    const FaIcon(FontAwesomeIcons.message),
                                    fgColor: Colors.blue,
                                    btSize: const Size(130, 120),
                                  ),
                                  if (hasUnreadMessages)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: const Text(
                                          '!',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 40),
                            Expanded(
                              child: ElevatedIconButton(
                                onPress: () async {
                                  // Fetch selected property information, especially for local municipality
                                  if (currentProperty.isLocalMunicipality) {
                                    // Local municipality logic
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            UsersTableViewPage(
                                              property: currentProperty,
                                              userNumber: currentProperty
                                                  .cellNum,
                                              accountNumber:
                                              currentProperty.accountNo,
                                              propertyAddress:
                                              currentProperty.address,
                                              districtId:
                                              '',
                                              // No districtId for local municipalities
                                              municipalityId:
                                              currentProperty.municipalityId,
                                              isLocalMunicipality: currentProperty
                                                  .isLocalMunicipality,
                                            ),
                                      ),
                                    );
                                  } else {
                                    // District-based municipality logic
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            UsersTableViewPage(
                                              property: currentProperty,
                                              userNumber: currentProperty
                                                  .cellNum,
                                              accountNumber:
                                              currentProperty.accountNo,
                                              propertyAddress:
                                              currentProperty.address,
                                              districtId:
                                              currentProperty.districtId,
                                              municipalityId:
                                              currentProperty.municipalityId,
                                              isLocalMunicipality: currentProperty
                                                  .isLocalMunicipality,
                                            ),
                                      ),
                                    );
                                  }
                                },
                                labelText: 'View \nDetails',
                                fSize: 18,
                                faIcon: const FaIcon(
                                    FontAwesomeIcons.houseCircleExclamation),
                                fgColor: Colors.green,
                                btSize: const Size(130, 120),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Consumer<NotificationProvider>(
                                builder:
                                    (context, notificationProvider, child) {
                                  return Stack(
                                    children: [
                                      ElevatedIconButton(
                                        onPress: () async {
                                          // Fetch the selected property account number from SharedPreferences
                                          SharedPreferences prefs =
                                          await SharedPreferences
                                              .getInstance();
                                          String?
                                          selectedPropertyAccountNumber =
                                          prefs.getString(
                                              'selectedPropertyAccountNo');

                                          // Check if the account number exists
                                          if (selectedPropertyAccountNumber ==
                                              null) {
                                            print(
                                                'Error: selectedPropertyAccountNumber is null.');
                                            Fluttertoast.showToast(
                                                msg: "No property selected.");
                                            return;
                                          }

                                          try {
                                            // Search for the property in both localMunicipalities and district properties
                                            QuerySnapshot propertySnapshot =
                                            await FirebaseFirestore.instance
                                                .collectionGroup(
                                                'properties')
                                                .where('accountNumber',
                                                isEqualTo:
                                                selectedPropertyAccountNumber)
                                                .get();

                                            if (propertySnapshot
                                                .docs.isNotEmpty) {
                                              DocumentSnapshot propertyDoc =
                                                  propertySnapshot.docs.first;

                                              // Retrieve the 'isLocalMunicipality', 'municipalityId', and 'districtId' (if applicable)
                                              bool isLocalMunicipality =
                                              propertyDoc.get(
                                                  'isLocalMunicipality')
                                              as bool;
                                              String municipalityId =
                                              propertyDoc
                                                  .get('municipalityId')
                                              as String;
                                              String? districtId = propertyDoc
                                                  .data()
                                                  .toString()
                                                  .contains('districtId')
                                                  ? propertyDoc.get(
                                                  'districtId') as String
                                                  : null;

                                              // Pass the correct data to the NoticeScreen based on whether it's a local or district property
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      NoticeScreen(
                                                        selectedPropertyAccountNumber:
                                                        selectedPropertyAccountNumber,
                                                        isLocalMunicipality:
                                                        isLocalMunicipality,
                                                        municipalityId:
                                                        municipalityId,
                                                        districtId:
                                                        districtId, // Can be null for local municipalities
                                                      ),
                                                ),
                                              );
                                            } else {
                                              print(
                                                  'Error: No property found for account number $selectedPropertyAccountNumber.');
                                              Fluttertoast.showToast(
                                                  msg:
                                                  "No property found for selected account.");
                                            }
                                          } catch (e) {
                                            print(
                                                'Error retrieving property details: $e');
                                            Fluttertoast.showToast(
                                                msg:
                                                "Failed to load property details.");
                                          }
                                        },
                                        labelText: 'Notices',
                                        fSize: 16.5,
                                        faIcon: const FaIcon(
                                            Icons.notifications_on),
                                        fgColor: Colors.red,
                                        btSize: const Size(130, 120),
                                      ),
                                      // Show notification badge if there are unread notices
                                      if (notificationProvider.hasUnreadNotices)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius
                                                  .circular(8),
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),
                                            child: const Text(
                                              '!',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 40),
                            Expanded(
                              child: Stack(
                                children: [
                                  ElevatedIconButton(
                                    onPress: () async {
                                      // Fetch selected property account number from SharedPreferences
                                      SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                      String? selectedPropertyAccountNumber =
                                      prefs.getString(
                                          'selectedPropertyAccountNo');

                                      // Check if the account number exists
                                      if (selectedPropertyAccountNumber ==
                                          null) {
                                        print(
                                            'Error: selectedPropertyAccountNumber is null.');
                                        Fluttertoast.showToast(
                                            msg: "No property selected.");
                                        return;
                                      }

                                      try {
                                        // Search for the property in both localMunicipalities and district properties
                                        QuerySnapshot propertySnapshot =
                                        await FirebaseFirestore.instance
                                            .collectionGroup('properties')
                                            .where('accountNumber',
                                            isEqualTo:
                                            selectedPropertyAccountNumber)
                                            .get();

                                        if (propertySnapshot.docs.isNotEmpty) {
                                          DocumentSnapshot propertyDoc =
                                              propertySnapshot.docs.first;

                                          // Retrieve the 'isLocalMunicipality', 'municipalityId', and 'districtId' (if applicable)
                                          bool isLocalMunicipality = propertyDoc
                                              .get('isLocalMunicipality')
                                          as bool;
                                          String municipalityId = propertyDoc
                                              .get('municipalityId') as String;
                                          String? districtId = propertyDoc
                                              .data()
                                              .toString()
                                              .contains('districtId')
                                              ? propertyDoc.get('districtId')
                                          as String
                                              : null;

                                          // Pass the correct data to the UsersPdfListViewPage based on whether it's a local or district property
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  UsersPdfListViewPage(
                                                    userNumber: propertyDoc
                                                        .get('cellNumber'),
                                                    propertyAddress:
                                                    propertyDoc.get('address'),
                                                    accountNumber: propertyDoc
                                                        .get('accountNumber'),
                                                    isLocalMunicipality:
                                                    isLocalMunicipality,
                                                    municipalityId: municipalityId,
                                                    districtId:
                                                    districtId, // Can be null for local municipalities
                                                  ),
                                            ),
                                          );
                                        } else {
                                          print(
                                              'Error: No property found for account number $selectedPropertyAccountNumber.');
                                          Fluttertoast.showToast(
                                              msg:
                                              "No property found for selected account.");
                                        }
                                      } catch (e) {
                                        print(
                                            'Error retrieving property details: $e');
                                        Fluttertoast.showToast(
                                            msg:
                                            "Failed to load property details.");
                                      }
                                    },
                                    labelText: 'View\nInvoice',
                                    fSize: 18,
                                    faIcon: const FaIcon(
                                        FontAwesomeIcons.solidFilePdf),
                                    fgColor: Colors.redAccent,
                                    btSize: const Size(130, 120),
                                  ),
                                  if (hasUnreadFinanceMessages)
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: const Text(
                                          '!',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ElevatedIconButton(
                              onPress: () {
                                showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(18))),
                                      title: const Text("Logout"),
                                      content: const Text(
                                          "Are you sure you want to logout?"),
                                      actions: [
                                        IconButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          icon: const Icon(Icons.cancel,
                                              color: Colors.red),
                                        ),
                                        IconButton(
                                          onPressed: () async {
                                            await FirebaseAuth.instance
                                                .signOut();
                                            Navigator.pop(context);
                                          },
                                          icon: const Icon(Icons.done,
                                              color: Colors.green),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              labelText: 'Logout',
                              fSize: 18,
                              faIcon: const FaIcon(Icons.logout),
                              fgColor: Colors.red,
                              btSize: const Size(130, 120),
                            ),
                            const SizedBox(width: 40),
                            ElevatedIconButton(
                              onPress: () {
                                if (currentProperty != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          WaterSanitationReportMenu(
                                            currentProperty: currentProperty,
                                            isLocalMunicipality:
                                            currentProperty.isLocalMunicipality,
                                            municipalityId:
                                            currentProperty.municipalityId,
                                            districtId: currentProperty
                                                .isLocalMunicipality
                                                ? null
                                                : currentProperty
                                                .districtId, // null if local
                                          ),
                                    ),
                                  );
                                } else {
                                  print('Error: No property selected.');
                                  Fluttertoast.showToast(
                                      msg: "No property selected.");
                                }
                              },
                              labelText: 'Report \nFaults',
                              fSize: 17,
                              faIcon: const FaIcon(Icons.report_problem),
                              fgColor: Colors.orangeAccent,
                              btSize: const Size(130, 120),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            'Copyright Cyberfox ',
                            style: GoogleFonts.saira(
                              color: Colors.white,
                              backgroundColor: Colors.white10,
                              fontWeight: FontWeight.normal,
                              fontStyle: FontStyle.italic,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
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
    double logoHeight = logoWidth * (687 / 550); // Maintain new aspect ratio (550x687)

    return Center(
      child: Container(
        width: logoWidth,
        height: logoHeight,
        child: FittedBox(
          fit: BoxFit.contain,  // Ensures the image scales within the container
          child: Image.asset('assets/images/umdm.png'),
        ),
      ),
    );
  }
}