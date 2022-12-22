import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

import '../ImageUploading/image_upload_page.dart';
import '../MapTools/map_screen.dart';
import '../PDFViewer/pdf_api.dart';
import '../PDFViewer/view_pdf.dart';
import '../MapTools/map_component.dart';


class UsersTableEditPage extends StatefulWidget {
  const UsersTableEditPage({Key? key}) : super(key: key);

  @override
  _UsersTableEditPageState createState() => _UsersTableEditPageState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

final User? user = auth.currentUser;
final uid = user?.uid;
String userID = uid as String;

String accountNumber = ' ';
String locationGiven = ' ';


final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;

class FireStorageService extends ChangeNotifier{
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async{
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

Future<Widget> _getImage(BuildContext context, String imageName) async{
  Image image;
  final value = await FireStorageService.loadImage(context, imageName);
  image =Image.network(
    value.toString(),
    fit: BoxFit.fill,
  );
  return image;
}

class _UsersTableEditPageState extends State<UsersTableEditPage> {

  // text fields' controllers
  final _accountNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaCodeController = TextEditingController();
  final _meterNumberController = TextEditingController();
  final _meterReadingController = TextEditingController();
  final _cellNumberController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idNumberController = TextEditingController();

  final _userIDController = userID;

  final CollectionReference _userList =
  FirebaseFirestore.instance.collection('users');

  Future<void> _create([DocumentSnapshot? documentSnapshot]) async {
    _accountNumberController.text = '';
    _addressController.text = '';
    _areaCodeController.text = '';
    _meterNumberController.text = '';
    _meterReadingController.text = '';
    _cellNumberController.text = '';
    _firstNameController.text = '';
    _lastNameController.text = '';
    _idNumberController.text = '';

    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery
                      .of(ctx)
                      .viewInsets
                      .bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _accountNumberController,
                    decoration: const InputDecoration(labelText: 'Account Number'),
                  ),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Street Address'),
                  ),
                  TextField(
                    keyboardType:
                    const TextInputType.numberWithOptions(),
                    controller: _areaCodeController,
                    decoration: const InputDecoration(labelText: 'Area Code',),
                  ),
                  TextField(
                    controller: _meterNumberController,
                    decoration: const InputDecoration(labelText: 'Meter Number'),
                  ),
                  TextField(
                    controller: _meterReadingController,
                    decoration: const InputDecoration(labelText: 'Meter Reading'),
                  ),
                  TextField(
                    controller: _cellNumberController,
                    decoration: const InputDecoration(labelText: 'Phone Number'),
                  ),
                  TextField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                  ),
                  TextField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                  ),
                  TextField(
                    controller: _idNumberController,
                    decoration: const InputDecoration(labelText: 'ID Number'),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    child: const Text('Create'),
                    onPressed: () async {
                      final String accountNumber = _accountNumberController.text;
                      final String address = _addressController.text;
                      final String areaCode = _areaCodeController.text;
                      final String meterNumber = _meterNumberController.text;
                      final String meterReading = _meterReadingController.text;
                      final String cellNumber = _cellNumberController.text;
                      final String firstName = _firstNameController.text;
                      final String lastName = _lastNameController.text;
                      final String idNumber = _idNumberController.text;
                      if (accountNumber != null) {
                        await _userList.add({
                          "account number": accountNumber,
                          "address": address,
                          "area code": areaCode,
                          "meter number": meterNumber,
                          "meter reading": meterReading,
                          "cell number": cellNumber,
                          "first name": firstName,
                          "last name": lastName,
                          "id number": idNumber
                        });
                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _areaCodeController.text = '';
                        _meterNumberController.text = '';
                        _meterReadingController.text = '';
                        _cellNumberController.text = '';
                        _firstNameController.text = '';
                        _lastNameController.text = '';
                        _idNumberController.text = '';

                        Navigator.of(context).pop();
                      }
                    },
                  )
                ],
              ),
            ),
          );
        });
  }

  /// on update the only info necessary to change should be meter reading
  Future<void> _update([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      _accountNumberController.text = documentSnapshot['account number'];
      _addressController.text = documentSnapshot['address'];
      _areaCodeController.text = documentSnapshot['area code'].toString();
      _meterNumberController.text = documentSnapshot['meter number'];
      _meterReadingController.text = documentSnapshot['meter reading'];
      _cellNumberController.text = documentSnapshot['cell number'];
      _firstNameController.text = documentSnapshot['first name'];
      _lastNameController.text = documentSnapshot['last name'];
      _idNumberController.text = documentSnapshot['id number'];
      userID = documentSnapshot['user id'];
    }
    /// on update the only info necessary to change should be meter reading bottom modal sheet to only specify that information but let all data stat the same
    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery
                      .of(ctx)
                      .viewInsets
                      .bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _accountNumberController,
                    decoration: const InputDecoration(labelText: 'Account Number'),
                  ),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Street Address'),
                  ),
                  TextField(
                    keyboardType:
                    const TextInputType.numberWithOptions(),
                    controller: _areaCodeController,
                    decoration: const InputDecoration(labelText: 'Area Code'),
                  ),
                  TextField(
                    controller: _meterNumberController,
                    decoration: const InputDecoration(labelText: 'Meter Number'),
                  ),
                  TextField(
                    controller: _meterReadingController,
                    decoration: const InputDecoration(labelText: 'Meter Reading'),
                  ),
                  TextField(
                    controller: _cellNumberController,
                    decoration: const InputDecoration(labelText: 'Phone Number'),
                  ),
                  TextField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                  ),
                  TextField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                  ),
                  TextField(
                    controller: _idNumberController,
                    decoration: const InputDecoration(labelText: 'ID Number'),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    child: const Text('Update'),
                    onPressed: () async {
                      final String accountNumber = _accountNumberController.text;
                      final String address = _addressController.text;
                      final int areaCode = int.parse(_areaCodeController.text);
                      final String meterNumber = _meterNumberController.text;
                      final String meterReading = _meterReadingController.text;
                      final String cellNumber = _cellNumberController.text;
                      final String firstName = _firstNameController.text;
                      final String lastName = _lastNameController.text;
                      final String idNumber = _idNumberController.text;

                      if (accountNumber != null) {
                        await _userList
                            .doc(documentSnapshot!.id)
                            .update({
                          "account number": accountNumber,
                          "address": address,
                          "area code": areaCode,
                          "meter number": meterNumber,
                          "meter reading": meterReading,
                          "cell number": cellNumber,
                          "first name": firstName,
                          "last name": lastName,
                          "id number": idNumber,
                          "user id" : userID,
                        });

                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _areaCodeController.text = '';
                        _meterNumberController.text = '';
                        _meterReadingController.text = '';
                        _cellNumberController.text = '';
                        _firstNameController.text = '';
                        _lastNameController.text = '';
                        _idNumberController.text = '';

                        Navigator.of(context).pop();
                      }
                    },
                  )
                ],
              ),
            ),
          );
        });
  }

  Future<void> _delete(String users) async {
    await _userList.doc(users).delete();

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have successfully deleted an account')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: Text('Municipal Accounts'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder(
        stream: _userList.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              ///this call is to display all details for all users but is only displaying for the current user account.
              ///it can be changed to display all users for the staff to see if the role is set to all later on.
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                streamSnapshot.data!.docs[index];

                String billMessage;///A check for if payment is outstanding or not
                if(documentSnapshot['eBill'] != ''){
                  billMessage = 'Utilities bill outstanding: '+documentSnapshot['eBill'];
                } else {
                  billMessage = 'No outstanding payments';
                }

                ///Check for only user information, this displays only for the users details and not all users in the database.
                if(streamSnapshot.data!.docs[index]['user id'] == userID){
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Number: ' + documentSnapshot['account number'],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'Street Address: ' + documentSnapshot['address'],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'Area Code: ' + documentSnapshot['area code'].toString(),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'Meter Number: ' + documentSnapshot['meter number'],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'Meter Reading: ' + documentSnapshot['meter reading'],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'Phone Number: ' + documentSnapshot['cell number'],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'First Name: ' + documentSnapshot['first name'],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'Surname: ' + documentSnapshot['last name'],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'ID Number: ' + documentSnapshot['id number'],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),

                          ///Image display item needs to get the reference from the firestore using the users uploaded meter connection
                          InkWell(
                            ///onTap allows to open image upload page if user taps on the image.
                            ///Can be later changed to display the picture zoomed in if user taps on it.
                            onTap: () {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text('Uploading a new image will replace current image!'),
                                ),
                              );
                              Navigator.push(context,
                                  MaterialPageRoute(
                                      builder: (context) => ImageUploads()));
                            },
                            child: Container(
                              margin: EdgeInsets.only(bottom: 5),
                              height: 180,
                              child: Center(
                                child: Card(
                                  color: Colors.blue,
                                  semanticContainer: true,
                                  clipBehavior: Clip.antiAliasWithSaveLayer,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  elevation: 0,
                                  margin: EdgeInsets.all(10.0),
                                  child: FutureBuilder(
                                      future: _getImage(
                                          context, 'files/$userID/file'),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasError) {
                                          return Text('${snapshot.error}');
                                        }
                                        if (snapshot.connectionState ==
                                            ConnectionState.done) {
                                          return Container(
                                            child: snapshot.data,
                                          );
                                        }
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Container(
                                            child: CircularProgressIndicator(),);
                                        }
                                        return Container();
                                      }
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 5,),
                          Text(
                            billMessage,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),

                          const SizedBox(height: 10,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  _update(documentSnapshot);
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      color: Theme
                                          .of(context)
                                          .primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6,),
                              GestureDetector(
                                onTap: () {
                                  accountNumber = documentSnapshot['account number'];
                                  locationGiven = documentSnapshot['address'];

                                  // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  //     content: Text('$accountNumber $locationGiven ')));

                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) => MapScreen()
                                          //MapPage()
                                      ));
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.map,
                                      color: Colors.green[700],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6,),
                              GestureDetector(
                                onTap: () async {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text('Now downloading your statement! Please wait a few seconds!'),
                                    ),
                                  );
                                  final FirebaseAuth auth = FirebaseAuth.instance;
                                  final User? user = auth.currentUser;
                                  final uid = user?.uid;
                                  String userID = uid as String;

                                  ///code for loading the pdf is using dart:io I am setting it to use the userID to separate documents
                                  ///no pdfs are uploaded by users
                                  print(FirebaseAuth.instance.currentUser);
                                  final url = 'pdfs/$userID/ds_wirelessp2p.pdf';
                                  final file = await PDFApi.loadFirebase(url);
                                  try{
                                    openPDF(context, file);
                                  } catch(e){
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      SnackBar(
                                        content: Text('Unable to download statement. Please connect to the internet!'),
                                      ),
                                    );
                                  }
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.picture_as_pdf,
                                      color: Colors.orange[200],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6,),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text('Uploading a new image will replace current image!'),
                                    ),
                                  );
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) => ImageUploads()));
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      color: Colors.grey[700],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6,),
                              // GestureDetector(
                              //   onTap: () {
                              //     _delete(documentSnapshot.id);
                              //   },
                              //   child: Row(
                              //     children: [
                              //       Icon(
                              //         Icons.delete,
                              //         color: Colors.red[700],
                              //       ),
                              //     ],
                              //   ),
                              // ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                }///end of single user information display.
                else {
                  ///this card is to display ALL details for all users when role is set.
                  return Card();//(
                  //   margin: const EdgeInsets.all(10),
                  //   child: Padding(
                  //     padding: const EdgeInsets.all(20.0),
                  //     child: Column(
                  //       mainAxisAlignment: MainAxisAlignment.center,
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         Text(
                  //           'Account Number: ' +
                  //               documentSnapshot['account number'],
                  //           style: TextStyle(
                  //               fontSize: 16, fontWeight: FontWeight.w400),
                  //         ),
                  //         const SizedBox(height: 5,),
                  //         Text(
                  //           'Street Address: ' + documentSnapshot['address'],
                  //           style: TextStyle(
                  //               fontSize: 16, fontWeight: FontWeight.w400),
                  //         ),
                  //         const SizedBox(height: 5,),
                  //         Text(
                  //           'Area Code: ' +
                  //               documentSnapshot['area code'].toString(),
                  //           style: TextStyle(
                  //               fontSize: 16, fontWeight: FontWeight.w400),
                  //         ),
                  //         const SizedBox(height: 5,),
                  //         Text(
                  //           'Meter Number: ' + documentSnapshot['meter number'],
                  //           style: TextStyle(
                  //               fontSize: 16, fontWeight: FontWeight.w400),
                  //         ),
                  //         const SizedBox(height: 5,),
                  //         Text(
                  //           'Phone Number: ' + documentSnapshot['cell number'],
                  //           style: TextStyle(
                  //               fontSize: 16, fontWeight: FontWeight.w400),
                  //         ),
                  //         const SizedBox(height: 5,),
                  //         Text(
                  //           'First Name: ' + documentSnapshot['first name'],
                  //           style: TextStyle(
                  //               fontSize: 16, fontWeight: FontWeight.w400),
                  //         ),
                  //         const SizedBox(height: 5,),
                  //         Text(
                  //           'Surname: ' + documentSnapshot['last name'],
                  //           style: TextStyle(
                  //               fontSize: 16, fontWeight: FontWeight.w400),
                  //         ),
                  //         const SizedBox(height: 5,),
                  //         Text(
                  //           'ID Number: ' + documentSnapshot['id number'],
                  //           style: TextStyle(
                  //               fontSize: 16, fontWeight: FontWeight.w400),
                  //         ),
                  //         const SizedBox(height: 5,),
                  //
                  //         ///Image display item needs to get the reference from the firestore using the users uploaded meter connection
                  //         InkWell(
                  //           onTap: () {
                  //             ScaffoldMessenger.of(this.context).showSnackBar(
                  //               SnackBar(
                  //                 content: Text(
                  //                     'Uploading a new image will replace current image!'),
                  //               ),
                  //             );
                  //             Navigator.push(context,
                  //                 MaterialPageRoute(
                  //                     builder: (context) => ImageUploads()));
                  //           },
                  //           child: Container(
                  //             margin: EdgeInsets.only(bottom: 5),
                  //             height: 180,
                  //             child: Center(
                  //               child: Card(
                  //                 color: Colors.blue,
                  //                 semanticContainer: true,
                  //                 clipBehavior: Clip.antiAliasWithSaveLayer,
                  //                 shape: RoundedRectangleBorder(
                  //                   borderRadius: BorderRadius.circular(10.0),
                  //                 ),
                  //                 elevation: 0,
                  //                 margin: EdgeInsets.all(10.0),
                  //                 child: FutureBuilder(
                  //                     future: _getImage(
                  //                         context, 'files/$userID/file'),
                  //                     builder: (context, snapshot) {
                  //                       if (snapshot.hasError) {
                  //                         return Text('${snapshot.error}');
                  //                       }
                  //                       if (snapshot.connectionState ==
                  //                           ConnectionState.done) {
                  //                         return Container(
                  //                           child: snapshot.data,
                  //                         );
                  //                       }
                  //                       if (snapshot.connectionState ==
                  //                           ConnectionState.waiting) {
                  //                         return Container(
                  //                           child: CircularProgressIndicator(),);
                  //                       }
                  //                       return Container();
                  //                     }
                  //                 ),
                  //               ),
                  //             ),
                  //           ),
                  //         ),
                  //
                  //         const SizedBox(height: 10,),
                  //         Row(
                  //           mainAxisAlignment: MainAxisAlignment.end,
                  //           crossAxisAlignment: CrossAxisAlignment.center,
                  //           children: [
                  //             GestureDetector(
                  //               onTap: () {
                  //                 _update(documentSnapshot);
                  //               },
                  //               child: Row(
                  //                 children: [
                  //                   Icon(
                  //                     Icons.edit,
                  //                     color: Theme
                  //                         .of(context)
                  //                         .primaryColor,
                  //                   ),
                  //                 ],
                  //               ),
                  //             ),
                  //             const SizedBox(width: 6,),
                  //             GestureDetector(
                  //               onTap: () {
                  //                 Navigator.push(context,
                  //                     MaterialPageRoute(
                  //                         builder: (context) => MapPage()));
                  //               },
                  //               child: Row(
                  //                 children: [
                  //                   Icon(
                  //                     Icons.map,
                  //                     color: Colors.green[700],
                  //                   ),
                  //                 ],
                  //               ),
                  //             ),
                  //             const SizedBox(width: 6,),
                  //             GestureDetector(
                  //               onTap: () {
                  //                 ScaffoldMessenger.of(this.context)
                  //                     .showSnackBar(
                  //                   SnackBar(
                  //                     content: Text(
                  //                         'Uploading a new image will replace current image!'),
                  //                   ),
                  //                 );
                  //                 Navigator.push(context,
                  //                     MaterialPageRoute(
                  //                         builder: (context) =>
                  //                             ImageUploads()));
                  //               },
                  //               child: Row(
                  //                 children: [
                  //                   Icon(
                  //                     Icons.camera_alt,
                  //                     color: Colors.grey[700],
                  //                   ),
                  //                 ],
                  //               ),
                  //             ),
                  //             const SizedBox(width: 6,),
                  //             // GestureDetector(
                  //             //   onTap: () {
                  //             //     _delete(documentSnapshot.id);
                  //             //   },
                  //             //   child: Row(
                  //             //     children: [
                  //             //       Icon(
                  //             //         Icons.delete,
                  //             //         color: Colors.red[700],
                  //             //       ),
                  //             //     ],
                  //             //   ),
                  //             // ),
                  //           ],
                  //         )
                  //       ],
                  //     ),
                  //   ),
                  // );
                }
              },
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),

      /// Add new account, removed because it was not necessary for non-staff users.
      //   floatingActionButton: FloatingActionButton(
      //     onPressed: () => _create(),
      //     child: const Icon(Icons.add),
      //   ),
      //   floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat

    );
  }
  ///pdf view loader getting file name onPress/onTap that passes pdf filename to this class.
  void openPDF(BuildContext context, File file) => Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
  );
}