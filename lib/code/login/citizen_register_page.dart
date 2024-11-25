import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:municipal_services/code/DisplayPages/dashboard.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../DisplayPages/prop_selection.dart';
import '../Models/property.dart';

class RegisterPasswordScreen extends StatefulWidget {
  const RegisterPasswordScreen({Key? key}) : super(key: key);

  @override
  State<RegisterPasswordScreen> createState() => _RegisterPasswordScreenState();
}

class _RegisterPasswordScreenState extends State<RegisterPasswordScreen> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  double screenHeight = 0;
  double screenWidth = 0;
  double bottom = 0;

  String otpPin = " ";
  String countryDial = "+27";
  String verID = " ";

  int screenState = 0;

  Color blue = const Color(0xff8cccff);
  bool _isLoadingProperties = false;

  @override
  void dispose() {
    print('dispose called on this widget.');
    super.dispose();
  }

  Future<void> registerPhone(String number) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: number,
      timeout: const Duration(seconds: 20),
      verificationCompleted: (PhoneAuthCredential credential) {
        showSnackBarText("Auth Completed!");
      },
      verificationFailed: (FirebaseAuthException e) {
        showSnackBarText("Auth Failed!");
        showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) {
              return
                AlertDialog(
                  shape: const RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.all(Radius.circular(16))),
                  title: const Text("Login Error"),
                  content: const Text(
                      "Would you like to contact the municipality for assistance on this error?"),
                  actions: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(
                        Icons.cancel,
                        color: Colors.red,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final Uri _tel = Uri.parse('tel:+27${0800001868}');
                        launchUrl(_tel);
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(
                        Icons.done,
                        color: Colors.green,
                      ),
                    ),
                  ],
                );
            });
      },
      codeSent: (String verificationId, int? resendToken) {
        showSnackBarText("OTP Sent!");
        verID = verificationId;
        setState(() {
          screenState = 1;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        showSnackBarText("Timeout!");
      },
    );
  }

  // Future<void> verifyOTP() async {
  //   await FirebaseAuth.instance.signInWithCredential(
  //     PhoneAuthProvider.credential(
  //       verificationId: verID,
  //       smsCode: otpPin,
  //     ),
  //   ).whenComplete(() {
  //     Navigator.of(context).pushReplacement(
  //       MaterialPageRoute(
  //         builder: (context) => const  PropertySelectionScreen(properties: [],),
  //       ),
  //     );
  //   });
  // }
  Future<void> clearFirestoreCacheIfNeeded() async {
    // You can use shared preferences or a similar solution to track if the cache was cleared already
    // For example, using shared preferences:
    final prefs = await SharedPreferences.getInstance();
    bool cacheCleared = prefs.getBool('cacheCleared') ?? false;

    if (!cacheCleared) {
      try {
       // await FirebaseFirestore.instance.terminate();
        await FirebaseFirestore.instance.clearPersistence();
      //  await FirebaseFirestore.instance.enablePersistence();

        print("Firestore cache cleared.");
        // Mark cache as cleared
        prefs.setBool('cacheCleared', true);
      } catch (e) {
        print("Error clearing Firestore cache: $e");
      }
    }
  }


  Future<void> verifyOTP() async {
    print('Starting OTP verification...');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      try {
        setState(() {
          _isLoadingProperties = true;
        });
        // Perform OTP verification
        await FirebaseAuth.instance.signInWithCredential(
          PhoneAuthProvider.credential(
            verificationId: verID,
            smsCode: otpPin,
          ),
        );
        print('OTP verification successful.');

        // Get the user's phone number
        String? userPhone = FirebaseAuth.instance.currentUser?.phoneNumber;

        if (userPhone != null) {
          print('Clearing Firestore cache...');
          await clearFirestoreCacheIfNeeded();
          print('Cache cleared.');

          // Fetch properties associated with this phone number
          print('Fetching properties...');
          List<Property> properties = await fetchUserProperties(userPhone);
          print('Properties fetched: ${properties.length}');

          // Log each property explicitly
          for (var property in properties) {
            print('Property: ${property.address}, Account No: ${property.accountNo}, Is Local Municipality: ${property.isLocalMunicipality}');
          }
          bool isLocalMunicipality = properties.isNotEmpty && properties.first.isLocalMunicipality;

          // Navigate to the PropertySelectionScreen using GetX
          print('Navigating to PropertySelectionScreen...');
          Get.off(() =>
              PropertySelectionScreen(
                properties: properties,
                userPhoneNumber: userPhone,
                isLocalMunicipality: isLocalMunicipality,
              ));
        } else {
          print('Error: User phone number is null.');
        }
      } catch (e) {
        print('Error during OTP verification: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingProperties = false;
          });
        }
      }
    });
  }

