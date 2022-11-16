import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:municipal_track/code/DisplayPages/maps.dart';
import 'package:municipal_track/code/MapTools/location_controller.dart';
import 'package:municipal_track/code/login/citizen_login_page.dart';
import 'package:municipal_track/code/login/login_page.dart';

import 'code/main_page.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(LocationController());
    return const GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainPage(),
    );

    ///startup any 3 of these pages, MainPage is for staff to use, Register is for citizens
    //     home: MapView(), MainPage(), RegisterScreen()

  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Municipal Tracking",
            style: TextStyle(
                color: Colors.black,
                fontSize: 28.0,
              fontWeight: FontWeight.bold,

            ),
          ),
          const Text(
            "Login to begin tracking",
            style: TextStyle(
              color: Colors.black,
              fontSize: 44.0,
              fontWeight: FontWeight.bold,

            ),
          ),
          const SizedBox(height: 44.0,),
          const TextField(
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: "User Email",
              prefixIcon: Icon(Icons.mail, color: Colors.black,),
            ),
          ),
          const SizedBox(height: 26.0,),
          const TextField(
            obscureText: true,
            decoration: InputDecoration(
              hintText: "User Password",
              prefixIcon: Icon(Icons.lock, color: Colors.black,),
            ),
          ),
          const SizedBox(height: 12.0,),
          const Text("Forgot your password?",
          style: TextStyle(color: Colors.blue),
          ),
          const SizedBox(height: 88.0,),
          Container(
            width: double.infinity,
            child: RawMaterialButton(
              fillColor: Color(0xFF0069FE),
              elevation: 0.0,
              padding: EdgeInsets.symmetric(vertical: 20.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0) ),
              onPressed: () {},
              child: Text("Login", style: TextStyle(color: Colors.white, fontSize: 18.0),),
            ),
          ),
          
        ],
      ),
    );
  }
}
