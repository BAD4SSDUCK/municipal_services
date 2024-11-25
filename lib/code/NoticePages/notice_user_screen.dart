import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:municipal_services/code/Chat/chat_screen_finance.dart';
import 'package:municipal_services/code/NoticePages/notice_user_arc_screen.dart';
import 'package:municipal_services/code/faultPages/fault_task_screen_archive.dart';
import 'package:municipal_services/code/MapTools/map_screen.dart';
import 'package:municipal_services/code/MapTools/map_screen_prop.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';
import 'package:provider/provider.dart';
import '../Models/notify_provider.dart';
import '../Models/prop_provider.dart';

class NoticeScreen extends StatefulWidget {
  final String? selectedPropertyAccountNumber;
  final bool isLocalMunicipality;
  final String municipalityId;
  final String? districtId;
  const NoticeScreen({Key? key, this.selectedPropertyAccountNumber,
    required this.isLocalMunicipality,
    required this.municipalityId,
    this.districtId,}) : super(key: key);

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}
final FirebaseAuth auth = FirebaseAuth.instance;
DateTime now = DateTime.now();
final User? user = auth.currentUser;
final uid = user?.uid;
final email = user?.email;
String userID = uid as String;
String userEmail = email as String;

class _NoticeScreenState extends State<NoticeScreen> {
  String? userEmail;
  String districtId = '';
  String municipalityId = '';
  CollectionReference? _listNotifications;
  bool isLoading = false;
  bool _isDisposed = false;
  List _allNoticesResults = [];

  @override
  void initState() {
    super.initState();
    print("Selected property account number: ${widget
        .selectedPropertyAccountNumber}");
    fetchNotifications();
  }


  @override
  void dispose() {
    _headerController;
    _messageController;
    searchText;
    _isDisposed = true;
    //getNoticeStream();
    super.dispose();
  }

  // Future<void> fetchUserDetails() async {
  //   try {
  //     User? user = FirebaseAuth.instance.currentUser;
  //     if (user != null) {
  //       String userPhoneNumber = user.phoneNumber!;
  //
  //       // Fetch the property data based on the account number
  //       QuerySnapshot propertySnapshot = await FirebaseFirestore.instance
  //           .collectionGroup('properties')
  //           .where('accountNumber', isEqualTo: widget.selectedPropertyAccountNumber)
  //           .limit(1)
  //           .get();
  //
  //       if (propertySnapshot.docs.isNotEmpty) {
  //         var propertyDoc = propertySnapshot.docs.first;
  //
  //         // Check if the property belongs to a local municipality or district
  //         bool isLocalMunicipality = propertyDoc.get('isLocalMunicipality');
  //         municipalityId = propertyDoc.get('municipalityId');
  //         districtId = isLocalMunicipality ? '' : propertyDoc.get('districtId') ?? '';
  //
  //         print('District ID: $districtId');
  //         print('Municipality ID: $municipalityId');
  //
  //         // Initialize _listNotifications based on the municipality type
  //         if (isLocalMunicipality) {
  //           _listNotifications = FirebaseFirestore.instance
  //               .collection('localMunicipalities')
  //               .doc(municipalityId)
  //               .collection('Notifications');
  //         } else {
  //           _listNotifications = FirebaseFirestore.instance
  //               .collection('districts')
  //               .doc(districtId)
  //               .collection('municipalities')
  //               .doc(municipalityId)
  //               .collection('Notifications');
  //         }
  //
  //         print('Notifications collection initialized: $_listNotifications');
  //
  //         // Fetch notifications after determining the municipality type
  //         await getNoticeStream();
  //       } else {
  //         print('No matching property found for the account number.');
  //       }
  //     }
  //   } catch (e) {
  //     print('Error fetching user details: $e');
  //   }
  // }
  //
  // Future<void> getNoticeStream() async {
  //   if (_listNotifications != null && widget.selectedPropertyAccountNumber != null) {
  //     try {
  //       print('Fetching notifications for account number (user field): ${widget.selectedPropertyAccountNumber}');
  //
  //       // Use the 'user' field in the query
  //       var data = await _listNotifications!
  //           .where('user', isEqualTo: widget.selectedPropertyAccountNumber)
  //           .orderBy('date', descending: true)
  //           .get();
  //
  //       print('Number of notifications fetched: ${data.docs.length}');
  //
  //       if (mounted) {
  //         setState(() {
  //           _allNoticesResults = data.docs;
  //         });
  //       }
  //     } catch (e) {
  //       print('Error fetching notifications: $e');
  //     }
  //   } else {
  //     print('No notifications collection initialized or selectedPropertyAccountNumber is null');
  //   }
  // }
  Future<void> fetchNotifications() async {
    if(mounted) {
      setState(() {
        isLoading = true; // Show loading indicator while fetching notifications
      });
    }
    try {
      // Determine whether to fetch notifications from local or district collection
      if (widget.isLocalMunicipality) {
        _listNotifications = FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(widget.municipalityId)
            .collection('Notifications');
      } else if (widget.districtId != null) {
        _listNotifications = FirebaseFirestore.instance
            .collection('districts')
            .doc(widget.districtId)
            .collection('municipalities')
            .doc(widget.municipalityId)
            .collection('Notifications');
      }

      if (_listNotifications != null) {
        // Fetch notifications associated with the selected property account number
        QuerySnapshot snapshot = await _listNotifications!
            .where('user', isEqualTo: widget.selectedPropertyAccountNumber)
            .orderBy('date', descending: true)
            .get();

        print('Number of notifications fetched: ${snapshot.docs.length}');
          if(mounted) {
            setState(() {
              _allNoticesResults = snapshot.docs;
            });
          }
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        notificationProvider.updateUnreadNoticesStatus(snapshot.docs.isNotEmpty);
      } else {
        print('Error: Notification collection is not initialized.');
      }
      checkForUnreadNotices();
    } catch (e) {
      print('Error fetching notifications: $e');
    } finally {
      if(mounted) {
        setState(() {
          isLoading = false; // Stop showing the loading indicator
        });
      }
    }
  }

