import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

class AdminDetails extends StatefulWidget{

  @override
  State<AdminDetails> createState() => _AdminDetailsState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

final User? user = auth.currentUser;
final uid = user?.uid;
String userID = uid as String;

final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;

class FireStorageService extends ChangeNotifier{
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async{
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

class _AdminDetailsState extends State<AdminDetails> {

  //text fields' controllers
  final _userNameController = TextEditingController();
  final _userRollController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _userEmailController = TextEditingController();
  final _cellNumberController = TextEditingController();

  final CollectionReference _usersList =
  FirebaseFirestore.instance.collection('users');

  String userPass = '';
  String addressPass = '';

  bool visShow = true;
  bool visHide = false;

  //this widget is for displaying a user information with an icon next to it, NB. the icon is to make it look good
  Widget adminUserField(String propertyDat) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8,),
      child: Row(
        children: [
          const SizedBox(width: 6,),
          Text(
            propertyDat,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _create([DocumentSnapshot? documentSnapshot]) async {
    _userNameController.text = '';
    _userRollController.text = '';
    _firstNameController.text = '';
    _lastNameController.text = '';
    _userEmailController.text = '';
    _cellNumberController.text = '';

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
                      .bottom + 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _userNameController,
                      decoration: const InputDecoration(
                          labelText: 'User Name'),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _userRollController,
                      decoration: const InputDecoration(
                          labelText: 'User Roll'),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                          labelText: 'First Name'),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                          labelText: 'Last Name'),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _userEmailController,
                      decoration: const InputDecoration(
                          labelText: 'User Email'),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _cellNumberController,
                      decoration: const InputDecoration(
                          labelText: 'Phone Number'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                      child: const Text('Create'),
                      onPressed: () async {
                        final String userName = _userNameController.text;
                        final String userRoll = _userRollController.text;
                        final String firstName = _firstNameController.text;
                        final String lastName = _lastNameController.text;
                        final String email = _userEmailController.text;
                        final String cellNumber = _cellNumberController.text;
                        const bool official = true;

                        if (userName != null) {
                          await _usersList.add({
                            "userName": userName,
                            "adminRoll": userRoll,
                            "firstName": firstName,
                            "lastName": lastName,
                            "email": email,
                            "cellNumber": cellNumber,
                            "official": official,
                          });

                          _userNameController.text = '';
                          _userRollController.text = '';
                          _firstNameController.text = '';
                          _lastNameController.text = '';
                          _cellNumberController.text = '';
                          _userEmailController.text = '';

                          Navigator.of(context).pop();
                        }
                      }
                  ),
                ],
              ),
            ),
          );
        });
  }

  Future<void> _update([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      _userNameController.text = documentSnapshot['userName'];
      _userRollController.text = documentSnapshot['adminRoll'];
      _firstNameController.text = documentSnapshot['firstName'];
      _lastNameController.text = documentSnapshot['lastName'];
      _userEmailController.text = documentSnapshot['email'];
      _cellNumberController.text = documentSnapshot['cellNumber'];
    }

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
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
                      .bottom + 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _userNameController,
                      decoration: const InputDecoration(
                          labelText: 'User Name'),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _userRollController,
                      decoration: const InputDecoration(
                          labelText: 'User Roll'),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                          labelText: 'First Name'),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                          labelText: 'Last Name'),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _userEmailController,
                      decoration: const InputDecoration(
                          labelText: 'User Email'),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _cellNumberController,
                      decoration: const InputDecoration(
                          labelText: 'Phone Number'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                      child: const Text('Update'),
                      onPressed: () async {
                        final String userName = _userNameController.text;
                        final String userRoll = _userRollController.text;
                        final String firstName = _firstNameController.text;
                        final String lastName = _lastNameController.text;
                        final String email = _userEmailController.text;
                        final String cellNumber = _cellNumberController.text;
                        const bool official = true;

                        if (userName != null) {
                          await _usersList
                              .doc(documentSnapshot!.id)
                              .update({
                            "userName": userName,
                            "adminRoll": userRoll,
                            "firstName": firstName,
                            "lastName": lastName,
                            "email": email,
                            "cellNumber": cellNumber,
                            "official": official,
                          });

                          _userNameController.text = '';
                          _userRollController.text = '';
                          _firstNameController.text = '';
                          _lastNameController.text = '';
                          _cellNumberController.text = '';
                          _userEmailController.text = '';

                          Navigator.of(context).pop();
                        }
                      }
                  ),
                ],
              ),
            ),
          );
        });
  }

  Future<void> _delete(String user) async {
    await _usersList.doc(user).delete();
    Fluttertoast.showToast(msg: "You have successfully deleted an account!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Official User List'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder(
        stream: _usersList.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(

              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {

                final DocumentSnapshot documentSnapshot =
                streamSnapshot.data!.docs[index];

                if (streamSnapshot.data!.docs[index]['official'] == true) {
                  return Column(
                    children: [
                      ListView(
                          padding: const EdgeInsets.all(32),
                          children: [
                            const SizedBox(height: 20,),
                            adminUserField(
                                "First Name: $documentSnapshot['userName']"),
                            const SizedBox(height: 10,),
                            adminUserField(
                                "Roll: $documentSnapshot['adminRoll']"),
                            const SizedBox(height: 10,),
                            adminUserField(
                                "First Name: $documentSnapshot['firstName']"),
                            const SizedBox(height: 10,),
                            adminUserField(
                                "Last Name: $documentSnapshot['lastName']"),
                            const SizedBox(height: 10,),
                            adminUserField(
                                "Email: $documentSnapshot['email']"),
                            const SizedBox(height: 10,),
                            adminUserField(
                                "Phone Number: $documentSnapshot['cellNumber']"),
                            const SizedBox(height: 10,),
                            Visibility(
                              visible: visShow,
                              child: Row(
                                children: [
                                  Center(
                                      child: Material(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(8),
                                        child: InkWell(
                                          onTap: () {
                                            String deleteUser = documentSnapshot.reference.id;
                                            _delete(deleteUser);
                                          },
                                          borderRadius: BorderRadius.circular(32),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 30,
                                              vertical: 12,
                                            ),
                                            child: Text(
                                              "Delete User",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                  ),
                                  const SizedBox(width: 30,),
                                  Center(
                                      child: Material(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(8),
                                        child: InkWell(

                                          ///This will contain the function that edits the table data of meter readings for the current month only
                                          onTap: () {
                                            _update(documentSnapshot);
                                          },
                                          borderRadius: BorderRadius.circular(32),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 30,
                                              vertical: 12,
                                            ),
                                            child: Text(
                                              "Change User Roll",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 50,),
                          ]
                      ),
                    ],
                  );
                } else {
                  return const Padding(
                    padding: EdgeInsets.all(50.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
              },
            );
          }
          return const Padding(
            padding: EdgeInsets.all(50.0),
            child: Center(child: CircularProgressIndicator()),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _create(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.plus_one),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

}
