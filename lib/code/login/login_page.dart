import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'forgot_pw_page.dart';

class LoginPage extends StatefulWidget{

  final VoidCallback showRegisterPage;

  const LoginPage({Key? key, required this.showRegisterPage }) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>{

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
      Navigator.of(context).pop();
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

    Navigator.of(context).pop();

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
                Image.asset('images/logo.png',height: 200,width: 300,),
                Text(
                  'Welcome!',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 50,
                  ),
                ),
                const SizedBox(height: 10,),
                const Text('Let\'s log in to manage your details.',
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

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: (){
                          Navigator.push(context,
                            MaterialPageRoute(builder: (context){
                              return ForgotPasswordPage();
                            },
                            ),
                          );
                        },
                        child: const Text('Forgot Password?',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),),
                      )
                    ],
                  ),
                ),
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Not a member?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.showRegisterPage,
                      child: const Text(
                        ' Register now',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}