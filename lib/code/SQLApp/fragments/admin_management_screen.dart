import 'dart:convert';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as html;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:municipal_track/code/SQLApp/adminData/admin_users.dart';
import 'package:municipal_track/code/SQLApp/fragments/user_add_screen.dart';
import 'package:municipal_track/code/ApiConnection/api_connection.dart';

class AdminManagementScreen extends StatelessWidget{

  final _userNameController = TextEditingController();
  final _userRollController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _userEmailController = TextEditingController();
  final _cellNumberController = TextEditingController();

  final AdminUser _adminUser = Get.put(AdminUser());

  String userPass='';
  String addressPass='';

  bool visShow = true;
  bool visHide = false;

  //this widget is for displaying a user information with an icon next to it, NB. the icon is to make it look good
  //it is called within a listview page widget
  Widget adminUserField(String propertyDat){
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

  void showPressed(BuildContext context) {
    //need to work on update controller for property readings, meter and water
    Future<void> _update([AdminUser? documentSnapshot]) async {
      if (documentSnapshot != null) {
        _userNameController.text = documentSnapshot.user.userName;
        _userRollController.text = documentSnapshot.user.adminRoll;
        _firstNameController.text = documentSnapshot.user.firstName;
        _lastNameController.text = documentSnapshot.user.lastName;
        _userEmailController.text = documentSnapshot.user.email;
        _cellNumberController.text = documentSnapshot.user.cellNumber;
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
                    Visibility(
                      visible: visShow,
                      child: TextField(
                        controller: _userNameController,
                        decoration: const InputDecoration(
                            labelText: 'Account Number'),
                      ),
                    ),
                    Visibility(
                      visible: visShow,
                      child: TextField(
                        controller: _userRollController,
                        decoration: const InputDecoration(
                            labelText: 'Street Address'),
                      ),
                    ),
                    Visibility(
                      visible: visShow,
                      child: TextField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                            labelText: 'First Name'),
                      ),
                    ),
                    Visibility(
                      visible: visShow,
                      child: TextField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                            labelText: 'Last Name'),
                      ),
                    ),
                    Visibility(
                      visible: visShow,
                      child: TextField(
                        controller: _userEmailController,
                        decoration: const InputDecoration(
                            labelText: 'ID Number'),
                      ),
                    ),
                    Visibility(
                      visible: visShow,
                      child: TextField(
                        controller: _cellNumberController,
                        decoration: const InputDecoration(
                            labelText: 'Phone Number'),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    ElevatedButton(
                        child: const Text('Update'),
                        onPressed: () async {
                          final String userName = _userNameController.text;
                          final String userRoll = _userRollController.text;
                          final String firstName = _firstNameController.text;
                          final String lastName = _lastNameController.text;
                          final String email = _userEmailController.text;
                          final String cellNumber = _cellNumberController.text;
                          const bool official = true;

                          Future<void> _UpdateAdminData() async {
                            var response = await html.post(
                              Uri.parse(API.adminUserUpdate),
                              body: {
                                "uid": _adminUser.user.uid,
                                "userName": userName,
                                "adminRoll": userRoll,
                                "firstName": firstName,
                                "lastName": lastName,
                                "email": email,
                                "cellNumber": cellNumber,
                                "official": official,
                              }
                            );
                            var jsonData = jsonDecode(response.body);

                            if (jsonData == "failed"){
                              print('failed');
                            }

                          }

                          _userNameController.text = '';
                          _userRollController.text = '';
                          _firstNameController.text = '';
                          _lastNameController.text = '';
                          _cellNumberController.text = '';
                          _userEmailController.text = '';

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
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Official User List'),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        ///I need to figure out how to get the item count of all the rows of the propertiesData list so that displaying is not limited to the number set
        itemCount: 4,
        itemBuilder: (BuildContext context, int index) {
          if(_adminUser.user.official == true){
            ///This checks and only displays the users property where the UID saved for both is the same
            return Column(
              children: [
                ListView(
                    padding: const EdgeInsets.all(32),
                    children: [
                      const SizedBox(height: 20,),
                      adminUserField(
                          "First Name: ${_adminUser.user.userName}"),
                      const SizedBox(height: 10,),
                      adminUserField(
                          "Roll: ${_adminUser.user.adminRoll}"),
                      const SizedBox(height: 10,),
                      adminUserField(
                          "First Name: ${_adminUser.user.firstName}"),
                      const SizedBox(height: 10,),
                      adminUserField(
                          "Last Name: ${_adminUser.user.lastName}"),
                      const SizedBox(height: 10,),
                      adminUserField(
                          "Email: ${_adminUser.user.email}"),
                      const SizedBox(height: 10,),
                      adminUserField(
                          "Phone Number: ${_adminUser.user.cellNumber}"),
                      const SizedBox(height: 10,),
                      Visibility(
                        visible: visShow,
                        child: Center(
                            child: Material(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                ///This will contain the function that edits the table data of meter readings for the current month only
                                onTap: ()=>showPressed(context),
                                borderRadius: BorderRadius.circular(32),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    "Change User Roll",
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
            );
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),

        floatingActionButton: FloatingActionButton(
          onPressed: () => const AddAdminUserScreen(),
          backgroundColor: Colors.green,
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat

    );
  }
}
