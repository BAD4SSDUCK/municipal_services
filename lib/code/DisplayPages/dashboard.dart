import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:municipal_track/code/ImageUploading/image_upload_page.dart';
import 'package:municipal_track/code/PDFViewer/pdf_api.dart';
import 'package:municipal_track/code/Reuseables/main_menu_reusable_button.dart';
import 'package:municipal_track/code/Reuseables/nav_drawer.dart';
import 'package:municipal_track/main.dart';
import 'package:http/http.dart' as http;

import '../MapTools/location_controller.dart';
import '../MapTools/map_screen.dart';
import '../PDFViewer/view_pdf.dart';
import '../MapTools/map_component.dart';
import '../Reuseables/menu_reusable_elevated_button.dart';
import 'add_details.dart';
import 'display_info.dart';
import 'display_info_edit.dart';


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
  String title2 = "Outstanding Utilities Payment";
  String body2 = "Make sure you pay utilities before the end of this month or your services will be disconnected";
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
              "title": title2,
              "body": body2,
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
    flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification:(String? payload) async{
      try{
        if(payload != null && payload.isNotEmpty){
          Navigator.push(context, MaterialPageRoute(builder: (BuildContext context){
            return const UsersTableEditPage();
          }
          ));

        } else {

        }
      } catch (e){

      }
      return;
    }
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

  final CollectionReference _userList =
  FirebaseFirestore.instance.collection('users');


  @override
  Widget build(BuildContext context) {
    Get.put(LocationController());
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
                    Image.asset('assets/images/logo.png', height: 200, width: 200,),

                    //const SizedBox(height: 30),
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

                    ///Add new details will not be available to anyone as it will all be details pulled from the server when SQL is implemented
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
                              MaterialPageRoute(builder: (context) => const MapScreen()));
                          //MapPage()
                        },
                        buttonText: 'Map Viewer',fSize: fontSize,
                      ),
                    ),

                    const SizedBox(height: 30),
                    Visibility(
                      visible: currentVis1,
                      child: ReusableElevatedButton(
                        onPress: (){
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('Uploading a new image will replace existing image if this is not your first upload!'),
                            ),
                          );
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
                          ///this onPress code bellow is used to set the message information and pop it up to the user,
                          ///It can be changed to the firebase notification
                          String titleText = title.text;
                          String bodyText = body.text;

                          ///gets users phone token to send notification to this phone
                          if(user.phoneNumber! != ""){
                            DocumentSnapshot snap =
                            await FirebaseFirestore.instance.collection("UserToken").doc(user.phoneNumber!).get();

                            String token = snap['token'];
                            print(token);

                            sendPushMessage(token, titleText, bodyText);
                          }
                        },
                        buttonText: 'Notification Checker',fSize: fontSize,
                      ),
                    ),

                    //const SizedBox(height: 30),
                    Visibility(
                      visible: currentVis2,
                      child: ReusableElevatedButton(
                        onPress: () async {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('Now downloading your statement! Pease wait a few seconds!'),
                            ),
                          );

                          final FirebaseAuth auth = FirebaseAuth.instance;
                          final User? user = auth.currentUser;
                          final uid = user?.uid;
                          String userID = uid as String;

                          ///code for loading the pdf is using dart:io I am setting it to use the userID to separate documents
                          ///no pdfs are uploaded by users
                          print(FirebaseAuth.instance.currentUser);
                          final url = 'pdfs/$userID/Advert.pdf';
                          final file = await PDFApi.loadFirebase(url);
                          openPDF(context, file);
                        },
                        buttonText: 'Document download',fSize: fontSize,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Visibility(
                      visible: currentVis1,
                      child: ReusableElevatedButton(
                        onPress: (){
                          FirebaseAuth.instance.signOut();
                        },
                        buttonText: 'Sign Out',fSize: fontSize,
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

  ///pdf view loader getting file name onPress/onTap that passes filename to this class
  void openPDF(BuildContext context, File file) => Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
  );

}