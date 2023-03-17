import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as html;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:municipal_track/code/ImageUploading/image_upload_meter.dart';
import 'package:municipal_track/code/ImageUploading/image_upload_water.dart';
import 'package:municipal_track/code/MapTools/map_screen_prop.dart';
import 'package:municipal_track/code/SQLApp/fragments/photo_upload_screen.dart';
import 'package:municipal_track/code/SQLApp/model/property.dart';

import 'package:municipal_track/code/SQLApp/propertiesData/image_data.dart';
import 'package:municipal_track/code/SQLApp/propertiesData/properties_data.dart';
import 'package:municipal_track/code/SQLApp/userPreferences/current_user.dart';
import 'package:municipal_track/code/PDFViewer/view_pdf.dart';
import 'package:municipal_track/code/ApiConnection/api_connection.dart';

class PropertyFragmentScreenAll extends StatelessWidget{
  PropertyFragmentScreenAll({super.key});

  final _meterReadingController = TextEditingController();
  final _waterMeterReadingController = TextEditingController();

  final _accountNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaCodeController = TextEditingController();
  final _meterNumberController = TextEditingController();
  final _waterMeterController = TextEditingController();
  final _cellNumberController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idNumberController = TextEditingController();

  final CurrentUser _currentUser = Get.put(CurrentUser());
  final PropertiesData _propertiesData = Get.put(PropertiesData());
  final ImageData _imageData = Get.put(ImageData());

  late String userPass;
  late String addressPass;

  int propertyRowsCount = 1;

