import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:municipal_track/code/PDFViewer/pdf_api.dart';
import 'package:municipal_track/code/PDFViewer/view_pdf.dart';

import 'package:municipal_track/code/Reusable/icon_elevated_button.dart';


class UsersPdfListViewPage extends StatefulWidget {
  const UsersPdfListViewPage({Key? key}) : super(key: key);

  @override
  _UsersPdfListViewPageState createState() => _UsersPdfListViewPageState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

final User? user = auth.currentUser;
final uid = user?.uid;
final phone = user?.phoneNumber;
String userID = uid as String;
String userPhone = phone as String;

String locationGiven = ' ';

bool visibilityState1 = true;
bool visibilityState2 = false;

final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;

class FireStorageService extends ChangeNotifier{
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async{
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

class _UsersPdfListViewPageState extends State<UsersPdfListViewPage> {

  final CollectionReference _propList =
  FirebaseFirestore.instance.collection('properties');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Account Details'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder(
        stream: _propList.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              ///this call is to display all details for all users but is only displaying for the current user account.
              ///it can be changed to display all users for the staff to see if the role is set to all later on.
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                streamSnapshot.data!.docs[index];

                ///Check for only user information, this displays only for the users details and not all users in the database.
                if(streamSnapshot.data!.docs[index]['user id'] == userID) {
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'Property Data',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            Text(
                              'Account Number: ' + documentSnapshot['account number'],
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Street Address: ' + documentSnapshot['address'],
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Area Code: ' + documentSnapshot['area code'].toString(),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 20,),

                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            ElevatedIconButton(
                                              onPress: () async {
                                                Fluttertoast.showToast(
                                                    msg: "Now downloading your statement!\nPlease wait a few seconds!");

                                                ///code for loading the pdf is using dart:io I am setting it to use the userID to separate documents
                                                ///no pdfs are uploaded by users
                                                print(FirebaseAuth.instance.currentUser?.phoneNumber);
                                                String accountNumberPDF = documentSnapshot['account number'];
                                                String nameOfUserPdf;

                                                ///todo: make this find the name of documents by the property account number owned by the logged in user for their statement
                                                if (PDFApi.loadFirebase('pdfs/$userPhone/Invoice').toString().contains(accountNumberPDF)) {
                                                  nameOfUserPdf = PDFApi.loadFirebase('pdfs/$userPhone/').toString();

                                                  final url = nameOfUserPdf; //'pdfs/$userID/ds_wirelessp2p.pdf';
                                                  print(url);
                                                }

                                                final url2 = 'pdfs/$userPhone/Invoice_000003728743_040000653226.pdf';
                                                const url3 = 'pdfs/Invoice_000003728743_040000653226.PDF';
                                                final file = await PDFApi.loadFirebase(url3);
                                                try {
                                                  openPDF(context, file);
                                                } catch (e) {
                                                  Fluttertoast.showToast(msg: "Unable to download statement.");
                                                }
                                              },
                                              labelText: 'Statement',
                                              fSize: 16,
                                              faIcon: const FaIcon(Icons.picture_as_pdf),
                                              fgColor: Colors.orangeAccent,
                                              btSize: const Size(50, 50),
                                            ),

                                            const SizedBox(width: 5,),
                                          ],
                                        ),
                                      ],
                                    ),

                                  ],
                                ),
                              ],
                            ),
                          ]
                      ),
                    ),
                  );
                }///end of single user information display.
                else {
                  return Card();
                }
              },
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
  ///pdf view loader getting file name onPress/onTap that passes pdf filename to this class.
  void openPDF(BuildContext context, File file) => Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
  );
}