// Fetch user's properties from Firestore
  Future<List<Property>> fetchUserProperties(String userPhone) async {
    List<Property> properties = [];
    try {
      print('Starting to fetch properties for phone number: $userPhone');

      // Step 1: Check Firestore instance
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      print('Firestore instance initialized: $firestore');

      // Step 2: Execute the collectionGroup query to get properties linked to the phone number
      print('Running collectionGroup query...');
      final propertiesSnapshot = await firestore
          .collectionGroup('properties')
          .where('cellNumber', isEqualTo: userPhone)
          .get();

      print('Query completed. Found ${propertiesSnapshot.docs.length} documents.');

      // Step 3: Loop through each document found and process based on isLocalMunicipality
      for (var propertyDoc in propertiesSnapshot.docs) {
        print('Processing document with ID: ${propertyDoc.id}');
        try {
          Property property = Property.fromSnapshot(propertyDoc);
          properties.add(property);
          print('Property added: ${property.address} - Account No: ${property.accountNo}, Local Municipality: ${property.isLocalMunicipality}');

          // Add conditional logic if necessary based on whether it is a local municipality
          if (property.isLocalMunicipality) {
            print("This property is managed by a local municipality, districtId is not required.");
          } else {
            print("This property belongs to a district-managed municipality.");
          }
        } catch (e) {
          print('Error converting document to Property: $e');
        }
      }

      if (properties.isEmpty) {
        print('No properties found for the phone number.');
      } else {
        print('Successfully fetched ${properties.length} properties.');
      }
    } catch (e) {
      print('Error fetching properties: $e');
    }

    return properties;
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    bottom = MediaQuery.of(context).viewInsets.bottom;

    return WillPopScope(
      onWillPop: () {
        setState(() {
          screenState = 0;
        });
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: blue,
        body:_isLoadingProperties
            ? const Center(child: CircularProgressIndicator())
            : SizedBox(
          height: screenHeight,
          width: screenWidth,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: screenHeight / 8),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          "GET DETAILS",
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth / 10,
                          ),
                        ),
                        Text(
                          "Sign in with your mobile number!",
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: screenWidth / 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: circle(5),
              ),
              Transform.translate(
                offset: const Offset(30, -30),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: circle(4.5),
                ),
              ),
              Center(
                child: circle(3),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  height: bottom > 0 ? screenHeight : screenHeight / 2,
                  width: screenWidth,
                  color: Colors.white,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.fastLinearToSlowEaseIn,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: screenWidth / 12,
                      right: screenWidth / 12,
                      top: bottom > 0 ? screenHeight / 12 : 0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        screenState == 0 ? stateRegister() : stateOTP(),
                        GestureDetector(
                          onTap: () {
                            if(screenState == 0) {
                              // if(usernameController.text.isEmpty) {
                              //   showSnackBarText("Username is still empty!");
                              // } else
                              if(phoneController.text.isEmpty) {
                                showSnackBarText("Phone number is still empty!");
                              } else {
                                showSnackBarText("Now verifying your phone number!");
                                registerPhone(countryDial + phoneController.text);
                              }
                            } else {
                              if(otpPin.length >= 6) {
                                verifyOTP();
                              } else {
                                showSnackBarText("Enter OTP correctly!");
                              }
                            }
                          },
                          child: Container(
                            height: 50,
                            width: screenWidth,
                            margin: EdgeInsets.only(bottom: screenHeight / 12),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Center(
                              child: Text(
                                "CONTINUE",
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void showSnackBarText(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  Widget stateRegister() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   "Username",
        //   style: GoogleFonts.montserrat(
        //     color: Colors.black87,
        //     fontWeight: FontWeight.bold,
        //   ),
        // ),
        // const SizedBox(height: 8,),
        // TextFormField(
        //   controller: usernameController,
        //   decoration: InputDecoration(
        //     border: OutlineInputBorder(
        //       borderRadius: BorderRadius.circular(16),
        //     ),
        //     contentPadding: const EdgeInsets.symmetric(
        //       horizontal: 16,
        //     ),
        //   ),
        // ),
        const SizedBox(height: 16,),
        Text(
          "Phone number",
          style: GoogleFonts.montserrat(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        IntlPhoneField(
          textAlign: TextAlign.start,
          style: const TextStyle(fontSize: 14,),
          controller: phoneController,
          showCountryFlag: false,
          showDropdownIcon: false,
          initialValue: countryDial,
          onCountryChanged: (country) {
            setState(() {
              countryDial = "+"+country.dialCode;
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget stateOTP() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: "We just sent a code to ",
                style: GoogleFonts.montserrat(
                  color: Colors.black87,
                  fontSize: 18,
                ),
              ),
              TextSpan(
                text: countryDial + phoneController.text,
                style: GoogleFonts.montserrat(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              TextSpan(
                text: "\nEnter the code here to finish logging in!",
                style: GoogleFonts.montserrat(
                  color: Colors.black87,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20,),
        PinCodeTextField(
          appContext: context,
          length: 6,
          onChanged: (value) {
            setState(() {
              otpPin = value;
            });
          },
          pinTheme: PinTheme(
            activeColor: blue,
            selectedColor: blue,
            inactiveColor: Colors.black26,
          ),
        ),
        const SizedBox(height: 20,),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "Didn't receive the code? ",
                style: GoogleFonts.montserrat(
                  color: Colors.black87,
                  fontSize: 12,
                ),
              ),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () {
                    setState(() {

                      screenState = 0;
                    });
                  },
                  child: Text(
                    "Resend",
                    style: GoogleFonts.montserrat(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget circle(double size) {
    return Container(
      height: screenHeight / size,
      width: screenHeight / size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
    );
  }
}
