import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

import 'package:municipal_tracker_msunduzi/code/PDFViewer/view_pdf.dart';


class ReportBuilderProps extends StatefulWidget {
  const ReportBuilderProps({Key? key}) : super(key: key);

  @override
  _ReportBuilderPropsState createState() => _ReportBuilderPropsState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

final User? user = auth.currentUser;
final uid = user?.uid;
String userID = uid as String;
DateTime now = DateTime.now();

String phoneNum = ' ';

String accountNumberAll = ' ';
String locationGivenAll = ' ';
String eMeterNumber = ' ';
String accountNumberW = ' ';
String locationGivenW = ' ';
String wMeterNumber = ' ';

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

class _ReportBuilderPropsState extends State<ReportBuilderProps> {

  @override
  void initState() {
    if(_searchController.text == ""){
      getPropertyStream();
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
    _allPropertyResults;
    _allPropertyReport;
    super.dispose();
  }

  void checkAdmin() {
    String? emailLogged = user?.email.toString();
    if(emailLogged?.contains("admin") == true){
      adminAcc = true;
    } else {
      adminAcc = false;
    }
  }

  String searchText = '';

  String formattedDate = DateFormat.MMMM().format(now);

  final CollectionReference _listUserTokens =
  FirebaseFirestore.instance.collection('UserToken');

  final CollectionReference _listNotifications =
  FirebaseFirestore.instance.collection('Notifications');

  final _headerController = TextEditingController();
  final _messageController = TextEditingController();

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

  bool visShow = true;
  bool visHide = false;
  bool adminAcc = false;

  int numTokens=0;

  String dropdownValue = 'Select Month';
  List<String> dropdownMonths = ['Select Month','January','February','March','April','May','June','July','August','September','October','November','December'];

  TextEditingController _searchController = TextEditingController();
  List _allPropertyResults = [];
  List _allPropertyReport = [];

  getPropertyStream() async{
    var data = await FirebaseFirestore.instance.collection('properties').get();

    setState(() {
      _allPropertyResults = data.docs;
    });
    searchResultsList();
  }

  _onSearchChanged() async {
    searchResultsList();
  }

  searchResultsList() async {
    var showResults = [];
    if(_searchController.text != "") {
      getPropertyStream();
      for(var propSnapshot in _allPropertyResults){
        ///Need to build a property model that retrieves property data entirely from the db
        var address = propSnapshot['address'].toString().toLowerCase();

        if(address.contains(_searchController.text.toLowerCase())) {
          showResults.add(propSnapshot);
        }
      }
    } else {
      getPropertyStream();
      showResults = List.from(_allPropertyResults);
    }
    setState(() {
      _allPropertyResults = showResults;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Report Generator',style: TextStyle(color: Colors.white),),
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
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.red,
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                Fluttertoast.showToast(msg: "Now generating report\nPlease wait till prompted to open Spreadsheet!");
                                reportGeneration();
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                Icons.done,
                                color: Colors.green,
                              ),
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
          /// Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(10.0,10.0,10.0,10.0),
            child: SearchBar(
              controller: _searchController,
              padding: const MaterialStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(horizontal: 16.0)),
              leading: const Icon(Icons.search),
              hintText: "Search by Address...",
              onChanged: (value) async{
                setState(() {
                  searchText = value;
                  // print('this is the input text ::: $searchText');
                });
              },
            ),
          ),
          /// Search bar end

          Expanded(child: propertyCard(),),

          const SizedBox(height: 5,),
        ],
      ),
      /// Add new account, removed because it was not necessary for non-staff users.
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
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.red,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          Fluttertoast.showToast(
                              msg: "Now generating report\nPlease wait till prompted to open Spreadsheet!");
                          reportGeneration();
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.done,
                          color: Colors.green,
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

