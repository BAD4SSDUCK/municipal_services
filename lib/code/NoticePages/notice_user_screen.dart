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
import 'package:municipal_tracker_msunduzi/code/NoticePages/notice_user_arc_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:municipal_tracker_msunduzi/code/faultPages/fault_task_screen_archive.dart';
import 'package:municipal_tracker_msunduzi/code/MapTools/map_screen.dart';
import 'package:municipal_tracker_msunduzi/code/MapTools/map_screen_prop.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/icon_elevated_button.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({Key? key}) : super(key: key);

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}


class _NoticeScreenState extends State<NoticeScreen> {

  final CollectionReference _listNotifications =
  FirebaseFirestore.instance.collection('Notifications');

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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _headerController;
    _messageController;
    searchText;
    super.dispose();
  }

  User? user = FirebaseAuth.instance.currentUser;

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

  Widget userNotificationCard(CollectionReference<Object?> noticeDataStream){
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

                if(documentSnapshot['user'] == user?.phoneNumber.toString()){
                  if(documentSnapshot['user'].contains('+27') && documentSnapshot['read'] != true ){
                    return Card(
                      margin: const EdgeInsets.fromLTRB(10.0,5.0,10.0,10.0),
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
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            noticeItemField(documentSnapshot['title']),
                            const Text(
                              'Notice Details:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            noticeItemField(documentSnapshot['body']),
                            const Text(
                              'Notice Received Date:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                                        if((documentSnapshot['user'].toString()).contains('+27')){
                                          _notifyUpdate(documentSnapshot);
                                        }
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
          .doc(documentSnapshot?.id)
          .update({
        "read": true,
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Latest Notifications'),
        actions: <Widget>[
          Visibility(
              visible: true,
              child: IconButton(
                  onPressed: (){
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => const NoticeArchiveScreen()));
                  },
                  icon: const Icon(Icons.history_outlined, color: Colors.white,)),),
        ],
        backgroundColor: Colors.green,
      ),

      body: Column(
        children: [
          const SizedBox(height: 10,),
          ///made the listview card a reusable widget
          userNotificationCard(_listNotifications),
        ],
      ),
    );
  }
}
