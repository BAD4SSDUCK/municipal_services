import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:municipal_services/code/Chat/chat_screen.dart' as chat;
import 'package:municipal_services/code/Chat/chat_screen_finance.dart'
    as finance;
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';
import 'package:municipal_services/code/Chat/chat_screen.dart' as regularChat;
import 'package:municipal_services/code/Chat/chat_screen_finance.dart' as financeChat;
import '../Models/notify_provider.dart';
import 'chat_screen.dart';
import 'chat_screen_finance.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatList extends StatefulWidget {
  const ChatList({super.key, });

  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> with TickerProviderStateMixin {
  CollectionReference? _chatsList;
  CollectionReference? _chatsListFinance;
  CollectionReference? _userList;
  CollectionReference? _propList;
  List<Map<String, dynamic>> _filteredChatList = [];
  List<Map<String, dynamic>> _filteredProperties = [];
  List<Map<String, dynamic>> _filteredFinanceProperties = [];
  List<Map<String, dynamic>> _filteredFinanceChatList = [];
  List<Map<String, dynamic>> _allChats = [];
  List<Map<String, dynamic>> _allFinanceChats = [];
  String districtId = '';
  String municipalityId = '';
  final searchController = TextEditingController();
  final financeSearchController = TextEditingController();
  bool _isLoading = true;
  bool isLocalMunicipality = false;
  Timer? _timer;
  bool hasUnreadUserMessages = false;
  bool isLocalUser = false;
  bool hasUnreadFinanceMessages = false;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _userChatScrollController = ScrollController();
  final ScrollController _financeChatScrollController = ScrollController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    print("TabController initialized");

    _tabController.addListener(() {
      print("Current Tab Index: ${_tabController.index}");
      if (_tabController.index == 1) {
        print("Switched to Payment Queries tab");
        setState(() {}); // Rebuild for Payment Queries
      }
    });

    initializeData();
    searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    financeSearchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    _userChatScrollController.dispose();
    _financeChatScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }


  Future<void> initializeData() async {
    await fetchUserDetails();
    await fetchAndStoreAllChats();
    await fetchAndStoreAllFinanceChats();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchUserDetails() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collectionGroup('users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          var userDoc = userSnapshot.docs.first;
          final userPathSegments = userDoc.reference.path.split('/');

          // Determine if the user belongs to a district or local municipality
          if (userPathSegments[0] == 'districts') {
            // District municipality user
            districtId = userPathSegments[1];
            municipalityId = userPathSegments[3];
            isLocalMunicipality = false;
            isLocalUser = userDoc.get('isLocalUser') ?? false;

            if (isLocalUser) {
              // If the user is a district-level user, fetch all chats across municipalities
              await fetchAndStoreAllChats();
              await fetchAndStoreAllFinanceChats(); // Call the method to fetch all chats in the district
            } else {
              // Municipality-level user within a district
              _chatsList = FirebaseFirestore.instance
                  .collection('districts')
                  .doc(districtId)
                  .collection('municipalities')
                  .doc(municipalityId)
                  .collection('chatRoom');

              _chatsListFinance = FirebaseFirestore.instance
                  .collection('districts')
                  .doc(districtId)
                  .collection('municipalities')
                  .doc(municipalityId)
                  .collection('chatRoomFinance');

              _propList = FirebaseFirestore.instance
                  .collection('districts')
                  .doc(districtId)
                  .collection('municipalities')
                  .doc(municipalityId)
                  .collection('properties');
            }
          } else if (userPathSegments[0] == 'localMunicipalities') {
            // Local municipality user
            municipalityId = userPathSegments[1];
            isLocalMunicipality = true;
            isLocalUser = true;

            _chatsList = FirebaseFirestore.instance
                .collection('localMunicipalities')
                .doc(municipalityId)
                .collection('chatRoom');

            _chatsListFinance = FirebaseFirestore.instance
                .collection('localMunicipalities')
                .doc(municipalityId)
                .collection('chatRoomFinance');

            _propList = FirebaseFirestore.instance
                .collection('localMunicipalities')
                .doc(municipalityId)
                .collection('properties');
          }

          if (mounted) {
            setState(() {
              print(
                  'Chat and property references initialized for ${isLocalMunicipality ? 'local' : 'district'} municipality.');
            });
          }

          // Fetch specific chat rooms if it's a non-district-level user (local municipality or specific municipality within a district)
          if (!isLocalUser) {
            await fetchAndGroupChats();
            await fetchAndGroupFinanceChats();
          }
        } else {
          print("No user document found for the provided email.");
        }
      } else {
        print("No current user found.");
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  Future<void> fetchAndStoreAllChats() async {
    try {
      print("Fetching all chats across municipalities within the district");

      QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
          .collectionGroup('chatRoom')
          .get();

      List<Map<String, dynamic>> allChats = [];
      Map<String, List<String>> utilityTypeCache = {};

      for (var chatDoc in chatSnapshot.docs) {
        String phoneNumber = chatDoc.id;
        String? municipalityId = chatDoc.reference.parent.parent?.id;

        if (municipalityId == null) continue;

        // Get utilityType from cache or Firestore
        if (!utilityTypeCache.containsKey(municipalityId)) {
          final municipalitySnap = await FirebaseFirestore.instance
              .collection('districts')
              .doc(districtId)
              .collection('municipalities')
              .doc(municipalityId)
              .get();

          final utilityType = List<String>.from(municipalitySnap.get('utilityType') ?? []);
          utilityTypeCache[municipalityId] = utilityType;
        }

        final currentUtilityType = utilityTypeCache[municipalityId]!;

        QuerySnapshot accountsSnapshot = await chatDoc.reference.collection('accounts').get();

        for (var accountDoc in accountsSnapshot.docs) {
          String accountNumber = accountDoc.id;
          String? matchedField;
          QuerySnapshot propertySnapshot;

          // Match based on utility type
          if (currentUtilityType.contains('water') && !currentUtilityType.contains('electricity')) {
            matchedField = 'accountNumber';
            propertySnapshot = await FirebaseFirestore.instance
                .collection('districts')
                .doc(districtId)
                .collection('municipalities')
                .doc(municipalityId)
                .collection('properties')
                .where('accountNumber', isEqualTo: accountNumber)
                .limit(1)
                .get();
          } else if (!currentUtilityType.contains('water') && currentUtilityType.contains('electricity')) {
            matchedField = 'electricityAccountNumber';
            propertySnapshot = await FirebaseFirestore.instance
                .collection('districts')
                .doc(districtId)
                .collection('municipalities')
                .doc(municipalityId)
                .collection('properties')
                .where('electricityAccountNumber', isEqualTo: accountNumber)
                .limit(1)
                .get();
          } else {
            // Handles both
            propertySnapshot = await FirebaseFirestore.instance
                .collection('districts')
                .doc(districtId)
                .collection('municipalities')
                .doc(municipalityId)
                .collection('properties')
                .where('accountNumber', isEqualTo: accountNumber)
                .limit(1)
                .get();

            if (propertySnapshot.docs.isNotEmpty) {
              matchedField = 'accountNumber';
            } else {
              propertySnapshot = await FirebaseFirestore.instance
                  .collection('districts')
                  .doc(districtId)
                  .collection('municipalities')
                  .doc(municipalityId)
                  .collection('properties')
                  .where('electricityAccountNumber', isEqualTo: accountNumber)
                  .limit(1)
                  .get();
              if (propertySnapshot.docs.isNotEmpty) {
                matchedField = 'electricityAccountNumber';
              }
            }
          }

          if (propertySnapshot.docs.isEmpty) {
            print("❌ No property found for: $accountNumber in $municipalityId");
            continue;
          }

          var propertyData = propertySnapshot.docs.first.data() as Map<String, dynamic>;

          // Fetch unread and latest messages
          QuerySnapshot unreadMessagesSnapshot = await accountDoc.reference
              .collection('chats')
              .where('isReadByMunicipalUser', isEqualTo: false)
              .where('sendBy', isNotEqualTo: FirebaseAuth.instance.currentUser?.phoneNumber)
              .get();

          QuerySnapshot latestMessageSnapshot = await accountDoc.reference
              .collection('chats')
              .orderBy('time', descending: true)
              .limit(1)
              .get();

          bool hasUnreadMessages = unreadMessagesSnapshot.docs.isNotEmpty;

          String latestMessage = latestMessageSnapshot.docs.isNotEmpty
              ? latestMessageSnapshot.docs.first['message']
              : "No messages yet.";

          dynamic latestMessageTime = latestMessageSnapshot.docs.isNotEmpty
              ? latestMessageSnapshot.docs.first['time']
              : 0;

          allChats.add({
            'chatRoomId': phoneNumber,
            'municipalityId': municipalityId,
            'accountNumber': accountNumber,
            'matchedAccountField': matchedField ?? '',
            'firstName': propertyData['firstName'] ?? 'Unknown',
            'lastName': propertyData['lastName'] ?? '',
            'address': propertyData['address'] ?? 'Unknown',
            'phoneNumber': phoneNumber,
            'hasUnreadMessages': hasUnreadMessages,
            'latestMessage': latestMessage,
            'latestMessageTime': latestMessageTime,
          });
        }
      }

      // Sort by latest message time
      allChats.sort((a, b) =>
          (b['latestMessageTime'] ?? 0).compareTo(a['latestMessageTime'] ?? 0));

      if (mounted) {
        setState(() {
          _allChats = allChats;
        });
      }

      print("✅ All general chats fetched: ${_allChats.length}");
    } catch (e) {
      print("❌ Error fetching general chats: $e");
    }
  }

  Future<void> fetchAndStoreAllFinanceChats() async {
    try {
      List<Map<String, dynamic>> allFinanceChats = [];

      if (!isLocalMunicipality) {
        // 1. Fetch all municipalities under the district
        QuerySnapshot municipalitiesSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .get();

        for (var municipalityDoc in municipalitiesSnapshot.docs) {
          String currentMunicipalityId = municipalityDoc.id;

          // 2. Get utilityType array
          List<dynamic> utilityType = municipalityDoc.get('utilityType') ?? [];
          bool handlesWater = utilityType.contains('water');
          bool handlesElectricity = utilityType.contains('electricity');

          // 3. Access chatRoomFinance
          CollectionReference chatRoomFinanceRef = FirebaseFirestore.instance
              .collection('districts')
              .doc(districtId)
              .collection('municipalities')
              .doc(currentMunicipalityId)
              .collection('chatRoomFinance');

          QuerySnapshot chatRoomDocs = await chatRoomFinanceRef.get();
          print("Fetched ${chatRoomDocs.docs.length} finance chat documents");

          for (var chatRoomDoc in chatRoomDocs.docs) {
            String phoneNumber = chatRoomDoc.id;

            QuerySnapshot accountsSnapshot = await chatRoomDoc.reference
                .collection('accounts')
                .get();

            for (var accountDoc in accountsSnapshot.docs) {
              String accountId = accountDoc.id;
              String? matchedField;
              QuerySnapshot propSnapshot;

              // 4. Determine which field to match
              if (handlesWater && !handlesElectricity) {
                matchedField = 'accountNumber';
                propSnapshot = await FirebaseFirestore.instance
                    .collection('districts')
                    .doc(districtId)
                    .collection('municipalities')
                    .doc(currentMunicipalityId)
                    .collection('properties')
                    .where('accountNumber', isEqualTo: accountId)
                    .get();
              } else if (!handlesWater && handlesElectricity) {
                matchedField = 'electricityAccountNumber';
                propSnapshot = await FirebaseFirestore.instance
                    .collection('districts')
                    .doc(districtId)
                    .collection('municipalities')
                    .doc(currentMunicipalityId)
                    .collection('properties')
                    .where('electricityAccountNumber', isEqualTo: accountId)
                    .get();
              } else {
                // Handles both
                propSnapshot = await FirebaseFirestore.instance
                    .collection('districts')
                    .doc(districtId)
                    .collection('municipalities')
                    .doc(currentMunicipalityId)
                    .collection('properties')
                    .where('accountNumber', isEqualTo: accountId)
                    .get();

                if (propSnapshot.docs.isEmpty) {
                  propSnapshot = await FirebaseFirestore.instance
                      .collection('districts')
                      .doc(districtId)
                      .collection('municipalities')
                      .doc(currentMunicipalityId)
                      .collection('properties')
                      .where('electricityAccountNumber', isEqualTo: accountId)
                      .get();

                  matchedField = 'electricityAccountNumber';
                } else {
                  matchedField = 'accountNumber';
                }
              }

              if (propSnapshot.docs.isEmpty) {
                print("No properties found for $accountId = $accountId under chat document: $phoneNumber");
                continue;
              }

              var propertyData = propSnapshot.docs.first.data() as Map<String, dynamic>;

              propertyData['chatRoomId'] = phoneNumber;
              propertyData['accountNumber'] = accountId;
              propertyData['municipalityId'] = currentMunicipalityId;
              propertyData['matchedAccountField'] = matchedField;

              // Get unread messages
              QuerySnapshot unreadMessagesSnapshot = await accountDoc.reference
                  .collection('chats')
                  .where('isReadByMunicipalUser', isEqualTo: false)
                  .where('sendBy', isNotEqualTo: FirebaseAuth.instance.currentUser?.phoneNumber)
                  .get();

              // Get latest message
              QuerySnapshot latestMessageSnapshot = await accountDoc.reference
                  .collection('chats')
                  .orderBy('time', descending: true)
                  .limit(1)
                  .get();

              bool hasUnreadMessages = unreadMessagesSnapshot.docs.isNotEmpty;
              propertyData['hasUnreadMessages'] = hasUnreadMessages;

              if (latestMessageSnapshot.docs.isNotEmpty) {
                var latestMessageData = latestMessageSnapshot.docs.first.data() as Map<String, dynamic>?;
                propertyData['latestMessageTime'] = latestMessageData?['time'] ?? 0;
                propertyData['latestMessage'] = latestMessageData?['message'] ?? "No messages yet.";
              }

              allFinanceChats.add(propertyData);
            }
          }
        }

        // Sort by latest message time
        allFinanceChats.sort((a, b) =>
            (b['latestMessageTime'] ?? 0).compareTo(a['latestMessageTime'] ?? 0));

        if (mounted) {
          setState(() {
            _allFinanceChats = allFinanceChats;
          });
        }

        print("All finance chats set in state: $_allFinanceChats");
      }
    } catch (e) {
      print("Error fetching finance chats: $e");
    }
  }

  Future<void> fetchAndGroupChats() async {
    try {
      List<Map<String, dynamic>> allPropertiesWithMessages = [];
      Map<String, List<String>> utilityTypeCache = {};

      if (!isLocalMunicipality) {
        // Fetch all municipalities under the specified district
        QuerySnapshot municipalitiesSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .get();

        for (var municipalityDoc in municipalitiesSnapshot.docs) {
          String currentMunicipalityId = municipalityDoc.id;

          // Fetch and cache utilityType
          if (!utilityTypeCache.containsKey(currentMunicipalityId)) {
            DocumentSnapshot utilSnap = await FirebaseFirestore.instance
                .collection('districts')
                .doc(districtId)
                .collection('municipalities')
                .doc(currentMunicipalityId)
                .get();

            List<String> utilityTypes = List<String>.from(utilSnap.get('utilityType') ?? []);
            utilityTypeCache[currentMunicipalityId] = utilityTypes;
          }

          final currentUtilityType = utilityTypeCache[currentMunicipalityId]!;
          String matchedAccountField = 'accountNumber';
          if (currentUtilityType.contains('electricity') && !currentUtilityType.contains('water')) {
            matchedAccountField = 'electricityAccountNumber';
          }

          CollectionReference chatsCollection = FirebaseFirestore.instance
              .collection('districts')
              .doc(districtId)
              .collection('municipalities')
              .doc(currentMunicipalityId)
              .collection('chatRoom');

          QuerySnapshot chatRoomSnapshot = await chatsCollection.get();

          for (var phoneNumberDoc in chatRoomSnapshot.docs) {
            String phoneNumber = phoneNumberDoc.id;

            QuerySnapshot accountsSnapshot =
            await phoneNumberDoc.reference.collection('accounts').get();

            for (var accountDoc in accountsSnapshot.docs) {
              String accountNumber = accountDoc.id;

              // Match property using the correct field
              QuerySnapshot propSnapshot = await FirebaseFirestore.instance
                  .collection('districts')
                  .doc(districtId)
                  .collection('municipalities')
                  .doc(currentMunicipalityId)
                  .collection('properties')
                  .where(matchedAccountField, isEqualTo: accountNumber)
                  .limit(1)
                  .get();

              if (propSnapshot.docs.isNotEmpty) {
                Map<String, dynamic> propertyData =
                propSnapshot.docs.first.data() as Map<String, dynamic>;

                propertyData['phoneNumber'] = phoneNumber;
                propertyData['accountNumber'] = accountNumber;
                propertyData['matchedAccountField'] = matchedAccountField;
                propertyData['municipalityId'] = currentMunicipalityId;

                // Fetch unread status and latest message
                QuerySnapshot unreadMessagesSnapshot = await accountDoc.reference
                    .collection('chats')
                    .where('isRead', isEqualTo: false)
                    .get();

                QuerySnapshot latestMessageSnapshot = await accountDoc.reference
                    .collection('chats')
                    .orderBy('time', descending: true)
                    .limit(1)
                    .get();

                propertyData['hasUnreadMessages'] = unreadMessagesSnapshot.docs.isNotEmpty;

                if (latestMessageSnapshot.docs.isNotEmpty) {
                  Map<String, dynamic> latestMessage =
                  latestMessageSnapshot.docs.first.data() as Map<String, dynamic>;

                  propertyData['latestMessage'] = latestMessage['message'] ?? 'No messages yet.';
                  propertyData['latestMessageTime'] = latestMessage['time'] ?? 0;
                }

                allPropertiesWithMessages.add(propertyData);
                print('✅ Grouped property with $matchedAccountField: $accountNumber for $phoneNumber');
              } else {
                print('⚠️ No matching property for $matchedAccountField: $accountNumber in $currentMunicipalityId');
              }
            }
          }
        }

        // Sort by latest message time
        allPropertiesWithMessages.sort((a, b) =>
            (b['latestMessageTime'] ?? 0).compareTo(a['latestMessageTime'] ?? 0));

        if (mounted) {
          setState(() {
            _filteredProperties = allPropertiesWithMessages;
          });
        }
      }
    } catch (e) {
      print('❌ Error fetching or grouping chats: $e');
      if (mounted) {
        setState(() {
          _filteredProperties = [];
        });
      }
    }
  }

  void markMessagesAsReadForMunicipalUser(String phoneNumber, String accountNumber) async {
    CollectionReference chatsCollection = isLocalMunicipality
        ? FirebaseFirestore.instance
        .collection('localMunicipalities')
        .doc(municipalityId)
        .collection('chatRoom')
        .doc(phoneNumber)
        .collection('accounts')
        .doc(accountNumber)
        .collection('chats')
        : FirebaseFirestore.instance
        .collection('districts')
        .doc(districtId)
        .collection('municipalities')
        .doc(municipalityId)
        .collection('chatRoom')
        .doc(phoneNumber)
        .collection('accounts')
        .doc(accountNumber)
        .collection('chats');

    QuerySnapshot unreadMessagesSnapshot = await chatsCollection.where('isRead', isEqualTo: false).get();
    for (var doc in unreadMessagesSnapshot.docs) {
      if (doc['sendBy'] != regularChat.userEmail) {
        await doc.reference.update({'isRead': true});
      }
    }
    // Immediately update the specific chat entry
    if (mounted) {
      setState(() {
        // Find and update the specific chat entry without refetching everything
        _allChats = _allChats.map((chat) {

          if (chat['phoneNumber'] == phoneNumber && accountNumber== accountNumber) {
            chat['hasUnreadMessages'] = false;
          }
          return chat;
        }).toList();

      });
    }
  }

  void markFinanceMessagesAsReadForMunicipalUser(String phoneNumber, String accountNumber) async {
    CollectionReference financeChatsCollection = isLocalMunicipality
        ? FirebaseFirestore.instance
        .collection('localMunicipalities')
        .doc(municipalityId)
        .collection('chatRoomFinance')
        .doc(phoneNumber)
        .collection('accounts')
        .doc(accountNumber)
        .collection('chats')
        : FirebaseFirestore.instance
        .collection('districts')
        .doc(districtId)
        .collection('municipalities')
        .doc(municipalityId)
        .collection('chatRoomFinance')
        .doc(phoneNumber)
        .collection('accounts')
        .doc(accountNumber)
        .collection('chats');

    QuerySnapshot unreadMessagesSnapshot = await financeChatsCollection
        .where('isReadByMunicipalUser', isEqualTo: false)
        .get();

    for (var doc in unreadMessagesSnapshot.docs) {
      if (doc['sendBy'] != FirebaseAuth.instance.currentUser?.phoneNumber) {
        await doc.reference.update({'isReadByMunicipalUser': true});
      }
    }

    // Immediately update the specific finance chat entry
    if (mounted) {
      setState(() {
        _allFinanceChats = _allFinanceChats.map((chat) {

          if (chat['phoneNumber'] == phoneNumber && accountNumber == accountNumber) {
            chat['hasUnreadMessages'] = false;
          }
          return chat;
        }).toList();

      });
    }
  }

  List<Map<String, dynamic>> _filterFinancePropertiesBySearch() {
    final searchLower = financeSearchController.text.toLowerCase();

    if (searchLower.isEmpty) {
      return _filteredFinanceProperties; // Return all properties if no search term
    }

    // Filter the properties based on the search term
    return _filteredFinanceProperties.where((property) {
      final String usersName =
          '${property['firstName'] ?? ''} ${property['lastName'] ?? ''}'
              .toLowerCase();
      final String usersProperty = (property['address'] ?? '').toLowerCase();
      final String accountNumber =
          (property['accountNumber'] ?? '').toLowerCase();

      return usersName.contains(searchLower) ||
          usersProperty.contains(searchLower) ||
          accountNumber.contains(searchLower);
    }).toList();
  }

  Future<void> fetchAndGroupFinanceChats() async {
    try {
      QuerySnapshot chatRoomSnapshot = await _chatsListFinance!.get();

      if (chatRoomSnapshot.docs.isEmpty) {
        print("No finance chat rooms found.");
        if (mounted) {
          setState(() {
            _filteredFinanceProperties = [];
          });
        }
        return;
      }

      print("Total finance chat rooms fetched: ${chatRoomSnapshot.docs.length}");

      List<Map<String, dynamic>> financePropertiesWithMessages = [];
      Map<String, List<String>> utilityTypeCache = {}; // Cache utilityType per municipality

      if (!isLocalMunicipality) {
        // Fetch all municipalities under the specified district
        QuerySnapshot municipalitiesSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .get();

        for (var municipalityDoc in municipalitiesSnapshot.docs) {
          String currentMunicipalityId = municipalityDoc.id;

          // Fetch and cache utilityType
          if (!utilityTypeCache.containsKey(currentMunicipalityId)) {
            DocumentSnapshot utilSnap = await FirebaseFirestore.instance
                .collection('districts')
                .doc(districtId)
                .collection('municipalities')
                .doc(currentMunicipalityId)
                .get();

            List<String> utilityTypes = List<String>.from(utilSnap.get('utilityType') ?? []);
            utilityTypeCache[currentMunicipalityId] = utilityTypes;
          }

          final currentUtilityType = utilityTypeCache[currentMunicipalityId]!;
          String matchedAccountField = 'accountNumber';
          if (currentUtilityType.contains('electricity') && !currentUtilityType.contains('water')) {
            matchedAccountField = 'electricityAccountNumber';
          }

          CollectionReference chatsCollection = FirebaseFirestore.instance
              .collection('districts')
              .doc(districtId)
              .collection('municipalities')
              .doc(currentMunicipalityId)
              .collection('chatRoomFinance');

          QuerySnapshot chatRoomSnapshot = await chatsCollection.get();

          for (var phoneNumberDoc in chatRoomSnapshot.docs) {
            String phoneNumber = phoneNumberDoc.id;

            QuerySnapshot accountsSnapshot =
            await phoneNumberDoc.reference.collection('accounts').get();

            for (var accountDoc in accountsSnapshot.docs) {
              String accountNumber = accountDoc.id;

              // Match property using the correct field
              QuerySnapshot propSnapshot = await FirebaseFirestore.instance
                  .collection('districts')
                  .doc(districtId)
                  .collection('municipalities')
                  .doc(currentMunicipalityId)
                  .collection('properties')
                  .where(matchedAccountField, isEqualTo: accountNumber)
                  .limit(1)
                  .get();

              if (propSnapshot.docs.isNotEmpty) {
                Map<String, dynamic> propertyData =
                propSnapshot.docs.first.data() as Map<String, dynamic>;

                propertyData['phoneNumber'] = phoneNumber;
                propertyData['accountNumber'] = accountNumber;
                propertyData['matchedAccountField'] = matchedAccountField;
                propertyData['municipalityId'] = currentMunicipalityId;

                // Fetch unread status and latest message
                QuerySnapshot unreadMessagesSnapshot = await accountDoc.reference
                    .collection('chats')
                    .where('isRead', isEqualTo: false)
                    .get();

                QuerySnapshot latestMessageSnapshot = await accountDoc.reference
                    .collection('chats')
                    .orderBy('time', descending: true)
                    .limit(1)
                    .get();

                propertyData['hasUnreadMessages'] = unreadMessagesSnapshot.docs.isNotEmpty;

                if (latestMessageSnapshot.docs.isNotEmpty) {
                  Map<String, dynamic> latestMessage =
                  latestMessageSnapshot.docs.first.data() as Map<String, dynamic>;

                  propertyData['latestMessage'] = latestMessage['message'] ?? 'No messages yet.';
                  propertyData['latestMessageTime'] = latestMessage['time'] ?? 0;
                }

                financePropertiesWithMessages.add(propertyData);
                print('✅ Grouped property with $matchedAccountField: $accountNumber for $phoneNumber');
              } else {
                print('⚠️ No matching property for $matchedAccountField: $accountNumber in $currentMunicipalityId');
              }
            }
          }
        }

        // Sort by latest message time
        financePropertiesWithMessages.sort((a, b) =>
            (b['latestMessageTime'] ?? 0).compareTo(a['latestMessageTime'] ?? 0));

        if (mounted) {
          setState(() {
            _filteredFinanceProperties = financePropertiesWithMessages;
          });
        }
      }
    } catch (e) {
      print('❌ Error fetching or grouping chats: $e');
      if (mounted) {
        setState(() {
          _filteredFinanceProperties= [];
        });
      }
    }
  }

  Future<Map<String, dynamic>> _fetchLatestMessage(
      String chatRoomId, CollectionReference collection) async {
    var latestMessageSnapshot = await collection
        .doc(chatRoomId)
        .collection('chats')
        .orderBy('time', descending: true)
        .limit(1)
        .get();

    if (latestMessageSnapshot.docs.isNotEmpty) {
      return latestMessageSnapshot.docs.first.data();
    } else {
      return {};
    }
  }

  List<DocumentSnapshot> _filterProperties(
      String searchTerm, List<DocumentSnapshot> properties) {
    if (searchTerm.isNotEmpty) {
      return properties.where((prop) {
        final data = prop.data() as Map<String, dynamic>;
        final String usersName =
            '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}';
        final String property = data['address'] ?? '';
        final String accountNumber = data['accountNumber'] ?? '';

        final searchLower = searchTerm.toLowerCase();
        return usersName.toLowerCase().contains(searchLower) ||
            property.toLowerCase().contains(searchLower) ||
            accountNumber.toLowerCase().contains(searchLower);
      }).toList();
    } else {
      return properties;
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final double scrollAmount = _userChatScrollController.position.viewportDimension;

      if (_tabController.index == 0) {
        // User Queries Tab
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _userChatScrollController.animateTo(
            _userChatScrollController.offset + 50,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeIn,
          );
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _userChatScrollController.animateTo(
            _userChatScrollController.offset - 50,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeIn,
          );
        } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
          _userChatScrollController.animateTo(
            _userChatScrollController.offset + scrollAmount,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeIn,
          );
        } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
          _userChatScrollController.animateTo(
            _userChatScrollController.offset - scrollAmount,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeIn,
          );
        }
      } else if (_tabController.index == 1) {
        // Finance Queries Tab
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _financeChatScrollController.animateTo(
            _financeChatScrollController.offset + 50,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeIn,
          );
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _financeChatScrollController.animateTo(
            _financeChatScrollController.offset - 50,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeIn,
          );
        } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
          _financeChatScrollController.animateTo(
            _financeChatScrollController.offset + scrollAmount,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeIn,
          );
        } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
          _financeChatScrollController.animateTo(
            _financeChatScrollController.offset - scrollAmount,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeIn,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[350],
        appBar: AppBar(
          title: const Text(
            'Queries List',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(
                text: 'User Queries',
              ),
              Tab(
                text: 'Payment Queries',
              ),
            ],
          ),
        ),
        body: KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: _handleKeyEvent,
          child: Builder(
            builder: (context) {
              return TabBarView(
                controller: _tabController,
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: searchController,
                          onChanged: (value) {
                            setState(() {});
                          },
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: "Search Queries",
                          ),
                        ),
                      ),
                      Expanded(
                          child:Scrollbar(
                            controller: _userChatScrollController,
                            thickness: 10,
                            radius: const Radius.circular(10),
                            thumbVisibility: true,
                            child: _allChats.isEmpty
                                ? const Center(child: Text('No queries available'))
                                : ListView.builder(
                              controller: _userChatScrollController,
                                    itemCount: _allChats.length,
                                    itemBuilder: (context, index) {
                                      final chatData = _allChats[index];
                                      print(
                                          "Displaying chat room: ${chatData['chatRoomId']} for user: ${chatData['accountNumber']}");

                                      String chatRoomID =
                                          chatData['accountNumber'] ?? 'Unknown';
                                      String usersName =
                                          '${chatData['firstName'] ?? 'Unknown'} ${chatData['lastName'] ?? ''}';
                                      String usersProperty =
                                          chatData['address'] ?? 'Unknown';
                                      String number =
                                          chatData['phoneNumber'] ?? 'Unknown';
                                      bool hasUnreadMessages =
                                          chatData['hasUnreadMessages'] ?? false;

                                      String matchedField = 'accountNumber';
                                      String matchedAccountNumber = '';
                                      Map<String, String> chatRoomAccountsMap = {};

                                       // Ensure utilityType is parsed safely
                                      final utilityTypeList = chatData['utilityType'] is List
                                          ? List<String>.from(chatData['utilityType'])
                                          : [];

                                      if (utilityTypeList.contains('electricity') && !utilityTypeList.contains('water')) {
                                        matchedField = 'electricityAccountNumber';
                                        matchedAccountNumber = chatData['electricityAccountNumber'] ?? '';
                                        chatRoomAccountsMap = {
                                          'accountNumber': '',
                                          'electricityAccountNumber': matchedAccountNumber,
                                        };
                                      } else {
                                        matchedField = 'accountNumber';
                                        matchedAccountNumber = chatData['accountNumber'] ?? '';
                                        chatRoomAccountsMap = {
                                          'accountNumber': matchedAccountNumber,
                                          'electricityAccountNumber': '',
                                        };
                                      }

                                      print("🟠 Final matchedField = $matchedField");
                                      print("🟠 Final chatRoomAccountsMap = $chatRoomAccountsMap");


                                      return Card(
                                        margin: const EdgeInsets.only(
                                            left: 10, right: 10, top: 5, bottom: 5),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Center(
                                                child: Text(
                                                  'User Queries',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Query from: $usersName',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              Text(
                                                'Property: $usersProperty',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              Text(
                                                'Number: $number',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Stack(
                                                children: [
                                                  ChatButtonWidget(
                                                    chatRoomId:
                                                        chatData['chatRoomId'] ??
                                                            'Unknown',
                                                    usersName: matchedAccountNumber,
                                                    chatCollectionRef:
                                                        _chatsList!, // Temporary placeholder for CollectionReference
                                                    refreshChatList:
                                                        fetchAndStoreAllChats,
                                                    isLocalMunicipality:
                                                        isLocalMunicipality,
                                                    districtId: districtId,
                                                    municipalityId:
                                                        chatData['municipalityId'] ??
                                                            municipalityId,
                                                    hasUnreadMessages:
                                                        chatData['hasUnreadMessages'] ??
                                                            false,
                                                    chatRoomAccountsMap: chatRoomAccountsMap,

                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          )),
                    ],
                  ),
                  // Payment Queries Tab
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: financeSearchController,
                          onChanged: (value) {
                            setState(
                                () {}); // Update the state when search input changes
                          },
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: "Search Finance Queries",
                          ),
                        ),
                      ),
                      Expanded(
                        child: Scrollbar(
                          controller: _financeChatScrollController,
                          thickness: 10,
                          radius: const Radius.circular(10),
                          thumbVisibility: true,
                          child: _allFinanceChats.isEmpty
                              ? const Center(
                              child: Text('No finance queries available'))
                              : ListView.builder(
                            controller: _financeChatScrollController,
                            itemCount: _allFinanceChats.length,
                            itemBuilder: (context, index) {
                              final property = _allFinanceChats[index];
                              String chatRoomID =
                                  property['accountNumber'] ?? 'Unknown';
                              String usersProperty =
                                  property['address'] ?? 'Unknown';
                              String number =
                                  property['cellNumber'] ?? 'Unknown';
                              bool hasUnreadMessages =
                                  property['hasUnreadMessages'] ?? false;
                              String userName =
                                  '${property['firstName'] ?? 'Unknown'} ${property['lastName'] ?? ''}';
                              String matchedField = 'accountNumber';
                              String matchedAccountNumber = '';
                              Map<String, String> chatRoomAccountsMap = {};

                              // Ensure utilityType is parsed safely
                              final utilityTypeList = property['utilityType'] is List
                                  ? List<String>.from(property['utilityType'])
                                  : [];

                              if (utilityTypeList.contains('electricity') && !utilityTypeList.contains('water')) {
                                matchedField = 'electricityAccountNumber';
                                matchedAccountNumber = property['electricityAccountNumber'] ?? '';
                                chatRoomAccountsMap = {
                                  'accountNumber': '',
                                  'electricityAccountNumber': matchedAccountNumber,
                                };
                              } else {
                                matchedField = 'accountNumber';
                                matchedAccountNumber = property['accountNumber'] ?? '';
                                chatRoomAccountsMap = {
                                  'accountNumber': matchedAccountNumber,
                                  'electricityAccountNumber': '',
                                };
                              }

                              print("🟠 Final matchedField = $matchedField");
                              print("🟠 Final chatRoomAccountsMap = $chatRoomAccountsMap");

                              return Card(
                                margin: const EdgeInsets.only(
                                    left: 10, right: 10, top: 5, bottom: 5),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Center(
                                        child: Text(
                                          'Finance Queries',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Query from: $userName',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      Text(
                                        'Property: $usersProperty',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      Text(
                                        'Number: $number',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      ChatButtonFinanceWidget(
                                        chatRoomId:
                                        property['chatRoomId'] ??
                                            'Unknown',
                                        userFinanceName: matchedAccountNumber,
                                        chatFinCollectionRef: _chatsListFinance!,
                                        isLocalMunicipality: isLocalMunicipality,
                                        districtId: districtId,
                                        municipalityId:
                                        property['municipalityId'] ??
                                            municipalityId,
                                        hasUnreadMessages:
                                        property['hasUnreadMessages'] ??
                                            false,
                                        refreshChatList: fetchAndStoreAllFinanceChats,
                                        chatRoomAccountsMap: chatRoomAccountsMap,
                                      ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  )
                ],
              );
            }
          ),
        ),
      ),
    );
  }
}

///This is a button to open the selected chat from the list of chats on the server per user.
class ChatButtonWidget extends StatelessWidget {
  final String chatRoomId;
  final String usersName;
  final CollectionReference chatCollectionRef;
  final Function refreshChatList;
  final bool isLocalMunicipality;
  final String districtId;
  final String municipalityId;
  final bool hasUnreadMessages;
  final Map<String, String> chatRoomAccountsMap;
  const ChatButtonWidget({
    super.key,
    required this.chatRoomId,
    required this.usersName,
    required this.chatCollectionRef,
    required this.refreshChatList,
    required this.isLocalMunicipality,
    required this.districtId,
    required this.municipalityId,
    required this.hasUnreadMessages,
    required this.chatRoomAccountsMap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BasicIconButtonGrey(
            onPress: () async {
              final chatCollectionRef = isLocalMunicipality
                  ? FirebaseFirestore.instance
                  .collection('localMunicipalities')
                  .doc(municipalityId)
                  .collection('chatRoom')
                  : FirebaseFirestore.instance
                  .collection('districts')
                  .doc(districtId)
                  .collection('municipalities')
                  .doc(municipalityId)
                  .collection('chatRoom');

              // 🧠 Resolve correct property by checking both account fields
              QuerySnapshot propertySnapshot = await FirebaseFirestore.instance
                  .collectionGroup('properties')
                  .where('accountNumber', isEqualTo: usersName)
                  .get();

              if (propertySnapshot.docs.isEmpty) {
                propertySnapshot = await FirebaseFirestore.instance
                    .collectionGroup('properties')
                    .where('electricityAccountNumber', isEqualTo: usersName)
                    .get();
              }

              if (propertySnapshot.docs.isEmpty) {
                print("❌ No property found for userName = $usersName");
                Fluttertoast.showToast(msg: "Property not found.");
                return;
              }

              final propertyDoc = propertySnapshot.docs.first;
              final String waterAccount = propertyDoc['accountNumber'] ?? '';
              final String electricityAccount = propertyDoc['electricityAccountNumber'] ?? '';

              final Map<String, String> resolvedAccountMap = {
                'accountNumber': waterAccount,
                'electricityAccountNumber': electricityAccount,
              };

              final chatListState = context.findAncestorStateOfType<_ChatListState>();
              chatListState?.markMessagesAsReadForMunicipalUser(chatRoomId, usersName);

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Chat(
                    chatRoomId: chatRoomId,
                    userName: usersName,
                    chatCollectionRef: chatCollectionRef,
                    refreshChatList: refreshChatList,
                    isLocalMunicipality: isLocalMunicipality,
                    districtId: districtId,
                    municipalityId: municipalityId,
                    chatRoomAccountsMap: resolvedAccountMap,
                  ),
                ),
              );
              refreshChatList();
            },
            labelText: 'Chat',
            fSize: 16,
            faIcon: const FaIcon(Icons.chat),
            fgColor: Colors.blue,
            btSize: const Size(100, 38),
          ),
          if (hasUnreadMessages)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
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
        ],
      ),
    );
  }
}

