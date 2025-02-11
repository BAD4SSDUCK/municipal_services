import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Models/notify_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;

class ChatCouncillor extends StatefulWidget {
  final String chatRoomId;
  final String councillorName;
  final String userId;
  final bool isLocalMunicipality;
  final String districtId; // Required when not a local municipality
  final String municipalityId;

  const ChatCouncillor({
    super.key,
    required this.chatRoomId,
    required this.councillorName,
    required this.userId,
    required this.isLocalMunicipality,
    required this.districtId,
    required this.municipalityId,
  });

  @override
  _ChatCouncillorState createState() => _ChatCouncillorState();
}

class _ChatCouncillorState extends State<ChatCouncillor> {
  late CollectionReference _messages;
  Stream<QuerySnapshot>? messageStream;
  TextEditingController messageEditingController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  String? regularUserPhoneNumber;
  String? councillorName;
  bool isCouncillor = false;
  bool hasUnreadCouncillorMessages = false;
  StreamSubscription<QuerySnapshot>? unreadCouncillorMessagesSubscription;

  @override
  void initState() {
    super.initState();
    initializeChatCollectionReference();
    print("ChatCouncillor initState called.");
    checkIfCouncillor().then((result) {
      if(mounted) {
        setState(() {
          isCouncillor = result;
        });
      }
      checkForUnreadCouncilMessages(); // Start checking for unread messages
    });
    initializeChat();
  }

