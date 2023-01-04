import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:municipal_track/code/DisplayPages/display_info_electricity.dart';
import 'package:path/path.dart';

import '../DisplayPages/display_info_water.dart';

class ImageUploadWater extends StatefulWidget {

  //final String meterNumber;

  const ImageUploadWater({
    Key? key, //required this.meterNumber,

  }) : super(key: key,);
  @override
  _ImageUploadWaterState createState() => _ImageUploadWaterState();
}

class _ImageUploadWaterState extends State<ImageUploadWater> {
  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  final GlobalKey<ScaffoldState> _key = GlobalKey();
  File? _photo;
  final ImagePicker _picker = ImagePicker();

  Future imgFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60,);

    setState(() {
      if (pickedFile != null) {
        _photo = File(pickedFile.path);
        uploadFile();
        print('Meternumber for gallery '+wMeterNumber);
      } else {
        print('No image selected.');
      }
    });
  }

  Future imgFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 60,);

    setState(() {
      if (pickedFile != null) {
        _photo = File(pickedFile.path);

        print('Meternumber for camera '+wMeterNumber);
        uploadFile();
      } else {
        print('No image selected.');
      }
    });
  }

  Future uploadFile() async {

    ///This is the method to get the user id for reference in data upload
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final uid = user?.uid;
    String userID = uid as String;
    final String photoName;

    print('Meternumber for up '+wMeterNumber);

    ///'files/$userID/$fileName' is used specifically for adding the user id to a table in order to split the users per account
    ///$fileName creates a folder with random numbers .jpg, the actual jpg gets named 'file' for some reason
    if (_photo == null) return;
    final fileName = basename(_photo!.path);
    final destination = 'files/$userID/water/'; // /$fileName

    try {
      final ref = firebase_storage.FirebaseStorage.instance
          .ref(destination)
          .child('$wMeterNumber/');  ///$fileName this is the jpg filename which needs to be named something on the db in order to display in the display screen
      await ref.putFile(_photo!);
      photoName = _photo!.toString();
      print('destination is '+destination);
    } catch (e) {
      print('error occured');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('the meter number ----- '+wMeterNumber);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Meter Image'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            SizedBox(height: 100,),
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
                      _photo!,
                      width: 250,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Container(
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10)), width: 250, height: 250,
                    child: Icon(Icons.camera_alt, color: Colors.grey[800],),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 100,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: GestureDetector(
                onTap: () {
                  if (_photo != null) {
                    uploadFile();
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Image Successfully Uploaded!'),
                      ),);
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Please tap on the image area and select the image to upload!'),
                      ),);
                  }
                },

                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Upload Image',
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
}