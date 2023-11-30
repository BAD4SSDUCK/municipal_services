import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'package:municipal_tracker_msunduzi/code/ImageUploading/image_upload_meter.dart';
import 'package:municipal_tracker_msunduzi/code/ImageUploading/image_upload_water.dart';
import 'package:municipal_tracker_msunduzi/code/MapTools/map_screen.dart';
import 'package:municipal_tracker_msunduzi/code/PDFViewer/pdf_api.dart';
import 'package:municipal_tracker_msunduzi/code/PDFViewer/view_pdf.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/icon_elevated_button.dart';


class UsersTableViewPage extends StatefulWidget {
  const UsersTableViewPage({Key? key}) : super(key: key);

  @override
  _UsersTableViewPageState createState() => _UsersTableViewPageState();
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


class _UsersTableViewPageState extends State<UsersTableViewPage> {

  // text fields' controllers
  final _accountNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaCodeController = TextEditingController();
  final _meterNumberController = TextEditingController();
  final _meterReadingController = TextEditingController();
  final _waterMeterController = TextEditingController();
  final _waterMeterReadingController = TextEditingController();
  final _cellNumberController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idNumberController = TextEditingController();

  final _userIDController = userID;

  String formattedMonth = DateFormat.MMMM().format(now);//format for full Month by name
  String formattedDateMonth = DateFormat.MMMMd().format(now);//format for Day Month only

  String dropdownValue = 'Select Month';
  List<String> dropdownMonths = ['Select Month','January','February','March','April','May','June','July','August','September','October','November','December'];

  final CollectionReference _propList =
  FirebaseFirestore.instance.collection('properties');

  ///For getting sub collections within a collection
  // final CollectionReference _propListMonthBill = FirebaseFirestore.instance
  //     .collection('properties').doc('documentID')
  //     .collection('month').doc('monthID') as CollectionReference<Object?>;

  Future<void> updateImgCheckE(bool imgCheck, [DocumentSnapshot? documentSnapshot]) async{
    if (documentSnapshot != null) {
      await _propList
          .doc(documentSnapshot.id)
          .update({
        "imgStateE": imgCheck,
      });
    }

  }

  Future<void> updateImgCheckW(bool imgCheck, [DocumentSnapshot? documentSnapshot]) async{
    if (documentSnapshot != null) {
      await _propList
          .doc(documentSnapshot.id)
          .update({
        "imgStateW": imgCheck,
      });
    }

  }

