import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:municipal_track/code/MapTools/location_controller.dart';
import 'package:municipal_track/code/login/citizen_otp_page.dart';
import 'package:municipal_track/code/login/login_page.dart';

import 'code/main_page.dart';

///notification handler start
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  print('Handling a background message ${message.messageId}');
}
///notification handler end

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseMessaging.instance.getInitialMessage();

  ///notification section
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  ///notification section ended

  Get.put(LocationController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(
      debugShowCheckedModeBanner: false,
      ///MainPage links to an auth state for logging in using the necessary firebase method.
      home: MainPage(),
    );
  }
}

///notification channel init start
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  //'This channel is used for important notifications.', // description
  importance: Importance.high,
);
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();
///notification channel init end


///This login Screen is not used. This was just a template during initial dev using an email and password. MainPage() was used to auth using phone number and OTP to login
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