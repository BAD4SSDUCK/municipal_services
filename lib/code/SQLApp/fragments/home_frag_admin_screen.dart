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
import 'package:municipal_track/code/ImageUploading/image_upload_page.dart';
import 'package:municipal_track/code/PDFViewer/pdf_api.dart';
import 'package:municipal_track/code/Reusable/main_menu_reusable_button.dart';
import 'package:municipal_track/code/Reusable/nav_drawer.dart';
import 'package:municipal_track/code/SQLApp/faultPages/fault_report_screen.dart';
import 'package:municipal_track/code/SQLApp/fragments/profile_fragment_screen.dart';
import 'package:municipal_track/code/SQLApp/fragments/statement_download.dart';
import 'package:municipal_track/main.dart';
import 'package:http/http.dart' as http;

import 'package:municipal_track/code/DisplayPages/add_details.dart';
import 'package:municipal_track/code/DisplayPages/display_info.dart';
import 'package:municipal_track/code/DisplayPages/display_info_all_users.dart';
import 'package:municipal_track/code/Chat/chat_list.dart';
import 'package:municipal_track/code/MapTools/location_controller.dart';
import 'package:municipal_track/code/MapTools/map_screen.dart';
import 'package:municipal_track/code/PDFViewer/view_pdf.dart';
import 'package:municipal_track/code/Reusable/menu_reusable_elevated_button.dart';
import 'package:municipal_track/code/ApiConnection/api_connection.dart';

import 'package:municipal_track/code/Reusable/icon_elevated_button.dart';
import 'dashboard_of_fragments_sql.dart';


class HomeAdminScreen extends StatefulWidget {
  const HomeAdminScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() =>_HomeAdminScreenState();
}

class _HomeAdminScreenState extends State<HomeAdminScreen>{

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

  final CollectionReference _propList =
  FirebaseFirestore.instance.collection('properties');

  final CollectionReference _userList =
  FirebaseFirestore.instance.collection('users');


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
          title:
          Text(''),
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
                                    // Navigator.push(context,
                                    //     MaterialPageRoute(builder: (context) => const pdfSelectionPage()));

                                  },
                                  labelText: 'Maps',
                                  fSize: 24,
                                  faIcon: const FaIcon(FontAwesomeIcons.map),
                                  fgColor: Colors.green,
                                  btSize: const Size(300, 80),
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

                                    // Navigator.push(context,
                                    //     MaterialPageRoute(builder: (context) => ReportPropertyMenu()));

                                  },
                                  labelText: 'Report List',
                                  fSize: 24,
                                  faIcon: const FaIcon(Icons.report_problem),
                                  fgColor: Colors.orange,
                                  btSize: const Size(300, 80),
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
                                    ProfileFragmentScreen().signOutUser();

                                  },
                                  labelText: 'Logout',
                                  fSize: 24,
                                  faIcon: const FaIcon(Icons.logout),
                                  fgColor: Colors.red,
                                  btSize: const Size(300, 80),
                                ),
                              ],
                            ),
                          ),
                        ),

                      ],
                    ),


                    ///Old Buttons
                    // ///Display information for all users properties information for admins to see
                    // Visibility(
                    //     visible: visInternal,
                    //     child: const SizedBox(height: 20)),
                    // Visibility(
                    //   visible: visInternal,
                    //   child: ReusableElevatedButton(
                    //     onPress: (){
                    //       Navigator.push(context,
                    //           MaterialPageRoute(builder: (context) => const UsersTableAllViewPage()));
                    //     },
                    //     buttonText: 'All Users Details',fSize: fontSize,
                    //   ),
                    // ),
                    //
                    // Visibility(
                    //     visible: visInternal,
                    //     child: const SizedBox(height: 20)),
                    // Visibility(
                    //   visible: visInternal,
                    //   child: ReusableElevatedButton(
                    //     onPress: (){
                    //
                    //       Navigator.push(context,
                    //           MaterialPageRoute(builder: (context) => const MapScreen()));
                    //       //MapPage()
                    //     },
                    //     buttonText: 'Map Viewer',fSize: fontSize,
                    //   ),
                    // ),
                    //
                    //
                    // ///button for admin to get all chats from the DB
                    // Visibility(
                    //     visible: visInternal,//visInternal,
                    //     child: const SizedBox(height: 20)),
                    // Visibility(
                    //   visible: visInternal,//visInternal,
                    //   child: ReusableElevatedButton(
                    //     onPress: () async {
                    //
                    //       Navigator.push(context,
                    //           MaterialPageRoute(builder: (context) => ChatList()));
                    //
                    //     },
                    //     buttonText: 'Message User List',fSize: fontSize,
                    //   ),
                    // ),
                    //
                    // ///Direct statement download feature needs to be for the user account only
                    // Visibility(
                    //     visible: visExternal,
                    //     child: const SizedBox(height: 20)),
                    // Visibility(
                    //   visible: visExternal,
                    //   child: ReusableElevatedButton(
                    //     onPress: () async {
                    //       Fluttertoast.showToast(msg: "Now downloading your statement!\nPlease wait a few seconds!");
                    //
                    //       final FirebaseAuth auth = FirebaseAuth.instance;
                    //       final User? user = auth.currentUser;
                    //       final uid = user?.uid;
                    //       String userID = uid as String;
                    //
                    //       ///code for loading the pdf is using dart:io I am setting it to use the userID to separate documents
                    //       ///no pdfs are uploaded by users
                    //       print(FirebaseAuth.instance.currentUser);
                    //       final url = 'pdfs/$userID/ds_wirelessp2p.pdf';
                    //       final url2 = 'pdfs/$userID/Invoice_000003728743_040000653226.PDF';
                    //       final file = await PDFApi.loadFirebase(url);
                    //       try{
                    //         openPDF(context, file);
                    //       } catch(e){
                    //         Fluttertoast.showToast(msg: "Unable to download statement.");
                    //       }
                    //     },
                    //     buttonText: 'Download Statement',fSize: fontSize,
                    //   ),
                    // ),
                    //
                    // Visibility(
                    //     visible: visExternal,
                    //     child: const SizedBox(height: 20)),
                    // Visibility(
                    //   visible: visExternal,
                    //   child: ReusableElevatedButton(
                    //     onPress: (){
                    //       showDialog(
                    //           barrierDismissible: false,
                    //           context: context,
                    //           builder: (context) {
                    //             return AlertDialog(
                    //               shape: const RoundedRectangleBorder(borderRadius:
                    //               BorderRadius.all(Radius.circular(16))),
                    //               title: const Text("Logout"),
                    //               content: const Text("Are you sure you want to logout?"),
                    //               actions: [
                    //                 IconButton(
                    //                   onPressed: () {
                    //                     Navigator.pop(context);
                    //                   },
                    //                   icon: const Icon(
                    //                     Icons.cancel,
                    //                     color: Colors.red,
                    //                   ),
                    //                 ),
                    //                 IconButton(
                    //                   onPressed: () async {
                    //                     ProfileFragmentScreen().signOutUser();
                    //                     FirebaseAuth.instance.signOut();
                    //                     SystemNavigator.pop();
                    //                   },
                    //                   icon: const Icon(
                    //                     Icons.done,
                    //                     color: Colors.green,
                    //                   ),
                    //                 ),
                    //               ],
                    //             );
                    //           });
                    //     },
                    //     buttonText: 'Logout',fSize: fontSize,
                    //   ),
                    // ),

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

  ///pdf view loader getting file name onPress/onTap that passes filename to this class
  void openPDF(BuildContext context, File file) => Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
  );

}