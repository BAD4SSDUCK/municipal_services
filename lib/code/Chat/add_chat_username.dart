import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../QueryChat/pages/chat_home_page.dart';


class AddChatUsername extends StatefulWidget {
  const AddChatUsername({Key? key}) : super(key: key);

  @override
  State<AddChatUsername> createState() => _AddChatUsernameState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final User? user = auth.currentUser;
final uid = user?.uid;
String userID = uid as String;

final pn = user?.phoneNumber;
String currentPhoneNum = pn as String;


class _AddChatUsernameState extends State<AddChatUsername> {

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cellNumberController = currentPhoneNum;
  final _profilePicController = TextEditingController();
  final _userIDController = userID;

  bool sentItem = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    //_cellNumberController.dispose();
    _profilePicController.dispose();
    super.dispose();
  }

  @override
  void initState(){
    settingPreFilled();
  }

  void settingPreFilled(){
    print(currentPhoneNum);

  }

  Future dataAdd() async {
    // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    //   content: Text('Please enter correct email and password'),
    //   behavior: SnackBarBehavior.floating,
    //   margin: EdgeInsets.all(20.0),
    //   duration: Duration(seconds: 5),
    // ));

    showDialog(
      context: context,
      builder: (context){
        return const Center(child: CircularProgressIndicator());
      },
    );

    if(fieldsNotEmptyConfirmed() == true) {
      addUserDetails(
        _fullNameController.text.trim(),
        _emailController.text.trim(),
        _cellNumberController,
        _profilePicController.text.trim(),
        _userIDController,
      );

      sentItem = true;

    } else {
      Navigator.of(context).pop();
    }

  }

  bool fieldsNotEmptyConfirmed(){
    if (_fullNameController.text.isNotEmpty && _emailController.text.isNotEmpty ){//&& _cellNumberController.text.isNotEmpty
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Chat details are saved!'),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20.0),
        duration: Duration(seconds: 5),
      ));
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Makes sure all fields are filled!'),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20.0),
        duration: Duration(seconds: 5),
      ));
      return false;
    }
  }

  Future addUserDetails(String fullName, String email, String cellNumber, String profilePic, String userid) async{

    profilePic="";

    if(fieldsNotEmptyConfirmed() == false){
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please make sure all necessary information is entered'),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20.0),
        duration: Duration(seconds: 5),
      ));

    } else {
      await FirebaseFirestore.instance.collection('users').add({
        'fullName': fullName,
        'cell number': cellNumber,
        'profilePic': profilePic,
        'uid': userid,

      });

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(

              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //Image.asset('images/MainMenu/logo.png',height: 200,width: 300,),
                const SizedBox(height: 20,),
                Text(
                  'Hello There',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 50,
                  ),
                ),
                const SizedBox(height: 10,),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.0),
                  child: Text('Enter all details bellow to make a query or follow an existing one!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18,),),
                ),
                const SizedBox(height: 40,),

                Padding(
                  padding:  const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: _fullNameController,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'User Name',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                ),

                const SizedBox(height: 10,),

                Padding(
                  padding:  const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Email Address',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                ),

                const SizedBox(height: 10,),

                // Padding(
                //   padding:  const EdgeInsets.symmetric(horizontal: 25.0),
                //   child: TextField(
                //     controller: _cellNumberController,
                //     decoration: InputDecoration(
                //       enabledBorder: OutlineInputBorder(
                //         borderSide: const BorderSide(color: Colors.white),
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //       focusedBorder: OutlineInputBorder(
                //         borderSide: const BorderSide(color: Colors.green),
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //       hintText: 'Cellphone Number',
                //       fillColor: Colors.grey[200],
                //       filled: true,
                //     ),
                //   ),
                // ),
                //
                // const SizedBox(height: 10,),


                // login button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: GestureDetector(
                    onTap: () {
                      dataAdd();
                      if(sentItem == true) {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) =>
                                const ChatHomePage()));
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
                          'Add Details!',
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

                const SizedBox(height: 25,),
              ],
            ),
          ),
        ),
      ),
    );
  }
}