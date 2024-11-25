import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:municipal_services/code/AuthGoogle/auth_page_google.dart';
import 'package:municipal_services/code/DisplayPages/display_info.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';

class DevConfigPage extends StatefulWidget{

  const DevConfigPage({super.key, });

  @override
  State<DevConfigPage> createState() => _DevConfigPageState();
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

class _DevConfigPageState extends State<DevConfigPage> with TickerProviderStateMixin{
  String? userEmail;
  String districtId='';
  String municipalityId='';
  bool isLocalMunicipality=false;

  @override
  void initState() {
    super.initState();

    fetchUserDetails().then((_) {
      // Ensure that Firestore references are initialized before calling these methods
      if (_usersList != null && _deptInfo != null && _roles != null && _deptRoles != null && _version != null) {
        // Call the counting and data-fetching methods after ensuring initialization
        countUsersResult();
        countDeptResult();
        countRoleResult();

        // Fetch data only after ensuring the references are ready
        getDBUsers(_usersList!);
        getDBDept(_deptInfo!);
        getDBRoles(_roles!);
        getDBDeptRoles(_deptRoles!);
        getDBAppVersion(_version!);
      } else {
        print("Error: One or more Firestore references are not initialized.");
      }
    }).catchError((error) {
      print("Error fetching user details: $error");
    });
  }

  @override
  void dispose() {
    super.dispose();
  }


  Future<void> fetchUserDetails() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userEmail = user.email;

        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collectionGroup('users')
            .where('email', isEqualTo: userEmail)
            .limit(1)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          var userDoc = userSnapshot.docs.first;

          // Detect whether the user is in a local or district municipality
          isLocalMunicipality = userDoc['isLocalMunicipality'] ?? false;

