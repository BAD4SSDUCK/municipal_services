import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'forgot_pw_page.dart';
import 'package:municipal_services/code/DisplayPages/dashboard_official.dart';

class LoginPage extends StatefulWidget{
  final bool isLocalMunicipality;
  //final VoidCallback showRegisterPage;

  const LoginPage({Key? key, required this.isLocalMunicipality, //required this.showRegisterPage
  }) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum authProblems { userNotFound, passwordNotValid, networkError }

class _LoginPageState extends State<LoginPage>{

  // text controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Future signIn() async{
  //
  //   //loading circle
  //   showDialog(
  //     context: context,
  //     builder: (context){
  //       return const Center(child: CircularProgressIndicator());
  //     },
  //   );
  //
  //   // try {
  //   //   await FirebaseAuth.instance.signInWithEmailAndPassword(
  //   //     email: _emailController.text.trim(),
  //   //     password: _passwordController.text.trim(),
  //   //   ).whenComplete(() {
  //   //
  //   //     Navigator.of(context).pushReplacement(
  //   //       MaterialPageRoute(
  //   //         builder: (context) => const HomeManagerScreen(),
  //   //       ),
  //   //     );
  //   //   });
  //   try {
  //     UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
  //       email: _emailController.text.trim(),
  //       password: _passwordController.text.trim(),
  //     );
  //
  //     // Fetch districtId and municipalityId dynamically
  //     String userId = userCredential.user?.uid ?? '';
  //
  //     String? districtId;
  //     String? municipalityId;
  //
  //     // Query all districts and municipalities to find the user
  //     final districtsSnapshot = await FirebaseFirestore.instance.collection('districts').get();
  //     for (var districtDoc in districtsSnapshot.docs) {
  //       final municipalitiesSnapshot = await districtDoc.reference.collection('municipalities').get();
  //       for (var municipalityDoc in municipalitiesSnapshot.docs) {
  //         final userDoc = await municipalityDoc.reference.collection('users').doc(userId).get();
  //         if (userDoc.exists) {
  //           districtId = districtDoc.id;
  //           municipalityId = municipalityDoc.id;
  //           break;
  //         }
  //       }
  //       if (districtId != null && municipalityId != null) {
  //         break;
  //       }
  //     }
  //
  //     if (districtId != null && municipalityId != null) {
  //       if (context.mounted) {
  //         Navigator.of(context).pushReplacement(
  //           MaterialPageRoute(
  //             builder: (context) => HomeManagerScreen(
  //               districtId: districtId!,
  //               municipalityId: municipalityId!,
  //             ),
  //           ),
  //         );
  //       }
  //     } else {
  //       throw Exception('User document does not exist in any municipality');
  //     }
  //     if(context.mounted)Navigator.of(context).pop();
  //
  //   } on FirebaseAuthException catch (e) {
  //
  //     authProblems errorType;
  //     if(Platform.isAndroid){
  //       switch(e.message){
  //         case 'There is no user record corresponding to this identifier. The user may have been deleted.':
  //           errorType = authProblems.userNotFound;
  //           Fluttertoast.showToast(msg: "There is no user record corresponding to this email. The user may have been deleted.",gravity: ToastGravity.CENTER);
  //           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //             content: Text('There is no user record corresponding to this identifier. The user may have been deleted.'),
  //             behavior: SnackBarBehavior.floating,
  //             margin: EdgeInsets.all(20.0),
  //             duration: Duration(seconds: 5),
  //           ));
  //           break;
  //         case 'The password is invalid or the user does not have a password.':
  //           errorType = authProblems.passwordNotValid;
  //           Fluttertoast.showToast(msg: "The password is invalid or the user does not have a password.",gravity: ToastGravity.CENTER);
  //           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //             content: Text('The password was incorrect. Enter correct password or reset your password.'),
  //             behavior: SnackBarBehavior.floating,
  //             margin: EdgeInsets.all(20.0),
  //             duration: Duration(seconds: 5),
  //           ));
  //           break;
  //         case 'A network error (such as timeout, interrupted connection or unreachable host) has occurred.':
  //           errorType = authProblems.networkError;
  //           Fluttertoast.showToast(msg: "A network error (such as timeout, interrupted connection or unreachable host) has occurred.",gravity: ToastGravity.CENTER);
  //           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //             content: Text('The internet connection has timed out. Connect to the internet to login'),
  //             behavior: SnackBarBehavior.floating,
  //             margin: EdgeInsets.all(20.0),
  //             duration: Duration(seconds: 5),
  //           ));
  //           break;
  //         default:
  //           print('Case ${e.message} is not yet implemented');
  //       }
  //     } else if (Platform.isIOS) {
  //       switch (e.code) {
  //         case 'Error 17011':
  //           errorType = authProblems.userNotFound;
  //           break;
  //         case 'Error 17009':
  //           errorType = authProblems.passwordNotValid;
  //           break;
  //         case 'Error 17020':
  //           errorType = authProblems.networkError;
  //           break;
  //       // ...
  //         default:
  //           print('Case ${e.message} is not yet implemented');
  //       }
  //     }
  //   }
  //
  //   if(context.mounted)Navigator.of(context).pop();
  // }
  // Future signIn() async {
  //   // Show loading circle
  //   showDialog(
  //     context: context,
  //     builder: (context) => const Center(child: CircularProgressIndicator()),
  //   );
  //
  //   try {
  //     UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
  //       email: _emailController.text.trim(),
  //       password: _passwordController.text.trim(),
  //     );
  //
  //     // Fetch districtId and municipalityId dynamically using collectionGroup
  //     String? userEmail = userCredential.user?.email;
  //     print('User Email: $userEmail');
  //
  //     if (userEmail != null) {
  //       QuerySnapshot userSnapshot = await FirebaseFirestore.instance
  //           .collectionGroup('users')
  //           .where('email', isEqualTo: userEmail)
  //           .limit(1)
  //           .get();
  //
  //       print('User Snapshot Docs Length: ${userSnapshot.docs.length}');
  //
  //       if (userSnapshot.docs.isNotEmpty) {
  //         var userDoc = userSnapshot.docs.first;
  //
  //         // Extract districtId and municipalityId from the document reference path
  //         DocumentReference userDocRef = userDoc.reference;
  //         String municipalityId = userDocRef.parent.parent!.id;
  //         String districtId = userDocRef.parent.parent!.parent!.parent!.id;
  //
  //         print("Full document path: ${userDocRef.path}");
  //         print("District ID: $districtId");
  //         print("Municipality ID: $municipalityId");
  //
  //         // Navigate to HomeManagerScreen with the correct IDs
  //         if (context.mounted) {
  //           Navigator.of(context).pushReplacement(
  //             MaterialPageRoute(
  //               builder: (context) => HomeManagerScreen(
  //
  //               ),
  //             ),
  //           );
  //         }
  //       } else {
  //         throw Exception('User document does not exist in any municipality');
  //       }
  //
  //     }
  //
  //     if (context.mounted) Navigator.of(context).pop(); // Close loading indicator
  //   } on FirebaseAuthException catch (e) {
  //     if (context.mounted) Navigator.of(context).pop(); // Close loading indicator
  //
  //     // Handle FirebaseAuthException and show relevant error messages
  //     _handleAuthException(e);
  //   } catch (e) {
  //     if (context.mounted) Navigator.of(context).pop(); // Close loading indicator
  //     print('Error: $e');
  //   }
  // }

