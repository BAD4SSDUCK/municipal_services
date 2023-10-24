import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:municipal_tracker_msunduzi/code/AuthGoogle/auth_page_google.dart';

import 'forgot_pw_page.dart';

///Copied design from LoginPage and trimmed to have one login button that grabs users gamil account tried to their playstore

class LoginPageG extends StatefulWidget{

  const LoginPageG({Key? key, }) : super(key: key);

  @override
  State<LoginPageG> createState() => _LoginPageGState();
}

class _LoginPageGState extends State<LoginPageG>{

  // text controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future signIn() async{
    //loading circle
    showDialog(
      context: context,
      builder: (context){
        return const Center(child: CircularProgressIndicator());
      },
    );
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if(context.mounted)Navigator.of(context).pop();
      switch (e.code) {
        case "invalid-email":
        //Thrown if the email address is not valid.
          throw const AlertDialog(
            content: Text('invalid-email',textAlign: TextAlign.center,),
          );
        case "user-disabled":
        //Thrown if the user corresponding to the given email has been disabled.
          throw const AlertDialog(
            content: Text('User account Disabled',textAlign: TextAlign.center,),
          );
        case "user-not-found":
        //Thrown if there is no user corresponding to the given email.
          throw const AlertDialog(
            content: Text('User account not found',textAlign: TextAlign.center,),
          );
        case "wrong-password":
          throw const AlertDialog(
            content: Text('User Password is incorrect',textAlign: TextAlign.center,),
          );
      //Thrown if the password is invalid for the given email, or the account corresponding to the email does not have a password set.
        default:
          throw const AlertDialog(
            content: Text('An unknown error has occurred',textAlign: TextAlign.center,),
          );
      }
    }

    if(context.mounted)Navigator.of(context).pop();

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
                Image.asset('images/MainMenu/logo.png',height: 200,width: 300,),
                Text(
                  'Hello New Drivers',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 50,
                  ),
                ),
                const SizedBox(height: 10,),
                const Text('Welcome, let\'s log in to learn the K53!',
                  style: TextStyle(fontSize: 18),),
                const SizedBox(height: 50,),


                const SizedBox(height: 10,),


                const SizedBox(height: 10,),


                const SizedBox(height: 10,),

                // login button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: GestureDetector(
                    onTap: (){
                      AuthService().signInWithGoogle();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.deepOrangeAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Sign In',
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