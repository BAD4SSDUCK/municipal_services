import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:municipal_services/main.dart';
import 'package:municipal_services/code/Chat/chat_screen.dart';
import 'package:municipal_services/code/DisplayPages/display_info.dart';
import 'package:municipal_services/code/DisplayPages/display_pdf_list.dart';
import 'package:municipal_services/code/DisplayPages/display_info_all_users.dart';
import 'package:municipal_services/code/Reusable/nav_drawer.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';
import 'package:municipal_services/code/Reusable/main_menu_reusable_button.dart';
import 'package:municipal_services/code/Reusable/menu_reusable_elevated_button.dart';
import 'package:municipal_services/code/ImageUploading/image_upload_fault.dart';
import 'package:municipal_services/code/faultPages/fault_report_screen.dart';
import 'package:municipal_services/code/Chat/chat_list.dart';
import 'package:municipal_services/code/MapTools/location_controller.dart';
import 'package:municipal_services/code/MapTools/map_screen.dart';
import 'package:municipal_services/code/NoticePages/notice_user_screen.dart';
import 'package:municipal_services/code/PDFViewer/view_pdf.dart';

final StreamController<String?> selectNotificationStream = StreamController<String?>.broadcast();
const String navigationActionId = 'id_3';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // ignore: avoid_print
  print('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    // ignore: avoid_print
    print('notification action tapped with input: ${notificationResponse.input}');
  }
}