  // Future signIn() async{
  //
  //   //loading circle
  //   showDialog(
  //     context: context,
  //     builder: (context){
  //       return const Center(child: CircularProgressIndicator());
  //     },
  //   );
  //
  //   try {
  //     await FirebaseAuth.instance.signInWithEmailAndPassword(
  //       email: _emailController.text.trim(),
  //       password: _passwordController.text.trim(),
  //     ).whenComplete(() async {
  //       // Fetch user details
  //       User? user = FirebaseAuth.instance.currentUser;
  //       if (user != null) {
  //         // Fetch user data from Firestore
  //         QuerySnapshot userSnapshot = await FirebaseFirestore.instance
  //             .collectionGroup('users')
  //             .where('email', isEqualTo: user.email)
  //             .limit(1)
  //             .get();
  //
  //         if (userSnapshot.docs.isNotEmpty) {
  //           var userDoc = userSnapshot.docs.first;
  //
  //           // Check if the user belongs to a local municipality
  //           bool isLocalMunicipality = userDoc['isLocalMunicipality'] ?? false;
  //
  //           // Navigate to HomeManagerScreen with the isLocalMunicipality flag
  //           Get.off(() => HomeManagerScreen(
  //             isLocalMunicipality: isLocalMunicipality,  // Pass flag to HomeManagerScreen
  //           ));
  //         } else {
  //           // If no user document is found, show an error message
  //           Fluttertoast.showToast(
  //             msg: "User document not found.",
  //             gravity: ToastGravity.CENTER,
  //           );
  //         }
  //       }
  //     });
  //
  //     if (context.mounted) Navigator.of(context).pop();
  //   } on FirebaseAuthException catch (e) {
  //
  //     authProblems errorType;
  //     if(Platform.isAndroid){
  //       switch(e.message){
  //         case 'There is no user record corresponding to this identifier. The user may have been deleted.':
  //           errorType = authProblems.userNotFound;
  //           Fluttertoast.showToast(msg: "There is no user record corresponding to this email. The user may have been deleted.",gravity: ToastGravity.CENTER);
  //           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //             content: Text('There is no user record corresponding to this identifier. The user may have been deleted.'),
  //             behavior: SnackBarBehavior.floating,
  //             margin: EdgeInsets.all(20.0),
  //             duration: Duration(seconds: 5),
  //           ));
  //           break;
  //         case 'The password is invalid or the user does not have a password.':
  //           errorType = authProblems.passwordNotValid;
  //           Fluttertoast.showToast(msg: "The password is invalid or the user does not have a password.",gravity: ToastGravity.CENTER);
  //           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //             content: Text('The password was incorrect. Enter correct password or reset your password.'),
  //             behavior: SnackBarBehavior.floating,
  //             margin: EdgeInsets.all(20.0),
  //             duration: Duration(seconds: 5),
  //           ));
  //           break;
  //         case 'A network error (such as timeout, interrupted connection or unreachable host) has occurred.':
  //           errorType = authProblems.networkError;
  //           Fluttertoast.showToast(msg: "A network error (such as timeout, interrupted connection or unreachable host) has occurred.",gravity: ToastGravity.CENTER);
  //           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //             content: Text('The internet connection has timed out. Connect to the internet to login'),
  //             behavior: SnackBarBehavior.floating,
  //             margin: EdgeInsets.all(20.0),
  //             duration: Duration(seconds: 5),
  //           ));
  //           break;
  //         default:
  //           print('Case ${e.message} is not yet implemented');
  //       }
  //     } else if (Platform.isIOS) {
  //       switch (e.code) {
  //         case 'Error 17011':
  //           errorType = authProblems.userNotFound;
  //           break;
  //         case 'Error 17009':
  //           errorType = authProblems.passwordNotValid;
  //           break;
  //         case 'Error 17020':
  //           errorType = authProblems.networkError;
  //           break;
  //       // ...
  //         default:
  //           print('Case ${e.message} is not yet implemented');
  //       }
  //     }
  //   }
  //
  //   if(context.mounted)Navigator.of(context).pop();
  // }

