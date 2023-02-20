import 'dart:convert';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:municipal_track/code/SQLApp/propertiesData/properties_data.dart';
import 'package:municipal_track/code/SQLApp/userPreferences/current_user.dart';

import 'package:municipal_track/code/ApiConnection/api_connection.dart';

class ReportPropertyMenu extends StatelessWidget {


  final _electricalFaultController = TextEditingController();
  final _waterFaultController = TextEditingController();

  final CurrentUser _currentUser = Get.put(CurrentUser());
  final PropertiesData _propertiesData = Get.put(PropertiesData());

  String userPass = '';
  String addressPass = '';


  bool elecDesVis = true;
  bool waterDesVis = false;
  bool buttonEnabled = true;

  //this widget is for displaying a property field of information with an icon next to it, NB. the icon is to make it look good
  //it is called within a listview page widget
  Widget propertyItemField(String propertyDat) {
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
            propertyDat,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _addNewFaultReport() async {
    final int uid = _currentUser.user.uid;
    String accountNumber = _propertiesData.properties.accountNumber;
    final String addressFault = _propertiesData.properties.address;
    final String electricityFaultDes = _electricalFaultController.text;
    final String waterFaultDes = _waterFaultController.text;
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);

    var data = {
      "uid": uid.toString(),
      "accountNumber": accountNumber,
      "address": addressFault,
      "electricityFaultDes": electricityFaultDes,
      "waterFaultDes": waterFaultDes,
      "dateReported": formattedDate,
    };

    try {
      var res = await http.post(
        Uri.parse(API.reportFault),
        body: data,
      );

      if (res.statusCode == 200) {
        var resBodyOfImage = jsonDecode(res.body);
        if (resBodyOfImage['success'] == true) {
          print('reaching api');

          Fluttertoast.showToast(msg: "Fault has been reported successfully!",
            gravity: ToastGravity.CENTER,);

        } else {
          Fluttertoast.showToast(
              msg: "Server connection failed. Report with network connection!");
        }
      }
    } catch (e) {
      print("Error :: " + e.toString());
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  Future<void> showPressed(BuildContext context) async {
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
                  //Text controllers for the properties db visibility only available for the electric and water readings
                  Visibility(
                    visible: elecDesVis,
                    child: TextField(
                      controller: _electricalFaultController,
                      decoration: const InputDecoration(
                          labelText: 'Electrical Fault Description'),
                    ),
                  ),
                  Visibility(
                    visible: waterDesVis,
                    child: TextField(
                      controller: _waterFaultController,
                      decoration: const InputDecoration(
                          labelText: 'Water Fault Description'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    child: const Text('Report'),
                    onPressed: () async {

                      AlertDialog(
                        shape: const RoundedRectangleBorder(borderRadius:
                        BorderRadius.all(Radius.circular(16))),
                        title: const Text("Call Report Center!"),
                        content: const Text(
                            "Would you like to call the report center after sending your report description?"),
                        actions: [
                          IconButton(
                            onPressed: () {
                              _addNewFaultReport();

                              _electricalFaultController.text = '';
                              _waterFaultController.text = '';

                              Get.back();
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                            ),
                          ),
                          IconButton(
                            onPressed: () async {

                              _addNewFaultReport();

                              _electricalFaultController.text = '';
                              _waterFaultController.text = '';

                              final Uri _tel = Uri.parse(
                                  'tel:+27${0800001868}');
                              launchUrl(_tel);

                              Get.back();
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(
                              Icons.done,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
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
        title: const Text('Report Property Fault'),
        backgroundColor: Colors.green,
      ),

      body: ListView.builder(

        ///I need to figure out how to get the item count of all the rows of the propertiesData list so that displaying is not limited to the number set
        itemCount: 4,
        itemBuilder: (BuildContext context, int index) {
          if (_propertiesData.properties.uid == _currentUser.user.uid) {
            ///This checks and only displays the users property where the UID saved for both is the same

            String billMessage;

            ///A check for if payment is outstanding or not
            if (_propertiesData.properties.eBill.toString() == '' ||
                _propertiesData.properties.eBill.toString() == '0' ||
                _propertiesData.properties.eBill
                    .toString()
                    .isEmpty) {
              billMessage = "No outstanding payments";
              buttonEnabled = true;
            } else {
              String feesOnAddress = _propertiesData.properties.address
                  .toString();
              billMessage =
              "Current bill: R${_propertiesData.properties.eBill}";
              Fluttertoast.showToast(
                msg: "Outstanding bill to pay on:\nR$feesOnAddress\nFault Reporting unavailable!",
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
                          "Area Code: ${_propertiesData.properties
                              .areaCode}"),

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

                      const SizedBox(height: 20,),

                      ///button visibility only when the current month is selected
                      Center(
                          child: Material(
                            color: Colors.amberAccent,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: buttonEnabled ? () {
                                userPass = _currentUser.user.uid.toString();
                                addressPass =
                                    _propertiesData.properties.address
                                        .toString();
                                elecDesVis = true;
                                waterDesVis = false;

                                showPressed;

                              } : null,
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

                      const SizedBox(height: 20,),

                      ///Save changed button
                      Center(
                          child: Material(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: buttonEnabled ? () {
                                userPass = _currentUser.user.uid.toString();
                                addressPass =
                                    _propertiesData.properties.address
                                        .toString();

                                elecDesVis = false;
                                waterDesVis = true;
                                showPressed;

                              } : null,
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
}