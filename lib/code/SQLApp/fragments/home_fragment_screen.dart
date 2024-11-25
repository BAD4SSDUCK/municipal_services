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
import 'package:municipal_services/code/PDFViewer/pdf_api.dart';
import 'package:municipal_services/code/Reusable/main_menu_reusable_button.dart';
import 'package:municipal_services/code/Reusable/nav_drawer.dart';
import 'package:municipal_services/code/SQLApp/faultSQLPages/fault_report_screen.dart';
import 'package:municipal_services/code/SQLApp/fragments/profile_fragment_screen.dart';
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


class HomeFragmentScreen extends StatefulWidget {
  final String districtId;
  final String municipalityId;
  const HomeFragmentScreen({super.key, required this.districtId, required this.municipalityId});

  @override
  State<StatefulWidget> createState() =>_HomeFragmentScreenState();
}

class _HomeFragmentScreenState extends State<HomeFragmentScreen>{

  bool loading = true;
  late List pdfList;
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
    Fluttertoast.showToast(msg: "Navigate The App From The Bottom Tabs.", gravity: ToastGravity.CENTER);

  }

  bool visShow = true;
  bool visHide = false;
  bool hasUnreadCouncilMessages=false;
  final CollectionReference _propList =
  FirebaseFirestore.instance.collection('properties');

  final CollectionReference _userList =
  FirebaseFirestore.instance.collection('users');

  Future<bool> determineIfCouncillor(String userPhone) async {
    try {
      // Replace with your logic to check if the user is a councillor
      QuerySnapshot councillorCheck = await FirebaseFirestore.instance
          .collectionGroup('councillors')
          .where('councillorPhone', isEqualTo: userPhone)
          .limit(1)
          .get();
      return councillorCheck.docs.isNotEmpty;
    } catch (e) {
      print("Error checking councillor status: $e");
      return false;
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
    User? currentUser = FirebaseAuth.instance.currentUser;
    String userPhone = currentUser?.phoneNumber ?? '';
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
          title:
          Text(''),
          backgroundColor: Colors.black87,
        ),
        drawer: FutureBuilder<bool>(
          future: determineIfCouncillor(userPhone),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              bool isCouncillor = snapshot.data ?? false;
              return NavDrawer(
                userPhone: userPhone,
                isCouncillor: isCouncillor,
              );
            }
            return const SizedBox.shrink(); // Show nothing until the status is known
          },
        ),
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

                    const SizedBox(height: 50),
                    Image.asset('assets/images/logo.png', height: 180, width: 180,),
                    const SizedBox(height: 50),

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
                                    Fluttertoast.showToast(msg: "Now downloading your statements!\nPlease wait a few seconds!",
                                      gravity: ToastGravity.CENTER,);

                                    ///SQL pdf list that shows the users statements if it contains their account number
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context) => const pdfSelectionPage()));

                                  },
                                  labelText: 'Download Statement',
                                  fSize: 22,
                                  faIcon: const FaIcon(FontAwesomeIcons.solidFilePdf),
                                  fgColor: Colors.redAccent,
                                  btSize: const Size(280, 60),
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
                                    // Fluttertoast.showToast(msg: "Now downloading your statements!\nPlease wait a few seconds!",
                                    //   gravity: ToastGravity.CENTER,);

                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context) => ReportPropertyMenu()));

                                  },
                                  labelText: 'Report Fault',
                                  fSize: 22,
                                  faIcon: const FaIcon(Icons.report_problem),
                                  fgColor: Colors.orange,
                                  btSize: const Size(280, 60),
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
                                    // ProfileFragmentScreen().signOutUser();
                                  },
                                  labelText: 'Logout',
                                  fSize: 22,
                                  faIcon: const FaIcon(Icons.logout),
                                  fgColor: Colors.red,
                                  btSize: const Size(280, 60),
                                ),
                              ],
                            ),
                          ),
                        ),

                      ],
                    ),

                    const SizedBox(height: 50),
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
}
