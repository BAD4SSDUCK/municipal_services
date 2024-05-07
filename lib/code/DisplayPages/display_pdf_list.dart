import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:municipal_services/code/PDFViewer/pdf_api.dart';
import 'package:municipal_services/code/PDFViewer/view_pdf.dart';
import 'package:municipal_services/code/Chat/chat_screen_finance.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';


class UsersPdfListViewPage extends StatefulWidget {
  const UsersPdfListViewPage({Key? key}) : super(key: key);

  @override
  _UsersPdfListViewPageState createState() => _UsersPdfListViewPageState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

DateTime now = DateTime.now();

final User? user = auth.currentUser;
final uid = user?.uid;
final phone = user?.phoneNumber;
final email = user?.email;
String userID = uid as String;
String userPhone = phone as String;
String userEmail = email as String;

String locationGiven = ' ';

bool visibilityState1 = true;
bool visibilityState2 = false;

final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;

class FireStorageService extends ChangeNotifier{
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async{
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

class _UsersPdfListViewPageState extends State<UsersPdfListViewPage> {

  final user = FirebaseAuth.instance.currentUser!;

  final CollectionReference _propList =
  FirebaseFirestore.instance.collection('properties');

  String formattedDate = DateFormat.MMMM().format(now);

  String dropdownValue = 'Select Month';
  List<String> dropdownMonths = ['Select Month','January','February','March','April','May','June','July','August','September','October','November','December'];

  Timer? timer;
  var _isLoading = false;

  void _onSubmit() {
    setState(() => _isLoading = true);
    Future.delayed(
      const Duration(seconds: 5),
          () => setState(() => _isLoading = false),
    );
  }

  @override
  void initState() {
    setMonthLimits(formattedDate);
    super.initState();
  }

  Widget firebasePDFCard(CollectionReference<Object?> pdfDataStream){
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: pdfDataStream.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              ///this call is to display all details for all users but is only displaying for the current user account.
              ///it can be changed to display all users for the staff to see if the role is set to all later on.
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                streamSnapshot.data!.docs[index];

                ///Check for only user information, this displays only for the users details and not all users in the database.
                if(streamSnapshot.data!.docs[index]['cell number'] == userPhone) {
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
                                'Property Data',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            Text(
                              'Account Number: ${documentSnapshot['account number']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Street Address: ${documentSnapshot['address']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Area Code: ${documentSnapshot['area code']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 20,),

                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            BasicIconButtonGrey(
                                              onPress: () async {

                                                String financeID = 'finance@msunduzi.gov.za';

                                                String passedID = user.phoneNumber!;
                                                String? userName = FirebaseAuth.instance.currentUser!.phoneNumber;
                                                print('The user name of the logged in person is $userName}');
                                                String id = passedID;

                                                Navigator.push(context,
                                                    MaterialPageRoute(builder: (context) => ChatFinance(chatRoomId: id, userName: null, )));

                                              },
                                              labelText: 'Dispute',
                                              fSize: 16,
                                              faIcon: const FaIcon(Icons.error_outline),
                                              fgColor: Colors.red,
                                              btSize: const Size(100, 38),
                                            ),
                                            Stack(
                                              children: [
                                                BasicIconButtonGrey(
                                                onPress: () async {

                                                  _onSubmit();

                                                  String accountNumberPDF = documentSnapshot['account number'];
                                                  print('The acc number is ::: $accountNumberPDF');
                                                  print('The month we are in is::: $formattedDate');

                                                  // getPDFByAccMon(accountNumberPDF,formattedDate);
                                                  if(dropdownValue=='Select Month'){
                                                    getPDFByAccMon(accountNumberPDF,formattedDate);
                                                    print('The month selected is::: $dropdownValue');
                                                  } else {
                                                    getPDFByAccMon(accountNumberPDF,dropdownValue);
                                                    print('The month selected is::: $dropdownValue');
                                                  }

                                                },
                                                labelText: 'Invoice',
                                                fSize: 16,
                                                faIcon: const FaIcon(Icons.download),
                                                fgColor: Colors.green,
                                                btSize: const Size(100, 38),
                                              ),
                                                const SizedBox(width: 5,),
                                                Visibility(
                                                  visible: _isLoading,
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      const SizedBox(height: 15, width: 130,),
                                                      Container(
                                                        width: 24,
                                                        height: 24,
                                                        padding: const EdgeInsets.all(2.0),
                                                        child: const CircularProgressIndicator(
                                                        color: Colors.purple,
                                                        strokeWidth: 3,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                )

                                              ]
                                            ),

                                            const SizedBox(width: 5,),
                                          ],
                                        ),
                                      ],
                                    ),

                                  ],
                                ),
                              ],
                            ),
                          ]
                      ),
                    ),
                  );
                }///end of single user information display.
                else {
                  return Card();
                }
              },
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Account Details',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
      Column(
        children: [
          const SizedBox(height: 10,),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0.0,horizontal: 15.0),
            child: Column(
                children: [
                  SizedBox(
                    width: 400,
                    height: 50,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: Center(
                        child: TextField(
                          ///Input decoration here had to be manual because dropdown button uses suffix icon of the textfield
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    30),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                )
                            ),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    30),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                )
                            ),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    30),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                )
                            ),
                            disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    30),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                )
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6
                            ),
                            fillColor: Colors.white,
                            filled: true,
                            suffixIcon: DropdownButtonFormField <String>(
                              value: dropdownValue,
                              items: dropdownMonths
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 20.0),
                                    child: Text(
                                      value,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  dropdownValue = newValue!;
                                });
                              },
                              icon: const Padding(
                                padding: EdgeInsets.only(left: 10, right: 10),
                                child: Icon(Icons.arrow_circle_down_sharp),
                              ),
                              iconEnabledColor: Colors.green,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18
                              ),
                              dropdownColor: Colors.grey[50],
                              isExpanded: true,

                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]
            ),
          ),

          firebasePDFCard(_propList),

        ],
      ),
    );
  }

  ///This function gets the document on the firestore in the month that we are in as well as if the document name contains the properties account number
  void getPDFByAccMon(String accNum, String month) async{
    Fluttertoast.showToast(
        msg: "Now downloading your statement!\nPlease wait a few seconds!");

    final storageRef = FirebaseStorage.instance.ref().child("pdfs/$month");
    final listResult = await storageRef.listAll();
    int list = 0;
    for (var prefix in listResult.prefixes) {
      print('The ref is ::: $prefix');
      // The prefixes under storageRef.
      // You can call listAll() recursively on them.
    }
    for (var item in listResult.items) {
      print('The item is ::: $item');
      list++;
      // The items under storageRef.
      try {
      if (item.toString().contains(accNum)) {
        final url = item.fullPath;
        print('The url is ::: $url');
        final file = await PDFApi.loadFirebase(url);
        try {
          if(item.toString().contains(accNum)){
          Fluttertoast.showToast(msg: "Download Successful!");
          if(context.mounted)openPDF(context, file);
          }
        } catch (e) {
          Fluttertoast.showToast(msg: "Unable to download statement.");
          if (context.mounted) {
            showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) {
                  return
                    AlertDialog(
                      shape: const RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.all(Radius.circular(16))),
                      title: const Text("Statement Download Error"),
                      content: const Text(
                          "Would you like to contact the municipality for assistance on this error?"),
                      actions: [
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.red,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            final Uri _tel = Uri.parse('tel:+27${0800001868}');
                            launchUrl(_tel);
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(
                            Icons.done,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    );
                });
          }
        }
      }
      } catch(e) {
        print('error::: $e');
        Fluttertoast.showToast(msg: "Unable to download statement.");
      }

    }
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