  bool visShow = true;
  bool visHide = false;

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
    image = Image.network(
      value.toString(),
      fit: BoxFit.fill,
    );
    return image;
  }

  Future<Widget> _getWImage(BuildContext context, String imageName) async{
    Image image;
    final value = _imageData.meterImageData.waterImage;
    image = Image.network(
      value.toString(),
      fit: BoxFit.fill,
    );
    return image;
  }


  void showPressed(BuildContext context) async{
    //need to work on update controller for property readings, meter and water
    void _update([PropertiesData? documentSnapshot]) async {
      if (documentSnapshot != null) {
        _accountNumberController.text = documentSnapshot.properties.accountNumber;
        _addressController.text = documentSnapshot.properties.address;
        _areaCodeController.text = documentSnapshot.properties.areaCode.toString();
        _meterNumberController.text = documentSnapshot.properties.electricityMeterNumber;
        _meterReadingController.text = documentSnapshot.properties.electricityMeterReading;
        _waterMeterController.text = documentSnapshot.properties.waterMeterNumber;
        _waterMeterReadingController.text = documentSnapshot.properties.waterMeterReading;
        _cellNumberController.text = documentSnapshot.properties.cellNumber;
        _firstNameController.text = documentSnapshot.properties.firstName;
        _lastNameController.text = documentSnapshot.properties.lastName;
        _idNumberController.text = documentSnapshot.properties.idNumber.toString();
        _currentUser.user.uid = documentSnapshot.properties.uid;
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
                      visible: visShow,
                      child: TextField(
                        controller: _meterReadingController,
                        decoration: const InputDecoration(
                            labelText: 'Electricity Meter Reading'),
                      ),
                    ),
                    Visibility(
                      visible: visShow,
                      child: TextField(
                        controller: _waterMeterReadingController,
                        decoration: const InputDecoration(
                            labelText: 'Water Meter Reading'),
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

                          DateTime now = DateTime.now();
                          String formattedDate = DateFormat('yyyy-MM-dd – hh:mm').format(now);
                          String formatYear = DateFormat.y().format(now);

                          Future<void> _Update_PropData() async {
                            try{
                              var url = API.propertiesUpdate;
                              print("Updating to :: $url");
                              var response = await html.post(Uri.parse(url), body:{
                                "id": documentSnapshot?.properties.id,
                                "accountNumber": accountNumber,
                                "address": address,
                                "areaCode": areaCode,
                                "meterNumber": meterNumber,
                                "meterReading": meterReading,
                                "waterMeterNumber": waterMeterNumber,
                                "waterMeterReading": waterMeterReading,
                                "cellNumber": cellNumber,
                                "firstName": firstName,
                                "lastName": lastName,
                                "idNumber": idNumber,
                                "monthUpdated": formattedDate,
                                "year": formatYear,
                                "uid": _currentUser.user.uid,
                              });
                            } catch(e){
                              print("Error updating :: $e");
                            }
                          }

                          _Update_PropData();

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

                          Navigator.of(context).pop();
                        }
                    ),
                  ],
                ),
              ),
            );
          });
    }
  }


  @override
  Widget build(BuildContext context) {
    ///if statement that only matches the users uid to the uid saved in the properties table so the user only sees
    ///a list of this property information and images, I will also have to make a modal that allows updating the electricity and water readings
    ///I will have to make a dropdown button that inputs the year and month so that the user can only update for the current month or view other months
    ///The image upload will have to be worked on with the same month system ie. only current moth upload or overwrite and previous months viewing only

    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('All Registered Properties'),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        ///I need to figure out how to get the item count of all the rows of the propertiesData list so that displaying is not limited to the number set
        itemCount: propertyRowsCount,
        itemBuilder: (BuildContext context, int index) {
          String billMessage;
          ///A check for if payment is outstanding or not
          if (_propertiesData.properties.eBill.toString() != '' ||
              _propertiesData.properties.eBill.toString() != '0') {
            String feesOnAddress = _propertiesData.properties.address.toString();
            billMessage = "Current bill: R${_propertiesData.properties.eBill}";
            propertyRowsCount++;
          } else {
            billMessage = "No outstanding payments";
          }
          if (_currentUser.user.official == true) {
            ///This checks and only displays the users property where the logged in user is an official
            Card(
              margin: const EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20,),
                    propertyItemField("Account Number: ${_propertiesData.properties.accountNumber}"),
                    const SizedBox(height: 10,),
                    propertyItemField("Address: ${_propertiesData.properties.address}"),
                    const SizedBox(height: 10,),
                    propertyItemField("Area Code: ${_propertiesData.properties.areaCode}"),
                    const SizedBox(height: 10,),
                    propertyItemField("Current bill: R$billMessage"),
                    const SizedBox(height: 10,),
                    propertyItemField("Electric Meter Number: ${_propertiesData.properties.electricityMeterNumber}"),
                    const SizedBox(height: 10,),
                    propertyItemField("Electric Meter Reading: ${_propertiesData.properties.electricityMeterReading}"),
                    const SizedBox(height: 10,),
                    propertyItemField("Water Meter Number: ${_propertiesData.properties.waterMeterNumber}"),
                    const SizedBox(height: 10,),
                    propertyItemField("Water Meter Reading: ${_propertiesData.properties.waterMeterReading}"),
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
                      child: Text('Electricity Meter Photo',
                        style: TextStyle(fontWeight: FontWeight.bold),),
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
                                return const Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Text(
                                      'Image not yet uploaded.'),
                                ); //${snapshot.error} if error needs to be displayed instead
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
                                  child: const Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: Center(child: CircularProgressIndicator()),
                                  ),);
                              }
                              return Container();
                            }
                        ),
                      ),
                    ),
                    const SizedBox(height: 20,),
                    const Center(
                      child: Text('Water Meter Photo',
                        style: TextStyle(fontWeight: FontWeight.bold),),
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
                                return const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Image not yet uploaded.'),
                                ); //${snapshot.error} if error needs to be displayed instead
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

                    Visibility(visible: visShow,
                        child: const SizedBox(height: 20,)),

                    ///button visibility only when the current month is selected
                    Visibility(
                      visible: visShow,
                      child: Center(
                          child: Material(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () {
                                userPass = _currentUser.user.uid.toString();
                                addressPass = _propertiesData.properties.address
                                    .toString();
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) =>
                                        PhotoUploadState(userGet: userPass,
                                          addressGet: addressPass,)));
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
                      visible: visShow,
                      child: Center(
                          child: Material(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(

                              ///This will contain the function that edits the table data of meter readings for the current month only
                              onTap: () => showPressed(context),
                              borderRadius: BorderRadius.circular(32),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 12,
                                ),
                                child: Text(
                                  "Update Meter Reading",
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
                    ///View on map
                    Visibility(
                      visible: visShow,
                      child: Center(
                          child: Material(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              ///This will send the address to the property map screen to show its location
                              onTap: () {
                                MaterialPageRoute(builder: (context) =>
                                    MapScreenProp(propAddress: _propertiesData.properties.address, propAccNumber: _propertiesData.properties.accountNumber,));
                              },
                              borderRadius: BorderRadius.circular(32),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 12,
                                ),
                                child: Text(
                                  "View Property Map",
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
                  ],
                ),
              ),
            );
          } else {
            return const Padding(
              padding: EdgeInsets.all(50.0),
              child: Center(child: CircularProgressIndicator()),
            );
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