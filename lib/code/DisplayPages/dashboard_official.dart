import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:municipal_tracker_msunduzi/code/DisplayPages/admin_details.dart';
import 'package:municipal_tracker_msunduzi/code/DisplayPages/display_info_all_users.dart';
import 'package:municipal_tracker_msunduzi/code/DisplayPages/configuration_page.dart';
import 'package:municipal_tracker_msunduzi/code/NoticePages/notice_config_screen.dart';
import 'package:municipal_tracker_msunduzi/code/MapTools/map_screen_multi.dart';
import 'package:municipal_tracker_msunduzi/code/MapTools/map_screen.dart';
import 'package:municipal_tracker_msunduzi/code/MapTools/location_controller.dart';
import 'package:municipal_tracker_msunduzi/code/PDFViewer/view_pdf.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/menu_reusable_elevated_button.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/icon_elevated_button.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/nav_drawer.dart';
import 'package:municipal_tracker_msunduzi/code/faultPages/fault_task_screen.dart';
import 'package:municipal_tracker_msunduzi/code/faultPages/fault_report_screen.dart';
import 'package:municipal_tracker_msunduzi/code/Chat/chat_list.dart';
import 'package:municipal_tracker_msunduzi/code/main_page.dart';

class HomeManagerScreen extends StatefulWidget {
  const HomeManagerScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() =>_HomeManagerScreenState();
}

class _HomeManagerScreenState extends State<HomeManagerScreen>{

  bool loading = true;
  late FToast fToast;

  @override
  void initState() {
    super.initState();
    fToast =FToast();
    fToast.init(context);
    visibilityCheckAdmin();
    //Fluttertoast.showToast(msg: "Navigate The App From The Bottom Tabs.", gravity: ToastGravity.CENTER);

  }

  bool visShow = true;
  bool visHide = false;
  bool visAdmin = false;

  void visibilityCheckAdmin() {
    User? user = FirebaseAuth.instance.currentUser;
    String? emailLogged = user?.email.toString();

    if(emailLogged?.contains("admin") == true){
      visAdmin = true;
    } else {
      visAdmin = false;
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
        backgroundColor: Colors.transparent,//Colors.grey,
        ///App bar text removed for aesthetic
        appBar: AppBar(
          title: const Text(''),
          backgroundColor: Colors.black87,
        ),
        drawer: const NavDrawer(),
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
                    const SizedBox(height: 20),
                    Image.asset('assets/images/logo.png', height: 180, width: 180,),
                    // Image.asset('assets/images/municipal_services.png', height: 150, width: 300,),
                    const SizedBox(height: 20),
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
                                  onPress: () async {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context) => const MapScreenMulti()));
                                  },
                                  labelText: 'Map',
                                  fSize: 18,
                                  faIcon: const FaIcon(FontAwesomeIcons.map),
                                  fgColor: Colors.purple,
                                  btSize: const Size(130, 120),
                                ),
                                const SizedBox(width: 40,),
                                ElevatedIconButton(
                                  onPress: () async {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context) => const FaultTaskScreen()));
                                  },
                                  labelText: 'Report\nList',
                                  fSize: 18,
                                  faIcon: const FaIcon(Icons.report_problem),
                                  fgColor: Colors.orange,
                                  btSize: const Size(130, 120),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 5,),
                        Visibility(
                          visible: visShow,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ElevatedIconButton(
                                  onPress: () async {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context) => const ChatList()));
                                  },
                                  labelText: 'Chat\nList',
                                  fSize: 18,
                                  faIcon: const FaIcon(Icons.mark_chat_unread),
                                  fgColor: Colors.green,
                                  btSize: const Size(130, 120),
                                ),
                                const SizedBox(width: 40,),
                                Visibility(
                                  visible: visAdmin,
                                  child: ElevatedIconButton(
                                    onPress: () async {
                                      Navigator.push(context,
                                          MaterialPageRoute(builder: (context) => const ConfigPage()));
                                    },
                                    labelText: 'Admin\nConfig',
                                    fSize: 18,
                                    faIcon: const FaIcon(Icons.people),
                                    fgColor: Colors.blue,
                                    btSize: const Size(130, 120),
                                  ),
                                ),

                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 5,),
                        Visibility(
                          visible: visShow,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ElevatedIconButton(
                                  onPress: () async {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context) => const NoticeConfigScreen()));
                                  },
                                  labelText: 'User\nNotifier',
                                  fSize: 18,
                                  faIcon: const FaIcon(Icons.notifications_on),
                                  fgColor: Colors.red,
                                  btSize: const Size(130, 120),
                                ),
                                const SizedBox(width: 40,),
                                ElevatedIconButton(
                                  onPress: () async {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context) => const UsersPropsAll()));
                                  },
                                  labelText: 'Readings\nCapture',
                                  fSize: 16,
                                  faIcon: const FaIcon(Icons.holiday_village),
                                  fgColor: Colors.black54,
                                  btSize: const Size(130, 120),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 5,),
                        Visibility(
                          visible: visShow,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
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

                                                  // Navigator.popAndPushNamed(context, const MainPage() as String);
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

                                    ///commented out old sql sign out method
                                    // ProfileFragmentScreen().signOutUser();
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
                    const SizedBox(height: 20),
                    const Text('Copyright Cyberfox ',
                      style: TextStyle(
                        color: Colors.white,
                        backgroundColor: Colors.white10,
                        fontStyle: FontStyle.italic,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
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
