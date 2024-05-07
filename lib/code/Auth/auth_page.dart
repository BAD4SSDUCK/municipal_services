import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:municipal_services/code/Auth/auth_page.dart';
import 'package:municipal_services/code/login/login_page.dart';
import 'package:municipal_services/code/Login/register_page.dart';

import '../login/citizen_otp_page.dart';
import '../login/citizen_register_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {

  //initially show the login page
  bool showLoginPage = true;

  void toggleScreens(){
    setState(() {
      showLoginPage =! showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {

    ///The following is for email login version
    // if (showLoginPage){
    //   return LoginPage(showRegisterPage: toggleScreens);
    // } else {
    //   return RegisterPage(showLoginPage: toggleScreens);
    // }

    ///the following is for login using phone number and otp
    if (showLoginPage){
      return const RegisterScreen();
    } else {
      return const RegisterPasswordScreen();
    }
  }
}