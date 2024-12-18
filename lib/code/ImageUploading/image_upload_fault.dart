import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;


class FaultImageUpload extends StatefulWidget {
   FaultImageUpload({super.key, required this.propertyAddress, required this.reportedDate, });

  final String propertyAddress;
  final String reportedDate;
  @override
  _FaultImageUploadState createState() => _FaultImageUploadState();
}

class _FaultImageUploadState extends State<FaultImageUpload> {

  @override
  void initState(){
    Fluttertoast.showToast(
        msg: "Going back will cancel image upload entirely!",
        gravity: ToastGravity.CENTER);
    super.initState();
  }

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
        uploadFile();
      } else {
        print('No image selected.');
      }
    });
  }

  // Future uploadFile() async {
  //
  //   final String photoName;
  //   final String reportAddress = widget.propertyAddress;
  //   final String dateReported = widget.reportedDate;
  //
  //   ///'files/$userID/$fileName' is used specifically for adding the user id to a table in order to split the users per account
  //   if (_photo == null) return;
  //   final fileName = basename(_photo!.path);
  //   final destination = 'files/faultImages/$dateReported/';
  //
  //   try {
  //     final ref = firebase_storage.FirebaseStorage.instance
  //         .ref(destination)
  //         .child('$reportAddress/');   ///this is the jpg filename which needs to be named something on the db in order to display in the display screen
  //     await ref.putFile(_photo!);
  //     photoName = _photo!.toString();
  //     print(destination);
  //   } catch (e) {
  //     print('error occured');
  //   }
  // }
  Future uploadFile() async {
    if (_photo == null) {
      print('No image selected.');
      return;
    }

    final String reportAddress = widget.propertyAddress;
    final String dateReported = widget.reportedDate;
    String fileExtension = path.extension(_photo!.path);
    final String fileName = '$reportAddress$fileExtension';
    final String destination = 'files/faultImages/$dateReported/$fileName';

    try {
      final ref = firebase_storage.FirebaseStorage.instance.ref(destination);

      // Determine MIME type of the file
      final mimeType = lookupMimeType(_photo!.path) ?? 'application/octet-stream';
      print("Determined MIME type: $mimeType");

      // Metadata for the upload, specifying the content type
      final metadata = firebase_storage.SettableMetadata(contentType: mimeType);

      // Uploading the file with metadata
      await ref.putFile(_photo!, metadata);

      // Optionally, get the URL of the uploaded file
      String fileUrl = await ref.getDownloadURL();
      print('Image uploaded successfully to: $destination');
      print('File URL: $fileUrl');
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fault Photo Upload',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 100,),
            Center(
              child: GestureDetector(
                onTap: () {
                  _showPicker(context);

                },
                child: CircleAvatar(
                  radius: 180,
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
                    Fluttertoast.showToast(
                        msg: "Report Image Successfully Uploaded!",
                        gravity: ToastGravity.CENTER);
                    Navigator.of(context).pop();
                  } else {
                    Fluttertoast.showToast(
                        msg: "Please tap on the image area and select the image to upload!",
                        gravity: ToastGravity.CENTER);
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
                      'Upload Fault Image',
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