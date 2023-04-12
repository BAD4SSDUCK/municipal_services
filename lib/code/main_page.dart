import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:municipal_track/code/Auth/auth_page.dart';
import 'package:municipal_track/code/AuthGoogle/auth_page_google.dart';
import 'package:municipal_track/code/DisplayPages/admin_dashboard_menu.dart';
import 'package:municipal_track/code/login/login_page.dart';
import 'package:municipal_track/code/DisplayPages/dashboard.dart';
import 'package:municipal_track/code/DisplayPages/dashboard_of_fragments.dart';

///this page is for login check on users and will return the user to the main menu or a login page if they are logged in or not.

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    ///code for sign in using user created email and password
    ///AuthPage determines the login type between email or phone number otp
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot){
          if (snapshot.hasData){
            final FirebaseAuth auth = FirebaseAuth.instance;
            final User? user = auth.currentUser;
            final uid = user?.uid;
            String userID = uid as String;
            if(user?.email?.isEmpty == false){
              return HomeManagerScreen();
            } else {
              return MainMenu();
            }
          } else {
            return AuthPage();
          }
        },
      ),
    );

    ///code for signing with users device google account with gmail
    // return MaterialApp(
    //   themeMode: ThemeMode.system,
    //   debugShowCheckedModeBanner: false,
    //   home: AuthService().handleAuthState(),
    // );

  }
}
