import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:municipal_services/code/Chat/upload_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_screen.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class ChatFinance extends StatefulWidget {
  final String chatRoomId;
  final String? userName;
  final CollectionReference chatFinCollectionRef;
  final Function refreshChatList;
  final bool isLocalMunicipality; // Add this flag to distinguish between local municipalities and districts
  final String districtId; // Only needed for district-based municipalities
  final String municipalityId;
  final Map<String, String>? chatRoomAccountsMap;
  const ChatFinance({super.key, required this.chatRoomId, required this.userName, required this.chatFinCollectionRef, required this.refreshChatList, required this.isLocalMunicipality, required this.districtId, required this.municipalityId,required this.chatRoomAccountsMap, });

  @override
  _ChatFinanceState createState() => _ChatFinanceState();
}
final FirebaseAuth auth = FirebaseAuth.instance;
DateTime now = DateTime.now();
final User? user = auth.currentUser;
final uid = user?.uid;
final email = user?.email;
String userID = uid as String;
String userEmail = email as String;

class _ChatFinanceState extends State<ChatFinance> {
  bool _isLoading = false;
  late Stream<QuerySnapshot> chats = const Stream.empty();
  TextEditingController messageEditingController = TextEditingController();
  String chatTo = 'Finance Chat';
  ScrollController _scrollController = ScrollController();
  late CollectionReference _chatsListFinance ;
  String? userEmail;
  String districtId='';
  String municipalityId='';
  late CollectionReference _propList;
  bool hasUnreadMessages = false;
  String? propertyAddress;
  late String accountNumber;
  late String matchedAccountField;
  bool hasLoadedChats = false;

  @override
  void initState() {
    super.initState();
    print('Initializing chat with chatRoomId: ${widget.chatRoomId}');
    _isLoading = true;
    matchedAccountField = 'accountNumber'; // default
    accountNumber = widget.chatRoomAccountsMap?['accountNumber'] ?? '';

// Dynamically determine correct account field
    if ((widget.chatRoomAccountsMap?['electricityAccountNumber']?.isNotEmpty ?? false) &&
        !(widget.chatRoomAccountsMap?['accountNumber']?.isNotEmpty ?? false)) {
      matchedAccountField = 'electricityAccountNumber';
      accountNumber = widget.chatRoomAccountsMap?['electricityAccountNumber'] ?? '';
    }

    print("✅ Loaded chat for $matchedAccountField = $accountNumber");


    print("✅ Loaded chat for $matchedAccountField = $accountNumber");
    () async {
      initializeChatCollectionReference().then((success) {
        if (success) {
          fetchChats(); // Only proceed if chat path is valid
        } else {
          print("❌ Failed to initialize chat path. Chat will not load.");
        }
      });
    //  fetchChats(); // ✅ safe to use _chatsList now

      fetchPropertyAddress();
      createOrUpdateChatRoom();
      markMessagesAsRead(widget.chatRoomId, widget.userName);

      if (mounted) {
        setState(() {
          hasLoadedChats = true;
          _isLoading = false;
        });
      }
    }();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  Future<bool> initializeChatCollectionReference() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Fallback to prevent crashes
    _chatsListFinance = FirebaseFirestore.instance.collection('dummyPath/invalid/chats');

    String accountNumberToUse = '';
    String matchedField = 'accountNumber'; // default

    if (currentUser?.email != null) {
      // 🏛️ Municipality user
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collectionGroup('users')
          .where('email', isEqualTo: currentUser!.email)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        print("⚠️ No matching municipal user found in Firestore.");
        return false;
      }

      var userDoc = userSnapshot.docs.first;
      final userPathSegments = userDoc.reference.path.split('/');

      bool isLocalMunicipality = userPathSegments.first == 'localMunicipalities';
      String municipalityId = isLocalMunicipality
          ? userPathSegments[1]
          : userPathSegments[3];
      String districtId = isLocalMunicipality ? '' : userPathSegments[1];

      // 🔌 Get utility type
      final municipalityDoc = isLocalMunicipality
          ? await FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .get()
          : await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .get();

      final utilityType = List<String>.from(municipalityDoc.get('utilityType') ?? []);

      // 🧠 Determine matched account field
      if (utilityType.contains('electricity') && !utilityType.contains('water')) {
        matchedField = 'electricityAccountNumber';
      }

      // ✅ Attempt to get account number from map
      accountNumberToUse = widget.chatRoomAccountsMap?[matchedField] ?? '';

      // Fallback to other field if empty
      if (accountNumberToUse.isEmpty) {
        matchedField = matchedField == 'electricityAccountNumber'
            ? 'accountNumber'
            : 'electricityAccountNumber';

        accountNumberToUse = widget.chatRoomAccountsMap?[matchedField] ?? '';
      }

      if (accountNumberToUse.isEmpty) {
        print("❌ Cannot initialize chat: account number for $matchedField is empty.");
        return false;
      }

      // ✅ Store globally
      this.matchedAccountField = matchedField;
      this.accountNumber = accountNumberToUse;

      // ✅ Build path
      _chatsListFinance = isLocalMunicipality
          ? FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('chatRoomFinance')
          .doc(widget.chatRoomId)
          .collection('accounts')
          .doc(accountNumberToUse)
          .collection('chats')
          : FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('chatRoomFinance')
          .doc(widget.chatRoomId)
          .collection('accounts')
          .doc(accountNumberToUse)
          .collection('chats');

      print("✅ Chat path initialized for municipal user with $matchedField = $accountNumberToUse");
      return true;

    } else if (currentUser?.phoneNumber != null) {
      // 👤 Regular user
      final prefs = await SharedPreferences.getInstance();
      matchedField = prefs.getString('matchedAccountField') ?? 'accountNumber';
      accountNumberToUse = prefs.getString('selectedPropertyAccountNo') ?? '';

      if (accountNumberToUse.isEmpty) {
        print("❌ Cannot initialize chat: selected account number is empty.");
        return false;
      }

      // ✅ Store globally
      this.matchedAccountField = matchedField;
      this.accountNumber = accountNumberToUse;

      _chatsListFinance = widget.isLocalMunicipality
          ? FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(widget.municipalityId)
          .collection('chatRoomFinance')
          .doc(widget.chatRoomId)
          .collection('accounts')
          .doc(accountNumberToUse)
          .collection('chats')
          : FirebaseFirestore.instance
          .collection('districts')
          .doc(widget.districtId)
          .collection('municipalities')
          .doc(widget.municipalityId)
          .collection('chatRoomFinance')
          .doc(widget.chatRoomId)
          .collection('accounts')
          .doc(accountNumberToUse)
          .collection('chats');
      chats = _chatsListFinance.orderBy('time', descending: false).snapshots();
      print("✅ Chat path initialized for regular user with $matchedField = $accountNumberToUse");
      return true;
    }

