import 'dart:collection';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:municipal_track/code/ImageUploading/image_upload_page.dart';
import 'package:municipal_track/code/Reuseables/main_menu_reusable_button.dart';
import 'package:municipal_track/code/Reuseables/nav_drawer.dart';
import 'package:municipal_track/main.dart';
import 'package:http/http.dart' as http;

import '../Reuseables/map_component.dart';
import '../Reuseables/menu_reusable_elevated_button.dart';
import 'add_details.dart';
import 'display_info.dart';
import 'display_info_edit.dart';

// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:quickblox_sdk/push/constants.dart';
// import 'package:quickblox_sdk/quickblox_sdk.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() =>_MainMenuState();
  }

  class _MainMenuState extends State<MainMenu>{
  final user = FirebaseAuth.instance.currentUser!;

  ///Methods and implementation for push notifications with firebase and specific device token saving
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  TextEditingController username = TextEditingController();
  TextEditingController title = TextEditingController();
  TextEditingController body = TextEditingController();
  String? mtoken = " ";

  @override
  void initState() {
    super.initState();
    requestPermission();
    getToken();
    initInfo();
  }

  void requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized){
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional){
      print('User granted provisional permissions');
    } else {
      print('User declined or has not accepted permissions');
    }

  }
///todo finish this
  void sendPushMessage(String token, String body, String title) async{
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
              'body': body,
              'title': title,
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

  void getToken() async{
    await FirebaseMessaging.instance.getToken().then(
        (token){
          setState((){
            mtoken = token;
            print("My token is $mtoken");
          });
          saveToken(token!);
        }
    );
  }

  void saveToken(String token) async{
    await FirebaseFirestore.instance.collection("UserToken").doc(user.phoneNumber).set({
      'token': token,
    });
  }

  initInfo(){
    var androidInitialize = const AndroidInitializationSettings('@mipmap/ic_launcher');
    //var iOSInitialize = const IOSInitializationSettings();
    var initializationSettings = InitializationSettings(android: androidInitialize,);
    flutterLocalNotificationsPlugin.initialize(initializationSettings, //onDidReceiveNotificationResponse:(String? payload) async{
    //   try{
    //     if(payload != null && payload.isNotEmpty){
    //
    //     } else {
    //
    //     }
    //   } catch (e){
    //
    //   }
    //   return;
    // }
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async{
      print("..........onMessage..........");
      print("onMessage: ${message.notification?.title}/${message.notification?.body}}");

      BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
        message.notification!.body.toString(), htmlFormatBigText: true,
        contentTitle: message.notification!.title.toString(), htmlFormatContentTitle: true,
      );
      AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'User', 'User', importance: Importance.high,
        styleInformation: bigTextStyleInformation, priority: Priority.high, playSound: true,

      );
      NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(0, message.notification?.title, message.notification?.body, platformChannelSpecifics,
      payload: message.data['body']);

    });
  }
  ///end of methods for push notifications with firebase and the device specific token

  bool currentVis1 = true;
  bool currentVis2 = false;


  @override
  Widget build(BuildContext context) {
    const double fontSize = 30.0;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return Container(
      // decoration: const BoxDecoration(
      //   image: DecorationImage(
      //       image: AssetImage("images/MainMenu/mainbackground.png"),
      //       fit: BoxFit.cover),
      // ),
      child: Scaffold(
        backgroundColor: Colors.grey[350],
        appBar: AppBar(
          title:
          Text('Signed in from: ${user.phoneNumber!}'),///${user.email!}
          backgroundColor: Colors.black87,
        ),
        //drawer: const NavigationDrawer(),
        body: SingleChildScrollView(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Column(
                  // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  //  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[

                    const SizedBox(height: 30),

                    Image.asset(
                      'images/logo.png',
                      height: 200,
                      width: 200,
                    ), //

                    // ReusableElevatedButton(
                    //   onPress: (){
                    //     Navigator.push(context,
                    //         MaterialPageRoute(builder: (context) => const UsersTableViewPage()));
                    //   },
                    //   buttonText: 'Users Details',fSize: fontSize,
                    // ),

                    const SizedBox(height: 60),
                    Visibility(
                      visible: currentVis1,
                      child: ReusableElevatedButton(
                        onPress: (){
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const UsersTableEditPage()));
                        },
                        buttonText: 'View Details',fSize: fontSize,
                      ),
                    ),

                    //const SizedBox(height: 30),
                    Visibility(
                      visible: currentVis2,
                      child: ReusableElevatedButton(
                        onPress: (){
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const AddUserDetails()));
                        },
                        buttonText: 'Add New Details',fSize: fontSize,
                      ),
                    ),

                    const SizedBox(height: 30),
                    Visibility(
                      visible: currentVis1,
                      child: ReusableElevatedButton(
                        onPress: (){

                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => MapPage()));
                        },
                        buttonText: 'Map Viewer',fSize: fontSize,
                      ),
                    ),

                    //const SizedBox(height: 30),
                    // ReusableElevatedButton(
                    //   onPress: (){
                    //     FirebaseAuth.instance.signOut();
                    //   },
                    //   buttonText: 'Sign Out',fSize: fontSize,
                    // ),

                    const SizedBox(height: 30),
                    Visibility(
                      visible: currentVis1,
                      child: ReusableElevatedButton(
                        onPress: (){

                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => ImageUploads()));
                        },
                        buttonText: 'Upload Image',fSize: fontSize,
                      ),
                    ),

                    const SizedBox(height: 30),
                    Visibility(
                      visible: currentVis1,
                      child: ReusableElevatedButton(
                        onPress: () async {
                          //initSubscription;

                          if(user.phoneNumber! != ""){
                            DocumentSnapshot snap =
                            await FirebaseFirestore.instance.collection("UserToken").doc(user.phoneNumber!).get();

                            String token = snap['token'];
                            print(token);
                          }

                          // sendPushMessage(token, titleText, bodyText);

                          // Navigator.push(context,
                          //     MaterialPageRoute(builder: (context) => MapPage()));
                        },
                        buttonText: 'Notification Center',fSize: fontSize,
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

///Added code for push notifications
// void initSubscription() async {
//   FirebaseMessaging.instance.getToken().then((token) {
//     QB.subscriptions.create(token!, QBPushChannelNames.GCM);
//   });
//
//   try {
//     FirebaseMessaging.onMessage.listen((message) {
//       showNotification(message);
//     });
//   } on PlatformException catch (e) {
//     //some error occurred
//   }
// }
//
// void showNotification(RemoteMessage message) {
//   AndroidNotificationChannel channel = const AndroidNotificationChannel(
//       'channel_id', 'some_title', //'some_description',
//       importance: Importance.high);
//
//   AndroidNotificationDetails details = AndroidNotificationDetails(
//       channel.id, channel.name, //channel.description,
//       icon: 'launch_background');
//
//   FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
//   int id = message.hashCode;
//   String title = "some message title";
//   String body = message.data["message"];
//
//   plugin.show(id, title, body, NotificationDetails(android: details));
// }