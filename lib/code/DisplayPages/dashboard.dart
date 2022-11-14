import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:municipal_track/code/Reuseables/main_menu_reusable_button.dart';

import 'package:municipal_track/code/Reuseables/nav_drawer.dart';
import 'package:flutter/services.dart';

import '../Reuseables/map_component.dart';
import '../Reuseables/menu_reusable_elevated_button.dart';
import 'add_details.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() =>_MainMenuState();
  }

  class _MainMenuState extends State<MainMenu>{
  final user = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    const double fontSize = 30.0;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return Container(
      // decoration: const BoxDecoration(
      //   image: DecorationImage(
      //       image: AssetImage("images/MainMenu/mainbackground.png"),
      //       fit: BoxFit.cover),
      // ),
      child: Scaffold(
        backgroundColor: Colors.grey[350],
        appBar: AppBar(
          title:
          Text('Signed in as: ${user.email!}'),
          backgroundColor: Colors.black87,
        ),
        //drawer: const NavigationDrawer(),
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

                    const SizedBox(height: 100),
                    ReusableElevatedButton(
                      onPress: (){


                      },
                      buttonText: 'User Details',fSize: fontSize,
                    ),

                    const SizedBox(height: 30),
                    ReusableElevatedButton(
                      onPress: (){


                      },
                      buttonText: 'Edit Details',fSize: fontSize,
                    ),

                    const SizedBox(height: 30),
                    ReusableElevatedButton(
                      onPress: (){
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => const AddUserDetails()));
                      },
                      buttonText: 'Add New Details',fSize: fontSize,
                    ),

                    const SizedBox(height: 30),
                    ReusableElevatedButton(
                      onPress: (){

                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => MapPage()));
                      },
                      buttonText: 'Map Viewer',fSize: fontSize,
                    ),

                    const SizedBox(height: 30),
                    ReusableElevatedButton(
                      onPress: (){
                        FirebaseAuth.instance.signOut();
                      },
                      buttonText: 'Sign Out',fSize: fontSize,
                    ),
                    const SizedBox(height: 30),
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