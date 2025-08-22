// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:municipal_services/code/Chat/upload_file.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class Chat extends StatefulWidget {
//   final String chatRoomId;
//   final String? userName;
//
//   Chat({super.key, required this.chatRoomId, required this.userName});
//
//   @override
//   _ChatState createState() => _ChatState();
// }
//
// class _ChatState extends State<Chat> {
//   late bool _isLoading;
//   late Stream<QuerySnapshot> chats;
//   TextEditingController messageEditingController = TextEditingController();
//   final _navigatorKey = GlobalKey<NavigatorState>();
//   String chatTo = 'Administrator Chat';
//   ScrollController _scrollController = ScrollController();
//
//   @override
//   void initState() {
//     _isLoading = true;
//     checkUser();
//     _scrollController = ScrollController();
//     print(Constants.myName);
//     Future.delayed(const Duration(seconds: 3), () {
//       setState(() {
//         _isLoading = false;
//       });
//     });
//
//     DatabaseMethods().getChats(widget.chatRoomId).then((val) {
//       setState(() {
//         chats = val;
//       });
//     });
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   Future<void> checkUser() async {
//     print('username must be :::${user?.phoneNumber}');
//     if (user?.phoneNumber == null || user?.phoneNumber == '') {
//       useNum = '';
//       useEmail = user?.email!;
//       Constants.myName = useEmail;
//     } else if (user?.email == null || user?.email == '') {
//       useNum = user?.phoneNumber!;
//       useEmail = '';
//       Constants.myName = useNum;
//     }
//
//     print('chatroom name is ${widget.chatRoomId}');
//     print('username is :::${Constants.myName}');
//   }
//
//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }
//
//   Widget chatMessages(BuildContext context) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: chats,
//       builder: (context, snapshot) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (_scrollController.hasClients) {
//             _scrollToBottom();
//           }
//         });
//
//         return snapshot.hasData
//             ? SingleChildScrollView(
//           reverse: true,
//           physics: const BouncingScrollPhysics(),
//           child: Column(
//             children: [
//               ListView.builder(
//                 controller: _scrollController,
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: snapshot.data?.docs.length ?? 0,
//                 itemBuilder: (context, index) {
//                   var data = snapshot.data?.docs[index].data()
//                   as Map<String, dynamic>;
//                   return MessageTile(
//                     message: data["message"],
//                     sendByMe: Constants.myName == data["sendBy"],
//                     timestamp: data["time"],
//                     fileUrl: data["fileUrl"],
//                   );
//                 },
//               ),
//               SizedBox(height: MediaQuery
//                   .of(context)
//                   .viewInsets
//                   .bottom),
//             ],
//           ),
//         )
//             : Container();
//       },
//     );
//   }
//
//   String official = 'official';
//
//   // void uploadAndSendFile() async {
//   //   FileUploadChat uploader = FileUploadChat(widget.chatRoomId);
//   //   String? fileUrl = await uploader.pickAndUploadFile();
//   //   if (fileUrl != null) {
//   //     sendMessage(fileUrl: fileUrl);
//   //   }
//   // }
//   // Future<void> uploadFile() async {
//   //   FilePickerResult? result = await FilePicker.platform.pickFiles();
//   //
//   //   if (result != null) {
//   //     File file = File(result.files.single.path!);
//   //     String fileName = result.files.single.name;
//   //
//   //     try {
//   //       String filePath = 'chat_files/${widget.chatRoomId}/$fileName';
//   //       TaskSnapshot uploadTask =
//   //           await FirebaseStorage.instance.ref(filePath).putFile(file);
//   //       String fileUrl = await uploadTask.ref.getDownloadURL();
//   //
//   //       addMessage(fileUrl: fileUrl); // Pass the URL to the message sender
//   //     } catch (e) {
//   //       print("Upload error: $e");
//   //     }
//   //   } else {
//   //     print("No file selected");
//   //   }
//   // }
//   Future<void> uploadFile() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles();
//
//     if (result != null) {
//       File file = File(result.files.single.path!);
//       String fileName = result.files.single.name;
//
//       try {
//         String filePath = 'chat_files/${widget.chatRoomId}/$fileName';
//         TaskSnapshot uploadTask =
//         await FirebaseStorage.instance.ref(filePath).putFile(file);
//         String fileUrl = await uploadTask.ref.getDownloadURL();
//
//         addMessage(fileUrl: fileUrl); // Pass the URL to the message sender
//       } catch (e) {
//         print("Upload error: $e");
//       }
//     } else {
//       print("No file selected");
//     }
//   }
//
//
//
//   void sendMessage({String? text, String? fileUrl}) {
//     String message = text ?? "Sent a file";
//     Map<String, dynamic> messageData = {
//       "sendBy": Constants.myName,
//       "message": message,
//       "time": DateTime.now().millisecondsSinceEpoch,
//       if (fileUrl != null) "fileUrl": fileUrl,
//     };
//     DatabaseMethods().addMessage(widget.chatRoomId, messageData);
//     messageEditingController.clear();
//   }
//
//   //
//   // addMessage() {
//   //   if (messageEditingController.text.isNotEmpty) {
//   //     if (Constants.myName == '') {
//   //       Constants.myName = useEmail;
//   //       Map<String, dynamic> chatMessageMap = {
//   //         "sendBy": Constants.myName,
//   //         "message": messageEditingController.text,
//   //         'time': DateTime.now().millisecondsSinceEpoch,
//   //       };
//   //
//   //       DatabaseMethods().addMessage(widget.chatRoomId, chatMessageMap);
//   //
//   //       setState(() {
//   //         messageEditingController.text = "";
//   //       });
//   //     } else {
//   //       Map<String, dynamic> chatMessageMap = {
//   //         "sendBy": Constants.myName,
//   //         "message": messageEditingController.text,
//   //         'time': DateTime.now().millisecondsSinceEpoch,
//   //       };
//   //
//   //       DatabaseMethods().addMessage(widget.chatRoomId, chatMessageMap);
//   //
//   //       setState(() {
//   //         messageEditingController.text = "";
//   //       });
//   //     }
//   //   }
//   // }
//   void addMessage({String? fileUrl}) {
//     Map<String, dynamic> chatMessageMap = {
//       "sendBy": Constants.myName,
//       "message": fileUrl != null ? "Sent a file" : messageEditingController.text,
//       'time': DateTime.now().millisecondsSinceEpoch,
//     };
//
//     if (fileUrl?.isNotEmpty == true) {
//       chatMessageMap["fileUrl"] = fileUrl;
//     }
//
//     DatabaseMethods().addMessage(widget.chatRoomId, chatMessageMap);
//
//     setState(() {
//       messageEditingController.text = "";
//     });
//   }
//
//   Future<void> setIDName() async {
//     String thisNewChat = widget.chatRoomId;
//     DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
//         .collection(thisNewChat)
//         .doc(thisNewChat)
//         .get();
//
//     DatabaseMethods().addChatDocName(documentSnapshot, thisNewChat);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (widget.userName != null) {
//       chatTo = '${widget.userName}';
//     } else {
//       chatTo = 'Administrator Chat';
//     }
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           chatTo,
//           style: const TextStyle(color: Colors.white),
//         ),
//         backgroundColor: Colors.green,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: Stack(
//         children: [
//           _isLoading
//               ? const Center(
//                   child: CircularProgressIndicator(),
//                 )
//               : chatMessages(context),
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: 0,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//               color: Colors.grey[350],
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.attach_file),
//                     onPressed: () async {
//                       FileUploadChat upload = FileUploadChat(widget.chatRoomId);
//                       String? fileUrl = await upload.pickAndUploadFile();
//                       if (fileUrl != null) {
//                         addMessage(fileUrl: fileUrl);
//                       }
//                     }, // This triggers the file upload process
//                   ),
//                   Expanded(
//                     child: TextField(
//                       controller: messageEditingController,
//                       style: simpleTextStyle(),
//                       decoration: const InputDecoration(
//                           hintText: "Message ...",
//                           hintStyle: TextStyle(
//                             color: Colors.black54,
//                             fontSize: 16,
//                           ),
//                           border: InputBorder.none),
//                     ),
//                   ),
//                   const SizedBox(
//                     width: 16,
//                   ),
//                   GestureDetector(
//                     onTap: () {
//                       addMessage();
//                     },
//                     child: Container(
//                       height: 40,
//                       width: 40,
//                       decoration: BoxDecoration(
//                           gradient: const LinearGradient(
//                               colors: [Color(0xFF39833C), Color(0xFF474747)],
//                               begin: FractionalOffset.topLeft,
//                               end: FractionalOffset.bottomRight),
//                           borderRadius: BorderRadius.circular(40)),
//                       padding: const EdgeInsets.all(12),
//                       child: Image.asset(
//                         "assets/images/send.png",
//                         height: 30,
//                         width: 30,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class Chat extends StatefulWidget {
  final String chatRoomId;
  final String? userName;
  final CollectionReference chatCollectionRef;
  final Function refreshChatList;
  final bool
      isLocalMunicipality; // Add this flag to distinguish between local municipalities and districts
  final String districtId; // Only needed for district-based municipalities
  final String municipalityId;
  final Map<String, String>? chatRoomAccountsMap;

  const Chat({
    super.key,
    required this.chatRoomId,
    required this.userName,
    required this.chatCollectionRef,
    required this.refreshChatList,
    required this.isLocalMunicipality,
    required this.districtId, // Pass the districtId for district-based properties
    required this.municipalityId,
    required this.chatRoomAccountsMap,
  });

  @override
  _ChatState createState() => _ChatState();
}

