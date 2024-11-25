import 'dart:convert';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:municipal_services/code/SQLApp/faultData/fault_data.dart';
import 'package:municipal_services/code/SQLApp/model/fault_report.dart';
import 'package:municipal_services/code/SQLApp/userPreferences/current_user.dart';
import 'package:municipal_services/code/ApiConnection/api_connection.dart';


class FaultTaskScreen extends StatelessWidget {

  final _accountNumberController = TextEditingController();
  final _addressController = TextEditingController();
  // final _eDescriptionController = TextEditingController();
  final _wDescriptionController = TextEditingController();
  final _depAllocationController = TextEditingController();
  bool _faultResolvedController = false;
  final _dateReportedController = TextEditingController();

  final FaultData _faultData = Get.put(FaultData());

  //final UserData _userData = Get.put( );

  bool buttonVis1 = true;
  bool buttonVis2 = false;


  //this widget is for displaying a property field of information with an icon next to it, NB. the icon is to make it look good
  //it is called within a listview page widget
  Widget faultItemField(String faultDat) {
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
            faultDat,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  setState(value) {
    _faultResolvedController = value!;
  }

  Future<void> _updateReport() async {
    final int id = _faultData.fault.id;
    final int uid = _faultData.fault.uid;
    final String accountNumber = _faultData.fault.accountNumber;
    final String addressOfFault = _faultData.fault.propertyAddress;
    // final String electricityFaultDes = _faultData.fault.electricFaultDes;
    final String waterFaultDes = _faultData.fault.waterFaultDes;
    final String reportedDate = _faultData.fault.dateReported;
    final String allocatedDpt = _faultData.fault.depAllocation;

    var data = {
      "id": id.toString(),
      "uid": uid.toString(),
      "accountNumber": accountNumber,
      "address": addressOfFault,
      // "electricityFaultDes": electricityFaultDes,
      "waterFaultDes": waterFaultDes,
      "dateReported": reportedDate,
      "depAllocation": allocatedDpt,
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
                  //Text controllers for the properties db visibility only available for the electric and water readings because users must not be able to
                  //edit any other data but the controllers have to be there to prevent updating items to null, this may not be necessary but I left it for null safety
                  Visibility(
                    visible: buttonVis2,
                    child: TextField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(
                          labelText: 'Account Number'),
                    ),
                  ),
                  Visibility(
                    visible: buttonVis2,
                    child: TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                          labelText: 'Street Address'),
                    ),
                  ),
                  // Visibility(
                  //   visible: buttonVis2,
                  //   child: TextField(
                  //     keyboardType:
                  //     const TextInputType.numberWithOptions(),
                  //     controller: _eDescriptionController,
                  //     decoration: const InputDecoration(
                  //       labelText: 'Electrical Fault Description',),
                  //   ),
                  // ),
                  Visibility(
                    visible: buttonVis2,
                    child: TextField(
                      controller: _wDescriptionController,
                      decoration: const InputDecoration(
                          labelText: 'Water Fault Description'),
                    ),
                  ),
                  Visibility(
                    visible: buttonVis1,
                    child: TextField(
                      controller: _depAllocationController,
                      decoration: const InputDecoration(
                          labelText: 'Department Allocation'),
                    ),
                  ),
                  Visibility(
                    visible: buttonVis2,
                    child: Row(
                      children: <Widget>[
                        const SizedBox(
                          width: 10,
                        ), //SizedBox
                        const Text(
                          'Resolve Logged Fault: ',
                          style: TextStyle(fontSize: 17.0),
                        ), //Text
                        const SizedBox(width: 10), //SizedBox
                        Checkbox(
                          value: _faultResolvedController,
                          onChanged: (value) {
                            setState((value) {
                              _faultResolvedController =
                              value!; // rebuilds with new value
                            });
                          },
                        ),
                      ], //<Widget>[]
                    ),
                  ),
                  Visibility(
                    visible: buttonVis1,
                    child: TextField(
                      controller: _dateReportedController,
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
                        _updateReport();

                        _accountNumberController.text = '';
                        _addressController.text = '';
                        // _eDescriptionController.text = '';
                        _wDescriptionController.text = '';
                        _depAllocationController.text = '';
                        _faultResolvedController = false;
                        _dateReportedController.text = '';

                        Navigator.of(context).pop();
                      }
                  ),
                ],
              ),
            ),
          );
        });
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
        title: const Text('Fault Reports Listed'),
        backgroundColor: Colors.green,
      ),

      body: FutureBuilder(
        future: FaultData().getFaultInfo(),
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasData) {
            Object? fault = snapshot.data;
            return Card(
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5.0),
                          topRight: Radius.circular(5.0),
                        ),
                        color: Color(0xfff6f8fa),
                        border: Border.all(
                          color: Color(0xffd5d8dc),
                          width: 1,
                        )),
                    padding: EdgeInsets.only(
                        top: 13.0, left: 13.0, bottom: 13.0),
                    child: Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.addressBook,
                          color: Colors.blue,
                          size: 15,
                        ),
                        Text(
                          '   Fault Overviews',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DataTable(
                          sortColumnIndex: 1,
                          sortAscending: true,
                          columns: [
                            DataColumn(
                              label: Text('Account #'),
                              numeric: false,
                              tooltip: 'Account #',
                            ),
                            DataColumn(
                              label: Text('Address'),
                              numeric: false,
                              tooltip: 'Address',
                            ),
                            DataColumn(
                              label: Text('Status'),
                              numeric: false,
                              tooltip: 'Attended',
                            ),
                            DataColumn(
                              label: Text('Action'),
                              numeric: false,
                              tooltip: 'Press',
                            ),
                          ],
                          rows: [
                            for (var item in FaultData().getFaultInfo())
                              DataRow(
                                cells: [
                                  DataCell(
                                    Text('${item.Fault.accountNumber}'),
                                  ),
                                  DataCell(
                                    Text('${item.Fault.propertyAddress}'),
                                  ),
                                  DataCell(
                                    Text('${item.Fault.faultResolved}'),
                                  ),
                                  DataCell(
                                    IconButton(
                                      onPressed: () {
                                        showPressed;
                                      },
                                      icon: Icon(FontAwesomeIcons
                                          .fileCircleExclamation),),),
                                ].toList(),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          else {
            return const Padding(
              padding: EdgeInsets.all(10.0),
              child: Center(
                  child: CircularProgressIndicator()),
            );
          }
        },),
    );
  }
}