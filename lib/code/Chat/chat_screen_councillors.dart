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
import 'package:url_launcher/url_launcher.dart';
import '../Models/notify_provider.dart';

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

  @override
  void initState() {
    super.initState();
    print("ChatCouncillor initState called.");
    councillorName = widget.councillorName;
    initializeChat();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }


  Future<void> initializeChat() async {
    try {
      await identifyUser();
      if (_messages == null) {
        throw Exception("Chat collection reference (_messages) not initialized.");
      }
      fetchMessages();
      markMessagesAsRead();
    } catch (e) {
      print("Error during chat initialization: $e");
    }
  }


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> identifyUser() async {
    print("Identifying user...");
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      print("Error: No authenticated user found.");
      return;
    }

    String phoneNumber = currentUser.phoneNumber ?? '';
    print("Current user's phone number: $phoneNumber");

    bool isCouncillor = await isUserCouncillor(phoneNumber);

    if (isCouncillor) {
      print("Logged-in user is a councillor");
      initializeChatCollectionReferenceForCouncillor();
    } else {
      print("Logged-in user is a regular user");
      regularUserPhoneNumber = phoneNumber;

      if (regularUserPhoneNumber != null) {
        print("Initializing chat collection reference for user...");
        initializeChatCollectionReference();
        fetchMessages();
        createOrUpdateChatRoom();
      } else {
        print("No regular user phone number available.");
      }
    }
  }

  Future<bool> isUserCouncillor(String phoneNumber) async {
    print("Checking if user is a councillor for phone: $phoneNumber");
    try {
      QuerySnapshot councillorCheck = widget.isLocalMunicipality
          ? await FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(widget.municipalityId)
          .collection('councillors')
          .where('councillorPhone', isEqualTo: phoneNumber)
          .limit(1)
          .get()
          : await FirebaseFirestore.instance
          .collection('districts')
          .doc(widget.districtId)
          .collection('municipalities')
          .doc(widget.municipalityId)
          .collection('councillors')
          .where('councillorPhone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (councillorCheck.docs.isNotEmpty) {
        var councillorData = councillorCheck.docs.first.data() as Map<String, dynamic>;
        print("Councillor found: ${councillorData['councillorName']}");
        setState(() {
          councillorName = councillorData['councillorName'] ?? "Councillor";
        });
        return true;
      }
      print("No councillor details found for phone: $phoneNumber");
      return false;
    } catch (e) {
      print("Error checking councillor status: $e");
      return false;
    }
  }

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
    if (regularUserPhoneNumber == null && councillorName != null) {
      print("Error: No regular user phone number. Defaulting to councillor logic.");
      return; // Ensure no action if regular user phone number is not set
    }

    String userPhoneNumber = regularUserPhoneNumber ?? widget.userId;

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
      bool isCouncillor = await isUserCouncillor(FirebaseAuth.instance.currentUser?.phoneNumber ?? '');

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

  Future<void> markMessagesAsRead() async {
    if (_messages == null) {
      print("Error: _messages reference is not initialized.");
      return;
    }

    try {
      String currentUserPhone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
      bool isCouncillor = await isUserCouncillor(currentUserPhone);

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
        title: Text(
          'Chat with ${widget.councillorName}',
          style: const TextStyle(color: Colors.white),
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
                  onPressed: () {}, // Implement file upload logic
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
