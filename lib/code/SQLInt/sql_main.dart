// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:municipal_track/code/SQLApp/Auth/login_screen.dart';
// import 'package:municipal_track/code/SQLApp/fragments/dashboard_of_fragments_sql.dart';
// import 'package:municipal_track/code/SQLApp/userPreferences/user_preferences.dart';
//
//
// class SQLMain extends StatelessWidget {
//   const SQLMain({Key? key}) : super(key: key);
//
//   ///This would have been the new root of the app for sql integration. we are still using main.dart which has firebase login.
//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       title: 'Municipal Tracking Service',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.green,
//       ),
//       home: FutureBuilder(
//         future: RememberUserPrefs.readUserInfo(),
//         builder: (context, dataSnapshot){
//           //this snapshot data check makes sure to stay logged in everytime the app is opened if they have already logged in previously
//           if(dataSnapshot.data == null){
//             return LoginScreen();
//           } else {
//             return DashboardOfFragments();
//           }
//         },
//       ),
//     );
//   }
// }
