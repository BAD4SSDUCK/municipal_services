import 'dart:io';
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
// import 'dart:html' as html
//     if(dart.library.html)'dart:html';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:municipal_services/code/DisplayPages/admin_details.dart';
import 'package:municipal_services/code/DisplayPages/configuration_dev_page.dart';
import 'package:municipal_services/code/DisplayPages/display_all_capture.dart';
import 'package:municipal_services/code/DisplayPages/display_all_meters.dart';
import 'package:municipal_services/code/DisplayPages/display_connections_all_users.dart';
import 'package:municipal_services/code/DisplayPages/display_info_all_users.dart';
import 'package:municipal_services/code/DisplayPages/configuration_page.dart';
import 'package:municipal_services/code/MapTools/map_screen.dart';
import 'package:municipal_services/code/MapTools/map_screen_multi.dart';
import 'package:municipal_services/code/MapTools/location_controller.dart';
import 'package:municipal_services/code/Reusable/municipal_nav_drawer.dart';
import 'package:municipal_services/code/Reusable/nav_drawer.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';
import 'package:municipal_services/code/Reusable/menu_reusable_elevated_button.dart';
import 'package:municipal_services/code/faultPages/fault_task_screen.dart';
import 'package:municipal_services/code/faultPages/fault_report_screen.dart';
import 'package:municipal_services/code/faultPages/fault_attendant_screen.dart';
import 'package:municipal_services/code/NoticePages/notice_config_screen.dart';
import 'package:municipal_services/code/PDFViewer/view_pdf.dart';
import 'package:municipal_services/code/Chat/chat_list.dart';
import 'package:municipal_services/code/main_page.dart';
import 'package:provider/provider.dart';
import '../Models/notify_provider.dart';
import '../Models/property.dart';
//Menu for municipality users
// class HomeManagerScreen extends StatefulWidget {
//   const HomeManagerScreen({super.key});
//
//   @override
//   State<StatefulWidget> createState() =>_HomeManagerScreenState();
// }
//
// final FirebaseAuth auth = FirebaseAuth.instance;
//
// final User? user = auth.currentUser;
// final uid = user?.uid;
// final email = user?.email;
// String userID = uid as String;
// String userEmail = email as String;
//
// class _HomeManagerScreenState extends State<HomeManagerScreen>{
//   String? userEmail;
//   String? districtId;
//   String? municipalityId;
//   bool isLoading = true;
//   late FToast fToast;
//   Timer? timer;
//   //late Property currentProperty;
//   @override
//   void initState() {
//
//     fToast =FToast();
//     fToast.init(context);
//    // adminCheck();
//     // timer = Timer.periodic(const Duration(seconds: 5), (Timer t) => adminCheck());
//     // getVersionStream();
//     // timer = Timer.periodic(const Duration(seconds: 5), (Timer t) => getVersionStream());
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     fetchUserDetails();
//     fToast =FToast();
//     fToast.init(context);
//     // userRole;
//     // visShow;
//     // visHide;
//     // visAdmin;
//     // visManager;
//     // visEmployee;
//     timer?.cancel();
//     super.dispose();
//   }
//   Future<void> fetchUserDetails() async {
//     try {
//       User? user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         userEmail = user.email;
//
//         // Use collectionGroup to search across all 'users' subcollections
//         QuerySnapshot userSnapshot = await FirebaseFirestore.instance
//             .collectionGroup('users')
//             .where('email', isEqualTo: userEmail)
//             .limit(1)
//             .get();
//
//         if (userSnapshot.docs.isNotEmpty) {
//           var userDoc = userSnapshot.docs.first;
//
//           // Extract districtId and municipalityId from the document reference path
//           var districtId = userDoc.reference.parent.parent?.parent?.id;
//           var municipalityId = userDoc.reference.parent.parent?.id;
//
//           if (districtId != null && municipalityId != null) {
//             setState(() {
//               this.districtId = districtId;
//               this.municipalityId = municipalityId;
//               isLoading = false;
//             });
//           }
//         } else {
//           // Handle the case where the user document is not found
//           print('User document not found for email: $userEmail');
//           setState(() {
//             isLoading = false;
//           });
//         }
//       }
//     } catch (e) {
//       print('Error fetching user details: $e');
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

