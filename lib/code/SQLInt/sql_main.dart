import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:municipal_track/code/Users/Auth/login_screen.dart';

class SQLMain extends StatelessWidget {
  const SQLMain({Key? key}) : super(key: key);

  ///This will be the new root of the app for sql integration
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Municipal Tracking Service',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: FutureBuilder(
        builder: (context, dataSnapshot){
          return LoginScreen();
        },
      ),
    );
  }
}
