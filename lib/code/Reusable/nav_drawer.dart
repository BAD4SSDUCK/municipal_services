import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:municipal_services/code/Reusable/menu_reusable_elevated_button.dart';
import 'package:municipal_services/code/EventsPages/display_events_calendar.dart';
import 'package:municipal_services/code/PDFViewer/view_pdf.dart';
import 'package:municipal_services/code/DisplayPages/councillor_screen.dart';
import 'package:provider/provider.dart';

import '../Chat/chat_screen_councillors.dart';
import '../DisplayPages/city_directory.dart';
import '../Models/notify_provider.dart';

class NavDrawer extends StatefulWidget {
  const NavDrawer({
    super.key,
  });

  @override
  State<NavDrawer> createState() => _NavDrawerState();
}

class _NavDrawerState extends State<NavDrawer> {
  bool isCouncillor = false;
  StreamSubscription<QuerySnapshot>? unreadCouncillorMessagesSubscription;
  bool hasUnreadCouncillorMessages = false;

  @override
  void initState() {
    super.initState();
    checkIfCouncillor();
    checkForUnreadCouncilMessages();
  }

  @override
  void dispose() {
    unreadCouncillorMessagesSubscription?.cancel();
    super.dispose();
  }

  // Determine if the user is a councillor
  Future<bool> checkIfCouncillor() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? selectedPropertyAccountNumber =
      prefs.getString('selectedPropertyAccountNo');

      if (selectedPropertyAccountNumber == null) {
        print('Error: selectedPropertyAccountNumber is null.');
        return false;
      }

      QuerySnapshot propertySnapshot = await FirebaseFirestore.instance
          .collectionGroup('properties')
          .where('accountNumber', isEqualTo: selectedPropertyAccountNumber)
          .get();

      if (propertySnapshot.docs.isNotEmpty) {
        DocumentSnapshot propertyDoc = propertySnapshot.docs.first;
        bool isLocalMunicipality = propertyDoc.get('isLocalMunicipality');
        String municipalityId = propertyDoc.get('municipalityId');
        String? districtId =
        propertyDoc.data().toString().contains('districtId')
            ? propertyDoc.get('districtId')
            : null;

        // Check the councillor collection
        QuerySnapshot councillorSnapshot = isLocalMunicipality
            ? await FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(municipalityId)
            .collection('councillors')
            .where('councillorPhone',
            isEqualTo: FirebaseAuth.instance.currentUser?.phoneNumber)
            .get()
            : await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId!)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('councillors')
            .where('councillorPhone',
            isEqualTo: FirebaseAuth.instance.currentUser?.phoneNumber)
            .get();

