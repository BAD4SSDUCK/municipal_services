import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:municipal_tracker_msunduzi/code/ImageUploading/image_upload_fault.dart';
import 'package:municipal_tracker_msunduzi/code/MapTools/map_screen.dart';

import 'package:municipal_tracker_msunduzi/code/MapTools/map_screen_prop.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/icon_elevated_button.dart';

class FaultViewingScreen extends StatefulWidget {
  const FaultViewingScreen({Key? key}) : super(key: key);

  @override
  State<FaultViewingScreen> createState() => _FaultViewingScreenState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;

class FireStorageService extends ChangeNotifier{
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async{
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

final User? user = auth.currentUser;
final uid = user?.uid;
final phone = user?.phoneNumber;
String userID = uid as String;
String userPhone = phone as String;

DateTime now = DateTime.now();

class _FaultViewingScreenState extends State<FaultViewingScreen> {

  final _accountNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _commentController = TextEditingController();
  final _wDescriptionController = TextEditingController();
  final _depAllocationController = TextEditingController();
  late bool _faultResolvedController;
  final _dateReportedController = TextEditingController();

  final CollectionReference _faultData =
  FirebaseFirestore.instance.collection('faultReporting');

  final CollectionReference _listUser =
  FirebaseFirestore.instance.collection('users');

  String accountNumberRep = ' ';
  String locationGivenRep = ' ';
  int faultStage = 0;
  String reporterCellGiven = ' ';
  String reporterDateGiven = ' ';

  bool visShow = true;
  bool visHide = false;
  bool imageVisibility = true;

  bool managerAcc = false;
  bool visStage1 = false;
  bool visStage2 = false;
  bool visStage3 = false;
  bool visStage4 = false;

  String formattedDate = DateFormat.MMMM().format(now);

  String dropdownValue = 'Select Month';
  List<String> dropdownMonths = ['Select Month','January','February','March','April','May','June','July','August','September','October','November','December'];

  @override
  void initState() {

    super.initState();
  }

  void initApprove(String stateGivenCheck){
    if(stateGivenCheck == 'manager'){
      managerAcc = true;
    }
  }

  //this widget is for displaying a property field of information with an icon next to it, NB. the icon is to make it look good
  //it is called within a listview page widget
  Widget faultItemField(String faultDat) {
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
            faultDat,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
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

  Future<void> _updateReport([DocumentSnapshot? documentSnapshot]) async {

    String dropdownValue = 'Electricity';

    int stageNum = documentSnapshot!['faultStage'];

    if (stageNum == 1) {
      visStage1 = true;
      visStage2 = false;
      visStage3 = false;
      visStage4 = false;
    } else if (stageNum == 2) {
      visStage1 = false;
      visStage2 = true;
      visStage3 = false;
      visStage4 = false;
    } else if (stageNum == 3) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = true;
      visStage4 = false;
    } else if (stageNum == 4) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = false;
      visStage4 = true;
    }

    if (documentSnapshot != null) {
      _accountNumberController.text = documentSnapshot['accountNumber'];
      _addressController.text = documentSnapshot['address'];
      _descriptionController.text = documentSnapshot['generalFault'];
      _commentController.text = '';
      _wDescriptionController.text = documentSnapshot['waterFaultDes'];
      _depAllocationController.text = documentSnapshot['depAllocated'];
      _faultResolvedController = documentSnapshot['faultResolved'];
      _dateReportedController.text = documentSnapshot['dateReported'];
    }

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
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
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(
                          labelText: 'Account Number'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                          labelText: 'Street Address'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      keyboardType:
                      const TextInputType.numberWithOptions(),
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'General Fault Description',),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _wDescriptionController,
                      decoration: const InputDecoration(
                          labelText: 'Water Fault Description'),
                    ),
                  ),
                  Visibility(
                    visible: visStage1,
                    child: const Text('Department Allocation'),
                  ),
                  Visibility(
                    visible: visStage1,
                    child: DropdownButtonFormField <String>(
                      // Step 3.
                      value: dropdownValue,
                      // Step 4.
                      items: <String>['Electricity', 'Water & Sanitation', 'Roadworks', 'Waste Management']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                      // Step 5.
                      onChanged: (String? newValue) {
                        setState(() {
                          dropdownValue = newValue!;
                        });
                      },
                    ),
                  ),
                  Visibility(
                    visible: visStage1,
                    child: TextField(
                      keyboardType: TextInputType.text,
                      controller: _commentController,
                      decoration: const InputDecoration(
                        labelText: 'Comment to Department',),
                    ),
                  ),
                  // Visibility(
                  //   visible: visShow,
                  //   child: TextField(
                  //     controller: _depAllocationController,
                  //     decoration: const InputDecoration(
                  //         labelText: 'Department Allocation'),
                  //   ),
                  // ),
                  const SizedBox(height: 10,),
                  Visibility(
                    visible: visStage3,
                    child:
                    Row(
                      children: [
                        const Text('Fault Resolved?'),
                        const SizedBox(width: 5,),
                        Checkbox(
                          checkColor: Colors.white,
                          fillColor: MaterialStateProperty.all<Color>(
                              Colors.green),
                          value: _faultResolvedController,
                          onChanged: (bool? value) {
                            setState(() {
                              _faultResolvedController = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _dateReportedController,
                      decoration: const InputDecoration(
                          labelText: 'Date Reported'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    child: const Text('Update'),
                    onPressed: () async {
                      final String accountNumber = _accountNumberController.text;
                      final String address = _addressController.text;
                      final String userComment = _commentController.text;
                      final String depAllocated = _depAllocationController.text;
                      final String depSelected = dropdownValue;
                      final bool faultResolved = _faultResolvedController;
                      final String dateRep = _dateReportedController.text;

                      if (faultStage == 1) {
                        if (accountNumber != null) {
                          await _faultData
                              .doc(documentSnapshot.id)
                              .update({
                            "accountNumber": accountNumber,
                            "address": address,
                            "depComment1": userComment,
                            "depComment2": '',
                            "handlerCom1": '',
                            "handlerCom2": '',
                            "depAllocated": depSelected,
                            "faultResolved": faultResolved,
                            "dateReported": dateRep,
                            "faultStage": 2,
                          });
                        }
                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _commentController.text = '';
                        _wDescriptionController.text = '';
                        _depAllocationController.text = '';
                        dropdownValue = '';
                        _faultResolvedController = false;
                        _dateReportedController.text = '';

                        visStage1 = false;
                        visStage2 = false;
                        visStage3 = false;
                        visStage4 = false;

                        if(context.mounted)Navigator.of(context).pop();

                      } else if (faultStage == 2) {
                        if (accountNumber != null) {
                          await _faultData
                              .doc(documentSnapshot.id)
                              .update({
                            "accountNumber": accountNumber,
                            "address": address,
                            "depComment1": '',
                            "depComment2": '',
                            "handlerCom1": userComment,
                            "handlerCom2": '',
                            "depAllocated": depSelected,
                            "faultResolved": faultResolved,
                            "dateReported": dateRep,
                            "faultStage": 3,
                          });
                        }
                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _commentController.text = '';
                        _wDescriptionController.text = '';
                        _depAllocationController.text = '';
                        dropdownValue = '';
                        _faultResolvedController = false;
                        _dateReportedController.text = '';

                        visStage1 = false;
                        visStage2 = false;
                        visStage3 = false;
                        visStage4 = false;

                        if(context.mounted)Navigator.of(context).pop();

                      } else if (faultStage == 3) {
                        if (accountNumber != null) {
                          await _faultData
                              .doc(documentSnapshot.id)
                              .update({
                            "accountNumber": accountNumber,
                            "address": address,
                            "depComment1": '',
                            "depComment2": userComment,
                            "handlerCom1": '',
                            "handlerCom2": '',
                            "depAllocated": depSelected,
                            "faultResolved": faultResolved,
                            "dateReported": dateRep,
                            "faultStage": 4,
                          });
                        }
                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _commentController.text = '';
                        _wDescriptionController.text = '';
                        _depAllocationController.text = '';
                        dropdownValue = '';
                        _faultResolvedController = false;
                        _dateReportedController.text = '';

                        visStage1 = false;
                        visStage2 = false;
                        visStage3 = false;
                        visStage4 = false;

                        if(context.mounted)Navigator.of(context).pop();

                      } else if (faultStage == 4) {
                        if (accountNumber != null) {
                          await _faultData
                              .doc(documentSnapshot.id)
                              .update({
                            "accountNumber": accountNumber,
                            "address": address,
                            "depComment1": '',
                            "depComment2": '',
                            "handlerCom1": '',
                            "handlerCom2": userComment,
                            "depAllocated": depSelected,
                            "faultResolved": faultResolved,
                            "dateReported": dateRep,
                            "faultStage": 5,
                          });
                        }
                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _commentController.text = '';
                        _wDescriptionController.text = '';
                        _depAllocationController.text = '';
                        dropdownValue = '';
                        _faultResolvedController = false;
                        _dateReportedController.text = '';

                        visStage1 = false;
                        visStage2 = false;
                        visStage3 = false;
                        visStage4 = false;

                        if(context.mounted)Navigator.of(context).pop();

                      }

                    },
                  )
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
        title: const Text('Fault Reports Listed',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: StreamBuilder(
        stream: _faultData.orderBy('dateReported', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                streamSnapshot.data!.docs[index];

                if(streamSnapshot.data!.docs[index]['faultResolved'] == false && streamSnapshot.data!.docs[index]['reporterContact'] == phone){
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
                              'Fault Information',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 10,),
                          Text(
                            'Reporter Account Number: ${documentSnapshot['accountNumber']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'Street Address of Fault: ${documentSnapshot['address']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'Fault Type: ${documentSnapshot['faultType']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),

                          Column(
                            children: [
                              if(documentSnapshot['faultDescription'] != "")...[
                                Text(
                                  'Fault Description: ${documentSnapshot['faultDescription']}',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: 5,),
                              ] else ...[

                              ],
                            ],
                          ),

                          Column(
                            children: [
                              if(documentSnapshot['handlerCom1'] != "")...[
                                Text(
                                  'Handler Comment: ${documentSnapshot['handlerCom1']}',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: 5,),
                              ] else ...[

                              ],
                            ],
                          ),
                          Column(
                            children: [
                              if(documentSnapshot['depComment1'] != "")...[
                                Text(
                                  'Department Comment 1: ${documentSnapshot['depComment1']}',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: 5,),
                              ] else ...[

                              ],
                            ],
                          ),
                          Column(
                            children: [
                              if(documentSnapshot['handlerCom2'] != "")...[
                                Text(
                                  'Handler Final Comment: ${documentSnapshot['handlerCom2']}',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: 5,),
                              ] else ...[

                              ],
                            ],
                          ),
                          Column(
                            children: [
                              if(documentSnapshot['depComment2'] != "")...[
                                Text(
                                  'Department Comment 2: ${documentSnapshot['depComment2']}',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: 5,),
                              ] else ...[

                              ],
                            ],
                          ),

                          Text(
                            'Resolve State: ${documentSnapshot['faultResolved'].toString()}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'Date of Fault Report: ${documentSnapshot['dateReported']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),

                          Column(
                            children: [
                              if(documentSnapshot['faultDescription'] != "")...[
                                Visibility(
                                  visible: imageVisibility,
                                  child: InkWell(
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 5),
                                      height: 180,
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
                                              future: _getImage(
                                                ///Firebase image location must be changed to display image based on the address
                                                  context, 'files/faultImages/${documentSnapshot['dateReported']}/${documentSnapshot['address']}'),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasError) {
                                                  //imageVisibility = false;
                                                  return const Text('Image not uploaded for Fault.', style: TextStyle(fontSize: 18),); //${snapshot.error} if error needs to be displayed instead
                                                }
                                                if (snapshot.connectionState ==
                                                    ConnectionState.done) {
                                                  return Container(
                                                    child: snapshot.data,
                                                  );
                                                }
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
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


                          const SizedBox(height: 20,),
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  BasicIconButtonGreen(
                                    onPress: () {
                                      accountNumberRep = documentSnapshot['accountNumber'];
                                      locationGivenRep = documentSnapshot['address'];

                                      Navigator.push(context,
                                          MaterialPageRoute(
                                              builder: (context) => MapScreenProp(propAddress: locationGivenRep, propAccNumber: accountNumberRep,)
                                            //MapPage()
                                          ));
                                      },
                                    labelText: 'Fault Location',
                                    fSize: 15,
                                    faIcon: const FaIcon(Icons.map),
                                    fgColor: Colors.purple,
                                    btSize: const Size(50, 50),
                                  ),
                                  BasicIconButtonGreen(
                                    onPress: () {

                                      locationGivenRep = documentSnapshot['address'];
                                      reporterDateGiven = documentSnapshot['dateReported'];

                                      Navigator.push(context,
                                          MaterialPageRoute(
                                              builder: (context) => FaultImageUpload(propertyAddress: locationGivenRep, reportedDate: reporterDateGiven)
                                            //MapPage()
                                          ));
                                    },
                                    labelText: 'Add Image',
                                    fSize: 15,
                                    faIcon: const FaIcon(Icons.photo_camera),
                                    fgColor: Colors.blueGrey,
                                    btSize: const Size(50, 50),
                                  ),
                                ],
                              ),

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
                        ],
                      ),
                    ),
                  );
                }
                else {
                  return const Card();
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
                        'No Faults Reported',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),                      ),
                    ),
                  ),
                ),);
        },
      ),
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

}