  Future<void> signIn() async {
    // loading circle
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = cred.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'user-null', message: 'No user');
      }

      // 1) Refresh token so custom claims (developer/devScope) are present
      await user.getIdToken(true);
      final token = await user.getIdTokenResult();
      final claims = token.claims ?? {};
      final isSuperadmin = claims['superadmin'] == true;

      // 2) Resolve municipal profile (supports legacy discovery temporarily)
      final profile = await _loadMunicipalProfile(user);

      // Close spinner before routing / toasting
      if (mounted) Navigator.of(context).pop();

      if (profile == null) {
        Fluttertoast.showToast(
          msg: "Profile not found. Please contact your administrator.",
          gravity: ToastGravity.CENTER,
        );
        return;
      }

      // If only legacy doc exists (no canonical users/{uid}), nudge admin to backfill.
      // You can detect that by checking a known canonical-only field, or by probing again:
      final hasCanonicalUsersDoc = await FirebaseFirestore.instance
          .collection(profile.isLocalMunicipality
          ? 'localMunicipalities'
          : 'districts')
          .doc(profile.isLocalMunicipality ? profile.municipalityId : profile.districtId)
          .collection(profile.isLocalMunicipality ? 'users' : 'municipalities')
          .doc(profile.isLocalMunicipality ? null : profile.municipalityId)
      // The above chaining is messy to inline; skip the extra probe and rely on rules.
      // Kept here as a comment to show idea.
          ;

