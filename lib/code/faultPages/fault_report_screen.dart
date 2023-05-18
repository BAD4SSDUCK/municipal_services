import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:municipal_track/code/ImageUploading/image_upload_prop_fault.dart';
import 'package:municipal_track/code/faultPages/fault_viewing_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:municipal_track/code/Reusable/icon_elevated_button.dart';
import 'package:municipal_track/code/faultPages/general_fault_screen.dart';

class ReportPropertyMenu extends StatefulWidget {
  const ReportPropertyMenu({Key? key}) : super(key: key);

  @override
  State<ReportPropertyMenu> createState() => _ReportPropertyMenuState();
}


final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

final User? user = auth.currentUser;
final uid = user?.uid;
final phone = user?.phoneNumber;
String userID = uid as String;
String userPhone = phone as String;

class _ReportPropertyMenuState extends State<ReportPropertyMenu> {

  final _faultDescriptionController = TextEditingController();

  final String _currentUser = userID;

  final CollectionReference _faultData =
  FirebaseFirestore.instance.collection('faultReporting');

  final CollectionReference _deptInfo =
  FirebaseFirestore.instance.collection('departments');

  final CollectionReference _propList =
  FirebaseFirestore.instance.collection('properties');

  String userPass = '';
  String addressPass = '';
  String accountPass = '';
  String phoneNumPass = '';
  String dropdownValue = 'Select Fault Type';

  bool buttonEnabled = true;

