import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:municipal_track/code/SQLApp/propertiesData/property_preferences.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

import 'package:municipal_track/code/ApiConnection/api_connection.dart';
import '../propertiesData/image_preferences.dart';


class PhotoFragmentState extends StatefulWidget {
  final String userGet;
  final String addressGet;

  const PhotoFragmentState({Key? key, required this.userGet, required this.addressGet,}) : super(key: key);

  @override
  State<PhotoFragmentState> createState() => _PhotoFragmentStateState();
}

class _PhotoFragmentStateState extends State<PhotoFragmentState> {

  File? _photo;
  final ImagePicker _picker = ImagePicker();
  String? meterType;


  TextEditingController nameController = TextEditingController();

  //Used to set the _photo file as image from gallery
  Future imgFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60,);

    setState(() {
      if (pickedFile != null) {
        _photo = File(pickedFile.path);
        if(meterType == "E"){
          uploadEFile();
        } else if (meterType == "W"){
          uploadWFile();
        }
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
        if(meterType == "E"){
          uploadEFile();
        } else if (meterType == "W"){
          uploadWFile();
        }
      } else {
        print('No image selected.');
      }
    });
  }

  Future uploadEFile() async {

    if (_photo == null) return;

    File? imageFile = _photo;
    List<int> imageBytes = imageFile!.readAsBytesSync();
    String imageData = base64Encode(imageBytes);

    final String photoName;

    

    ///'electricity/month/$userGet/$addressGet' is used specifically for adding the user id to a table in order to split the users per account
    // if (_photo == null) return;
    // final fileName = basename(_photo!.path);
    // final destination = 'electricity/month/$userGet/$addressGet'; // /$fileName  $meterNumber
    //
    // try {
    //   final ref = firebase_storage.FirebaseStorage.instance
    //       .ref(destination)
    //       .child('${widget.addressGet}/');   ///this is the jpg filename which needs to be named something on the db in order to display in the display screen
    //   await ref.putFile(_photo!);
    //   photoName = _photo!.toString();
    //   print(destination);
    // } catch (e) {
    //   print('error occured');
    // }
  }

  Future uploadWFile() async {

    if (_photo == null) return;

    File? imageFile = _photo;
    List<int> imageBytes = imageFile!.readAsBytesSync();
    String imageData = base64Encode(imageBytes);



    final String photoName;

    var data ={
      "uid": widget.userGet,
      "propertyAddress": widget.addressGet,
      "uploadMonth": imageData,
      "waterMeterIMG": imageData,
      "uploadTime": DateTime.now()
    };

    try{
      var res = await http.post(
        Uri.parse(API.meterImgData),
        body: data,
      );

      if(res.statusCode == 200){
        var resBodyOfImage = jsonDecode(res.body);
        if(resBodyOfImage['success'] == true){
          print('reaching api');

          //save user info to local storage using shared Preferences ///fix imageData
          //await RememberImageInfo.storeImageInfo(imageData);


        } else {
          Fluttertoast.showToast(msg: "Upload connection failed. Try again with network!");
        }
      }
    } catch(e) {
      print("Error :: " + e.toString());
      Fluttertoast.showToast(msg: e.toString());
    }


    ///This is the old method for firebase, some of it is commented out because firebasecore is not imported on this page
    ///'water/month/$userGet/' is used specifically for adding the user id to a table in order to split the users per account '$addressGet' will be the image name

    final fileName = basename(_photo!.path);
    final destination = 'water/month/${widget.userGet}/'; // /$fileName  $meterNumber

    // try {
    //   final ref = firebase_storage.FirebaseStorage.instance
    //       .ref(destination)
    //       .child('${widget.addressGet}/');   ///this is the jpg filename which needs to be named something on the db in order to display in the display screen
    //   await ref.putFile(_photo!);
    //   photoName = _photo!.toString();
    //   print(destination);
    // } catch (e) {
    //   print('error occured');
    // }
  }
  
  showImage(String image){
    return Image.memory(base64Decode(image));
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Electricity Meter Reading Upload'),
        backgroundColor: Colors.green,
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
            const SizedBox(height: 20,),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Meter Image Upload'),
              ),
            ),
            const SizedBox(height: 100,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: GestureDetector(
                onTap: () {
                  if (_photo != null) {
                    AlertDialog(
                      title: const Text("Meter Type!"),
                      content: const Text(
                          "Are you uploading an Electricity Meter Image \n or a Water Meter Image?"),
                      actions: [
                        TextButton(
                          child: Row(
                            children: const [
                              Icon(
                                Icons.power, color: Colors.yellowAccent,
                              ),
                              Text('Electric'),
                            ],
                          ),
                          onPressed: () {
                            meterType = "E";
                            uploadEFile();
                            Fluttertoast.showToast(msg: "Successfully Uploaded!\nElectric Meter Image!");
                            Navigator.of(context).pop(context);
                            Navigator.of(context).pop(context);
                          },
                        ),
                        TextButton(
                          child: Row(
                            children: const [
                              Icon(
                                Icons.water_drop, color: Colors.blueAccent,
                              ),
                              Text('Water'),
                            ],
                          ),
                          onPressed: () {
                            meterType = "W";
                            uploadWFile();
                            Fluttertoast.showToast(msg: "Successfully Uploaded!\nWater Meter Image!");
                            Navigator.of(context).pop(context); //pops the alert dialogue box
                            Navigator.of(context).pop(context); //pops the image upload page back to the listview
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
                  } else {
                    Fluttertoast.showToast(msg: "Please tap on the image area and select the image to upload!");
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