import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'package:municipal_tracker_msunduzi/code/ImageUploading/image_upload_fault.dart';
import 'package:municipal_tracker_msunduzi/code/MapTools/map_screen_prop.dart';
import 'package:municipal_tracker_msunduzi/code/MapTools/map_screen.dart';
import 'package:municipal_tracker_msunduzi/code/PDFViewer/view_pdf.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/icon_elevated_button.dart';



class ImageZoomFaultPage extends StatefulWidget {
  const ImageZoomFaultPage({Key? key, required this.imageName, required this.dateReported}) : super(key: key);

  final String imageName;
  final String dateReported;

  @override
  _ImageZoomFaultPageState createState() => _ImageZoomFaultPageState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

final User? user = auth.currentUser;
final uid = user?.uid;
final phone = user?.phoneNumber;
String userID = uid as String;
String phoneNum = phone as String;
DateTime now = DateTime.now();

String accountNumber = ' ';
String locationGiven = ' ';
String eMeterNumber = ' ';
String accountNumberW = ' ';
String locationGivenW = ' ';
String wMeterNumber = ' ';

String propPhoneNum = ' ';

bool visibilityState1 = true;
bool visibilityState2 = false;

bool imgUploadCheck = false;


final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;

class FireStorageService extends ChangeNotifier{
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async{
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

Future<Widget> _getImage(BuildContext context, String imageName) async{
  Image image;
  final value = await FireStorageService.loadImage(context, imageName);
  image =Image.network(
    value.toString(),
    fit: BoxFit.fill,
  );
  return image;
}

Future<Widget> _getImageW(BuildContext context, String imageName2) async{
  Image image2;
  final value = await FireStorageService.loadImage(context, imageName2);
  image2 =Image.network(
    value.toString(),
    fit: BoxFit.fill,
  );
  return image2;
}


class _ImageZoomFaultPageState extends State<ImageZoomFaultPage> {

  String formattedMonth = DateFormat.MMMM().format(now);//format for full Month by name
  String formattedDateMonth = DateFormat.MMMMd().format(now);//format for Day Month only

  String dropdownValue = 'Select Month';
  List<String> dropdownMonths = ['Select Month','January','February','March','April','May','June','July','August','September','October','November','December'];

  final CollectionReference _propList =
  FirebaseFirestore.instance.collection('properties');

  final CollectionReference _faultData =
  FirebaseFirestore.instance.collection('faultReporting');

  String reporterCellGiven = '';
  String reporterDateGiven = '';
  String accountNumberRep = '';
  String locationGivenRep = '';
  bool imageVisibility = true;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Fault Image',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(0.0,5.0,0.0,5.0),
        child:Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _faultData.orderBy('dateReported', descending: true).snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
              if (streamSnapshot.hasData) {
                return ListView.builder(
                  itemCount: streamSnapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final DocumentSnapshot documentSnapshot =
                    streamSnapshot.data!.docs[index];
                    String status;
                    if(documentSnapshot['faultResolved'] == false){
                      status = "Pending";
                    } else {
                      status = "Completed";
                    }

                    if(documentSnapshot['dateReported'] == widget.dateReported) {
                        return Card(
                          margin: const EdgeInsets.only(
                              left: 10, right: 10, top: 5, bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Text(
                                    'Fault ${documentSnapshot['ref']}',
                                    style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(height: 10,),

                                // Text(
                                //   'Reference Number: ${documentSnapshot['ref']}',
                                //   style: TextStyle(
                                //       fontSize: 19,
                                //       fontWeight: FontWeight.w700),
                                // ),
                                // const SizedBox(height: 5,),

                                Text(
                                  'Street Address of Fault: ${documentSnapshot['address']}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: 5,),
                                Text(
                                  'Fault Type: ${documentSnapshot['faultType']}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: 5,),
                                Column(
                                  children: [
                                    if(documentSnapshot['faultDescription'] != "")...[
                                      Text(
                                        'Fault Description: ${documentSnapshot['faultDescription']}',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                                      ),
                                      const SizedBox(height: 5,),
                                    ] else ...[

                                    ],
                                  ],
                                ),

                                Text(
                                  'Resolve State: $status',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: 5,),
                                Text(
                                  'Date of Fault Report: ${documentSnapshot['dateReported']}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: 5,),
                                Column(
                                  children: [
                                    if(documentSnapshot['faultDescription'] != "")...[
                                      Visibility(
                                        visible: imageVisibility,
                                        child: InkWell(
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 5),
                                            // height: 180,
                                            child: Center(
                                              child: Card(
                                                color: Colors.grey,
                                                semanticContainer: true,
                                                clipBehavior: Clip.antiAliasWithSaveLayer,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10.0),
                                                ),
                                                elevation: 0,
                                                margin: const EdgeInsets.all(10.0),
                                                child: FutureBuilder(
                                                    future: _getImage(context,
                                                        'files/faultImages/${documentSnapshot['dateReported']}/${documentSnapshot['address']}'),
                                                    builder: (context, snapshot) {
                                                      if (snapshot.hasError) {
                                                        return const Padding(padding: EdgeInsets.all(20.0),
                                                          child: Text('Image not uploaded for Fault.',),
                                                        ); //${snapshot.error} if error needs to be displayed instead
                                                      }
                                                      if (snapshot.connectionState == ConnectionState.done) {
                                                        return Container(
                                                          child: snapshot.data,
                                                        );
                                                      }
                                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                                        return Container(
                                                          child: const CircularProgressIndicator(),);
                                                      }
                                                      return Container();
                                                    }
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ] else ...[

                                    ],
                                  ],
                                ),
                                const SizedBox(height: 0,),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment
                                        .center,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .center,
                                        crossAxisAlignment: CrossAxisAlignment
                                            .center,
                                        children: [
                                          BasicIconButtonGreen(
                                            onPress: () {
                                              accountNumberRep = documentSnapshot['accountNumber'];
                                              locationGivenRep = documentSnapshot['address'];

                                              Navigator.push(context, MaterialPageRoute(
                                                      builder: (context) =>
                                                          MapScreenProp(propAddress: locationGivenRep, propAccNumber: accountNumberRep,)
                                                    //MapPage()
                                                  ));
                                            },
                                            labelText: 'Location',
                                            fSize: 14,
                                            faIcon: const FaIcon(Icons.map),
                                            fgColor: Colors.purple,
                                            btSize: const Size(40, 40),
                                          ),
                                          BasicIconButtonGreen(
                                            onPress: () {
                                              locationGivenRep = documentSnapshot['address'];
                                              reporterDateGiven = documentSnapshot['dateReported'];
                                              Navigator.push(context, MaterialPageRoute(builder: (context) =>
                                                          FaultImageUpload(propertyAddress: locationGivenRep, reportedDate: reporterDateGiven)
                                                    //MapPage()
                                                  ));
                                            },
                                            labelText: 'Image +',
                                            fSize: 14,
                                            faIcon: const FaIcon(Icons.photo_camera),
                                            fgColor: Colors.blueGrey,
                                            btSize: const Size(40, 40),
                                          ),
                                        ],
                                      ),

                                      ///Button for staff to use in calling the user that reported this fault, not needed here
                                      // ElevatedButton(
                                      //   onPressed: () {
                                      //     showDialog(
                                      //         barrierDismissible: false,
                                      //         context: context,
                                      //         builder: (context) {
                                      //           return
                                      //             AlertDialog(
                                      //               shape: const RoundedRectangleBorder(
                                      //                   borderRadius:
                                      //                   BorderRadius.all(Radius.circular(16))),
                                      //               title: const Text("Call Reporter!"),
                                      //               content: const Text(
                                      //                   "Would you like to call the individual who logged the fault?"),
                                      //               actions: [
                                      //                 IconButton(
                                      //                   onPressed: () {
                                      //                     Navigator.of(context).pop();
                                      //                   },
                                      //                   icon: const Icon(
                                      //                     Icons.cancel,
                                      //                     color: Colors.red,
                                      //                   ),
                                      //                 ),
                                      //                 IconButton(
                                      //                   onPressed: () {
                                      //                     reporterCellGiven = documentSnapshot['reporterContact'];
                                      //
                                      //                     final Uri _tel = Uri.parse('tel:${reporterCellGiven.toString()}');
                                      //                     launchUrl(_tel);
                                      //
                                      //                     Navigator.of(context).pop();
                                      //                   },
                                      //                   icon: const Icon(
                                      //                     Icons.done,
                                      //                     color: Colors.green,
                                      //                   ),
                                      //                 ),
                                      //               ],
                                      //             );
                                      //         });
                                      //   },
                                      //   style: ElevatedButton.styleFrom(
                                      //     backgroundColor: Colors.grey[350],
                                      //     fixedSize: const Size(150, 10),),
                                      //   child: Row(
                                      //     children: [
                                      //       Icon(
                                      //         Icons.call,
                                      //         color: Colors.orange[700],
                                      //       ),
                                      //       const SizedBox(width: 2,),
                                      //       const Text('Call Reporter', style: TextStyle(
                                      //         fontWeight: FontWeight.w600,
                                      //         color: Colors.black,),),
                                      //     ],
                                      //   ),
                                      // ),
                                      // const SizedBox(width: 5,),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                    }
                    else {
                      return const SizedBox();
                    }
                  },
                );
              }
              return const Padding(
                padding: EdgeInsets.all(10.0),
                child: Center(
                  child: Card(
                    margin: EdgeInsets.all(10),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'No Faults Reported Yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),


      //   floatingActionButton: FloatingActionButton(
      //     onPressed: () {},
      //     child: const Icon(Icons.add),
      //   ),
      //   floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat

    );
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