          if (isLocalMunicipality) {
            municipalityId = userDoc.reference.parent.parent!.id;

            // Set Firestore paths for local municipalities
            setState(() {
              _usersList = FirebaseFirestore.instance
                  .collection('localMunicipalities')
                  .doc(municipalityId)
                  .collection('users');

              _deptInfo = FirebaseFirestore.instance
                  .collection('localMunicipalities')
                  .doc(municipalityId)
                  .collection('departments');

              _roles = FirebaseFirestore.instance
                  .collection('localMunicipalities')
                  .doc(municipalityId)
                  .collection('roles');

              _deptRoles = FirebaseFirestore.instance
                  .collection('localMunicipalities')
                  .doc(municipalityId)
                  .collection('departmentRoles');

              _version = FirebaseFirestore.instance
                  .collection('localMunicipalities')
                  .doc(municipalityId)
                  .collection('version');
            });
          } else {
            // District municipality handling
            districtId = userDoc.reference.parent.parent!.parent.id;
            municipalityId = userDoc.reference.parent.parent!.id;

            // Set Firestore paths for district municipalities
            setState(() {
              _usersList = FirebaseFirestore.instance
                  .collection('districts')
                  .doc(districtId)
                  .collection('municipalities')
                  .doc(municipalityId)
                  .collection('users');

              _deptInfo = FirebaseFirestore.instance
                  .collection('districts')
                  .doc(districtId)
                  .collection('municipalities')
                  .doc(municipalityId)
                  .collection('departments');

              _roles = FirebaseFirestore.instance
                  .collection('districts')
                  .doc(districtId)
                  .collection('municipalities')
                  .doc(municipalityId)
                  .collection('roles');

              _deptRoles = FirebaseFirestore.instance
                  .collection('districts')
                  .doc(districtId)
                  .collection('municipalities')
                  .doc(municipalityId)
                  .collection('departmentRoles');

              _version = FirebaseFirestore.instance
                  .collection('districts')
                  .doc(districtId)
                  .collection('municipalities')
                  .doc(municipalityId)
                  .collection('version');
            });
          }
        } else {
          print("No user document found for the provided email.");
        }
      } else {
        print("No current user found.");
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  //text fields' controllers
  final _deptNameController = TextEditingController();
  final _userRoleController = TextEditingController();
  final _userNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _userEmailController = TextEditingController();
  final _cellNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _versionController = TextEditingController();

  late final _tabController = TabController(length: 4, vsync: this);
  int _tabIndex = 0;
  final int _tabLength = 4;
  void _toggleTab(){
    _tabIndex = _tabController.index+1 ;
    _tabController.animateTo(_tabIndex);
  }

  TextEditingController controllerDept = TextEditingController();
  bool displayDeptList = false;

  List<String> usersEmails =[];
  int numUsers = 0;
  List<String> deptName =["Select Department..."];
  String dropdownValue = 'Select Department...';
  int numDept = 0;
  List<String> role =["Select Role..."];
  List<String> deptRole =["Select Role..."];
  String dropdownValue2 = 'Select Role...';
  int numRoles = 0;
  List<String> versionList =["Select Version...","Unpaid","Paid","Premium"];
  String dropdownValue3 = 'Select Version...';
  int numVersion = 0;

  // final CollectionReference _usersList =
  // FirebaseFirestore.instance.collection('users');
  //
  // final CollectionReference _deptInfo =
  // FirebaseFirestore.instance.collection('departments');
  //
  // final CollectionReference _roles =
  // FirebaseFirestore.instance.collection('roles');
  //
  // final CollectionReference _deptRoles =
  // FirebaseFirestore.instance.collection('departmentRoles');
  //
  // final CollectionReference _version =
  // FirebaseFirestore.instance.collection('version');
  CollectionReference? _usersList;
  CollectionReference? _deptInfo;
  CollectionReference? _roles;
  CollectionReference? _deptRoles;
  CollectionReference? _version;

  // Data storage

  String selectedDept = "0";
  String selectedRole = "0";

  bool visShow = true;
  bool visHide = false;
  bool vis1 = false;
  bool vis2 = false;
  bool vis3 = false;

  //this widget is for displaying a user information with an icon next to it, NB. the icon is to make it look good
  Widget adminUserField(IconData iconImg, String dbData) {

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8,),
      child: Row(
        children: [
          Icon(
            iconImg,
            size: 20,
            color: Colors.black,
          ),
          const SizedBox(width: 6,),
          Expanded(
            child: Text(
              dbData,
              style: const TextStyle(
                overflow: TextOverflow.fade,
                fontSize: 15,
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8,),
      child: Row(
        children: [
          Icon(
            iconImg,
            size: 20,
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

  ///to fix register authentication on user creation
  static Future<UserCredential> register(String email, String password) async {
    FirebaseApp app = await Firebase.initializeApp(
        name: 'Secondary', options: Firebase.app().options);

    UserCredential userCredential = await FirebaseAuth.instanceFor(app: app)
        .createUserWithEmailAndPassword(email: email, password: password);

    await app.delete();
    return Future.sync(() => userCredential);
  }///Firebase auth user creation for officials login details

  Future<void> createAuthUser(String emailReg, String passwordReg) async {
    try{
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: emailReg,
      password: passwordReg,
    );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password'){
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e){
      print(e);
    }
  }

  Future<void> _create([DocumentSnapshot? documentSnapshot]) async {

    deptRole = deptRole.toSet().toList();///To set clips out all duplicates and leaves only unique items in the array

    _userNameController.text = '';
    _deptNameController.text = '';
    _userRoleController.text = '';
    _firstNameController.text = '';
    _lastNameController.text = '';
    _userEmailController.text = '';
    _cellNumberController.text = '';
    _passwordController.text = '';
    dropdownValue = 'Select Department...';
    dropdownValue2 = 'Select Role...';

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
                    visible: visHide,
                    child: TextField(
                      controller: _deptNameController,
                      decoration: const InputDecoration(
                          labelText: 'User Department'),
                    ),
                  ),


                  Visibility(
                    visible: visShow,
                    child: DropdownButtonFormField <String>(
                      value: dropdownValue,
                      items: deptName
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toSet().toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          dropdownValue = newValue!;
                        });
                      },
                    ),
                  ),


                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _userRoleController,
                      decoration: const InputDecoration(
                          labelText: 'User Role'),
                    ),
                  ),

                  Visibility(
                    visible: visShow,
                    child: DropdownButtonFormField <String>(
                      value: dropdownValue2,
                      items: deptRole
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toSet().toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          dropdownValue2 = newValue!;
                        });
                      },
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
                        final String deptName = dropdownValue;
                        final String userRole = dropdownValue2;
                        final String firstName = _firstNameController.text;
                        final String lastName = _lastNameController.text;
                        final String email = _userEmailController.text;
                        final String cellNumber = _cellNumberController.text;
                        final String password = _passwordController.text;
                        const bool official = true;

                        if (userName != null) {
                          await _usersList?.add({
                            "userName": userName,
                            "deptName": deptName,
                            "userRole": userRole,
                            "firstName": firstName,
                            "lastName": lastName,
                            "email": email,
                            "cellNumber": cellNumber,
                            "official": official,
                          });

                          register(email,password);

                          createAuthUser(email,password);

                          _userNameController.text = '';
                          _deptNameController.text = '';
                          _userRoleController.text = '';
                          _firstNameController.text = '';
                          _lastNameController.text = '';
                          _cellNumberController.text = '';
                          _userEmailController.text = '';
                          dropdownValue = 'Select Department...';
                          dropdownValue2 = 'Select Role...';

                          if(context.mounted)Navigator.of(context).pop();
                        }
                      }
                  ),
                ],
              ),
            ),
          );
        });
  }///Creation method for details on an official user

  Future<void> _update([DocumentSnapshot? documentSnapshot]) async {
    final docRef = _deptInfo?.snapshots();

    if (documentSnapshot != null) {
      _userNameController.text = documentSnapshot['userName'];
      // dropdownValue = documentSnapshot['deptName'];
      // dropdownValue2 = documentSnapshot['userRole'];
      _deptNameController.text = documentSnapshot['deptName'];
      _userRoleController.text = documentSnapshot['userRole'];
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
                      controller: _deptNameController,
                      decoration: const InputDecoration(
                          labelText: 'User Department'),
                    ),
                  ),

                  Visibility(
                    visible: visHide,
                    child: DropdownButtonFormField <String>(
                      value: dropdownValue,
                      items: deptName
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toSet().toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          dropdownValue = newValue!;
                        });
                      },
                    ),
                  ),


                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _userRoleController,
                      decoration: const InputDecoration(
                          labelText: 'User Role'),
                    ),
                  ),

                  Visibility(
                    visible: visHide,
                    child: DropdownButtonFormField <String>(
                      value: dropdownValue2,
                      items: deptRole
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toSet().toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          dropdownValue2 = newValue!;
                        });
                      },
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
                        final String deptName = _deptNameController.text;
                        final String userRole = _userRoleController.text;
                        final String firstName = _firstNameController.text;
                        final String lastName = _lastNameController.text;
                        final String email = _userEmailController.text;
                        final String cellNumber = _cellNumberController.text;
                        const bool official = true;

                        if (userName != null) {
                          await _usersList
                              ?.doc(documentSnapshot!.id)
                              .update({
                            "userName": userName,
                            "deptName": deptName,
                            "userRole": userRole,
                            "firstName": firstName,
                            "lastName": lastName,
                            "email": email,
                            "cellNumber": cellNumber,
                            "official": official,
                          });

                          _userNameController.text = '';
                          _deptNameController.text = '';
                          _userRoleController.text = '';
                          _firstNameController.text = '';
                          _lastNameController.text = '';
                          _userEmailController.text = '';
                          _cellNumberController.text = '';

                          if(context.mounted)Navigator.of(context).pop();
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
    await _usersList?.doc(user).delete();
    Fluttertoast.showToast(msg: "You have successfully deleted an account!");
  }

  Future<void> _createDeptRoles([DocumentSnapshot? documentSnapshot]) async {
    _deptNameController.text = '';
    _userRoleController.text = '';

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
                      'Link Department to Role',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _deptNameController,
                      decoration: const InputDecoration(
                          labelText: 'Department'),
                    ),
                  ),

                  Visibility(
                    visible: visShow,
                    child: DropdownButtonFormField <String>(
                      value: dropdownValue,
                      items: deptName
                      // <String>['Select Department...', 'Electricity', 'Water & Sanitation', 'Roadworks', 'Waste Management']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toSet().toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          dropdownValue = newValue!;
                        });
                      },
                    ),
                  ),

                  Visibility(
                    visible: visShow,
                    child: DropdownButtonFormField <String>(
                      value: dropdownValue2,
                      items: deptRole
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toSet().toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          dropdownValue2 = newValue!;
                        });
                      },
                    ),
                  ),

                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _userRoleController,
                      decoration: const InputDecoration(
                          labelText: 'User Role'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                      child: const Text('Create'),
                      onPressed: () async {
                        // final String deptName = _deptNameController.text;
                        final String deptName = dropdownValue;
                        final String userRole = _userRoleController.text;
                        const bool official = true;

                        if (deptName != null) {
                          await _deptRoles?.add({
                            "deptName": deptName,
                            "userRole": userRole,
                            "official": official,
                          });

                          _deptNameController.text = '';
                          _userRoleController.text = '';
                          dropdownValue = 'Select Department...';
                          dropdownValue2 = 'Select Role...';

                          if(context.mounted)Navigator.of(context).pop();
                        }
                      }
                  ),
                ],
              ),
            ),
          );
        });
  }///Creation method for department roles

  Future<void> _updateDeptRoles([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      _deptNameController.text = documentSnapshot['deptName'];
      _userRoleController.text = documentSnapshot['userRole'];

      dropdownValue = documentSnapshot['deptName'];
      // dropdownValue = documentSnapshot['deptName'];
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
                    visible: visHide,
                    child: TextField(
                      controller: _deptNameController,
                      decoration: const InputDecoration(
                          labelText: 'Department Name'),
                    ),
                  ),

                  Visibility(
                    visible: visShow,
                    child: DropdownButtonFormField <String>(
                      value: dropdownValue,
                      items: deptName
                      // <String>['Select Department...', 'Electricity', 'Water & Sanitation', 'Roadworks', 'Waste Management']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toSet().toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          dropdownValue = newValue!;
                        });
                      },
                    ),
                  ),

                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _userRoleController,
                      decoration: const InputDecoration(
                          labelText: 'User Role'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                      child: const Text('Update'),
                      onPressed: () async {
                        // final String deptName = _deptNameController.text;
                        final String deptName = dropdownValue;
                        final String userRole = _userRoleController.text;
                        const bool official = true;

                        if (deptName != null) {
                          await _deptRoles
                              ?.doc(documentSnapshot!.id)
                              .update({
                            "deptName": deptName,
                            "userRole": userRole,
                            "official": official,
                          });

                          _deptNameController.text = '';
                          _userRoleController.text = '';

                          if(context.mounted)Navigator.of(context).pop();
                        }
                      }
                  ),
                ],
              ),
            ),
          );
        });
  }

  Future<void> _deleteDeptRole(String deptID) async {
    await _deptRoles?.doc(deptID).delete();
    Fluttertoast.showToast(msg: "You have successfully deleted a department & role!");
  }

  Future<void> _createDept([DocumentSnapshot? documentSnapshot]) async {
    _deptNameController.text = '';

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
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                      child: const Text('Create'),
                      onPressed: () async {
                        final String deptartName = _deptNameController.text;
                        const bool official = true;

                        if (deptName != null) {
                          await _deptInfo?.add({
                            "deptName": deptartName,
                            "official": official,
                          });

                          _deptNameController.text = '';
                          deptName =["Select Department..."];

                          if(context.mounted)Navigator.of(context).pop();
                        }
                      }
                  ),
                ],
              ),
            ),
          );
        });
  }///Creation method for departments

  Future<void> _updateDept([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      _deptNameController.text = documentSnapshot['deptName'];
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
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                      child: const Text('Update'),
                      onPressed: () async {
                        final String deptName = _deptNameController.text;
                        const bool official = true;

                        if (deptName != null) {
                          await _deptInfo
                              ?.doc(documentSnapshot!.id)
                              .update({
                            "deptName": deptName,
                            "official": official,
                          });

                          _deptNameController.text = '';

                          if(context.mounted)Navigator.of(context).pop();
                        }
                      }
                  ),
                ],
              ),
            ),
          );
        });
  }

  Future<void> _deleteDept(String deptID) async {
    await _deptInfo?.doc(deptID).delete();
    Fluttertoast.showToast(msg: "You have successfully deleted a department & role!");
  }

  Future<void> _createRole([DocumentSnapshot? documentSnapshot]) async {
    _deptNameController.text = '';

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
                      'Create Role',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _userRoleController,
                      decoration: const InputDecoration(
                          labelText: 'Role'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                      child: const Text('Create'),
                      onPressed: () async {
                        final String roleName = _userRoleController.text;
                        const bool official = true;

                        if (deptName != null) {
                          await _deptInfo?.add({
                            "role": roleName,
                          });

                          _userRoleController.text = '';
                          deptName =["Select Department..."];

                          if(context.mounted)Navigator.of(context).pop();
                        }
                      }
                  ),
                ],
              ),
            ),
          );
        });
  }///Creation method for departments

  Future<void> _updateRole([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      _userRoleController.text = documentSnapshot['role'];
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
                      'Edit Role Information',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _userRoleController,
                      decoration: const InputDecoration(
                          labelText: 'Role'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                      child: const Text('Update'),
                      onPressed: () async {
                        final String roleName = _userRoleController.text;
                        const bool official = true;

                        if (deptName != null) {
                          await _roles
                              ?.doc(documentSnapshot!.id)
                              .update({
                            "role": roleName,
                          });

                          _userRoleController.text = '';

                          if(context.mounted)Navigator.of(context).pop();
                        }
                      }
                  ),
                ],
              ),
            ),
          );
        });
  }

  Future<void> _deleteRole(String roleID) async {
    await _roles?.doc(roleID).delete();
    Fluttertoast.showToast(msg: "You have successfully deleted a role!");
  }

  Future<void> _createVersion([DocumentSnapshot? documentSnapshot]) async {
    _versionController.text = '';

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
                      'Create Version',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _versionController,
                      decoration: const InputDecoration(
                          labelText: 'Version Name'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                      child: const Text('Create'),
                      onPressed: () async {
                        final String versionName = _versionController.text;

                        if (deptName != null) {
                          await _deptInfo?.add({
                            "version": versionName,
                          });

                          _versionController.text = '';
                          deptName =["Select Department..."];

                          if(context.mounted)Navigator.of(context).pop();
                        }
                      }
                  ),
                ],
              ),
            ),
          );
        });
  }///Creation method for versions

    Future<void> _updateVersion(String newVersion) async {

    final CollectionReference _currentvVersion =
    FirebaseFirestore.instance.collection('version').doc('current').collection('current-version');

    if (_currentvVersion != null) {
      await _currentvVersion
          .doc('current')
          .update({
        "version": newVersion,
      });

      await _version
          ?.doc('current')
          .update({
        "version": newVersion,
      });

      Fluttertoast.showToast(msg: "The app version has been set to $newVersion!", gravity: ToastGravity.CENTER);

    }
    dropdownValue3 = 'Select Version...';

  }

  Future<void> _deleteVersion(String versionID) async {
    await _version?.doc(versionID).delete();
    Fluttertoast.showToast(msg: "You have successfully deleted a role!");
  }

  void countUsersResult() async {
    if (_usersList != null) {
      var query = _usersList!.where("email");
      var snapshot = await query.get();
      var count = snapshot.size;
      numUsers = snapshot.size;

      print('Records are ::: $count');
      print('num emails are ::: $numUsers');
    } else {
      print('Users list is not initialized yet.');
    }
  }

  void countDeptResult() async {
    if (_deptInfo != null) {
      var query1 = _deptInfo!.where("deptName");
      var snapshot1 = await query1.get();
      var count1 = snapshot1.size;
      numDept = snapshot1.size;
    } else {
      print('Department info is not initialized yet.');
    }
  }

  void countRoleResult() async {
    if (_roles != null) {
      var query2 = _roles!.where("userRole");
      var snapshot2 = await query2.get();
      var count2 = snapshot2.size;
      numDept = snapshot2.size;
    } else {
      print('Roles collection is not initialized yet.');
    }
  }

  void getDBDept(CollectionReference dept) async {
    dept.get().then((querySnapshot) async {
      for (var result in querySnapshot.docs) {
        print('The department is::: ${result['deptName']}');
        if(deptName.length-1<querySnapshot.docs.length) {
          deptName.add(result['deptName']);
        }
        print(deptName);
        print(deptName.length);
      }
    });
  }///Looping department collection

  void getDBRoles(CollectionReference roles) async {
    roles.get().then((querySnapshot) async {
      for (var result in querySnapshot.docs) {
        print('The role is::: ${result['role']}');
        if(role.length-1<querySnapshot.docs.length) {
          role.add(result['role']);
        }
        print(role);
        print(role.length);
      }
    });
  }///Looping roles collection

  void getDBDeptRoles(CollectionReference deptRoles) async {
    deptRoles.get().then((querySnapshot) async {
      for (var result in querySnapshot.docs) {
        print('The role is::: ${result['userRole']}');
        if(deptRole.length-1<querySnapshot.docs.length) {
          deptRole.add(result['userRole']);
        }
      }
    });
  }///Looping department roles collection

  void getDBUsers(CollectionReference users) async {
    try {
      // Fetch users from Firestore and process them
      final querySnapshot = await users.get();
      for (var result in querySnapshot.docs) {
        print('The user email is::: ${result['email']}');
        if (result['email'].contains('@') && usersEmails.length - 1 < querySnapshot.docs.length) {
          usersEmails.add(result['email']);
        }
      }
      print(usersEmails);
      print(usersEmails.length);
    } catch (e) {
      // Handle any errors that occur during the Firestore query
      print("Error fetching users from Firestore: $e");
    }
  }


  // void getDBAppVersion(CollectionReference versions) async {
  //   versions.get().then((querySnapshot) async {
  //     for (var result in querySnapshot.docs) {
  //       print('The version is::: ${result['version']}');
  //
  //       versions.add(result['version']);
  //
  //       if(versionList.length-1<querySnapshot.docs.length && result != result[2]['version']) {
  //         versionList.add(result['version']);
  //       }
  //     }
  //   });
  //
  //   versionList.toSet();
  //   print(versionList);
  //
  // }///Looping version collection
  void getDBAppVersion(CollectionReference versions) async {
    versions.get().then((querySnapshot) async {
      for (var result in querySnapshot.docs) {
        String version = result['version'];
        print('The version is::: $version');

        // Add the version to the versionList if it's not already present
        if (!versionList.contains(version)) {
          versionList.add(version);
        }
      }

      // Remove any duplicate versions from the list
      versionList = versionList.toSet().toList();
      print(versionList);
    }).catchError((error) {
      print('Error fetching app versions: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_usersList == null || _deptInfo == null || _roles == null || _deptRoles == null || _version == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return DefaultTabController(
      initialIndex: 0,
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.grey[350],
        appBar: AppBar(
          title: const Text('Department and Officials',style: TextStyle(color: Colors.white),),
          backgroundColor: Colors.green,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            controller: _tabController,
            tabs: const [
              Tab(text: 'Roles', icon: FaIcon(Icons.work_history),),
              Tab(text: 'Depts', icon: FaIcon(Icons.corporate_fare),),
              Tab(text: 'User List', icon: FaIcon(Icons.person_2_outlined),),
              Tab(text: 'Version', icon: FaIcon(Icons.lock_open_outlined),),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            StreamBuilder(
              stream: _roles?.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                if (streamSnapshot.hasData) {
                  return ListView.builder(
                    itemCount: streamSnapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final DocumentSnapshot userDocumentSnapshot = streamSnapshot.data!.docs[index];

                      return Card(
                        margin: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(
                                child: Text(
                                  'Staff Roles List',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 20,),
                              adminUserField(
                                  Icons.business_center_outlined,
                                  "Role: ${userDocumentSnapshot['role']}"),

                              const SizedBox(height: 20,),
                              Visibility(
                                visible: visShow,
                                child: Center(
                                  child: Column(
                                    children: [
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
                                                          title: const Text("Delete this role!"),
                                                          content: const Text("Are you sure about deleting this role?"),
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
                                                                String deleteRole = userDocumentSnapshot.id;
                                                                _deleteRole(deleteRole);
                                                                Navigator.of(context).pop();
                                                                // Navigator.of(context).pop();
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
                                              borderRadius: BorderRadius.circular(32),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 10,
                                                ),
                                                child: Text(
                                                  "  Delete Role  ",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                      ),
                                      const SizedBox(height: 10,),
                                      Center(
                                          child: Material(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(8),
                                            child: InkWell(
                                              onTap: () {
                                                _updateRole(userDocumentSnapshot);
                                              },
                                              borderRadius: BorderRadius.circular(32),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 10,
                                                ),
                                                child: Text(
                                                  "Edit Role",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
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
                              const SizedBox(height: 0,),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return const Padding(
                    padding: EdgeInsets.all(50.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
              },
            ),///Tab for role control

            StreamBuilder(
              stream: _deptInfo?.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                if (streamSnapshot.hasData) {
                  return ListView.builder(
                    itemCount: streamSnapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final DocumentSnapshot deptDocumentSnapshot =
                      streamSnapshot.data!.docs[index];

                      if (streamSnapshot.data!.docs[index]['official'] == true) {
                        return Card(
                          margin: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
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
                                const SizedBox(height: 15,),
                                departmentField(
                                  Icons.business,
                                  "Department: ${deptDocumentSnapshot['deptName']}",),
                                const SizedBox(height: 15,),
                                Visibility(
                                  visible: visShow,
                                  child: Center(
                                    child: Column(
                                      children: [
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
                                                            title: const Text("Delete this Department!"),
                                                            content: const Text(
                                                                "Are you sure about deleting this Department?"),
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
                                                                  deptName.remove(deptDocumentSnapshot['deptName']);
                                                                  _deleteDept(deleteDept);
                                                                  Navigator.of(context).pop();
                                                                  // Navigator.of(context).pop();
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
                                                    vertical: 10,
                                                  ),
                                                  child: Text(
                                                    "Delete Department",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                        ),
                                        const SizedBox(height: 10,),
                                        Center(
                                            child: Material(
                                              color: Colors.green,
                                              borderRadius: BorderRadius.circular(8),
                                              child: InkWell(
                                                onTap: () {
                                                  _updateDept(deptDocumentSnapshot);
                                                },
                                                borderRadius: BorderRadius.circular(
                                                    32),
                                                child: const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 10,
                                                  ),
                                                  child: Text(
                                                    "  Edit Department  ",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
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
            ),///Tab for department list view

            StreamBuilder(
              stream: _usersList?.orderBy('deptName', descending: false).snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                if (streamSnapshot.hasData) {
                  return ListView.builder(
                    itemCount: streamSnapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final DocumentSnapshot userDocumentSnapshot = streamSnapshot.data!.docs[index];

                      if (streamSnapshot.data!.docs[index]['official'] == true) {
                        return Card(
                          margin: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
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
                                    "User Name: ${userDocumentSnapshot['userName']}"),
                                adminUserField(
                                    Icons.business_center,
                                    "Department: ${userDocumentSnapshot['deptName']}"),
                                adminUserField(
                                    Icons.business_center,
                                    "Role: ${userDocumentSnapshot['userRole']}"),
                                adminUserField(
                                    Icons.account_circle,
                                    "First Name: ${userDocumentSnapshot['firstName']}"),
                                adminUserField(
                                    Icons.account_circle,
                                    "Last Name: ${userDocumentSnapshot['lastName']}"),
                                adminUserField(
                                    Icons.email,
                                    "Email: ${userDocumentSnapshot['email']}"),
                                adminUserField(
                                    Icons.phone,
                                    "Phone Number: ${userDocumentSnapshot['cellNumber']}"),
                                const SizedBox(height: 20,),
                                Visibility(
                                  visible: visShow,
                                  child: Center(
                                    child: Column(
                                      children: [
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
                                                            content: const Text("Are you sure about deleting this user?"),
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
                                                                  String deleteUser = userDocumentSnapshot.id;
                                                                  _delete(deleteUser);
                                                                  Navigator.of(context).pop();
                                                                  // Navigator.of(context).pop();
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
                                                    vertical: 10,
                                                  ),
                                                  child: Text(
                                                    "  Delete User  ",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                        ),
                                        const SizedBox(height: 10,),
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
                                                    vertical: 10,
                                                  ),
                                                  child: Text(
                                                    "Edit User Info",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
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
                                const SizedBox(height: 0,),
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
            ),///Tab for users list view

            Column(
              children: [
                Visibility(
                  visible: visShow,
                  child: SingleChildScrollView(
                    child: Card(
                      child: Column(
                      children: [
                        const SizedBox(height: 20,),
                        const Center(
                          child: Text(
                            'Set Application Version State',
                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 20,),
                        Center(
                          child: Column(
                              children: [
                                SizedBox(
                                  width: 450,
                                  height: 50,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 10, right: 10),
                                    child: Center(
                                      child: TextField(

                                        ///Input decoration here had to be manual because dropdown button uses suffix icon of the textfield
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(30),
                                              borderSide: const BorderSide(
                                                color: Colors.grey,
                                              )
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(30),
                                              borderSide: const BorderSide(
                                                color: Colors.grey,
                                              )
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(30),
                                              borderSide: const BorderSide(
                                                color: Colors.grey,
                                              )
                                          ),
                                          disabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(30),
                                              borderSide: const BorderSide(
                                                color: Colors.grey,
                                              )
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 6
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          suffixIcon: DropdownButtonFormField <String>(
                                            value: dropdownValue3,
                                            items: versionList.map<DropdownMenuItem<String>>((String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 20.0),
                                                  child: Text(
                                                    value,
                                                    style: const TextStyle(fontSize: 16),
                                                  ),
                                                ),
                                              );
                                            }).toSet().toList(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                dropdownValue3 = newValue!;
                                              });
                                            },
                                            icon: const Padding(
                                              padding: EdgeInsets.only(left: 10, right: 10),
                                              child: Icon(Icons.arrow_circle_down_sharp),
                                            ),
                                            iconEnabledColor: Colors.green,
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 18
                                            ),
                                            dropdownColor: Colors.grey[50],
                                            isExpanded: true,

                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20,),

                                // Text(
                                //   'Current App Version: ${versions[2]}',
                                //   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                                // ),

                                const SizedBox(height: 20,),
                                Center(
                                    child: BasicIconButtonGrey(
                                      onPress: () {
                                        String selectedVersionChange;
                                        if(dropdownValue3 != 'Select Version...') {
                                          selectedVersionChange = dropdownValue3;
                                          _updateVersion(selectedVersionChange);
                                        }
                                      },
                                      labelText: 'Set App Version',
                                      fSize: 16,
                                      faIcon: const FaIcon(Icons.monetization_on),
                                      fgColor: Colors.green,
                                      btSize: const Size(100, 50),
                                    )
                                ),

                                const SizedBox(height: 20,),

                              ]
                          ),
                        ),
                      ],
                    ),
                    ),
                  ),
                ),
              ],
            ),///Tab for version control


          ],
        ),

        floatingActionButton: Row(
          children: [
            const SizedBox(width: 10,),
            Visibility(
              visible: visShow,
              child: FloatingActionButton(
                heroTag: 'roleFab', // Unique hero tag
                onPressed: () => _createRole(),
                backgroundColor: Colors.green,
                child: const Icon(Icons.add_moderator),
              ),
            ),
            const SizedBox(width: 10,),
            FloatingActionButton(
              heroTag: 'deptFab', // Unique hero tag
              onPressed: () => _createDept(),
              backgroundColor: Colors.green,
              child: const Icon(Icons.business),
            ),
            const SizedBox(width: 10,),
            FloatingActionButton(
              heroTag: 'deptRolesFab', // Unique hero tag
              onPressed: () => _createDeptRoles(),
              backgroundColor: Colors.green,
              child: const Icon(Icons.add_business),
            ),
            const SizedBox(width: 10,),
            FloatingActionButton(
              heroTag: 'createUserFab', // Unique hero tag
              onPressed: () => _create(),
              backgroundColor: Colors.green,
              child: const Icon(Icons.add_reaction),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      ),
    );
  }
}