class ChatButtonFinanceWidget extends StatelessWidget {
  final String chatRoomId;
  final String userFinanceName;
  final CollectionReference chatFinCollectionRef;
  final bool isLocalMunicipality;
  final String districtId;
  final String municipalityId;
  final Function refreshChatList;
  final bool hasUnreadMessages;
  final Map<String, String> chatRoomAccountsMap;

  const ChatButtonFinanceWidget({
    super.key,
    required this.chatRoomId,
    required this.userFinanceName,
    required this.chatFinCollectionRef,
    required this.isLocalMunicipality,
    required this.districtId,
    required this.municipalityId,
    required this.refreshChatList,
    required this.hasUnreadMessages,
    required this.chatRoomAccountsMap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BasicIconButtonGrey(
            onPress: () async {
              final chatCollectionRef = isLocalMunicipality
                  ? FirebaseFirestore.instance
                  .collection('localMunicipalities')
                  .doc(municipalityId)
                  .collection('chatRoomFinance')
                  : FirebaseFirestore.instance
                  .collection('districts')
                  .doc(districtId)
                  .collection('municipalities')
                  .doc(municipalityId)
                  .collection('chatRoomFinance');

              // 🧠 Resolve correct property by checking both account fields
              QuerySnapshot propertySnapshot = await FirebaseFirestore.instance
                  .collectionGroup('properties')
                  .where('accountNumber', isEqualTo: userFinanceName)
                  .get();

              if (propertySnapshot.docs.isEmpty) {
                propertySnapshot = await FirebaseFirestore.instance
                    .collectionGroup('properties')
                    .where('electricityAccountNumber', isEqualTo: userFinanceName)
                    .get();
              }

              if (propertySnapshot.docs.isEmpty) {
                print("❌ No property found for userName = $userFinanceName");
                Fluttertoast.showToast(msg: "Property not found.");
                return;
              }

              final propertyDoc = propertySnapshot.docs.first;
              final String waterAccount = propertyDoc['accountNumber'] ?? '';
              final String electricityAccount = propertyDoc['electricityAccountNumber'] ?? '';

              final Map<String, String> resolvedAccountMap = {
                'accountNumber': waterAccount,
                'electricityAccountNumber': electricityAccount,
              };

              final chatListState = context.findAncestorStateOfType<_ChatListState>();
              chatListState?.markFinanceMessagesAsReadForMunicipalUser(chatRoomId, userFinanceName);

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatFinance(
                    chatRoomId: chatRoomId,
                    userName: userFinanceName,
                    chatFinCollectionRef: chatCollectionRef,
                    refreshChatList: refreshChatList,
                    isLocalMunicipality: isLocalMunicipality,
                    districtId: districtId,
                    municipalityId: municipalityId,
                    chatRoomAccountsMap: resolvedAccountMap,
                  ),
                ),
              );
              refreshChatList();
            },
            labelText: 'Chat',
            fSize: 16,
            faIcon: const FaIcon(Icons.chat),
            fgColor: Colors.blue,
            btSize: const Size(100, 38),
          ),
          if (hasUnreadMessages)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
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
        ],
      ),
    );
  }
}
