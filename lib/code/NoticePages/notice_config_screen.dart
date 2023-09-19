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
import 'package:municipal_tracker_msunduzi/code/NoticePages/notice_config_arc_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:municipal_tracker_msunduzi/code/faultPages/fault_task_screen_archive.dart';
import 'package:municipal_tracker_msunduzi/code/MapTools/map_screen.dart';
import 'package:municipal_tracker_msunduzi/code/MapTools/map_screen_prop.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/icon_elevated_button.dart';

class NoticeConfigScreen extends StatefulWidget {
  const NoticeConfigScreen({Key? key}) : super(key: key);

  @override
  State<NoticeConfigScreen> createState() => _NoticeConfigScreenState();
}


class _NoticeConfigScreenState extends State<NoticeConfigScreen> {

  final CollectionReference _listUserTokens =
  FirebaseFirestore.instance.collection('UserToken');

  final CollectionReference _listNotifications =
  FirebaseFirestore.instance.collection('Notifications');

  final _headerController = TextEditingController();
  final _messageController = TextEditingController();
  final _searchBarController = TextEditingController();
  late bool _noticeReadController;

  List<String> usersNumbers =[];
  List<String> usersTokens =[];
  List<String> usersRetrieve =[];

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

  int numTokens=0;

  @override
  void initState() {
    checkAdmin();
    countResult();
    super.initState();
  }

  void countResult() async{
    var query = _listUserTokens.where("token");
    var snapshot = await query.get();
    var count = snapshot.size;
    numTokens = snapshot.size;
    print('Records are ::: $count');
    print('num tokens are ::: $numTokens');
  }

  @override
  void dispose() {
    _headerController;
    _messageController;
    token;
    title;
    body;
    searchText;
    usersNumbers;
    usersTokens;
    super.dispose();
  }

  User? user = FirebaseAuth.instance.currentUser;

  void checkAdmin() {
    String? emailLogged = user?.email.toString();
    if(emailLogged?.contains("admin") == true){
      adminAcc = true;
    } else {
      adminAcc = false;
    }
  }