  @override
  void dispose() {
    unreadCouncillorMessagesSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> initializeChat() async {
    try {
      await checkIfCouncillor();
      if (_messages == null) {
        throw Exception("Chat collection reference (_messages) not initialized.");
      }
      fetchMessages();
      markMessagesAsRead();
    } catch (e) {
      print("Error during chat initialization: $e");
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
        String? selectedPropertyAccountNumber = prefs.getString('selectedPropertyAccountNo');
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
            String? districtId = propertyDoc.data().toString().contains('districtId')
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
            unreadCouncillorMessagesSubscription = councillorChatsCollection.snapshots().listen(
                  (councillorSnapshot) async {
                bool hasUnread = false;

                if (isCouncillor) {
                  String councillorPhoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
                  councillorChatsCollection
                      .doc(councillorPhoneNumber)
                      .collection('userChats')
                      .snapshots()
                      .listen((userChatSnapshot) {
                    for (var userChatDoc in userChatSnapshot.docs) {
                      userChatDoc.reference.collection('messages').snapshots().listen((messagesSnapshot) {
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
                          print("Real-time badge updated: $hasUnreadCouncillorMessages");
                        }
                      });
                    }
                  });
                } else {
                  for (var councillorDoc in councillorSnapshot.docs) {
                    councillorDoc.reference.collection('userChats').snapshots().listen((userChatSnapshot) {
                      for (var userChatDoc in userChatSnapshot.docs) {
                        userChatDoc.reference.collection('messages').snapshots().listen((messagesSnapshot) {
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
                            print("Real-time badge updated: $hasUnreadCouncillorMessages");
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


  // Future<void> identifyUser() async {
  //   print("Identifying user...");
  //   User? currentUser = FirebaseAuth.instance.currentUser;
  //
  //   if (currentUser == null) {
  //     print("Error: No authenticated user found.");
  //     return;
  //   }
  //
  //   String phoneNumber = currentUser.phoneNumber ?? '';
  //   print("Current user's phone number: $phoneNumber");
  //
  //   bool isCouncillor = await isUserCouncillor(phoneNumber);
  //
  //   if (isCouncillor) {
  //     print("Logged-in user is a councillor");
  //     initializeChatCollectionReferenceForCouncillor();
  //   } else {
  //     print("Logged-in user is a regular user");
  //     regularUserPhoneNumber = phoneNumber;
  //
  //     if (regularUserPhoneNumber != null) {
  //       print("Initializing chat collection reference for user...");
  //       initializeChatCollectionReference();
  //       fetchMessages();
  //       createOrUpdateChatRoom();
  //     } else {
  //       print("No regular user phone number available.");
  //     }
  //   }
  // }
  //
  // Future<bool> isUserCouncillor(String phoneNumber) async {
  //   print("Checking if user is a councillor for phone: $phoneNumber");
  //   try {
  //     QuerySnapshot councillorCheck = widget.isLocalMunicipality
  //         ? await FirebaseFirestore.instance
  //         .collection('localMunicipalities')
  //         .doc(widget.municipalityId)
  //         .collection('councillors')
  //         .where('councillorPhone', isEqualTo: phoneNumber)
  //         .limit(1)
  //         .get()
  //         : await FirebaseFirestore.instance
  //         .collection('districts')
  //         .doc(widget.districtId)
  //         .collection('municipalities')
  //         .doc(widget.municipalityId)
  //         .collection('councillors')
  //         .where('councillorPhone', isEqualTo: phoneNumber)
  //         .limit(1)
  //         .get();
  //
  //     if (councillorCheck.docs.isNotEmpty) {
  //       var councillorData = councillorCheck.docs.first.data() as Map<String, dynamic>;
  //       print("Councillor found: ${councillorData['councillorName']}");
  //       setState(() {
  //         councillorName = councillorData['councillorName'] ?? "Councillor";
  //       });
  //       return true;
  //     }
  //     print("No councillor details found for phone: $phoneNumber");
  //     return false;
  //   } catch (e) {
  //     print("Error checking councillor status: $e");
  //     return false;
  //   }
  // }

  void initializeChatCollectionReferenceForCouncillor() {
    if (widget.councillorName == null || widget.chatRoomId == null) {
      print("Error: Missing councillor details for chat initialization.");
      return;
    }

    // Initialize the correct path for the councillor to fetch messages
    _messages = widget.isLocalMunicipality
        ? FirebaseFirestore.instance
        .collection('localMunicipalities')
        .doc(widget.municipalityId)
        .collection('chatRoomCouncillor')
        .doc(widget.chatRoomId) // Councillor's phone
        .collection('userChats')
        .doc(widget.userId) // Regular user's phone
        .collection('messages')
        : FirebaseFirestore.instance
        .collection('districts')
        .doc(widget.districtId)
        .collection('municipalities')
        .doc(widget.municipalityId)
        .collection('chatRoomCouncillor')
        .doc(widget.chatRoomId) // Councillor's phone
        .collection('userChats')
        .doc(widget.userId) // Regular user's phone
        .collection('messages');

    print("Chat collection reference for councillor initialized: ${_messages.path}");
    fetchMessagesForCouncillor();
  }

  void fetchMessagesForCouncillor() {
    if (_messages == null) {
      print("Error: _messages is null for councillor.");
      return;
    }
      if(mounted) {
        setState(() {
          messageStream =
              _messages.snapshots(); // Fetch all userChats for the councillor
          _isLoading = false;
        });
      }
    print("Fetching messages for councillor from: ${_messages.path}");
  }

  void initializeChatCollectionReference() {
    // Validate input values
    if (widget.chatRoomId == null || widget.chatRoomId!.isEmpty) {
      print("Error: Chat Room ID is null or empty.");
      return;
    }

    String? userPhoneNumber = regularUserPhoneNumber ?? widget.userId;

    if (userPhoneNumber == null || userPhoneNumber.isEmpty) {
      print("Error: User phone number is null or empty. Unable to initialize chat reference.");
      return;
    }

    // Determine the correct path based on municipality type
    _messages = widget.isLocalMunicipality
        ? FirebaseFirestore.instance
        .collection('localMunicipalities')
        .doc(widget.municipalityId)
        .collection('chatRoomCouncillor')
        .doc(widget.chatRoomId)
        .collection('userChats')
        .doc(userPhoneNumber)
        .collection('messages')
        : FirebaseFirestore.instance
        .collection('districts')
        .doc(widget.districtId)
        .collection('municipalities')
        .doc(widget.municipalityId)
        .collection('chatRoomCouncillor')
        .doc(widget.chatRoomId)
        .collection('userChats')
        .doc(userPhoneNumber)
        .collection('messages');

    print("Chat collection reference initialized: ${_messages.path}");
  }


  void fetchMessages() {
    if (_messages == null) {
      print("Error: _messages is null.");
      return;
    }
        if(mounted) {
          setState(() {
            messageStream =
                _messages.orderBy('time', descending: false).snapshots();
            _isLoading = false;
          });
        }
    print("Fetching messages from: ${_messages.path}");
  }


  Future<void> createOrUpdateChatRoom() async {
    if (regularUserPhoneNumber == null) {
      print("Error: Regular user phone number is null");
      return;
    }

    try {
      DocumentReference councillorRef = widget.isLocalMunicipality
          ? FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(widget.municipalityId)
          .collection('chatRoomCouncillor')
          .doc(widget.chatRoomId) // Councillor's phone
          : FirebaseFirestore.instance
          .collection('districts')
          .doc(widget.districtId)
          .collection('municipalities')
          .doc(widget.municipalityId)
          .collection('chatRoomCouncillor')
          .doc(widget.chatRoomId); // Councillor's phone

      DocumentReference userChatRef = councillorRef
          .collection('userChats')
          .doc(regularUserPhoneNumber); // Regular user's phone

      // Update or create the councillor's document
      await councillorRef.set({
        'councillorPhone': widget.chatRoomId,
        'councillorName': councillorName ?? widget.councillorName, // Use the updated councillor name
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update or create the user chat document
      await userChatRef.set({
        'chatRoom': regularUserPhoneNumber,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print(
          'Councillor chat room and user chat created/updated: ${userChatRef.path}');
    } catch (e) {
      print('Error creating/updating councillor chat room: $e');
    }
  }


  Future<void> sendMessage({String? text, String? fileUrl}) async {
    if (messageEditingController.text.trim().isEmpty && fileUrl == null) return;

    if (_messages == null) {
      print("Error: _messages reference is not initialized.");
      return;
    }

    try {
      // Determine if the sender is a councillor
      bool isCouncillor = await checkIfCouncillor();

      // Set the read flags based on the sender's role
      Map<String, dynamic> messageData = {
        "sendBy": FirebaseAuth.instance.currentUser?.phoneNumber,
        "message": text ?? '',
        "time": DateTime.now().millisecondsSinceEpoch,
        "isReadByCouncillor": isCouncillor, // True if sent by councillor
        "isReadByUser": !isCouncillor,      // True if sent by user
        if (fileUrl != null) "fileUrl": fileUrl,
      };

      // Add the message to Firestore
      await _messages.add(messageData);
      messageEditingController.clear();
      print("Message sent to: ${_messages.path}");
    } catch (e) {
      print("Error sending message: $e");
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
        String filePath = 'councillor_chat_files/$cellNumber/${widget.chatRoomId}/$fileName';
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
        String filePath = 'councillor_chat_files/$cellNumber/${widget.chatRoomId}/$fileName';
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
        String filePath = 'councillor_chat_files/$cellNumber/${widget.chatRoomId}/$fileName';
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
          sendMessage( text: "", fileUrl: fileUrl);
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



  Future<void> markMessagesAsRead() async {
    if (_messages == null) {
      print("Error: _messages reference is not initialized.");
      return;
    }

    try {
      String currentUserPhone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
      bool isCouncillor = await checkIfCouncillor();

      QuerySnapshot unreadMessages = await _messages
          .where(isCouncillor ? 'isReadByCouncillor' : 'isReadByUser', isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({
          isCouncillor ? 'isReadByCouncillor' : 'isReadByUser': true,
        });
      }

      print("Marked all messages as read for ${isCouncillor ? 'councillor' : 'user'}: $currentUserPhone");
    } catch (e) {
      print("Error marking messages as read: $e");
    }

  }


  Widget chatMessages() {
    if (messageStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: messageStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading messages"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No messages"));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        return ListView.builder(
          controller: _scrollController,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            bool sendByMe = data["sendBy"] == FirebaseAuth.instance.currentUser?.phoneNumber;

            return MessageTile(
              message: data["message"],
              sendByMe: sendByMe,
              timestamp: data["time"],
              fileUrl: data["fileUrl"],
            );
          },
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Chat with ${widget.councillorName}',
              style: const TextStyle(color: Colors.white),
            ),
            if (hasUnreadCouncillorMessages)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator()) : chatMessages()),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: Colors.grey[350],
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: showUploadOptions,// Implement file upload logic
                ),
                Expanded(
                  child: TextField(
                    controller: messageEditingController,
                    decoration: const InputDecoration(
                      hintText: "Type a message",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => sendMessage(text: messageEditingController.text),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class MessageTile extends StatelessWidget {
  final String message;
  final bool sendByMe;
  final int timestamp;
  final String? fileUrl;

  const MessageTile({
    super.key,
    required this.message,
    required this.sendByMe,
    required this.timestamp,
    this.fileUrl,
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
        padding: const EdgeInsets.only(
          top: 17,
          bottom: 17,
          left: 20,
          right: 20,
        ),
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
            if (fileUrl != null && fileUrl!.isNotEmpty)
              InkWell(
                onTap: () => _launchURL(fileUrl!),
                child: const Row(
                  children: [
                    Icon(Icons.attachment, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'View File',
                      style: TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                      ),
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