// bool visLocked = true;
// bool visFeatureMode = false;
// bool visPremium = false;
// bool visShow = true;
// bool visHide = false;
// bool visAdmin = false;
// bool visManager = false;
// bool visEmployee = false;
// bool visCapture = false;
// bool visDev = false;

// String userRole = '';
// String userDept = '';
// List _allUserRolesResults = [];
// List _allVersionResults = [];
// List _currentVersionResult = [];

// void adminCheck() {
//   getUsersStream();
//   if(userRole == 'Admin'|| userRole == 'Administrator'){
//     visAdmin = true;
//   } else {
//     visAdmin = false;
//   }
// }
//
// getUsersStream() async {
//   var data = await FirebaseFirestore.instance
//       .collection('districts')
//       .doc(widget.districtId)
//       .collection('municipalities')
//       .doc(widget.municipalityId)
//       .collection('users')
//       .get();
//   setState(() {
//     _allUserRolesResults = data.docs;
//   });
//   getUserDetails();
// }
//
// getUserDetails() async {
//   for (var userSnapshot in _allUserRolesResults) {
//     ///Need to build a property model that retrieves property data entirely from the db
//     var user = userSnapshot['email'].toString();
//     var role = userSnapshot['userRole'].toString();
//     var userName = userSnapshot['userName'].toString();
//     var firstName = userSnapshot['firstName'].toString();
//     var lastName = userSnapshot['lastName'].toString();
//     var userDepartment = userSnapshot['deptName'].toString();
//
//     if (user == userEmail) {
//       userRole = role;
//       userDept = userDepartment;
//       // print('My Role is::: $userRole');
//
//       if(userRole == 'Admin'|| userRole == 'Administrator'){
//         visAdmin = true;
//         visManager = false;
//         visEmployee = false;
//         visCapture = false;
//       } else if(userRole == 'Manager'){
//         visAdmin = false;
//         visManager = true;
//         visEmployee = false;
//         visCapture = false;
//       } else if(userRole == 'Employee'){
//         visAdmin = false;
//         visManager = false;
//         visEmployee = true;
//         visCapture = false;
//       } else if(userRole == 'Capturer'){
//         visAdmin = false;
//         visManager = false;
//         visEmployee = false;
//         visCapture = true;
//       }
//
//       if(userDept == 'Developer'
//           // || userDept == 'Service Provider'
//       ){
//         visDev = true;
//       }
//
//     }
//   }
// }
//
// getVersionStream() async {
//   var data = await FirebaseFirestore.instance
//       .collection('districts')
//       .doc(widget.districtId)
//       .collection('municipalities')
//       .doc(widget.municipalityId)
//       .collection('version')
//       .get();
//   setState(() {
//     _allVersionResults = data.docs;
//   });
//   getVersionDetails();
// }
//
// getVersionDetails() async {
//   String activeVersion = _allVersionResults[2]['version'].toString();
//   var versionData = await FirebaseFirestore.instance
//       .collection('districts')
//       .doc(widget.districtId)
//       .collection('municipalities')
//       .doc(widget.municipalityId)
//       .collection('version')
//       .doc('current')
//       .collection('current-version')
//       .where('version', isEqualTo: activeVersion)
//       .get();
//
//   String currentVersion = versionData.docs[0].data()['version'];
//
//   for (var versionSnapshot in _allVersionResults) {
//     var version = versionSnapshot['version'].toString();
//
//     if (currentVersion == version) {
//       if (currentVersion == 'Unpaid') {
//         visLocked = true;
//         visFeatureMode = true;
//         visPremium = true;
//       } else if (currentVersion == 'Paid') {
//         visLocked = false;
//         visFeatureMode = false;
//         visPremium = true;
//       } else if (currentVersion == 'Premium') {
//         visLocked = false;
//         visFeatureMode = false;
//         visPremium = false;
//       }
//     }
//   }
// }

