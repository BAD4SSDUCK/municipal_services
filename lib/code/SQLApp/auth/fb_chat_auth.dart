// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:municipal_tracker_msunduzi/code/Auth/auth_page.dart';
// import 'package:municipal_tracker_msunduzi/code/AuthGoogle/auth_page_google.dart';
// import 'package:municipal_tracker_msunduzi/code/Chat/chat_screen.dart';
// import 'package:municipal_tracker_msunduzi/code/login/login_page.dart';
// import 'package:municipal_tracker_msunduzi/code/DisplayPages/dashboard.dart';
//
// import 'fb_auth_page.dart';
//
// ///this page is for login check on users and will return the user to the chat screen or a login page if they are logged in to firebase or not.
//
// class FBChatAuth extends StatelessWidget {
//   const FBChatAuth({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//
//     return Scaffold(
//       body: StreamBuilder<User?>(
//         stream: FirebaseAuth.instance.authStateChanges(),
//         builder: (context, snapshot){
//           if (snapshot.hasData){
//             String passedID = user.phoneNumber!;
//             String? userName = FirebaseAuth.instance.currentUser!.phoneNumber;
//             print('The user name of the logged in person is $userName}');
//             String id = passedID;
//
//             return Chat(chatRoomId: id);
//           } else {
//             return FBAuthPage();
//           }
//         },
//       ),
//     );
//
//   }
// }