  //this widget is for displaying a property field of information with an icon next to it, NB. the icon is to make it look good
  //it is called within a listview page widget
  Widget faultItemField(String propertyDat) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8,),
      child: Row(
        children: [
          const SizedBox(width: 6,),
          Text(
            propertyDat,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewFaultReport() async {
    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField <String>(
                    value: dropdownValue,
                    items: <String>['Select Fault Type', 'Electricity', 'Water & Sanitation', 'Roadworks', 'Waste Management']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        dropdownValue = newValue!;
                      });
                    },
                  ),
                  TextField(
                    controller: _faultDescriptionController,
                    decoration: const InputDecoration(
                        labelText: 'Fault Description'),
                  ),
                  const SizedBox(height: 20,),
                  Center(
                    child: Row(
                      children: [
                        ElevatedButton(
                          child: const Text('Report With Photo'),
                          onPressed: () async {
                            DateTime now = DateTime.now();
                            String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);

                            final String uid = _currentUser;
                            String accountNumber = accountPass;
                            final String addressFault = addressPass;
                            final String faultDescription = _faultDescriptionController.text;
                            String faultType = dropdownValue;

                            if (faultType != 'Select Fault Type'){
                              if(faultDescription!=''){
                                if (uid == _currentUser) {
                                  await _faultData.add({
                                    "uid": uid,
                                    "accountNumber": accountNumber,
                                    "address": addressFault,
                                    "reporterContact": userPhone,
                                    "depComment1": '',
                                    "depComment2": '',
                                    "handlerCom1": '',
                                    "handlerCom2": '',
                                    "faultType": faultType,
                                    "faultDescription": faultDescription,
                                    "dateReported": formattedDate,
                                    "depAllocated": '',
                                    "faultResolved": false,
                                    "faultStage": 1,
                                  });

                                }
                                _faultDescriptionController.text ='';
                                dropdownValue = 'Select Fault Type';

                                Fluttertoast.showToast(msg: "Fault has been reported successfully!",
                                  gravity: ToastGravity.CENTER,);


                                // if (!mounted) return;
                                // Navigator.push(context,
                                //     MaterialPageRoute(builder: (context) => FaultImageUpload(propertyAddress: addressFault)
                                //     ));
                                //
                                // final navigator = Navigator.of(context);
                                // navigator.popAndPushNamed(FaultImageUpload(propertyAddress: addressFault) as String);

                                // Navigator.of(context).popAndPushNamed(FaultImageUpload(propertyAddress: addressFault) as String);

                                Get.back();

                              } else {
                                Fluttertoast.showToast(msg: "Please Give A Fault Description!",
                                  gravity: ToastGravity.CENTER,);
                              }
                            } else {
                              Fluttertoast.showToast(msg: "Please Select Fault Type being Reported!!",
                                gravity: ToastGravity.CENTER,);
                            }
                          },
                        ),

                        const SizedBox(width: 20,),

                        ElevatedButton(
                          child: const Text('Report'),
                          onPressed: () async {
                            DateTime now = DateTime.now();
                            String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);

                            final String uid = _currentUser;
                            String accountNumber = accountPass;
                            final String addressFault = addressPass;
                            final String faultDescription = _faultDescriptionController.text;
                            String faultType = dropdownValue;

                            if (faultType != 'Select Fault Type'){
                              if(faultDescription!=''){
                                if (uid == _currentUser) {
                                  await _faultData.add({
                                    "uid": uid,
                                    "accountNumber": accountNumber,
                                    "address": addressFault,
                                    "reporterContact": userPhone,
                                    "depComment1": '',
                                    "depComment2": '',
                                    "handlerCom1": '',
                                    "handlerCom2": '',
                                    "faultType": faultType,
                                    "faultDescription": faultDescription,
                                    "dateReported": formattedDate,
                                    "depAllocated": '',
                                    "faultResolved": false,
                                    "faultStage": 1,
                                  });

                                }
                                _faultDescriptionController.text ='';
                                dropdownValue = 'Select Fault Type';

                                Fluttertoast.showToast(msg: "Fault has been reported successfully!",
                                  gravity: ToastGravity.CENTER,);

                                //Navigator.of(context).pop();
                                Get.back();
                              } else {
                                Fluttertoast.showToast(msg: "Please Give A Fault Description!",
                                  gravity: ToastGravity.CENTER,);
                              }
                            } else {
                              Fluttertoast.showToast(msg: "Please Select Fault Type being Reported!!",
                                gravity: ToastGravity.CENTER,);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Report Fault'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: <Widget>[
          Card(
            margin: const EdgeInsets.all(10),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const Center(
                      child: Text(
                        'Report Public Fault',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10,),

                    Row(
                      children: [
                        Column(
                          children: [
                            DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.lightGreen,
                              border: Border.all(color: Colors.black38, width:3),
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: const <BoxShadow>[
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.57),
                                  blurRadius: 5),
                              ]
                            ),
                            // child: DropdownButton <String>( //DropdownButtonFormField
                            //   value: dropdownValue,
                            //   items: <String>['Select Fault Type', 'Electricity', 'Water & Sanitation', 'Roadworks', 'Waste Management']
                            //       .map<DropdownMenuItem<String>>((String value) {
                            //         return DropdownMenuItem<String>(
                            //           value: value,
                            //           child: Text(
                            //             value,
                            //             style: const TextStyle(fontSize: 16),
                            //           ),
                            //         );
                            //       }).toList(),
                            //   onChanged: (String? newValue) {
                            //     setState(() {
                            //       dropdownValue = newValue!;
                            //     });
                            //     },
                            //   icon: const Padding(
                            //     padding: EdgeInsets.only(left: 20),
                            //     child: Icon(Icons.arrow_circle_down_sharp),
                            //   ),
                            //   iconEnabledColor: Colors.white,
                            //   style: const TextStyle(
                            //     color: Colors.white,
                            //     fontSize: 18
                            //   ),
                            //   dropdownColor: Colors.green,
                            //   underline: Container(),
                            //   isExpanded: true,
                            //
                            // ),
                          ),
                          ]
                        ),


                        ElevatedIconButton(
                          onPress: () async {
                            if(dropdownValue == 'Select Fault Type'){
                              Fluttertoast.showToast(msg: "Please Select The Fault Type First!",
                                gravity: ToastGravity.CENTER,);
                            } else{
                              Navigator.push(context,
                                  MaterialPageRoute(
                                      builder: (context) => GeneralFaultReporting(faultTypeSelected: dropdownValue,)));
                            }
                          },
                          labelText: 'Report',
                          fSize: 16,
                          faIcon: const FaIcon(Icons.report_problem),
                          fgColor: Colors.orangeAccent,
                          btSize: const Size(50, 50),
                        ),

                      ],
                    ),

                    Row(
                      children: [
                        ElevatedIconButton(
                          onPress: () {
                            Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (context) => FaultViewingScreen()));
                          },
                          labelText: 'Current Reports',
                          fSize: 15,
                          faIcon: const FaIcon(Icons.list),
                          fgColor: Colors.green,
                          btSize: const Size(50, 50),
                        ),
                        ElevatedIconButton(
                          onPress: () {
                            showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (context) {
                                  return
                                    AlertDialog(
                                      shape: const RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.all(Radius.circular(16))),
                                      title: const Text("Call Report Center!"),
                                      content: const Text(
                                          "Would you like to call the report center directly?"),
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
                                            final Uri _tel = Uri.parse(
                                                'tel:+27${0800001868}');
                                            launchUrl(_tel);

                                            Navigator.of(context).pop();
                                            Get.back();
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
                          labelText: 'Call Center',
                          fSize: 16,
                          faIcon: const FaIcon(Icons.phone),
                          fgColor: Colors.orangeAccent,
                          btSize: const Size(50, 50),
                        ),

                      ],
                    ),

                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _propList.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                if (streamSnapshot.hasData) {
                  return ListView.builder(

                    ///this call is to display all details for all users but is only displaying for the current user account.
                    ///it can be changed to display all users for the staff to see if the role is set to all later on.
                    itemCount: streamSnapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final DocumentSnapshot documentSnapshot = streamSnapshot.data!.docs[index];
                      String billMessage;

                      ///A check for if payment is outstanding or not
                      if (documentSnapshot['eBill'] != '') {
                        billMessage = documentSnapshot['eBill'];
                        buttonEnabled = false;
                      } else {
                        billMessage = 'No outstanding payments';
                        buttonEnabled = true;
                      }

                      ///Check for only user information, this displays only for the users details and not all users in the database.
                      if (streamSnapshot.data!.docs[index]['user id'] == userID) {
                        return Card(
                          margin: const EdgeInsets.all(10),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Center(
                                  child: Text(
                                    'Property Information',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(height: 20,),
                                Text(
                                  'Account Number: ' + documentSnapshot['account number'],
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: 5,),
                                Text(
                                  'Street Address: ' + documentSnapshot['address'],
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: 5,),
                                Text(
                                  'Area Code: ' + documentSnapshot['area code'].toString(),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: 5,),
                                Text(
                                  'Property Bill: $billMessage',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: 20,),

                                ///Report adding button
                                Center(
                                    child: ElevatedIconButton(
                                      onPress: buttonEnabled ? () {
                                        userPass = _currentUser;
                                        addressPass = documentSnapshot['address'];
                                        accountPass = documentSnapshot['account number'];
                                        phoneNumPass = documentSnapshot['cell number'];

                                        _addNewFaultReport();

                                      } : () {
                                        Fluttertoast.showToast(msg: "Outstanding bill on property, Fault Reporting unavailable!",
                                          gravity: ToastGravity.CENTER,);
                                      },
                                      labelText: 'Report Property Fault',
                                      fSize: 16,
                                      faIcon: const FaIcon(Icons.report),
                                      fgColor: Colors.blue,
                                      btSize: const Size(200, 50),
                                    )
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        ///a card to display ALL details for users when role is set to admin is in "display_info_all_users.dart"
                        return Card();
                      }
                    },
                  );
                }
                return const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