//   @override
//   Widget build(BuildContext context) {
//     Get.put(LocationController());
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.portraitUp,
//       DeviceOrientation.portraitDown,
//     ]);
//     if (districtId == null || municipalityId == null) {
//       return const Center(child: CircularProgressIndicator());
//     }
//     return Container(
//       decoration: const BoxDecoration(
//         image: DecorationImage(
//           image: AssetImage("assets/images/greyscale.jpg"),
//           fit: BoxFit.cover,
//         ),
//       ),
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         appBar: AppBar(
//           title: const Text(''),
//           backgroundColor: Colors.black87,
//           iconTheme: const IconThemeData(color: Colors.white),
//         ),
//         drawer:  NavDrawer( districtId: districtId!,
//             municipalityId: municipalityId!,),
//         body: SingleChildScrollView(
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center, // Center the row
//             children: <Widget>[
//               Expanded(
//                 flex: 1,
//                 child: Column(
//                   children: <Widget>[
//                     const SizedBox(height: 20),
//                     Stack(
//                       alignment: Alignment.topCenter,
//                       children: [
//                         Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.circular(40.0),
//                             child: Image.asset(
//                               'assets/images/umdm.png',
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 20),
//                     Column(
//                       children: [
//                         Center(
//                           child: Row(
//                             mainAxisAlignment:
//                             MainAxisAlignment.center, // Center the row
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               ElevatedIconButton(
//                                 onPress: () async {
//                                   Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                           builder: (context) =>
//                                            UsersPropsAll( districtId: districtId!,
//                                                municipalityId: municipalityId!,
//                                                municipalityUserEmail: userEmail!,)));
//                                 },
//                                 labelText: 'Reading\nDetails',
//                                 fSize: 16,
//                                 faIcon: const FaIcon(Icons.holiday_village),
//                                 fgColor: Colors.green,
//                                 btSize: const Size(130, 120),
//                               ),
//                               const SizedBox(width: 40),
//                               ElevatedIconButton(
//                                 onPress: () async {
//                                   Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                           builder: (context) => AllPropCapture(
//                                             districtId: districtId!,
//                                             municipalityId: municipalityId!,
//                                             municipalityUserEmail: userEmail!,)));
//                                 },
//                                 labelText: 'Capture\nReading',
//                                 fSize: 14,
//                                 faIcon: const FaIcon(Icons.holiday_village),
//                                 fgColor: Colors.green,
//                                 btSize: const Size(130, 120),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 5),
//                         Center(
//                           child: Row(
//                             mainAxisAlignment:
//                             MainAxisAlignment.center, // Center the row
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               ElevatedIconButton(
//                                 onPress: () async {
//                                   Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                           builder: (context) =>
//                                           ChatList( districtId: districtId!,
//                                             municipalityId: municipalityId!,)));
//                                 },
//                                 labelText: 'Chat \nList',
//                                 fSize: 18,
//                                 faIcon: const FaIcon(Icons.mark_chat_unread),
//                                 fgColor: Colors.blue,
//                                 btSize: const Size(130, 120),
//                               ),
//                               const SizedBox(width: 40),
//                               ElevatedIconButton(
//                                 onPress: () async {
//                                   Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                           builder: (context) =>
//                                          FaultTaskScreen( districtId: districtId!,
//                                            municipalityId: municipalityId!,)));
//                                 },
//                                 labelText: 'Report\nList',
//                                 fSize: 18,
//                                 faIcon: const FaIcon(Icons.report_problem),
//                                 fgColor: Colors.orange,
//                                 btSize: const Size(130, 120),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 5),
//                         Center(
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               ElevatedIconButton(
//                                 onPress: () {
//                                   Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                           builder: (context) =>
//                                           UsersConnectionsAll( districtId: districtId!,
//                                             municipalityId: municipalityId!,)));
//                                 },
//                                 labelText: 'Connect',
//                                 fSize: 14.5,
//                                 faIcon: const FaIcon(Icons.power_settings_new),
//                                 fgColor: Colors.orangeAccent,
//                                 btSize: const Size(130, 120),
//                               ),
//                               const SizedBox(width: 40),
//                               ElevatedIconButton(
//                                 onPress: () {
//                                   Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                           builder: (context) =>
//                                               PropertyMetersAll(
//                                                 districtId: districtId!,
//                                                 municipalityId: municipalityId!,
//                                                 municipalityUserEmail: userEmail!,)));
//                                 },
//                                 labelText: 'Meter\nUpdate',
//                                 fSize: 17,
//                                 faIcon: const FaIcon(Icons.build),
//                                 fgColor: Colors.brown,
//                                 btSize: const Size(130, 120),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 5),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             ElevatedIconButton(
//                               onPress: () {
//                                 showDialog(
//                                     barrierDismissible: false,
//                                     context: context,
//                                     builder: (context) {
//                                       return AlertDialog(
//                                         shape: const RoundedRectangleBorder(
//                                             borderRadius: BorderRadius.all(
//                                                 Radius.circular(18))),
//                                         title: const Text("Logout"),
//                                         content: const Text(
//                                             "Are you sure you want to logout?"),
//                                         actions: [
//                                           IconButton(
//                                             onPressed: () {
//                                               Navigator.pop(context);
//                                             },
//                                             icon: const Icon(Icons.cancel,
//                                                 color: Colors.red),
//                                           ),
//                                           IconButton(
//                                             onPressed: () async {
//                                               await FirebaseAuth.instance
//                                                   .signOut(); // Ensure the user is signed out
//
//                                               // Check the platform to handle the navigation accordingly
//                                               if (defaultTargetPlatform ==
//                                                   TargetPlatform.android) {
//                                                 if (defaultTargetPlatform ==
//                                                     TargetPlatform.android) {
//                                                   FirebaseAuth.instance
//                                                       .signOut();
//                                                   Navigator.pop(context);
//                                                   SystemNavigator.pop();
//                                                 } else {
//                                                   FirebaseAuth.instance
//                                                       .signOut();
//                                                   SystemNavigator.pop();
//                                                   // html.window.location.reload();
//                                                 }
//
//                                                 Navigator.pop(context);
//                                               }
//                                             },
//                                             icon: const Icon(Icons.done,
//                                                 color: Colors.green),
//                                           ),
//                                         ],
//                                       );
//                                     });
//                               },
//                               labelText: 'Logout',
//                               fSize: 18,
//                               faIcon: const FaIcon(Icons.logout),
//                               fgColor: Colors.red,
//                               btSize: const Size(130, 120),
//                             ),
//                             const SizedBox(width: 40),
//                             ElevatedIconButton(
//                               onPress: () async {
//                                 Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                         builder: (context) =>
//                                         NoticeConfigScreen(
//                                           userNumber: '',  districtId: districtId!,
//                                           municipalityId: municipalityId!,
//                                         )));
//                               },
//                               labelText: 'Broad\n-cast',
//                               fSize: 18,
//                               faIcon: const FaIcon(Icons.notifications_on),
//                               fgColor: Colors.red,
//                               btSize: const Size(130, 120),
//                             ),
//                             const SizedBox(width: 40),
//                             ElevatedIconButton(
//                               onPress: () async {
//                                 Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                         builder: (context) =>
//                                         FaultAttendantScreen(  districtId: districtId!,
//                                           municipalityId: municipalityId!,)));
//                               },
//                               labelText: 'Report\nList',
//                               fSize: 18,
//                               faIcon: const FaIcon(Icons.report_problem),
//                               fgColor: Colors.orange,
//                               btSize: const Size(130, 120),
//                             ),
//                           ],
//                         ),
//                         Stack(
//                           alignment: Alignment.center,
//                           children: [
//                             ElevatedIconButton(
//                               onPress: () async {
//                                 Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                         builder: (context) =>
//                                       DevConfigPage(  districtId: districtId!,
//                                         municipalityId: municipalityId!,)));
//                               },
//                               labelText: 'Dev\nConfig',
//                               fSize: 18,
//                               faIcon: const FaIcon(Icons.people),
//                               fgColor: Colors.black54,
//                               btSize: const Size(130, 120),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 20),
//                         Text(
//                           'Copyright Cyberfox ',
//                           style: GoogleFonts.saira(
//                             color: Colors.white,
//                             backgroundColor: Colors.white10,
//                             fontWeight: FontWeight.normal,
//                             fontStyle: FontStyle.italic,
//                             fontSize: 16,
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
//
//   ///pdf view loader getting file name onPress/onTap that passes filename to this class
//   void openPDF(BuildContext context, File file) => Navigator.of(context).push(
//     MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
//   );

class HomeManagerScreen extends StatefulWidget {
  const HomeManagerScreen({super.key, required bool isLocalMunicipality});

  @override
  State<StatefulWidget> createState() => _HomeManagerScreenState();
}

final FirebaseAuth auth = FirebaseAuth.instance;

final User? user = auth.currentUser;
final uid = user?.uid;
final email = user?.email;
String userID = uid as String;
String userEmail = email as String;

class _HomeManagerScreenState extends State<HomeManagerScreen> {
  String? userEmail;
  String? districtId;
  String? municipalityId;
  bool isLoading = true;
  late FToast fToast;
  bool isLocalMunicipality = false;
  bool isLocalUser = false;
  bool loading = true;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => initializeAndCheckUnreadMessages());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    fToast = FToast();
    fToast.init(context);
  }

  Future<void> initializeAndCheckUnreadMessages() async {
    await fetchUserDetails(); // Ensures `districtId` and `municipalityId` are available
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> fetchUserDetails() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userEmail = user.email;
        print('Fetched User Email: $userEmail');

        // Query the users collection group to get the current user document
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collectionGroup('users')
            .where('email', isEqualTo: userEmail)
            .limit(1)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          var userDoc = userSnapshot.docs.first;

          // Fetch the document data
          final data = userDoc.data() as Map<String, dynamic>?;

          if (data != null) {
            // Check if the document contains the 'isLocalMunicipality' field
            if (data.containsKey('isLocalMunicipality')) {
              isLocalMunicipality = data['isLocalMunicipality'] ?? false;
            } else {
              // Default to district municipality if the field is absent
              isLocalMunicipality = false;
            }
            isLocalUser = data['isLocalUser'] ?? false;
            // Get districtId and municipalityId directly from the document data, if they exist
            districtId = data['districtId'] ??
                userDoc.reference.parent.parent?.parent.id;
            municipalityId =
                data['municipalityId'] ?? userDoc.reference.parent.parent?.id;
          }
        }
        if (mounted) {
          setState(() {
            isLoading = false; // Set loading to false after fetching data
          });
        }
      }
    } catch (e) {
      print('Error fetching user details: $e');
      if (mounted) {
        setState(() {
          isLoading = false; // Set loading to false even if there's an error
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      double scrollAmount = 50.0; // Adjust scroll amount as needed

      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _scrollController.animateTo(
          _scrollController.offset + scrollAmount,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
        );
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _scrollController.animateTo(
          _scrollController.offset - scrollAmount,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
        );
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
        _scrollController.animateTo(
          _scrollController.offset + scrollAmount * 5,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
        _scrollController.animateTo(
          _scrollController.offset - scrollAmount * 5,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    bool hasUnreadMessages = notificationProvider.hasUnreadMessages ||
        notificationProvider.hasUnreadFinanceMessages;

    print(
        "HomeManagerScreen build: combined hasUnreadMessages = $hasUnreadMessages");
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (districtId == null && municipalityId == null && !isLocalMunicipality) {
      return const Scaffold(
        body: Center(
          child: Text("Error: Could not load municipality data"),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/greyscale.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(''),
          backgroundColor: Colors.black87,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        drawer: MunicipalNavDrawer(municipalityId: municipalityId ??'', isLocalMunicipality: isLocalMunicipality, isLocalUser: isLocalUser, districtId: districtId ??'',),
        body: Focus(
          focusNode: _focusNode, // Attach the focus node
          onKeyEvent: _handleKeyEvent, // Listen for key events
          child: Scrollbar(
            controller: _scrollController,
            thickness: 12, // Customize the thickness of the scrollbar
            radius: const Radius.circular(8), // Rounded edges for the scrollbar
            thumbVisibility: true,
            trackVisibility: true, // Makes the track visible as well
            interactive: true, // Ensures the scrollbar remains interactive// Ensure the scrollbar is always visible
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: 20),
                  // Logo at the top
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40.0),
                      child: const ResponsiveLogo(),
                    ),
                  ),
                  const SizedBox(height: 40),
            
                  // First row of buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedIconButton(
                        onPress: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UsersPropsAll(
                                municipalityUserEmail: userEmail!,
                                isLocalMunicipality: isLocalMunicipality,
                                districtId: districtId,
                                municipalityId: municipalityId!,
                                isLocalUser: isLocalUser,
                              ),
                            ),
                          );
                        },
                        labelText: 'Reading\nDetails',
                        fSize: 16,
                        faIcon: const FaIcon(Icons.holiday_village),
                        fgColor: Colors.green,
                        btSize: const Size(130, 120),
                      ),
                      const SizedBox(width: 40),
                      ElevatedIconButton(
                        onPress: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AllPropCapture(
                                municipalityUserEmail: userEmail!,
                                isLocalMunicipality: isLocalMunicipality,
                                districtId: districtId,
                                municipalityId: municipalityId!,
                                isLocalUser: isLocalUser,
                              ),
                            ),
                          );
                        },
                        labelText: 'Capture\nReading',
                        fSize: 14,
                        faIcon: const FaIcon(Icons.camera_alt),
                        fgColor: Colors.green,
                        btSize: const Size(130, 120),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
            
                  // Second row of buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          ElevatedIconButton(
                            onPress: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatList(),
                                  ));
                            },
                            labelText: 'Chat \nList',
                            fSize: 18,
                            faIcon: const FaIcon(Icons.mark_chat_unread),
                            fgColor: Colors.blue,
                            btSize: const Size(130, 120),
                          ),
                          Consumer<NotificationProvider>(
                            builder: (context, notificationProvider, child) {
                              final hasUnreadMessages =
                                  notificationProvider.hasUnreadMessages ||
                                      notificationProvider.hasUnreadFinanceMessages;
                              print("Consumer badge update: $hasUnreadMessages");
                              return hasUnreadMessages
                                  ? Positioned(
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
                                    )
                                  : Container();
                            },
                          ), // No badge if no unread messages
                        ],
                      ),
                      const SizedBox(width: 40),
                      ElevatedIconButton(
                        onPress: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FaultTaskScreen(
                                municipalityUserEmail: userEmail!,
                                isLocalMunicipality: isLocalMunicipality,
                                districtId: districtId,
                                municipalityId: municipalityId!,
                                isLocalUser: isLocalUser,
                              ),
                            ),
                          );
                        },
                        labelText: 'Report\nList',
                        fSize: 18,
                        faIcon: const FaIcon(Icons.report_problem),
                        fgColor: Colors.orange,
                        btSize: const Size(130, 120),
                      ),
                    ],
                  ),
            
                  const SizedBox(height: 20),
            
                  // Third row of buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedIconButton(
                        onPress: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UsersConnectionsAll(
                                  municipalityUserEmail: userEmail!,
                                  isLocalMunicipality: isLocalMunicipality,
                                  districtId: districtId,
                                  municipalityId: municipalityId!,
                                  isLocalUser: isLocalUser),
                            ),
                          );
                        },
                        labelText: 'Connect',
                        fSize: 14.5,
                        faIcon: const FaIcon(Icons.power_settings_new),
                        fgColor: Colors.orangeAccent,
                        btSize: const Size(130, 120),
                      ),
                      const SizedBox(width: 40),
                      ElevatedIconButton(
                        onPress: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PropertyMetersAll(
                                municipalityUserEmail: userEmail!,
                                isLocalMunicipality: isLocalMunicipality,
                                districtId: districtId,
                                municipalityId: municipalityId!,
                                isLocalUser: isLocalUser,
                              ),
                            ),
                          );
                        },
                        labelText: 'Meter\nUpdate',
                        fSize: 17,
                        faIcon: const FaIcon(Icons.build),
                        fgColor: Colors.brown,
                        btSize: const Size(130, 120),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
            
                  // Fourth row of buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedIconButton(
                        onPress: () {
                          showDialog(
                            barrierDismissible: false,
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(18),
                                  ),
                                ),
                                title: const Text("Logout"),
                                content:
                                    const Text("Are you sure you want to logout?"),
                                actions: [
                                  IconButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    icon:
                                        const Icon(Icons.cancel, color: Colors.red),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      await FirebaseAuth.instance.signOut();
                                      Navigator.pop(context);
                                    },
                                    icon:
                                        const Icon(Icons.done, color: Colors.green),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        labelText: 'Logout',
                        fSize: 18,
                        faIcon: const FaIcon(Icons.logout),
                        fgColor: Colors.red,
                        btSize: const Size(130, 120),
                      ),
                      const SizedBox(width: 40),
                      ElevatedIconButton(
                        onPress: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NoticeConfigScreen(
                                userNumber: '',
                                municipalityUserEmail: userEmail!,
                                isLocalMunicipality: isLocalMunicipality,
                                districtId: districtId,
                                municipalityId: municipalityId!,
                                isLocalUser: isLocalUser,
                              ),
                            ),
                          );
                        },
                        labelText: 'Broad\n-cast',
                        fSize: 18,
                        faIcon: const FaIcon(Icons.notifications_on),
                        fgColor: Colors.red,
                        btSize: const Size(130, 120),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
            
                  // Developer Config button
                  ElevatedIconButton(
                    onPress: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DevConfigPage(),
                        ),
                      );
                    },
                    labelText: 'Dev\nConfig',
                    fSize: 18,
                    faIcon: const FaIcon(Icons.people),
                    fgColor: Colors.black54,
                    btSize: const Size(130, 120),
                  ),
                  const SizedBox(height: 20),
            
                  Text(
                    'Copyright Cyberfox',
                    style: GoogleFonts.saira(
                      color: Colors.white,
                      backgroundColor: Colors.white10,
                      fontWeight: FontWeight.normal,
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

///pdf view loader getting file name onPress/onTap that passes filename to this class
void openPDF(BuildContext context, File file) => Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
    );
class ResponsiveLogo extends StatelessWidget {
  const ResponsiveLogo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the screen width and height
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Set a base logo size that scales based on the screen dimensions
    double logoWidth = screenWidth * 0.3; // Set to 30% of screen width
    double logoHeight = logoWidth * (687 / 550); // Maintain new aspect ratio (550x687)

    return Center(
      child: Container(
        width: logoWidth,
        height: logoHeight,
        child: FittedBox(
          fit: BoxFit.contain,  // Ensures the image scales within the container
          child: Image.asset('assets/images/umdm.png'),
        ),
      ),
    );
  }
}