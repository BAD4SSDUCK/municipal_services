import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:municipal_track/code/MapTools/map_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:municipal_track/code/MapTools/map_screen_prop.dart';

class FaultTaskScreen extends StatefulWidget {
  const FaultTaskScreen({Key? key}) : super(key: key);

  @override
  State<FaultTaskScreen> createState() => _FaultTaskScreenState();
}

final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;

class FireStorageService extends ChangeNotifier{
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async{
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

class _FaultTaskScreenState extends State<FaultTaskScreen> {

  final _accountNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _commentController = TextEditingController();
  final _depAllocationController = TextEditingController();
  late bool _faultResolvedController;
  final _dateReportedController = TextEditingController();

  final CollectionReference _faultData =
  FirebaseFirestore.instance.collection('faultReporting');

  String accountNumberRep = ' ';
  String locationGivenRep = ' ';
  int faultStage = 0;
  String reporterCellGiven = ' ';

  bool visShow = true;
  bool visHide = false;

  bool managerAcc = false;
  bool visStage1 = false;
  bool visStage2 = false;
  bool visStage3 = false;
  bool visStage4 = false;

  final CollectionReference _listUser =
  FirebaseFirestore.instance.collection('users');


  void initApprover(String stateGivenCheck){
    if(stateGivenCheck == 'manager'){
      managerAcc = true;
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
      _descriptionController.text = documentSnapshot['faultDescription'];
      _commentController.text = '';
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
                    visible: visShow,
                    child: TextField(
                      keyboardType: TextInputType.text,
                      controller: _commentController,
                      decoration: const InputDecoration(
                        labelText: 'Comment to Department',),
                    ),
                  ),
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
                    visible: visStage4,
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
                      final String reporterNumber = documentSnapshot['cell number'];
                      final String address = _addressController.text;
                      final String userComment = _commentController.text;
                      final String depAllocated = _depAllocationController.text;
                      final String depSelected = dropdownValue;
                      final bool faultResolved = _faultResolvedController;
                      final String dateRep = _dateReportedController.text;


                      if (faultStage == 1) {
                        if (reporterNumber != null) {
                          await _faultData
                              .doc(documentSnapshot.id)
                              .update({
                            "accountNumber": accountNumber,
                            "address": address,
                            "depComment1": userComment,
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
                        _depAllocationController.text = '';
                        dropdownValue = '';
                        _faultResolvedController = false;
                        _dateReportedController.text = '';

                        visStage1 = false;
                        visStage2 = false;
                        visStage3 = false;
                        visStage4 = false;

                        Navigator.of(context).pop();

                      } else if (faultStage == 2) {
                        if (reporterNumber != null) {
                          await _faultData
                              .doc(documentSnapshot.id)
                              .update({
                            "accountNumber": accountNumber,
                            "address": address,
                            "handlerCom1": userComment,
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
                        _depAllocationController.text = '';
                        dropdownValue = '';
                        _faultResolvedController = false;
                        _dateReportedController.text = '';

                        visStage1 = false;
                        visStage2 = false;
                        visStage3 = false;
                        visStage4 = false;

                        Navigator.of(context).pop();

                      } else if (faultStage == 3) {
                        if (reporterNumber != null) {
                          await _faultData
                              .doc(documentSnapshot.id)
                              .update({
                            "accountNumber": accountNumber,
                            "address": address,
                            "depComment2": userComment,
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
                        _depAllocationController.text = '';
                        dropdownValue = '';
                        _faultResolvedController = false;
                        _dateReportedController.text = '';

                        visStage1 = false;
                        visStage2 = false;
                        visStage3 = false;
                        visStage4 = false;

                        Navigator.of(context).pop();

                      } else if (faultStage == 4) {
                        if (reporterNumber != null) {
                          await _faultData
                              .doc(documentSnapshot.id)
                              .update({
                            "accountNumber": accountNumber,
                            "address": address,
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
                        _depAllocationController.text = '';
                        dropdownValue = '';
                        _faultResolvedController = false;
                        _dateReportedController.text = '';

                        visStage1 = false;
                        visStage2 = false;
                        visStage3 = false;
                        visStage4 = false;

                        Navigator.of(context).pop();

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
        title: const Text('Fault Reports Listed'),
        backgroundColor: Colors.green,
      ),

      body: StreamBuilder(
        stream: _faultData.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                streamSnapshot.data!.docs[index];

                if(streamSnapshot.data!.docs[index]['faultResolved'] == false
                    || documentSnapshot['faultStage'] == 1 || documentSnapshot['faultStage'] == 3){
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
                                  'Department Final Comment: ${documentSnapshot['depComment2']}',
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
                          InkWell(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 5),
                              height: 180,
                              child: Center(
                                child: Card(
                                  color: Colors.blue,
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
                                          context, 'files/faultImages/property/${documentSnapshot['address']}'),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasError) {
                                          return const Text('Image not uploaded for Fault.'); //${snapshot.error} if error needs to be displayed instead
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
                          const SizedBox(height: 20,),
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      accountNumberRep = documentSnapshot['accountNumber'];
                                      locationGivenRep = documentSnapshot['address'];

                                      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      //     content: Text('$accountNumber $locationGiven ')));

                                      Navigator.push(context,
                                          MaterialPageRoute(
                                              builder: (context) => MapScreenProp(propAddress: locationGivenRep, propAccNumber: accountNumberRep,)
                                            //MapPage()
                                          ));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[350],
                                      fixedSize: const Size(150, 10),),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.map,
                                          color: Colors.green[700],
                                        ),
                                        const SizedBox(width: 2,),
                                        const Text('Fault Location', style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,),),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 5,),
                                  ElevatedButton(
                                    onPressed: () {
                                      faultStage = documentSnapshot['faultStage'];
                                      _updateReport(documentSnapshot);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[350],
                                      fixedSize: const Size(150, 10),),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        const SizedBox(width: 2,),
                                        const Text('Update Details', style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,),),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 5,),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context) {
                                        return
                                          AlertDialog(
                                            shape: const RoundedRectangleBorder(
                                                borderRadius:
                                                BorderRadius.all(Radius.circular(16))),
                                            title: const Text("Call Reporter!"),
                                            content: const Text(
                                                "Would you like to call the individual who logged the fault?"),
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
                                                  reporterCellGiven = documentSnapshot['reporterContact'];

                                                  final Uri _tel = Uri.parse('tel:${reporterCellGiven.toString()}');
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
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[350],
                                  fixedSize: const Size(150, 10),),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.call,
                                      color: Colors.orange[700],
                                    ),
                                    const SizedBox(width: 2,),
                                    const Text('Call Reporter', style: TextStyle(
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
                    ),
                  );
                } else if(streamSnapshot.data!.docs[index]['faultResolved'] == false || documentSnapshot['faultStage'] == 2 || documentSnapshot['faultStage'] == 4){
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
                            'Fault Description: ${documentSnapshot['faultDescription']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
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
                          const SizedBox(height: 20,),
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      accountNumberRep = documentSnapshot['accountNumber'];
                                      locationGivenRep = documentSnapshot['address'];

                                      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      //     content: Text('$accountNumber $locationGiven ')));

                                      Navigator.push(context,
                                          MaterialPageRoute(
                                              builder: (context) => MapScreenProp(propAddress: locationGivenRep, propAccNumber: accountNumberRep,)
                                          ));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[350],
                                      fixedSize: const Size(150, 10),),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.map,
                                          color: Colors.green[700],
                                        ),
                                        const SizedBox(width: 2,),
                                        const Text('Fault Location', style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,),),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 5,),
                                  ElevatedButton(
                                    onPressed: () {
                                      faultStage = documentSnapshot['faultStage'];
                                      _updateReport(documentSnapshot);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[350],
                                      fixedSize: const Size(150, 10),),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        const SizedBox(width: 2,),
                                        const Text('Update Details', style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,),),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 5,),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context) {
                                        return
                                          AlertDialog(
                                            shape: const RoundedRectangleBorder(
                                                borderRadius:
                                                BorderRadius.all(Radius.circular(16))),
                                            title: const Text("Call User!"),
                                            content: const Text(
                                                "Would you like to call the individual who logged the fault?"),
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
                                                  reporterCellGiven = documentSnapshot['reporterContact'];

                                                  final Uri _tel = Uri.parse('tel:${reporterCellGiven.toString()}');
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
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[350],
                                  fixedSize: const Size(115, 10),),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.call,
                                      color: Colors.orange[700],
                                    ),
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
                child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
