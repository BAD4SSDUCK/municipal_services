import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:getwidget/components/button/gf_icon_button.dart';
import 'package:getwidget/getwidget.dart';

import 'package:syncfusion_flutter_xlsio/xlsio.dart' as excel;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' show AnchorElement;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:municipal_services/code/MapTools/map_screen_prop.dart';
import 'package:municipal_services/code/PDFViewer/view_pdf.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';
import 'package:municipal_services/code/Reusable/push_notification_message.dart';
import 'package:municipal_services/code/NoticePages/notice_config_screen.dart';


class ReportBuilderFaults extends StatefulWidget {
  const ReportBuilderFaults({Key? key}) : super(key: key);

  @override
  _ReportBuilderFaultsState createState() => _ReportBuilderFaultsState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
// final storageRef = FirebaseStorage.instance.ref();

final User? user = auth.currentUser;
final uid = user?.uid;
final email = user?.email;
String userID = uid as String;
String userEmail = email as String;
DateTime now = DateTime.now();

String phoneNum = ' ';

String accountNumberAll = ' ';
String locationGivenAll = ' ';
String eMeterNumber = ' ';
String accountNumberW = ' ';
String locationGivenW = ' ';
String wMeterNumber = ' ';
String dateRange1 = ' ';
String dateRange2 = ' ';

String propPhoneNum = ' ';

bool visibilityState1 = true;
bool visibilityState2 = false;
bool adminAcc = false;
bool imgUploadCheck = false;

final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;

class FireStorageService extends ChangeNotifier{
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async{
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

class _ReportBuilderFaultsState extends State<ReportBuilderFaults> {

  @override
  void initState() {
    if(_searchController.text == ""){
      getFaultStream();
    }
    // getPropertyStream();
    checkAdmin();
    _searchController.addListener(_onSearchChanged);
    super.initState();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    searchText;
    _allFaultResults;
    _allFaultReport;
    super.dispose();
  }

  void checkAdmin() {
    getUsersStream();
    if(userRole == 'Admin'|| userRole == 'Administrator'){
      adminAcc = true;
    } else {
      adminAcc = false;
    }
  }

  getUsersStream() async{
    var data = await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      _allUserRolesResults = data.docs;
    });
    getUserDetails();
  }

  getUserDetails() async {
    for (var userSnapshot in _allUserRolesResults) {
      ///Need to build a property model that retrieves property data entirely from the db
      var user = userSnapshot['email'].toString();
      var role = userSnapshot['userRole'].toString();

      if (user == userEmail) {
        userRole = role;
        print('My Role is::: $userRole');

        if (userRole == 'Admin' || userRole == 'Administrator') {
          adminAcc = true;
        } else {
          adminAcc = false;
        }
      }
    }
  }

  String accountNumberRep = '';
  String locationGivenRep = '';
  int faultStage = 0;
  String reporterCellGiven = '';
  String searchText = '';

  String formattedDate = DateFormat.MMMM().format(now);
  String formattedDateTime = DateFormat('yyyy-MM-dd – kk:mm').format(now);
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  List<String> usersNumbers =[];
  List<String> usersTokens =[];
  List<String> usersRetrieve =[];

  ///Methods and implementation for push notifications with firebase and specific device token saving
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  TextEditingController username = TextEditingController();
  TextEditingController title = TextEditingController();
  TextEditingController body = TextEditingController();
  String? mtoken = " ";

  ///This was made for testing a default message
  String title2 = "Outstanding Utilities Payment";
  String body2 = "Make sure you pay utilities before the end of this month or your services will be disconnected";

  String token = '';
  String notifyToken = '';

  String userRole = '';
  List _allUserRolesResults = [];
  bool visShow = true;
  bool visHide = false;
  bool adminAcc = false;

  int numTokens=0;

  String dropdownValue = 'Select Month';
  List<String> dropdownMonths = ['Select Month','January','February','March','April','May','June','July','August','September','October','November','December'];

  TextEditingController _searchController = TextEditingController();
  List _allFaultResults = [];
  List _allFaultReport = [];

  getFaultStream() async{
    var data = await FirebaseFirestore.instance.collection('faultReporting').get();

    CollectionReference collection = FirebaseFirestore.instance.collection('faultReporting');

    DateTime dateParseString = DateTime.parse(formattedDateTime);
    DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.parse(formattedDateTime));

    if(startDate != dateParseString){
      _allFaultResults = [];

      QuerySnapshot querySnapshot = await collection
          .where('dateReported', isGreaterThanOrEqualTo: startDate.toUtc())
          .where('dateReported', isLessThanOrEqualTo: endDate.toUtc())
          .get();

      List<DocumentSnapshot> documents = querySnapshot.docs;
      setState(() {
        _allFaultResults = documents;
      });
    } else {
      setState(() {
        _allFaultResults = data.docs;
      });
    }

    searchResultsList();
  }

  _onSearchChanged() async {
    searchResultsList();
  }

