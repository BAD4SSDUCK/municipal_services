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

import 'package:municipal_tracker_msunduzi/code/faultPages/fault_task_screen_archive.dart';
import 'package:municipal_tracker_msunduzi/code/MapTools/map_screen.dart';
import 'package:municipal_tracker_msunduzi/code/MapTools/map_screen_prop.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/icon_elevated_button.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/push_notification_message.dart';

class NoticeConfigArcScreen extends StatefulWidget {
  const NoticeConfigArcScreen({Key? key}) : super(key: key);

  @override
  State<NoticeConfigArcScreen> createState() => _NoticeConfigArcScreenState();
}

final FirebaseAuth auth = FirebaseAuth.instance;

final User? user = auth.currentUser;
final uid = user?.uid;
final email = user?.email;
String userID = uid as String;
String userEmail = email as String;

class _NoticeConfigArcScreenState extends State<NoticeConfigArcScreen> {

  final CollectionReference _listUserTokens =
  FirebaseFirestore.instance.collection('UserToken');

  final CollectionReference _listNotifications =
  FirebaseFirestore.instance.collection('Notifications');

  final _headerController = TextEditingController();
  final _messageController = TextEditingController();
  final _searchBarController = TextEditingController();
  late bool _noticeReadController;

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

  String userRole = '';
  List _allUserRolesResults = [];
  bool visShow = true;
  bool visHide = false;
  bool adminAcc = false;

