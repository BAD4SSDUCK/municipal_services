import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:municipal_track/code/Chat/chat_screen.dart';
import 'package:municipal_track/code/DisplayPages/display_pdf_list.dart';
import 'package:municipal_track/code/ImageUploading/image_upload_prop_fault.dart';
import 'package:municipal_track/code/PDFViewer/pdf_api.dart';
import 'package:municipal_track/code/Reusable/main_menu_reusable_button.dart';
import 'package:municipal_track/code/Reusable/nav_drawer.dart';
import 'package:municipal_track/code/faultPages/fault_report_screen.dart';
import 'package:municipal_track/main.dart';
import 'package:http/http.dart' as http;

import 'package:municipal_track/code/Chat/chat_list.dart';
import 'package:municipal_track/code/MapTools/location_controller.dart';
import 'package:municipal_track/code/MapTools/map_screen.dart';
import 'package:municipal_track/code/PDFViewer/view_pdf.dart';
import 'package:municipal_track/code/Reusable/icon_elevated_button.dart';
import 'package:municipal_track/code/Reusable/menu_reusable_elevated_button.dart';
import 'package:path/path.dart';
import 'add_details.dart';
import 'display_info.dart';
import 'display_info_all_users.dart';


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
    ///checking chat login status
    // getUserLoggedInStatus();
    addChatCustomId();
  }

  ///added login status for chat
  bool _isSignedIn = false;


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

  void saveChatPhoneNumber(String mobile) async{
    await FirebaseFirestore.instance.collection("chatRoom").doc(user.phoneNumber).set({
      'chatRoom': mobile,
    });
  }

  initInfo(){
    var androidInitialize = const AndroidInitializationSettings('@mipmap/ic_launcher');
    //var iOSInitialize = const IOSInitializationSettings();
    var initializationSettings = InitializationSettings(android: androidInitialize,);
    flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification:(String? payload) async {
      try {
        if (payload != null && payload.isNotEmpty) {
          Navigator.push(
              context as BuildContext, MaterialPageRoute(builder: (BuildContext context) {
            return const UsersTableViewPage();
          }
          ));
        } else {

        }
      } catch (e) {
        print(e);
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

  bool visShow = true;
  bool visHide = false;

  final CollectionReference _chatRoom =
  FirebaseFirestore.instance.collection('chatRoom');

  addChatCustomId() async{
    String? addChatID = user.phoneNumber;
    final chatSnapshot = await FirebaseFirestore.instance
        .collection("chatRoom").doc(addChatID);
    if(chatSnapshot.isBlank!){
    } else {
      _chatRoom.add(addChatID);
    }
  }

  @override
  Widget build(BuildContext context) {
    Get.put(LocationController());
    const double fontSize = 28.0;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return Container(
      ///When a background image is created this section will display it on the dashboard instead of just a grey colour with no background
      decoration: const BoxDecoration(
        image: DecorationImage(
            image: AssetImage("assets/images/greyscale.jpg"),
            fit: BoxFit.cover),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,//grey[350],
        appBar: AppBar(
          title:
          Text('Signed in from: ${user.phoneNumber!}'),///${user.email!}
          backgroundColor: Colors.black87,
        ),
        drawer: const NavDrawer(),
        body: SingleChildScrollView(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Column(
                // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //  crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[

                  const SizedBox(height: 30),
                  Image.asset('assets/images/logo.png', height: 180, width: 180,),
                  const SizedBox(height: 20),

                  ///For Icon buttons
                  Column(
                    children: [
                      Visibility(
                        visible: visShow,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ElevatedIconButton(
                              onPress: (){
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) => const UsersTableViewPage()));
                              },
                              labelText: 'View\nDetails',
                              fSize: 18,
                              faIcon: const FaIcon(FontAwesomeIcons.houseCircleExclamation),
                              fgColor: Colors.green,
                              btSize: const Size(130, 120),
                            ),
                            const SizedBox(width: 40),
                            ElevatedIconButton(
                              onPress: () {
                                String passedID = user.phoneNumber!;
                                String? userName = FirebaseAuth.instance.currentUser!.phoneNumber;
                                print('The user name of the logged in person is $userName}');
                                String id = passedID;

                                saveChatPhoneNumber(id);

                                ///Directly to the chatapp page that creates a chat id that will be saved on the DB. for an admin to access the chat I will have to
                                ///make a new page that lists all DB chats for the admin to select and connect to for responding to users
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) =>
                                        Chat(chatRoomId: id,)));
                              },
                              labelText: 'Admin\nChat',
                              fSize: 18,
                              faIcon: const FaIcon(FontAwesomeIcons.message),
                              fgColor: Colors.blue,
                              btSize: const Size(130, 120),
                            ),
                          ],
                          ),
                        ),
                      ),
                      Visibility(
                        visible: visShow,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ElevatedIconButton(
                                onPress: () async {
                                  //Fluttertoast.showToast(msg: "Now downloading a list of your statements!\nDownload speed dependent on network connection.", gravity: ToastGravity.CENTER);

                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) => UsersPdfListViewPage()));

                                  ///code for loading the pdf is using dart:io I am setting it to use the userID to separate documents
                                  ///no pdfs are uploaded by users
                                  ///todo get the document name by account number
                                  // print(FirebaseAuth.instance.currentUser);
                                  //
                                  // final url = 'pdfs/$userID/ds_wirelessp2p.pdf';
                                  // final url2 = 'pdfs/$userID/Invoice_000003728743_040000653226.PDF';
                                  // final file = await PDFApi.loadFirebase(url2);
                                  // try{
                                  //   openPDF(context, file);
                                  // } catch(e){
                                  //   Fluttertoast.showToast(msg: "Unable to download statement.", gravity: ToastGravity.CENTER);
                                  // }
                                },
                                labelText: 'View\nStatement',
                                fSize: 16,
                                faIcon: const FaIcon(FontAwesomeIcons.solidFilePdf),
                                fgColor: Colors.redAccent,
                                btSize: const Size(130, 120),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Visibility(
                        visible: visShow,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ElevatedIconButton(
                                onPress: (){
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) => ReportPropertyMenu()));
                                },
                                labelText: 'Report\nFaults',
                                fSize: 18,
                                faIcon: const FaIcon(Icons.report_problem),
                                fgColor: Colors.orangeAccent,
                                btSize: const Size(130, 120),
                              ),
                              const SizedBox(width: 40),
                              ElevatedIconButton(
                                onPress: (){
                                  showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          shape: const RoundedRectangleBorder(borderRadius:
                                          BorderRadius.all(Radius.circular(18))),
                                          title: const Text("Logout"),
                                          content: const Text("Are you sure you want to logout?"),
                                          actions: [
                                            IconButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              icon: const Icon(
                                                Icons.cancel,
                                                color: Colors.red,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () async {
                                                FirebaseAuth.instance.signOut();
                                                Navigator.pop(context);

                                                ///SystemNavigator.pop() closes the entire app
                                                // SystemNavigator.pop();
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
                                labelText: 'Logout',
                                fSize: 18,
                                faIcon: const FaIcon(Icons.logout),
                                fgColor: Colors.red,
                                btSize: const Size(130, 120),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),


                  ///this onPress code bellow is used to set the message information and pop it up to the user in their notifications.
                  ///button not needed as it will only be used when a new chat is sent or when an admin sends to a specific phone which will be a list of tokens per device
                  // Visibility(
                  //     visible: false,
                  //     child: const SizedBox(height: 20)),
                  // Visibility(
                  //   visible: false,
                  //   child: ReusableElevatedButton(
                  //     onPress: () async {
                  //
                  //       ///It can be changed to the firebase notification
                  //       String titleText = title.text;
                  //       String bodyText = body.text;
                  //
                  //       ///gets users phone token to send notification to this phone
                  //       if(user.phoneNumber! != ""){
                  //         DocumentSnapshot snap =
                  //         await FirebaseFirestore.instance.collection("UserToken").doc(user.phoneNumber!).get();
                  //
                  //         String token = snap['token'];
                  //
                  //         sendPushMessage(token, titleText, bodyText);
                  //       }
                  //     },
                  //     buttonText: 'Notification Checker',fSize: fontSize,
                  //   ),
                  // ),

                  const SizedBox(height: 30),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                      children: const <Widget>[
                        Text('Copyright Cyberfox ',
                          //textAlign: TextAlign.end,
                          style: TextStyle(
                            color: Colors.white,
                            backgroundColor: Colors.white10,
                            fontStyle: FontStyle.italic,
                            fontSize: 16,
                          ),
                        ),
                      ]
                  ),
                  const SizedBox(height: 20),
                ],
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