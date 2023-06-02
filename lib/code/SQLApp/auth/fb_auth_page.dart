// import 'package:flutter/material.dart';
//
// import '../../login/citizen_register_page.dart';
// import 'chat_otp_page.dart';
//
// class FBAuthPage extends StatefulWidget {
//   const FBAuthPage({Key? key}) : super(key: key);
//
//   @override
//   State<FBAuthPage> createState() => _FBAuthPageState();
// }
//
// class _FBAuthPageState extends State<FBAuthPage> {
//
//   //initially show the login page
//   bool showLoginPage = true;
//
//   void toggleScreens(){
//     setState(() {
//       showLoginPage =! showLoginPage;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     ///the following is for login using phone number and otp
//     if (showLoginPage){
//       return ChatRegisterScreen();
//     } else {
//       return RegisterPasswordScreen();
//     }
//   }
// }