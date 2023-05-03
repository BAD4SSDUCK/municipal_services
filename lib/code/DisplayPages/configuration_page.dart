import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:municipal_track/code/AuthGoogle/auth_page_google.dart';

class ConfigPage extends StatefulWidget{
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

final User? user = auth.currentUser;
final uid = user?.uid;
final uEmail = user?.email;
String userID = uid as String;

final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;

class FireStorageService extends ChangeNotifier{
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async{
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

class _ConfigPageState extends State<ConfigPage> {

  //text fields' controllers
  final _deptNameController = TextEditingController();
  final _userRollController = TextEditingController();
  final _userNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _userEmailController = TextEditingController();
  final _cellNumberController = TextEditingController();
  final _passwordController = TextEditingController();

  final CollectionReference _usersList =
  FirebaseFirestore.instance.collection('users');

  final CollectionReference _deptInfo =
  FirebaseFirestore.instance.collection('departments');

  String userPass = '';
  String addressPass = '';

  bool visShow = true;
  bool visHide = false;

  //this widget is for displaying a user information with an icon next to it, NB. the icon is to make it look good
  Widget adminUserField(IconData iconImg, String dbData) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8,),
      child: Row(
        children: [
          Icon(
            iconImg,
            size: 30,
            color: Colors.black,
          ),
          const SizedBox(width: 6,),
          Text(
            dbData,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget departmentField(IconData iconImg, String dbData) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8,),
      child: Row(
        children: [
          Icon(
            iconImg,
            size: 30,
            color: Colors.black,
          ),
          const SizedBox(width: 6,),
          Text(
            dbData,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  static Future<UserCredential> register(String email, String password) async {
    FirebaseApp app = await Firebase.initializeApp(
        name: 'Secondary', options: Firebase.app().options);

    UserCredential userCredential = await FirebaseAuth.instanceFor(app: app)
        .createUserWithEmailAndPassword(email: email, password: password);

    await app.delete();
    return Future.sync(() => userCredential);
  }

  Future<void> _create([DocumentSnapshot? documentSnapshot]) async {
    _userNameController.text = '';
    _userRollController.text = '';
    _firstNameController.text = '';
    _lastNameController.text = '';
    _userEmailController.text = '';
    _cellNumberController.text = '';
    _passwordController.text = '';

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
                  const Center(
                    child: Text(
                      'Create New Official User',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
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
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                          labelText: 'User Password'),
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
                        final String password = _passwordController.text;
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

                          register(email,password);

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
                  const Center(
                    child: Text(
                      'Edit Official Users Information',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
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

  Future<void> _createDeptInfo([DocumentSnapshot? documentSnapshot]) async {
    _deptNameController.text = '';
    _userRollController.text = '';

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
                  const Center(
                    child: Text(
                      'Create Department',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _deptNameController,
                      decoration: const InputDecoration(
                          labelText: 'Department'),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _userRollController,
                      decoration: const InputDecoration(
                          labelText: 'User Rolls'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                      child: const Text('Create'),
                      onPressed: () async {
                        final String deptName = _deptNameController.text;
                        final String userRoll = _userRollController.text;
                        const bool official = true;

                        if (deptName != null) {
                          await _deptInfo.add({
                            "deptName": deptName,
                            "adminRoll": userRoll,
                            "official": official,
                          });

                          _deptNameController.text = '';
                          _userRollController.text = '';

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

  Future<void> _updateDeptInfo([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      _deptNameController.text = documentSnapshot['deptName'];
      _userRollController.text = documentSnapshot['adminRoll'];
    }

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
                  const Center(
                    child: Text(
                      'Edit Department Information',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _deptNameController,
                      decoration: const InputDecoration(
                          labelText: 'Department Name'),
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
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                      child: const Text('Update'),
                      onPressed: () async {
                        final String deptName = _deptNameController.text;
                        final String userRoll = _userRollController.text;
                        const bool official = true;

                        if (deptName != null) {
                          await _usersList
                              .doc(documentSnapshot!.id)
                              .update({
                            "deptName": deptName,
                            "adminRoll": userRoll,
                            "official": official,
                          });

                          _deptNameController.text = '';
                          _userRollController.text = '';

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

  Future<void> _deleteDeptInfo(String deptID) async {
    await _deptInfo.doc(deptID).delete();
    Fluttertoast.showToast(msg: "You have successfully deleted a department & roll!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Department and Officials'),
        backgroundColor: Colors.green,
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Departments List'),
            Tab(text: 'Users List'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          ///Tab for department list view
          StreamBuilder(
            stream: _deptInfo.snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
              if (streamSnapshot.hasData) {
                return ListView.builder(
                  itemCount: streamSnapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final DocumentSnapshot deptDocumentSnapshot =
                    streamSnapshot.data!.docs[index];
                    if (streamSnapshot.data!.docs[index]['official'] == true) {
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
                                  'Departments Information',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 20,),
                              departmentField(
                                Icons.business,
                                "Department Name: " + deptDocumentSnapshot['deptName'],),
                              departmentField(
                                Icons.account_circle_outlined,
                                "Roll: " + deptDocumentSnapshot['adminRoll'],),
                              const SizedBox(height: 20,),
                              Visibility(
                                visible: visShow,
                                child: Center(
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 15,),
                                      Center(
                                          child: Material(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(8),
                                            child: InkWell(
                                              onTap: () {
                                                showDialog(
                                                    barrierDismissible: false,
                                                    context: context,
                                                    builder: (context) {
                                                      return
                                                        AlertDialog(
                                                          shape: const RoundedRectangleBorder(
                                                              borderRadius:
                                                              BorderRadius.all(Radius.circular(16))),
                                                          title: const Text("Delete this Roll & Department!"),
                                                          content: const Text(
                                                              "Are you sure about deleting this Roll and the Department associated with it?"),
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
                                                                String deleteDept = deptDocumentSnapshot.reference.id;
                                                                _deleteDeptInfo(deleteDept);

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
                                              borderRadius: BorderRadius.circular(
                                                  32),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 12,
                                                ),
                                                child: Text(
                                                  "Delete Roll",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                      ),
                                      const SizedBox(width: 10,),
                                      Center(
                                          child: Material(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(8),
                                            child: InkWell(
                                              onTap: () {
                                                _updateDeptInfo(deptDocumentSnapshot);
                                              },
                                              borderRadius: BorderRadius.circular(
                                                  32),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 12,
                                                ),
                                                child: Text(
                                                  "Change Roll Info",
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
                              ),
                              const SizedBox(height: 10,),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return const Padding(
                        padding: EdgeInsets.all(50.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                  },
                );
              } else {
                return const Padding(
                  padding: EdgeInsets.all(50.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
            },
          ),

          ///Tab for users list view
          StreamBuilder(
            stream: _usersList.snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
              if (streamSnapshot.hasData) {
                return ListView.builder(
                  itemCount: streamSnapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final DocumentSnapshot userDocumentSnapshot =
                    streamSnapshot.data!.docs[index];

                    if (streamSnapshot.data!.docs[index]['official'] == true) {
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
                                  'Official User Information',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 20,),
                              adminUserField(
                                Icons.switch_account,
                                  "First Name: " + userDocumentSnapshot['userName']),
                              adminUserField(
                                  Icons.business_center,
                                  "Roll: " + userDocumentSnapshot['adminRoll']),
                              adminUserField(
                                  Icons.account_circle,
                                  "First Name: " + userDocumentSnapshot['firstName']),
                              adminUserField(
                                  Icons.account_circle,
                                  "Last Name: " + userDocumentSnapshot['lastName']),
                              adminUserField(
                                  Icons.email,
                                  "Email: " + userDocumentSnapshot['email']),
                              adminUserField(
                                  Icons.phone,
                                  "Phone Number: " + userDocumentSnapshot['cellNumber']),
                              const SizedBox(height: 20,),
                              Visibility(
                                visible: visShow,
                                child: Center(
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 15,),
                                      Center(
                                          child: Material(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(8),
                                            child: InkWell(
                                              onTap: () {
                                                showDialog(
                                                    barrierDismissible: false,
                                                    context: context,
                                                    builder: (context) {
                                                      return
                                                        AlertDialog(
                                                          shape: const RoundedRectangleBorder(
                                                              borderRadius:
                                                              BorderRadius.all(Radius.circular(16))),
                                                          title: const Text("Delete this User!"),
                                                          content: const Text(
                                                              "Are you sure about deleting this user?"),
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
                                                                String deleteUser = userDocumentSnapshot.reference.id;
                                                                _delete(deleteUser);

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
                                              borderRadius: BorderRadius.circular(
                                                  32),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 20,
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
                                      const SizedBox(width: 10,),
                                      Center(
                                          child: Material(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(8),
                                            child: InkWell(
                                              onTap: () {
                                                _update(userDocumentSnapshot);
                                              },
                                              borderRadius: BorderRadius.circular(
                                                  32),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 12,
                                                ),
                                                child: Text(
                                                  "Change User Info",
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
                              ),
                              const SizedBox(height: 10,),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return const Padding(
                        padding: EdgeInsets.all(50.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                  },
                );
              } else {
              return const Padding(
                padding: EdgeInsets.all(50.0),
                child: Center(child: CircularProgressIndicator()),
              );
              }
            },
          ),

        ],
      ),

      floatingActionButton: Row(
        children: [
          FloatingActionButton(
            onPressed: () => _create(),
            backgroundColor: Colors.green,
            child: const Icon(Icons.add_reaction),
          ),
          const SizedBox(width: 10,),
          FloatingActionButton(
            onPressed: () => _createDeptInfo(),
            backgroundColor: Colors.green,
            child: const Icon(Icons.add_business),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

    );
  }

}
