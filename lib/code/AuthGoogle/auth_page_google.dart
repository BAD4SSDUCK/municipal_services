import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:municipal_services/code/login/login_page_google.dart';
import 'package:municipal_services/main.dart';
import 'package:municipal_services/code/login/login_page.dart';

import '../DisplayPages/dashboard.dart';

///Auth service was made separately from original authpage. This covers authentication for only gmail auth only

class AuthService{

  handleAuthState(){
    return StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, snapshot){
          if (snapshot.hasData){
            return MainMenu();
          } else {
            return LoginPageG();
          }
        });
  }

  signInWithGoogle() async{
    final GoogleSignInAccount? googleUser = await GoogleSignIn(
        scopes: <String>["email"]).signIn();

    final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  signOut(){
    FirebaseAuth.instance.signOut();
  }
}