      // 3) Route — keep your existing HomeManagerScreen but pass what it needs
      Get.off(() => HomeManagerScreen(
        isLocalMunicipality: profile.isLocalMunicipality,
        // You can add optional named params in HomeManagerScreen to accept these:
        // districtId: profile.districtId,
        // municipalityId: profile.municipalityId,
        isSuperadmin: isSuperadmin,
      ));

    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.of(context).pop();
      _handleAuthException(e);
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      Fluttertoast.showToast(
        msg: "Login failed. Please try again.",
        gravity: ToastGravity.CENTER,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login failed. Please try again.'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(20.0),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }


  void _handleAuthException(FirebaseAuthException e) {
    String errorMessage;
    if (Platform.isAndroid) {
      switch (e.message) {
        case 'There is no user record corresponding to this identifier. The user may have been deleted.':
          errorMessage = "No user record found for this email. The user may have been deleted.";
          break;
        case 'The password is invalid or the user does not have a password.':
          errorMessage = "Invalid password. Please try again or reset your password.";
          break;
        case 'A network error (such as timeout, interrupted connection or unreachable host) has occurred.':
          errorMessage = "Network error. Please check your connection and try again.";
          break;
        default:
          errorMessage = "Login failed. Please try again.";
      }
    } else if (Platform.isIOS) {
      switch (e.code) {
        case 'Error 17011':
          errorMessage = "No user record found for this email.";
          break;
        case 'Error 17009':
          errorMessage = "Invalid password.";
          break;
        case 'Error 17020':
          errorMessage = "Network error.";
          break;
        default:
          errorMessage = "Login failed. Please try again.";
      }
    } else {
      errorMessage = "An unexpected error occurred.";
    }

    Fluttertoast.showToast(msg: errorMessage, gravity: ToastGravity.CENTER);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20.0),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                // Image.asset('assets/images/logo.png',height: 200,width: 300,),
                const ResponsiveLogo(),
                const SizedBox(height: 10,),
                Text(
                  'Welcome!',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 50,
                  ),
                ),
                const SizedBox(height: 5,),
                const Text('Let\'s log in to continue.',
                  style: TextStyle(fontSize: 18),),
                const SizedBox(height: 20,),

                // email textfield
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
                      hintText: 'Email',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(height: 10,),

