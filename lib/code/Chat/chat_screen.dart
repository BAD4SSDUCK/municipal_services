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

class Chat extends StatefulWidget {
  final String chatRoomId;
  final String? userName;
  final CollectionReference chatCollectionRef;
  final Function refreshChatList;
  final bool
      isLocalMunicipality; // Add this flag to distinguish between local municipalities and districts
  final String districtId; // Only needed for district-based municipalities
  final String municipalityId;

  Chat({
    super.key,
    required this.chatRoomId,
    required this.userName,
    required this.chatCollectionRef,
    required this.refreshChatList,
    required this.isLocalMunicipality,
    required this.districtId, // Pass the districtId for district-based properties
    required this.municipalityId,
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

  @override
  void initState() {
    super.initState();
    print('Initializing chat with chatRoomId: ${widget.chatRoomId}');
    fetchPropertyAddress();
    // Initialize _chatsList with the passed chatCollectionRef from the widget
    initializeChatCollectionReference();
    createOrUpdateChatRoom();

    _isLoading = true;

    // Fetch chat data
    fetchChats();
    markMessagesAsRead(widget.chatRoomId, widget.userName);
    // Delay to stop loading indicator after fetching chats
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
    _scrollController.dispose();
    super.dispose();
  }

  void initializeChatCollectionReference() {
    if (widget.isLocalMunicipality) {
      _chatsList = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(widget.municipalityId)
          .collection('chatRoom')
          .doc(widget.chatRoomId)
          .collection('accounts')
          .doc(widget.userName)
          .collection('chats');
    } else {
      _chatsList = FirebaseFirestore.instance
          .collection('districts')
          .doc(widget.districtId)
          .collection('municipalities')
          .doc(widget.municipalityId)
          .collection('chatRoom')
          .doc(widget.chatRoomId)
          .collection('accounts')
          .doc(widget.userName)
          .collection('chats');
    }
  }

  void fetchChats() {
    chats = _chatsList.orderBy('time', descending: false).snapshots();
  }


  Future<void> fetchPropertyAddress() async {
    String? address = await getPropertyAddress(
      widget.userName ?? '',
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
      // Reference to the chat room document based on the user's phone number
      DocumentReference chatRoomRef;
      DocumentReference accountRef;

      if (widget.isLocalMunicipality) {
        // Reference for the cell number document
        chatRoomRef = FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(widget.municipalityId)
            .collection('chatRoom')
            .doc(widget.chatRoomId); // Document for the user's phone number

        // Reference for the account number document under the phone number
        accountRef = chatRoomRef
            .collection('accounts')
            .doc(widget.userName); // Document for the property account number
      } else {
        chatRoomRef = FirebaseFirestore.instance
            .collection('districts')
            .doc(widget.districtId)
            .collection('municipalities')
            .doc(widget.municipalityId)
            .collection('chatRoom')
            .doc(widget.chatRoomId); // Document for the user's phone number

        accountRef = chatRoomRef
            .collection('accounts')
            .doc(widget.userName); // Document for the property account number
      }

      // Set or update the cell number document with the 'chatRoom' field
      await chatRoomRef.set({
        'chatRoom':
            widget.chatRoomId, // The phone number is the 'chatRoom' value here
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Set or update the account number document under the user's phone number
      await accountRef.set({
        'chatRoom':
            widget.userName, // Use accountNumber as the 'chatRoom' field here
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print(
          'Chat room created/updated for phoneNumber: ${widget.chatRoomId} and accountNumber: ${widget.userName}');
    } catch (e) {
      print('Error creating or updating chat room: $e');
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
      String accountNumber, String districtId, String municipalityId, bool isLocalMunicipality) async {
    try {
      QuerySnapshot propertiesSnapshot;

      if (isLocalMunicipality) {
        // 🔍 Search in the Local Municipality collection
        propertiesSnapshot = await FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(municipalityId)
            .collection('properties')
            .where('accountNumber', isEqualTo: accountNumber)
            .limit(1)
            .get();
      } else {
        // 🔍 Search in the District Municipality collection
        propertiesSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('properties')
            .where('accountNumber', isEqualTo: accountNumber)
            .limit(1)
            .get();
      }

      if (propertiesSnapshot.docs.isNotEmpty) {
        var propertyData = propertiesSnapshot.docs.first.data() as Map<String, dynamic>;
        String propertyAddress = propertyData['address'];
        print('✅ Property Address Found: $propertyAddress');
        return propertyAddress;
      } else {
        print('❌ No property found for account number: $accountNumber');
        return null;
      }
    } catch (e) {
      print('🚨 Error fetching property address: $e');
      return null;
    }
  }


  void markMessagesAsRead(String phoneNumber, String? accountNumber) async {
    CollectionReference chatsCollection;

    // Determine the correct path for the chat collection
    if (widget.isLocalMunicipality) {
      chatsCollection = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(widget.municipalityId)
          .collection('chatRoom')
          .doc(phoneNumber)
          .collection('accounts')
          .doc(accountNumber)
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
          .doc(accountNumber)
          .collection('chats');
    }

    // Get current user's identifier (phone number or email) to differentiate
    final currentUser = FirebaseAuth.instance.currentUser;
    String currentUserIdentifier =
        currentUser?.phoneNumber ?? currentUser?.email ?? '';

    // Only mark messages as read if they were sent by the other party
    QuerySnapshot unreadMessagesSnapshot =
        await chatsCollection.where('isRead', isEqualTo: false).get();

    for (var doc in unreadMessagesSnapshot.docs) {
      if (doc['sendBy'] != currentUserIdentifier) {
        await doc.reference.update({'isRead': true});
      }
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
          .showSnackBar(SnackBar(content: Text('No file selected')));
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
  }) {
    if (messageEditingController.text.trim().isEmpty && fileUrl == null) {
      return; // Do not send if both text and file are empty
    }

    // Determine the current user identifier (phone number or email)
    String currentUserIdentifier;
    if (FirebaseAuth.instance.currentUser!.phoneNumber != null) {
      // Regular user
      currentUserIdentifier = FirebaseAuth.instance.currentUser!.phoneNumber!;
    } else {
      // Municipal user
      currentUserIdentifier = FirebaseAuth.instance.currentUser!.email!;
    }

    // Set isRead fields based on who is sending the message
    bool isReadByRegularUser = currentUserIdentifier == FirebaseAuth.instance.currentUser!.phoneNumber;
    bool isReadByMunicipalUser = currentUserIdentifier != FirebaseAuth.instance.currentUser!.phoneNumber;

    Map<String, dynamic> messageData = {
      "sendBy": currentUserIdentifier,
      "message": text ?? '',
      "time": DateTime.now().millisecondsSinceEpoch,
      "isReadByRegularUser": isReadByRegularUser,    // Set based on sender type
      "isReadByMunicipalUser": isReadByMunicipalUser, // Set based on sender type
      if (fileUrl != null) "fileUrl": fileUrl,
    };

    _chatsList.add(messageData);
    messageEditingController.clear();
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
                  "Leave a message for any queries, and someone will get back to you.",
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

