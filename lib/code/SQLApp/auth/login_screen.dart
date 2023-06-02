// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:get/get.dart';
// import 'package:municipal_track/code/SQLApp/Auth/signup_screen.dart';
// import 'package:http/http.dart' as http;
//
// import 'package:municipal_track/code/ApiConnection/api_connection.dart';
// import 'package:municipal_track/code/SQLApp/auth/admin_login_screen.dart';
// import 'package:municipal_track/code/SQLApp/model/user.dart';
// import 'package:municipal_track/code/SQLApp/userPreferences/user_preferences.dart';
//
// import 'package:municipal_track/code/SQLApp/fragments/dashboard_of_fragments_sql.dart';
// //
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({Key? key}) : super(key: key);
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//
//   var formKey = GlobalKey<FormState>();
//   var phoneNumberController = TextEditingController();
//   var passwordController = TextEditingController();
//   var isObscure = true.obs;
//
//   loginUserNow() async {
//     if (phoneNumberController.toString().contains('+27')) {
//       try {
//         //print('reaching login api');
//         //ByteData rootCACertificate = await rootBundle.load("assets/ca.pem");
//         //ByteData clientCertificate = await rootBundle.load("assets/cert.pem");
//         //ByteData privateKey = await rootBundle.load("assets/public_key.pem");
//
//         var res = await http.post(
//           Uri.parse(API.login),
//           body: {
//             "cellNumber": phoneNumberController.text.trim(),
//             "userPassword": passwordController.text.trim(),
//           },
//         );
//         print(res.toString());
//         if (res.statusCode == 200) {
//
//           print('the body is::${res.body}');
//           var resBodyOfLogin = jsonDecode(res.body);
//           if (resBodyOfLogin['success'] == true) {
//             Fluttertoast.showToast(msg: "You are logged in Successfully");
//
//             User userInfo = User.fromJson(resBodyOfLogin["userData"]);
//
//             //save user info to local storage using shared Preferences
//             await RememberUserPrefs.storeUserInfo(userInfo);
//
//             //send user to a dashboard once logged in 'DashboardOfFragments' is a temp dashboard to test the sql user info login
//             Future.delayed(Duration(milliseconds: 2000), () {
//               Get.to(DashboardOfFragments());
//             });
//           } else {
//             Fluttertoast.showToast(
//                 msg: "Incorrect credentials. \nPlease enter correct password and phone number and Try Again.");
//           }
//         }
//       } catch (e) {
//         print("Error :: " + e.toString());
//         Fluttertoast.showToast(msg: e.toString());
//       }
//     } else {
//       Fluttertoast.showToast(
//           msg: "Please use phone number country code format.\nReplace the first 0 with +27");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey,
//       body: LayoutBuilder(
//         builder: (context, cons) {
//           return ConstrainedBox(
//             constraints: BoxConstraints(
//                 minHeight: cons.maxHeight
//             ),
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   const SizedBox(height: 100,),
//
//                   //Login screen header
//                   Center(
//                     child: SizedBox(
//                       width: MediaQuery
//                           .of(context)
//                           .size
//                           .width,
//                       height: 250,
//                       child: Image.asset("assets/images/logo.png"),
//                     ),
//                   ),
//
//                   const SizedBox(height: 20,),
//
//                   Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Container(
//                       decoration: const BoxDecoration(
//                         color: Colors.white60,
//                         borderRadius: BorderRadius.all(Radius.circular(60),
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             blurRadius: 8,
//                             color: Colors.black26,
//                             offset: Offset(0, -3),
//                           )
//                         ],
//                       ),
//
//                       child: Padding(
//                         padding: const EdgeInsets.fromLTRB(30, 30, 30, 8),
//                         child: Column(
//                           children: [
//                             //login with phone number form
//                             Form(
//                               key: formKey,
//                               child: Column(
//                                 children: [
//
//                                   ///Phone number
//                                   TextFormField(
//                                     controller: phoneNumberController,
//                                     validator: (val) =>
//                                     val == ""
//                                         ? "Please Enter Your Phone Number"
//                                         : null,
//                                     decoration: InputDecoration(
//                                       prefixIcon: const Icon(
//                                         Icons.phone,
//                                         color: Colors.black,
//                                       ),
//                                       hintText: "+27 Phone Number...",
//                                       border: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(
//                                               30),
//                                           borderSide: const BorderSide(
//                                             color: Colors.white60,
//                                           )
//                                       ),
//                                       enabledBorder: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(
//                                               30),
//                                           borderSide: const BorderSide(
//                                             color: Colors.white60,
//                                           )
//                                       ),
//                                       focusedBorder: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(
//                                               30),
//                                           borderSide: const BorderSide(
//                                             color: Colors.white60,
//                                           )
//                                       ),
//                                       disabledBorder: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(
//                                               30),
//                                           borderSide: const BorderSide(
//                                             color: Colors.white60,
//                                           )
//                                       ),
//                                       contentPadding: const EdgeInsets
//                                           .symmetric(
//                                           horizontal: 14,
//                                           vertical: 6
//                                       ),
//                                       fillColor: Colors.white,
//                                       filled: true,
//                                     ),
//                                   ),
//
//                                   const SizedBox(height: 18,),
//
//                                   ///Password
//                                   Obx(
//                                         () =>
//                                         TextFormField(
//                                           controller: passwordController,
//                                           obscureText: isObscure.value,
//                                           validator: (val) =>
//                                           val == ""
//                                               ? "Please Enter Your Password"
//                                               : null,
//                                           decoration: InputDecoration(
//                                             prefixIcon: const Icon(
//                                               Icons.vpn_key_sharp,
//                                               color: Colors.black,
//                                             ),
//                                             suffixIcon: Obx(
//                                                     () =>
//                                                     GestureDetector(
//                                                       onTap: () {
//                                                         isObscure.value =
//                                                         !isObscure.value;
//                                                       },
//                                                       child: Icon(
//                                                         isObscure.value
//                                                             ? Icons
//                                                             .visibility_off
//                                                             : Icons.visibility,
//                                                         color: Colors.black,
//                                                       ),
//                                                     )
//                                             ),
//                                             hintText: "Password...",
//                                             border: OutlineInputBorder(
//                                                 borderRadius: BorderRadius
//                                                     .circular(30),
//                                                 borderSide: const BorderSide(
//                                                   color: Colors.white60,
//                                                 )
//                                             ),
//                                             enabledBorder: OutlineInputBorder(
//                                                 borderRadius: BorderRadius
//                                                     .circular(30),
//                                                 borderSide: const BorderSide(
//                                                   color: Colors.white60,
//                                                 )
//                                             ),
//                                             focusedBorder: OutlineInputBorder(
//                                                 borderRadius: BorderRadius
//                                                     .circular(30),
//                                                 borderSide: const BorderSide(
//                                                   color: Colors.white60,
//                                                 )
//                                             ),
//                                             disabledBorder: OutlineInputBorder(
//                                                 borderRadius: BorderRadius
//                                                     .circular(30),
//                                                 borderSide: const BorderSide(
//                                                   color: Colors.white60,
//                                                 )
//                                             ),
//                                             contentPadding: const EdgeInsets
//                                                 .symmetric(
//                                                 horizontal: 14,
//                                                 vertical: 6
//                                             ),
//                                             fillColor: Colors.white,
//                                             filled: true,
//                                           ),
//                                         ),
//                                   ),
//
//                                   const SizedBox(height: 18,),
//
//                                   ///Button for login
//                                   Material(
//                                     color: Colors.green,
//                                     borderRadius: BorderRadius.circular(30),
//                                     child: InkWell(
//                                       onTap: () {
//                                         if(formKey.currentState!.validate()) {
//                                           loginUserNow();
//                                         }
//                                         },
//                                       borderRadius: BorderRadius.circular(30),
//                                       child: const Padding(
//                                         padding: EdgeInsets.symmetric(
//                                           vertical: 10,
//                                           horizontal: 28,
//                                         ),
//                                         child: Text(
//                                           "Login",
//                                           style: TextStyle(
//                                             color: Colors.white,
//                                             fontSize: 16,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   )
//
//                                 ],
//
//                               ),
//                             ),
//
//                             const SizedBox(height: 16,),
//
//                             //register new account if none
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 const Text("Don't have an Account?"),
//                                 TextButton(
//                                   onPressed: () {
//                                     ///Using this can be changed for other pages instead of using Navigator.push in any onPressed:/onTap: functions.
//                                     // [GETX] WARNING, consider using: "Get.to(() => Page())" instead of "Get.to(Page())".
//                                     // Using a widget function instead of a widget fully guarantees that the widget and its controllers will be removed from memory when they are no longer used.
//                                     Get.to(SignUpScreen());
//                                   },
//                                   child: const Text("Register Here",
//                                     style: TextStyle(
//                                         color: Colors.blue,
//                                         fontSize: 16
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//
//                             const Text("Or",
//                                 style: TextStyle(
//                                     color: Colors.green, fontSize: 16)),
//
//                             //admin sing in instead.
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 const Text("Are you an Admin?"),
//                                 TextButton(
//                                   onPressed: () {
//                                     Get.to(AdminLoginScreen());
//                                   },
//                                   child: const Text("Click Here",
//                                     style: TextStyle(
//                                       color: Colors.blue,
//                                       fontSize: 16,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//
//
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