  //function for messaging
  void sendPushMessage(String token, String title, String body,) async{
    try{
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=AAAA5PnILx8:APA91bFrXK321LraFWsbh6er8bWta0ggbvb0pxUhVnzYfjYbP6rDMecElIu0pAYnKOWthddgsZUxXMEPPXxT1EguNdkGYZsrm3fjjlGeY2EP4bxjgvn9IZQvgxKzv6w8ES2f_g9Idlv5',
        },
        body: jsonEncode(
          <String, dynamic>{
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action':'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
              'title': title,
              'body': body,
            },

            "notification": <String, dynamic>{
              "title": title,
              "body": body,
              "android_channel_id": "User"
            },
            "to": token,
          },
        ),
      );
    } catch(e) {
      if(kDebugMode){
        print("error push notification");
      }
    }
  }

  //this widget is for displaying a property field of information with an icon next to it, NB. the icon is to make it look good
  //it is called within a listview page widget
  Widget tokenItemField(String tokenData) {
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
              tokenData,
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

                if(documentSnapshot.id.toString().contains('+27') && usersNumbers.length<numTokens && usersTokens.length<numTokens) {
                  usersNumbers.add(documentSnapshot.id.toString());
                  usersTokens.add(documentSnapshot['token']);
                }

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
                            tokenItemField('User Phone Number ${documentSnapshot.id}'),
                            Visibility(
                              visible: false,
                              child: Text(
                                'User Token: ${documentSnapshot['token']}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                            ),
                            // const SizedBox(height: 10,),
                            // Column(
                            //   children: [
                            //     Row(
                            //       mainAxisAlignment: MainAxisAlignment.center,
                            //       crossAxisAlignment: CrossAxisAlignment.center,
                            //       children: [
                            //         BasicIconButtonGrey(
                            //           onPress: () async {
                            //             showDialog(
                            //                 barrierDismissible: false,
                            //                 context: context,
                            //                 builder: (context) {
                            //                   return
                            //                     AlertDialog(
                            //                       shape: const RoundedRectangleBorder(
                            //                           borderRadius:
                            //                           BorderRadius.all(Radius.circular(16))),
                            //                       title: const Text("Call User!"),
                            //                       content: const Text(
                            //                           "Would you like to call the user directly?"),
                            //                       actions: [
                            //                         IconButton(
                            //                           onPressed: () {
                            //                             Navigator.of(context).pop();
                            //                           },
                            //                           icon: const Icon(
                            //                             Icons.cancel,
                            //                             color: Colors.red,
                            //                           ),
                            //                         ),
                            //                         IconButton(
                            //                           onPressed: () {
                            //                             String cellGiven = documentSnapshot.id;
                            //
                            //                             final Uri _tel = Uri.parse('tel:${cellGiven.toString()}');
                            //                             launchUrl(_tel);
                            //
                            //                             Navigator.of(context).pop();
                            //                           },
                            //                           icon: const Icon(
                            //                             Icons.done,
                            //                             color: Colors.green,
                            //                           ),
                            //                         ),
                            //                       ],
                            //                     );
                            //                 });
                            //           },
                            //           labelText: 'Call User',
                            //           fSize: 14,
                            //           faIcon: const FaIcon(Icons.call,),
                            //           fgColor: Colors.green,
                            //           btSize: const Size(50, 38),
                            //         ),
                            //         BasicIconButtonGrey(
                            //           onPress: () async {
                            //             notifyToken = documentSnapshot['token'];
                            //             _notifyThisUser(documentSnapshot);
                            //           },
                            //           labelText: 'Notify User',
                            //           fSize: 14,
                            //           faIcon: const FaIcon(Icons.edit,),
                            //           fgColor: Theme.of(context).primaryColor,
                            //           btSize: const Size(50, 38),
                            //         ),
                            //       ],
                            //     ),
                            //   ],
                            // ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const Card();
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

  Widget userAndTokenCardSearch(CollectionReference<Object?> tokenDataStream){
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
                            tokenItemField('User Phone Number ${documentSnapshot.id}'),
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
                                      labelText: 'Notify',
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

  //This class is for updating the notification
  Future<void> _notifyUpdateUser([DocumentSnapshot? documentSnapshot]) async {

    if (documentSnapshot != null) {
      username.text = documentSnapshot.id;
      title.text = documentSnapshot['title'];
      body.text = documentSnapshot['body'];
      _noticeReadController = documentSnapshot['read'];

      _headerController.text = documentSnapshot['title'];
      _messageController.text = documentSnapshot['body'];
    }

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    void _createBottomSheet() async{
      Future<void> future = showModalBottomSheet(
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
                            Visibility(
                              visible: visShow,
                              child:
                              Container(
                                height: 50,
                                padding: const EdgeInsets.only(left: 0.0, right: 25.0),
                                child: Row(
                                  children: <Widget>[
                                    const Text('Notice Has Been Read', style: TextStyle(fontSize: 16, fontWeight:FontWeight.w400 ),),
                                    const SizedBox(width: 5,),
                                    Checkbox(
                                      checkColor: Colors.white,
                                      fillColor: MaterialStateProperty.all<Color>(
                                          Colors.green),
                                      value: _noticeReadController,
                                      onChanged: (bool? value) async {
                                        setState(() {
                                          _noticeReadController = value!;
                                        });
                                      },
                                    ),
                                  ],
                                ),
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
                                  final String? userNumber = documentSnapshot?.id;
                                  final String notificationTitle = title.text;
                                  final String notificationBody = body.text;
                                  final String notificationDate = formattedDate;
                                  final bool readStatus = _noticeReadController;

                                  if (tokenSelected != null) {
                                    if(title.text != '' || title.text.isNotEmpty || body.text != '' || body.text.isNotEmpty){
                                      await _listNotifications
                                          .doc(documentSnapshot?.id)
                                          .update({
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
                                      if(userNumber != ""){
                                        DocumentSnapshot snap =
                                        await FirebaseFirestore.instance.collection("UserToken").doc(userNumber).get();

                                        String token = snap['token'];

                                        sendPushMessage(token, titleText, bodyText);
                                      }

                                    } else {
                                      Fluttertoast.showToast(msg: 'Please fill Header and Message of the Notification!', gravity: ToastGravity.CENTER);
                                    }
                                  }

                                  username.text =  '';
                                  title.text =  '';
                                  body.text =  '';
                                  _headerController.text =  '';
                                  _messageController.text =  '';
                                  _noticeReadController =  false;
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

    _createBottomSheet();

  }

  Future<void> _notifyAllUser([DocumentSnapshot? documentSnapshot]) async {

    _searchBarController.text = '';

    for (var i = 0; i < numTokens; i++) {
      if (documentSnapshot?.id == usersNumbers[i]) {
        usersNumbers.removeAt(i);
      }
    }
    print(usersNumbers);
    print(usersNumbers.length);
    print(usersTokens);
    print(usersTokens.length);

    if (documentSnapshot != null) {
      username.text = documentSnapshot.id;
      title.text = documentSnapshot['title'];
      body.text = documentSnapshot['body'];
      _headerController.text = documentSnapshot['title'];
      _messageController.text = documentSnapshot['body'];
    }

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    void _createBottomSheet() async{
      Future<void> future = showModalBottomSheet(
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

                                  for(int i = 0;i<usersTokens.length;i++){

                                    final String tokenSelected = usersTokens[i];
                                    final String userNumber = usersNumbers[i];
                                    final String notificationTitle = title.text;
                                    final String notificationBody = body.text;
                                    final String notificationDate = formattedDate;
                                    const bool readStatus = false;

                                    if (tokenSelected != null) {
                                      if(title.text != '' || title.text.isNotEmpty || body.text != '' || body.text.isNotEmpty){
                                        await _listNotifications
                                            .add({
                                          "token": tokenSelected,
                                          "user": userNumber,
                                          "title": notificationTitle,
                                          "body": notificationBody,
                                          "read": readStatus,
                                          "date": notificationDate,
                                        });

                                      } else {
                                        Fluttertoast.showToast(msg: 'Please Fill Header and Message of the notification!', gravity: ToastGravity.CENTER);
                                      }
                                    }

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
                                      Fluttertoast.showToast(msg: 'All users have been sent the notification!', gravity: ToastGravity.CENTER);
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

    _createBottomSheet();

  }

  Future<void> _notifyThisUser([DocumentSnapshot? documentSnapshot]) async {

    if (documentSnapshot != null) {
      username.text = documentSnapshot.id;
    }

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    void _createBottomSheet() async{
      Future<void> future = showModalBottomSheet(
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
                                final String? userNumber = documentSnapshot?.id;
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
                                        Fluttertoast.showToast(msg: 'The user has been sent the notification!', gravity: ToastGravity.CENTER);
                                      }
                                    } else {
                                      Fluttertoast.showToast(msg: 'Please Fill Header and Message of the notification!', gravity: ToastGravity.CENTER);
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

    _createBottomSheet();

  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[350],
        appBar: AppBar(
          title: const Text('User Notifications',style: TextStyle(color: Colors.white),),
          backgroundColor: Colors.green,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: <Widget>[
            Visibility(
                visible: adminAcc,
                child: IconButton(
                    onPressed: (){
                      usersNumbers = [];
                      usersTokens = [];
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const NoticeConfigArcScreen()));
                    },
                    icon: const Icon(Icons.history_outlined, color: Colors.white,)),),
          ],
          bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: 'Notify All',),
                Tab(text: 'Targeted Notice',),
              ]
          ),
        ),

        body: TabBarView(
          children: [
            ///Tab for all
            Column(
            children: [
              const SizedBox(height: 10,),
              ///this onPress code bellow is used to set the message information and pop it up to the user in their notifications.
              ///button not needed as it will only be used when a new chat is sent or when an admin sends to a specific phone which will be a list of tokens per device

              BasicIconButtonGrey(
                onPress: () async {
                  _notifyAllUser();
                },
                labelText: 'Send Notice To All',
                fSize: 16,
                faIcon: const FaIcon(Icons.notifications,),
                fgColor: Theme.of(context).primaryColor,
                btSize: const Size(300, 50),
              ),

              const SizedBox(height: 10,),

              ///made the listview card a reusable widget
              userAndTokenCard(_listUserTokens),

            ],
          ),

            ///Tab for searching
            Column(
              children: [
                const SizedBox(height: 10,),
                ///this onPress code bellow is used to set the message information and pop it up to the user in their notifications.
                ///button not needed as it will only be used when a new chat is sent or when an admin sends to a specific phone which will be a list of tokens per device


                /// Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(10.0,5.0,10.0,5.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        onChanged: (value) async{
                          setState(() {
                            usersNumbers = [];
                            usersTokens = [];
                            searchText = value;
                            print('this is the input text ::: $searchText');
                          });
                        },
                        autofocus: false,
                        controller: _searchBarController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search by phone number',
                          focusColor: Colors.white,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                /// Search bar end

                ///made the listview card a reusable widget
                userAndTokenCardSearch(_listUserTokens),

              ],
            ),
          ]
        ),
      ),
    );
  }
}