    print("❌ No logged in user.");
    return false;
  }

  void fetchChats() {
    final newStream = _chatsListFinance.orderBy('time', descending: false).snapshots();
    if (mounted) {
      setState(() {
        chats = newStream;
      });
    } else {
      chats = newStream; // fallback
    }
  }

  // Future<void> fetchUserDetails() async {
  //   try {
  //     User? user = FirebaseAuth.instance.currentUser;
  //     if (user != null) {
  //       String userPhoneNumber = user.phoneNumber!;
  //       String accountNumber = widget.chatRoomId;
  //
  //       // Add logging for phone number and account number
  //       print("Fetching details for phoneNumber: $userPhoneNumber and accountNumber: $accountNumber");
  //
  //       QuerySnapshot propertySnapshot = await FirebaseFirestore.instance
  //           .collectionGroup('properties')
  //           .where('cellNumber', isEqualTo: userPhoneNumber)
  //           .where(selectedAccountField, isEqualTo: accountNumber)
  //           .get();
  //
  //       // Check if the query returns any documents
  //       if (propertySnapshot.docs.isNotEmpty) {
  //         var propertyDoc = propertySnapshot.docs.first;
  //         var pathSegments = propertyDoc.reference.path.split('/');
  //
  //         // Log the full path for debugging
  //         print("Property found at path: ${propertyDoc.reference.path}");
  //
  //         // Check if it's a local municipality or district
  //         if (pathSegments[0] == 'localMunicipalities') {
  //           municipalityId = pathSegments[1];
  //           print('Found local municipality: $municipalityId');
  //         } else if (pathSegments[0] == 'districts') {
  //           districtId = pathSegments[1];
  //           municipalityId = pathSegments[3];
  //           print('Found district: $districtId and municipality: $municipalityId');
  //         } else {
  //           print('Error: Unexpected path format.');
  //         }
  //       } else {
  //         // Log that no property was found for this user
  //         print("No matching property found for the user.");
  //       }
  //     }
  //   } catch (e) {
  //     print('Error fetching user details: $e');
  //   }
  // }

  Future<void> fetchPropertyAddress() async {
    String? address = await getPropertyAddress(
      '', // unused now
      widget.districtId,
      widget.municipalityId,
      widget.isLocalMunicipality,
    );

    if (mounted) {
      setState(() {
        propertyAddress = address ?? 'Unknown Property';
      });
    }
  }

  Future<String?> getPropertyAddress(
      String unusedAccountNumber,
      String districtId,
      String municipalityId,
      bool isLocalMunicipality,
      ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    bool isMunicipalUser = currentUser?.email != null;

    // Extract both account fields
    String accNo = widget.chatRoomAccountsMap?['accountNumber'] ?? '';
    String elecAccNo = widget.chatRoomAccountsMap?['electricityAccountNumber'] ?? '';

    String matchedAccountField = '';
    String accountNumberToUse = '';

    // ✅ Prefer explicit match with userName
    if (widget.userName == accNo) {
      matchedAccountField = 'accountNumber';
      accountNumberToUse = accNo;
    } else if (widget.userName == elecAccNo) {
      matchedAccountField = 'electricityAccountNumber';
      accountNumberToUse = elecAccNo;
    } else if (elecAccNo.isNotEmpty && accNo.isEmpty) {
      matchedAccountField = 'electricityAccountNumber';
      accountNumberToUse = elecAccNo;
    } else if (accNo.isNotEmpty) {
      matchedAccountField = 'accountNumber';
      accountNumberToUse = accNo;
    }

    print('🟡 getPropertyAddress: incoming userName = ${widget.userName}');
    print('🟡 chatRoomAccountsMap: ${widget.chatRoomAccountsMap}');
    print('🟡 Using matchedAccountField = $matchedAccountField');
    print('🟡 Using accountNumber = $accountNumberToUse');

    if (accountNumberToUse.isEmpty) {
      print('❌ No valid account number stored. Aborting.');
      return null;
    }

    try {
      QuerySnapshot propertiesSnapshot;

      if (isLocalMunicipality) {
        propertiesSnapshot = await FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(municipalityId)
            .collection('properties')
            .where(matchedAccountField, isEqualTo: accountNumberToUse)
            .limit(1)
            .get();
      } else {
        propertiesSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('properties')
            .where(matchedAccountField, isEqualTo: accountNumberToUse)
            .limit(1)
            .get();
      }

      if (propertiesSnapshot.docs.isNotEmpty) {
        final propertyData = propertiesSnapshot.docs.first.data() as Map<String, dynamic>;
        final fetchedAddress = propertyData['address'] ?? 'Unknown Property';
        print('✅ Property Address Found: $fetchedAddress');
        return fetchedAddress;
      } else {
        print('❌ No property found for: $matchedAccountField = $accountNumberToUse');
        return null;
      }
    } catch (e) {
      print('🚨 Error fetching property address: $e');
      return null;
    }
  }


  Future<void> createOrUpdateChatRoom() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = FirebaseAuth.instance.currentUser;

      String accountNumberToUse = '';
      String matchedField = 'accountNumber';

      if (currentUser?.email != null) {
        // 🔹 Municipality user: Use account number from passed-in map
        final utilityTypeDoc = widget.isLocalMunicipality
            ? await FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(widget.municipalityId)
            .get()
            : await FirebaseFirestore.instance
            .collection('districts')
            .doc(widget.districtId)
            .collection('municipalities')
            .doc(widget.municipalityId)
            .get();

        final utilityTypes = List<String>.from(utilityTypeDoc.get('utilityType') ?? []);

        if (utilityTypes.contains('electricity') && !utilityTypes.contains('water')) {
          matchedField = 'electricityAccountNumber';
        }

        accountNumberToUse = widget.chatRoomAccountsMap?[matchedField] ?? '';

        // Fallback to the other field if empty
        if (accountNumberToUse.isEmpty && matchedField == 'electricityAccountNumber') {
          accountNumberToUse = widget.chatRoomAccountsMap?['accountNumber'] ?? '';
          matchedField = 'accountNumber';
        } else if (accountNumberToUse.isEmpty && matchedField == 'accountNumber') {
          accountNumberToUse = widget.chatRoomAccountsMap?['electricityAccountNumber'] ?? '';
          matchedField = 'electricityAccountNumber';
        }

      } else {
        // 🔹 Regular user: use from SharedPreferences
        matchedField = prefs.getString('matchedAccountField') ?? 'accountNumber';
        accountNumberToUse = prefs.getString('selectedPropertyAccountNo') ?? '';
      }

      if (accountNumberToUse.isEmpty) {
        print("❌ Cannot create/update chat room: no valid account number found.");
        return;
      }

      // ✅ Proceed to write
      DocumentReference chatRoomRef;
      DocumentReference accountRef;

      if (widget.isLocalMunicipality) {
        chatRoomRef = FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(widget.municipalityId)
            .collection('chatRoomFinance')
            .doc(widget.chatRoomId);

        accountRef = chatRoomRef.collection('accounts').doc(accountNumberToUse);
      } else {
        chatRoomRef = FirebaseFirestore.instance
            .collection('districts')
            .doc(widget.districtId)
            .collection('municipalities')
            .doc(widget.municipalityId)
            .collection('chatRoomFinance')
            .doc(widget.chatRoomId);

        accountRef = chatRoomRef.collection('accounts').doc(accountNumberToUse);
      }

      await chatRoomRef.set({
        'chatRoom': widget.chatRoomId,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await accountRef.set({
        'chatRoom': accountNumberToUse,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Chat room created/updated for: $matchedField = $accountNumberToUse');
    } catch (e) {
      print('❌ Error creating/updating chat room: $e');
    }
  }

  // void fetchChats(String phoneNumber) {
  //   CollectionReference chatsCollection;
  //
  //   if (widget.isLocalMunicipality) {
  //     chatsCollection = FirebaseFirestore.instance
  //         .collection('localMunicipalities')
  //         .doc(widget.municipalityId)
  //         .collection('chatRoomFinance')
  //         .doc(phoneNumber)
  //         .collection('accounts')
  //         .doc(widget.userName)
  //         .collection('chats');
  //   } else {
  //     chatsCollection = FirebaseFirestore.instance
  //         .collection('districts')
  //         .doc(widget.districtId)
  //         .collection('municipalities')
  //         .doc(widget.municipalityId)
  //         .collection('chatRoomFinance')
  //         .doc(phoneNumber)
  //         .collection('accounts')
  //         .doc(widget.userName)
  //         .collection('chats');
  //   }
  //
  //   chats = chatsCollection.orderBy('time').snapshots();
  //   if(mounted) {
  //     setState(() {
  //       hasLoadedChats = true; // now safe to build StreamBuilder
  //     });
  //   }
  //   chatsCollection
  //       .where('isReadByMunicipalUser', isEqualTo: false)
  //       .snapshots()
  //       .listen((snapshot) {
  //     if (mounted) {
  //       setState(() {
  //         hasUnreadMessages = snapshot.docs.isNotEmpty;
  //       });
  //       widget.refreshChatList();
  //     }
  //   });
  // }



  // Future<void> checkUser() async {
  //   print('username must be :::${user?.phoneNumber}');
  //   if (user?.phoneNumber == null || user?.phoneNumber == '') {
  //     useNum = '';
  //     useEmail = user?.email!;
  //     Constants.myName = useEmail;
  //   } else if (user?.email == null || user?.email == '') {
  //     useNum = user?.phoneNumber!;
  //     useEmail = '';
  //     Constants.myName = useNum;
  //   }
  //
  //   print('chatroom name is ${widget.chatRoomId}');
  //   print('username is :::${Constants.myName}');
  // }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void markMessagesAsRead(String phoneNumber, String? _) async {
    try {
      // ✅ Use resolved values
      final String resolvedAccountNumber = accountNumber;
      final String resolvedField = matchedAccountField;

      if (resolvedAccountNumber.isEmpty) {
        print("❌ No valid account number found when marking messages as read.");
        return;
      }

      CollectionReference chatsCollection;

      if (widget.isLocalMunicipality) {
        chatsCollection = FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(widget.municipalityId)
            .collection('chatRoomFinance')
            .doc(phoneNumber)
            .collection('accounts')
            .doc(resolvedAccountNumber)
            .collection('chats');
      } else {
        chatsCollection = FirebaseFirestore.instance
            .collection('districts')
            .doc(widget.districtId)
            .collection('municipalities')
            .doc(widget.municipalityId)
            .collection('chatRoomFinance')
            .doc(phoneNumber)
            .collection('accounts')
            .doc(resolvedAccountNumber)
            .collection('chats');
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserIdentifier =
          currentUser?.phoneNumber ?? currentUser?.email ?? '';

      QuerySnapshot unreadMessagesSnapshot = await chatsCollection.get();

      for (var doc in unreadMessagesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        if (data['sendBy'] != currentUserIdentifier) {
          final fieldToUpdate = currentUserIdentifier.contains('@')
              ? 'isReadByMunicipalUser'
              : 'isReadByRegularUser';

          if (data[fieldToUpdate] == false) {
            await doc.reference.update({fieldToUpdate: true});
          }
        }
      }

      print("✅ Marked messages as read for $resolvedField = $resolvedAccountNumber");

    } catch (e) {
      print("❌ Error marking messages as read: $e");
    }
  }


  Widget chatMessages(BuildContext context) {
    print("🟢 Building chatMessages with stream = $chats");
    return StreamBuilder<QuerySnapshot>(
      stream: chats,
      builder: (context, snapshot) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollToBottom();
          }
        });

        if (snapshot.hasData) {
          var currentUserIdentifier = FirebaseAuth.instance.currentUser!.phoneNumber != null
              ? FirebaseAuth.instance.currentUser!.phoneNumber!
              : FirebaseAuth.instance.currentUser!.email!;

          // ✅ Check unread messages and mark as read if necessary
          snapshot.data?.docs.forEach((doc) {
            var data = doc.data() as Map<String, dynamic>;
            var sendBy = data["sendBy"];

            if ((sendBy != currentUserIdentifier) &&
                ((currentUserIdentifier.contains('@') && !data["isReadByMunicipalUser"]) ||
                    (!currentUserIdentifier.contains('@') && !data["isReadByRegularUser"]))) {
              doc.reference.update({
                currentUserIdentifier.contains('@') ? "isReadByMunicipalUser" : "isReadByRegularUser": true,
              });
            }
          });

          // ✅ If there are NO messages, show a background message
          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Leave a message for any payment disputes, and someone will get back to you.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600, // Light grey text
                  ),
                ),
              ),
            );
          }

          // ✅ Display messages normally when they exist
          return SingleChildScrollView(
            reverse: true,
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data?.docs.length ?? 0,
                  itemBuilder: (context, index) {
                    var data = snapshot.data?.docs[index].data() as Map<String, dynamic>;
                    bool sendByMe = data["sendBy"] == currentUserIdentifier;

                    return MessageTile(
                      message: data["message"],
                      sendByMe: sendByMe,
                      timestamp: data["time"],
                      sendBy: data["sendBy"],
                      isRead: data[currentUserIdentifier.contains('@') ? "isReadByMunicipalUser" : "isReadByRegularUser"],
                      fileUrl: data["fileUrl"],
                    );
                  },
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }




  // void sendMessage({String? text, String? fileUrl}) {
  //   String message = text ?? "Sent a file";
  //   Map<String, dynamic> messageData = {
  //     "sendBy": Constants.myName,
  //     "message": message,
  //     "time": DateTime.now().millisecondsSinceEpoch,
  //     if (fileUrl != null) "fileUrl": fileUrl,
  //   };
  //   DatabaseMethods().addMessage(widget.chatRoomId, messageData);
  //   messageEditingController.clear();
  // }
  // void addMessage({String? fileUrl}) {
  //   Map<String, dynamic> chatMessageMap = {
  //     "sendBy": Constants.myName,
  //     "message": fileUrl != null ? "Sent a file" : messageEditingController.text,  // This sets the message text
  //     'time': DateTime.now().millisecondsSinceEpoch,
  //     if (fileUrl != null) "fileUrl": fileUrl,
  //   };
  //
  //   DatabaseMethods().addFinanceMessage(
  //     widget.chatRoomId,
  //     chatMessageMap,
  //   );
  //
  //   setState(() {
  //     messageEditingController.text = "";  // Clear the text field after sending
  //   });
  // }

  // void sendMessage({
  //   String? text,
  //   String? fileUrl,
  //   required String chatRoomId,
  //   required String districtId,
  //   required String municipalityId,
  // }) {
  //   User? user = FirebaseAuth.instance.currentUser;
  //
  //   if (user == null) {
  //     print("User is not authenticated, message not sent.");
  //     return;
  //   }
  //
  //   // Log the values to check if they are correctly populated
  //   print('chatRoomId: $chatRoomId');
  //   print('districtId: $districtId');
  //   print('municipalityId: $municipalityId');
  //
  //   if (chatRoomId.isEmpty || municipalityId.isEmpty || (districtId.isEmpty && !widget.isLocalMunicipality)) {
  //     print('Error: One of the required values (chatRoomId, municipalityId, districtId) is empty.');
  //     return;
  //   }
  //
  //   String message = messageEditingController.text.trim();
  //   if (message.isEmpty && fileUrl == null) {
  //     return;
  //   }
  //
  //   if (message.isEmpty && fileUrl != null) {
  //     message = "File has been sent";
  //   }
  //
  //   String sendBy = user.phoneNumber ?? user.email ?? 'Unknown User';
  //
  //   Map<String, dynamic> messageData = {
  //     "sendBy": sendBy,
  //     "message": message,
  //     "time": DateTime.now().millisecondsSinceEpoch,
  //     if (fileUrl != null) "fileUrl": fileUrl,
  //   };
  //
  //   if (districtId.isEmpty) {
  //     // Local municipality case
  //     FirebaseFirestore.instance
  //         .collection('localMunicipalities')
  //         .doc(municipalityId)
  //         .collection("chatRoomFinance")
  //         .doc(chatRoomId)
  //         .collection("chats")
  //         .add(messageData)
  //         .then((_) {
  //       print("Message sent successfully.");
  //     }).catchError((error) {
  //       print("Failed to send message: $error");
  //     });
  //   } else {
  //     // District-based case
  //     FirebaseFirestore.instance
  //         .collection('districts')
  //         .doc(districtId)
  //         .collection('municipalities')
  //         .doc(municipalityId)
  //         .collection("chatRoomFinance")
  //         .doc(chatRoomId)
  //         .collection("chats")
  //         .add(messageData)
  //         .then((_) {
  //       print("Message sent successfully.");
  //     }).catchError((error) {
  //       print("Failed to send message: $error");
  //     });
  //   }
  //
  //   messageEditingController.clear();
  // }
  //
  void sendMessage({
    String? text,
    String? fileUrl,
    required String chatRoomId,
  }) async {
    if (messageEditingController.text.trim().isEmpty && fileUrl == null) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserIdentifier =
        currentUser?.phoneNumber ?? currentUser?.email ?? '';

    bool isReadByRegularUser = currentUserIdentifier == currentUser?.phoneNumber;
    bool isReadByMunicipalUser = !isReadByRegularUser;

    Map<String, dynamic> messageData = {
      "sendBy": currentUserIdentifier,
      "message": text ?? messageEditingController.text.trim(),
      "time": DateTime.now().millisecondsSinceEpoch,
      "isReadByRegularUser": isReadByRegularUser,
      "isReadByMunicipalUser": isReadByMunicipalUser,
      if (fileUrl != null) "fileUrl": fileUrl,
    };

    // ✅ Use resolved field and value
    final String resolvedField = matchedAccountField;
    final String resolvedAccountNumber = accountNumber;

    if (resolvedAccountNumber.isEmpty) {
      print("❌ Cannot send message: resolved account number is empty.");
      return;
    }

    try {
      CollectionReference chatsRef;

      if (widget.isLocalMunicipality) {
        chatsRef = FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(widget.municipalityId)
            .collection('chatRoomFinance')
            .doc(chatRoomId)
            .collection('accounts')
            .doc(resolvedAccountNumber)
            .collection('chats');
      } else {
        chatsRef = FirebaseFirestore.instance
            .collection('districts')
            .doc(widget.districtId)
            .collection('municipalities')
            .doc(widget.municipalityId)
            .collection('chatRoomFinance')
            .doc(chatRoomId)
            .collection('accounts')
            .doc(resolvedAccountNumber)
            .collection('chats');
      }

      await chatsRef.add(messageData);
      messageEditingController.clear();
      print("✅ Message sent to $resolvedField: $resolvedAccountNumber");

    } catch (e) {
      print("❌ Failed to send message: $e");
    }
  }


  Future<void> uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      String fileName = pickedFile.name;
      String cellNumber = FirebaseAuth.instance.currentUser!.phoneNumber!;

      if (await file.length() > 10 * 1024 * 1024) { // 10 MB limit
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image is too large (over 10 MB). Please select a smaller file.'))
        );
        return; // Stop execution if the file is too large
      }

      String mimeType = 'image/jpeg'; // Default MIME type; adjust as necessary
      if (fileName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (fileName.endsWith('.gif')) {
        mimeType = 'image/gif';
      }

      try {
        String filePath = 'finance_chat_files/$cellNumber/${widget.chatRoomId}/$fileName';
        final ref = FirebaseStorage.instance.ref().child(filePath);
        var metadata = SettableMetadata(
            contentType: mimeType,  // Ensure this is correctly set based on the file
            customMetadata: {'compressed': 'false'}
        );

        // Show snackbar to inform the user about the upload process
        const snackBar =
        SnackBar(content: Text('Uploading file... Please wait.'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);

        print("Starting upload to: $filePath");
        // Uploading the file with metadata
        TaskSnapshot uploadTask = await ref.putFile(file,metadata);
        print("Upload task state: ${uploadTask.state}");

        // Verify if the file upload was successful
        if (uploadTask.state == TaskState.success) {
          // Add delay to ensure the file is fully processed before fetching the URL
          await Future.delayed(const Duration(seconds: 1)); // Adjust as needed

          // Try to get the download URL
          String fileUrl = await ref.getDownloadURL();
          print("File uploaded successfully to: $filePath");
          print("File URL: $fileUrl"); // Debugging

          // Dismiss the snackbar after successful upload
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          sendMessage(
            chatRoomId: widget.chatRoomId,
            text: "",
            fileUrl: fileUrl,

          ); // Pass the URL to the message sender
        } else {
          print("Upload failed: ${uploadTask.state}");
          // Show an error snackbar
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: ${uploadTask.state}')));
        }
      } catch (e) {
        print("Upload error: $e");
        // Show an error snackbar
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload error: $e')));
      }
    } else {
      print("No file selected");
      // Show a snackbar for no file selected
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No file selected')));
    }
  }

  Future<void> uploadDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt', 'xlsx', 'xls'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;
      String cellNumber = FirebaseAuth.instance.currentUser!.phoneNumber!;
      // Check if the file size is within the 10 MB limit
      if (await file.length() > 10 * 1024 * 1024) { // 10 MB limit
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document is too large (over 10 MB). Please select a smaller file.'))
        );
        return; // Stop execution if the file is too large
      }

      String mimeType = 'application/octet-stream'; // Default MIME type; adjust as necessary
      if (fileName.endsWith('.pdf')) {
        mimeType = 'application/pdf';
      } else if (fileName.endsWith('.doc')) {
        mimeType = 'application/msword';
      } else if (fileName.endsWith('.docx')) {
        mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      } else if (fileName.endsWith('.ppt')) {
        mimeType = 'application/vnd.ms-powerpoint';
      } else if (fileName.endsWith('.pptx')) {
        mimeType = 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      } else if (fileName.endsWith('.txt')) {
        mimeType = 'text/plain';
      } else if (fileName.endsWith('.xls')) {
        mimeType = 'application/vnd.ms-excel';
      } else if (fileName.endsWith('.xlsx')) {
        mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      }

      try {
        String filePath = 'finance_chat_files/$cellNumber/${widget.chatRoomId}/$fileName';
        final ref = FirebaseStorage.instance.ref().child(filePath);
        var metadata = SettableMetadata(
            contentType: mimeType,
            customMetadata: {'description': 'User uploaded document'}
        );

        // Show snackbar to inform the user about the upload process
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploading document... Please wait.'))
        );

        // Uploading the file with metadata
        TaskSnapshot uploadTask = await ref.putFile(file, metadata);
        // Verify if the file upload was successful
        if (uploadTask.state == TaskState.success) {
          // Try to get the download URL
          String fileUrl = await ref.getDownloadURL();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          sendMessage(
            chatRoomId: widget.chatRoomId,
            text: "",

            fileUrl: fileUrl,
          ); // Pass the URL to the message sender
        } else {
          // Show an error snackbar
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: ${uploadTask.state}'))
          );
        }
      } catch (e) {
        // Show an error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload error: $e'))
        );
      }
    } else {
      // Show a snackbar for no file selected
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No document selected'))
      );
    }
  }

  Future<void> uploadFileWeb() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any, // ✅ Allow all file types
    );

    if (result != null) {
      PlatformFile pickedFile = result.files.first;
      Uint8List? fileBytes = pickedFile.bytes;
      String fileName = pickedFile.name;
      String cellNumber = FirebaseAuth.instance.currentUser!.phoneNumber ?? "unknown";

      if (fileBytes == null) {
        Fluttertoast.showToast(msg: "Error: Could not read file data.");
        return;
      }

      try {
        String filePath = 'finance_chat_files/$cellNumber/${widget.chatRoomId}/$fileName';
        final ref = FirebaseStorage.instance.ref().child(filePath);

        SettableMetadata metadata = SettableMetadata(
          contentType: pickedFile.extension == 'jpg' || pickedFile.extension == 'png'
              ? 'image/${pickedFile.extension}'
              : 'application/octet-stream',
        );

        // ✅ Upload file bytes to Firebase Storage
        TaskSnapshot uploadTask = await ref.putData(fileBytes, metadata);

        if (uploadTask.state == TaskState.success) {
          String fileUrl = await ref.getDownloadURL();
          sendMessage(chatRoomId: widget.chatRoomId, text: "", fileUrl: fileUrl);
          Fluttertoast.showToast(msg: "Upload Successful!");
        } else {
          Fluttertoast.showToast(msg: "Upload failed.");
        }
      } catch (e) {
        print("🚨 Upload error: $e");
        Fluttertoast.showToast(msg: "Error uploading file.");
      }
    } else {
      Fluttertoast.showToast(msg: "No file selected.");
    }
  }

  void showUploadOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              if (kIsWeb)
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Upload File'),
                  onTap: () {
                    Navigator.pop(context);
                    uploadFileWeb(); // 🌐 Handle file uploads for web
                  },
                )
              else ...[
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Upload Image'),
                  onTap: () {
                    Navigator.pop(context);
                    uploadImage(); // 📸 Handle image uploads for mobile
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: const Text('Upload Document'),
                  onTap: () {
                    Navigator.pop(context);
                    uploadDocument(); // 📄 Handle document uploads for mobile
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!hasLoadedChats) {
      return const Center(child: CircularProgressIndicator());
    }

    String chatTo = propertyAddress ?? 'Finance Queries';
    return WillPopScope(
        onWillPop: () async {
      // Trigger the refresh function when the back button is pressed
          markMessagesAsRead(widget.chatRoomId, widget.userName!);
      widget.refreshChatList();
      return true;  // Allows the pop to happen
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          chatTo,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : chatMessages(context),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: Colors.grey[350],
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () async {
                    showUploadOptions(); // This function will handle file picking and uploading
                  },
                ),

                Expanded(
                  child: TextField(
                    controller: messageEditingController,
                    style: simpleTextStyle(),
                    decoration: const InputDecoration(
                        hintText: "Message ...",
                        hintStyle: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                        border: InputBorder.none),
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
                GestureDetector(
                  onTap: () {
                    sendMessage(chatRoomId: widget.chatRoomId);
                  },
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF39833C), Color(0xFF474747)],
                            begin: FractionalOffset.topLeft,
                            end: FractionalOffset.bottomRight),
                        borderRadius: BorderRadius.circular(40)),
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      "assets/images/send.png",
                      height: 30,
                      width: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class MessageTile extends StatelessWidget {
  final String message;
  final bool sendByMe;
  final int timestamp;
  final String sendBy;
  final String? fileUrl;
// Callback for attaching files

  const MessageTile({
    super.key,
    required this.message,
    required this.sendByMe,
    required this.timestamp,
    this.fileUrl,
    required bool isRead, required this.sendBy,
    // Accept the callback in the constructor
  });

  String _formatTimestamp(int timestamp) {
    var format = DateFormat('dd MMM yyyy, hh:mm a');
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return format.format(date);
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: sendByMe ? 0 : 24,
        right: sendByMe ? 24 : 0,
      ),
      alignment: sendByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: sendByMe
            ? const EdgeInsets.only(left: 30)
            : const EdgeInsets.only(right: 30),
        padding:
        const EdgeInsets.only(top: 17, bottom: 17, left: 20, right: 20),
        decoration: BoxDecoration(
          borderRadius: sendByMe
              ? const BorderRadius.only(
              topLeft: Radius.circular(23),
              topRight: Radius.circular(23),
              bottomLeft: Radius.circular(23))
              : const BorderRadius.only(
              topLeft: Radius.circular(23),
              topRight: Radius.circular(23),
              bottomRight: Radius.circular(23)),
          color: sendByMe ? Colors.blue : Colors.grey[700],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sendBy,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 5),
            if (fileUrl != null && fileUrl!.isNotEmpty)
              InkWell(
                onTap: () => _launchURL(fileUrl!),
                child: const Row(
                  children: [
                    Icon(Icons.attachment),
                    SizedBox(width: 8),
                    Text(
                      'View File',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ],
                ),
              ),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'OverpassRegular',
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _formatTimestamp(timestamp),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFamily: 'OverpassRegular',
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Constraints class
class Constants {
  static String? myName;
}

InputDecoration textFieldInputDecoration(String hintText) {
  return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white54),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)));
}

TextStyle simpleTextStyle() {
  return const TextStyle(color: Colors.black54, fontSize: 16);
}

TextStyle biggerTextStyle() {
  return const TextStyle(color: Colors.white, fontSize: 17);
}

