import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as html;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:municipal_track/code/ImageUploading/image_upload_meter.dart';
import 'package:municipal_track/code/ImageUploading/image_upload_water.dart';
import 'package:municipal_track/code/SQLApp/fragments/photo_upload_screen.dart';

import 'package:municipal_track/code/SQLApp/propertiesData/image_data.dart';
import 'package:municipal_track/code/SQLApp/propertiesData/properties_data.dart';
import 'package:municipal_track/code/SQLApp/userPreferences/current_user.dart';

import 'package:municipal_track/code/PDFViewer/view_pdf.dart';

class ReportPropertyMenu extends StatelessWidget{


  final _meterReadingController = TextEditingController();
  final _waterMeterReadingController = TextEditingController();

  final CurrentUser _currentUser = Get.put(CurrentUser());
  final PropertiesData _propertiesData = Get.put(PropertiesData());
  final ImageData _imageData = Get.put(ImageData());

  String userPass='';
  String addressPass='';
  String accountNumber='';

  bool buttonVis1 = true;
  bool buttonVis2 = false;

  bool buttonEnabled = true;

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

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Report Property Fault'),
        backgroundColor: Colors.green,
      ),

      body: ListView.builder(
        ///I need to figure out how to get the item count of all the rows of the propertiesData list so that displaying is not limited to the number set
        itemCount: 4,
        itemBuilder: (BuildContext context, int index) {

          if(_propertiesData.properties.uid == _currentUser.user.uid){
            ///This checks and only displays the users property where the UID saved for both is the same

            String billMessage;///A check for if payment is outstanding or not
            if(_propertiesData.properties.eBill.toString() == '' || _propertiesData.properties.eBill.toString() == '0' || _propertiesData.properties.eBill.toString().isEmpty){
              billMessage = "No outstanding payments";
              buttonEnabled = true;
            } else {
              String feesOnAddress = _propertiesData.properties.address.toString();
              billMessage = "Current bill: R${_propertiesData.properties.eBill}";
              Fluttertoast.showToast(msg: "Outstanding bill to pay on:\n$feesOnAddress\nFault Reporting unavailable!",
                gravity: ToastGravity.CENTER,);
              buttonEnabled = false;
            }

            return Column(
              children: [
                ListView(
                    padding: const EdgeInsets.all(32),
                    children: [

                      const SizedBox(height: 20,),

                      propertyItemField(
                          "Account Number: ${_propertiesData.properties
                              .accountNumber}"),

                      const SizedBox(height: 10,),

                      propertyItemField(
                          "Address: ${_propertiesData.properties.address}"),

                      const SizedBox(height: 10,),

                      propertyItemField(
                          "Area Code: ${_propertiesData.properties.areaCode}"),

                      const SizedBox(height: 10,),

                      propertyItemField(
                          "Current bill: $billMessage"),

                      const SizedBox(height: 10,),

                      propertyItemField(
                          "Electric Meter Number: ${_propertiesData.properties
                              .electricityMeterNumber}"),

                      const SizedBox(height: 10,),

                      propertyItemField(
                          "Water Meter Number: ${_propertiesData.properties
                              .waterMeterNumber}"),

                      const SizedBox(height: 20,),

                      Visibility(visible: buttonVis1,
                          child: const SizedBox(height: 20,)),

                      ///button visibility only when the current month is selected
                      Visibility(
                        visible: buttonVis1,
                        child: Center(
                            child: Material(
                              color: Colors.amberAccent,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: buttonEnabled?() {
                                    userPass = _currentUser.user.uid.toString();
                                    accountNumber = _propertiesData.properties.accountNumber.toString();
                                    addressPass = _propertiesData.properties.address.toString();


                                }:null,
                                borderRadius: BorderRadius.circular(32),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    "Report\nElectrical Fault",
                                    style: TextStyle(
                                      color: Colors.black,
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
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: buttonEnabled?() {
                                  userPass = _currentUser.user.uid.toString();
                                  accountNumber = _propertiesData.properties.accountNumber.toString();
                                  addressPass = _propertiesData.properties.address.toString();


                                }:null,
                                borderRadius: BorderRadius.circular(32),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    "Report\nWater Fault",
                                    style: TextStyle(
                                      color: Colors.black,
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
            );

          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }



  ///pdf view loader getting file name onPress/onTap that passes pdf filename to this class.
  void openPDF(BuildContext context, File file) => Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
  );
}