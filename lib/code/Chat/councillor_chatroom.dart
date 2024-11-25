import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Models/notify_provider.dart';
import 'chat_screen.dart';
import 'chat_screen_councillors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

class CouncillorChatListScreen extends StatefulWidget {
  final String councillorPhone;
  final bool isLocalMunicipality;
  final String municipalityId;

  const CouncillorChatListScreen({
    super.key,
    required this.councillorPhone,
    required this.isLocalMunicipality,
    required this.municipalityId,
  });

  @override
  _CouncillorChatListScreenState createState() =>
      _CouncillorChatListScreenState();
}

class _CouncillorChatListScreenState extends State<CouncillorChatListScreen> {
  String councillorName = '';
  String districtId = '';
  String municipalityId = '';
  late Stream<QuerySnapshot> userChats;
  bool isLocalMunicipality = false;
  bool _isLoading = true;
  String? regularUserAccountNumber;
  List<Map<String, dynamic>> _filteredChatList = []; // To store chats
  bool hasUnreadUserMessages = false; // For notification badge

  @override
  void initState() {
    super.initState();
    municipalityId = widget.municipalityId;
    fetchUserDetails().then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      fetchAndStoreCouncillorChats();
    });
    fetchCouncillorName();
    initializeChatRoomsStream();
  }


  Future<void> fetchUserDetails() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null || user.phoneNumber == null) {
        print("Error: No authenticated user found.");
        return;
      }

      String phoneNumber = user.phoneNumber!;
      print("Fetching user details for phone: $phoneNumber");

      // Initialize the municipality and district IDs
      QuerySnapshot localProperties = await FirebaseFirestore.instance
          .collectionGroup('properties')
          .where('cellNumber', isEqualTo: phoneNumber)
          .where('isLocalMunicipality', isEqualTo: true)
          .limit(1)
          .get();

      if (localProperties.docs.isNotEmpty) {
        var propertyDoc = localProperties.docs.first;
        municipalityId = propertyDoc['municipalityId'];
        isLocalMunicipality = true;
        regularUserAccountNumber = propertyDoc['accountNumber'];
        print(
            "Local municipality property found. Municipality ID: $municipalityId, Account Number: $regularUserAccountNumber");
      } else {
        QuerySnapshot districtProperties = await FirebaseFirestore.instance
            .collectionGroup('properties')
            .where('cellNumber', isEqualTo: phoneNumber)
            .where('isLocalMunicipality', isEqualTo: false)
            .limit(1)
            .get();

        if (districtProperties.docs.isNotEmpty) {
          var propertyDoc = districtProperties.docs.first;
          municipalityId = propertyDoc['municipalityId'];
          districtId = propertyDoc['districtId'];
          isLocalMunicipality = false;
          regularUserAccountNumber = propertyDoc['accountNumber'];
          print(
              "District municipality property found. Municipality ID: $municipalityId, District ID: $districtId, Account Number: $regularUserAccountNumber");
        } else {
          print("Error: No property found for user with phone: $phoneNumber");
          return;
        }
      }

      // Validate required IDs
      if (municipalityId.isEmpty || (!isLocalMunicipality && districtId.isEmpty)) {
        print("Error: Municipality ID or District ID is empty.");
        return;
      }

      // Check if the user is a councillor
      bool isCouncillor = await checkIfUserIsCouncillor(phoneNumber);
      if (isCouncillor) {
        print("Logged-in user is a councillor");
        return; // Skip further checks
      }

      print("User details fetched successfully.");
      initializeChatRoomsStream(); // Initialize after fetching user details
    } catch (e) {
      print("Error fetching user details: $e");
    }
  }



  Future<bool> checkIfUserIsCouncillor(String phoneNumber) async {
    try {
      if (municipalityId.isEmpty) {
        print("Error: Municipality ID is not set.");
        return false;
      }

      DocumentSnapshot councillorDoc;

      if (isLocalMunicipality) {
        // Check in local municipalities
        councillorDoc = await FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(municipalityId)
            .collection('councillors')
            .doc(phoneNumber)
            .get();
      } else {
        if (districtId.isEmpty) {
          print("Error: District ID is not set for a district municipality.");
          return false;
        }
        // Check in district municipalities
        councillorDoc = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('councillors')
            .doc(phoneNumber)
            .get();
      }

      if (councillorDoc.exists) {
        print("Councillor details found for phone: $phoneNumber");
        return true;
      } else {
        print("No councillor details found for phone: $phoneNumber");
        return false;
      }
    } catch (e) {
      print("Error checking councillor status: $e");
      return false;
    }
  }

  void initializeChatRoomsStream() {
    if (municipalityId.isEmpty || widget.councillorPhone.isEmpty) {
      print("Error: Municipality ID or Councillor Phone is empty.");
      userChats = Stream.empty(); // Use an empty stream as a fallback
      return;
    }

    if (!isLocalMunicipality && districtId.isEmpty) {
      print("Error: District ID is empty for a district municipality.");
      userChats = Stream.empty(); // Use an empty stream as a fallback
      return;
    }

    try {
      userChats = widget.isLocalMunicipality
          ? FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(widget.municipalityId)
          .collection('chatRoomCouncillor')
          .doc(widget.councillorPhone)
          .collection('userChats')
          .snapshots()
          : FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(widget.municipalityId)
          .collection('chatRoomCouncillor')
          .doc(widget.councillorPhone)
          .collection('userChats')
          .snapshots();

      print("ChatRooms stream initialized successfully.");
      print(
          "ChatRooms stream initialized for councillor at: ${widget.isLocalMunicipality ? 'localMunicipalities/${widget.municipalityId}/chatRoomCouncillor/${widget.councillorPhone}' : 'districts/$districtId/municipalities/${widget.municipalityId}/chatRoomCouncillor/${widget.councillorPhone}'}");

    } catch (e) {
      print("Error initializing chatRooms stream: $e");
      userChats = Stream.empty(); // Use an empty stream as a fallback
    }
  }

  void fetchCouncillorName() async {
    if (municipalityId.isEmpty) {
      print("Error: Municipality ID is empty, cannot fetch councillor name.");
      return;
    }

    try {
      DocumentSnapshot doc;
      if (isLocalMunicipality) {
        doc = await FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(municipalityId)
            .collection('councillors')
            .doc(widget.councillorPhone)
            .get();
      } else if (districtId.isNotEmpty) {
        doc = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('councillors')
            .doc(widget.councillorPhone)
            .get();
      } else {
        print("Error: District ID is empty for a district municipality.");
        return;
      }

      if (doc.exists) {
        final councillorData = doc.data() as Map<String, dynamic>?;
        if (mounted) {
          setState(() {
            councillorName = councillorData?['name'] ?? "No Name Found";
          });
        }
      } else {
        print("Councillor not found for phone: ${widget.councillorPhone}");
      }
    } catch (e) {
      print("Error fetching councillor name: $e");
    }
  }


  Future<Map<String, String>> getUserDetails(String userPhone) async {
    try {
      // Step 1: Check if the user exists in the councillors collection (exclude councillors)
      QuerySnapshot councillorCheck = widget.isLocalMunicipality
          ? await FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('councillors')
          .where('councillorPhone', isEqualTo: userPhone) // Check by councillor phone
          .limit(1)
          .get()
          : await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('councillors')
          .where('councillorPhone', isEqualTo: userPhone) // Check by councillor phone
          .limit(1)
          .get();

      if (councillorCheck.docs.isNotEmpty) {
        // If user exists in the councillors collection, return a default value
        print("User is a councillor, skipping details fetch: $userPhone");
        return {"fullName": "Councillor", "address": "N/A", "phone": userPhone};
      }

      // Step 2: Fetch the regular user's details from the properties collection
      QuerySnapshot snapshot = widget.isLocalMunicipality
          ? await FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('properties')
          .where('cellNumber', isEqualTo: userPhone) // Query by user's phone number
          .limit(1)
          .get()
          : await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('properties')
          .where('cellNumber', isEqualTo: userPhone) // Query by user's phone number
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs.first;
        // Return the regular user's details
        print("User details found for phone: $userPhone");
        return {
          "fullName": "${doc['firstName']} ${doc['lastName']}",
          "address": doc['address'],
          "phone": userPhone,
        };
      } else {
        print("No user details found for phone: $userPhone");
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }

    // Return default values if user details cannot be fetched
    return {"fullName": userPhone, "address": "No address found", "phone": userPhone};
  }

  Future<void> markMessagesAsReadForCouncillor(String chatRoomId) async {
    try {
      CollectionReference messagesRef = widget.isLocalMunicipality
          ? FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(widget.municipalityId)
          .collection('chatRoomCouncillor')
          .doc(widget.councillorPhone)
          .collection('userChats')
          .doc(chatRoomId)
          .collection('messages')
          : FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(widget.municipalityId)
          .collection('chatRoomCouncillor')
          .doc(widget.councillorPhone)
          .collection('userChats')
          .doc(chatRoomId)
          .collection('messages');

      QuerySnapshot unreadMessages = await messagesRef
          .where('isReadByCouncillor', isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({'isReadByCouncillor': true});
      }

      print("Marked all messages as read for councillor in chatRoomId: $chatRoomId");


    } catch (e) {
      print("Error marking messages as read: $e");
    }
  }



  Future<void> fetchAndStoreCouncillorChats() async {
    try {
      print("Fetching all chats for councillor: ${widget.councillorPhone}");

      CollectionReference chatRoomRef = widget.isLocalMunicipality
          ? FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(widget.municipalityId)
          .collection('chatRoomCouncillor')
          .doc(widget.councillorPhone)
          .collection('userChats')
          : FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(widget.municipalityId)
          .collection('chatRoomCouncillor')
          .doc(widget.councillorPhone)
          .collection('userChats');

      QuerySnapshot chatSnapshot = await chatRoomRef.get();

      List<Map<String, dynamic>> allCouncillorChats = [];
      bool anyUnreadMessages = false;

      for (var chatDoc in chatSnapshot.docs) {
        String userPhoneNumber = chatDoc.id;

        CollectionReference messagesRef = chatDoc.reference.collection('messages');

        QuerySnapshot unreadMessagesSnapshot = await messagesRef
            .where('isReadByCouncillor', isEqualTo: false)
            .get();

        QuerySnapshot latestMessageSnapshot = await messagesRef
            .orderBy('time', descending: true)
            .limit(1)
            .get();

        bool hasUnreadCouncilMessages = unreadMessagesSnapshot.docs.isNotEmpty;
        anyUnreadMessages = anyUnreadMessages || hasUnreadCouncilMessages;

        Map<String, String> userDetails = await getUserDetails(userPhoneNumber);

        allCouncillorChats.add({
          'chatRoomId': userPhoneNumber,
          'userPhoneNumber': userPhoneNumber,
          'fullName': userDetails['fullName'] ?? 'Unknown',
          'address': userDetails['address'] ?? 'Unknown',
          'hasUnreadCouncilMessages': hasUnreadCouncilMessages,
          'latestMessage': latestMessageSnapshot.docs.isNotEmpty
              ? latestMessageSnapshot.docs.first['message']
              : "No messages yet.",
          'latestMessageTime': latestMessageSnapshot.docs.isNotEmpty
              ? latestMessageSnapshot.docs.first['time']
              : 0,
        });
      }

      allCouncillorChats.sort((a, b) =>
          (b['latestMessageTime'] as int).compareTo(a['latestMessageTime'] as int));

      if (mounted) {
        setState(() {
          _filteredChatList = allCouncillorChats;
        });
      }
    } catch (e) {
      print("Error fetching councillor chats: $e");
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              "Chats",
              style: TextStyle(color: Colors.white),
            ),

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
                    "!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                     const SizedBox.shrink(),


          ],
        ),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _filteredChatList.length,
        itemBuilder: (context, index) {
          final chatData = _filteredChatList[index];
          final String usersName = chatData['fullName'] ?? 'Unknown';
          final String usersProperty = chatData['address'] ?? 'No address found';
          final String number = chatData['userPhoneNumber'] ?? 'Unknown';
          final bool hasUnreadCouncilMessages =
              chatData['hasUnreadCouncilMessages'] ?? false;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            elevation: 2.0,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Chat Room",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Chat from: $usersName',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Property: $usersProperty',
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Number: $number',
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            await markMessagesAsReadForCouncillor(chatData['chatRoomId']);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatCouncillor(
                                  chatRoomId: widget.councillorPhone,
                                  councillorName: councillorName,
                                  userId: chatData['userPhoneNumber'],
                                  isLocalMunicipality: widget.isLocalMunicipality,
                                  districtId: districtId,
                                  municipalityId: widget.municipalityId,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat),
                          label: const Text(
                            "Chat",
                            style: TextStyle(color: Colors.black),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            side: const BorderSide(
                              color: Colors.grey,
                              width: 1.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                        ),
                        if (hasUnreadCouncilMessages)
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
                              "!",
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
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


}