                // password textfield
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Password',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(height: 10,),

                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 25.0),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.end,
                //     children: [
                //       GestureDetector(
                //         onTap: (){
                //           Navigator.push(context,
                //             MaterialPageRoute(builder: (context){
                //               return ForgotPasswordPage();
                //             },
                //             ),
                //           );
                //         },
                //         child: const Text('Forgot Password?',
                //           style: TextStyle(
                //             color: Colors.blue,
                //             fontWeight: FontWeight.bold,
                //           ),),
                //       )
                //     ],
                //   ),
                // ),
                const SizedBox(height: 10,),

                // login button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: GestureDetector(
                    onTap: signIn,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Login',
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Not an official?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: (){
                        Navigator.pop(context);
                        },
                      child: const Text(
                        ' Phone Login',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),),
                    ),
                  ],
                )

                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     const Text(
                //       'Not a member?',
                //       style: TextStyle(
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //     GestureDetector(
                //       onTap: widget.showRegisterPage,
                //       child: const Text(
                //         ' Register now',
                //         style: TextStyle(
                //           color: Colors.blue,
                //           fontWeight: FontWeight.bold,
                //         ),),
                //     ),
                //   ],
                // )

              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ResponsiveLogo extends StatelessWidget {
  const ResponsiveLogo({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the screen width and height
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Set a base logo size that scales based on the screen dimensions
    double logoWidth = screenWidth * 0.3; // Set to 30% of screen width
    double logoHeight = logoWidth * (687 / 550); // Maintain new aspect ratio (550x687)

    return Center(
      child: Container(
        width: logoWidth,
        height: logoHeight,
        child: FittedBox(
          fit: BoxFit.contain,  // Ensures the image scales within the container
          child: Image.asset('assets/images/Municipal_Services_App_Logo.png'),
        ),
      ),
    );
  }
}

class MunicipalProfile {
  final bool isLocalMunicipality;
  final String districtId;       // empty for local
  final String municipalityId;   // doc id
  final Map<String, dynamic> data;

  MunicipalProfile({
    required this.isLocalMunicipality,
    required this.districtId,
    required this.municipalityId,
    required this.data,
  });
}

Future<MunicipalProfile?> _loadMunicipalProfile(User user) async {
  final fs = FirebaseFirestore.instance;
  final uid = user.uid;

  // Try canonical LOCAL: /localMunicipalities/{municipalityId}/users/{uid}
  // If you have a selected/known municipalityId, probe it directly.
  // If not, try discovering via a lightweight collectionGroup (TEMP while migrating).

  // 1) Canonical DISTRICT path probe by discovering IDs from a legacy doc (TEMP)
  final legacy = await fs
      .collectionGroup('users')
      .where('email', isEqualTo: user.email)
      .limit(1)
      .get();

  if (legacy.docs.isNotEmpty) {
    final d = legacy.docs.first;
    final data = d.data();
    final usersColl = d.reference.parent;    // .../users
    final muniDoc = usersColl.parent!;       // .../municipalities/{municipalityId} OR /localMunicipalities/{municipalityId}
    final parentColl = muniDoc.parent;      // 'municipalities' or 'localMunicipalities'
    final muniId = muniDoc.id;

    if (parentColl.id == 'municipalities') {
      final districtId = parentColl.parent!.id; // /districts/{districtId}
      // Prefer the CANONICAL doc keyed by uid (rules expect this)
      final canonical = await fs
          .collection('districts').doc(districtId)
          .collection('municipalities').doc(muniId)
          .collection('users').doc(uid)
          .get();

      if (canonical.exists) {
        return MunicipalProfile(
          isLocalMunicipality: false,
          districtId: districtId,
          municipalityId: muniId,
          data: canonical.data() as Map<String, dynamic>,
        );
      } else {
        // Legacy found but no canonical doc yet — return legacy info so you can inform admin/backfill
        return MunicipalProfile(
          isLocalMunicipality: false,
          districtId: districtId,
          municipalityId: muniId,
          data: data,
        );
      }
    } else {
      // localMunicipalities
      final canonical = await fs
          .collection('localMunicipalities').doc(muniId)
          .collection('users').doc(uid)
          .get();

      if (canonical.exists) {
        return MunicipalProfile(
          isLocalMunicipality: true,
          districtId: '',
          municipalityId: muniId,
          data: canonical.data() as Map<String, dynamic>,
        );
      } else {
        return MunicipalProfile(
          isLocalMunicipality: true,
          districtId: '',
          municipalityId: muniId,
          data: d.data(),
        );
      }
    }
  }

  // If nothing found at all, return null
  return null;
}
