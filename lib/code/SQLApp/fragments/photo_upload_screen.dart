import 'dart:convert';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:municipal_track/code/SQLApp/propertiesData/property_preferences.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
//import 'package:location/location.dart';
//import 'package:location/location.dart' as loc;

import 'package:municipal_track/code/ApiConnection/api_connection.dart';
import 'package:municipal_track/code/SQLApp/propertiesData/image_preferences.dart';
import 'package:municipal_track/code/SQLapp/propertiesData/properties_data.dart';


class PhotoUploadState extends StatefulWidget {
  final String userGet;
  final String addressGet;

  const PhotoUploadState({Key? key, required this.userGet, required this.addressGet,}) : super(key: key);

  @override
  State<PhotoUploadState> createState() => _PhotoUploadStateState();
}



class _PhotoUploadStateState extends State<PhotoUploadState> {

  File? _photo;
  final ImagePicker _picker = ImagePicker();
  String? meterType;

  final PropertiesData _propertiesData = Get.put(PropertiesData());

  TextEditingController nameController = TextEditingController();

  bool buttonEnabled = true;

  String location ='Null, Press Button';
  String Address = 'search';

  @override
  void initState() async {
    Position position = await _getGeoLocationPosition();
    location ='Lat: ${position.latitude} , Long: ${position.longitude}';
    GetAddressFromLatLong(position);
    if(_getGeoLocationPosition.isBlank == false){
      buttonEnabled = false;
    }
    super.initState();
  }

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

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);

    var data ={
      "uid": widget.userGet,
      "propertyAddress": widget.addressGet,
      "electricMeterIMG": imageFile,
      "capturedFrom": Address.toString(),
      "uploadTime": formattedDate,
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
          Fluttertoast.showToast(msg: "Upload connection failed. Try again with network!", gravity: ToastGravity.CENTER);
        }
      }
    } catch(e) {
      print("Error :: " + e.toString());
      Fluttertoast.showToast(msg: e.toString(), gravity: ToastGravity.CENTER);
    }
  }

  Future uploadWFile() async {

    if (_photo == null) return;

    File? imageFile = _photo;
    List<int> imageBytes = imageFile!.readAsBytesSync();
    String imageData = base64Encode(imageBytes);

    final String photoName;

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);

    var data ={
      "uid": widget.userGet,
      "propertyAddress": widget.addressGet,
      "waterMeterIMG": imageFile,
      "capturedFrom": Address.toString(),
      "uploadTime": formattedDate,
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

          //save user info to local storage using shared Preferences
          //await RememberImageInfo.storeImageInfo(imageData);


        } else {
          Fluttertoast.showToast(msg: "Upload connection failed. Try again with network!");
        }
      }
    } catch(e) {
      print("Error :: " + e.toString());
      Fluttertoast.showToast(msg: e.toString());
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
                onTap: buttonEnabled? () {
                  if (_photo != null) {
                    AlertDialog(
                      shape: const RoundedRectangleBorder(borderRadius:
                      BorderRadius.all(Radius.circular(16))),
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
                            Fluttertoast.showToast(msg: "Successfully Uploaded!\nElectric Meter Image!", gravity: ToastGravity.CENTER);
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
                            Fluttertoast.showToast(msg: "Successfully Uploaded!\nWater Meter Image!", gravity: ToastGravity.CENTER);
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
                    Fluttertoast.showToast(msg: "Please tap on the image area and select the image to upload!", gravity: ToastGravity.CENTER);
                  }
                } : null,

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