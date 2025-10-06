import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';


class AddPropertyDetails extends StatefulWidget {
  const AddPropertyDetails({super.key,});

  @override
  State<AddPropertyDetails> createState() => _AddPropertyDetailsState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final User? user = auth.currentUser;
final uid = user?.uid;
String userID = uid as String;

class _AddPropertyDetailsState extends State<AddPropertyDetails> {
  final _firstNameController = TextEditingController();
  final _secondNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaCodeController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _meterNumberController = TextEditingController();
  final _meterReadingController = TextEditingController();
  final _waterMeterController = TextEditingController();
  final _waterMeterReadingController = TextEditingController();
  final _cellNumberController = TextEditingController();
  final  _wardController = TextEditingController();
  final _districtIdController=TextEditingController();
  final _municipalityIDController=TextEditingController();
  final _electricityAccountNumberController=TextEditingController();
  final _userIDController = userID;

  @override
  void dispose() {
    _firstNameController.dispose();
    _secondNameController.dispose();
    _addressController.dispose();
    _areaCodeController.dispose();
    _idNumberController.dispose();
    _accountNumberController.dispose();
    _meterNumberController.dispose();
    _meterReadingController.dispose();
    _waterMeterController.dispose();
    _waterMeterReadingController.dispose();
    _cellNumberController.dispose();
    _districtIdController.dispose();
    _municipalityIDController.dispose();
    super.dispose();
  }