  searchResultsList() async {
    var showResults = [];
    if(_searchController.text != "") {
      getFaultStream();
      for(var faultSnapshot in _allFaultResults){
        ///Need to build a property model that retrieves property data entirely from the db
        var reference = faultSnapshot['ref'].toString().toLowerCase();

        if(reference.contains(_searchController.text.toLowerCase())) {
          showResults.add(faultSnapshot);
        }
      }
    } else {
      getFaultStream();
      showResults = List.from(_allFaultResults);
    }
    setState(() {
      _allFaultResults = showResults;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Fault Report Generator',style: TextStyle(color: Colors.white),),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.green,
        actions: <Widget>[
          Visibility(
            visible: false,
            child: IconButton(
                onPressed: (){
                  ///Generate Report here
                  showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("Generate Live Report"),
                          content: const Text("Generating a report will go through all properties and build an excel Spreadsheet!\n\nThis process will take time based on your internet speed.\n\nAre you ready to proceed? This may take a few minutes."),
                          actions: [
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.cancel, color: Colors.red,),
                            ),
                            IconButton(
                              onPressed: () async {
                                Fluttertoast.showToast(msg: "Now generating report\nPlease wait till prompted to open Spreadsheet!");
                                reportGeneration();
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.done, color: Colors.green,),
                            ),
                          ],
                        );
                      });
                },
                icon: const Icon(Icons.file_copy_outlined, color: Colors.white,)),),
        ],
      ),
      body: Column(
        children: [
          ///For date range entry
          Padding(
            padding: const EdgeInsets.fromLTRB(10.0,10.0,10.0,0.0),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10.0,10.0,10.0,10.0),
              decoration: const BoxDecoration(shape: BoxShape.rectangle, color: Colors.white,),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          ).then((pickedDate) {
                            if (pickedDate != null && pickedDate != startDate) {
                              setState(() {
                                startDate = pickedDate;
                              });
                            }
                          });
                        },
                        child: const Text('Start Date'),
                      ),

                      ElevatedButton(
                        onPressed: () {
                          showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          ).then((pickedDate) {
                            if (pickedDate != null && pickedDate != endDate) {
                              setState(() {
                                endDate = pickedDate;
                              });
                            }
                          });
                        },
                        child: const Text('End Date'),
                      ),

                    ],
                  ),
                  const SizedBox(height: 10,),
                  Center(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 25),
                                child: Text(
                                  "${startDate.toLocal()}".split(' ')[0],
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 25),
                                child: Text(
                                  "${endDate.toLocal()}".split(' ')[0],
                                  style: const TextStyle(fontSize: 18,),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10,),
                  ElevatedButton(
                    onPressed: () {
                      dateRange1 = startDate.toString();
                      dateRange2 = endDate.toString();

                      DateTime dateTimeString1 = DateTime.parse(dateRange1);

                      showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Generate Live Report"),
                              content: const Text("Generating a report will go through all faults filtered between the start and end dates you have given.\n\nAre you ready to proceed? This may take some time."),
                              actions: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.cancel, color: Colors.red,),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    Fluttertoast.showToast(msg: "Now generating report\nPlease wait till prompted to open Spreadsheet!");
                                    reportGeneration();
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.done, color: Colors.green,),
                                ),
                              ],
                            );
                          });

                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, fixedSize: const Size(200, 40),),
                    child: Row(
                      children: [
                        Icon(Icons.bar_chart, color: Colors.grey[700],),
                        const SizedBox(width: 2,),
                        const Text(
                          'Generate Report', style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,),),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(10.0,10.0,10.0,10.0),
            child: SearchBar(
              controller: _searchController,
              padding: const MaterialStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(horizontal: 16.0)),
              leading: const Icon(Icons.search),
              hintText: "Search by Reference Number...",
              onChanged: (value) async{
                setState(() {
                  searchText = value;
                  // print('this is the input text ::: $searchText');
                });
              },
            ),
          ),
          /// Search bar end

          Expanded(child: faultCard(),),

          const SizedBox(height: 5,),
        ],
      ),

        floatingActionButton: FloatingActionButton(
          onPressed: () => {
            ///Generate Report here
            showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Generate Live Report"),
                    content: const Text(
                        "Generating a report will go through all properties and build an excel Spreadsheet!\n\nThis process will take time based on your internet speed.\n\nAre you ready to proceed? This may take a few minutes."),
                    actions: [
                      Center(
                        child: Column(
                          children: [
                            BasicIconButtonGrey(
                              onPress: () {
                                Navigator.pop(context);
                              },
                              labelText: "Cancel", fSize: 12, faIcon: const FaIcon(Icons.cancel), fgColor: Colors.red, btSize: const Size(50,10),
                            ),
                            BasicIconButtonGrey(
                              onPress: () async {
                                Fluttertoast.showToast(
                                    msg: "Now generating report\nPlease wait till prompted to open Spreadsheet!");
                                reportGenerationWaste();
                                Navigator.pop(context);
                              },
                              labelText: "Roadworks", fSize: 12, faIcon: const FaIcon(Icons.add_road), fgColor: Colors.black54, btSize: const Size(50,10),
                            ),
                            BasicIconButtonGrey(
                              onPress: () async {
                                Fluttertoast.showToast(
                                    msg: "Now generating report\nPlease wait till prompted to open Spreadsheet!");
                                reportGenerationWaste();
                                Navigator.pop(context);
                              },
                              labelText: "Waste Management", fSize: 12, faIcon: const FaIcon(Icons.recycling), fgColor: Colors.brown, btSize: const Size(50,10),
                            ),
                            BasicIconButtonGrey(
                              onPress: () async {
                                Fluttertoast.showToast(
                                    msg: "Now generating report\nPlease wait till prompted to open Spreadsheet!");
                                reportGenerationWater();
                                Navigator.pop(context);
                              },
                              labelText: "Water & Sanitation", fSize: 12, faIcon: const FaIcon(Icons.water_drop_outlined), fgColor: Colors.blue, btSize: const Size(50,10),
                            ),
                            BasicIconButtonGrey(
                              onPress: () async {
                                Fluttertoast.showToast(
                                    msg: "Now generating report\nPlease wait till prompted to open Spreadsheet!");
                                reportGenerationElectricity();
                                Navigator.pop(context);
                              },
                              labelText: "Electricity", fSize: 12, faIcon: const FaIcon(Icons.power), fgColor: Colors.yellow, btSize: const Size(50,10),
                            ),
                            BasicIconButtonGrey(
                              onPress: () async {
                                Fluttertoast.showToast(
                                    msg: "Now generating report\nPlease wait till prompted to open Spreadsheet!");
                                reportGeneration();
                                Navigator.pop(context);
                              },
                              labelText: "All", fSize: 12, faIcon: const FaIcon(Icons.check_circle), fgColor: Colors.green, btSize: const Size(50,10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                })
          },
          backgroundColor: Colors.green,
          child: const Icon(Icons.file_copy_outlined, color: Colors.white,),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat

    );
  }

  Widget faultCard(){
    if (_allFaultResults.isNotEmpty) {
      return ListView.builder(
        itemCount: _allFaultResults.length,
        itemBuilder: (context, index) {
          String status;
          if (_allFaultResults[index]['faultResolved'] == false) {
            status = "Pending";
          } else {
            status = "Completed";
          }

          return Card(
              margin: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Fault Information',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10,),
                    Text(
                      'Reference Number: ${_allFaultResults[index]['ref']}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 5,),
                    Column(
                      children: [
                        if(_allFaultResults[index]['accountNumber'] != "")...[
                          Text(
                            'Reporter Account Number: ${_allFaultResults[index]['accountNumber']}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                        ] else
                          ...[
                          ],
                      ],
                    ),
                    Text(
                      'Street Address of Fault: ${_allFaultResults[index]['address']}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 5,),
                    Text(
                      'Date of Fault Report: ${_allFaultResults[index]['dateReported']}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 5,),
                    Column(
                      children: [
                        if(_allFaultResults[index]['faultStage'] == 1)...[
                          Text(
                            'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.deepOrange),
                          ),
                          const SizedBox(height: 5,),
                        ] else
                          if(_allFaultResults[index]['faultStage'] == 2) ...[
                            Text(
                              'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.orange),
                            ),
                            const SizedBox(height: 5,),
                          ] else
                            if(_allFaultResults[index]['faultStage'] == 3) ...[
                              Text(
                                'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.orangeAccent),
                              ),
                              const SizedBox(height: 5,),
                            ] else
                              if(_allFaultResults[index]['faultStage'] == 4) ...[
                                Text(
                                  'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.greenAccent),
                                ),
                                const SizedBox(height: 5,),
                              ] else
                                if(_allFaultResults[index]['faultStage'] == 5) ...[
                                  Text(
                                    'Fault Stage: ${_allFaultResults[index]['faultStage'].toString()}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.lightGreen),
                                  ),
                                  const SizedBox(height: 5,),
                                ] else
                                  ...[
                                  ],
                      ],
                    ),
                    Text(
                      'Fault Type: ${_allFaultResults[index]['faultType']}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 5,),
                    Column(
                      children: [
                        if(_allFaultResults[index]['faultDescription'] != "")...[
                          Text(
                            'Fault Description: ${_allFaultResults[index]['faultDescription']}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                        ] else
                          ...[
                          ],
                      ],
                    ),
                    Column(
                      children: [
                        if(_allFaultResults[index]['adminComment'] != "")...[
                          Text(
                            'Admin Comment: ${_allFaultResults[index]['adminComment']}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                        ] else
                          ...[
                          ],
                      ],
                    ),
                    Column(
                      children: [
                        if(_allFaultResults[index]['reallocationComment'] != "")...[
                          Text(
                            'Reason fault reallocated: ${_allFaultResults[index]['reallocationComment']}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                        ] else
                          ...[
                          ],
                      ],
                    ),
                    Column(
                      children: [
                        if(_allFaultResults[index]['managerAllocated'] != "")...[
                          Text(
                            'Manager of fault: ${_allFaultResults[index]['managerAllocated']}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                        ] else
                          ...[
                          ],
                      ],
                    ),

                    Column(
                      children: [
                        if(_allFaultResults[index]['attendeeAllocated'] != "")...[
                          Text(
                            'Attendee Allocated: ${_allFaultResults[index]['attendeeAllocated']}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                        ] else
                          ...[
                          ],
                      ],
                    ),
                    Column(
                      children: [
                        if(_allFaultResults[index]['attendeeCom1'] != "")...[
                          Text(
                            'Attendee Comment: ${_allFaultResults[index]['attendeeCom1']}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                        ] else
                          ...[
                          ],
                      ],
                    ),
                    Column(
                      children: [
                        if(_allFaultResults[index]['managerCom1'] != "")...[
                          Text(
                            'Manager Comment: ${_allFaultResults[index]['managerCom1']}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                        ] else
                          ...[
                          ],
                      ],
                    ),
                    Column(
                      children: [
                        if(_allFaultResults[index]['attendeeCom2'] != "")...[
                          Text(
                            'Attendee Followup Comment: ${_allFaultResults[index]['attendeeCom2']}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                        ] else
                          ...[
                          ],
                      ],
                    ),
                    Column(
                      children: [
                        if(_allFaultResults[index]['managerCom2'] != "")...[
                          Text(
                            'Manager Final/Additional Comment: ${_allFaultResults[index]['managerCom2']}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                        ] else
                          ...[
                          ],
                      ],
                    ),
                    Column(
                      children: [
                        if(_allFaultResults[index]['attendeeCom3'] != "")...[
                          Text(
                            'Attendee Final Comment: ${_allFaultResults[index]['attendeeCom3']}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                        ] else
                          ...[
                          ],
                      ],
                    ),
                    Column(
                      children: [
                        if(_allFaultResults[index]['managerCom3'] != "")...[
                          Text(
                            'Manager Final Comment: ${_allFaultResults[index]['managerCom3']}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                        ] else
                          ...[
                          ],
                      ],
                    ),
                    Text(
                      'Resolve State: $status',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 20,),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                accountNumberRep =
                                _allFaultResults[index]['accountNumber'];
                                locationGivenRep =
                                _allFaultResults[index]['address'];

                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) =>
                                        MapScreenProp(
                                          propAddress: locationGivenRep,
                                          propAccNumber: accountNumberRep,)
                                    ));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[350],
                                fixedSize: const Size(140, 10),),
                              child: Row(
                                children: [
                                  Icon(Icons.map, color: Colors.green[700],),
                                  const SizedBox(width: 2,),
                                  const Text(
                                    'Location', style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,),),
                                ],
                              ),
                            ),
                            const SizedBox(width: 5,),
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (context) {
                                      return
                                        AlertDialog(
                                          shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(16))),
                                          title: const Text("Call Reporter!"),
                                          content: const Text(
                                              "Would you like to call the individual who logged the fault?"),
                                          actions: [
                                            IconButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              icon: const Icon(
                                                Icons.cancel, color: Colors.red,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                reporterCellGiven =
                                                _allFaultResults[index]['reporterContact'];

                                                final Uri _tel = Uri.parse(
                                                    'tel:${reporterCellGiven
                                                        .toString()}');
                                                launchUrl(_tel);

                                                Navigator.of(context).pop();
                                              },
                                              icon: const Icon(Icons.done,
                                                color: Colors.green,),
                                            ),
                                          ],
                                        );
                                    });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[350],
                                fixedSize: const Size(140, 10),),
                              child: Row(
                                children: [
                                  Icon(Icons.call, color: Colors.orange[700],),
                                  const SizedBox(width: 2,),
                                  const Text('Call User', style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,),),
                                ],
                              ),
                            ),
                            const SizedBox(width: 5,),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
        },
      );
    }
    return const Padding(
      padding: EdgeInsets.all(10.0),
      child: Center(
          child: CircularProgressIndicator()),
    );

  }

  Future<void> reportGeneration() async {
    final excel.Workbook workbook = excel.Workbook();
    final excel.Worksheet sheet = workbook.worksheets[0];

    var data = await FirebaseFirestore.instance.collection('faultReporting').get();

    _allFaultReport = data.docs;

    String column = "A";
    int excelRow = 2;
    int listRow = 0;

    sheet.getRangeByName('A1').setText('Ref #');
    sheet.getRangeByName('B1').setText('Resolve Status');
    sheet.getRangeByName('C1').setText('Fault Type');
    sheet.getRangeByName('D1').setText('Account #');
    sheet.getRangeByName('E1').setText('Address');
    sheet.getRangeByName('F1').setText('Report Date');
    sheet.getRangeByName('G1').setText('Department Allocated');
    sheet.getRangeByName('H1').setText('Fault Description');
    sheet.getRangeByName('I1').setText('Fault Stage');
    sheet.getRangeByName('J1').setText('Reporters Phone Number');
    sheet.getRangeByName('K1').setText('Attendee Allocated');
    sheet.getRangeByName('L1').setText('Manager Allocated');
    sheet.getRangeByName('M1').setText('Admin Comment');
    sheet.getRangeByName('N1').setText('Attendee Com1');
    sheet.getRangeByName('O1').setText('Manager Com1');
    sheet.getRangeByName('P1').setText('Attendee Com2');
    sheet.getRangeByName('Q1').setText('Manager Com2');
    sheet.getRangeByName('R1').setText('Attendee Com3');
    sheet.getRangeByName('S1').setText('Manager Com3');
    sheet.getRangeByName('T1').setText('Department SwitchComment');
    sheet.getRangeByName('U1').setText('Reallocation Comment');
    sheet.getRangeByName('V1').setText('Manager ReturnCom');
    sheet.getRangeByName('W1').setText('Attendee ReturnCom');

    for(var reportSnapshot in _allFaultReport){
      ///Need to build a property model that retrieves property data entirely from the db
      while(excelRow <= _allFaultReport.length+1) {
        print('Report Lists:::: ${_allFaultReport[listRow]['address']}');
        
        // if(_allFaultReport[listRow]['dateReported'].toString().contains(dateRange1)){
        //   String referenceNum      = _allFaultReport[listRow]['ref'].toString();
        //   String resolveStatus     = _allFaultReport[listRow]['faultResolved'].toString();
        //   String faultType         = _allFaultReport[listRow]['faultType'].toString();
        //   String accountNum        = _allFaultReport[listRow]['accountNumber'].toString();
        //   String address           = _allFaultReport[listRow]['address'].toString();
        //   String faultDate         = _allFaultReport[listRow]['dateReported'].toString();
        //   String depAllocated      = _allFaultReport[listRow]['depAllocated'].toString();
        //   String faultDescription  = _allFaultReport[listRow]['faultDescription'].toString();
        //   String faultStage        = _allFaultReport[listRow]['faultStage'].toString();
        //   String phoneNumber       = _allFaultReport[listRow]['reporterContact'].toString();
        //   String attendeeAlloc     = _allFaultReport[listRow]['attendeeAllocated'].toString();
        //   String managerAlloc      = _allFaultReport[listRow]['managerAllocated'].toString();
        //   String adminCom          = _allFaultReport[listRow]['adminComment'].toString();
        //   String attendeeCom1      = _allFaultReport[listRow]['attendeeCom1'].toString();
        //   String managerCom1       = _allFaultReport[listRow]['managerCom1'].toString();
        //   String attendeeCom2      = _allFaultReport[listRow]['attendeeCom2'].toString();
        //   String managerCom2       = _allFaultReport[listRow]['managerCom2'].toString();
        //   String attendeeCom3      = _allFaultReport[listRow]['attendeeCom3'].toString();
        //   String managerCom3       = _allFaultReport[listRow]['managerCom3'].toString();
        //   String deptSwitchCom     = _allFaultReport[listRow]['departmentSwitchComment'].toString();
        //   String reallocCom        = _allFaultReport[listRow]['reallocationComment'].toString();
        //   String managerReturnCom  = _allFaultReport[listRow]['managerReturnCom'].toString();
        //   String attendeeReturnCom = _allFaultReport[listRow]['attendeeReturnCom'].toString();
        //
        //   sheet.getRangeByName('A$excelRow').setText(referenceNum);
        //   sheet.getRangeByName('B$excelRow').setText(resolveStatus);
        //   sheet.getRangeByName('C$excelRow').setText(faultType);
        //   sheet.getRangeByName('D$excelRow').setText(accountNum);
        //   sheet.getRangeByName('E$excelRow').setText(address);
        //   sheet.getRangeByName('F$excelRow').setText(faultDate);
        //   sheet.getRangeByName('G$excelRow').setText(depAllocated);
        //   sheet.getRangeByName('H$excelRow').setText(faultDescription);
        //   sheet.getRangeByName('I$excelRow').setText(faultStage);
        //   sheet.getRangeByName('J$excelRow').setText(phoneNumber);
        //   sheet.getRangeByName('K$excelRow').setText(attendeeAlloc);
        //   sheet.getRangeByName('L$excelRow').setText(managerAlloc);
        //   sheet.getRangeByName('M$excelRow').setText(adminCom);
        //   sheet.getRangeByName('N$excelRow').setText(attendeeCom1);
        //   sheet.getRangeByName('O$excelRow').setText(managerCom1);
        //   sheet.getRangeByName('P$excelRow').setText(attendeeCom2);
        //   sheet.getRangeByName('Q$excelRow').setText(managerCom2);
        //   sheet.getRangeByName('R$excelRow').setText(attendeeCom3);
        //   sheet.getRangeByName('S$excelRow').setText(managerCom3);
        //   sheet.getRangeByName('T$excelRow').setText(deptSwitchCom);
        //   sheet.getRangeByName('U$excelRow').setText(reallocCom);
        //   sheet.getRangeByName('V$excelRow').setText(managerReturnCom);
        //   sheet.getRangeByName('W$excelRow').setText(attendeeReturnCom);
        //
        //   excelRow+=1;
        //   listRow+=1;
        // }

        String referenceNum      = _allFaultReport[listRow]['ref'].toString();
        String resolveStatus     = _allFaultReport[listRow]['faultResolved'].toString();
        String faultType         = _allFaultReport[listRow]['faultType'].toString();
        String accountNum        = _allFaultReport[listRow]['accountNumber'].toString();
        String address           = _allFaultReport[listRow]['address'].toString();
        String faultDate         = _allFaultReport[listRow]['dateReported'].toString();
        String depAllocated      = _allFaultReport[listRow]['depAllocated'].toString();
        String faultDescription  = _allFaultReport[listRow]['faultDescription'].toString();
        String faultStage        = _allFaultReport[listRow]['faultStage'].toString();
        String phoneNumber       = _allFaultReport[listRow]['reporterContact'].toString();
        String attendeeAlloc     = _allFaultReport[listRow]['attendeeAllocated'].toString();
        String managerAlloc      = _allFaultReport[listRow]['managerAllocated'].toString();
        String adminCom          = _allFaultReport[listRow]['adminComment'].toString();
        String attendeeCom1      = _allFaultReport[listRow]['attendeeCom1'].toString();
        String managerCom1       = _allFaultReport[listRow]['managerCom1'].toString();
        String attendeeCom2      = _allFaultReport[listRow]['attendeeCom2'].toString();
        String managerCom2       = _allFaultReport[listRow]['managerCom2'].toString();
        String attendeeCom3      = _allFaultReport[listRow]['attendeeCom3'].toString();
        String managerCom3       = _allFaultReport[listRow]['managerCom3'].toString();
        String deptSwitchCom     = _allFaultReport[listRow]['departmentSwitchComment'].toString();
        String reallocCom        = _allFaultReport[listRow]['reallocationComment'].toString();
        String managerReturnCom  = _allFaultReport[listRow]['managerReturnCom'].toString();
        String attendeeReturnCom = _allFaultReport[listRow]['attendeeReturnCom'].toString();

        sheet.getRangeByName('A$excelRow').setText(referenceNum);
        sheet.getRangeByName('B$excelRow').setText(resolveStatus);
        sheet.getRangeByName('C$excelRow').setText(faultType);
        sheet.getRangeByName('D$excelRow').setText(accountNum);
        sheet.getRangeByName('E$excelRow').setText(address);
        sheet.getRangeByName('F$excelRow').setText(faultDate);
        sheet.getRangeByName('G$excelRow').setText(depAllocated);
        sheet.getRangeByName('H$excelRow').setText(faultDescription);
        sheet.getRangeByName('I$excelRow').setText(faultStage);
        sheet.getRangeByName('J$excelRow').setText(phoneNumber);
        sheet.getRangeByName('K$excelRow').setText(attendeeAlloc);
        sheet.getRangeByName('L$excelRow').setText(managerAlloc);
        sheet.getRangeByName('M$excelRow').setText(adminCom);
        sheet.getRangeByName('N$excelRow').setText(attendeeCom1);
        sheet.getRangeByName('O$excelRow').setText(managerCom1);
        sheet.getRangeByName('P$excelRow').setText(attendeeCom2);
        sheet.getRangeByName('Q$excelRow').setText(managerCom2);
        sheet.getRangeByName('R$excelRow').setText(attendeeCom3);
        sheet.getRangeByName('S$excelRow').setText(managerCom3);
        sheet.getRangeByName('T$excelRow').setText(deptSwitchCom);
        sheet.getRangeByName('U$excelRow').setText(reallocCom);
        sheet.getRangeByName('V$excelRow').setText(managerReturnCom);
        sheet.getRangeByName('W$excelRow').setText(attendeeReturnCom);

        excelRow+=1;
        listRow+=1;
      }
    }

    final List<int> bytes = workbook.saveAsStream();

    if(kIsWeb){
      AnchorElement(href: 'data:application/ocelot-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
          ..setAttribute('download', 'Msunduzi Faults Report $formattedDate.xlsx')
          ..click();

    } else {
      final String path = (await getApplicationSupportDirectory()).path;
      final String filename = Platform.isWindows ? '$path\\Msunduzi Faults Report $formattedDate.xlsx' : '$path/Msunduzi Faults Report $formattedDate.xlsx';
      final File file = File(filename);
      final List<int> bytes = workbook.saveAsStream();
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open('$path/Msunduzi Faults Report $formattedDate.xlsx');
    }

    workbook.dispose();

  }

  Future<void> reportGenerationElectricity() async {
    final excel.Workbook workbook = excel.Workbook();
    final excel.Worksheet sheet = workbook.worksheets[0];

    var data = await FirebaseFirestore.instance.collection('faultReporting').get();

    _allFaultReport = data.docs;

    String column = "A";
    int excelRowFill = 2;
    int excelRow = 2;
    int listRow = 0;

    sheet.getRangeByName('A1').setText('Ref #');
    sheet.getRangeByName('B1').setText('Resolve Status');
    sheet.getRangeByName('C1').setText('Fault Type');
    sheet.getRangeByName('D1').setText('Account #');
    sheet.getRangeByName('E1').setText('Address');
    sheet.getRangeByName('F1').setText('Report Date');
    sheet.getRangeByName('G1').setText('Department Allocated');
    sheet.getRangeByName('H1').setText('Fault Description');
    sheet.getRangeByName('I1').setText('Fault Stage');
    sheet.getRangeByName('J1').setText('Reporters Phone Number');
    sheet.getRangeByName('K1').setText('Attendee Allocated');
    sheet.getRangeByName('L1').setText('Manager Allocated');
    sheet.getRangeByName('M1').setText('Admin Comment');
    sheet.getRangeByName('N1').setText('Attendee Com1');
    sheet.getRangeByName('O1').setText('Manager Com1');
    sheet.getRangeByName('P1').setText('Attendee Com2');
    sheet.getRangeByName('Q1').setText('Manager Com2');
    sheet.getRangeByName('R1').setText('Attendee Com3');
    sheet.getRangeByName('S1').setText('Manager Com3');
    sheet.getRangeByName('T1').setText('Department SwitchComment');
    sheet.getRangeByName('U1').setText('Reallocation Comment');
    sheet.getRangeByName('V1').setText('Manager ReturnCom');
    sheet.getRangeByName('W1').setText('Attendee ReturnCom');

      for (var reportSnapshot in _allFaultReport) {
        ///Need to build a property model that retrieves property data entirely from the db
        while (excelRow <= _allFaultReport.length + 1) {
          if (_allFaultReport[listRow]['faultType'].toString() == 'Electricity') {

            print('Report Lists:::: ${_allFaultReport[listRow]['address']}');

            String referenceNum      = _allFaultReport[listRow]['ref'].toString();
            String resolveStatus     = _allFaultReport[listRow]['faultResolved'].toString();
            String faultType         = _allFaultReport[listRow]['faultType'].toString();
            String accountNum        = _allFaultReport[listRow]['accountNumber'].toString();
            String address           = _allFaultReport[listRow]['address'].toString();
            String faultDate         = _allFaultReport[listRow]['dateReported'].toString();
            String depAllocated      = _allFaultReport[listRow]['depAllocated'].toString();
            String faultDescription  = _allFaultReport[listRow]['faultDescription'].toString();
            String faultStage        = _allFaultReport[listRow]['faultStage'].toString();
            String phoneNumber       = _allFaultReport[listRow]['reporterContact'].toString();
            String attendeeAlloc     = _allFaultReport[listRow]['attendeeAllocated'].toString();
            String managerAlloc      = _allFaultReport[listRow]['managerAllocated'].toString();
            String adminCom          = _allFaultReport[listRow]['adminComment'].toString();
            String attendeeCom1      = _allFaultReport[listRow]['attendeeCom1'].toString();
            String managerCom1       = _allFaultReport[listRow]['managerCom1'].toString();
            String attendeeCom2      = _allFaultReport[listRow]['attendeeCom2'].toString();
            String managerCom2       = _allFaultReport[listRow]['managerCom2'].toString();
            String attendeeCom3      = _allFaultReport[listRow]['attendeeCom3'].toString();
            String managerCom3       = _allFaultReport[listRow]['managerCom3'].toString();
            String deptSwitchCom     = _allFaultReport[listRow]['departmentSwitchComment'].toString();
            String reallocCom        = _allFaultReport[listRow]['reallocationComment'].toString();
            String managerReturnCom  = _allFaultReport[listRow]['managerReturnCom'].toString();
            String attendeeReturnCom = _allFaultReport[listRow]['attendeeReturnCom'].toString();

            sheet.getRangeByName('A$excelRowFill').setText(referenceNum);
            sheet.getRangeByName('B$excelRowFill').setText(resolveStatus);
            sheet.getRangeByName('C$excelRowFill').setText(faultType);
            sheet.getRangeByName('D$excelRowFill').setText(accountNum);
            sheet.getRangeByName('E$excelRowFill').setText(address);
            sheet.getRangeByName('F$excelRowFill').setText(faultDate);
            sheet.getRangeByName('G$excelRowFill').setText(depAllocated);
            sheet.getRangeByName('H$excelRowFill').setText(faultDescription);
            sheet.getRangeByName('I$excelRowFill').setText(faultStage);
            sheet.getRangeByName('J$excelRowFill').setText(phoneNumber);
            sheet.getRangeByName('K$excelRowFill').setText(attendeeAlloc);
            sheet.getRangeByName('L$excelRowFill').setText(managerAlloc);
            sheet.getRangeByName('M$excelRowFill').setText(adminCom);
            sheet.getRangeByName('N$excelRowFill').setText(attendeeCom1);
            sheet.getRangeByName('O$excelRowFill').setText(managerCom1);
            sheet.getRangeByName('P$excelRowFill').setText(attendeeCom2);
            sheet.getRangeByName('Q$excelRowFill').setText(managerCom2);
            sheet.getRangeByName('R$excelRowFill').setText(attendeeCom3);
            sheet.getRangeByName('S$excelRowFill').setText(managerCom3);
            sheet.getRangeByName('T$excelRowFill').setText(deptSwitchCom);
            sheet.getRangeByName('U$excelRowFill').setText(reallocCom);
            sheet.getRangeByName('V$excelRowFill').setText(managerReturnCom);
            sheet.getRangeByName('W$excelRowFill').setText(attendeeReturnCom);

            excelRowFill += 1;
            excelRow += 1;
            listRow += 1;
          } else {
            // excelRow += 1;
            listRow += 1;
          }
      }
    }

    final List<int> bytes = workbook.saveAsStream();

    if(kIsWeb){
      AnchorElement(href: 'data:application/ocelot-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
          ..setAttribute('download', 'Msunduzi Faults Electricity Report $formattedDate.xlsx')
          ..click();

    } else {
      final String path = (await getApplicationSupportDirectory()).path;
      final String filename = Platform.isWindows ? '$path\\Msunduzi Faults Electricity Report $formattedDate.xlsx' : '$path/Msunduzi Faults Electricity Report $formattedDate.xlsx';
      final File file = File(filename);
      final List<int> bytes = workbook.saveAsStream();
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open('$path/Msunduzi Faults Electricity Report $formattedDate.xlsx');
    }

    workbook.dispose();

  }

  Future<void> reportGenerationWater() async {
    final excel.Workbook workbook = excel.Workbook();
    final excel.Worksheet sheet = workbook.worksheets[0];

    var data = await FirebaseFirestore.instance.collection('faultReporting').get();

    _allFaultReport = data.docs;

    String column = "A";
    int excelRowFill = 2;
    int excelRow = 2;
    int listRow = 0;

    sheet.getRangeByName('A1').setText('Ref #');
    sheet.getRangeByName('B1').setText('Resolve Status');
    sheet.getRangeByName('C1').setText('Fault Type');
    sheet.getRangeByName('D1').setText('Account #');
    sheet.getRangeByName('E1').setText('Address');
    sheet.getRangeByName('F1').setText('Report Date');
    sheet.getRangeByName('G1').setText('Department Allocated');
    sheet.getRangeByName('H1').setText('Fault Description');
    sheet.getRangeByName('I1').setText('Fault Stage');
    sheet.getRangeByName('J1').setText('Reporters Phone Number');
    sheet.getRangeByName('K1').setText('Attendee Allocated');
    sheet.getRangeByName('L1').setText('Manager Allocated');
    sheet.getRangeByName('M1').setText('Admin Comment');
    sheet.getRangeByName('N1').setText('Attendee Com1');
    sheet.getRangeByName('O1').setText('Manager Com1');
    sheet.getRangeByName('P1').setText('Attendee Com2');
    sheet.getRangeByName('Q1').setText('Manager Com2');
    sheet.getRangeByName('R1').setText('Attendee Com3');
    sheet.getRangeByName('S1').setText('Manager Com3');
    sheet.getRangeByName('T1').setText('Department SwitchComment');
    sheet.getRangeByName('U1').setText('Reallocation Comment');
    sheet.getRangeByName('V1').setText('Manager ReturnCom');
    sheet.getRangeByName('W1').setText('Attendee ReturnCom');

    for (var reportSnapshot in _allFaultReport) {
      ///Need to build a property model that retrieves property data entirely from the db
      while (excelRow <= _allFaultReport.length + 1) {
        if (_allFaultReport[listRow]['faultType'].toString() == 'Water & Sanitation') {

            print('Report Lists:::: ${_allFaultReport[listRow]['address']}');

            String referenceNum      = _allFaultReport[listRow]['ref'].toString();
            String resolveStatus     = _allFaultReport[listRow]['faultResolved'].toString();
            String faultType         = _allFaultReport[listRow]['faultType'].toString();
            String accountNum        = _allFaultReport[listRow]['accountNumber'].toString();
            String address           = _allFaultReport[listRow]['address'].toString();
            String faultDate         = _allFaultReport[listRow]['dateReported'].toString();
            String depAllocated      = _allFaultReport[listRow]['depAllocated'].toString();
            String faultDescription  = _allFaultReport[listRow]['faultDescription'].toString();
            String faultStage        = _allFaultReport[listRow]['faultStage'].toString();
            String phoneNumber       = _allFaultReport[listRow]['reporterContact'].toString();
            String attendeeAlloc     = _allFaultReport[listRow]['attendeeAllocated'].toString();
            String managerAlloc      = _allFaultReport[listRow]['managerAllocated'].toString();
            String adminCom          = _allFaultReport[listRow]['adminComment'].toString();
            String attendeeCom1      = _allFaultReport[listRow]['attendeeCom1'].toString();
            String managerCom1       = _allFaultReport[listRow]['managerCom1'].toString();
            String attendeeCom2      = _allFaultReport[listRow]['attendeeCom2'].toString();
            String managerCom2       = _allFaultReport[listRow]['managerCom2'].toString();
            String attendeeCom3      = _allFaultReport[listRow]['attendeeCom3'].toString();
            String managerCom3       = _allFaultReport[listRow]['managerCom3'].toString();
            String deptSwitchCom     = _allFaultReport[listRow]['departmentSwitchComment'].toString();
            String reallocCom        = _allFaultReport[listRow]['reallocationComment'].toString();
            String managerReturnCom  = _allFaultReport[listRow]['managerReturnCom'].toString();
            String attendeeReturnCom = _allFaultReport[listRow]['attendeeReturnCom'].toString();

            sheet.getRangeByName('A$excelRowFill').setText(referenceNum);
            sheet.getRangeByName('B$excelRowFill').setText(resolveStatus);
            sheet.getRangeByName('C$excelRowFill').setText(faultType);
            sheet.getRangeByName('D$excelRowFill').setText(accountNum);
            sheet.getRangeByName('E$excelRowFill').setText(address);
            sheet.getRangeByName('F$excelRowFill').setText(faultDate);
            sheet.getRangeByName('G$excelRowFill').setText(depAllocated);
            sheet.getRangeByName('H$excelRowFill').setText(faultDescription);
            sheet.getRangeByName('I$excelRowFill').setText(faultStage);
            sheet.getRangeByName('J$excelRowFill').setText(phoneNumber);
            sheet.getRangeByName('K$excelRowFill').setText(attendeeAlloc);
            sheet.getRangeByName('L$excelRowFill').setText(managerAlloc);
            sheet.getRangeByName('M$excelRowFill').setText(adminCom);
            sheet.getRangeByName('N$excelRowFill').setText(attendeeCom1);
            sheet.getRangeByName('O$excelRowFill').setText(managerCom1);
            sheet.getRangeByName('P$excelRowFill').setText(attendeeCom2);
            sheet.getRangeByName('Q$excelRowFill').setText(managerCom2);
            sheet.getRangeByName('R$excelRowFill').setText(attendeeCom3);
            sheet.getRangeByName('S$excelRowFill').setText(managerCom3);
            sheet.getRangeByName('T$excelRowFill').setText(deptSwitchCom);
            sheet.getRangeByName('U$excelRowFill').setText(reallocCom);
            sheet.getRangeByName('V$excelRowFill').setText(managerReturnCom);
            sheet.getRangeByName('W$excelRowFill').setText(attendeeReturnCom);

            excelRowFill += 1;
            excelRow += 1;
            listRow += 1;
        } else {
          excelRow += 1;
          listRow += 1;
        }
      }
    }

    final List<int> bytes = workbook.saveAsStream();

    if(kIsWeb){
      AnchorElement(href: 'data:application/ocelot-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
        ..setAttribute('download', 'Msunduzi Faults Water & Sanitation Report $formattedDate.xlsx')
        ..click();

    } else {
      final String path = (await getApplicationSupportDirectory()).path;
      final String filename = Platform.isWindows ? '$path\\Msunduzi Faults Water & Sanitation Report $formattedDate.xlsx' : '$path/Msunduzi Faults Water & Sanitation Report $formattedDate.xlsx';
      final File file = File(filename);
      final List<int> bytes = workbook.saveAsStream();
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open('$path/Msunduzi Faults Water & Sanitation Report $formattedDate.xlsx');
    }

    workbook.dispose();

  }

  Future<void> reportGenerationWaste() async {
    final excel.Workbook workbook = excel.Workbook();
    final excel.Worksheet sheet = workbook.worksheets[0];

    var data = await FirebaseFirestore.instance.collection('faultReporting').get();

    _allFaultReport = data.docs;

    String column = "A";
    int excelRowFill = 2;
    int excelRow = 2;
    int listRow = 0;

    sheet.getRangeByName('A1').setText('Ref #');
    sheet.getRangeByName('B1').setText('Resolve Status');
    sheet.getRangeByName('C1').setText('Fault Type');
    sheet.getRangeByName('D1').setText('Account #');
    sheet.getRangeByName('E1').setText('Address');
    sheet.getRangeByName('F1').setText('Report Date');
    sheet.getRangeByName('G1').setText('Department Allocated');
    sheet.getRangeByName('H1').setText('Fault Description');
    sheet.getRangeByName('I1').setText('Fault Stage');
    sheet.getRangeByName('J1').setText('Reporters Phone Number');
    sheet.getRangeByName('K1').setText('Attendee Allocated');
    sheet.getRangeByName('L1').setText('Manager Allocated');
    sheet.getRangeByName('M1').setText('Admin Comment');
    sheet.getRangeByName('N1').setText('Attendee Com1');
    sheet.getRangeByName('O1').setText('Manager Com1');
    sheet.getRangeByName('P1').setText('Attendee Com2');
    sheet.getRangeByName('Q1').setText('Manager Com2');
    sheet.getRangeByName('R1').setText('Attendee Com3');
    sheet.getRangeByName('S1').setText('Manager Com3');
    sheet.getRangeByName('T1').setText('Department SwitchComment');
    sheet.getRangeByName('U1').setText('Reallocation Comment');
    sheet.getRangeByName('V1').setText('Manager ReturnCom');
    sheet.getRangeByName('W1').setText('Attendee ReturnCom');

    for (var reportSnapshot in _allFaultReport) {
      ///Need to build a property model that retrieves property data entirely from the db
      while (excelRow <= _allFaultReport.length + 1) {
        if (_allFaultReport[listRow]['faultType'].toString() == 'Waste Management') {

          print('Report Lists:::: ${_allFaultReport[listRow]['address']}');

          String referenceNum      = _allFaultReport[listRow]['ref'].toString();
          String resolveStatus     = _allFaultReport[listRow]['faultResolved'].toString();
          String faultType         = _allFaultReport[listRow]['faultType'].toString();
          String accountNum        = _allFaultReport[listRow]['accountNumber'].toString();
          String address           = _allFaultReport[listRow]['address'].toString();
          String faultDate         = _allFaultReport[listRow]['dateReported'].toString();
          String depAllocated      = _allFaultReport[listRow]['depAllocated'].toString();
          String faultDescription  = _allFaultReport[listRow]['faultDescription'].toString();
          String faultStage        = _allFaultReport[listRow]['faultStage'].toString();
          String phoneNumber       = _allFaultReport[listRow]['reporterContact'].toString();
          String attendeeAlloc     = _allFaultReport[listRow]['attendeeAllocated'].toString();
          String managerAlloc      = _allFaultReport[listRow]['managerAllocated'].toString();
          String adminCom          = _allFaultReport[listRow]['adminComment'].toString();
          String attendeeCom1      = _allFaultReport[listRow]['attendeeCom1'].toString();
          String managerCom1       = _allFaultReport[listRow]['managerCom1'].toString();
          String attendeeCom2      = _allFaultReport[listRow]['attendeeCom2'].toString();
          String managerCom2       = _allFaultReport[listRow]['managerCom2'].toString();
          String attendeeCom3      = _allFaultReport[listRow]['attendeeCom3'].toString();
          String managerCom3       = _allFaultReport[listRow]['managerCom3'].toString();
          String deptSwitchCom     = _allFaultReport[listRow]['departmentSwitchComment'].toString();
          String reallocCom        = _allFaultReport[listRow]['reallocationComment'].toString();
          String managerReturnCom  = _allFaultReport[listRow]['managerReturnCom'].toString();
          String attendeeReturnCom = _allFaultReport[listRow]['attendeeReturnCom'].toString();

          sheet.getRangeByName('A$excelRowFill').setText(referenceNum);
          sheet.getRangeByName('B$excelRowFill').setText(resolveStatus);
          sheet.getRangeByName('C$excelRowFill').setText(faultType);
          sheet.getRangeByName('D$excelRowFill').setText(accountNum);
          sheet.getRangeByName('E$excelRowFill').setText(address);
          sheet.getRangeByName('F$excelRowFill').setText(faultDate);
          sheet.getRangeByName('G$excelRowFill').setText(depAllocated);
          sheet.getRangeByName('H$excelRowFill').setText(faultDescription);
          sheet.getRangeByName('I$excelRowFill').setText(faultStage);
          sheet.getRangeByName('J$excelRowFill').setText(phoneNumber);
          sheet.getRangeByName('K$excelRowFill').setText(attendeeAlloc);
          sheet.getRangeByName('L$excelRowFill').setText(managerAlloc);
          sheet.getRangeByName('M$excelRowFill').setText(adminCom);
          sheet.getRangeByName('N$excelRowFill').setText(attendeeCom1);
          sheet.getRangeByName('O$excelRowFill').setText(managerCom1);
          sheet.getRangeByName('P$excelRowFill').setText(attendeeCom2);
          sheet.getRangeByName('Q$excelRowFill').setText(managerCom2);
          sheet.getRangeByName('R$excelRowFill').setText(attendeeCom3);
          sheet.getRangeByName('S$excelRowFill').setText(managerCom3);
          sheet.getRangeByName('T$excelRowFill').setText(deptSwitchCom);
          sheet.getRangeByName('U$excelRowFill').setText(reallocCom);
          sheet.getRangeByName('V$excelRowFill').setText(managerReturnCom);
          sheet.getRangeByName('W$excelRowFill').setText(attendeeReturnCom);

          excelRowFill += 1;
          excelRow += 1;
          listRow += 1;
        } else {
          excelRow += 1;
          listRow += 1;
        }
      }
    }

    final List<int> bytes = workbook.saveAsStream();

    if(kIsWeb){
      AnchorElement(href: 'data:application/ocelot-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
        ..setAttribute('download', 'Msunduzi Faults Water & Sanitation Report $formattedDate.xlsx')
        ..click();

    } else {
      final String path = (await getApplicationSupportDirectory()).path;
      final String filename = Platform.isWindows ? '$path\\Msunduzi Faults Water & Sanitation Report $formattedDate.xlsx' : '$path/Msunduzi Faults Water & Sanitation Report $formattedDate.xlsx';
      final File file = File(filename);
      final List<int> bytes = workbook.saveAsStream();
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open('$path/Msunduzi Faults Water & Sanitation Report $formattedDate.xlsx');
    }

    workbook.dispose();

  }

  Future<void> reportGenerationRoadworks() async {
    final excel.Workbook workbook = excel.Workbook();
    final excel.Worksheet sheet = workbook.worksheets[0];

    var data = await FirebaseFirestore.instance.collection('faultReporting').get();

    _allFaultReport = data.docs;

    String column = "A";
    int excelRowFill = 2;
    int excelRow = 2;
    int listRow = 0;

    sheet.getRangeByName('A1').setText('Ref #');
    sheet.getRangeByName('B1').setText('Resolve Status');
    sheet.getRangeByName('C1').setText('Fault Type');
    sheet.getRangeByName('D1').setText('Account #');
    sheet.getRangeByName('E1').setText('Address');
    sheet.getRangeByName('F1').setText('Report Date');
    sheet.getRangeByName('G1').setText('Department Allocated');
    sheet.getRangeByName('H1').setText('Fault Description');
    sheet.getRangeByName('I1').setText('Fault Stage');
    sheet.getRangeByName('J1').setText('Reporters Phone Number');
    sheet.getRangeByName('K1').setText('Attendee Allocated');
    sheet.getRangeByName('L1').setText('Manager Allocated');
    sheet.getRangeByName('M1').setText('Admin Comment');
    sheet.getRangeByName('N1').setText('Attendee Com1');
    sheet.getRangeByName('O1').setText('Manager Com1');
    sheet.getRangeByName('P1').setText('Attendee Com2');
    sheet.getRangeByName('Q1').setText('Manager Com2');
    sheet.getRangeByName('R1').setText('Attendee Com3');
    sheet.getRangeByName('S1').setText('Manager Com3');
    sheet.getRangeByName('T1').setText('Department SwitchComment');
    sheet.getRangeByName('U1').setText('Reallocation Comment');
    sheet.getRangeByName('V1').setText('Manager ReturnCom');
    sheet.getRangeByName('W1').setText('Attendee ReturnCom');

    for (var reportSnapshot in _allFaultReport) {
      ///Need to build a property model that retrieves property data entirely from the db
      while (excelRow <= _allFaultReport.length + 1) {
        if (_allFaultReport[listRow]['faultType'].toString() == 'Roadworks') {

          print('Report Lists:::: ${_allFaultReport[listRow]['address']}');

          String referenceNum      = _allFaultReport[listRow]['ref'].toString();
          String resolveStatus     = _allFaultReport[listRow]['faultResolved'].toString();
          String faultType         = _allFaultReport[listRow]['faultType'].toString();
          String accountNum        = _allFaultReport[listRow]['accountNumber'].toString();
          String address           = _allFaultReport[listRow]['address'].toString();
          String faultDate         = _allFaultReport[listRow]['dateReported'].toString();
          String depAllocated      = _allFaultReport[listRow]['depAllocated'].toString();
          String faultDescription  = _allFaultReport[listRow]['faultDescription'].toString();
          String faultStage        = _allFaultReport[listRow]['faultStage'].toString();
          String phoneNumber       = _allFaultReport[listRow]['reporterContact'].toString();
          String attendeeAlloc     = _allFaultReport[listRow]['attendeeAllocated'].toString();
          String managerAlloc      = _allFaultReport[listRow]['managerAllocated'].toString();
          String adminCom          = _allFaultReport[listRow]['adminComment'].toString();
          String attendeeCom1      = _allFaultReport[listRow]['attendeeCom1'].toString();
          String managerCom1       = _allFaultReport[listRow]['managerCom1'].toString();
          String attendeeCom2      = _allFaultReport[listRow]['attendeeCom2'].toString();
          String managerCom2       = _allFaultReport[listRow]['managerCom2'].toString();
          String attendeeCom3      = _allFaultReport[listRow]['attendeeCom3'].toString();
          String managerCom3       = _allFaultReport[listRow]['managerCom3'].toString();
          String deptSwitchCom     = _allFaultReport[listRow]['departmentSwitchComment'].toString();
          String reallocCom        = _allFaultReport[listRow]['reallocationComment'].toString();
          String managerReturnCom  = _allFaultReport[listRow]['managerReturnCom'].toString();
          String attendeeReturnCom = _allFaultReport[listRow]['attendeeReturnCom'].toString();

          sheet.getRangeByName('A$excelRowFill').setText(referenceNum);
          sheet.getRangeByName('B$excelRowFill').setText(resolveStatus);
          sheet.getRangeByName('C$excelRowFill').setText(faultType);
          sheet.getRangeByName('D$excelRowFill').setText(accountNum);
          sheet.getRangeByName('E$excelRowFill').setText(address);
          sheet.getRangeByName('F$excelRowFill').setText(faultDate);
          sheet.getRangeByName('G$excelRowFill').setText(depAllocated);
          sheet.getRangeByName('H$excelRowFill').setText(faultDescription);
          sheet.getRangeByName('I$excelRowFill').setText(faultStage);
          sheet.getRangeByName('J$excelRowFill').setText(phoneNumber);
          sheet.getRangeByName('K$excelRowFill').setText(attendeeAlloc);
          sheet.getRangeByName('L$excelRowFill').setText(managerAlloc);
          sheet.getRangeByName('M$excelRowFill').setText(adminCom);
          sheet.getRangeByName('N$excelRowFill').setText(attendeeCom1);
          sheet.getRangeByName('O$excelRowFill').setText(managerCom1);
          sheet.getRangeByName('P$excelRowFill').setText(attendeeCom2);
          sheet.getRangeByName('Q$excelRowFill').setText(managerCom2);
          sheet.getRangeByName('R$excelRowFill').setText(attendeeCom3);
          sheet.getRangeByName('S$excelRowFill').setText(managerCom3);
          sheet.getRangeByName('T$excelRowFill').setText(deptSwitchCom);
          sheet.getRangeByName('U$excelRowFill').setText(reallocCom);
          sheet.getRangeByName('V$excelRowFill').setText(managerReturnCom);
          sheet.getRangeByName('W$excelRowFill').setText(attendeeReturnCom);

          excelRowFill += 1;
          excelRow += 1;
          listRow += 1;
        } else {
          excelRow += 1;
          listRow += 1;
        }
      }
    }

    final List<int> bytes = workbook.saveAsStream();

    if(kIsWeb){
      AnchorElement(href: 'data:application/ocelot-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
        ..setAttribute('download', 'Msunduzi Faults Water & Sanitation Report $formattedDate.xlsx')
        ..click();

    } else {
      final String path = (await getApplicationSupportDirectory()).path;
      final String filename = Platform.isWindows ? '$path\\Msunduzi Faults Water & Sanitation Report $formattedDate.xlsx' : '$path/Msunduzi Faults Water & Sanitation Report $formattedDate.xlsx';
      final File file = File(filename);
      final List<int> bytes = workbook.saveAsStream();
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open('$path/Msunduzi Faults Water & Sanitation Report $formattedDate.xlsx');
    }

    workbook.dispose();

  }

  void setMonthLimits(String currentMonth) {
    String month1 = 'January';
    String month2 = 'February';
    String month3 = 'March';
    String month4 = 'April';
    String month5 = 'May';
    String month6 = 'June';
    String month7 = 'July';
    String month8 = 'August';
    String month9 = 'September';
    String month10 = 'October';
    String month11 = 'November';
    String month12 = 'December';

    if (currentMonth.contains(month1)) {
      dropdownMonths = ['Select Month', month10,month11,month12,currentMonth,];
    } else if (currentMonth.contains(month2)) {
      dropdownMonths = ['Select Month', month11,month12,month1,currentMonth,];
    } else if (currentMonth.contains(month3)) {
      dropdownMonths = ['Select Month', month12,month1,month2,currentMonth,];
    } else if (currentMonth.contains(month4)) {
      dropdownMonths = ['Select Month', month1,month2,month3,currentMonth,];
    } else if (currentMonth.contains(month5)) {
      dropdownMonths = ['Select Month', month2,month3,month4,currentMonth,];
    } else if (currentMonth.contains(month6)) {
      dropdownMonths = ['Select Month', month3,month4,month5,currentMonth,];
    } else if (currentMonth.contains(month7)) {
      dropdownMonths = ['Select Month', month4,month5,month6,currentMonth,];
    } else if (currentMonth.contains(month8)) {
      dropdownMonths = ['Select Month', month5,month6,month7,currentMonth,];
    } else if (currentMonth.contains(month9)) {
      dropdownMonths = ['Select Month', month6,month7,month8,currentMonth,];
    } else if (currentMonth.contains(month10)) {
      dropdownMonths = ['Select Month', month7,month8,month9,currentMonth,];
    } else if (currentMonth.contains(month11)) {
      dropdownMonths = ['Select Month', month8,month9,month10,currentMonth,];
    } else if (currentMonth.contains(month12)) {
      dropdownMonths = ['Select Month', month9,month10,month11,currentMonth,];
    } else {
      dropdownMonths = [
        'Select Month',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
    }
  }

  ///pdf view loader getting file name onPress/onTap that passes pdf filename to this class.
  void openPDF(BuildContext context, File file) => Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
  );

  List<ReportData> getReportData(){

    final List<ReportData> reportData =[];

    int allReportRow = 1;

    for(var reportSnapshot in _allFaultReport){
      ///Need to build a property model that retrieves property data entirely from the db
      while(allReportRow <= _allFaultReport.length+1) {
        reportData.add(
            ReportData(
              _allFaultReport[allReportRow]['ref'].toString(),
              _allFaultReport[allReportRow]['faultResolved'] as bool,
              _allFaultReport[allReportRow]['faultType'].toString(),
              _allFaultReport[allReportRow]['accountNumber'].toString(),
              _allFaultReport[allReportRow]['address'].toString(),
              _allFaultReport[allReportRow]['dateReported'].toString(),
              _allFaultReport[allReportRow]['depAllocated'].toString(),
              _allFaultReport[allReportRow]['faultDescription'].toString(),
              _allFaultReport[allReportRow]['faultStage'].toString(),
              _allFaultReport[allReportRow]['reporterContact'].toString(),
              _allFaultReport[allReportRow]['attendeeAllocated'].toString(),
              _allFaultReport[allReportRow]['managerAllocated'].toString(),
              _allFaultReport[allReportRow]['adminComment'].toString(),
              _allFaultReport[allReportRow]['attendeeCom1'].toString(),
              _allFaultReport[allReportRow]['managerCom1'].toString(),
              _allFaultReport[allReportRow]['attendeeCom2'].toString(),
              _allFaultReport[allReportRow]['managerCom2'].toString(),
              _allFaultReport[allReportRow]['attendeeCom3'].toString(),
              _allFaultReport[allReportRow]['managerCom3'].toString(),
              _allFaultReport[allReportRow]['departmentSwitchComment'].toString(),
              _allFaultReport[allReportRow]['reallocationComment'].toString(),
              _allFaultReport[allReportRow]['managerReturnCom'].toString(),
              _allFaultReport[allReportRow]['attendeeReturnCom'].toString(),
            )
        );
        allReportRow += 1;
      }
    }
    return reportData;
  }

}

class ReportData{
  ReportData(this.ref, this.faultResolved, this.faultType, this.accountNumber, this.address, this.dateReported, this.depAllocated, this.faultDescription, this.faultStage, this.reporterContact, this.attendeeAllocated, this.managerAllocated, this.adminComment, this.attendeeCom1, this.managerCom1, this.attendeeCom2, this.managerCom2, this.attendeeCom3, this.managerCom3, this.departmentSwitchComment, this.reallocationComment, this.managerReturnCom, this.attendeeReturnCom);

  final String ref;
  final bool faultResolved;
  final String faultType;
  final String accountNumber;
  final String address;
  final String dateReported;
  final String depAllocated;
  final String faultDescription;
  final String faultStage;
  final String reporterContact;
  final String attendeeAllocated;
  final String managerAllocated;
  final String adminComment;
  final String attendeeCom1;
  final String managerCom1;
  final String attendeeCom2;
  final String managerCom2;
  final String attendeeCom3;
  final String managerCom3;
  final String departmentSwitchComment;
  final String reallocationComment;
  final String managerReturnCom;
  final String attendeeReturnCom;

}