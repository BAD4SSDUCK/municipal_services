import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:municipal_track/code/Reusable/menu_reusable_elevated_button.dart';

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

              const SizedBox(height: 200,),
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
  child: Image.asset('assets/images/logo.png', height: 200,),
);


Widget buildMenuItems(BuildContext context) => Wrap(

  runSpacing: 10,
  children:  <Widget>[
    const SizedBox(height: 120,),
    // ListTile(
    //   leading: const Icon(Icons.label_important, size: 50,),
    //   title: const Text('Cyberfox IT',
    //     style: TextStyle(
    //       fontWeight: FontWeight.bold,
    //       fontSize: 20,),),
    //   onTap: (){
    //     Navigator.of(context).popUntil((route) => route.isFirst);
    //   },
    // ),
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
    const SizedBox(height: 20,),
    Wrap(
        runSpacing: 0,
        runAlignment: WrapAlignment.spaceEvenly,
        children:  <Widget>[
          SizedBox(
            height: 40,
            child: ListTile(
                leading: const Icon(Icons.add_call, size: 20,),
                title: const Text('Contact Cyberfox'),
                onTap: (){
                  final Uri _tel = Uri.parse('tel:+27${0333871974}');
                  launchUrl(_tel);
                }
            ),
          ),
          SizedBox(
            height: 40,
            child: ListTile(
              leading: const Icon(Icons.facebook_rounded, size: 20,),
              title: const Text('Cyberfox Facebook'),
              onTap: (){
                final Uri _url1 = Uri.parse('https://www.facebook.com/cyberfoxit');
                _launchURL(_url1);
              },
            ),
          ),
          SizedBox(
            height: 50,
            child: ListTile(
              leading: const Icon(Icons.video_collection_rounded, size: 20,),
              title: const Text('Subscribe on YouTube'),
              onTap: (){
                final Uri _url2 = Uri.parse('https://www.youtube.com/user/axed25');
                _launchURL(_url2);
              },
            ),
          ),

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
              height: 50,
              //width: 100,
              fit: BoxFit.fitWidth,
            )
        )
      ],
    ),


  ],
);

_launchURL(_url) async {
  if (await canLaunchUrl(_url)) {
    await launchUrl(_url);
  } else {
    throw 'Could not launch $_url';
  }
}