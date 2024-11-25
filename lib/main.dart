import 'dart:io' as io;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/foundation.dart';
import 'package:municipal_services/code/Models/prop_provider.dart';
import 'package:provider/provider.dart';
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
import 'code/Models/notify_provider.dart';
import 'code/main_page.dart';
import 'package:flutter_downloader/flutter_downloader.dart';


void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  if (!foundation.kIsWeb && (io.Platform.isAndroid || io.Platform.isIOS)) {
    await FlutterDownloader.initialize(
      debug: true, // set false to disable printing logs to console
    );
  }

  MaterialApp(
    theme: ThemeData(
        primarySwatch: Colors.grey
    ),
  );

  ///Check what the app is running on
  if(defaultTargetPlatform == TargetPlatform.android){
    await Firebase.initializeApp();
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      sslEnabled: true,
      host: 'firestore.googleapis.com',
    );
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PropertyProvider>(create: (context) => PropertyProvider()),
        ChangeNotifierProvider<NotificationProvider>(create: (context) => NotificationProvider()),
      ],
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        home: MainPage(),
      ),
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