  @override
  void initState() {
    checkAdmin();
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

  void checkAdmin() {
    getUsersStream();
    if(userRole == 'Admin'|| userRole == 'Administrator'){
      adminAcc = true;
    } else {
      adminAcc = false;
    }
  }

  getUsersStream() async{
    var data = await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      _allUserRolesResults = data.docs;
    });
    getUserDetails();
  }

  getUserDetails() async {
    for (var userSnapshot in _allUserRolesResults) {
      ///Need to build a property model that retrieves property data entirely from the db
      var user = userSnapshot['email'].toString();
      var role = userSnapshot['userRole'].toString();

      if (user == userEmail) {
        userRole = role;
        print('My Role is::: $userRole');

        if (userRole == 'Admin' || userRole == 'Administrator') {
          adminAcc = true;
        } else {
          adminAcc = false;
        }
      }
    }
  }

  //this widget is for displaying a property field of information with an icon next to it, NB. the icon is to make it look good
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

  //this widget is for displaying users phone numbers with the hidden stored device token
  Widget userAndTokenCard(CollectionReference<Object?> tokenDataStream){
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: tokenDataStream.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                streamSnapshot.data!.docs[index];

                if(((documentSnapshot.id.trim()).toLowerCase()).contains((_searchBarController.text.trim()).toLowerCase())){
                  if(documentSnapshot.id.contains('+27')){
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
                                'Users Device Number',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            noticeItemField(documentSnapshot.id),
                            Visibility(
                              visible: false,
                              child: Text(
                                'User Token: ${documentSnapshot['token']}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        showDialog(
                                            barrierDismissible: false,
                                            context: context,
                                            builder: (context) {
                                              return
                                                AlertDialog(
                                                  shape: const RoundedRectangleBorder(
                                                      borderRadius:
                                                      BorderRadius.all(Radius.circular(16))),
                                                  title: const Text("Call User!"),
                                                  content: const Text(
                                                      "Would you like to call the user directly?"),
                                                  actions: [
                                                    IconButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                      icon: const Icon(
                                                        Icons.cancel,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      onPressed: () {
                                                        String cellGiven = documentSnapshot.id;

                                                        final Uri _tel = Uri.parse('tel:${cellGiven.toString()}');
                                                        launchUrl(_tel);

                                                        Navigator.of(context).pop();
                                                      },
                                                      icon: const Icon(
                                                        Icons.done,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  ],
                                                );
                                            });
                                      },
                                      labelText: 'Call User',
                                      fSize: 14,
                                      faIcon: const FaIcon(Icons.call,),
                                      fgColor: Colors.green,
                                      btSize: const Size(50, 38),
                                    ),
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        notifyToken = documentSnapshot['token'];
                                        _notifyThisUser(documentSnapshot);
                                      },
                                      labelText: 'Notify User',
                                      fSize: 14,
                                      faIcon: const FaIcon(Icons.edit,),
                                      fgColor: Theme.of(context).primaryColor,
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

  //this widget is for displaying all notifications already sent to users phone numbers
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

                if(((documentSnapshot['user'])).contains((_searchBarController.text.trim()).toLowerCase())){
                  if(documentSnapshot['user'].contains('+27')){
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
                                'Delivered Notification',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            const Text(
                              'User number:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            noticeItemField(documentSnapshot['user']),
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
                              'Date Notice Sent:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            noticeItemField(documentSnapshot['date']),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        showDialog(
                                            barrierDismissible: false,
                                            context: context,
                                            builder: (context) {
                                              return
                                                AlertDialog(
                                                  shape: const RoundedRectangleBorder(
                                                      borderRadius:
                                                      BorderRadius.all(Radius.circular(16))),
                                                  title: const Text("Call User!"),
                                                  content: const Text(
                                                      "Would you like to call the user directly?"),
                                                  actions: [
                                                    IconButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                      icon: const Icon(
                                                        Icons.cancel,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      onPressed: () {
                                                        String cellGiven = documentSnapshot['user'];

                                                        final Uri _tel = Uri.parse('tel:$cellGiven');
                                                        launchUrl(_tel);

                                                        Navigator.of(context).pop();
                                                      },
                                                      icon: const Icon(
                                                        Icons.done,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  ],
                                                );
                                            });
                                      },
                                      labelText: 'Call User',
                                      fSize: 14,
                                      faIcon: const FaIcon(Icons.call,),
                                      fgColor: Colors.green,
                                      btSize: const Size(50, 38),
                                    ),

                                  ],
                                ),
                                BasicIconButtonGrey(
                                  onPress: () async {
                                    notifyToken = documentSnapshot['token'];
                                    if((documentSnapshot['user'].toString()).contains('+27')){
                                      _notifyThisUser(documentSnapshot);
                                    }
                                  },
                                  labelText: 'Re-Send Notice',
                                  fSize: 14,
                                  faIcon: const FaIcon(Icons.edit,),
                                  fgColor: Theme.of(context).primaryColor,
                                  btSize: const Size(50, 38),
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

  Future<void> _notifyThisUser([DocumentSnapshot? documentSnapshot]) async {

    if (documentSnapshot != null) {
      username.text = documentSnapshot['user'];
      title.text = documentSnapshot['title'];
      body.text = documentSnapshot['body'];
    }

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    void _createBottomSheet() async{
      // Future<void> future =
      if (!context.mounted) {
        showModalBottomSheet(
          context: context,
          builder: await showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (BuildContext ctx) {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(
                            top: 20,
                            left: 20,
                            right: 20,
                            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Visibility(
                              visible: visShow,
                              child: TextField(
                                controller: title,
                                decoration: const InputDecoration(
                                    labelText: 'Message Header'),
                              ),
                            ),
                            Visibility(
                              visible: visShow,
                              child: TextField(
                                controller: body,
                                decoration: const InputDecoration(
                                    labelText: 'Message'),
                              ),
                            ),

                            const SizedBox(
                              height: 10,
                            ),
                            ElevatedButton(
                              child: const Text('Send Notification'),
                              onPressed: () async {

                                DateTime now = DateTime.now();
                                String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);

                                final String tokenSelected = notifyToken;
                                final String? userNumber = documentSnapshot?['user'];
                                final String notificationTitle = title.text;
                                final String notificationBody = body.text;
                                final String notificationDate = formattedDate;
                                const bool readStatus = false;

                                  if (tokenSelected != null) {
                                    if(title.text != '' || title.text.isNotEmpty || body.text != '' || body.text.isNotEmpty) {
                                      await _listNotifications.add({
                                        "token": tokenSelected,
                                        "user": userNumber,
                                        "title": notificationTitle,
                                        "body": notificationBody,
                                        "read": readStatus,
                                        "date": notificationDate,
                                      });

                                      ///It can be changed to the firebase notification
                                      String titleText = title.text;
                                      String bodyText = body.text;

                                      ///gets users phone token to send notification to this phone
                                      if (userNumber != "") {
                                        DocumentSnapshot snap = await FirebaseFirestore.instance.collection("UserToken").doc(userNumber).get();
                                        String token = snap['token'];
                                        print('The phone number is retrieved as ::: $userNumber');
                                        print('The token is retrieved as ::: $token');
                                        sendPushMessage(token, titleText, bodyText);
                                      }
                                    } else {
                                      Fluttertoast.showToast(msg: 'Please Fill Header and Details of the Notification!', gravity: ToastGravity.CENTER);
                                    }
                                  }

                                  username.text =  '';
                                  title.text =  '';
                                  body.text =  '';
                                  _headerController.text =  '';
                                  _messageController.text =  '';

                                  if(context.mounted)Navigator.of(context).pop();

                                }
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              }));
      }
    }

    _createBottomSheet();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Notification Archive',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Column(
        children: [
          const SizedBox(height: 10,),
          ///this onPress code bellow is used to set the message information and pop it up to the user in their notifications.
          ///button not needed as it will only be used when a new chat is sent or when an admin sends to a specific phone which will be a list of tokens per device

          // BasicIconButtonGrey(
          //   onPress: () async {
          //
          //            ///It can be changed to the firebase notification
          //            String titleText = title.text;
          //            String bodyText = body.text;
          //
          //            ///gets users phone token to send notification to this phone
          //            if(user.phoneNumber! != ""){
          //              DocumentSnapshot snap =
          //              await FirebaseFirestore.instance.collection("UserToken").doc(user.phoneNumber!).get();
          //
          //              String token = snap['token'];
          //
          //              sendPushMessage(token, titleText, bodyText);
          //            }
          //   },
          //   labelText: 'Send Notice To All',
          //   fSize: 16,
          //   faIcon: const FaIcon(Icons.notifications,),
          //   fgColor: Theme.of(context).primaryColor,
          //   btSize: const Size(300, 50),
          // ),

          // const SizedBox(height: 10,),

          /// Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(10.0,5.0,10.0,5.0),
            child: SearchBar(
              controller: _searchBarController,
              padding: const MaterialStatePropertyAll<EdgeInsets>(
                  EdgeInsets.symmetric(horizontal: 16.0)),
              leading: const Icon(Icons.search),
              hintText: "Search by Phone Number...",
              onChanged: (value) async{
                setState(() {
                  searchText = value;
                  print('this is the input text ::: $searchText');
                });
              },
            ),
          ),
          /// Search bar end

          ///made the listview card a reusable widget
          // userAndTokenCard(_listUserTokens),

          userNotificationCard(_listNotifications),

        ],
      ),
    );
  }
}
