import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:municipal_track/code/Auth/auth_page.dart';
import 'package:municipal_track/code/AuthGoogle/auth_page_google.dart';
import 'package:municipal_track/code/login/login_page.dart';
import 'package:municipal_track/code/DisplayPages/dashboard.dart';

///this page is for login check on users and will return the user to the main menu or a login page if they are logged in or not.

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    ///code for sign in using user created email and password
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot){
          if (snapshot.hasData){
            return MainMenu();
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
