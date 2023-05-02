import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:path/path.dart';
// import 'package:location/location.dart';
// import 'package:location/location.dart' as loc;

import 'package:url_launcher/url_launcher.dart';


class GeneralFaultReporting extends StatefulWidget {

  const GeneralFaultReporting({Key? key}) : super(key: key);

  @override
  State<GeneralFaultReporting> createState() => _GeneralFaultReportingState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

final User? user = auth.currentUser;
final uid = user?.uid;
final phone = user?.phoneNumber;
String userID = uid as String;
String userPhone = phone as String;

class _GeneralFaultReportingState extends State<GeneralFaultReporting> {

  final _accountNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _depAllocationController = TextEditingController();
  final _dateReportedController = TextEditingController();

  final CollectionReference _faultData =
  FirebaseFirestore.instance.collection('faultReporting');

  bool visShow = true;
  bool visHide = false;

  File? _photo;
  final ImagePicker _picker = ImagePicker();
  String? meterType;

  final String _currentUser = userID;
  TextEditingController nameController = TextEditingController();
  bool buttonEnabled = true;
  String location ='Null, Press Button';
  String Address = 'search';

  @override
  void initState() {
    locationAllow();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('General Fault Reporting'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 50,),
            Center(
              child: GestureDetector(
                onTap: () {
                  _showPicker(context);
                },
                child: CircleAvatar(
                  radius: 190,
                  backgroundColor: Colors.grey[400],
                  child: _photo != null ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _photo!, width: 250, height: 250, fit: BoxFit.cover,),
                  )
                      : Container(decoration: BoxDecoration(color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10)), width: 250, height: 250, child: Icon(Icons.camera_alt, color: Colors.grey[800],),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80,),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: GestureDetector(
                onTap: buttonEnabled? () {
                  if (_photo != null) {
                    showPressed(context);
                  } else {
                    Fluttertoast.showToast(msg: "Please tap on the image area and select the image to upload!", gravity: ToastGravity.CENTER);
                  }
                } : (){
                  Fluttertoast.showToast(msg: "Please fill all fields!", gravity: ToastGravity.CENTER);
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Report Fault With Image',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10,),
          ],
        ),
      ),
    );
  }

  Future<void> locationAllow() async {
    Position position = await _getGeoLocationPosition();
    location ='Lat: ${position.latitude} , Long: ${position.longitude}';
    GetAddressFromLatLong(position);
    if(_getGeoLocationPosition.isBlank == false){
      buttonEnabled = true;
    }
  }

  //Used to set the _photo file as image from gallery
  Future imgFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60,);

    setState(() {
      if (pickedFile != null) {
        _photo = File(pickedFile.path);
        uploadFaultFile();
      } else {
        print('No image selected.');
      }
    });
  }

  //Used to set the _photo file as image from gallery
  Future imgFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 60,);

    setState(() {
      if (pickedFile != null) {
        _photo = File(pickedFile.path);
        uploadFaultFile();
      } else {
        print('No image selected.');
      }
    });
  }

  Future uploadFaultFile() async {
    if (_photo == null) return;

    final fileName = basename(_photo!.path);
    final destination = 'files/faultImages/general/';

    File? imageFile = _photo;
    List<int> imageBytes = imageFile!.readAsBytesSync();
    String imageData = base64Encode(imageBytes);

    final String photoName;

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);

    final String accountNumber = _accountNumberController.text;
    final String addressFault = Address;
    final String faultDescription = _descriptionController.text;

    if (_currentUser != null) {
      await _faultData.add({
        "uid": _currentUser,
        "accountNumber": '',
        "address": addressFault,
        "reporterContact": userPhone,
        "depComment1": '',
        "depComment2": '',
        "handlerCom1": '',
        "handlerCom2": '',
        "generalFault": faultDescription,
        "electricityFaultDes": '',
        "waterFaultDes": '',
        "depAllocated": '',
        "faultResolved": false,
        "dateReported": formattedDate,
        "faultStage": 1,
      });

      try {
        final ref = firebase_storage.FirebaseStorage.instance
            .ref(destination)
            .child('$addressFault/');   ///this is the jpg filename which needs to be named something on the db in order to display in the display screen
        await ref.putFile(_photo!);
        photoName = _photo!.toString();
        print(destination);
      } catch (e) {
        print('error occured');
      }

      _accountNumberController.text = '';
      _addressController.text = '';
      _accountNumberController.text = '';
      _addressController.text = '';
      _depAllocationController.text = '';
      _dateReportedController.text = '';

    } else {
      Fluttertoast.showToast(msg: "Connection failed. Fix network!",
          gravity: ToastGravity.CENTER);
    }
  }
  
  showImage(String image){
    return Image.memory(base64Decode(image));
  }

  Future<Position> _getGeoLocationPosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {

        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> GetAddressFromLatLong(Position position)async {
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    print(placemarks);
    Placemark place = placemarks[0];
    Address = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
  }

  void _showPicker(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Container(
              child: new Wrap(
                children: <Widget>[
                  new ListTile(
                      leading: new Icon(Icons.photo_library),
                      title: new Text('Gallery'),
                      onTap: () {
                        imgFromGallery();
                        Navigator.of(context).pop();
                      }),
                  new ListTile(
                    leading: new Icon(Icons.photo_camera),
                    title: new Text('Camera'),
                    onTap: () {
                      imgFromCamera();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }

  Future<void> showPressed(BuildContext context) async{
    String dropdownValue = 'Electricity';

     showModalBottomSheet(
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
                  //Text controllers for the properties db visibility only available for the electric and water readings because users must not be able to
                  //edit any other data but the controllers have to be there to prevent updating items to null, this may not be necessary but I left it for null safety
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
                    visible: visShow,
                    child: const Text('Type Of Fault'),
                  ),
                  Visibility(
                    visible: visShow,
                    child: DropdownButtonFormField <String>(
                      value: dropdownValue,
                      items: <String>['Electricity', 'Water & Sanitation', 'Roadworks', 'Waste Management']
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
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      keyboardType:
                      const TextInputType.numberWithOptions(),
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Fault Description',),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _depAllocationController,
                      decoration: const InputDecoration(
                          labelText: 'Department Allocation'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                      child: const Text('Report'),
                      onPressed: () {
                        showDialog(
                            barrierDismissible: false,
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                shape: const RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.all(Radius.circular(16))),
                                title: const Text("Complete Your Report!"),
                                content: const Text(
                                    "Would you like to call the report center after reporting?"),
                                actions: [
                                  TextButton(
                                    child: Row(
                                      children: const [
                                        Icon(
                                          Icons.call, color: Colors.orangeAccent,
                                        ),
                                        Text('Call After Reporting'),
                                      ],
                                    ),
                                    onPressed: () {
                                      uploadFaultFile();
                                      Fluttertoast.showToast(
                                          msg: "Successfully Sent Report!",
                                          gravity: ToastGravity.CENTER);
                                      Navigator.of(context).pop(context);
                                      Navigator.of(context).pop(context);
                                      final Uri _tel = Uri.parse(
                                          'tel:+27${0800001868}');
                                      launchUrl(_tel);
                                    },
                                  ),
                                  TextButton(
                                    child: Row(
                                      children: const [
                                        Icon(
                                          Icons.report_problem,
                                          color: Colors.tealAccent,
                                        ),
                                        Text('Don\'t Call'),
                                      ],
                                    ),
                                    onPressed: () {
                                      uploadFaultFile();
                                      Fluttertoast.showToast(
                                          msg: "Successfully Sent Report!",
                                          gravity: ToastGravity.CENTER);
                                      Navigator.of(context).pop(context);
                                      Navigator.of(context).pop(context);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.cancel, color: Colors.red,
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop(context);
                                    },
                                  ),
                                ],
                              );
                            });
                      },
                  ),
                ],
              ),
            ),
          );
        });
  }

}