class MainMenu extends StatefulWidget {
  const MainMenu({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() =>_MainMenuState();
  }

  class _MainMenuState extends State<MainMenu>{
  final user = FirebaseAuth.instance.currentUser!;

  final CollectionReference _propList =
  FirebaseFirestore.instance.collection('properties');

  final CollectionReference _tokenList =
  FirebaseFirestore.instance.collection('UserToken');

  ///Methods and implementation for push notifications with firebase and specific device token saving
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  TextEditingController username = TextEditingController();
  TextEditingController title = TextEditingController();
  TextEditingController body = TextEditingController();
  String title2 = "Outstanding Utilities Payment";
  String body2 = "Make sure you pay utilities before the end of this month or your services will be disconnected";
  String? mtoken = " ";

  Timer? timer;

  @override
  void initState() {
    requestPermission();
    getToken();
    initInfo();
    getVersionStream();
    ///checking chat login status
    // getUserLoggedInStatus();
    addChatCustomId();
    timer = Timer.periodic(const Duration(seconds: 5), (Timer t) => getVersionStream());
    super.initState();
  }

  @override
  void dispose(){
    timer?.cancel();
    super.dispose();
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

  void getToken() async{
    await FirebaseMessaging.instance.getToken().then(
        (token){
          setState((){
            mtoken = token;
            print("My token is $mtoken");
          });
          saveToken(token!);
          saveChatPhoneNumber(token!);
        }
    );
  }

  void saveToken(String token) async {
    await FirebaseFirestore.instance.collection("UserToken").doc(user.phoneNumber).set({
      'token': token,
    });

    ///This must loop through the properties and add the users phone token to the property information so that token can be used for notifications
    _propList.get().then((querySnapshot) async {
      for (var result in querySnapshot.docs) {

        print('Property linked to phone number::: ${result['cell number']}');

        if (_tokenList.where(_tokenList.id).toString() == user.phoneNumber || result['cell number'] == user.phoneNumber) {
          await _propList.doc(result.id)
              .update({
            'token': token,
          });
        }
      }
    });
  }

  void saveChatPhoneNumber(String mobile) async{
    await FirebaseFirestore.instance.collection("chatRoom").doc(user.phoneNumber).set({
      'chatRoom': user.phoneNumber,
    });
  }

  initInfo(){
    var androidInitialize = const AndroidInitializationSettings('@mipmap/ic_launcher');
    //var iOSInitialize = const IOSInitializationSettings();
    var initializationSettings = InitializationSettings(android: androidInitialize,);
    flutterLocalNotificationsPlugin.initialize(initializationSettings, onDidReceiveNotificationResponse:(NotificationResponse notificationResponse) {
      switch (notificationResponse.notificationResponseType) {
        case NotificationResponseType.selectedNotification:
          selectNotificationStream.add(notificationResponse.payload);
          break;
        case NotificationResponseType.selectedNotificationAction:
          if (notificationResponse.actionId == navigationActionId) {
            selectNotificationStream.add(notificationResponse.payload);
          }
          break;
      }
    },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
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
  bool visLocked = true;
  bool visFeatureMode = false;
  bool visPremium = false;

  List _allVersionResults = [];

  final CollectionReference _chatRoom =
  FirebaseFirestore.instance.collection('chatRoom');

  addChatCustomId() async{
    String? addChatID = user.phoneNumber;
    final chatSnapshot = FirebaseFirestore.instance
        .collection("chatRoom").doc(addChatID);
    if(chatSnapshot.isBlank!){
    } else {
      _chatRoom.add(addChatID);
    }
  }

  getVersionStream() async{
    var data = await FirebaseFirestore.instance.collection('version').get();
    setState(() {
      _allVersionResults = data.docs;
    });
    getVersionDetails();
  }

  getVersionDetails() async {

    String activeVersion =  _allVersionResults[2]['version'].toString();
    // print('The active version is::: $activeVersion');

    var versionData = await FirebaseFirestore.instance
        .collection('version')
        .doc('current')
        .collection('current-version')
        .where('version', isEqualTo: activeVersion)
        .get();

    // print('The testing group collection::: ${versionData.docs[0].data()['version']}');
    // print('The testing active version::: $versionData');

    String currentVersion = versionData.docs[0].data()['version'];

    for (var versionSnapshot in _allVersionResults) {

      var version = versionSnapshot['version'].toString();

      // print('The available versions are::: $version');

      if (currentVersion == version) {

        if(currentVersion == 'Unpaid'){
          visLocked = true;
          visFeatureMode = true;
          visPremium = true;
        } else if(currentVersion == 'Paid'){
          visLocked = false;
          visFeatureMode = false;
          visPremium = true;
        } else if(currentVersion == 'Premium'){
          visLocked = false;
          visFeatureMode = false;
          visPremium = false;
        }

      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Get.put(LocationController());
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
        backgroundColor: Colors.transparent, //grey[350],
        appBar: AppBar(
          title:
          Text('Signed in from: ${user.phoneNumber!}', style: GoogleFonts.turretRoad(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 19,),
          // TextStyle(color: Colors.white, fontSize: 19),
          ),
          backgroundColor: Colors.black87,
          iconTheme: const IconThemeData(color: Colors.white),
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
                  // Image.asset('assets/images/logo.png', height: 180, width: 180,),
                  Image.asset('assets/images/Coat_of_arms_South_Africa.png', height: 180, width: 180,),
                  // Stack(
                  //     alignment:Alignment.topCenter,
                  //     children:[
                  //       // Image.asset('assets/images/hall2.png', width: double.infinity, height: 180,  fit: BoxFit.cover,  ),
                  //       Padding(
                  //         padding: const EdgeInsets.all(8.0),
                  //         child: ClipRRect(
                  //             borderRadius: BorderRadius.circular(40.0),
                  //             child: Image.asset('assets/images/logo.png', width: 160, height: 160,)
                  //         ),
                  //       ),
                  //     ]
                  // ),
                  // Image.asset('assets/images/municipal_services.png', height: 150, width: 300,),
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
                              Stack(
                                  alignment: Alignment.center,
                                  children: [
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
                                            MaterialPageRoute(builder: (context) => Chat(chatRoomId: id, userName: null,)));
                                      },
                                      labelText: 'Admin \nChat',
                                      fSize: 18,
                                      faIcon: const FaIcon(FontAwesomeIcons.message),
                                      fgColor: Colors.blue,
                                      btSize: const Size(130, 120),
                                    ),
                                    Visibility(
                                      visible: visLocked || visFeatureMode || visPremium,
                                      child: InkWell(
                                          onTap: () {
                                            Fluttertoast.showToast(msg: "Feature Locked\nuntil paid for by Municipality!", gravity: ToastGravity.CENTER);
                                          },
                                          child: ClipRect(
                                              child: Image.asset('assets/images/feature_lock.gif', width: 140, height: 120, fit: BoxFit.cover, color: Colors.black45,)
                                          )
                                      ),
                                    ),
                                  ]
                              ),

                              const SizedBox(width: 40),
                              Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ElevatedIconButton(
                                      onPress: () {
                                        Navigator.push(context,
                                            MaterialPageRoute(builder: (context) => const UsersTableViewPage()));
                                      },
                                      labelText: 'View \nDetails',
                                      fSize: 18,
                                      faIcon: const FaIcon(FontAwesomeIcons.houseCircleExclamation),
                                      fgColor: Colors.green,
                                      btSize: const Size(130, 120),
                                    ),
                                    Visibility(
                                      visible: visLocked || visFeatureMode,
                                      child: InkWell(
                                          onTap: () {
                                            Fluttertoast.showToast(msg: "Feature Locked\nuntil paid for by Municipality!", gravity: ToastGravity.CENTER);
                                          },
                                          child: ClipRect(
                                              child: Image.asset('assets/images/feature_lock.gif', width: 140, height: 120, fit: BoxFit.cover, color: Colors.black45,)
                                          )
                                      ),
                                    ),
                                  ]
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
                              Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ElevatedIconButton(
                                      onPress: () async {
                                        Navigator.push(context,
                                            MaterialPageRoute(builder: (context) => const NoticeScreen()));

                                        ///add page for users to see
                                      },
                                      labelText: 'Notices',
                                      fSize: 16.5,
                                      faIcon: const FaIcon(Icons.notifications_on),
                                      fgColor: Colors.red,
                                      btSize: const Size(130, 120),
                                    ),
                                    Visibility(
                                      visible: visLocked || visFeatureMode || visPremium,
                                      child: InkWell(
                                          onTap: () {
                                            Fluttertoast.showToast(msg: "Feature Locked\nuntil paid for by Municipality!", gravity: ToastGravity.CENTER);
                                          },
                                          child: ClipRect(
                                              child: Image.asset('assets/images/feature_lock.gif', width: 140, height: 120, fit: BoxFit.cover, color: Colors.black45,)
                                          )
                                      ),
                                    ),
                                  ]
                              ),
                              const SizedBox(width: 40,),
                              ElevatedIconButton(
                                onPress: () async {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) => const UsersPdfListViewPage()));
                                },
                                labelText: 'View\nInvoice',
                                fSize: 18,
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
                                onPress: () {
                                  showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
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
                              const SizedBox(width: 40),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  ElevatedIconButton(
                                    onPress: () {
                                      Navigator.push(context,
                                          MaterialPageRoute(builder: (context) => const ReportPropertyMenu()));
                                    },
                                    labelText: 'Report \nFaults',
                                    fSize: 17,
                                    faIcon: const FaIcon(Icons.report_problem),
                                    fgColor: Colors.orangeAccent,
                                    btSize: const Size(130, 120),
                                  ),
                                  Visibility(
                                    visible: visLocked || visFeatureMode || visPremium,
                                    child: InkWell(
                                        onTap: () {
                                          Fluttertoast.showToast(msg: "Feature Locked\nuntil paid for by Municipality!", gravity: ToastGravity.CENTER);
                                        },
                                        child: ClipRect(
                                            child: Image.asset('assets/images/feature_lock.gif', width: 140, height: 120, fit: BoxFit.cover, color: Colors.black45,)
                                        )
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Visibility(
                        visible: visHide,
                        child: ElevatedIconButton(
                          onPress: () {
                            showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
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
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text('Copyright Cyberfox ',
                          //textAlign: TextAlign.end,
                          style: GoogleFonts.saira(
                            color: Colors.white,
                            backgroundColor: Colors.white10,
                            fontWeight: FontWeight.normal,
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
