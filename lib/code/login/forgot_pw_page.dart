import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {

  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future passwordReset() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text.trim());
      if(context.mounted) {
        showDialog(context: context, builder: (context){
        return const AlertDialog(
          content: Text('Password reset link sent! Check your email to reset the password.',textAlign: TextAlign.center,),
        );
      });
      }
    } on FirebaseAuthException catch (e){
      print(e);
      if(context.mounted) {
        showDialog(context: context, builder: (context){
        return const AlertDialog(
          content: Text('The email you entered is not a registered member email. Register or try using a registered email.',textAlign: TextAlign.center,),
        );
      });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title:
        const Text('Password Reset'),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.all(25.0),
            child: Text('Enter your Email and we will send you a Password reset link',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20,),
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
                  borderSide: const BorderSide(color: Colors.deepPurpleAccent),
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Email',
                fillColor: Colors.grey[200],
                filled: true,
              ),
            ),
          ),
          const SizedBox(height: 20,),
          MaterialButton(
            onPressed: passwordReset,
            color: Colors.deepPurpleAccent,
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }
}