        if (councillorSnapshot.docs.isNotEmpty) {
          print("User is a councillor.");
          return true;
        }
      }

      print("User is not a councillor.");
      return false;
    } catch (e) {
      print('Error checking if user is a councillor: $e');
      return false;
    }
  }


  Future<void> checkForUnreadCouncilMessages() async {
    String? userPhone = FirebaseAuth.instance.currentUser?.phoneNumber;

    if (userPhone == null) {
      print("Error: Current user's phone number is null.");
      return;
    }

    // Determine if the user is a councillor
    checkIfCouncillor().then((isCouncillor) {
      SharedPreferences.getInstance().then((prefs) {
        String? selectedPropertyAccountNumber = prefs.getString('selectedPropertyAccountNo');
        if (selectedPropertyAccountNumber == null) {
          print('Error: selectedPropertyAccountNumber is null.');
          return;
        }

        FirebaseFirestore.instance
            .collectionGroup('properties')
            .where('accountNumber', isEqualTo: selectedPropertyAccountNumber)
            .get()
            .then((propertySnapshot) {
          if (propertySnapshot.docs.isNotEmpty) {
            DocumentSnapshot propertyDoc = propertySnapshot.docs.first;
            bool isLocalMunicipality = propertyDoc.get('isLocalMunicipality');
            String municipalityId = propertyDoc.get('municipalityId');
            String? districtId = propertyDoc.data().toString().contains('districtId')
                ? propertyDoc.get('districtId')
                : null;

            CollectionReference councillorChatsCollection = isLocalMunicipality
                ? FirebaseFirestore.instance
                .collection('localMunicipalities')
                .doc(municipalityId)
                .collection('chatRoomCouncillor')
                : FirebaseFirestore.instance
                .collection('districts')
                .doc(districtId!)
                .collection('municipalities')
                .doc(municipalityId)
                .collection('chatRoomCouncillor');

            unreadCouncillorMessagesSubscription?.cancel();
            unreadCouncillorMessagesSubscription = councillorChatsCollection.snapshots().listen(
                  (councillorSnapshot) async {
                bool hasUnread = false;

                if (isCouncillor) {
                  String councillorPhoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
                  councillorChatsCollection
                      .doc(councillorPhoneNumber)
                      .collection('userChats')
                      .snapshots()
                      .listen((userChatSnapshot) {
                    for (var userChatDoc in userChatSnapshot.docs) {
                      userChatDoc.reference.collection('messages').snapshots().listen((messagesSnapshot) {
                        bool localUnread = false; // Temporary variable for this chat
                        for (var messageDoc in messagesSnapshot.docs) {
                          if (messageDoc['isReadByCouncillor'] == false) {
                            localUnread = true;
                            hasUnread = true;
                            break;
                          }
                        }

                        // Update the global unread state only if necessary
                        if (!localUnread) {
                          hasUnread = false;
                        }

                        if (mounted) {
                          setState(() {
                            hasUnreadCouncillorMessages = hasUnread;
                          });
                          print("Real-time badge updated: $hasUnreadCouncillorMessages");
                        }
                      });
                    }
                  });
                } else {
                  for (var councillorDoc in councillorSnapshot.docs) {
                    councillorDoc.reference.collection('userChats').snapshots().listen((userChatSnapshot) {
                      for (var userChatDoc in userChatSnapshot.docs) {
                        userChatDoc.reference.collection('messages').snapshots().listen((messagesSnapshot) {
                          bool localUnread = false; // Temporary variable for this chat
                          for (var messageDoc in messagesSnapshot.docs) {
                            if (messageDoc['isReadByUser'] == false) {
                              localUnread = true;
                              hasUnread = true;
                              break;
                            }
                          }

                          // Update the global unread state only if necessary
                          if (!localUnread) {
                            hasUnread = false;
                          }

                          if (mounted) {
                            setState(() {
                              hasUnreadCouncillorMessages = hasUnread;
                            });
                            print("Real-time badge updated: $hasUnreadCouncillorMessages");
                          }
                        });
                      }
                    });
                  }
                }
              },
            );
          }
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
        backgroundColor: Colors.grey[200],
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 80,),
              Center(child: buildHeader(context)),
              const SizedBox(height: 50,),
              buildMenuItems(context),
            ],
          ),
        )
    );
  }


  Widget buildHeader(BuildContext context) =>
      Container(
        // padding: EdgeInsets.only(
        //   top: MediaQuery.of(context).padding.top,
        // ),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          color: Colors.grey,),
        // padding: EdgeInsets.only(
        //   top: MediaQuery.of(context).padding.top,
        // ),
        child: Image.asset(
          'assets/images/municipal_services.png', height: 150, width: 290,),
      );


  Widget buildMenuItems(BuildContext context,) =>
      Wrap(
        runSpacing: 10,
        runAlignment: WrapAlignment.end,
        children: <Widget>[
          const SizedBox(height: 20,),
          ListTile(
            leading: Stack(
              children: [
                const Icon(Icons.supervised_user_circle_outlined, size: 40),
                if (hasUnreadCouncillorMessages)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text('Contact Councillors',
              style: GoogleFonts.turretRoad(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18.5,
              ),
            ),
            onTap: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => CouncillorScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lightbulb, size: 40,),
            title: Text('Load Shedding Schedule',
              style: GoogleFonts.turretRoad(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            onTap: () async {
              final Uri _url = Uri.parse(
                  'http://www.msunduzi.gov.za/site/search/downloadencode/LOAD%20SHEDDING%20SCHEDULE%20WORD%20STAGE%201%20-%204%20%205%20-%208%20update.pdf');
              // _launchURL(_url);
              _launchURLExternal(_url);

              //
              // final file = await PDFApi.loadAsset('http://www.msunduzi.gov.za/site/search/downloadencode/LOAD%20SHEDDING%20SCHEDULE%20WORD%20STAGE%201%20-%204%20%205%20-%208%20update.pdf');
              // try {
              //   if(context.mounted)openPDF(context, file);
              //   Fluttertoast.showToast(
              //       msg: "Download Successful!");
              // } catch (e) {
              //   Fluttertoast.showToast(msg: "Unable to download statement.");
              // }

            },
          ),
          ListTile(
            leading: const Icon(Icons.event_available, size: 40,),
            title: Text('Events Calendar',
              style: GoogleFonts.turretRoad(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18.5,
              ),
            ),
            onTap: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => EventsCalendar()),
              );
            },
          ),
          // ListTile(
          //   leading:  Image.asset('images/MainMenu/road_signs_icon.png'),
          //   title: const Text('User details'),
          //   onTap: (){
          //     Navigator.of(context).popUntil((route) => route.isFirst);
          //     // Navigator.push(context,
          //     //   MaterialPageRoute(builder: (context) => const RedMenu()),
          //     // );
          //   },
          // ),
          ListTile(
            leading: const Icon(Icons.people, size: 40,),
            title: Text('Municipal Directory',
              style: GoogleFonts.turretRoad(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18.5,
              ),
            ),
            onTap: () {
              Navigator.push(context,
                MaterialPageRoute(
                    builder: (context) => EmployeeDirectoryScreen()),
              );
            },
          ),
          const SizedBox(height: 80,),
          Wrap(
              runSpacing: 0,
              runAlignment: WrapAlignment.spaceEvenly,
              children: <Widget>[
                SizedBox(
                  height: 40,
                  child: ListTile(
                      leading: const Icon(Icons.add_call, size: 20,),
                      title: Text('Contact Municipality',
                        style: GoogleFonts.montserrat(
                          color: Colors.black,
                          fontWeight: FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                      onTap: () {
                        final Uri _tel = Uri.parse('tel:+27${0338976700}');
                        launchUrl(_tel);
                      }
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ListTile(
                      leading: const Icon(Icons.error, size: 20,),
                      title: Text('Report a bug',
                        style: GoogleFonts.montserrat(
                          color: Colors.black,
                          fontWeight: FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                      onTap: () {
                        final Uri _tel = Uri.parse('tel:+27${0333871974}');
                        launchUrl(_tel);
                      }
                  ),
                ),
                // SizedBox(
                //   height: 40,
                //   child: ListTile(
                //     leading: const Icon(Icons.facebook_rounded, size: 20,),
                //     title: const Text('Cyberfox Facebook'),
                //     onTap: () async {
                //
                //       ///could work but opens to facebook google play app install and not the app directly
                //       // await LaunchApp.openApp(
                //       //   // androidPackageName: 'com.android.chrome',
                //       //   androidPackageName: 'com.facebook.katana',
                //       //   appStoreLink: 'com.facebook.katana',
                //       //   openStore: false,
                //       // );
                //
                //       ///trying new method
                //       _launchSocial(Uri.parse('fb://page/122574191145679'), Uri.parse('https://www.facebook.com/cyberfoxit'));
                //
                //       ///works but breaks once web view completes loading and user is not logged into facebook
                //       // final Uri _url1 = Uri.parse("fb://facewebmodal/f?href=https://www.facebook.com/cyberfoxit");
                //       ///new url launcher
                //       // launchFacebook(_url1);
                //       ///old url Launcher
                //       // _launchURL(_url1);
                //     },
                //   ),
                // ),
                // SizedBox(
                //   height: 50,
                //   child: ListTile(
                //     leading: const Icon(Icons.video_collection_rounded, size: 20,),
                //     title: const Text('Subscribe on YouTube'),
                //     onTap: () async {
                //
                //       ///could work but opens to youtube app installed and not the channel directly
                //       // await LaunchApp.openApp(
                //       //   // androidPackageName: 'com.android.chrome',
                //       //   androidPackageName: 'com.google.android.youtube',
                //       //   appStoreLink: 'com.google.android.youtube',
                //       //   openStore: false,
                //       // );
                //
                //       ///canLaunch claims depreciated but still works
                //       const url = 'https://www.youtube.com/channel/UCifnsFfj8hr6ATnj8hVIRfQ';
                //       if (await canLaunch(url)) {
                //         await launch(url);
                //       } else {
                //         _launchSocial(Uri.parse('youtube:www.youtube.com/channel/UCifnsFfj8hr6ATnj8hVIRfQ'), Uri.parse('https://www.youtube.com/user/axed25'));
                //         throw 'Could not launch $url';
                //       }
                //
                //       // final Uri ytUrl = Uri.parse('https://www.youtube.com/channel/UCifnsFfj8hr6ATnj8hVIRfQ');
                //       // if (await canLaunchUrl(ytUrl)) {
                //       //   await launchUrl(ytUrl);
                //       // } else {
                //       //   _launchSocial(Uri.parse('youtube:www.youtube.com/channel/UCifnsFfj8hr6ATnj8hVIRfQ'), Uri.parse('https://www.youtube.com/user/axed25'));
                //       //   throw 'Could not launch youtube app $ytUrl';
                //       // }
                //
                //       //youtube:https://www.youtube.com/channel/UCifnsFfj8hr6ATnj8hVIRfQ < Cyberfox yt
                //       // _launchSocial(Uri.parse('youtube:www.youtube.com/channel/UCifnsFfj8hr6ATnj8hVIRfQ'), Uri.parse('https://www.youtube.com/user/axed25'));
                //
                //       ///old method
                //       // final Uri _url2 = Uri.parse('https://www.youtube.com/user/axed25');
                //       // _launchURL(_url2);
                //     },
                //   ),
                // ),

                // ListTile(
                //     leading: const Icon(Icons.logout, size: 20,),
                //     title: const Text('Logout'),
                //     onTap: (){
                //       FirebaseAuth.instance.signOut();
                //     }
                // ),
              ]
          ),
          const SizedBox(height: 90,),

          ListTile(
            leading: const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.label_important, size: 50,),
            ),
            title: Text(' Cyberfox',
              style: GoogleFonts.saira(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            trailing: const Padding(
              padding: EdgeInsets.only(right: 15.0),
              child: Icon(Icons.copyright, size: 30,),
            ),
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Align(
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(
                    'assets/images/cyberfox_logo_small.png',
                    height: 80,
                    width: 120,
                    fit: BoxFit.fitWidth,
                  )
              )
            ],
          ),
        ],
      );
}
///unused web view page component, left for reference
class WebViewApp extends StatefulWidget {
  final Uri webUrl;
  const WebViewApp({super.key, required this.webUrl});

  @override
  State<WebViewApp> createState() => _WebViewAppState();
}

class _WebViewAppState extends State<WebViewApp> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..loadRequest(
        widget.webUrl,
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Web View'),
      ),
      body:
      // WebViewApp(webUrl: widget.webUrl)
      WebViewWidget(controller: controller,),
    );
  }
}
///how to call web view page
// Navigator.push(context, MaterialPageRoute(builder: (context) => WebViewApp(webUrl: _url1)));
///end of web view page component

void _launchSocial(Uri url, Uri fallbackUrl) async {
  try {
    bool launched =
    await launchUrl(url, mode: LaunchMode.externalApplication,);
    if (!launched) {
      await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication,);
    }
  } catch (e) {
    await launchUrl(fallbackUrl, mode: LaunchMode.inAppWebView,);
    Fluttertoast.showToast(msg: "Failed to open in Youtube App!");
  }
}

void openPDF(BuildContext context, File file) => Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
);

_launchURL(url) async {
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    throw 'Could not launch $url';
  }
}

_launchURLExternal(url) async {
  if (await canLaunchUrl(url)) {
    await launchUrl(url,
    mode: LaunchMode.externalNonBrowserApplication);
  } else {
    throw 'Could not launch $url';
  }
}

void openPdfFromUrl(String url) {
  debugPrint('opening PDF url = $url');
  var googleDocsUrl = 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeQueryComponent(url)}';
  debugPrint('opening Google docs with PDF url = $googleDocsUrl');
  final Uri uri = Uri.parse(googleDocsUrl);
  launchUrl(uri);
  }