  final user = FirebaseAuth.instance.currentUser!;

  //
  // final CollectionReference _listNotifications =
  // FirebaseFirestore.instance.collection('Notifications');

  final _headerController = TextEditingController();
  final _messageController = TextEditingController();

  ///Methods and implementation for push notifications with firebase and specific device token saving
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  TextEditingController username = TextEditingController();
  TextEditingController title = TextEditingController();
  TextEditingController body = TextEditingController();
  String? mtoken = " ";

  ///This was made for testing a default message
  String title2 = "Outstanding Utilities Payment";
  String body2 = "Make sure you pay utilities before the end of this month or your services will be disconnected";

  String token = '';
  String notifyToken = '';
  String searchText = '';

  bool visShow = true;
  bool visHide = false;
  bool adminAcc = false;


  void checkForUnreadNotices() async {
    bool hasUnreadNotices = _allNoticesResults.any((notice) => notice['read'] == false);

    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    notificationProvider.updateUnreadNoticesStatus(hasUnreadNotices);
  }


  //it is called within a listview page widget
  Widget noticeItemField(String noticeData) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8,),
      child: Row(
        children: [
          Expanded(
            child: Text(
              noticeData,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //it is called within a listview page widget
  Widget noticeItemWarningField(String noticeData) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.amber[100],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8,),
      child: Row(
        children: [
          Expanded(
            child: Text(
              noticeData,
              style: const TextStyle(
                  color: Color.fromARGB(255, 200, 0, 0),
                  fontSize: 16,
                  fontWeight: FontWeight.w600
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget userNotificationCard() {
    if (_allNoticesResults.isNotEmpty) {
      return ListView.builder(
        itemCount: _allNoticesResults.length,
        itemBuilder: (context, index) {
          var notification = _allNoticesResults[index];
          var selectedAccountNumber = widget.selectedPropertyAccountNumber ?? '';
          var notificationUser = notification['user']?.toString() ?? '';
          var isRead = notification['read'] ?? true;
          var level = notification['level'] ?? 'general';

          // Only show general notifications here
          if (notificationUser == selectedAccountNumber && level == 'general') {
            return Card(
              margin: const EdgeInsets.all(10.0),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Notification',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Notice Header:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      notification['title'] ?? 'No Title',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Text(
                      'Notice Details:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      notification['body'] ?? 'No Body',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Text(
                      'Notice Received Date:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      notification['date'] ?? 'No Date',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            BasicIconButtonGrey(
                              onPress: () async {
                                notifyToken = notification['token'];
                                _notifyUpdate(notification);
                              },
                              labelText: 'Mark as Read',
                              fSize: 14,
                              faIcon: const FaIcon(Icons.check_circle),
                              fgColor: Colors.green,
                              btSize: const Size(50, 38),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      );
    } else {
      return const Center(child: Text('No notifications to display'));
    }
  }


  Widget userWarningCard() {
    if (_allNoticesResults.isNotEmpty) {
      return ListView.builder(
        itemCount: _allNoticesResults.length,
        itemBuilder: (context, index) {
          var notification = _allNoticesResults[index];
          var notificationAccountNumber = notification['user']?.toString() ?? '';
          var selectedAccountNumber = widget.selectedPropertyAccountNumber ?? '';
          var level = notification['level'] ?? 'general';
          var isRead = notification['read'] ?? true;

          // Only show unread severe notifications for the selected property account number
          if (notificationAccountNumber == selectedAccountNumber &&
              !isRead &&
              level == 'severe') {
            return Card(
              margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Unread Warning Notification',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Notice Header:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(notification['title'] ?? 'No Title',
                        style: const TextStyle(fontSize: 16)),
                    const Text(
                      'Notice Details:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(notification['body'] ?? 'No Body',
                        style: const TextStyle(fontSize: 16)),
                    const Text(
                      'Notice Received Date:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(notification['date'] ?? 'No Date',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        BasicIconButtonGrey(
                          onPress: () async {
                            notifyToken = notification['token'];
                            _notifyUpdate(notification);
                          },
                          labelText: 'Mark as Read',
                          fSize: 14,
                          faIcon: const FaIcon(Icons.check_circle),
                          fgColor: Colors.green,
                          btSize: const Size(50, 38),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          } else {
            return const SizedBox.shrink(); // Don't show anything if it doesn't match
          }
        },
      );
    } else {
      return const Center(
        child: Text('No warnings to display'),
      );
    }
  }


  Widget firebaseUserNotificationCard(
      CollectionReference<Object?> noticeDataStream) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: noticeDataStream.orderBy('date', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                streamSnapshot.data!.docs[index];

                if (documentSnapshot['user'] == user.phoneNumber.toString()) {
                  if (documentSnapshot['user'].contains('+27') &&
                      documentSnapshot['read'] != true &&
                      documentSnapshot['level'] == 'general') {
                    return Card(
                      margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'Unread Notification',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            const Text(
                              'Notice Header:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            noticeItemField(documentSnapshot['title']),
                            const Text(
                              'Notice Details:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            noticeItemField(documentSnapshot['body']),
                            const Text(
                              'Notice Received Date:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            noticeItemField(documentSnapshot['date']),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        notifyToken = documentSnapshot['token'];
                                        if ((documentSnapshot['user']
                                            .toString()).contains('+27')) {
                                          _notifyUpdate(documentSnapshot);
                                        }
                                       await fetchNotifications();
                                      },
                                      labelText: 'Mark as Read',
                                      fSize: 14,
                                      faIcon: const FaIcon(Icons.check_circle,),
                                      fgColor: Colors.green,
                                      btSize: const Size(50, 38),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const Card();
                  }
                }
                return const Card();
              },
            );
          }
          return const Padding(
            padding: EdgeInsets.all(10.0),
            child: Center(
                child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget firebaseUserWarningCard(
      CollectionReference<Object?> noticeDataStream) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: noticeDataStream.orderBy('date', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                streamSnapshot.data!.docs[index];

                if (documentSnapshot['user'] == user.phoneNumber.toString()) {
                  if (documentSnapshot['read'] != true &&
                      documentSnapshot['level'] == 'severe') {
                    return Card(
                      margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'Unread Notification',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            const Text(
                              'Notice Header:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            noticeItemWarningField(documentSnapshot['title'],),
                            const Text(
                              'Notice Details:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            noticeItemField(documentSnapshot['body']),
                            const Text(
                              'Notice Received Date:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            noticeItemField(documentSnapshot['date']),
                            const SizedBox(height: 5,),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        CollectionReference chatFinCollectionRef = FirebaseFirestore
                                            .instance
                                            .collection('districts')
                                            .doc(districtId)
                                            .collection('municipalities')
                                            .doc(municipalityId)
                                            .collection('chatRoomFinance');
                                        String financeID = 'finance@msunduzi.gov.za';

                                        String passedID = user.phoneNumber!;
                                        String? userName = FirebaseAuth.instance
                                            .currentUser!.phoneNumber;
                                        print(
                                            'The user name of the logged in person is $userName}');
                                        String id = passedID;

                                        Navigator.push(context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    ChatFinance(chatRoomId: id,
                                                      userName: null,
                                                      chatFinCollectionRef: chatFinCollectionRef,
                                                      refreshChatList: () {},
                                                      isLocalMunicipality: widget.isLocalMunicipality, // Pass this
                                                      municipalityId: widget.municipalityId, // Pass this
                                                      districtId: widget.districtId?? '',
                                                    )));
                                        // final Uri _tel = Uri.parse('tel:+27${0333923000}');
                                        // launchUrl(_tel);

                                      },
                                      labelText: 'Appeal',
                                      fSize: 14,
                                      faIcon: const FaIcon(Icons.add_call,),
                                      fgColor: Colors.orangeAccent,
                                      btSize: const Size(50, 38),
                                    ),
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        notifyToken = documentSnapshot['token'];
                                        if ((documentSnapshot['user']
                                            .toString()).contains('+27')) {
                                          _notifyUpdate(documentSnapshot);
                                        }
                                      },
                                      labelText: 'Mark Read',
                                      fSize: 14,
                                      faIcon: const FaIcon(Icons.check_circle,),
                                      fgColor: Colors.green,
                                      btSize: const Size(50, 38),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const Card();
                  }
                }
              },
            );
          }
          return const Padding(
            padding: EdgeInsets.all(10.0),
            child: Center(
                child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  //This class is for updating the notification
  // Future<void> _notifyUpdate([DocumentSnapshot? documentSnapshot]) async {
  //
  //   // if (documentSnapshot != null) {
  //   //   username.text = documentSnapshot.id;
  //   //   title.text = documentSnapshot['title'];
  //   //   body.text = documentSnapshot['body'];
  //   //   _noticeReadController = documentSnapshot['read'];
  //   //   _headerController.text = documentSnapshot['title'];
  //   //   _messageController.text = documentSnapshot['body'];
  //   // }
  //
  //   DateTime now = DateTime.now();
  //   String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);
  //
  //   final String tokenSelected = notifyToken;
  //   // final String? userNumber = documentSnapshot?.id;
  //   // final String notificationTitle = title.text;
  //   // final String notificationBody = body.text;
  //   // final String notificationDate = formattedDate;
  //   // final bool readStatus = _noticeReadController;
  //
  //   if (tokenSelected != null) {
  //     await _listNotifications
  //         .doc(documentSnapshot?.id)
  //         .update({
  //       "read": true,
  //     });
  //   }
  //
  // }
  Future<void> _notifyUpdate([DocumentSnapshot? documentSnapshot]) async {
    if (_listNotifications != null && documentSnapshot != null) {
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);

      final String tokenSelected = notifyToken;

      if (tokenSelected.isNotEmpty) {
        await _listNotifications!
            .doc(documentSnapshot.id)
            .update({
          "read": true,
        });
        await fetchNotifications();
      }
    } else {
      print('Notification collection or document is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[350],
        appBar: AppBar(
          title: const Text(
              'Latest Notifications', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: <Widget>[
            Visibility(
              visible: true,
              child: IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => NoticeArchiveScreen()));
                },
                icon: const Icon(Icons.history_outlined, color: Colors.white),
              ),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'General Notices'),
              Tab(text: 'Warning Notices'),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          children: [

            /// General Notices
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: userNotificationCard(),
            ),

            /// Warning Notices
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: userWarningCard(),
            ),
          ],
        ),
      ),
    );
  }
}