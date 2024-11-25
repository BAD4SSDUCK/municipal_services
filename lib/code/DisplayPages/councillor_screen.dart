import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:municipal_services/code/Chat/chat_screen_councillors.dart';
import 'package:municipal_services/code/NoticePages/notice_user_arc_screen.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';
import 'package:municipal_services/code/Reusable/cache_manager.dart';
import 'package:municipal_services/code/faultPages/fault_task_screen_archive.dart';
import 'package:municipal_services/code/MapTools/map_screen.dart';
import 'package:municipal_services/code/MapTools/map_screen_prop.dart';
import '../Chat/councillor_chatroom.dart';
import '../Models/notify_provider.dart';


class CouncillorScreen extends StatefulWidget {
  const CouncillorScreen({super.key,});

  @override
  State<CouncillorScreen> createState() => _CouncillorScreenState();
}

class _CouncillorScreenState extends State<CouncillorScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  late final CollectionReference councillors;

  List<DocumentSnapshot> councillorList = [];
  bool isLoading = true;
  String dropdownValue = 'Select Ward';
  List<String> dropdownWards = List.generate(
      41,
          (index) =>
      (index == 0) ? 'Select Ward' : index.toString().padLeft(2, '0'));
  List<DocumentSnapshot> filteredCouncillorList = [];
  final TextEditingController _searchController = TextEditingController();
  String? userEmail;
  String districtId='';
  String municipalityId='';
  bool isLocalMunicipality = false;
  StreamSubscription? councillorUnreadSubscription;


  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    fetchUserDetails();

    // Fetch user details and initialize councillors collection afterward
  }


  Future<void> fetchUserDetails() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String cellNumber = user.phoneNumber ?? '';

        // First, try fetching from local municipalities
        QuerySnapshot localPropertiesSnapshot = await FirebaseFirestore.instance
            .collectionGroup('properties')
            .where('cellNumber', isEqualTo: cellNumber)
            .where('isLocalMunicipality', isEqualTo: true)
            .limit(1)
            .get();

        if (localPropertiesSnapshot.docs.isNotEmpty) {
          // Local municipality property found
          var propertyDoc = localPropertiesSnapshot.docs.first;

          // Extract municipalityId
          List<String> pathSegments = propertyDoc.reference.path.split('/');
          municipalityId = pathSegments[1];
          isLocalMunicipality = true;

          print("Local municipality detected");
        } else {
          // If no local municipality property is found, fetch from district municipalities
          QuerySnapshot districtPropertiesSnapshot = await FirebaseFirestore.instance
              .collectionGroup('properties')
              .where('cellNumber', isEqualTo: cellNumber)
              .where('isLocalMunicipality', isEqualTo: false)
              .limit(1)
              .get();

          if (districtPropertiesSnapshot.docs.isNotEmpty) {
            var propertyDoc = districtPropertiesSnapshot.docs.first;

            // Extract districtId and municipalityId
            List<String> pathSegments = propertyDoc.reference.path.split('/');
            districtId = pathSegments[1];
            municipalityId = pathSegments[3];
            isLocalMunicipality = false;

            print("District municipality detected");
          } else {
            print("No property found for the provided cell number.");
          }
        }

        print("districtId: $districtId");
        print("municipalityId: $municipalityId");
        print("isLocalMunicipality: $isLocalMunicipality");

        // Initialize the councillors reference with the correct path
        councillors = isLocalMunicipality
            ? FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(municipalityId)
            .collection('councillors')
            : FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('councillors');

        // Fetch councillor data
        fetchCouncillorData();
      } else {
        print("No current user found.");
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

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
          .where('sendTo', isEqualTo: userPhone)
          .snapshots()
          .asyncMap((snapshot) async {
        for (var chatDoc in snapshot.docs) {
          QuerySnapshot unreadMessages = await chatDoc.reference
              .collection('messages')
              .where('isReadByUser', isEqualTo: false)
              .get();

          if (unreadMessages.docs.isNotEmpty) {
            return true; // Unread messages for the regular user
          }
        }
        return false; // No unread messages
      });
    }
  }

  void _onSearchChanged() {
    filterCouncillors(dropdownValue);
  }

  void filterCouncillors(String? ward) {
    List<DocumentSnapshot> tempResults = [];
    String searchText = _searchController.text.toLowerCase();
    if (ward == 'Select Ward' && searchText.isEmpty) {
      tempResults = List.from(councillorList);
    } else {
      for (var doc in councillorList) {
        final wardNum = doc['wardNum'].toString();
        final name = doc['councillorName'].toString().toLowerCase();
        final phone = doc['councillorPhone'].toString().toLowerCase();
        if ((ward == 'Select Ward' || wardNum == ward) &&
            (name.contains(searchText) || phone.contains(searchText))) {
          tempResults.add(doc);
        }
      }
    }
    if (mounted) {
      setState(() {
        filteredCouncillorList = tempResults;
      });
    }
  }


  void fetchCouncillorData() async {
    try {
      var snapshot = await councillors.orderBy('wardNum').get();
      print("Fetched ${snapshot.docs.length} councillors");
      if (mounted) {
        setState(() {
          councillorList = snapshot.docs;
          filteredCouncillorList = snapshot.docs;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching councillor data: $e");
    }
  }



  Future<String> getImageUrl(String imagePath) async {
    final ref = FirebaseStorage.instance.ref().child(imagePath);
    try {
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print("Failed to load image $imagePath, $e");
      return '';
    }
  }

  Stream<bool> councillorUnreadMessagesStream(String councillorPhone) async* {
    try {
      CollectionReference userChats = isLocalMunicipality
          ? FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('chatRoomCouncillor')
          .doc(councillorPhone)
          .collection('userChats')
          : FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('chatRoomCouncillor')
          .doc(councillorPhone)
          .collection('userChats');

      yield* userChats.snapshots().asyncMap((snapshot) async {
        for (var chatDoc in snapshot.docs) {
          QuerySnapshot unreadMessages = await chatDoc.reference
              .collection('messages')
              .where('isReadByCouncillor', isEqualTo: false)
              .get();

          if (unreadMessages.docs.isNotEmpty) {
            return true; // Unread messages found
          }
        }
        return false; // No unread messages
      });
    } catch (e) {
      print("Error in councillorUnreadMessagesStream: $e");
      yield false;
    }
  }


  Future<void> markMessagesAsReadForUser(String councillorPhone) async {
    try {
      CollectionReference userChats = isLocalMunicipality
          ? FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('chatRoomCouncillor')
          .doc(councillorPhone)
          .collection('userChats')
          : FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('chatRoomCouncillor')
          .doc(councillorPhone)
          .collection('userChats');

      String userPhone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';

      QuerySnapshot unreadMessages = await userChats
          .doc(userPhone)
          .collection('messages')
          .where('isReadByUser', isEqualTo: false)
          .get();

      for (var message in unreadMessages.docs) {
        await message.reference.update({'isReadByUser': true});
      }

      print("Marked all messages as read for user $userPhone with councillor $councillorPhone");

      // Update the provider
      NotificationProvider().updateCouncillorUnreadMessages(councillorPhone, false);
    } catch (e) {
      print("Error marking messages as read: $e");
    }
  }




  Future<bool> hasUnreadCouncilMessages(String councillorPhone) async {
    try {
      CollectionReference userChats = isLocalMunicipality
          ? FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('chatRoomCouncillor')
          .doc(councillorPhone)
          .collection('userChats')
          : FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('chatRoomCouncillor')
          .doc(councillorPhone)
          .collection('userChats');

      String userPhone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
      QuerySnapshot unreadMessages = await userChats
          .doc(userPhone)
          .collection('messages')
          .where('isReadByUser', isEqualTo: false)
          .get();

      return unreadMessages.docs.isNotEmpty;
    } catch (e) {
      print("Error checking unread messages: $e");
      return false;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Councillor Screen', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : buildBody(),
    );
  }

  Widget buildBody() {
    return Column(
      children: [
        buildSearchAndFilter(),
        Expanded(child: buildCouncillorList()),
      ],
    );
  }

  Widget buildSearchAndFilter() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: DropdownButton<String>(
            value: dropdownValue,
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  dropdownValue = newValue;
                  filterCouncillors(newValue);
                });
              }
            },
            items: dropdownWards.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search',
            suffixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          ),
          onChanged: (String value) {
            _onSearchChanged();
          },
        ),
      ],
    );
  }

  Widget buildCouncillorList() {
    final String userPhone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    return ListView.builder(
      itemCount: filteredCouncillorList.length,
      itemBuilder: (context, index) {
        DocumentSnapshot doc = filteredCouncillorList[index];
        if (doc.exists) {
          return StreamBuilder<bool>(
            stream: councillorUnreadMessagesStream(doc['councillorPhone']),
            builder: (context, snapshot) {
              bool hasUnreadMessages = snapshot.data ?? false;
              return buildCouncillorCard(doc, userPhone, hasUnreadMessages);
            },
          );
        } else {
          return const Text("Document does not exist");
        }
      },
    );
  }


  Widget buildCouncillorCard(
      DocumentSnapshot doc, String userPhone, bool hasUnreadMessages) {
    final String councillorPhone = doc['councillorPhone'];
    final String councillorName = doc['councillorName'];
    final String imagePath = 'files/councillors/$councillorName.jpg';

    bool isUserCouncillor = userPhone == councillorPhone;

    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FutureBuilder(
              future: getImageUrl(imagePath),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  return CircleAvatar(
                    backgroundImage: NetworkImage(snapshot.data!),
                    radius: 60,
                  );
                } else {
                  return const CircleAvatar(
                    radius: 60,
                    child: Icon(Icons.person),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            Text(
              councillorName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Ward: ${doc['wardNum']}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Contact Number: $councillorPhone',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.message, color: Colors.blue),
                  onPressed: () {
                    if (isUserCouncillor) {
                      navigateToCouncillorChatListScreen(councillorPhone);
                    } else {
                      navigateToCouncillorChat(councillorPhone, userPhone, councillorName);
                    }
                  },
                ),
                if (hasUnreadMessages)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
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
          ],
        ),
      ),
    );
  }


  void navigateToCouncillorChatListScreen(String councillorPhone) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CouncillorChatListScreen(
          councillorPhone: councillorPhone,
          isLocalMunicipality: isLocalMunicipality,
          municipalityId: municipalityId,  // Pass municipalityId
        ),
      ),
    );
    fetchCouncillorData();
  }


  void navigateToCouncillorChat(String councillorPhone, String userPhone, String councillorName) {
    // Mark messages as read before navigating to the chat screen
    markMessagesAsReadForUser(councillorPhone);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatCouncillor(
          chatRoomId: councillorPhone,
          councillorName: councillorName,
          userId: userPhone,
          isLocalMunicipality: isLocalMunicipality,
          districtId: districtId,
          municipalityId: municipalityId,
        ),
      ),
    ).then((_) {
      // Refresh councillor data after returning from the chat
      fetchCouncillorData();
    });
  }





  @override
  void dispose() {
    super.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    councillorUnreadSubscription?.cancel();
  }
}