  Future dataAdd() async {
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

    if (fieldsNotEmptyConfirmed()) {
      await addPropertyDetails(
        _firstNameController.text.trim(),
        _secondNameController.text.trim(),
        _cellNumberController.text.trim(),
        _addressController.text.trim(),
        int.parse(_areaCodeController.text.trim()),
        _idNumberController.text.trim(),
        _accountNumberController.text.trim(),
        _meterNumberController.text.trim(),
        _meterReadingController.text.trim(),
        _waterMeterController.text.trim(),
        _waterMeterReadingController.text.trim(),
        _wardController.text.trim(),
        _districtIdController.text.trim(),
        _municipalityIDController.text.trim(),
        _electricityAccountNumberController.text.trim(),
        _userIDController,
      );

      if (context.mounted) Navigator.of(context).pop();
    } else {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please make sure all fields are filled!'),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20.0),
        duration: Duration(seconds: 5),
      ));
    }
  }

  bool fieldsNotEmptyConfirmed(){
    if (_areaCodeController.text.isNotEmpty && _firstNameController.text.isNotEmpty && _secondNameController.text.isNotEmpty && _cellNumberController.text.isNotEmpty &&
        _addressController.text.isNotEmpty && _areaCodeController.text.isNotEmpty && _idNumberController.text.isNotEmpty && _accountNumberController.text.isNotEmpty &&
       _districtIdController.text.isNotEmpty&&_municipalityIDController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Details are now being saved!'),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20.0),
        duration: Duration(seconds: 5),
      ));
      return true;
    } else {
      return false;
    }
  }

  Future<void> addPropertyDetails(String firstName, String lastName, String cellNumber,  String address, int areaCode, String idNumber, String accountNumber,String electricityAccountNumber,String meterNumber,String meterReading,  String waterMeterNumber, String waterMeterReading, String userid,String ward,String districtId,String municipalityId) async {
    try {
      await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('properties')
          .add({
        'firstName': firstName,
        'lastName': lastName,
        'cellNumber': cellNumber,
        'address': address,
        'districtId': districtId,
        'municipalityId': municipalityId,
        'areaCode': areaCode,
        'idNumber': idNumber,
        'accountNumber': accountNumber,
        'electricityAccountNumber':electricityAccountNumber,
        'meter_number': meterNumber,
        'meter_reading': meterReading,
        'water_meter_number': waterMeterNumber,
        'water_meter_reading': waterMeterReading,
        'ward':ward,
        'userId': userid,
      });

      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      print('Failed to add property: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to add property. Please try again.'),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20.0),
        duration: Duration(seconds: 5),
      ));
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
                const SizedBox(height: 20,),
                Text(
                  'Hello There',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 50,
                  ),
                ),
                const SizedBox(height: 10,),
                const Text('Enter all details bellow!',
                  style: TextStyle(fontSize: 18),),
                const SizedBox(height: 40,),

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
                      hintText: 'Street Address',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                ),

                const SizedBox(height: 10,),

                Padding(
                  padding:  const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextFormField(
                    controller: _areaCodeController,
                    inputFormatters: <TextInputFormatter>[ FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Area Code',

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
                      hintText: 'ID Number',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                ),

                const SizedBox(height: 10,),

                Padding(
                  padding:  const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: _accountNumberController,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Account Number',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                ),


                const SizedBox(height: 10,),

                // Padding(
                //   padding:  const EdgeInsets.symmetric(horizontal: 25.0),
                //   child: TextField(
                //     controller: _meterNumberController,
                //     decoration: InputDecoration(
                //       enabledBorder: OutlineInputBorder(
                //         borderSide: const BorderSide(color: Colors.white),
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //       focusedBorder: OutlineInputBorder(
                //         borderSide: const BorderSide(color: Colors.green),
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //       hintText: 'Meter Number',
                //       fillColor: Colors.grey[200],
                //       filled: true,
                //     ),
                //   ),
                // ),
                //
                // const SizedBox(height: 10,),

                // Padding(
                //   padding:  const EdgeInsets.symmetric(horizontal: 25.0),
                //   child: TextField(
                //     controller: _meterReadingController,
                //     decoration: InputDecoration(
                //       enabledBorder: OutlineInputBorder(
                //         borderSide: const BorderSide(color: Colors.white),
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //       focusedBorder: OutlineInputBorder(
                //         borderSide: const BorderSide(color: Colors.green),
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //       hintText: 'Meter Reading',
                //       fillColor: Colors.grey[200],
                //       filled: true,
                //     ),
                //   ),
                // ),
                //
                // const SizedBox(height: 10,),

                Padding(
                  padding:  const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: _waterMeterController,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Water Meter Number',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                ),

                const SizedBox(height: 10,),

                Padding(
                  padding:  const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: _waterMeterReadingController,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Water Meter Reading',
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
                    controller: _wardController,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Ward Number',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(height: 10,),

                Padding(
                  padding:  const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: _wardController,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'District',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(height: 10,),

                Padding(
                  padding:  const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: _wardController,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Municipality',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                ),
                // login button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: GestureDetector(
                    onTap: dataAdd,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Add Details!',
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

class LocationAutoComp extends StatefulWidget {
  const LocationAutoComp({Key? key, required this.title, required this.onPressed}) : super(key: key);

  final String title;
  final VoidCallback onPressed;

  @override
  _LocationAutoComp createState() => _LocationAutoComp();
}

class _LocationAutoComp extends State<LocationAutoComp> {
  var _controller = TextEditingController();
  var uuid = new Uuid();
  late String _sessionToken;
  List<dynamic> _placeList = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      _onChanged();
    });
  }

  _onChanged() {
    if (_sessionToken == null) {
      setState(() {
        _sessionToken = uuid.v4();
      });
    }
    getSuggestion(_controller.text);
  }

  void getSuggestion(String input) async {
    // No Google Places on web → don't call the /place/autocomplete endpoint.
    if (kIsWeb) {
      if (!mounted) return;
      setState(() => _placeList = []); // show no suggestions on web
      return;
    }

    // --- Mobile path (Android/iOS) ---
    // NOTE: This still hits the legacy Places Web Service endpoint.
    // If Places API is disabled for the whole project, this will fail on mobile too.
    // Keep only if you plan to enable Places for mobile or proxy via your server.
    const String kPLACES_API_KEY = "YOUR_MOBILE_PLACES_KEY"; // move to secure config/env
    final String baseURL = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';

    // If you use session tokens, ensure _sessionToken is set (e.g., when the user focuses the field).
    final String sessionToken = _sessionToken ?? '';

    final uri = Uri.parse(
        '$baseURL?input=$input'
            '&key=$kPLACES_API_KEY'
            '&sessiontoken=$sessionToken'
            '&components=country:za' // optional: keep results in South Africa
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (!mounted) return;
      setState(() {
        _placeList = List.from(body['predictions'] ?? []);
      });
    } else {
      throw Exception('Failed to load predictions: ${response.body}');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Align(
              alignment: Alignment.topCenter,
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: "Seek your location here",
                  focusColor: Colors.white,
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  prefixIcon: Icon(Icons.map),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.cancel), onPressed: () {  },
                  ),
                ),
              ),
            ),
            ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _placeList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_placeList[index]["description"]),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}