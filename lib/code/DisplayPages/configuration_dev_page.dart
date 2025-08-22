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

class DevConfigPage extends StatefulWidget {
  const DevConfigPage({
    super.key,
  });

  @override
  State<DevConfigPage> createState() => _DevConfigPageState();
}

// final FirebaseAuth auth = FirebaseAuth.instance;
// final storageRef = FirebaseStorage.instance.ref();
// final User? user = auth.currentUser;
// final uid = user?.uid;
// final uEmail = user?.email;
// String userID = uid as String;

final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;

class FireStorageService extends ChangeNotifier {
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async {
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

class _DevConfigPageState extends State<DevConfigPage>
    with TickerProviderStateMixin {
  String? userEmail;
  String districtId = '';
  String municipalityId = '';
  bool isLocalMunicipality = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _init() async {
    try {
      await fetchUserDetails();

      // Only proceed once refs are set
      if (_usersList != null &&
          _deptInfo != null &&
          _roles != null &&
          _deptRoles != null &&
          _version != null) {
        // Debug: verify paths
        print('usersList: ${_usersList?.path}');
        print('deptInfo:  ${_deptInfo?.path}');
        print('roles:     ${_roles?.path}');
        print('deptRoles: ${_deptRoles?.path}');
        print('version:   ${_version?.path}');

        // Counts (safe versions)
        await countUsersResult();
        await countDeptResult();
        await countRoleResult();

        // Populate dropdown data
        getDBUsers(_usersList!);
        getDBDept(_deptInfo!);
        getDBRoles(_roles!);
        getDBDeptRoles(_deptRoles!);
        getDBAppVersion(_version!);
      } else {
        print("Error: One or more Firestore references are not initialized.");
      }
    } catch (e) {
      print("Error during _init: $e");
    }
  }

  Future<void> fetchUserDetails() async {
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current == null) {
        print("No current user found.");
        return;
      }

      userEmail = current.email;
      if (userEmail == null) {
        print("Current user has no email.");
        return;
      }

      final userSnapshot = await FirebaseFirestore.instance
          .collectionGroup('users')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        print("No user document found for email: $userEmail");
        return;
      }

      final userDoc = userSnapshot.docs.first;
      isLocalMunicipality = userDoc.data().containsKey('isLocalMunicipality')
          ? (userDoc['isLocalMunicipality'] as bool? ?? false)
          : false;

      // Common references derived from the user document’s location
      final usersCol = userDoc.reference.parent; // .../users
      final municipalityDoc = usersCol
          .parent!; // .../municipalities/{municipalityId} OR .../localMunicipalities/{municipalityId}
      final containerCol = municipalityDoc
          .parent; // either 'municipalities' or 'localMunicipalities'
      final containerName =
          containerCol.id; // 'municipalities' | 'localMunicipalities'

      if (isLocalMunicipality || containerName == 'localMunicipalities') {
        // LOCAL municipality path: /localMunicipalities/{municipalityId}/...
        municipalityId = municipalityDoc.id;

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
        // DISTRICT municipality path:
        // /districts/{districtId}/municipalities/{municipalityId}/users/{userId}
        // municipalityDoc = .../{municipalityId}
        // municipalityDoc.parent = 'municipalities' collection
        // municipalityDoc.parent.parent = district doc ✅
        final districtDoc = containerCol.parent!; // .../districts/{districtId}
        districtId = districtDoc.id;
        municipalityId = municipalityDoc.id;

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

      // Debug what we resolved
      print('Resolved isLocalMunicipality: $isLocalMunicipality');
      print('Resolved districtId: $districtId');
      print('Resolved municipalityId: $municipalityId');
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
  void _toggleTab() {
    _tabIndex = _tabController.index + 1;
    _tabController.animateTo(_tabIndex);
  }

  TextEditingController controllerDept = TextEditingController();
  bool displayDeptList = false;

  List<String> usersEmails = [];
  int numUsers = 0;
  List<String> deptName = ["Select Department..."];
  String dropdownValue = 'Select Department...';
  int numDept = 0;
  List<String> role = ["Select Role..."];
  List<String> deptRole = ["Select Role..."];
  String dropdownValue2 = 'Select Role...';
  int numRoles = 0;
  List<String> versionList = ["Select Version...", "Unpaid", "Paid", "Premium"];
  String dropdownValue3 = 'Select Version...';
  int numVersion = 0;

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
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 8,
      ),
      child: Row(
        children: [
          Icon(
            iconImg,
            size: 20,
            color: Colors.black,
          ),
          const SizedBox(
            width: 6,
          ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 8,
      ),
      child: Row(
        children: [
          Icon(
            iconImg,
            size: 20,
            color: Colors.black,
          ),
          const SizedBox(
            width: 6,
          ),
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
  }

  ///Firebase auth user creation for officials login details

  Future<void> createAuthUser(String emailReg, String passwordReg) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailReg,
        password: passwordReg,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _create([DocumentSnapshot? documentSnapshot]) async {
    deptRole = deptRole.toSet().toList();

    ///To set clips out all duplicates and leaves only unique items in the array

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
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Create New Official User',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _userNameController,
                      decoration: const InputDecoration(labelText: 'User Name'),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _firstNameController,
                      decoration:
                          const InputDecoration(labelText: 'First Name'),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _deptNameController,
                      decoration:
                          const InputDecoration(labelText: 'User Department'),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: DropdownButtonFormField<String>(
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
                          })
                          .toSet()
                          .toList(),
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
                      decoration: const InputDecoration(labelText: 'User Role'),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: DropdownButtonFormField<String>(
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
                          })
                          .toSet()
                          .toList(),
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
                      decoration:
                          const InputDecoration(labelText: 'User Email'),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _cellNumberController,
                      decoration:
                          const InputDecoration(labelText: 'Phone Number'),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _passwordController,
                      decoration:
                          const InputDecoration(labelText: 'User Password'),
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

                        register(email, password);

                        createAuthUser(email, password);

                        _userNameController.text = '';
                        _deptNameController.text = '';
                        _userRoleController.text = '';
                        _firstNameController.text = '';
                        _lastNameController.text = '';
                        _cellNumberController.text = '';
                        _userEmailController.text = '';
                        dropdownValue = 'Select Department...';
                        dropdownValue2 = 'Select Role...';

                        if (context.mounted) Navigator.of(context).pop();
                      }),
                ],
              ),
            ),
          );
        });
  }

  ///Creation method for details on an official user

  Future<void> _update([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      _userNameController.text = documentSnapshot['userName'] ?? '';
      dropdownValue = (documentSnapshot['deptName'] ?? '').toString();
      dropdownValue2 = (documentSnapshot['userRole'] ?? '').toString();
      _deptNameController.text = dropdownValue;
      _userRoleController.text = dropdownValue2;
      _firstNameController.text = documentSnapshot['firstName'] ?? '';
      _lastNameController.text = documentSnapshot['lastName'] ?? '';
      _userEmailController.text = documentSnapshot['email'] ?? '';
      _cellNumberController.text = documentSnapshot['cellNumber'] ?? '';
    }

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext ctx) {
        // Build UNIQUE lists for dropdowns
        final List<String> deptItems = (deptName
            .map((e) => (e ?? '').toString().trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList())
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

        final List<String> roleItems = (deptRole
            .map((e) => (e ?? '').toString().trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList())
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

        // Ensure current values exist exactly once; otherwise make them null
        final String? safeDeptValue =
            deptItems.contains(dropdownValue) ? dropdownValue : null;
        final String? safeRoleValue =
            roleItems.contains(dropdownValue2) ? dropdownValue2 : null;

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Edit Official Users Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),

                // Username / names
                Visibility(
                  visible: visShow,
                  child: TextField(
                    controller: _userNameController,
                    decoration: const InputDecoration(labelText: 'User Name'),
                  ),
                ),
                Visibility(
                  visible: visShow,
                  child: TextField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                  ),
                ),
                Visibility(
                  visible: visShow,
                  child: TextField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                  ),
                ),

                // Department (TextField version)
                Visibility(
                  visible: visShow,
                  child: TextField(
                    controller: _deptNameController,
                    decoration:
                        const InputDecoration(labelText: 'User Department'),
                  ),
                ),

                // Department (Dropdown version)
                Visibility(
                  visible: visHide,
                  child: DropdownButtonFormField<String>(
                    value: safeDeptValue,
                    items: deptItems
                        .map((value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value,
                                  style: const TextStyle(fontSize: 16)),
                            ))
                        .toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        dropdownValue = newValue ?? '';
                        _deptNameController.text = dropdownValue;
                      });
                    },
                    decoration:
                        const InputDecoration(labelText: 'User Department'),
                  ),
                ),

                // Role (TextField version)
                Visibility(
                  visible: visShow,
                  child: TextField(
                    controller: _userRoleController,
                    decoration: const InputDecoration(labelText: 'User Role'),
                  ),
                ),

                // Role (Dropdown version)
                Visibility(
                  visible: visHide,
                  child: DropdownButtonFormField<String>(
                    value: safeRoleValue,
                    items: roleItems
                        .map((value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value,
                                  style: const TextStyle(fontSize: 16)),
                            ))
                        .toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        dropdownValue2 = newValue ?? '';
                        _userRoleController.text = dropdownValue2;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'User Role'),
                  ),
                ),

                // Email / phone
                Visibility(
                  visible: visShow,
                  child: TextField(
                    controller: _userEmailController,
                    decoration: const InputDecoration(labelText: 'User Email'),
                  ),
                ),
                Visibility(
                  visible: visShow,
                  child: TextField(
                    controller: _cellNumberController,
                    decoration:
                        const InputDecoration(labelText: 'Phone Number'),
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  child: const Text('Update'),
                  onPressed: () async {
                    final String userNameVal = _userNameController.text.trim();
                    final String deptNameVal = _deptNameController.text.trim();
                    final String userRoleVal = _userRoleController.text.trim();
                    final String firstNameVal =
                        _firstNameController.text.trim();
                    final String lastNameVal = _lastNameController.text.trim();
                    final String emailVal = _userEmailController.text.trim();
                    final String cellNumberVal =
                        _cellNumberController.text.trim();
                    const bool officialVal = true;

                    if (userNameVal.isEmpty) return;

                    await _usersList?.doc(documentSnapshot!.id).update({
                      "userName": userNameVal,
                      "deptName": deptNameVal,
                      "userRole": userRoleVal,
                      "firstName": firstNameVal,
                      "lastName": lastNameVal,
                      "email": emailVal,
                      "cellNumber": cellNumberVal,
                      "official": officialVal,
                    });

                    _userNameController.clear();
                    _deptNameController.clear();
                    _userRoleController.clear();
                    _firstNameController.clear();
                    _lastNameController.clear();
                    _userEmailController.clear();
                    _cellNumberController.clear();

                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Link Department to Role',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _deptNameController,
                      decoration:
                          const InputDecoration(labelText: 'Department'),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: DropdownButtonFormField<String>(
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
                          })
                          .toSet()
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          dropdownValue = newValue!;
                        });
                      },
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: DropdownButtonFormField<String>(
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
                          })
                          .toSet()
                          .toList(),
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
                      decoration: const InputDecoration(labelText: 'User Role'),
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

                        await _deptRoles?.add({
                          "deptName": deptName,
                          "userRole": userRole,
                          "official": official,
                        });

                        _deptNameController.text = '';
                        _userRoleController.text = '';
                        dropdownValue = 'Select Department...';
                        dropdownValue2 = 'Select Role...';

                        if (context.mounted) Navigator.of(context).pop();
                      }),
                ],
              ),
            ),
          );
        });
  }

  ///Creation method for department roles

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
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Edit Department Information',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Visibility(
                    visible: visHide,
                    child: TextField(
                      controller: _deptNameController,
                      decoration:
                          const InputDecoration(labelText: 'Department Name'),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: DropdownButtonFormField<String>(
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
                          })
                          .toSet()
                          .toList(),
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
                      decoration: const InputDecoration(labelText: 'User Role'),
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

                        await _deptRoles?.doc(documentSnapshot!.id).update({
                          "deptName": deptName,
                          "userRole": userRole,
                          "official": official,
                        });

                        _deptNameController.text = '';
                        _userRoleController.text = '';

                        if (context.mounted) Navigator.of(context).pop();
                      }),
                ],
              ),
            ),
          );
        });
  }

  Future<void> _deleteDeptRole(String deptID) async {
    await _deptRoles?.doc(deptID).delete();
    Fluttertoast.showToast(
        msg: "You have successfully deleted a department & role!");
  }

  Future<void> _createDept([DocumentSnapshot? documentSnapshot]) async {
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
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Create Department',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _deptNameController,
                      decoration:
                          const InputDecoration(labelText: 'Department'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                      child: const Text('Create'),
                      onPressed: () async {
                        final String departName = _deptNameController.text;
                        const bool official = true;

                        await _deptInfo?.add({
                          "deptName": departName,
                          "official": official,
                        });

                        _deptNameController.text = '';
                        deptName = ["Select Department..."];

                        if (context.mounted) Navigator.of(context).pop();
                      }),
                ],
              ),
            ),
          );
        });
  }

  ///Creation method for departments

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
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Edit Department Information',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _deptNameController,
                      decoration:
                          const InputDecoration(labelText: 'Department Name'),
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

                        await _deptInfo?.doc(documentSnapshot!.id).update({
                          "deptName": deptName,
                          "official": official,
                        });

                        _deptNameController.text = '';

                        if (context.mounted) Navigator.of(context).pop();
                      }),
                ],
              ),
            ),
          );
        });
  }

  Future<void> _deleteDept(String deptID) async {
    await _deptInfo?.doc(deptID).delete();
    Fluttertoast.showToast(
        msg: "You have successfully deleted a department & role!");
  }

  Future<void> _createRole([DocumentSnapshot? documentSnapshot]) async {
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
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Create Role',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _userRoleController,
                      decoration: const InputDecoration(labelText: 'Role'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                      child: const Text('Create'),
                      onPressed: () async {
                        const bool official = true;

                        final String roleName = _userRoleController.text.trim();
                        if (roleName.isEmpty) return;

                        // ✅ write to the correct collection
                        await _roles?.add({"role": roleName});

                        _userRoleController.clear();

                        if (context.mounted) Navigator.of(context).pop();
                      }),
                ],
              ),
            ),
          );
        });
  }

  ///Creation method for departments

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
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Edit Role Information',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _userRoleController,
                      decoration: const InputDecoration(labelText: 'Role'),
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

                        await _roles?.doc(documentSnapshot!.id).update({
                          "role": roleName,
                        });

                        _userRoleController.text = '';

                        if (context.mounted) Navigator.of(context).pop();
                      }),
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
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Create Version',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _versionController,
                      decoration:
                          const InputDecoration(labelText: 'Version Name'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                      child: const Text('Create'),
                      onPressed: () async {
                        final String versionName = _versionController.text;

                        await _deptInfo?.add({
                          "version": versionName,
                        });

                        _versionController.text = '';
                        deptName = ["Select Department..."];

                        if (context.mounted) Navigator.of(context).pop();
                      }),
                ],
              ),
            ),
          );
        });
  }

  ///Creation method for versions

  Future<void> _updateVersion(String newVersion) async {
    final CollectionReference _currentvVersion = FirebaseFirestore.instance
        .collection('version')
        .doc('current')
        .collection('current-version');

    await _currentvVersion.doc('current').update({
      "version": newVersion,
    });

    await _version?.doc('current').update({
      "version": newVersion,
    });

    Fluttertoast.showToast(
        msg: "The app version has been set to $newVersion!",
        gravity: ToastGravity.CENTER);

    dropdownValue3 = 'Select Version...';
  }

  Future<void> _deleteVersion(String versionID) async {
    await _version?.doc(versionID).delete();
    Fluttertoast.showToast(msg: "You have successfully deleted a role!");
  }

  Future<void> countUsersResult() async {
    if (_usersList == null) return;
    final snapshot = await _usersList!.get();
    numUsers = snapshot.size;
    print('users count ::: $numUsers');
  }

  Future<void> countDeptResult() async {
    if (_deptInfo == null) return;
    final snapshot = await _deptInfo!.get();
    numDept = snapshot.size;
    print('depts count ::: $numDept');
  }

  Future<void> countRoleResult() async {
    if (_roles != null) {
      final snap = await _roles!.get();
      numRoles = snap.size;
      print('roles count ::: $numRoles');
    }
  }

  void getDBDept(CollectionReference dept) async {
    dept.get().then((querySnapshot) async {
      for (var result in querySnapshot.docs) {
        print('The department is::: ${result['deptName']}');
        if (deptName.length - 1 < querySnapshot.docs.length) {
          deptName.add(result['deptName']);
        }
        print(deptName);
        print(deptName.length);
      }
    });
  }

  ///Looping department collection

  Future<void> getDBRoles(CollectionReference rolesRef) async {
    try {
      final snap = await rolesRef.get();
      // Extract distinct non-empty role names
      final items = snap.docs
          .map((d) {
            final data = d.data() as Map<String, dynamic>?;
            return (data?['role'] as String?)?.trim() ?? '';
          })
          .where((r) => r.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      if (!mounted) return;
      setState(() {
        // Keep your "Select Role..." at the top
        role = ['Select Role...', ...items];
      });

      print('Roles dropdown items: $role');
    } catch (e) {
      print('Error loading roles for dropdown: $e');
    }
  }

  void getDBDeptRoles(CollectionReference deptRoles) async {
    deptRoles.get().then((querySnapshot) async {
      for (var result in querySnapshot.docs) {
        print('The role is::: ${result['userRole']}');
        if (deptRole.length - 1 < querySnapshot.docs.length) {
          deptRole.add(result['userRole']);
        }
      }
    });
  }

  ///Looping department roles collection

  void getDBUsers(CollectionReference users) async {
    try {
      // Fetch users from Firestore and process them
      final querySnapshot = await users.get();
      for (var result in querySnapshot.docs) {
        print('The user email is::: ${result['email']}');
        if (result['email'].contains('@') &&
            usersEmails.length - 1 < querySnapshot.docs.length) {
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
    if (_usersList == null ||
        _deptInfo == null ||
        _roles == null ||
        _deptRoles == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return DefaultTabController(
      initialIndex: 0,
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[350],
        appBar: AppBar(
          title: const Text(
            'Department and Officials',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            controller: _tabController,
            tabs: const [
              Tab(
                text: 'Roles',
                icon: FaIcon(Icons.work_history),
              ),
              Tab(
                text: 'Depts',
                icon: FaIcon(Icons.corporate_fare),
              ),
              Tab(
                text: 'User List',
                icon: FaIcon(Icons.person_2_outlined),
              ),
              // Tab(
              //   text: 'Version',
              //   icon: FaIcon(Icons.lock_open_outlined),
              // ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            // --- ROLES TAB ---
            StreamBuilder<QuerySnapshot>(
              // if _roles is still null, show a loader until fetchUserDetails() sets it
              stream: _roles?.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (_roles == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  // Empty state so the tab isn’t just blank
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No roles found.'),
                        const SizedBox(height: 8),
                        Text(
                          'Path: ${_roles?.path ?? '(uninitialised)'}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                print('roles path => ${_roles?.path}');
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final DocumentSnapshot roleDoc = docs[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'Staff Roles List',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 20),
                            adminUserField(
                              Icons.business_center_outlined,
                              "Role: ${roleDoc['role']}",
                            ),
                            const SizedBox(height: 20),
                            Visibility(
                              visible: visShow,
                              child: Center(
                                child: Column(
                                  children: [
                                    // Delete
                                    Material(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                      child: InkWell(
                                        onTap: () {
                                          showDialog(
                                            barrierDismissible: false,
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                shape:
                                                    const RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(16)),
                                                ),
                                                title: const Text(
                                                    "Delete this role!"),
                                                content: const Text(
                                                    "Are you sure about deleting this role?"),
                                                actions: [
                                                  IconButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(),
                                                    icon: const Icon(
                                                        Icons.cancel,
                                                        color: Colors.red),
                                                  ),
                                                  IconButton(
                                                    onPressed: () {
                                                      _deleteRole(roleDoc.id);
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    icon: const Icon(Icons.done,
                                                        color: Colors.green),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(32),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 10),
                                          child: Text(
                                            "  Delete Role  ",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Edit
                                    Material(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(8),
                                      child: InkWell(
                                        onTap: () => _updateRole(roleDoc),
                                        borderRadius: BorderRadius.circular(32),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 10),
                                          child: Text(
                                            "Edit Role",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            StreamBuilder(
              stream: _deptInfo?.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                if (streamSnapshot.hasData) {
                  return ListView.builder(
                    itemCount: streamSnapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final DocumentSnapshot deptDocumentSnapshot =
                          streamSnapshot.data!.docs[index];

                      if (streamSnapshot.data!.docs[index]['official'] ==
                          true) {
                        return Card(
                          margin: const EdgeInsets.only(
                              left: 10, right: 10, top: 5, bottom: 5),
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(
                                  height: 15,
                                ),
                                departmentField(
                                  Icons.business,
                                  "Department: ${deptDocumentSnapshot['deptName']}",
                                ),
                                const SizedBox(
                                  height: 15,
                                ),
                                Visibility(
                                  visible: visShow,
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Center(
                                            child: Material(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: InkWell(
                                            onTap: () {
                                              showDialog(
                                                  barrierDismissible: false,
                                                  context: context,
                                                  builder: (context) {
                                                    return AlertDialog(
                                                      shape: const RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          16))),
                                                      title: const Text(
                                                          "Delete this Department!"),
                                                      content: const Text(
                                                          "Are you sure about deleting this Department?"),
                                                      actions: [
                                                        IconButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          icon: const Icon(
                                                            Icons.cancel,
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                        IconButton(
                                                          onPressed: () {
                                                            String deleteDept =
                                                                deptDocumentSnapshot
                                                                    .reference
                                                                    .id;
                                                            deptName.remove(
                                                                deptDocumentSnapshot[
                                                                    'deptName']);
                                                            _deleteDept(
                                                                deleteDept);
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
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
                                            borderRadius:
                                                BorderRadius.circular(32),
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
                                        )),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Center(
                                            child: Material(
                                          color: Colors.green,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: InkWell(
                                            onTap: () {
                                              _updateDept(deptDocumentSnapshot);
                                            },
                                            borderRadius:
                                                BorderRadius.circular(32),
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
                                        )),
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
            ),

            ///Tab for department list view

            StreamBuilder(
              stream: _usersList
                  ?.orderBy('deptName', descending: false)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                if (streamSnapshot.hasData) {
                  return ListView.builder(
                    itemCount: streamSnapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final DocumentSnapshot userDocumentSnapshot =
                          streamSnapshot.data!.docs[index];

                      if (streamSnapshot.data!.docs[index]['official'] ==
                          true) {
                        return Card(
                          margin: const EdgeInsets.only(
                              left: 10, right: 10, top: 5, bottom: 5),
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                adminUserField(Icons.switch_account,
                                    "User Name: ${userDocumentSnapshot['userName']}"),
                                adminUserField(Icons.business_center,
                                    "Department: ${userDocumentSnapshot['deptName']}"),
                                adminUserField(Icons.business_center,
                                    "Role: ${userDocumentSnapshot['userRole']}"),
                                adminUserField(Icons.account_circle,
                                    "First Name: ${userDocumentSnapshot['firstName']}"),
                                adminUserField(Icons.account_circle,
                                    "Last Name: ${userDocumentSnapshot['lastName']}"),
                                adminUserField(Icons.email,
                                    "Email: ${userDocumentSnapshot['email']}"),
                                adminUserField(Icons.phone,
                                    "Phone Number: ${userDocumentSnapshot['cellNumber']}"),
                                const SizedBox(
                                  height: 20,
                                ),
                                Visibility(
                                  visible: visShow,
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Center(
                                            child: Material(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: InkWell(
                                            onTap: () {
                                              showDialog(
                                                  barrierDismissible: false,
                                                  context: context,
                                                  builder: (context) {
                                                    return AlertDialog(
                                                      shape: const RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          16))),
                                                      title: const Text(
                                                          "Delete this User!"),
                                                      content: const Text(
                                                          "Are you sure about deleting this user?"),
                                                      actions: [
                                                        IconButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          icon: const Icon(
                                                            Icons.cancel,
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                        IconButton(
                                                          onPressed: () {
                                                            String deleteUser =
                                                                userDocumentSnapshot
                                                                    .id;
                                                            _delete(deleteUser);
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
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
                                            borderRadius:
                                                BorderRadius.circular(32),
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
                                        )),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Center(
                                            child: Material(
                                          color: Colors.green,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: InkWell(
                                            onTap: () {
                                              _update(userDocumentSnapshot);
                                            },
                                            borderRadius:
                                                BorderRadius.circular(32),
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
                                        )),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 0,
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
            ),

            ///Tab for users list view

            // Column(
            //   children: [
            //     Visibility(
            //       visible: visShow,
            //       child: SingleChildScrollView(
            //         child: Card(
            //           child: Column(
            //             children: [
            //               const SizedBox(
            //                 height: 20,
            //               ),
            //               const Center(
            //                 child: Text(
            //                   'Set Application Version State',
            //                   style: TextStyle(
            //                       fontSize: 19, fontWeight: FontWeight.w700),
            //                 ),
            //               ),
            //               const SizedBox(
            //                 height: 20,
            //               ),
            //               Center(
            //                 child: Column(children: [
            //                   SizedBox(
            //                     width: 450,
            //                     height: 50,
            //                     child: Padding(
            //                       padding: const EdgeInsets.only(
            //                           left: 10, right: 10),
            //                       child: Center(
            //                         child: TextField(
            //                           ///Input decoration here had to be manual because dropdown button uses suffix icon of the textfield
            //                           decoration: InputDecoration(
            //                             border: OutlineInputBorder(
            //                                 borderRadius:
            //                                     BorderRadius.circular(30),
            //                                 borderSide: const BorderSide(
            //                                   color: Colors.grey,
            //                                 )),
            //                             enabledBorder: OutlineInputBorder(
            //                                 borderRadius:
            //                                     BorderRadius.circular(30),
            //                                 borderSide: const BorderSide(
            //                                   color: Colors.grey,
            //                                 )),
            //                             focusedBorder: OutlineInputBorder(
            //                                 borderRadius:
            //                                     BorderRadius.circular(30),
            //                                 borderSide: const BorderSide(
            //                                   color: Colors.grey,
            //                                 )),
            //                             disabledBorder: OutlineInputBorder(
            //                                 borderRadius:
            //                                     BorderRadius.circular(30),
            //                                 borderSide: const BorderSide(
            //                                   color: Colors.grey,
            //                                 )),
            //                             contentPadding:
            //                                 const EdgeInsets.symmetric(
            //                                     horizontal: 14, vertical: 6),
            //                             fillColor: Colors.white,
            //                             filled: true,
            //                             suffixIcon:
            //                                 DropdownButtonFormField<String>(
            //                               value: dropdownValue3,
            //                               items: versionList
            //                                   .map<DropdownMenuItem<String>>(
            //                                       (String value) {
            //                                     return DropdownMenuItem<String>(
            //                                       value: value,
            //                                       child: Padding(
            //                                         padding: const EdgeInsets
            //                                             .symmetric(
            //                                             vertical: 0.0,
            //                                             horizontal: 20.0),
            //                                         child: Text(
            //                                           value,
            //                                           style: const TextStyle(
            //                                               fontSize: 16),
            //                                         ),
            //                                       ),
            //                                     );
            //                                   })
            //                                   .toSet()
            //                                   .toList(),
            //                               onChanged: (String? newValue) {
            //                                 setState(() {
            //                                   dropdownValue3 = newValue!;
            //                                 });
            //                               },
            //                               icon: const Padding(
            //                                 padding: EdgeInsets.only(
            //                                     left: 10, right: 10),
            //                                 child: Icon(
            //                                     Icons.arrow_circle_down_sharp),
            //                               ),
            //                               iconEnabledColor: Colors.green,
            //                               style: const TextStyle(
            //                                   color: Colors.black,
            //                                   fontSize: 18),
            //                               dropdownColor: Colors.grey[50],
            //                               isExpanded: true,
            //                             ),
            //                           ),
            //                         ),
            //                       ),
            //                     ),
            //                   ),
            //                   const SizedBox(
            //                     height: 20,
            //                   ),
            //
            //                   // Text(
            //                   //   'Current App Version: ${versions[2]}',
            //                   //   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
            //                   // ),
            //
            //                   const SizedBox(
            //                     height: 20,
            //                   ),
            //                   Center(
            //                       child: BasicIconButtonGrey(
            //                     onPress: () {
            //                       String selectedVersionChange;
            //                       if (dropdownValue3 != 'Select Version...') {
            //                         selectedVersionChange = dropdownValue3;
            //                         _updateVersion(selectedVersionChange);
            //                       }
            //                     },
            //                     labelText: 'Set App Version',
            //                     fSize: 16,
            //                     faIcon: const FaIcon(Icons.monetization_on),
            //                     fgColor: Colors.green,
            //                     btSize: const Size(100, 50),
            //                   )),
            //
            //                   const SizedBox(
            //                     height: 20,
            //                   ),
            //                 ]),
            //               ),
            //             ],
            //           ),
            //         ),
            //       ),
            //     ),
            //   ],
            // ),

            ///Tab for version control
          ],
        ),
        floatingActionButton: Row(
          children: [
            const SizedBox(
              width: 10,
            ),
            Visibility(
              visible: visShow,
              child: FloatingActionButton(
                heroTag: 'roleFab', // Unique hero tag
                onPressed: () => _createRole(),
                backgroundColor: Colors.green,
                child: const Icon(Icons.add_moderator),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            FloatingActionButton(
              heroTag: 'deptFab', // Unique hero tag
              onPressed: () => _createDept(),
              backgroundColor: Colors.green,
              child: const Icon(Icons.business),
            ),
            const SizedBox(
              width: 10,
            ),
            FloatingActionButton(
              heroTag: 'deptRolesFab', // Unique hero tag
              onPressed: () => _createDeptRoles(),
              backgroundColor: Colors.green,
              child: const Icon(Icons.add_business),
            ),
            const SizedBox(
              width: 10,
            ),
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