final FirebaseAuth auth = FirebaseAuth.instance;

final User? user = auth.currentUser;
final uid = user?.uid;
final email = user?.email;
String userID = uid as String;
String userEmail = email as String;
DateTime now = DateTime.now();

class _ChatState extends State<Chat> {
  String districtId = '';
  String municipalityId = '';
  late bool _isLoading;
  late Stream<QuerySnapshot> chats;
  late CollectionReference _chatsList;
  TextEditingController messageEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? propertyAddress;
  late String accountNumber;
  late String matchedAccountField;


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
      fetchChats(); // ✅ safe to use _chatsList now

      fetchPropertyAddress();
      createOrUpdateChatRoom();
      markMessagesAsRead(widget.chatRoomId, widget.userName);

      if (mounted) {
        setState(() {
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
    _chatsList = FirebaseFirestore.instance.collection('dummyPath/invalid/chats');

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
      _chatsList = isLocalMunicipality
          ? FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('chatRoom')
          .doc(widget.chatRoomId)
          .collection('accounts')
          .doc(accountNumberToUse)
          .collection('chats')
          : FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('chatRoom')
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

      _chatsList = widget.isLocalMunicipality
          ? FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(widget.municipalityId)
          .collection('chatRoom')
          .doc(widget.chatRoomId)
          .collection('accounts')
          .doc(accountNumberToUse)
          .collection('chats')
          : FirebaseFirestore.instance
          .collection('districts')
          .doc(widget.districtId)
          .collection('municipalities')
          .doc(widget.municipalityId)
          .collection('chatRoom')
          .doc(widget.chatRoomId)
          .collection('accounts')
          .doc(accountNumberToUse)
          .collection('chats');

      print("✅ Chat path initialized for regular user with $matchedField = $accountNumberToUse");
      return true;
    }

    print("❌ No logged in user.");
    return false;
  }

  void fetchChats() {
    chats = _chatsList.orderBy('time', descending: false).snapshots();
  }

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
            .collection('chatRoom')
            .doc(widget.chatRoomId);

        accountRef = chatRoomRef.collection('accounts').doc(accountNumberToUse);
      } else {
        chatRoomRef = FirebaseFirestore.instance
            .collection('districts')
            .doc(widget.districtId)
            .collection('municipalities')
            .doc(widget.municipalityId)
            .collection('chatRoom')
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

    // Decide matched field
    String matchedAccountField = '';
    String accountNumberToUse = '';

    if (elecAccNo.isNotEmpty && (accNo.isEmpty || elecAccNo == widget.userName)) {
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
            .collection('chatRoom')
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
            .collection('chatRoom')
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

  // void fetchChats(String phoneNumber) {
  //   CollectionReference chatsCollection;
  //
  //   if (widget.isLocalMunicipality) {
  //     chatsCollection = FirebaseFirestore.instance
  //         .collection('localMunicipalities')
  //         .doc(widget.municipalityId)
  //         .collection('chatRoom')
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
  //         .collection('chatRoom')
  //         .doc(phoneNumber)
  //         .collection('accounts')
  //         .doc(widget.userName)
  //         .collection('chats');
  //   }
  //
  //   chats = chatsCollection.orderBy('time').snapshots();
  // }

  Future<void> uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      String fileName = pickedFile.name;
      String cellNumber = FirebaseAuth.instance.currentUser!.phoneNumber!;
      if (await file.length() > 10 * 1024 * 1024) {
        // 10 MB limit
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Image is too large (over 10 MB). Please select a smaller file.')));
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
        String filePath =
            'chat_files/$cellNumber/${widget.chatRoomId}/$fileName';
        final ref = FirebaseStorage.instance.ref().child(filePath);
        var metadata = SettableMetadata(
            contentType:
                mimeType, // Ensure this is correctly set based on the file
            customMetadata: {'compressed': 'false'});

        // Show snackbar to inform the user about the upload process
        const snackBar =
            SnackBar(content: Text('Uploading file... Please wait.'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);

        print("Starting upload to: $filePath");
        // Uploading the file with metadata
        TaskSnapshot uploadTask = await ref.putFile(file, metadata);
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
          .showSnackBar(const SnackBar(content: Text('No file selected')));
    }
  }

  Future<void> uploadDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'ppt',
        'pptx',
        'txt',
        'xlsx',
        'xls'
      ],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;
      String cellNumber = FirebaseAuth.instance.currentUser!.phoneNumber!;
      // Check if the file size is within the 10 MB limit
      if (await file.length() > 10 * 1024 * 1024) {
        // 10 MB limit
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Document is too large (over 10 MB). Please select a smaller file.')));
        return; // Stop execution if the file is too large
      }

      String mimeType =
          'application/octet-stream'; // Default MIME type; adjust as necessary
      if (fileName.endsWith('.pdf')) {
        mimeType = 'application/pdf';
      } else if (fileName.endsWith('.doc')) {
        mimeType = 'application/msword';
      } else if (fileName.endsWith('.docx')) {
        mimeType =
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      } else if (fileName.endsWith('.ppt')) {
        mimeType = 'application/vnd.ms-powerpoint';
      } else if (fileName.endsWith('.pptx')) {
        mimeType =
            'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      } else if (fileName.endsWith('.txt')) {
        mimeType = 'text/plain';
      } else if (fileName.endsWith('.xls')) {
        mimeType = 'application/vnd.ms-excel';
      } else if (fileName.endsWith('.xlsx')) {
        mimeType =
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      }

      try {
        String filePath =
            'chat_files/$cellNumber/${widget.chatRoomId}/$fileName';
        final ref = FirebaseStorage.instance.ref().child(filePath);
        var metadata = SettableMetadata(
            contentType: mimeType,
            customMetadata: {'description': 'User uploaded document'});

        // Show snackbar to inform the user about the upload process
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Uploading document... Please wait.')));

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
              SnackBar(content: Text('Upload failed: ${uploadTask.state}')));
        }
      } catch (e) {
        // Show an error snackbar
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload error: $e')));
      }
    } else {
      // Show a snackbar for no file selected
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No document selected')));
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
        String filePath = 'chat_files/$cellNumber/${widget.chatRoomId}/$fileName';
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
  // void sendMessage({
  //   String? text,
  //   String? fileUrl,
  //   required String chatRoomId,
  //   // This will be your accountNumber
  // }) {
  //   User? user = FirebaseAuth.instance.currentUser;
  //
  //   if (user == null) {
  //     // Handle unauthenticated user scenario
  //     print("User is not authenticated, message not sent.");
  //     // Optionally, redirect the user to a login screen or show an error message
  //     return;
  //   }
  //
  //
  //   print("Initial text: $text");
  //   print("File URL: $fileUrl");
  //   String message = messageEditingController.text.trim();
  //   print("Trimmed message: $message");
  //   if (message.isEmpty && fileUrl == null) {
  //     print("Message is empty and no file URL provided, not sending.");
  //     return;
  //   }
  //
  //   // If the message is empty but a fileUrl exists, set a default message
  //   if (message.isEmpty && fileUrl != null) {
  //     message = "File has been sent";
  //     print("Message was empty, setting default message: $message");
  //   }
  //
  //
  //   print("Final message to send: $message");
  //
  //
  //   String sendBy;
  //   if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
  //     sendBy = user.phoneNumber!;
  //   } else if (user.email != null && user.email!.isNotEmpty) {
  //     sendBy = user.email!;
  //   } else {
  //     sendBy = 'Unknown User';  // Fallback in case both are missing
  //   }
  //   CollectionReference chatsCollection;
  //
  //   if (widget.isLocalMunicipality) {
  //     chatsCollection = FirebaseFirestore.instance
  //         .collection('localMunicipalities')
  //         .doc(widget.municipalityId)
  //         .collection('chatRoom')
  //         .doc(chatRoomId)
  //         .collection('accounts')
  //         .doc(widget.userName)
  //         .collection('chats');
  //   } else {
  //     chatsCollection = FirebaseFirestore.instance
  //         .collection('districts')
  //         .doc(widget.districtId)
  //         .collection('municipalities')
  //         .doc(widget.municipalityId)
  //         .collection('chatRoom')
  //         .doc(chatRoomId)
  //         .collection('accounts')
  //         .doc(widget.userName)
  //         .collection('chats');
  //   }
  //
  //   Map<String, dynamic> messageData = {
  //     "sendBy": sendBy,  // Correctly set sendBy to phone number or email
  //     "message": message,
  //     "time": DateTime.now().millisecondsSinceEpoch,
  //     "isRead": false,
  //     if (fileUrl != null) "fileUrl": fileUrl,
  //   };
  //   // Add the message to the correct path
  //   chatsCollection.add(messageData).then((_) {
  //     print("Message sent successfully.");
  //   }).catchError((error) {
  //     print("Failed to send message: $error");
  //   });
  //
  //   messageEditingController.clear();
  // }

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
      "message": text ?? '',
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
            .collection('chatRoom')
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
            .collection('chatRoom')
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

  // Widget chatMessages(BuildContext context) {
  //   return StreamBuilder<QuerySnapshot>(
  //     stream: chats,
  //     builder: (context, snapshot) {
  //       WidgetsBinding.instance.addPostFrameCallback((_) {
  //         if (_scrollController.hasClients) {
  //           _scrollToBottom();
  //         }
  //       });
  //
  //       return snapshot.hasData
  //           ? SingleChildScrollView(
  //               reverse: true,
  //               physics: const BouncingScrollPhysics(),
  //               child: Column(
  //                 children: [
  //                   ListView.builder(
  //                     controller: _scrollController,
  //                     shrinkWrap: true,
  //                     physics: const NeverScrollableScrollPhysics(),
  //                     itemCount: snapshot.data?.docs.length ?? 0,
  //                     itemBuilder: (context, index) {
  //                       var data = snapshot.data?.docs[index].data()
  //                           as Map<String, dynamic>;
  //                       String currentUserIdentifier;
  //
  //                       // Determine the current user's identifier (phone number or email)
  //                       if (FirebaseAuth.instance.currentUser != null) {
  //                         if (FirebaseAuth.instance.currentUser!.phoneNumber !=
  //                                 null &&
  //                             FirebaseAuth.instance.currentUser!.phoneNumber!
  //                                 .isNotEmpty) {
  //                           currentUserIdentifier =
  //                               FirebaseAuth.instance.currentUser!.phoneNumber!;
  //                         } else {
  //                           currentUserIdentifier =
  //                               FirebaseAuth.instance.currentUser!.email!;
  //                         }
  //                       } else {
  //                         currentUserIdentifier = 'Unknown User';
  //                       }
  //
  //                       // Check if the message was sent by the current user
  //                       bool sendByMe = data["sendBy"] == currentUserIdentifier;
  //
  //                       return MessageTile(
  //                         message: data["message"],
  //                         sendByMe: sendByMe,
  //                         timestamp: data["time"],
  //                         isRead: false,
  //                         fileUrl: data["fileUrl"],
  //                       );
  //                     },
  //                   ),
  //                   SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
  //                 ],
  //               ),
  //             )
  //           : Container();
  //     },
  //   );
  // }
  Widget chatMessages(BuildContext context) {
    // ✅ Use already-resolved values
    final String resolvedAccountNumber = accountNumber;
    final String resolvedField = matchedAccountField;

    if (resolvedAccountNumber.isEmpty) {
      print("❌ No valid account number found in chatMessages.");
      return const Center(child: Text("Error loading chat."));
    }

    CollectionReference chatsRef;

    if (widget.isLocalMunicipality) {
      chatsRef = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(widget.municipalityId)
          .collection('chatRoom')
          .doc(widget.chatRoomId)
          .collection('accounts')
          .doc(resolvedAccountNumber)
          .collection('chats');
    } else {
      chatsRef = FirebaseFirestore.instance
          .collection('districts')
          .doc(widget.districtId)
          .collection('municipalities')
          .doc(widget.municipalityId)
          .collection('chatRoom')
          .doc(widget.chatRoomId)
          .collection('accounts')
          .doc(resolvedAccountNumber)
          .collection('chats');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: chatsRef.orderBy('time', descending: false).snapshots(),
      builder: (context, snapshot) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollToBottom();
          }
        });

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Leave a message for any queries, and someone will get back to you.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          );
        }

        final currentUserIdentifier = FirebaseAuth.instance.currentUser?.phoneNumber ??
            FirebaseAuth.instance.currentUser?.email ??
            '';

        // 🔄 Mark unread messages as read
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final sendBy = data["sendBy"];

          if ((sendBy != currentUserIdentifier) &&
              ((currentUserIdentifier.contains('@') && !data["isReadByMunicipalUser"]) ||
                  (!currentUserIdentifier.contains('@') && !data["isReadByRegularUser"]))) {
            doc.reference.update({
              currentUserIdentifier.contains('@')
                  ? "isReadByMunicipalUser"
                  : "isReadByRegularUser": true,
            });
          }
        }

        return SingleChildScrollView(
          reverse: true,
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  final sendByMe = data["sendBy"] == currentUserIdentifier;

                  return MessageTile(
                    message: data["message"],
                    sendByMe: sendByMe,
                    timestamp: data["time"],
                    sendBy: data["sendBy"],
                    isRead: data[currentUserIdentifier.contains('@')
                        ? "isReadByMunicipalUser"
                        : "isReadByRegularUser"],
                    fileUrl: data["fileUrl"],
                  );
                },
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    String chatTo = propertyAddress ?? 'Administrator Queries';

    return WillPopScope(
      onWillPop: () async {
        markMessagesAsRead(widget.chatRoomId, widget.userName!);
        // Trigger the refresh function when the back button is pressed
        widget.refreshChatList();
        return true; // Allows the pop to happen
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
                  ? const Center(child: CircularProgressIndicator())
                  : chatMessages(context),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              color: Colors.grey[350],
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed:
                        showUploadOptions, // Show upload options when pressed
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
                      sendMessage(
                        text: messageEditingController.text,
                        chatRoomId:
                            widget.chatRoomId, // Pass the correct chatRoomId
                      );
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

String? useNum;
String? useEmail;

class Constants {
  static String? myName = useNum;
}

Widget appBarMain(BuildContext context) {
  return AppBar(
    title: Image.asset(
      "assets/images/logo.png",
      height: 40,
    ),
    elevation: 0.0,
    centerTitle: false,
  );
}

InputDecoration textFieldInputDecoration(String hintText) {
  return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white54),
      focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white)),
      enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white)));
}

TextStyle simpleTextStyle() {
  return const TextStyle(color: Colors.black54, fontSize: 16);
}

TextStyle biggerTextStyle() {
  return const TextStyle(color: Colors.white, fontSize: 17);
}