  Widget propertyCard() {
    if (_allPropertyResults.isNotEmpty) {
    return ListView.builder(
      ///this call is to display all details for all users but is only displaying for the current user account.
      ///it can be changed to display all users for the staff to see if the role is set to all later on.
      itemCount: _allPropertyResults.length,
      itemBuilder: (context, index) {

        eMeterNumber = _allPropertyResults[index]['meter number'];
        wMeterNumber = _allPropertyResults[index]['water meter number'];
        propPhoneNum = _allPropertyResults[index]['cell number'];

        String billMessage;///A check for if payment is outstanding or not
        if(_allPropertyResults[index]['eBill'] != '' ||
            _allPropertyResults[index]['eBill'] != 'R0,000.00' ||
            _allPropertyResults[index]['eBill'] != 'R0.00' ||
            _allPropertyResults[index]['eBill'] != 'R0' ||
            _allPropertyResults[index]['eBill'] != '0'
        ){
          billMessage = 'Utilities bill outstanding: ${_allPropertyResults[index]['eBill']}';
        } else {
          billMessage = 'No outstanding payments';
        }

        return Card(
            margin: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Property Information',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 10,),
                  Text(
                    'Account Number: ${_allPropertyResults[index]['account number']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    'Street Address: ${_allPropertyResults[index]['address']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    'Area Code: ${_allPropertyResults[index]['area code']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    'Meter Number: ${_allPropertyResults[index]['meter number']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    'Meter Reading: ${_allPropertyResults[index]['meter reading']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    'Water Meter Number: ${_allPropertyResults[index]['water meter number']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    'Water Meter Reading: ${_allPropertyResults[index]['water meter reading']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    'Phone Number: ${_allPropertyResults[index]['cell number']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    'First Name: ${_allPropertyResults[index]['first name']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    'Surname: ${_allPropertyResults[index]['last name']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    'ID Number: ${_allPropertyResults[index]['id number']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    billMessage,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 10,),

                ],
              ),
            ),
          );
      },
    );
    } return const Center(
      child: CircularProgressIndicator(),
    );
  }


  Future<void> reportGeneration() async {
    final excel.Workbook workbook = excel.Workbook();
    final excel.Worksheet sheet = workbook.worksheets[0];

    var data = await FirebaseFirestore.instance.collection('properties').get();

    _allPropertyReport = data.docs;

    String column = "A";
    int excelRow = 2;
    int listRow = 0;

    sheet.getRangeByName('A1').setText('Account #');
    sheet.getRangeByName('B1').setText('Address');
    sheet.getRangeByName('C1').setText('Area Code');
    sheet.getRangeByName('D1').setText('Utilities Bill');
    sheet.getRangeByName('E1').setText('Meter Number');
    sheet.getRangeByName('F1').setText('Meter Reading');
    sheet.getRangeByName('G1').setText('Electric Image Submitted');
    sheet.getRangeByName('H1').setText('Water Meter Number');
    sheet.getRangeByName('I1').setText('Water Meter Reading');
    sheet.getRangeByName('J1').setText('Water Image Submitted');
    sheet.getRangeByName('K1').setText('First Name');
    sheet.getRangeByName('L1').setText('Last Name');
    sheet.getRangeByName('M1').setText('ID Number');
    sheet.getRangeByName('N1').setText('Owner Phone Number');

    for(var reportSnapshot in _allPropertyReport){
      ///Property snapshot that retrieves property data entirely from the db
      while(excelRow <= _allPropertyReport.length+1) {

        print('Report Lists:::: ${_allPropertyReport[listRow]['address']}');
        String accountNum = _allPropertyReport[listRow]['account number'].toString();
        String address = _allPropertyReport[listRow]['address'].toString();
        String eBill = _allPropertyReport[listRow]['eBill'].toString();
        String areaCode = _allPropertyReport[listRow]['area code'].toString();
        String meterNumber = _allPropertyReport[listRow]['meter number'].toString();
        String meterReading = _allPropertyReport[listRow]['meter reading'].toString();
        String uploadedLatestE = _allPropertyReport[listRow]['imgStateE'].toString();
        String waterMeterNum = _allPropertyReport[listRow]['water meter number'].toString();
        String waterMeterReading = _allPropertyReport[listRow]['water meter reading'].toString();
        String uploadedLatestW = _allPropertyReport[listRow]['imgStateW'].toString();
        String firstName = _allPropertyReport[listRow]['first name'].toString();
        String lastName = _allPropertyReport[listRow]['last name'].toString();
        String idNumber = _allPropertyReport[listRow]['id number'].toString();
        String phoneNumber = _allPropertyReport[listRow]['cell number'].toString();

        sheet.getRangeByName('A$excelRow').setText(accountNum);
        sheet.getRangeByName('B$excelRow').setText(address);
        sheet.getRangeByName('C$excelRow').setText(areaCode);
        sheet.getRangeByName('D$excelRow').setText(eBill);
        sheet.getRangeByName('E$excelRow').setText(meterNumber);
        sheet.getRangeByName('F$excelRow').setText(meterReading);
        sheet.getRangeByName('G$excelRow').setText(uploadedLatestE);
        sheet.getRangeByName('H$excelRow').setText(waterMeterNum);
        sheet.getRangeByName('I$excelRow').setText(waterMeterReading);
        sheet.getRangeByName('J$excelRow').setText(uploadedLatestW);
        sheet.getRangeByName('K$excelRow').setText(firstName);
        sheet.getRangeByName('L$excelRow').setText(lastName);
        sheet.getRangeByName('M$excelRow').setText(idNumber);
        sheet.getRangeByName('N$excelRow').setText(phoneNumber);

        excelRow+=1;
        listRow+=1;
      }
    }

    final List<int> bytes = workbook.saveAsStream();

    if(kIsWeb){
      AnchorElement(href: 'data:application/ocelot-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
          ..setAttribute('download', 'Msunduzi Property Reports $formattedDate.xlsx')
          ..click();
    } else {
      final String path = (await getApplicationSupportDirectory()).path;
      //Create an empty file to write Excel data
      final String filename = Platform.isWindows ? '$path\\Msunduzi Property Reports $formattedDate.xlsx' : '$path/Msunduzi Property Reports $formattedDate.xlsx';
      final File file = File(filename);
      final List<int> bytes = workbook.saveAsStream();
      //Write Excel data
      await file.writeAsBytes(bytes, flush: true);
      //Launch the file (used open_file package)
      await OpenFile.open('$path/Msunduzi Property Reports $formattedDate.xlsx');
    }
    // File('Msunduzi Property Reports.xlsx').writeAsBytes(bytes);
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
}