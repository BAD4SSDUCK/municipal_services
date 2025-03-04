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
import 'package:municipal_services/code/Chat/chat_screen.dart';
import 'package:municipal_services/code/MapTools/map_screen_multi.dart';
import 'package:municipal_services/code/PDFViewer/pdf_api.dart';
import 'package:municipal_services/code/Reusable/main_menu_reusable_button.dart';
import 'package:municipal_services/code/Reusable/nav_drawer.dart';
import 'package:municipal_services/code/SQLApp/faultSQLPages/fault_manage_screen.dart';
import 'package:municipal_services/code/SQLApp/faultSQLPages/fault_report_screen.dart';
import 'package:municipal_services/code/SQLApp/fragments/admin_management_screen.dart';
import 'package:municipal_services/code/SQLApp/fragments/profile_fragment_screen.dart';
import 'package:municipal_services/code/SQLApp/fragments/property_fragment_screen_all.dart';
import 'package:municipal_services/code/SQLApp/fragments/statement_download.dart';
import 'package:municipal_services/main.dart';
import 'package:http/http.dart' as http;

import 'package:municipal_services/code/DisplayPages/add_details.dart';
import 'package:municipal_services/code/DisplayPages/display_info.dart';
import 'package:municipal_services/code/DisplayPages/display_info_all_users.dart';
import 'package:municipal_services/code/Chat/chat_list.dart';
import 'package:municipal_services/code/MapTools/location_controller.dart';
import 'package:municipal_services/code/MapTools/map_screen.dart';
import 'package:municipal_services/code/PDFViewer/view_pdf.dart';
import 'package:municipal_services/code/Reusable/menu_reusable_elevated_button.dart';
import 'package:municipal_services/code/ApiConnection/api_connection.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';
import 'dashboard_of_fragments_sql.dart';


class HomeManagerScreen extends StatefulWidget {
  const HomeManagerScreen({super.key,});

  @override
  State<StatefulWidget> createState() =>_HomeManagerScreenState();
}

class _HomeManagerScreenState extends State<HomeManagerScreen>{

  bool loading = true;
  late List pdfList;
  bool hasUnreadMessages = false;
  Future fetchAllPdf() async{
    final response = await http.get(Uri.parse(API.pdfDBList));
    if (response.statusCode==200){
      setState((){
        pdfList = jsonDecode(response.body);
        loading = false;
      });
    }
  }

  late FToast fToast;

  @override
  void initState() {
    super.initState();
    fetchAllPdf();
    fToast =FToast();
    fToast.init(context);
    //Fluttertoast.showToast(msg: "Navigate The App From The Bottom Tabs.", gravity: ToastGravity.CENTER);

  }

  bool visShow = true;
  bool visHide = false;


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
        ///App bar removed for aesthetic
        appBar: AppBar(
          title: Text(''),
          backgroundColor: Colors.black87,
        ),
        drawer:  NavDrawer(),
        body: SingleChildScrollView(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 20),
                    Image.asset('assets/images/logo.png', height: 180, width: 180),
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
                                        MaterialPageRoute(builder: (context) => MapScreenMulti()));
                                  },
                                  labelText: 'Maps',
                                  fSize: 18,
                                  faIcon: const FaIcon(FontAwesomeIcons.map),
                                  fgColor: Colors.purple,
                                  btSize: const Size(130, 120),
                                ),
                                const SizedBox(width: 20),
                                ElevatedIconButton(
                                  onPress: () async {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context) => FaultManageScreen()));
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
                        const SizedBox(height: 5),
                        Visibility(
                          visible: visShow,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Stack(
                                  children: [
                                    ElevatedIconButton(
                                      onPress: () async {
                                        Navigator.push(context,
                                            MaterialPageRoute(builder: (context) => ChatList()));
                                      },
                                      labelText: 'Chat\nList',
                                      fSize: 18,
                                      faIcon: const FaIcon(Icons.mark_chat_unread),
                                      fgColor: Colors.green,
                                      btSize: const Size(130, 120),
                                    ),
                                    if (hasUnreadMessages) // Show badge if there are unread messages
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: const Text(
                                            '!',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                ElevatedIconButton(
                                  onPress: () async {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context) => AdminManagementScreen()));
                                  },
                                  labelText: 'Manage\nAdmin',
                                  fSize: 18,
                                  faIcon: const FaIcon(Icons.people),
                                  fgColor: Colors.blue,
                                  btSize: const Size(130, 120),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Visibility(
                          visible: visShow,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ElevatedIconButton(
                                  onPress: () {
                                    // ProfileFragmentScreen().signOutUser();
                                  },
                                  labelText: 'Logout',
                                  fSize: 18,
                                  faIcon: const FaIcon(Icons.logout),
                                  fgColor: Colors.red,
                                  btSize: const Size(130, 120),
                                ),
                                const SizedBox(width: 20),
                                ElevatedIconButton(
                                  onPress: () async {
                                    // Navigator.push(context,
                                    // MaterialPageRoute(builder: (context) => PropertyFragmentScreenAll()));
                                  },
                                  labelText: 'Reading\nCapture',
                                  fSize: 16,
                                  faIcon: const FaIcon(Icons.holiday_village),
                                  fgColor: Colors.brown,
                                  btSize: const Size(130, 120),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Copyright Cyberfox ',
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

  void openPDF(BuildContext context, File file) => Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
  );
}