  Future<void> _create([DocumentSnapshot? documentSnapshot]) async {
    _accountNumberController.text = '';
    _addressController.text = '';
    _areaCodeController.text = '';
    _meterNumberController.text = '';
    _meterReadingController.text = '';
    _waterMeterController.text = '';
    _waterMeterReadingController.text = '';
    _cellNumberController.text = '';
    _firstNameController.text = '';
    _lastNameController.text = '';
    _idNumberController.text = '';

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
                    visible: visibilityState1,
                    child: TextField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(labelText: 'Account Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Street Address'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      keyboardType:
                      const TextInputType.numberWithOptions(),
                      controller: _areaCodeController,
                      decoration: const InputDecoration(labelText: 'Area Code',),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _meterNumberController,
                      decoration: const InputDecoration(labelText: 'Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _meterReadingController,
                      decoration: const InputDecoration(labelText: 'Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _waterMeterController,
                      decoration: const InputDecoration(labelText: 'Water Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _waterMeterReadingController,
                      decoration: const InputDecoration(labelText: 'Water Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _cellNumberController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _idNumberController,
                      decoration: const InputDecoration(labelText: 'ID Number'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    child: const Text('Create'),
                    onPressed: () async {
                      final String accountNumber = _accountNumberController.text;
                      final String address = _addressController.text;
                      final String areaCode = _areaCodeController.text;
                      final String meterNumber = _meterNumberController.text;
                      final String meterReading = _meterReadingController.text;
                      final String waterMeterNumber = _waterMeterController.text;
                      final String waterMeterReading = _waterMeterReadingController.text;
                      final String cellNumber = _cellNumberController.text;
                      final String firstName = _firstNameController.text;
                      final String lastName = _lastNameController.text;
                      final String idNumber = _idNumberController.text;

                      if (accountNumber != null) {
                        await _propList.add({
                          "account number": accountNumber,
                          "address": address,
                          "area code": areaCode,
                          "meter number": meterNumber,
                          "meter reading": meterReading,
                          "water meter number": waterMeterNumber,
                          "water meter reading": waterMeterReading,
                          "cell number": cellNumber,
                          "first name": firstName,
                          "last name": lastName,
                          "id number": idNumber
                        });

                        await FirebaseFirestore.instance
                            .collection('consumption').doc(formattedMonth)
                            .collection('address').doc(address).set({
                          "address": address,
                          "meter reading": meterReading,
                          "water meter reading": waterMeterReading,
                        });

                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _areaCodeController.text = '';
                        _meterNumberController.text = '';
                        _meterReadingController.text = '';
                        _waterMeterController.text = '';
                        _waterMeterReadingController.text = '';
                        _cellNumberController.text = '';
                        _firstNameController.text = '';
                        _lastNameController.text = '';
                        _idNumberController.text = '';

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

  /// on update the only info necessary to change should be meter reading
  Future<void> _update([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      _accountNumberController.text = documentSnapshot['account number'];
      _addressController.text = documentSnapshot['address'];
      _areaCodeController.text = documentSnapshot['area code'].toString();
      _meterNumberController.text = documentSnapshot['meter number'];
      _meterReadingController.text = documentSnapshot['meter reading'];
      _waterMeterController.text = documentSnapshot['water meter number'];
      _waterMeterReadingController.text = documentSnapshot['water meter reading'];
      _cellNumberController.text = documentSnapshot['cell number'];
      _firstNameController.text = documentSnapshot['first name'];
      _lastNameController.text = documentSnapshot['last name'];
      _idNumberController.text = documentSnapshot['id number'];
      userID = documentSnapshot['user id'];
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
                    visible: visibilityState2,
                    child: TextField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(labelText: 'Account Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Street Address'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      keyboardType:
                      const TextInputType.numberWithOptions(),
                      controller: _areaCodeController,
                      decoration: const InputDecoration(labelText: 'Area Code',),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _meterNumberController,
                      decoration: const InputDecoration(labelText: 'Electricity Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _meterReadingController,
                      decoration: const InputDecoration(labelText: 'Electricity Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _waterMeterController,
                      decoration: const InputDecoration(labelText: 'Water Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _waterMeterReadingController,
                      decoration: const InputDecoration(labelText: 'Water Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _cellNumberController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _idNumberController,
                      decoration: const InputDecoration(labelText: 'ID Number'),
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
                      final int areaCode = int.parse(_areaCodeController.text);
                      final String meterNumber = _meterNumberController.text;
                      final String meterReading = _meterReadingController.text;
                      final String waterMeterNumber = _waterMeterController.text;
                      final String waterMeterReading = _waterMeterReadingController.text;
                      final String cellNumber = _cellNumberController.text;
                      final String firstName = _firstNameController.text;
                      final String lastName = _lastNameController.text;
                      final String idNumber = _idNumberController.text;

                      if (accountNumber != null) {
                        await _propList
                            .doc(documentSnapshot!.id)
                            .update({
                          "account number": accountNumber,
                          "address": address,
                          "area code": areaCode,
                          "meter number": meterNumber,
                          "meter reading": meterReading,
                          "water meter number": waterMeterNumber,
                          "water meter reading": waterMeterReading,
                          "cell number": cellNumber,
                          "first name": firstName,
                          "last name": lastName,
                          "id number": idNumber,
                          "user id" : userID,
                        });

                        await FirebaseFirestore.instance
                            .collection('consumption').doc(formattedMonth)
                            .collection('address').doc(address).set({
                          "address": address,
                          "meter reading": meterReading,
                          "water meter reading": waterMeterReading,
                        });

                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _areaCodeController.text = '';
                        _meterNumberController.text = '';
                        _meterReadingController.text = '';
                        _waterMeterController.text = '';
                        _waterMeterReadingController.text = '';
                        _cellNumberController.text = '';
                        _firstNameController.text = '';
                        _lastNameController.text = '';
                        _idNumberController.text = '';

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

  Future<void> _updateE([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      _accountNumberController.text = documentSnapshot['account number'];
      _addressController.text = documentSnapshot['address'];
      _areaCodeController.text = documentSnapshot['area code'].toString();
      _meterNumberController.text = documentSnapshot['meter number'];
      _meterReadingController.text = documentSnapshot['meter reading'];
      _waterMeterController.text = documentSnapshot['water meter number'];
      _waterMeterReadingController.text = documentSnapshot['water meter reading'];
      _cellNumberController.text = documentSnapshot['cell number'];
      _firstNameController.text = documentSnapshot['first name'];
      _lastNameController.text = documentSnapshot['last name'];
      _idNumberController.text = documentSnapshot['id number'];
      userID = documentSnapshot['user id'];
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
                    visible: visibilityState2,
                    child: TextField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(labelText: 'Account Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Street Address'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      keyboardType:
                      const TextInputType.numberWithOptions(),
                      controller: _areaCodeController,
                      decoration: const InputDecoration(labelText: 'Area Code',),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _meterNumberController,
                      decoration: const InputDecoration(labelText: 'Electricity Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: _meterReadingController,
                      decoration: const InputDecoration(labelText: 'Electricity Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _waterMeterController,
                      decoration: const InputDecoration(labelText: 'Water Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: _waterMeterReadingController,
                      decoration: const InputDecoration(labelText: 'Water Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _cellNumberController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _idNumberController,
                      decoration: const InputDecoration(labelText: 'ID Number'),
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
                      final int areaCode = int.parse(_areaCodeController.text);
                      final String meterNumber = _meterNumberController.text;
                      final String meterReading = _meterReadingController.text;
                      final String waterMeterNumber = _waterMeterController.text;
                      final String waterMeterReading = _waterMeterReadingController.text;
                      final String cellNumber = _cellNumberController.text;
                      final String firstName = _firstNameController.text;
                      final String lastName = _lastNameController.text;
                      final String idNumber = _idNumberController.text;

                      if (accountNumber != null) {
                        await _propList
                            .doc(documentSnapshot!.id)
                            .update({
                          "account number": accountNumber,
                          "address": address,
                          "area code": areaCode,
                          "meter number": meterNumber,
                          "meter reading": meterReading,
                          "water meter number": waterMeterNumber,
                          "water meter reading": waterMeterReading,
                          "cell number": cellNumber,
                          "first name": firstName,
                          "last name": lastName,
                          "id number": idNumber,
                          "user id" : userID,
                        });

                        await FirebaseFirestore.instance
                            .collection('consumption').doc(formattedMonth)
                            .collection('address').doc(address).set({
                          "address": address,
                          "meter reading": meterReading,
                          "water meter reading": waterMeterReading,
                        });

                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _areaCodeController.text = '';
                        _meterNumberController.text = '';
                        _meterReadingController.text = '';
                        _waterMeterController.text = '';
                        _waterMeterReadingController.text = '';
                        _cellNumberController.text = '';
                        _firstNameController.text = '';
                        _lastNameController.text = '';
                        _idNumberController.text = '';

                        if(context.mounted)Navigator.of(context).pop();
                        ///Added open the image upload straight after inputting the meter reading
                        if(context.mounted) {
                          showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text("Upload Electricity Meter"),
                                  content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
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
                                        Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
                                        Navigator.push(context,
                                            MaterialPageRoute(builder: (context) => ImageUploadMeter(userNumber: cellNumber, meterNumber: meterNumber,)));
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
                    },
                  )
                ],
              ),
            ),
          );
        });
  }

  Future<void> _updateW([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      _accountNumberController.text = documentSnapshot['account number'];
      _addressController.text = documentSnapshot['address'];
      _areaCodeController.text = documentSnapshot['area code'].toString();
      _meterNumberController.text = documentSnapshot['meter number'];
      _meterReadingController.text = documentSnapshot['meter reading'];
      _waterMeterController.text = documentSnapshot['water meter number'];
      _waterMeterReadingController.text = documentSnapshot['water meter reading'];
      _cellNumberController.text = documentSnapshot['cell number'];
      _firstNameController.text = documentSnapshot['first name'];
      _lastNameController.text = documentSnapshot['last name'];
      _idNumberController.text = documentSnapshot['id number'];
      userID = documentSnapshot['user id'];
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
                    visible: visibilityState2,
                    child: TextField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(labelText: 'Account Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Street Address'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      keyboardType:
                      const TextInputType.numberWithOptions(),
                      controller: _areaCodeController,
                      decoration: const InputDecoration(labelText: 'Area Code',),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _meterNumberController,
                      decoration: const InputDecoration(labelText: 'Electricity Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: _meterReadingController,
                      decoration: const InputDecoration(labelText: 'Electricity Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _waterMeterController,
                      decoration: const InputDecoration(labelText: 'Water Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: _waterMeterReadingController,
                      decoration: const InputDecoration(labelText: 'Water Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _cellNumberController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _idNumberController,
                      decoration: const InputDecoration(labelText: 'ID Number'),
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
                      final int areaCode = int.parse(_areaCodeController.text);
                      final String meterNumber = _meterNumberController.text;
                      final String meterReading = _meterReadingController.text;
                      final String waterMeterNumber = _waterMeterController.text;
                      final String waterMeterReading = _waterMeterReadingController.text;
                      final String cellNumber = _cellNumberController.text;
                      final String firstName = _firstNameController.text;
                      final String lastName = _lastNameController.text;
                      final String idNumber = _idNumberController.text;

                      if (accountNumber != null) {
                        await _propList
                            .doc(documentSnapshot!.id)
                            .update({
                          "account number": accountNumber,
                          "address": address,
                          "area code": areaCode,
                          "meter number": meterNumber,
                          "meter reading": meterReading,
                          "water meter number": waterMeterNumber,
                          "water meter reading": waterMeterReading,
                          "cell number": cellNumber,
                          "first name": firstName,
                          "last name": lastName,
                          "id number": idNumber,
                          "user id" : userID,
                        });

                        await FirebaseFirestore.instance
                            .collection('consumption').doc(formattedMonth)
                            .collection('address').doc(address).set({
                          "address": address,
                          "meter reading": meterReading,
                          "water meter reading": waterMeterReading,
                        });

                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _areaCodeController.text = '';
                        _meterNumberController.text = '';
                        _meterReadingController.text = '';
                        _waterMeterController.text = '';
                        _waterMeterReadingController.text = '';
                        _cellNumberController.text = '';
                        _firstNameController.text = '';
                        _lastNameController.text = '';
                        _idNumberController.text = '';

                        if(context.mounted)Navigator.of(context).pop();
                        ///Added open the image upload straight after inputting the meter reading
                        if(context.mounted) {
                          showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text("Upload Water Meter"),
                                  content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
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
                                        Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
                                        Navigator.push(context,
                                            MaterialPageRoute(builder: (context) => ImageUploadWater(userNumber: cellNumber, meterNumber: waterMeterNumber,)));
                                      },
                                      icon: const Icon(
                                        Icons.done,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                );
                              });}
                      }
                    },
                  )
                ],
              ),
            ),
          );
        });
  }

  Future<void> _delete(String users) async {
    await _propList.doc(users).delete();
    Fluttertoast.showToast(msg: "You have successfully deleted an account!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Account Management',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(0.0,10.0,0.0,10.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _propList.snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
            if (streamSnapshot.hasData) {
              return ListView.builder(
                ///this call is to display all details for all users but is only displaying for the current user account.
                ///it can be changed to display all users for the staff to see if the role is set to all later on.
                itemCount: streamSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final DocumentSnapshot documentSnapshot =
                  streamSnapshot.data!.docs[index];

                  eMeterNumber = documentSnapshot['meter number'];
                  wMeterNumber = documentSnapshot['water meter number'];
                  propPhoneNum = documentSnapshot['cell number'];

                  String billMessage;///A check for if payment is outstanding or not
                  if(documentSnapshot['eBill'] != '' ||
                      documentSnapshot['eBill'] != 'R0,000.00' ||
                      documentSnapshot['eBill'] != 'R0.00' ||
                      documentSnapshot['eBill'] != 'R0' ||
                      documentSnapshot['eBill'] != '0'
                  ){
                    billMessage = 'Utilities bill outstanding: ${documentSnapshot['eBill']}';
                  } else {
                    billMessage = 'No outstanding payments';
                  }

                  ///Check for only user information, this displays only for the users details and not all users in the database.
                  if(streamSnapshot.data!.docs[index]['cell number'] == phoneNum){
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
                              'Account Number: ${documentSnapshot['account number']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Street Address: ${documentSnapshot['address']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Area Code: ${documentSnapshot['area code']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Electric Meter Number: ${documentSnapshot['meter number']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Electric Meter Reading: ${documentSnapshot['meter reading']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Water Meter Number: ${documentSnapshot['water meter number']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Water Meter Reading: ${documentSnapshot['water meter reading']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Phone Number: ${documentSnapshot['cell number']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'First Name: ${documentSnapshot['first name']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Surname: ${documentSnapshot['last name']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'ID Number: ${documentSnapshot['id number']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 20,),

                            const Center(
                              child: Text(
                                'Electricity Meter Reading Photo',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 5,),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        eMeterNumber = documentSnapshot['meter number'];
                                        propPhoneNum = documentSnapshot['cell number'];
                                        showDialog(
                                            barrierDismissible: false,
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: const Text("Upload Electricity Meter"),
                                                content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
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
                                                      Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
                                                      Navigator.push(context,
                                                          MaterialPageRoute(builder: (context) => ImageUploadMeter(userNumber: propPhoneNum, meterNumber: eMeterNumber,)));
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
                                      labelText: 'Electricity',
                                      fSize: 16,
                                      faIcon: const FaIcon(Icons.camera_alt,),
                                      fgColor: Colors.black38,
                                      btSize: const Size(100, 38),
                                    ),
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        _updateE(documentSnapshot);
                                      },
                                      labelText: 'Capture',
                                      fSize: 16,
                                      faIcon: const FaIcon(Icons.edit,),
                                      fgColor: Theme.of(context).primaryColor,
                                      btSize: const Size(100, 38),
                                    ),
                                  ],
                                )
                              ],
                            ),
                            ///Image display item needs to get the reference from the firestore using the users uploaded meter connection
                            InkWell(
                              ///onTap allows to open image upload page if user taps on the image.
                              ///Can be later changed to display the picture zoomed in if user taps on it.
                              onTap: () {
                                eMeterNumber = documentSnapshot['meter number'];
                                propPhoneNum = documentSnapshot['cell number'];
                                showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text("Upload Electricity Meter"),
                                    content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
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
                                          Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
                                          Navigator.push(context,
                                              MaterialPageRoute(builder: (context) => ImageUploadMeter(userNumber: propPhoneNum, meterNumber: eMeterNumber,)));
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
                                          ///Firebase image location must be changed to display image based on the meter number
                                            context, 'files/meters/$formattedMonth/$propPhoneNum/electricity/$eMeterNumber.jpg'),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasError) {

                                            imgUploadCheck = false;
                                            updateImgCheckE(imgUploadCheck,documentSnapshot);

                                            return const Padding(
                                              padding: EdgeInsets.all(20.0),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text('Image not yet uploaded.',),
                                                    SizedBox(height: 10,),
                                                    FaIcon(Icons.camera_alt,),
                                                  ],
                                                ),
                                            );
                                          }
                                          if (snapshot.connectionState == ConnectionState.done) {

                                            imgUploadCheck = true;
                                            updateImgCheckE(imgUploadCheck,documentSnapshot);

                                            return Container(
                                              child: snapshot.data,
                                            );
                                          }
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return Container(
                                              child: const Padding(
                                                padding: EdgeInsets.all(5.0),
                                                child: CircularProgressIndicator(),
                                              ),);
                                          }
                                          return Container();
                                        }
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            const Center(
                              child: Text(
                                'Water Meter Reading Photo',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 5,),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        wMeterNumber = documentSnapshot['water meter number'];
                                        propPhoneNum = documentSnapshot['cell number'];
                                        showDialog(
                                            barrierDismissible: false,
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: const Text("Upload Water Meter"),
                                                content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
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
                                                      Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
                                                      Navigator.push(context,
                                                          MaterialPageRoute(builder: (context) => ImageUploadWater(userNumber: propPhoneNum, meterNumber: wMeterNumber,)));
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
                                      labelText: 'Water',
                                      fSize: 16,
                                      faIcon: const FaIcon(Icons.camera_alt,),
                                      fgColor: Colors.black38,
                                      btSize: const Size(100, 38),
                                    ),
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        _updateW(documentSnapshot);
                                      },
                                      labelText: 'Capture',
                                      fSize: 16,
                                      faIcon: const FaIcon(Icons.edit,),
                                      fgColor: Theme.of(context).primaryColor,
                                      btSize: const Size(100, 38),
                                    ),
                                  ],
                                )
                              ],
                            ),
                            InkWell(
                              ///onTap allows to open image upload page if user taps on the image.
                              ///Can be later changed to display the picture zoomed in if user taps on it.
                              onTap: () {
                                wMeterNumber = documentSnapshot['water meter number'];
                                propPhoneNum = documentSnapshot['cell number'];
                                showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text("Upload Water Meter Image"),
                                    content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
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
                                          propPhoneNum = documentSnapshot['water meter number'];
                                          Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
                                          Navigator.push(context,
                                              MaterialPageRoute(builder: (context) => ImageUploadWater(userNumber: propPhoneNum, meterNumber: wMeterNumber,)));
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
                                        future: _getImageW(
                                          ///Firebase image location must be changed to display image based on the meter number
                                            context, 'files/meters/$formattedMonth/$propPhoneNum/water/$wMeterNumber.jpg'),//$meterNumber
                                        builder: (context, snapshot) {
                                          if (snapshot.hasError) {

                                            imgUploadCheck = false;
                                            updateImgCheckW(imgUploadCheck,documentSnapshot);

                                            return const Padding(
                                              padding: EdgeInsets.all(20.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('Image not yet uploaded.',),
                                                  SizedBox(height: 10,),
                                                  FaIcon(Icons.camera_alt,),
                                                ],
                                              ),
                                            );
                                          }
                                          if (snapshot.connectionState == ConnectionState.done) {

                                            imgUploadCheck = true;
                                            updateImgCheckW(imgUploadCheck,documentSnapshot);

                                            return Container(
                                              child: snapshot.data,
                                            );
                                          }
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Container(
                                              child: const Padding(
                                                padding: EdgeInsets.all(5.0),
                                                child: CircularProgressIndicator(),
                                              ),);
                                          }
                                          return Container();
                                        }
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            Text(
                              billMessage,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),

                            const SizedBox(height: 10,),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        Fluttertoast.showToast(
                                            msg: "Now downloading your statement!\nPlease wait a few seconds!");

                                        String accountNumberPDF = documentSnapshot['account number'];
                                        print('The acc number is ::: $accountNumberPDF');

                                        final storageRef = FirebaseStorage.instance.ref().child("pdfs/$formattedMonth");
                                        final listResult = await storageRef.listAll();
                                        for (var prefix in listResult.prefixes) {
                                          print('The ref is ::: $prefix');
                                          // The prefixes under storageRef.
                                          // You can call listAll() recursively on them.
                                        }
                                        for (var item in listResult.items) {
                                          print('The item is ::: $item');
                                          // The items under storageRef.
                                          if (item.toString().contains(accountNumberPDF)) {
                                            final url = item.fullPath;
                                            print('The url is ::: $url');
                                            final file = await PDFApi.loadFirebase(url);
                                            try {
                                              Fluttertoast.showToast(
                                                  msg: "Download Successful!");
                                              if(context.mounted)openPDF(context, file);
                                            } catch (e) {
                                              Fluttertoast.showToast(msg: "Unable to download statement.");
                                            }
                                          } else {
                                            Fluttertoast.showToast(msg: "Unable to download statement.");
                                          }
                                        }
                                      },
                                      labelText: 'Invoice',
                                      fSize: 16,
                                      faIcon: const FaIcon(Icons.picture_as_pdf,),
                                      fgColor: Colors.orangeAccent,
                                      btSize: const Size(100, 38),
                                    ),
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        accountNumber = documentSnapshot['account number'];
                                        locationGiven = documentSnapshot['address'];

                                        Navigator.push(context,
                                            MaterialPageRoute(builder: (context) => const MapScreen()
                                              //MapPage()
                                            ));
                                      },
                                      labelText: 'Map',
                                      fSize: 16,
                                      faIcon: const FaIcon(Icons.map,),
                                      fgColor: Colors.green,
                                      btSize: const Size(100, 38),
                                    ),
                                    const SizedBox(width: 5,),
                                  ],
                                ),
                              ],
                            ),
                                    ///No need for a delete button but this is what a delete would look like
                                    // GestureDetector(
                                    //   onTap: () {
                                    //     showDialog(
                                    //         barrierDismissible: false,
                                    //         context: context,
                                    //         builder: (context) {
                                    //           return AlertDialog(
                                    //             title: const Text(
                                    //                 "Deleting Property Information"),
                                    //             content: const Text(
                                    //                 "Deleting this property will remove it entirely! Are you sure?"),
                                    //             actions: [
                                    //               IconButton(
                                    //                 onPressed: () {
                                    //                   Navigator.pop(context);
                                    //                 },
                                    //                 icon: const Icon(
                                    //                   Icons.cancel,
                                    //                   color: Colors.red,
                                    //                 ),
                                    //               ),
                                    //               IconButton(
                                    //                 onPressed: () async {
                                    //                   ScaffoldMessenger.of(
                                    //                       this.context)
                                    //                       .showSnackBar(
                                    //                     const SnackBar(
                                    //                       content: Text(
                                    //                           'Property was deleted!'),
                                    //                     ),
                                    //                   );
                                    //                   _delete(documentSnapshot.id);
                                    //                   Navigator.pop(context);
                                    //                 },
                                    //                 icon: const Icon(
                                    //                   Icons.done,
                                    //                   color: Colors.green,
                                    //                 ),
                                    //               ),
                                    //             ],
                                    //           );
                                    //         });
                                    //  },
                                    //   child: Row(
                                    //     children: [
                                    //       Icon(
                                    //         Icons.delete,
                                    //         color: Colors.red[700],
                                    //       ),
                                    //     ],
                                    //   ),
                                    // ),

                          ],
                        ),
                      ),
                    );
                  }///end of single user information display.
                  else {
                    return const SizedBox(height: 0,width: 0,);
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
                        'No properties registered on this number yet.',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            );
            // return const Padding(
            //   padding: EdgeInsets.all(10.0),
            //   child: Center(
            //       child: CircularProgressIndicator()),
            // );
          },
        ),
      ),

      /// Add new account, removed because it was not necessary for non-staff users.
      //   floatingActionButton: FloatingActionButton(
      //     onPressed: () => _create(),
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