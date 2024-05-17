import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:municipal_services/code/MapTools/location_controller.dart';
import 'package:municipal_services/code/SQLApp/auth/login_screen.dart';
import 'package:municipal_services/code/SQLApp/fragments/dashboard_of_fragments_sql.dart';
import 'package:municipal_services/code/SQLApp/fragments/home_frag_manager_screen.dart';
import 'package:municipal_services/code/SQLInt/sql_main.dart';
import 'package:municipal_services/code/login/citizen_otp_page.dart';
import 'package:municipal_services/code/login/login_page.dart';

import 'code/main_page.dart';


void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  MaterialApp(
    theme: ThemeData(
        primarySwatch: Colors.grey
    ),
  );

  ///Check what the app is running on
  if(defaultTargetPlatform == TargetPlatform.android){
    await Firebase.initializeApp();

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]).then((value) => runApp(const MyApp()));
  }else{
    await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCsOGfD-agV8u68pCfeCManNNoSs4csIbY",
          projectId: "municipal-tracker-msunduzi",
          storageBucket: "municipal-tracker-msunduzi.appspot.com",
          messagingSenderId: "183405317738",
          // appId: '1:183405317738:android:b5c51367f54dfd08790413',
          appId: "1:183405317738:web:05f6729dc81be7d4790413",
          measurementId: "G-3X7HM5HRHJ"
        )
    );

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]).then((value) => runApp(const MyApp()));
  }

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

  ///This sets the app orientation by default.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((value) => runApp(MyApp()));

  runApp(const MyApp());

  ///For the sql version the sql_main will call the SQLMain() StatelessWidget instead of the MyApp() StatelessWidget which is for the firebase version
  ///SQLMain(), For the sql version the sql_main will call the SQLMain() StatelessWidget.
  //runApp(const SQLMain());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(
      debugShowCheckedModeBanner: false,
      ///MainPage links to an auth state for logging in using the necessary firebase method.
      ///If already logged in user will be immediately directed to the firebase version dashboard
      home: MainPage(),

    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host,
          int port) => true;
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

///notification handler start
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  print('Handling a background message ${message.messageId}');
}
///notification handler end
