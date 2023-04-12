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

class FaultTaskScreen extends StatefulWidget {
  const FaultTaskScreen({Key? key}) : super(key: key);

  @override
  State<FaultTaskScreen> createState() => _FaultTaskScreenState();
}

class _FaultTaskScreenState extends State<FaultTaskScreen> {

  final _accountNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _eDescriptionController = TextEditingController();
  final _wDescriptionController = TextEditingController();
  final _depAllocationController = TextEditingController();
  bool _faultResolvedController = false;
  final _dateReportedController = TextEditingController();

  final CollectionReference _faultData =
  FirebaseFirestore.instance.collection('faultReporting');

  String accountNumber = ' ';
  String locationGiven = ' ';

  bool visShow = true;
  bool visHide = false;


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
    if (documentSnapshot != null) {
      _accountNumberController.text = documentSnapshot['accountNumber'];
      _addressController.text = documentSnapshot['address'];
      _descriptionController.text = documentSnapshot['generalFault'];
      _eDescriptionController.text = documentSnapshot['electricityFaultDes'];
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
                  bottom: MediaQuery
                      .of(ctx)
                      .viewInsets
                      .bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(labelText: 'Account Number'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Street Address'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      keyboardType:
                      const TextInputType.numberWithOptions(),
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'General Fault Description',),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      keyboardType:
                      const TextInputType.numberWithOptions(),
                      controller: _eDescriptionController,
                      decoration: const InputDecoration(labelText: 'Electricity Fault Description',),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _wDescriptionController,
                      decoration: const InputDecoration(labelText: 'Water Fault Description'),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _depAllocationController,
                      decoration: const InputDecoration(labelText: 'Department Allocation'),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child:
                    Row(
                      children: [
                        const Text('Fault Resolved?'),
                        const SizedBox(width: 5,),
                        Checkbox(
                          checkColor: Colors.white,
                          fillColor: MaterialStateProperty.all<Color>(Colors.green),
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
                      decoration: const InputDecoration(labelText: 'Date Reported'),
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
                      final String gDescription = _descriptionController.text;
                      final String eDescription = _eDescriptionController.text;
                      final String wDescription = _wDescriptionController.text;
                      final String depAllocated = _depAllocationController.text;
                      final bool faultResolved = _faultResolvedController;
                      final String dateRep = _dateReportedController.text;

                      if (accountNumber != null) {
                        await _faultData
                            .doc(documentSnapshot!.id)
                            .update({
                          "accountNumber": accountNumber,
                          "address": address,
                          "generalFault": gDescription,
                          "electricityFaultDes": eDescription,
                          "waterFaultDes": wDescription,
                          "depAllocated": depAllocated,
                          "faultResolved": faultResolved,
                          "dateReported": dateRep,
                        });

                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _eDescriptionController.text = '';
                        _wDescriptionController.text = '';
                        _depAllocationController.text = '';
                        _faultResolvedController = false;
                        _dateReportedController.text = '';

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

                if(documentSnapshot['faultResolved'] == false) {
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
                            'Reporter Account Number: ' + documentSnapshot['accountMumber'],
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'Street Address of Fault: ' + documentSnapshot['address'],
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'General Fault: ' + documentSnapshot['generalFault'].toString(),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'Electrical Fault: ' + documentSnapshot['electricityFaultDes'].toString(),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'Water Fault: ' + documentSnapshot['waterFaultDes'],
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'Resolve State: ' + documentSnapshot['faultResolved'].toString(),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'Date of Fault Report: ' + documentSnapshot['dateReported'],
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
                                      _updateReport(documentSnapshot);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[350],
                                      fixedSize: const Size(150, 10),),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit,
                                          color: Theme
                                              .of(context)
                                              .primaryColor,
                                        ),
                                        const SizedBox(width: 2,),
                                        const Text('Update Details', style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,),),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 5,),

                                  ElevatedButton(
                                    onPressed: () {
                                      accountNumber =
                                      documentSnapshot['accountNumber'];
                                      locationGiven =
                                      documentSnapshot['address'];

                                      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      //     content: Text('$accountNumber $locationGiven ')));

                                      Navigator.push(context,
                                          MaterialPageRoute(
                                              builder: (context) => MapScreen()
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
                                  const SizedBox(width: 6,),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
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