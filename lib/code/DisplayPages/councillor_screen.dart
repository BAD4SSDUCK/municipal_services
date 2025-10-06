import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:municipal_services/code/Chat/chat_screen_councillors.dart';
import '../Chat/councillor_chatroom.dart';
import '../widgets/avatar_image.dart';


class CouncillorScreen extends StatefulWidget {
  const CouncillorScreen({
    super.key,
  });

  @override
  State<CouncillorScreen> createState() => _CouncillorScreenState();
}

class _CouncillorScreenState extends State<CouncillorScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  late final CollectionReference councillors;
  List<DocumentSnapshot> filteredCouncillorList = [];
  Map<String, bool> unreadMessagesMap = {};
  List<DocumentSnapshot> councillorList = [];
  bool isLoading = true;
  String dropdownValue = 'Select Ward';
  List<String> dropdownWards = List.generate(
      41,
      (index) =>
          (index == 0) ? 'Select Ward' : index.toString().padLeft(2, '0'));
  final TextEditingController _searchController = TextEditingController();
  String? userEmail;
  String districtId = '';
  String municipalityId = '';
  bool isLocalMunicipality = false;
  bool hasUnreadCouncillorMessages = false;
  StreamSubscription<QuerySnapshot>? unreadCouncillorMessagesSubscription;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    fetchUserDetails();
    setupRealTimeBadgeListener();
  }

  @override
  void dispose() {
    unreadCouncillorMessagesSubscription?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> setupRealTimeBadgeListener() async {
    String? userPhone = FirebaseAuth.instance.currentUser?.phoneNumber;

    if (userPhone == null) {
      print("Error: Current user's phone number is null.");
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
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
        unreadCouncillorMessagesSubscription = councillorChatsCollection.snapshots().listen((snapshot) async {
          print("Councillor chats snapshot received: ${snapshot.docs.length} councillors.");
          Map<String, bool> updatedUnreadMessagesMap = {};
          bool hasUnread = false;

          for (var doc in snapshot.docs) {
            QuerySnapshot userChatsSnapshot = await doc.reference.collection('userChats').get();

            for (var userChatDoc in userChatsSnapshot.docs) {
              QuerySnapshot unreadMessages = await userChatDoc.reference
                  .collection('messages')
                  .where('isReadByCouncillor', isEqualTo: false)
                  .get();

              if (unreadMessages.docs.isNotEmpty) {
                updatedUnreadMessagesMap[doc.id] = true;
                hasUnread = true;
              }
            }
          }

          if (mounted) {
            setState(() {
              unreadMessagesMap = updatedUnreadMessagesMap;
              hasUnreadCouncillorMessages = hasUnread; // Update UI dynamically
            });
            print("Real-time badge updated: $hasUnreadCouncillorMessages");
            print("Unread messages map: $unreadMessagesMap");
          }
        });
      }
    }).catchError((error) {
      print("Error setting up real-time badge listener: $error");
    });
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
          QuerySnapshot districtPropertiesSnapshot = await FirebaseFirestore
              .instance
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

  Future<void> fetchCouncillorData() async {
    try {
      var snapshot = await councillors.orderBy('wardNum').get();
      print("Fetched ${snapshot.docs.length} councillors");

      Map<String, bool> updatedUnreadMessagesMap = {};
      bool anyUnreadMessages = false; // Track overall unread messages

      for (var doc in snapshot.docs) {
        String councillorPhone = doc['councillorPhone'];
        bool hasUnread = await checkForUnreadMessagesForCouncillor(councillorPhone);

        updatedUnreadMessagesMap[councillorPhone] = hasUnread;
        anyUnreadMessages = anyUnreadMessages || hasUnread;

        print("Councillor $councillorPhone has unread messages: $hasUnread");
      }

      if (mounted) {
        setState(() {
          councillorList = snapshot.docs;
          filteredCouncillorList = snapshot.docs;
          unreadMessagesMap = updatedUnreadMessagesMap;
          hasUnreadCouncillorMessages = anyUnreadMessages; // Update badge state
          isLoading = false; // Ensure this is called after data is fetched
        });
        print("Updated unreadMessagesMap: $unreadMessagesMap");
      }
    } catch (e) {
      print("Error fetching councillor data: $e");
    }
  }


  Future<bool> checkForUnreadMessagesForCouncillor(
      String councillorPhone) async {
    try {
      print("Checking unread messages for councillor: $councillorPhone");

      // Fetch all userChats for this councillor
      QuerySnapshot userChatsSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('chatRoomCouncillor')
          .doc(councillorPhone)
          .collection('userChats')
          .get();

      // Iterate through each userChat and check for unread messages
      for (var userChatDoc in userChatsSnapshot.docs) {
        QuerySnapshot unreadMessages = await userChatDoc.reference
            .collection('messages')
            .where('isReadByCouncillor', isEqualTo: false)
            .get();

        print(
            "Unread messages for userChat ${userChatDoc.id}: ${unreadMessages.docs.length}");

        if (unreadMessages.docs.isNotEmpty) {
          return true; // Return true if any unread messages are found
        }
      }

      return false; // Return false if no unread messages are found
    } catch (e) {
      print(
          "Error checking unread messages for councillor $councillorPhone: $e");
      return false;
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

  Future<void> checkForUnreadCouncillorMessages() async {
    if (!mounted) return;

    try {
      String? userPhone = FirebaseAuth.instance.currentUser?.phoneNumber;

      if (userPhone == null) {
        print("Error: Current user's phone number is null.");
        return;
      }

      print("Current user phone number: $userPhone");

      // Determine if the user is a councillor
      bool isCouncillor = await checkIfCouncillor();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? selectedPropertyAccountNumber = prefs.getString('selectedPropertyAccountNo');

      if (selectedPropertyAccountNumber == null) {
        print('Error: selectedPropertyAccountNumber is null.');
        return;
      }

      QuerySnapshot propertySnapshot = await FirebaseFirestore.instance
          .collectionGroup('properties')
          .where('accountNumber', isEqualTo: selectedPropertyAccountNumber)
          .get();

      if (propertySnapshot.docs.isNotEmpty) {
        DocumentSnapshot propertyDoc = propertySnapshot.docs.first;
        bool isLocalMunicipality = propertyDoc.get('isLocalMunicipality');
        String municipalityId = propertyDoc.get('municipalityId');
        String? districtId = propertyDoc.data().toString().contains('districtId')
            ? propertyDoc.get('districtId')
            : null;

        CollectionReference councillorChatsCollection;

        if (isCouncillor) {
          councillorChatsCollection = isLocalMunicipality
              ? FirebaseFirestore.instance
              .collection('localMunicipalities')
              .doc(municipalityId)
              .collection('chatRoomCouncillor')
              .doc(userPhone)
              .collection('userChats')
              : FirebaseFirestore.instance
              .collection('districts')
              .doc(districtId!)
              .collection('municipalities')
              .doc(municipalityId)
              .collection('chatRoomCouncillor')
              .doc(userPhone)
              .collection('userChats');
        } else {
          councillorChatsCollection = isLocalMunicipality
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
        }

        print("Councillor chats collection path: ${councillorChatsCollection.path}");

        unreadCouncillorMessagesSubscription?.cancel();

        unreadCouncillorMessagesSubscription = councillorChatsCollection
            .snapshots()
            .listen((snapshot) async {
          print("Councillor chats snapshot received. Docs count: ${snapshot.docs.length}");
          Map<String, bool> updatedUnreadMessagesMap = {};
          bool hasUnread = false;

          for (var doc in snapshot.docs) {
            if (isCouncillor) {
              QuerySnapshot unreadMessages = await doc.reference
                  .collection('messages')
                  .where('isReadByCouncillor', isEqualTo: false)
                  .get();

              print("Unread messages count for userChat ${doc.id}: ${unreadMessages.docs.length}");

              if (unreadMessages.docs.isNotEmpty) {
                updatedUnreadMessagesMap[userPhone] = true; // Mark councillor as having unread messages
                hasUnread = true;
              }
            } else {
              CollectionReference userChatsCollection = doc.reference.collection('userChats');
              QuerySnapshot userChats = await userChatsCollection.get();

              for (var userChatDoc in userChats.docs) {
                QuerySnapshot unreadMessages = await userChatDoc.reference
                    .collection('messages')
                    .where('isReadByUser', isEqualTo: false)
                    .get();

                print("Unread messages count for userChat ${userChatDoc.id}: ${unreadMessages.docs.length}");

                if (unreadMessages.docs.isNotEmpty) {
                  updatedUnreadMessagesMap[doc.id] = true; // Mark user chat as having unread messages
                  hasUnread = true;
                }
              }
            }
          }

          if (mounted) {
            setState(() {
              unreadMessagesMap = updatedUnreadMessagesMap;
              hasUnreadCouncillorMessages = hasUnread;
            });
            print("Final unreadMessagesMap: $unreadMessagesMap");
            print("Updated hasUnreadCouncillorMessages to: $hasUnreadCouncillorMessages");
          }
        });
      }
    } catch (e) {
      print('Error checking for unread councillor messages: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Councillor Screen',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : buildBody(),
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
                if (mounted) {
                  setState(() {
                    dropdownValue = newValue;
                    filterCouncillors(newValue);
                  });
                }
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
    return ListView.builder(
      itemCount: filteredCouncillorList.length,
      itemBuilder: (context, index) {
        DocumentSnapshot doc = filteredCouncillorList[index];
        if (doc.exists) {
          return buildCouncillorCard(doc);
        } else {
          return const Text("Document does not exist");
        }
      },
    );
  }

  Widget buildCouncillorCard(DocumentSnapshot doc) {
    final String councillorPhone = doc['councillorPhone'];
    final String councillorName = doc['councillorName'];
    final String imagePath = 'files/councillors/$councillorName.jpg';
    bool isUserCouncillor = user!.phoneNumber == councillorPhone;
    // Determine if this specific councillor has unread messages
    bool hasUnreadMessagesForCouncillor =
        unreadMessagesMap[councillorPhone] ?? false;

    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FutureBuilder(
              future: getImageUrl('files/councillors/$councillorName.jpg'),
              builder: (context, snapshot) {
                final url = (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data!.isNotEmpty)
                    ? snapshot.data!
                    : '';

                if (url.isEmpty) {
                  // fallback avatar
                  return const CircleAvatar(radius: 60, child: Icon(Icons.person));
                }

                // Cross-platform avatar (web uses native <img> with circular clip)
                return avatarImage(url: url, diameter: 120);
              },
            ),
            const SizedBox(height: 10),
            Text(
              councillorName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('Ward: ${doc['wardNum']}',
                style: const TextStyle(fontSize: 16)),
            Text('Contact Number: $councillorPhone',
                style: const TextStyle(fontSize: 16)),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.message, color: Colors.blue),
                  onPressed: () => isUserCouncillor
                      ? navigateToCouncillorChatListScreen(councillorPhone)
                      : navigateToCouncillorChat(
                          councillorPhone, councillorName),
                ),
                if (hasUnreadMessagesForCouncillor)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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
          municipalityId: municipalityId, // Pass municipalityId
        ),
      ),
    );
    fetchCouncillorData();
    setupRealTimeBadgeListener();
  }

  void navigateToCouncillorChat(String councillorPhone, String councillorName) {
    String? regularUserPhoneNumber =
        FirebaseAuth.instance.currentUser?.phoneNumber;

    if (regularUserPhoneNumber == null || regularUserPhoneNumber.isEmpty) {
      print("Error: Regular user phone number is null or empty.");
      return; // Prevent navigation if the phone number is unavailable
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatCouncillor(
          chatRoomId: councillorPhone,
          councillorName: councillorName,
          isLocalMunicipality: isLocalMunicipality,
          districtId: districtId,
          municipalityId: municipalityId,
          userId: regularUserPhoneNumber,
        ),
      ),
    ).then((_) {
      print("Returned from ChatCouncillor for councillor: $councillorPhone");
      // Refresh councillor data after returning from the chat
      fetchCouncillorData();
      setupRealTimeBadgeListener();
    });
  }
}