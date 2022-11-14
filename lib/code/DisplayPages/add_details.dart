import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AddUserDetails extends StatefulWidget {
  const AddUserDetails({Key? key}) : super(key: key);

  @override
  State<AddUserDetails> createState() => _AddUserDetailsState();
}

class _AddUserDetailsState extends State<AddUserDetails> {

  final _firstNameController = TextEditingController();
  final _secondNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _wardNumberController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _cellNumberController = TextEditingController();
  final _areaCodeController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _secondNameController.dispose();
    _addressController.dispose();
    _wardNumberController.dispose();
    _idNumberController.dispose();
    _cellNumberController.dispose();
    _areaCodeController.dispose();
    super.dispose();
  }

  Future signUp() async {
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

    addUserDetails(
      _firstNameController.text.trim(),
      _secondNameController.text.trim(),
      _addressController.text.trim(),
      int.parse(_wardNumberController.text.trim()),
      int.parse(_idNumberController.text.trim()),
      int.parse(_cellNumberController.text.trim()),
    );


    Navigator.of(context).pop();
  }

  bool numberFieldsConfirmed(){
    if (_areaCodeController == int && _wardNumberController == int && _idNumberController == int && _cellNumberController == int){
      return false;
    } else {
      return false;
    }
  }

  Future addUserDetails(String firstName, String lastName, String address, int ward, int idNumber, int cellNumber ) async{

    if(numberFieldsConfirmed() == false){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please make sure the entered Area code, Ward, ID and your Cell are numbers'),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20.0),
        duration: Duration(seconds: 5),
      ));
      Navigator.of(context).pop();
    } else {
      await FirebaseFirestore.instance.collection('users').add({
        'first name': firstName,
        'last name': lastName,
        'address' : address,
        'ward': ward,
        'id number': idNumber,
        'cell number': cellNumber,

      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Details are now being saved!'),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20.0),
        duration: Duration(seconds: 5),
      ));
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
                Text(
                  'Hello There',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 50,
                  ),
                ),
                const SizedBox(height: 10,),
                const Text('Enter your details bellow!',
                  style: TextStyle(fontSize: 18),),
                const SizedBox(height: 50,),

                Padding(
                  padding:  const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'First Name',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                ),

                const SizedBox(height: 10,),

                Padding(
                  padding:  const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: _secondNameController,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Last Name',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                ),

                const SizedBox(height: 10,),

                Padding(
                  padding:  const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Cellphone Number',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                ),

                const SizedBox(height: 10,),

                Padding(
                  padding:  const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: _wardNumberController,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Street Address',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                ),

                const SizedBox(height: 10,),

                Padding(
                  padding:  const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: _idNumberController,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Neighbourhood',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                ),

                const SizedBox(height: 10,),

                Padding(
                  padding:  const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: _cellNumberController,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'City',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                ),


                const SizedBox(height: 10,),

                Padding(
                  padding:  const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: _areaCodeController,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Postal Code',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                ),

                const SizedBox(height: 10,),


                // login button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: GestureDetector(
                    onTap: signUp,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Save Details!',
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


//
// class RegisterPage extends StatefulWidget {
//   final VoidCallback showLoginPage;
//   const RegisterPage({Key? key, required this.showLoginPage,}) : super(key: key);
//
//   @override
//   State<RegisterPage> createState() => _RegisterPageState();
// }
//
// class _RegisterPageState extends State<RegisterPage> {
//
//   final _emailController = TextEditingController();
//   final _firstNameController = TextEditingController();
//   final _secondNameController = TextEditingController();
//   final _cellNumberController = TextEditingController();
//   final _streetController = TextEditingController();
//   final _areaController = TextEditingController();
//   final _cityController = TextEditingController();
//   final _provinceController = TextEditingController();
//   final _countryController = TextEditingController();
//   final _areaCodeController = TextEditingController();
//   final _wardNumberController = TextEditingController();
//   final _idNumberController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     _firstNameController.dispose();
//     _secondNameController.dispose();
//     _cellNumberController.dispose();
//     _streetController.dispose();
//     _areaController.dispose();
//     _cityController.dispose();
//     _provinceController.dispose();
//     _countryController.dispose();
//     _areaCodeController.dispose();
//     _wardNumberController.dispose();
//     _idNumberController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }
//
//   Future signUp() async {
//     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//       content: Text('Please enter correct email and password'),
//       behavior: SnackBarBehavior.floating,
//       margin: EdgeInsets.all(20.0),
//       duration: Duration(seconds: 5),
//     ));
//
//     showDialog(
//       context: context,
//       builder: (context){
//         return const Center(child: CircularProgressIndicator());
//       },
//     );
//
//     if (passwordConfirmed() == true) {
//       await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//       );
//       Navigator.of(context).pop();
//
//     } else if (passwordConfirmed() == false){
//       Navigator.of(context).pop();
//
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//         content: Text('Passwords entered do not match'),
//         behavior: SnackBarBehavior.floating,
//         margin: EdgeInsets.all(20.0),
//       ));
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//         content: Text('Please fill in all details'),
//         behavior: SnackBarBehavior.floating,
//         margin: EdgeInsets.all(20.0),
//       ));
//       Navigator.of(context).pop();
//
//     }
//
//     addUserDetails(
//       _firstNameController.text.trim(),
//       _secondNameController.text.trim(),
//       _streetController.text.trim(),
//       _areaController.text.trim(),
//       _cityController.text.trim(),
//       _provinceController.text.trim(),
//       _countryController.text.trim(),
//       int.parse(_areaCodeController.text.trim()),
//       int.parse(_wardNumberController.text.trim()),
//       int.parse(_idNumberController.text.trim()),
//       int.parse(_cellNumberController.text.trim()),
//     );
//
//
//     Navigator.of(context).pop();
//   }
//
//   bool numberFieldsConfirmed(){
//     if (_areaCodeController == int && _wardNumberController == int && _idNumberController == int && _cellNumberController == int){
//       return true;
//     } else {
//       return false;
//     }
//   }
//
//   Future addUserDetails(String firstName, String lastName, String streetAddress, String areaAddress, String city, String province, String country,
//       int areaCode, int ward, int idNumber, int cellNumber ) async{
//
//     if(numberFieldsConfirmed() == false){
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//         content: Text('Please make sure the entered Area code, Ward, ID and your Cell are numbers'),
//         behavior: SnackBarBehavior.floating,
//         margin: EdgeInsets.all(20.0),
//       ));
//     } else {
//       await FirebaseFirestore.instance.collection('users').add({
//         'first name': firstName,
//         'last name': lastName,
//         'cell number': cellNumber,
//         'address street name': streetAddress,
//         'address area': areaAddress,
//         'city': city,
//         'province': province,
//         'country': country,
//         'area code': areaCode,
//         'ward': ward,
//         'id number': idNumber,
//
//       });
//     }
//   }
//
//   bool passwordConfirmed(){
//     if (_passwordController.text.trim() == _confirmPasswordController.text.trim()){
//       return true;
//     } else {
//       return false;
//     }
//   }
//
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[300],
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             child: Column(
//
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 //Image.asset('images/MainMenu/logo.png',height: 200,width: 300,),
//                 Text(
//                   'Hello There',
//                   style: GoogleFonts.bebasNeue(
//                     fontSize: 50,
//                   ),
//                 ),
//                 const SizedBox(height: 10,),
//                 const Text('Register below with your details!',
//                   style: TextStyle(fontSize: 18),),
//                 const SizedBox(height: 50,),
//
//                 // email textfield
//                 Padding(
//                   padding:  const EdgeInsets.symmetric(horizontal: 25.0),
//                   child: TextField(
//                     controller: _emailController,
//                     decoration: InputDecoration(
//                       enabledBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.white),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.deepPurpleAccent),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       hintText: 'Email',
//                       fillColor: Colors.grey[200],
//                       filled: true,
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 10,),
//
//                 Padding(
//                   padding:  const EdgeInsets.symmetric(horizontal: 25.0),
//                   child: TextField(
//                     controller: _firstNameController,
//                     decoration: InputDecoration(
//                       enabledBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.white),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.deepPurpleAccent),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       hintText: 'First Name',
//                       fillColor: Colors.grey[200],
//                       filled: true,
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 10,),
//
//                 Padding(
//                   padding:  const EdgeInsets.symmetric(horizontal: 25.0),
//                   child: TextField(
//                     controller: _secondNameController,
//                     decoration: InputDecoration(
//                       enabledBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.white),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.deepPurpleAccent),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       hintText: 'Second Name',
//                       fillColor: Colors.grey[200],
//                       filled: true,
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 10,),
//
//                 Padding(
//                   padding:  const EdgeInsets.symmetric(horizontal: 25.0),
//                   child: TextField(
//                     controller: _cellNumberController,
//                     decoration: InputDecoration(
//                       enabledBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.white),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.deepPurpleAccent),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       hintText: 'Cellphone Number',
//                       fillColor: Colors.grey[200],
//                       filled: true,
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 10,),
//
//                 Padding(
//                   padding:  const EdgeInsets.symmetric(horizontal: 25.0),
//                   child: TextField(
//                     controller: _streetController,
//                     decoration: InputDecoration(
//                       enabledBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.white),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.deepPurpleAccent),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       hintText: 'Street Address',
//                       fillColor: Colors.grey[200],
//                       filled: true,
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 10,),
//
//                 Padding(
//                   padding:  const EdgeInsets.symmetric(horizontal: 25.0),
//                   child: TextField(
//                     controller: _areaController,
//                     decoration: InputDecoration(
//                       enabledBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.white),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.deepPurpleAccent),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       hintText: 'Neighbourhood',
//                       fillColor: Colors.grey[200],
//                       filled: true,
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 10,),
//
//                 Padding(
//                   padding:  const EdgeInsets.symmetric(horizontal: 25.0),
//                   child: TextField(
//                     controller: _cityController,
//                     decoration: InputDecoration(
//                       enabledBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.white),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.deepPurpleAccent),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       hintText: 'City',
//                       fillColor: Colors.grey[200],
//                       filled: true,
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 10,),
//
//                 Padding(
//                   padding:  const EdgeInsets.symmetric(horizontal: 25.0),
//                   child: TextField(
//                     controller: _provinceController,
//                     decoration: InputDecoration(
//                       enabledBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.white),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.deepPurpleAccent),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       hintText: 'Province',
//                       fillColor: Colors.grey[200],
//                       filled: true,
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 10,),
//
//                 Padding(
//                   padding:  const EdgeInsets.symmetric(horizontal: 25.0),
//                   child: TextField(
//                     controller: _countryController,
//                     decoration: InputDecoration(
//                       enabledBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.white),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.deepPurpleAccent),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       hintText: 'Country',
//                       fillColor: Colors.grey[200],
//                       filled: true,
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 10,),
//
//                 Padding(
//                   padding:  const EdgeInsets.symmetric(horizontal: 25.0),
//                   child: TextField(
//                     controller: _areaCodeController,
//                     decoration: InputDecoration(
//                       enabledBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.white),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.deepPurpleAccent),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       hintText: 'Postal Code',
//                       fillColor: Colors.grey[200],
//                       filled: true,
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 10,),
//
//                 // password textfield
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 25.0),
//                   child: TextField(
//                     controller: _passwordController,
//                     obscureText: true,
//                     decoration: InputDecoration(
//                       enabledBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.white),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.deepPurpleAccent),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       hintText: 'Password',
//                       fillColor: Colors.grey[200],
//                       filled: true,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 10,),
//
//                 // confirm password textfield
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 25.0),
//                   child: TextField(
//                     controller: _confirmPasswordController,
//                     obscureText: true,
//                     decoration: InputDecoration(
//                       enabledBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.white),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderSide: const BorderSide(color: Colors.deepPurpleAccent),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       hintText: 'Confirm Password',
//                       fillColor: Colors.grey[200],
//                       filled: true,
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 10,),
//
//                 // login button
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 25.0),
//                   child: GestureDetector(
//                     onTap: signUp,
//                     child: Container(
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         color: Colors.deepPurpleAccent,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: const Center(
//                         child: Text(
//                           'Sign Up',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 18,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 25,),
//
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text(
//                       'Already a member?',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     GestureDetector(
//                       onTap: widget.showLoginPage,
//                       child: const Text(
//                         ' Log in!',
//                         style: TextStyle(
//                           color: Colors.blue,
//                           fontWeight: FontWeight.bold,
//                         ),),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
