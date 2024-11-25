import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:municipal_services/code/Reusable/menu_reusable_elevated_button.dart';
import 'package:municipal_services/code/EventsPages/display_events_calendar.dart';
import 'package:municipal_services/code/PDFViewer/view_pdf.dart';
import 'package:municipal_services/code/DisplayPages/councillor_screen.dart';

import '../Chat/chat_screen_councillors.dart';
import '../DisplayPages/city_directory.dart';
import '../EventsPages/municipal_calendar.dart';


class MunicipalNavDrawer extends StatelessWidget {
  final String municipalityId;
  final bool isLocalMunicipality;
  final bool isLocalUser;
  final String districtId;

  const MunicipalNavDrawer({
    super.key,
    required this.municipalityId,
    required this.isLocalMunicipality,
    required this.isLocalUser, required this.districtId,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[200],
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 80),
            Center(child: buildHeader(context)),
            const SizedBox(height: 50),
            buildMenuItems(context),
          ],
        ),
      ),
    );
  }

  Widget buildHeader(BuildContext context) => Container(
    decoration: const BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(20)),
      color: Colors.grey,
    ),
    child: Image.asset(
      'assets/images/municipal_services.png',
      height: 150,
      width: 290,
    ),
  );

  Widget buildMenuItems(BuildContext context) => Wrap(
    runSpacing: 10,
    runAlignment: WrapAlignment.end,
    children: <Widget>[
      const SizedBox(height: 20),
      ListTile(
        leading: const Icon(Icons.event, size: 40),
        title: Text(
          'Manage Events',
          style: GoogleFonts.turretRoad(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18.5,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MunicipalEventsCalendar(districtId: districtId, isLocalUser: isLocalUser, isLocalMunicipality: isLocalMunicipality,),
            ),
          );
        },
      ),
      // ListTile(
      //   leading: const Icon(Icons.people, size: 40),
      //   title: Text(
      //     'Municipal Directory',
      //     style: GoogleFonts.turretRoad(
      //       color: Colors.black,
      //       fontWeight: FontWeight.bold,
      //       fontSize: 18.5,
      //     ),
      //   ),
      //   onTap: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) => EmployeeDirectoryScreen(),
      //       ),
      //     );
      //   },
      // ),
      ListTile(
        leading: const Icon(Icons.lightbulb, size: 40,),
        title: Text('Load Shedding Schedule',
          style: GoogleFonts.turretRoad(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        onTap: () async {
          final Uri _url = Uri.parse('http://www.msunduzi.gov.za/site/search/downloadencode/LOAD%20SHEDDING%20SCHEDULE%20WORD%20STAGE%201%20-%204%20%205%20-%208%20update.pdf');
          // _launchURL(_url);
          _launchURLExternal(_url);
        },
      ),
      // Additional options specific to municipal users can go here
      const SizedBox(height: 80),
      ListTile(
        leading: const Icon(Icons.add_call, size: 20),
        title: Text(
          'Contact Municipality',
          style: GoogleFonts.montserrat(
            color: Colors.black,
            fontWeight: FontWeight.normal,
            fontSize: 15,
          ),
        ),
        onTap: () {
          final Uri tel = Uri.parse('tel:+27${0338976700}');
          launchUrl(tel);
        },
      ),
      ListTile(
        leading: const Icon(Icons.error, size: 20),
        title: Text(
          'Report a Bug',
          style: GoogleFonts.montserrat(
            color: Colors.black,
            fontWeight: FontWeight.normal,
            fontSize: 15,
          ),
        ),
        onTap: () {
          final Uri tel = Uri.parse('tel:+27${0333871974}');
          launchUrl(tel);
        },
      ),
      const SizedBox(height: 90),
      buildFooter(context),
    ],
  );

  Widget buildFooter(BuildContext context) => Column(
    children: [
      ListTile(
        leading: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Icon(Icons.label_important, size: 50),
        ),
        title: Text(
          'Cyberfox',
          style: GoogleFonts.saira(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        trailing: const Padding(
          padding: EdgeInsets.only(right: 15.0),
          child: Icon(Icons.copyright, size: 30),
        ),
        onTap: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: Image.asset(
          'assets/images/cyberfox_logo_small.png',
          height: 80,
          width: 120,
          fit: BoxFit.fitWidth,
        ),
      ),
    ],
  );
  _launchURLExternal(url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url,
          mode: LaunchMode.externalNonBrowserApplication);
    } else {
      throw 'Could not launch $url';
    }
  }
}
