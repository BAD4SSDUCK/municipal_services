import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:municipal_tracker_msunduzi/code/NoticePages/notice_user_screen.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:municipal_tracker_msunduzi/main.dart';
import 'package:municipal_tracker_msunduzi/code/Chat/chat_screen.dart';
import 'package:municipal_tracker_msunduzi/code/DisplayPages/display_pdf_list.dart';
import 'package:municipal_tracker_msunduzi/code/ImageUploading/image_upload_fault.dart';
import 'package:municipal_tracker_msunduzi/code/PDFViewer/pdf_api.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/main_menu_reusable_button.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/nav_drawer.dart';
import 'package:municipal_tracker_msunduzi/code/faultPages/fault_report_screen.dart';
import 'package:municipal_tracker_msunduzi/code/Chat/chat_list.dart';
import 'package:municipal_tracker_msunduzi/code/MapTools/location_controller.dart';
import 'package:municipal_tracker_msunduzi/code/MapTools/map_screen.dart';
import 'package:municipal_tracker_msunduzi/code/PDFViewer/view_pdf.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/icon_elevated_button.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/menu_reusable_elevated_button.dart';
import 'package:municipal_tracker_msunduzi/code/DisplayPages/display_info.dart';
import 'package:municipal_tracker_msunduzi/code/DisplayPages/display_info_all_users.dart';
import 'package:table_calendar/table_calendar.dart';


class EventsCalendar extends StatefulWidget {
  const EventsCalendar({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() =>_EventsCalendarState();
  }

  class _EventsCalendarState extends State<EventsCalendar>{
  final user = FirebaseAuth.instance.currentUser!;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> events ={

  };



  final CollectionReference _propList =
  FirebaseFirestore.instance.collection('properties');

  @override
  void initState() {
    super.initState();
  }

  bool visShow = true;
  bool visHide = false;

  final CollectionReference _chatRoom =
  FirebaseFirestore.instance.collection('chatRoom');

  @override
  Widget build(BuildContext context) {
    return Container(
      ///When a background image is created this section will display it on the dashboard instead of just a grey colour with no background
      decoration: const BoxDecoration(
        image: DecorationImage(
            image: AssetImage("assets/images/greyscale.jpg"),
            fit: BoxFit.cover),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,//grey[350],
        appBar: AppBar(
          title:
          const Text('Event Calendar',style: TextStyle(color: Colors.white,fontSize: 19 ),),///${user.email!}
          backgroundColor: Colors.green,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        // drawer: const NavDrawer(),
        body: Column(
          children: [
            // TableCalendar(
            //   firstDay:
            //
            // ),
          ],
        ),
      ),
    );
  }

  ///pdf view loader getting file name onPress/onTap that passes filename to this class
  void openPDF(BuildContext context, File file) => Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
  );
}

class Event{
  final String title;
  Event(this.title);
}