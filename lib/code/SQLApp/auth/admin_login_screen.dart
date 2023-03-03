import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:municipal_track/code/SQLApp/Auth/login_screen.dart';
import 'package:municipal_track/code/SQLApp/Auth/signup_screen.dart';
import 'package:http/http.dart' as http;

import 'package:municipal_track/code/ApiConnection/api_connection.dart';
import 'package:municipal_track/code/SQLApp/model/user.dart';
import 'package:municipal_track/code/SQLApp/userPreferences/user_preferences.dart';

import 'package:municipal_track/code/SQLApp/fragments/dashboard_of_fragments_sql.dart';
import 'package:url_launcher/url_launcher.dart';
//
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {

  var formKey = GlobalKey<FormState>();
  var userNameController = TextEditingController();
  var passwordController = TextEditingController();
  var isObscure = true.obs;

  loginUserNow() async {
    try {
      var res = await http.post(
        Uri.parse(API.login),
        body: {
          "userName": userNameController.text.trim(),
          "userPassword": passwordController.text.trim(),
        },
      );

      if (res.statusCode == 200) {
        var resBodyOfLogin = jsonDecode(res.body);
        if (resBodyOfLogin['success'] == true) {
          print('reaching login api');
          Fluttertoast.showToast(msg: "You are logged in Successfully");

          User userInfo = User.fromJson(resBodyOfLogin["userData"]);

          //save user info to local storage using shared Preferences
          await RememberUserPrefs.storeUserInfo(userInfo);

          //send user to a dashboard once logged in 'DashboardOfFragments' is a temp dashboard to test the sql user info login
          Future.delayed(Duration(milliseconds: 2000), () {
            Get.to(DashboardOfFragments());
          });
        } else {
          Fluttertoast.showToast(
              msg: "Incorrect credentials. \nPlease enter correct password and phone number and Try Again.");
        }
      }
    } catch (e) {
      print("Error :: " + e.toString());
      Fluttertoast.showToast(msg: e.toString());
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

                  //Login screen header
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
                            //login with phone number form
                            Form(
                              key: formKey,
                              child: Column(
                                children: [

                                  ///Username
                                  TextFormField(
                                    controller: userNameController,
                                    validator: (val) =>
                                    val == ""
                                        ? "Please Enter Your Username"
                                        : null,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.phone,
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
                                      onTap: () {
                                        if(formKey.currentState!.validate()) {
                                          loginUserNow();
                                        }
                                        },
                                      borderRadius: BorderRadius.circular(30),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 28,
                                        ),
                                        child: Text(
                                          "Login",
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

                            //register new account if none
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an Account?"),
                                TextButton(
                                  onPressed: () {
                                    ///Using this needs to be for managers phone number.
                                    final Uri _tel = Uri.parse('tel:+27${"TOBE changed"}');
                                    launchUrl(_tel);
                                  },
                                  child: const Text("Contact Manager",
                                    style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 16
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const Text("Or",
                                style: TextStyle(
                                    color: Colors.green, fontSize: 16)),

                            //admin sing in instead.
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Are you a regular user?"),
                                TextButton(
                                  onPressed: () {
                                    Get.to(LoginScreen());
                                  },
                                  child: const Text("Click Here",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 16,
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
