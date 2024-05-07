import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:municipal_services/code/DisplayPages/dashboard.dart';
import 'package:municipal_services/code/login/login_page.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:url_launcher/url_launcher.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  TextEditingController fullNameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  double screenHeight = 0;
  double screenWidth = 0;
  double bottom = 0;
  double change = 2;
  double topText = 12;
  double botText = 23;

  String otpPin = " ";
  String countryDial = "+27";
  String verID = " ";

  int screenState = 0;

  Color blue = const Color(0xff8cccff);

  @override
  initState(){
    super.initState();
    checkText();
  }

  void checkText() {
    if(defaultTargetPlatform == TargetPlatform.android){
      topText = 12;
      botText = 23;
    }else{
      topText = 20;
      botText = 40;
    }
  }

  Future<void> verifyPhone(String number) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: number,
      timeout: const Duration(seconds: 20),
      verificationCompleted: (PhoneAuthCredential credential) {
        showSnackBarText("Auth Completed!");
      },
      verificationFailed: (FirebaseAuthException e) {
        print('error is ::: $e');
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
                      "You have reached your OTP request limit of 5. Beyond 5 requests is seen as a security threat to the system. Wait 4 hours until it is reset!\n\nAlternatively make sure you have internet access on your phone!\n\nWould you like to contact the municipality for assistance with this error?"),
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
        showSnackBarText("Awaiting OTP!");
      },
    );
  }

  Future<void> verifyOTP() async {
    await FirebaseAuth.instance.signInWithCredential(
      PhoneAuthProvider.credential(
        verificationId: verID,
        smsCode: otpPin,
      ),
    ).whenComplete(() {

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainMenu(),
        ),
      );
    });
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
        resizeToAvoidBottomInset: false,
        body: SizedBox(
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
                        const SizedBox(height: 30),
                        Text(
                          "MANAGE DETAILS",
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth / topText,
                          ),
                        ),
                        Text(
                          "Sign in with mobile number!",
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.w500 ,
                            fontSize: screenWidth / botText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              cloudDesign(),
              // Align(
              //   alignment: Alignment.centerLeft,
              //   child: circle(5),
              // ),
              // Transform.translate(
              //   offset: const Offset(30, -30),
              //   child: Align(
              //     alignment: Alignment.centerRight,
              //     child: circle(4.5),
              //   ),
              // ),
              // Center(
              //   child: circle(3),
              // ),
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  height: bottom > 0 ? screenHeight : screenHeight / change,
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

                              // if(fullNameController.text.isEmpty) {
                              //   showSnackBarText("Full Name is still empty!");
                              //
                              // } else
                              if(phoneController.text.isEmpty) {
                                  showSnackBarText("Phone number is still empty!");
                              } else {
                                  showSnackBarText("Now verifying your phone number!");
                                  verifyPhone(countryDial + phoneController.text);
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
                        const SizedBox(height: 5,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Municipality Member?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap:() {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) =>
                                        const LoginPage()));
                              },
                              child: const Text(
                                ' Login Here',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20,),
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
        //   "Full Name",
        //   style: GoogleFonts.montserrat(
        //     color: Colors.black87,
        //     fontWeight: FontWeight.bold,
        //   ),
        // ),
        // const SizedBox(height: 8,),
        // TextFormField(
        //   controller: fullNameController,
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
          autofocus: false,
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

  Widget cloudDesign(){
    if(defaultTargetPlatform == TargetPlatform.android){
      return Column(
        children: [
          Transform.translate(
            offset: const Offset(0, 390),
            child: Align(
              alignment: Alignment.centerLeft,
              child: circle(5),
            ),
          ),
          Transform.translate(
            offset: const Offset(30, 190),
            child: Align(
              alignment: Alignment.centerRight,
              child: circle(4.5),
            ),
          ),
          Transform.translate(
            offset: const Offset(10,20),
            child: Center(
              child: circle(3),
            ),
          ),
        ],
      );
    }else{
      return Column();
    }
  }

}
