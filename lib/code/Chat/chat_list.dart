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

      // Using collectionGroup on chatRoom to fetch all documents under this collection name
      QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
          .collectionGroup(
              'chatRoom') // Target all subcollections named chatRoom
          .get();

      List<Map<String, dynamic>> allChats = [];
      bool anyUnreadMessages = false;

      for (var chatDoc in chatSnapshot.docs) {
        String phoneNumber = chatDoc
            .id; // This is the document ID, which represents the user’s phone number
        String? municipalityId = chatDoc.reference.parent.parent
            ?.id; // Extract municipality ID if available

        // Now we need to access the 'accounts' subcollection within this chatRoom document
        QuerySnapshot accountsSnapshot =
            await chatDoc.reference.collection('accounts').get();

        for (var accountDoc in accountsSnapshot.docs) {
          String accountNumber =
              accountDoc.id; // This is the account number for the property

          // Fetch property details using the account number
          QuerySnapshot propertySnapshot = await FirebaseFirestore.instance
              .collectionGroup('properties')
              .where('accountNumber', isEqualTo: accountNumber)
              .limit(1)
              .get();

          Map<String, dynamic> propertyData = {};

          if (propertySnapshot.docs.isNotEmpty) {
            propertyData =
                propertySnapshot.docs.first.data() as Map<String, dynamic>;
          }

          // Fetch the latest chat message for this account under the 'chats' subcollection
          // Update real-time listener logic in fetchAndStoreAllChats
          await accountDoc.reference.collection('chats')
              .where('isReadByMunicipalUser', isEqualTo: false)
              .where('sendBy', isNotEqualTo: FirebaseAuth.instance.currentUser?.phoneNumber)
              .snapshots().listen((snapshot) {
            bool hasUnreadMessages = snapshot.docs.isNotEmpty;
            anyUnreadMessages = anyUnreadMessages || hasUnreadMessages;

            if (mounted) {
              setState(() {
                // Find the chat if it already exists
                int existingChatIndex = allChats.indexWhere((chat) =>
                chat['phoneNumber'] == phoneNumber && chat['accountNumber'] == accountNumber
                );

                if (existingChatIndex != -1) {
                  // Update the existing chat entry's unread status
                  allChats[existingChatIndex]['hasUnreadMessages'] = hasUnreadMessages;

                  // Check that there are documents in the snapshot before accessing the first one
                  if (snapshot.docs.isNotEmpty) {
                    allChats[existingChatIndex]['latestMessage'] = snapshot.docs.first['message'];
                    allChats[existingChatIndex]['latestMessageTime'] = snapshot.docs.first['time'];
                  }
                } else {
                  // If not found, add a new entry
                  allChats.add({
                    'chatRoomId': phoneNumber,
                    'municipalityId': municipalityId,
                    'accountNumber': accountNumber,
                    'firstName': propertyData['firstName'] ?? 'Unknown',
                    'lastName': propertyData['lastName'] ?? '',
                    'address': propertyData['address'] ?? 'Unknown',
                    'phoneNumber': phoneNumber,
                    'hasUnreadMessages': hasUnreadMessages,
                    'latestMessage': snapshot.docs.isNotEmpty ? snapshot.docs.first['message'] : "No messages yet.",
                    'latestMessageTime': snapshot.docs.isNotEmpty ? snapshot.docs.first['time'] : 0,
                  });
                }
              });
            }
          });
        }
      }
      if (mounted) {
        setState(() {
          _allChats = allChats;
        });
      }
    } catch (e) {
      print("Error fetching chats: $e");
    }
  }

  Future<void> fetchAndStoreAllFinanceChats() async {
    try {
      print("Fetching all finance chats across municipalities within the district");

      QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
          .collectionGroup('chatRoomFinance') // Target all subcollections named chatRoomFinance
          .get();
      print("Fetched ${chatSnapshot.docs.length} finance chat documents");
      List<Map<String, dynamic>> allFinanceChats = [];
      bool anyUnreadFinanceMessages = false;

      for (var chatDoc in chatSnapshot.docs) {
        String phoneNumber = chatDoc.id; // Document ID representing the user’s phone number
        String? municipalityId = chatDoc.reference.parent.parent?.id; // Extract municipality ID if available
        print("Processing chat document: ${chatDoc.id}");
        // Access the 'accounts' subcollection within this chatRoom document
        QuerySnapshot accountsSnapshot = await chatDoc.reference.collection('accounts').get();

        for (var accountDoc in accountsSnapshot.docs) {
          String accountNumber = accountDoc.id; // Account number for the property

          // Fetch property details using the account number
          QuerySnapshot propertySnapshot = await FirebaseFirestore.instance
              .collectionGroup('properties')
              .where('accountNumber', isEqualTo: accountNumber)
              .limit(1)
              .get();

          Map<String, dynamic> propertyData = {};

          if (propertySnapshot.docs.isNotEmpty) {
            propertyData = propertySnapshot.docs.first.data() as Map<String, dynamic>;
          }

          // Real-time listener for unread messages
          accountDoc.reference.collection('chats')
              .where('isReadByMunicipalUser', isEqualTo: false)
              .where('sendBy', isNotEqualTo: FirebaseAuth.instance.currentUser?.phoneNumber)
              .snapshots().listen((snapshot) {
            bool hasUnreadMessages = snapshot.docs.isNotEmpty;
            anyUnreadFinanceMessages = anyUnreadFinanceMessages || hasUnreadMessages;

            if (mounted) {
              setState(() {
                // Find the chat if it already exists
                int existingChatIndex = allFinanceChats.indexWhere((chat) =>
                chat['phoneNumber'] == phoneNumber && chat['accountNumber'] == accountNumber
                );

                if (existingChatIndex != -1) {
                  // Update the existing chat entry's unread status
                  allFinanceChats[existingChatIndex]['hasUnreadMessages'] = hasUnreadMessages;

                  // Only update latest message and time if there are documents
                  if (snapshot.docs.isNotEmpty) {
                    allFinanceChats[existingChatIndex]['latestMessage'] = snapshot.docs.first['message'];
                    allFinanceChats[existingChatIndex]['latestMessageTime'] = snapshot.docs.first['time'];
                  }
                } else {
                  // If not found, add a new entry
                  allFinanceChats.add({
                    'chatRoomId': phoneNumber,
                    'municipalityId': municipalityId,
                    'accountNumber': accountNumber,
                    'firstName': propertyData['firstName'] ?? 'Unknown',
                    'lastName': propertyData['lastName'] ?? '',
                    'address': propertyData['address'] ?? 'Unknown',
                    'phoneNumber': phoneNumber,
                    'hasUnreadMessages': hasUnreadMessages,
                    'latestMessage': snapshot.docs.isNotEmpty ? snapshot.docs.first['message'] : "No messages yet.",
                    'latestMessageTime': snapshot.docs.isNotEmpty ? snapshot.docs.first['time'] : 0,
                  });
                }
              });
            }
          });
        }
      }
      print("Final processed finance chats: $allFinanceChats");

      if (mounted) {
        setState(() {
          _allFinanceChats = allFinanceChats;
          print("All finance chats set in state: $_allFinanceChats");
        });
      }
    } catch (e) {
      print("Error fetching finance chats: $e");
    }
  }

  Future<void> fetchAndGroupChats() async {
    try {
      List<Map<String, dynamic>> allPropertiesWithMessages = [];

      if (!isLocalMunicipality) {
        // Fetch all municipalities under the specified district
        QuerySnapshot municipalitiesSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .get();

        // Iterate over each municipality in the district
        for (var municipalityDoc in municipalitiesSnapshot.docs) {
          String currentMunicipalityId = municipalityDoc.id;

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

              // Fetch properties filtered by account number and municipality
              QuerySnapshot propSnapshot = await FirebaseFirestore.instance
                  .collection('districts')
                  .doc(districtId)
                  .collection('municipalities')
                  .doc(currentMunicipalityId)
                  .collection('properties')
                  .where('accountNumber', isEqualTo: accountNumber)
                  .get();

              if (propSnapshot.docs.isNotEmpty) {
                var propertyData =
                    propSnapshot.docs.first.data() as Map<String, dynamic>;
                propertyData['phoneNumber'] = phoneNumber;
                propertyData['accountNumber'] = accountNumber;
                propertyData['municipalityId'] = currentMunicipalityId;

                // Check for unread messages and get the latest message
                QuerySnapshot unreadMessagesSnapshot = await phoneNumberDoc
                    .reference
                    .collection('accounts')
                    .doc(accountNumber)
                    .collection('chats')
                    .where('isRead', isEqualTo: false)
                    .get();

                QuerySnapshot latestMessageSnapshot = await phoneNumberDoc
                    .reference
                    .collection('accounts')
                    .doc(accountNumber)
                    .collection('chats')
                    .orderBy('time', descending: true)
                    .limit(1)
                    .get();

                bool hasUnreadMessages = unreadMessagesSnapshot.docs.isNotEmpty;
                propertyData['hasUnreadMessages'] = hasUnreadMessages;

                if (latestMessageSnapshot.docs.isNotEmpty) {
                  var latestMessageData = latestMessageSnapshot.docs.first
                      .data() as Map<String, dynamic>?;

                  propertyData['latestMessageTime'] =
                      latestMessageData?['time'] ?? 0;
                  propertyData['latestMessage'] =
                      latestMessageData?['message'] ?? "No messages yet.";
                }

                allPropertiesWithMessages.add(propertyData);

                print(
                    'Processing property with accountNumber: $accountNumber and phoneNumber: $phoneNumber');
              }
            }
          }
        }

        // Sort by latest message time
        allPropertiesWithMessages.sort((a, b) => (b['latestMessageTime'] as int)
            .compareTo(a['latestMessageTime'] as int));

        if (mounted) {
          setState(() {
            _filteredProperties = allPropertiesWithMessages;
          });
        }
      }
    } catch (e) {
      print('Error fetching or grouping chats: $e');
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
          if (chat['phoneNumber'] == phoneNumber && chat['accountNumber'] == accountNumber) {
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
          if (chat['phoneNumber'] == phoneNumber && chat['accountNumber'] == accountNumber) {
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
      // Step 1: Fetch all finance chat rooms from the chatRoomFinance collection
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

      // Step 2: Create a list of chatRoomIds from the finance chatRoom collection
      List<String> chatRoomIds =
      chatRoomSnapshot.docs.map((doc) => doc.id).toList();

      // Log the number of finance chat rooms found
      print("Total finance chat rooms fetched: ${chatRoomIds.length}");

      // Step 3: Fetch properties whose accountNumbers match the finance chatRoomIds
      List<Map<String, dynamic>> financePropertiesWithMessages = [];

      for (var phoneNumberDoc in chatRoomSnapshot.docs) {
        String phoneNumber = phoneNumberDoc.id;

        print("Processing chat document: $phoneNumber");

        // Fetch the accounts subcollection for each phone number
        QuerySnapshot accountsSnapshot =
        await phoneNumberDoc.reference.collection('accounts').get();

        if (accountsSnapshot.docs.isEmpty) {
          print("No accounts found under chat document: $phoneNumber");
          continue; // Skip if no accounts are found
        }

        for (var accountDoc in accountsSnapshot.docs) {
          String accountNumber = accountDoc.id;

          print("Processing account document: $accountNumber");

          // Fetch properties whose accountNumber matches the account number under the phone number
          QuerySnapshot propSnapshot = await _propList!
              .where('accountNumber', isEqualTo: accountNumber)
              .get();

          if (propSnapshot.docs.isNotEmpty) {
            var propertyData =
            propSnapshot.docs.first.data() as Map<String, dynamic>;

            // Step 4: Fetch the latest message for this account
            var latestMessageSnapshot = await phoneNumberDoc.reference
                .collection('accounts')
                .doc(accountNumber)
                .collection('chats')
                .orderBy('time', descending: true)
                .get();

            if (latestMessageSnapshot.docs.isEmpty) {
              print("No messages found for accountNumber: $accountNumber");
              propertyData['latestMessageTime'] = 0;
              propertyData['latestMessage'] = "No messages yet.";
            } else {
              var latestMessage = latestMessageSnapshot.docs.first.data();
              print("Latest message data: $latestMessage");

              // Null-safe checks for latestMessage['time'] and ['message']
              propertyData['latestMessageTime'] =
                  latestMessage['time'] ?? 0; // Fallback to 0 if null
              propertyData['latestMessage'] =
                  latestMessage['message'] ?? "No messages yet."; // Fallback
            }

            // Add property and chat message data
            propertyData['accountNumber'] = accountNumber;
            propertyData['phoneNumber'] = phoneNumber;
            financePropertiesWithMessages.add(propertyData);

            print(
                'Added finance property with accountNumber: $accountNumber and phoneNumber: $phoneNumber');
          } else {
            print(
                "No properties found for accountNumber: $accountNumber under chat document: $phoneNumber");
          }
        }
      }

      // Step 5: Sort the list by the latest message time (most recent first)
      financePropertiesWithMessages.sort((a, b) =>
          (b['latestMessageTime'] as int)
              .compareTo(a['latestMessageTime'] as int));

      // Step 6: Update the UI with the processed and sorted finance properties
      if (context.mounted) {
        setState(() {
          _filteredFinanceProperties = financePropertiesWithMessages;
        });
      }
      print("Updated _allFinanceChats: $_allFinanceChats");
      // Log the final number of finance properties to be displayed
      print(
          "Total finance properties to display: ${_filteredFinanceProperties.length}");
    } catch (e) {
      print('Error fetching or grouping finance chats: $e');
      if (context.mounted) {
        setState(() {
          _filteredFinanceProperties = [];
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
            'Chat Rooms List',
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
                            hintText: "Search Chats",
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
                                ? const Center(child: Text('No chat rooms available'))
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
                                                  'Chat Room',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Chat from: $usersName',
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
                                                    usersName:
                                                        chatData['accountNumber'] ??
                                                            'Unknown',
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
                            hintText: "Search Finance Chats",
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
                              child: Text('No finance chat rooms available'))
                              : ListView.builder(
                            controller: _financeChatScrollController,
                            itemCount: _allFinanceChats.length,
                            itemBuilder: (context, index) {
                              final property = _allFinanceChats[index];
                              String chatRoomID =
                                  property['phoneNumber'] ?? 'Unknown'; // Extract phone number
                              String usersName =
                                  property['accountNumber'] ?? 'Unknown'; // Extract account number
                              String usersDetails =
                                  '${property['firstName'] ?? 'Unknown'} ${property['lastName'] ?? ''}';
                              String usersProperty = property['address'] ?? 'Unknown';
                              bool hasUnreadMessages =
                                  property['hasUnreadMessages'] ?? false;

                              // Debugging print statement to confirm data source
                              print(
                                  "Displaying finance chat room: $chatRoomID for user: $usersName");

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
                                          'Chat Room',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Chat from: $usersDetails',
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
                                        'Number: $chatRoomID',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      ChatButtonFinanceWidget(
                                        chatRoomId: chatRoomID,
                                        userFinanceName: usersName,
                                        chatFinCollectionRef: _chatsListFinance!,
                                        isLocalMunicipality: isLocalMunicipality,
                                        districtId: districtId,
                                        municipalityId: municipalityId,
                                        refreshChatList: fetchAndStoreAllFinanceChats,
                                        hasUnreadMessages: hasUnreadMessages,
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
                  ? FirebaseFirestore.instance.collection('localMunicipalities').doc(municipalityId).collection('chatRoom')
                  : FirebaseFirestore.instance.collection('districts').doc(districtId).collection('municipalities').doc(municipalityId).collection('chatRoom');
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
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BasicIconButtonGrey(
            onPress: () async {
              final chatFinCollectionRef = isLocalMunicipality
                  ? FirebaseFirestore.instance.collection('localMunicipalities').doc(municipalityId).collection('chatRoomFinance')
                  : FirebaseFirestore.instance.collection('districts').doc(districtId).collection('municipalities').doc(municipalityId).collection('chatRoomFinance');

              final chatListState = context.findAncestorStateOfType<_ChatListState>();
              chatListState?.markFinanceMessagesAsReadForMunicipalUser(chatRoomId, userFinanceName);

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>  ChatFinance(
                    chatRoomId: chatRoomId,
                    userName: userFinanceName,
                    chatFinCollectionRef:  chatFinCollectionRef,
                    refreshChatList: refreshChatList,
                    isLocalMunicipality: isLocalMunicipality,
                    districtId: districtId,
                    municipalityId: municipalityId,
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
