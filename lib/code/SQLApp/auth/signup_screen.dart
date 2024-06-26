import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:municipal_services/code/SQLApp/Auth/login_screen.dart';
import 'package:http/http.dart' as http;

import 'package:municipal_services/code/ApiConnection/api_connection.dart';
import 'package:municipal_services/code/SQLApp/model/user.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}
//
class _SignUpScreenState extends State<SignUpScreen> {

  var formKey = GlobalKey<FormState>();
  var phoneNumberController = TextEditingController();
  var emailController = TextEditingController();
  var firstNameController = TextEditingController();
  var lastNameController = TextEditingController();
  var userNameController = TextEditingController();
  var passwordController = TextEditingController();
  var rollController = '';
  var isObscure = true.obs;

  Future <void> validateUserPhone() async{
    try {
      var res = await http.post(
        Uri.parse(API.validatePhone),
        body: {
          'cellNumber': phoneNumberController.text.trim(),
        }
      );
      print(res.statusCode.toString());
      if(res.statusCode == 200){ //from the flutter app the connection with api to the server is a success
        var resBodyOfValidPhone = jsonDecode(res.body);
        if(resBodyOfValidPhone['phoneFound'] == true){
          Fluttertoast.showToast(msg: "Phone Number already in use. Try a different phone number if you have not already registered.");
        }
        else{
          //register new user and save new record to db
          registerAndSaveUserRecord();
        }
      }
    } catch(e){
      print("error is::"+e.toString());
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  registerAndSaveUserRecord() async {
    if (phoneNumberController.toString().contains('+27')) {
      User userModel = User(
        1,
        phoneNumberController.text.trim(),
        emailController.text.trim(),
        firstNameController.text.trim(),
        lastNameController.text.trim(),
        userNameController.text.trim(),
        passwordController.text.trim(),
        rollController,
        false,
      );
      try {
        var res = await http.post(
          Uri.parse(API.signUp),
          body: userModel.toJson(),
        );
        if (res.statusCode == 200) {
          print('reaching signup api');
          var resBodyOfSigneUp = jsonDecode(jsonEncode(res.body));
          if (resBodyOfSigneUp['success'] == true) {
            Fluttertoast.showToast(
                msg: "Congratulations, you have Signed Up Successfully");

            setState(() {
              phoneNumberController.clear();
              emailController.clear();
              firstNameController.clear();
              lastNameController.clear();
              userNameController.clear();
              passwordController.clear();
            });
          } else {
            Fluttertoast.showToast(msg: "Error Occurred, Try Again.");
          }
        }
      } catch (e) {
        print(e.toString());
        Fluttertoast.showToast(msg: e.toString());
      }
    } else {
      Fluttertoast.showToast(
          msg: "Please use phone number country code format.\nReplace the first 0 with +27");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      body: LayoutBuilder(
        builder: (context, cons) {
          return ConstrainedBox(
            constraints: BoxConstraints(
                minHeight: cons.maxHeight
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 100,),
                  //Signup screen header
                  Center(
                    child: SizedBox(
                      width: MediaQuery
                          .of(context)
                          .size
                          .width,
                      height: 250,
                      child: Image.asset("assets/images/logo.png"),
                    ),
                  ),

                  const SizedBox(height: 20,),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white60,
                        borderRadius: BorderRadius.all(Radius.circular(60),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 8,
                            color: Colors.black26,
                            offset: Offset(0, -3),
                          )
                        ],

                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(30, 30, 30, 8),
                        child: Column(
                          children: [
                            //signup with phone number form
                            Form(
                              key: formKey,
                              child: Column(
                                children: [

                                  ///User Name field
                                  TextFormField(
                                    controller: userNameController,
                                    validator: (val) =>
                                    val == ""
                                        ? "Please enter your Username"
                                        : null,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.person,
                                        color: Colors.black,
                                      ),
                                      hintText: "Username...",
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              30),
                                          borderSide: const BorderSide(
                                            color: Colors.white60,
                                          )
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              30),
                                          borderSide: const BorderSide(
                                            color: Colors.white60,
                                          )
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              30),
                                          borderSide: const BorderSide(
                                            color: Colors.white60,
                                          )
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              30),
                                          borderSide: const BorderSide(
                                            color: Colors.white60,
                                          )
                                      ),
                                      contentPadding: const EdgeInsets
                                          .symmetric(
                                          horizontal: 14,
                                          vertical: 6
                                      ),
                                      fillColor: Colors.white,
                                      filled: true,
                                    ),
                                  ),

                                  const SizedBox(height: 18,),

                                  ///Phone number
                                  TextFormField(
                                    controller: phoneNumberController,
                                    validator: (val) =>
                                    val == ""
                                        ? "Please enter your Phone Number"
                                        : null,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.phone,
                                        color: Colors.black,
                                      ),
                                      hintText: "+27 Phone Number...",
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              30),
                                          borderSide: const BorderSide(
                                            color: Colors.white60,
                                          )
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              30),
                                          borderSide: const BorderSide(
                                            color: Colors.white60,
                                          )
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              30),
                                          borderSide: const BorderSide(
                                            color: Colors.white60,
                                          )
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              30),
                                          borderSide: const BorderSide(
                                            color: Colors.white60,
                                          )
                                      ),
                                      contentPadding: const EdgeInsets
                                          .symmetric(
                                          horizontal: 14,
                                          vertical: 6
                                      ),
                                      fillColor: Colors.white,
                                      filled: true,
                                    ),
                                  ),

                                  const SizedBox(height: 18,),

                                  ///Email
                                  TextFormField(
                                    controller: emailController,
                                    validator: (val) =>
                                    val == ""
                                        ? "Please enter your Email Address"
                                        : null,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.email,
                                        color: Colors.black,
                                      ),
                                      hintText: "email...",
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              30),
                                          borderSide: const BorderSide(
                                            color: Colors.white60,
                                          )
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              30),
                                          borderSide: const BorderSide(
                                            color: Colors.white60,
                                          )
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              30),
                                          borderSide: const BorderSide(
                                            color: Colors.white60,
                                          )
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              30),
                                          borderSide: const BorderSide(
                                            color: Colors.white60,
                                          )
                                      ),
                                      contentPadding: const EdgeInsets
                                          .symmetric(
                                          horizontal: 14,
                                          vertical: 6
                                      ),
                                      fillColor: Colors.white,
                                      filled: true,
                                    ),
                                  ),

                                  const SizedBox(height: 18,),

                                  ///First name
                                  TextFormField(
                                    controller: firstNameController,
                                    validator: (val) =>
                                    val == ""
                                        ? "Please enter your First Name"
                                        : null,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.person_rounded,
                                        color: Colors.black,
                                      ),
                                      hintText: "First Name...",
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              30),
                                          borderSide: const BorderSide(
                                            color: Colors.white60,
                                          )
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              30),
                                          borderSide: const BorderSide(
                                            color: Colors.white60,
                                          )
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              30),
                                          borderSide: const BorderSide(
                                            color: Colors.white60,
                                          )
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              30),
                                          borderSide: const BorderSide(
                                            color: Colors.white60,
                                          )
                                      ),
                                      contentPadding: const EdgeInsets
                                          .symmetric(
                                          horizontal: 14,
                                          vertical: 6
                                      ),
                                      fillColor: Colors.white,
                                      filled: true,
                                    ),
                                  ),

                                  const SizedBox(height: 18,),

                                  ///Last name
                                  TextFormField(
                                    controller: lastNameController,
                                    validator: (val) =>
                                    val == ""
                                        ? "Please enter your Last Name"
                                        : null,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.person_rounded,
                                        color: Colors.black,
                                      ),
                                      hintText: "Last Name...",
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              30),
                                          borderSide: const BorderSide(
                                            color: Colors.white60,
                                          )
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              30),
                                          borderSide: const BorderSide(
                                            color: Colors.white60,
                                          )
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              30),
                                          borderSide: const BorderSide(
                                            color: Colors.white60,
                                          )
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              30),
                                          borderSide: const BorderSide(
                                            color: Colors.white60,
                                          )
                                      ),
                                      contentPadding: const EdgeInsets
                                          .symmetric(
                                          horizontal: 14,
                                          vertical: 6
                                      ),
                                      fillColor: Colors.white,
                                      filled: true,
                                    ),
                                  ),

                                  const SizedBox(height: 18,),

                                  ///Password
                                  Obx(
                                        () =>
                                        TextFormField(
                                          controller: passwordController,
                                          obscureText: isObscure.value,
                                          validator: (val) =>
                                          val == ""
                                              ? "Please enter your password"
                                              : null,
                                          decoration: InputDecoration(
                                            prefixIcon: const Icon(
                                              Icons.vpn_key_sharp,
                                              color: Colors.black,
                                            ),
                                            suffixIcon: Obx(
                                                    () =>
                                                    GestureDetector(
                                                      onTap: () {
                                                        isObscure.value =
                                                        !isObscure.value;
                                                      },
                                                      child: Icon(
                                                        isObscure.value
                                                            ? Icons
                                                            .visibility_off
                                                            : Icons.visibility,
                                                        color: Colors.black,
                                                      ),
                                                    )
                                            ),
                                            hintText: "Password...",
                                            border: OutlineInputBorder(
                                                borderRadius: BorderRadius
                                                    .circular(30),
                                                borderSide: const BorderSide(
                                                  color: Colors.white60,
                                                )
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius
                                                    .circular(30),
                                                borderSide: const BorderSide(
                                                  color: Colors.white60,
                                                )
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius
                                                    .circular(30),
                                                borderSide: const BorderSide(
                                                  color: Colors.white60,
                                                )
                                            ),
                                            disabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius
                                                    .circular(30),
                                                borderSide: const BorderSide(
                                                  color: Colors.white60,
                                                )
                                            ),
                                            contentPadding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 14,
                                                vertical: 6
                                            ),
                                            fillColor: Colors.white,
                                            filled: true,
                                          ),
                                        ),
                                  ),

                                  const SizedBox(height: 18,),

                                  ///Button for login
                                  Material(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(30),
                                    child: InkWell(
                                      onTap: () async {
                                        ///This button needs to be fixed, the validate with user phone function does not seem to be running when tapped
                                        // if(formKey.currentState!.validate() == true){
                                        //   //validation of phone number already in the db so it is in use, only one user can have this phone number
                                        //   validateUserPhone();
                                        //   print("validateUserPhone fuction :: "+validateUserPhone().toString());
                                        // }
                                        //print("Form feilds filled state :: "+formKey.currentState!.validate().toString());

                                      },
                                      borderRadius: BorderRadius.circular(30),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 28,
                                        ),
                                        child: Text(
                                          "Sign Up",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )

                                ],
                              ),
                            ),

                            const SizedBox(height: 16,),

                            //Account exists, login with username and password
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Already have an Account?"),
                                TextButton(
                                  onPressed: () {
                                    // Get.to(LoginScreen());
                                  },
                                  child: const Text("Login Here",
                                    style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 16
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
