import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:municipal_track/code/Reuseables/menu_reusable_elevated_button.dart';

class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  Drawer(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child:Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children:  <Widget>[
              buildHeader(context),
              buildMenuItems(context),
            ],
          ),
        )
    );
  }
}

Widget buildHeader(BuildContext context) => Container(
  padding: EdgeInsets.only(
    top: MediaQuery.of(context).padding.top,
  ),
  child: Image.asset('images/logo.png'),
);

Widget buildMenuItems(BuildContext context) => Wrap(
  runSpacing: 10,
  children:  <Widget>[
    ListTile(
      leading: const Icon(Icons.home, size: 60,),
      title: const Text('Home'),
      onTap: (){
        Navigator.of(context).popUntil((route) => route.isFirst);
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
    // ListTile(
    //   leading:  Image.asset('images/MainMenu/road_signs_markings_icon.png'),
    //   title: const Text('Map View'),
    //   onTap: (){
    //     Navigator.of(context).popUntil((route) => route.isFirst);
    //     // Navigator.push(context,
    //     //   MaterialPageRoute(builder: (context) => const GreenMenu()),
    //     // );
    //   },
    // ),
    // ListTile(
    //   leading:  Image.asset('images/MainMenu/driver_section_icon.png'),
    //   title: const Text('Driver Section'),
    //   onTap: (){
    //     Navigator.of(context).popUntil((route) => route.isFirst);
    //     // Navigator.push(context,
    //     //   MaterialPageRoute(builder: (context) => const BlueMenu()),
    //     // );
    //   },
    // ),
    // ListTile(
    //   leading:  Image.asset('images/MainMenu/rulesoftheroadicon.png'),
    //   title: const Text('Rules of the Road'),
    //   onTap: (){
    //     Navigator.of(context).popUntil((route) => route.isFirst);
    //     // Navigator.push(context,
    //     //   MaterialPageRoute(builder: (context) => const PurpleMenu()),
    //     // );
    //   },
    // ),
    // ListTile(
    //   leading: Image.asset('images/MainMenu/quiz_icon.png'),
    //   title: const Text('Quiz Yourself'),
    //   onTap: (){
    //     Navigator.of(context).popUntil((route) => route.isFirst);
    //     // Navigator.push(context,
    //     //   MaterialPageRoute(builder: (context) => const quizPage()),
    //     // );
    //   },
    // ),
    const SizedBox(
      height: 10,
    ),
    Wrap(
        runSpacing: -15,
        children:  <Widget>[
          ListTile(
            leading: const Icon(Icons.facebook_rounded, size: 30,),
            title: const Text('Follow us on Facebook'),
            onTap: (){
              final Uri _url1 = Uri.parse('https://www.facebook.com/cyberfoxit');
              _launchURL(_url1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.video_collection_rounded, size: 30,),
            title: const Text('Subscribe on YouTube'),
            onTap: (){
              final Uri _url2 = Uri.parse('https://www.youtube.com/user/axed25');
              _launchURL(_url2);
            },
          ),
          ListTile(
              leading: const Icon(Icons.add_call, size: 30,),
              title: const Text('Contact us'),
              onTap: (){
                final Uri _tel = Uri.parse('tel:+27${0333871974}');
                launchUrl(_tel);
              }
          ),
          ListTile(
              leading: const Icon(Icons.logout, size: 30,),
              title: const Text('Logout'),
              onTap: (){
                FirebaseAuth.instance.signOut();
              }
          ),
        ]
    ),
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              'images/cyberfox_logo_small.png',
              height: 70,
              width: 100,
              fit: BoxFit.fitWidth,
            )
        )
      ],
    )
  ],
);

_launchURL(_url) async {
  if (await canLaunchUrl(_url)) {
    await launchUrl(_url);
  } else {
    throw 'Could not launch $_url';
  }
}