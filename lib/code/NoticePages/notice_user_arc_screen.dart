import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
import 'package:provider/provider.dart';
import 'package:municipal_services/code/faultPages/fault_task_screen_archive.dart';
import 'package:municipal_services/code/MapTools/map_screen.dart';
import 'package:municipal_services/code/MapTools/map_screen_prop.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';

import '../Models/prop_provider.dart';

class NoticeArchiveScreen extends StatefulWidget {
  final String? selectedPropertyAccountNumber;
  final bool isLocalMunicipality;
  final String municipalityId;
  final String? districtId;

  const NoticeArchiveScreen({
    super.key,
    required this.selectedPropertyAccountNumber, // ✅ Accept account number
    required this.isLocalMunicipality,
    required this.municipalityId,
    this.districtId,
  });

  @override
  State<NoticeArchiveScreen> createState() => _NoticeArchiveScreenState();
}
final FirebaseAuth auth = FirebaseAuth.instance;
DateTime now = DateTime.now();
final User? user = auth.currentUser;
final uid = user?.uid;
final email = user?.email;
String userID = uid as String;
String userEmail = email as String;

class _NoticeArchiveScreenState extends State<NoticeArchiveScreen> {
  CollectionReference? _listNotifications;
  final CollectionReference _listUserTokens =
  FirebaseFirestore.instance.collection('UserToken');
  String? userEmail;
 String? districtId;
   String? municipalityId;
  // final CollectionReference _listNotifications =
  // FirebaseFirestore.instance.collection('Notifications');
  bool isLoading = true;
  final _headerController = TextEditingController();
  final _messageController = TextEditingController();
  final _searchBarController = TextEditingController();
  late bool _noticeReadController;
  List<DocumentSnapshot> _allNoticesResults = [];
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
  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
    fetchNotices();
  }

  @override
  void dispose() {
    _headerController;
    _messageController;
    searchText;
    super.dispose();
  }

  Future<void> fetchUserDetails() async {
    try {
      if (widget.selectedPropertyAccountNumber == null) {
        Fluttertoast.showToast(
          msg: "No selected property found!",
          gravity: ToastGravity.CENTER,
        );
        return;
      }

      setState(() {
        municipalityId = widget.municipalityId;
        districtId = widget.districtId ?? "";
      });

      // Initialize the Firestore reference
      _listNotifications = FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('Notifications');

      print("✅ Notifications collection initialized.");

      // Fetch notifications that are "read" for this user
      QuerySnapshot querySnapshot = await _listNotifications!
          .where('user', isEqualTo: widget.selectedPropertyAccountNumber)
          .where('read', isEqualTo: true) // ✅ Only fetch "read" notifications
          .get();

      print("📩 Found ${querySnapshot.docs.length} read notifications.");

      setState(() {
        _allNoticesResults = querySnapshot.docs;
        isLoading = false;
      });

    } catch (e) {
      print('❌ Error fetching notifications: $e');
      setState(() {
        isLoading = false;
      });
    }
  }


  Future<void> fetchNotices() async {
    try {
      if(mounted) {
        setState(() {
          isLoading = true; // Start loading
        });
      }
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(widget.districtId)
          .collection('municipalities')
          .doc(widget.municipalityId)
          .collection('Notifications')
          .where('user', isEqualTo: widget.selectedPropertyAccountNumber) // ✅ Match account number
          .where('read', isEqualTo: true) // ✅ Show only read notifications
          .orderBy('date', descending: true) // ✅ Order by latest first
          .get();
         if(mounted) {
           setState(() {
             _allNoticesResults = querySnapshot.docs; // ✅ Assign results
             isLoading = false; // Stop loading
           });
         }
      print("✅ Retrieved ${_allNoticesResults.length} notifications.");
    } catch (e) {
      print("❌ Error fetching notices: $e");
      if(mounted) {
        setState(() {
          isLoading = false; // Ensure UI updates
        });
      }
    }
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

  Widget _noticeField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(value, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }


  /// **Fetch & Display Read Notifications**
  Widget _userNotificationCard(CollectionReference noticeDataStream) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: noticeDataStream
            .where('user', isEqualTo: widget.selectedPropertyAccountNumber) // ✅ Filter by account number
            .where('read', isEqualTo: true) // ✅ Only show read notifications
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!streamSnapshot.hasData || streamSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "No read notifications available.",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: streamSnapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final DocumentSnapshot documentSnapshot =
              streamSnapshot.data!.docs[index];

              return Card(
                margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Previous Notification',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _noticeField("Notice Header:", documentSnapshot['title']),
                      _noticeField("Notice Details:", documentSnapshot['body']),
                      _noticeField("Received Date:", documentSnapshot['date']),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }


  //This class is for updating the notification
  Future<void> _notifyUpdate([DocumentSnapshot? documentSnapshot]) async {

    // if (documentSnapshot != null) {
    //   username.text = documentSnapshot.id;
    //   title.text = documentSnapshot['title'];
    //   body.text = documentSnapshot['body'];
    //   _noticeReadController = documentSnapshot['read'];
    //   _headerController.text = documentSnapshot['title'];
    //   _messageController.text = documentSnapshot['body'];
    // }

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);

    final String tokenSelected = notifyToken;
    // final String? userNumber = documentSnapshot?.id;
    // final String notificationTitle = title.text;
    // final String notificationBody = body.text;
    // final String notificationDate = formattedDate;
    // final bool readStatus = _noticeReadController;

    if (tokenSelected != null) {
      await _listNotifications
          ?.doc(documentSnapshot?.id)
          .update({
        "read": false,
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Previous Notifications', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // ✅ Show loader
          : _allNoticesResults.isEmpty
          ? const Center(child: Text("No read notifications found.")) // ✅ No results message
          : ListView.builder(
        itemCount: _allNoticesResults.length,
        itemBuilder: (context, index) {
          final DocumentSnapshot documentSnapshot = _allNoticesResults[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(documentSnapshot['title'], style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(documentSnapshot['body']),
              trailing: Text(documentSnapshot['date']),
            ),
          );
        },
      ),
    );
  }

}
