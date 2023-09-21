import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/menu_reusable_elevated_button.dart';
import 'package:municipal_tracker_msunduzi/code/DisplayPages/counsellor_screen.dart';

class NavDrawer extends StatelessWidget {
  const NavDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[200],
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child:Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children:  <Widget>[

              const SizedBox(height: 100,),
              Center(child: buildHeader(context)),

              const SizedBox(height: 50,),
              buildMenuItems(context),

            ],
          ),
        )
    );
  }
}

Widget buildHeader(BuildContext context) => Container(
  // padding: EdgeInsets.only(
  //   top: MediaQuery.of(context).padding.top,
  // ),
  decoration: const BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(20)),
    color: Colors.grey,),
  // padding: EdgeInsets.only(
  //   top: MediaQuery.of(context).padding.top,
  // ),
  child: Image.asset('assets/images/municipal_services.png', height: 150, width: 290,),
);


Widget buildMenuItems(BuildContext context) => Wrap(
  runSpacing: 10,
  runAlignment: WrapAlignment.end,
  children:  <Widget>[
    const SizedBox(height: 20,),
    ListTile(
      leading: const Icon(Icons.supervised_user_circle_outlined, size: 50,),
      title: const Text('Contact councillors',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,),),
      onTap: () {
        Navigator.push(context,
          MaterialPageRoute(builder: (context) => const CouncillorScreen()),
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
    const SizedBox(height: 200,),
    Wrap(
        runSpacing: 0,
        runAlignment: WrapAlignment.spaceEvenly,
        children:  <Widget>[
          SizedBox(
            height: 40,
            child: ListTile(
                leading: const Icon(Icons.add_call, size: 20,),
                title: const Text('Contact Support'),
                onTap: (){
                  final Uri _tel = Uri.parse('tel:+27${0333923000}');
                  launchUrl(_tel);
                }
            ),
          ),
          SizedBox(
            height: 40,
            child: ListTile(
                leading: const Icon(Icons.error, size: 20,),
                title: const Text('Report a bug'),
                onTap: (){
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
    const SizedBox(height: 100,),


    ListTile(
      leading: const Padding(
        padding: EdgeInsets.only(left: 8.0),
        child: Icon(Icons.label_important, size: 50,),
      ),
      title: const Text('    Cyberfox',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,),),
      trailing: const Padding(
        padding: EdgeInsets.only(right: 15.0),
        child: Icon(Icons.copyright, size: 30,),
      ),
      onTap: (){
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

_launchURL(url) async {
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    throw 'Could not launch $url';
  }
}