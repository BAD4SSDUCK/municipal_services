import 'dart:io';
import 'package:http/http.dart' as html;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:municipal_track/code/ImageUploading/image_upload_meter.dart';
import 'package:municipal_track/code/ImageUploading/image_upload_water.dart';
import 'package:municipal_track/code/SQLApp/fragments/photo_fragment_screen.dart';

import 'package:municipal_track/code/SQLApp/propertiesData/image_data.dart';
import 'package:municipal_track/code/SQLApp/propertiesData/properties_data.dart';
import 'package:municipal_track/code/SQLApp/userPreferences/current_user.dart';

import '../../PDFViewer/view_pdf.dart';

class PropertyFragmentScreen extends StatelessWidget{


  final _meterReadingController = TextEditingController();
  final _waterMeterReadingController = TextEditingController();

  final CurrentUser _currentUser = Get.put(CurrentUser());
  final PropertiesData _propertiesData = Get.put(PropertiesData());
  final ImageData _imageData = Get.put(ImageData());

  String userPass='';
  String addressPass='';

  bool buttonVis1 = true;
  bool buttonVis2 = false;

  //this widget is for displaying a property field of information with an icon next to it, NB. the icon is to make it look good
  //it is called within a listview page widget
  Widget propertyItemField(String propertyDat){
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 8,),
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

  Future<Widget> _getEImage(BuildContext context, String imageName) async{
    Image image;
    final value = _imageData.meterImageData.electricImage;
    image =Image.network(
      value.toString(),
      fit: BoxFit.fill,
    );
    return image;
  }

  Future<Widget> _getWImage(BuildContext context, String imageName) async{
    Image image;
    final value = _imageData.meterImageData.waterImage;
    image =Image.network(
      value.toString(),
      fit: BoxFit.fill,
    );
    return image;
  }


  Future userPropertyImageMatch() async{
    _propertiesData.properties.uid == _currentUser.user.uid;

  }


  @override
  Widget build(BuildContext context) {
    ///I will be putting an if statement that only matches the users uid to the uid saved in the properties table so the user only sees
    ///a list of his property information and images, I will also have to make a modal that allows updating the electricity and water readings
    ///I will have to make a dropdown button that inputs the year and month so that the user can only update for the current month or view other months
    ///The image upload will have to be worked on with the same month system ie. only current moth upload or overwrite and previous months viewing only

    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Property Details'),
        backgroundColor: Colors.green,
      ),
      body:
      Column(
        children: [

          ///will have to create a ListView.builder
          ///which needs itemCount: and itemBuilder: (context, index){ } for documentation go to https://docs.flutter.dev/cookbook/lists/mixed-list
          ///also check https://www.geeksforgeeks.org/listview-builder-in-flutter/

          ListView(
              padding: const EdgeInsets.all(32),
              children: [

                const SizedBox(height: 20,),

                propertyItemField("Account Number: ${_propertiesData.properties.accountNumber}"),

                const SizedBox(height: 10,),

                propertyItemField("Address: ${_propertiesData.properties.address}"),

                const SizedBox(height: 10,),

                propertyItemField("Area Code: ${_propertiesData.properties.areaCode}"),

                const SizedBox(height: 10,),

                propertyItemField("Current bill: R${_propertiesData.properties.eBill}"),

                const SizedBox(height: 10,),

                propertyItemField("Electric Meter Number: ${_propertiesData.properties.electricityMeterNumber}"),

                const SizedBox(height: 10,),

                propertyItemField("Electric Meter Reading: ${_propertiesData.properties.electricityMeterReading}"),
                ///add text input to make tappable to edit and save changes for only the current months meter reading

                const SizedBox(height: 10,),

                propertyItemField("Water Meter Number: ${_propertiesData.properties.waterMeterNumber}"),

                const SizedBox(height: 10,),

                propertyItemField("Water Meter Reading: ${_propertiesData.properties.waterMeterReading}"),
                ///add text input to make tappable to edit and save changes for only the current months meter reading

                const SizedBox(height: 10,),

                propertyItemField("First Name: ${_propertiesData.properties.firstName}"),

                const SizedBox(height: 10,),

                propertyItemField("Last Name: ${_propertiesData.properties.lastName}"),

                const SizedBox(height: 10,),

                propertyItemField("ID Number: ${_propertiesData.properties.idNumber}"),

                const SizedBox(height: 10,),

                propertyItemField("Contact Number: ${_propertiesData.properties.cellNumber}"),

                const SizedBox(height: 20,),

                const Center(
                  child: Text('Electricity Meter Photo',style: TextStyle(fontWeight: FontWeight.bold),),
                ),
                const SizedBox(height: 10,),
                Center(
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
                        future: _getEImage(
                            context, _propertiesData.properties.address),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('Image not uploaded yet.'); //${snapshot.error} if error needs to be displayed instead
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

                const SizedBox(height: 20,),

                const Center(
                  child: Text('Water Meter Photo',style: TextStyle(fontWeight: FontWeight.bold),),
                ),
                const SizedBox(height: 10,),
                Center(
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
                        future: _getWImage(
                            context, _propertiesData.properties.address),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('Image not uploaded yet.'); //${snapshot.error} if error needs to be displayed instead
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

                Visibility(visible: buttonVis1, child: const SizedBox(height: 20,)),

                ///button visibility only when the current month is selected
                Visibility(
                  visible: buttonVis1,
                  child: Center(
                      child: Material(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: (){
                            userPass = _currentUser.user.uid.toString();
                            addressPass = _propertiesData.properties.address.toString();
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) =>
                                    PhotoFragmentState(userGet: userPass, addressGet: addressPass,)));
                          },
                          borderRadius: BorderRadius.circular(32),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                            child: Text(
                              "Meter Photo Upload",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                      )
                  ),
                ),

                const SizedBox(height: 20,),

                ///Save changed button
                Visibility(
                  visible: buttonVis1,
                  child: Center(
                      child: Material(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: (){
                            ///This will contain the function that edits the table data of meter readings for the current month only
                          },
                          borderRadius: BorderRadius.circular(32),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                            child: Text(
                              "Save Changes",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                      )
                  ),
                ),

                const SizedBox(height: 50,),

              ]
          ),
        ],
      ),
    );
  }

  ///pdf view loader getting file name onPress/onTap that passes pdf filename to this class.
  void openPDF(BuildContext context, File file) => Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
  );
}