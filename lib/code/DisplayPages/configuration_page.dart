import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:municipal_track/code/AuthGoogle/auth_page_google.dart';
import 'package:municipal_track/code/DisplayPages/display_info.dart';

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
  final _userRoleController = TextEditingController();
  final _userNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _userEmailController = TextEditingController();
  final _cellNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  late String _deptListController = DropdownMenuItem as String;

  TextEditingController controllerDept = TextEditingController();
  List<String> deptName =[""];
  bool displayDeptList = false;

  final _formKey = GlobalKey<FormState>();
  late List<String> deptSelection = [];
  late String _currentSelectedDept;

  final CollectionReference _usersList =
  FirebaseFirestore.instance.collection('users');

  final CollectionReference _deptInfo =
  FirebaseFirestore.instance.collection('departments');

  final CollectionReference _deptRoles =
  FirebaseFirestore.instance.collection('departmentRoles');

  String selectedDept = "0";
  String selectedRole = "0";

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
    _deptNameController.text = '';
    _userRoleController.text = '';
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

                  ///Need to work on drop down menu with information
                  // Visibility(
                  //   visible: true,
                  //   child: SizedBox(
                  //     width: 180,
                  //     height: 100,
                  //     child: Text(
                  //         DeptWidget().deptRepository.deptDBRetrieveRef.toString()),
                  //   ),
                  // ),
                  ///Need to work on drop down menu with information
                  // Visibility(
                  //   visible: visShow,
                  //     child: SizedBox(
                  //       width: 200,//double.infinity,//10
                  //       height: 180,//double.infinity,//10
                  //       child: Column(
                  //         crossAxisAlignment: CrossAxisAlignment.center,
                  //         children: [
                  //           const Text('User Department'),
                  //           // const SizedBox(height: 200,),
                  //           Container(
                  //             width: 300,
                  //             height: 50,
                  //             decoration: BoxDecoration(
                  //               border: Border.all(color: Colors.grey),
                  //               color: Colors.white,
                  //               borderRadius: BorderRadius.circular(6),
                  //             ),
                  //             child: TextField(
                  //               controller: controllerDept,
                  //               decoration: InputDecoration(
                  //                 border: InputBorder.none,
                  //                 suffixIcon: GestureDetector(
                  //                     onTap: (){
                  //                       displayDeptList = !displayDeptList;
                  //                     },
                  //                     child: Icon(Icons.arrow_downward),
                  //                 ),
                  //               ),
                  //             ),
                  //           ),
                  //           displayDeptList?
                  //           Container(
                  //             height: 200,
                  //             width: 130,
                  //             decoration: BoxDecoration(
                  //               borderRadius: BorderRadius.circular(9),
                  //               color: Colors.white,
                  //               boxShadow: [
                  //                 BoxShadow(
                  //                   color: Colors.grey.withOpacity(0.3),
                  //                   spreadRadius: 1,
                  //                   blurRadius: 3,
                  //                   offset: Offset(0,1),
                  //                 )
                  //               ]),
                  //             child: ListView.builder(
                  //               itemCount: deptName.length,
                  //                 itemBuilder: ((context,index){
                  //               return GestureDetector(
                  //                 onTap: (){
                  //                   setState(() {
                  //                     deptSelection.add(DeptWidget().deptRepository.deptDBRetrieveRef.get().toString());
                  //                     controllerDept.text = (index+1).toString();
                  //                     _deptNameController.text = deptSelection[index].toString();
                  //                   });
                  //                 },
                  //                 child: ListTile(
                  //                   title: Text(deptName[index]),
                  //                 ),
                  //               );
                  //             })),
                  //           ):const SizedBox(),
                  //         ],
                  //       ),
                  //     )
                  // ),


                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _userRoleController,
                      decoration: const InputDecoration(
                          labelText: 'User Role'),
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
                        final String deptName = _deptNameController.text;
                        final String userRole = _userRoleController.text;
                        final String firstName = _firstNameController.text;
                        final String lastName = _lastNameController.text;
                        final String email = _userEmailController.text;
                        final String cellNumber = _cellNumberController.text;
                        final String password = _passwordController.text;
                        const bool official = true;

                        if (userName != null) {
                          await _usersList.add({
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

                          _userNameController.text = '';
                          _deptNameController.text = '';
                          _userRoleController.text = '';
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

                  // Visibility(
                  //   visible: false,
                  //   child: Text(
                  //       DeptWidget().deptRepository.deptDBRetrieveRef.toString()),
                  // ),
                  // ///Need to work on drop down menu with information
                  // Visibility(
                  //     visible: visShow,
                  //     child: SizedBox(
                  //       width: double.infinity,
                  //       height: double.infinity,
                  //       child: Column(
                  //         crossAxisAlignment: CrossAxisAlignment.center,
                  //         children: [
                  //           const Text('Department'),
                  //           // const SizedBox(height: 200,),
                  //           Container(
                  //             width: 130,
                  //             height: 50,
                  //             decoration: BoxDecoration(
                  //               border: Border.all(color: Colors.grey),
                  //               color: Colors.white,
                  //               borderRadius: BorderRadius.circular(6),
                  //             ),
                  //             child: TextField(
                  //               controller: controllerDept,
                  //               decoration: InputDecoration(
                  //                 border: InputBorder.none,
                  //                 suffixIcon: GestureDetector(
                  //                   onTap: (){
                  //                     displayDeptList = !displayDeptList;
                  //                   },
                  //                   child: Icon(Icons.arrow_downward),
                  //                 ),
                  //               ),
                  //             ),
                  //           ),
                  //           displayDeptList?
                  //           Container(
                  //             height: 200,
                  //             width: 130,
                  //             decoration: BoxDecoration(
                  //                 borderRadius: BorderRadius.circular(9),
                  //                 color: Colors.white,
                  //                 boxShadow: [
                  //                   BoxShadow(
                  //                     color: Colors.grey.withOpacity(0.3),
                  //                     spreadRadius: 1,
                  //                     blurRadius: 3,
                  //                     offset: Offset(0,1),
                  //                   )
                  //                 ]),
                  //             child: ListView.builder(
                  //                 itemCount: deptName.length,
                  //                 itemBuilder: ((context,index){
                  //                   return GestureDetector(
                  //                     onTap: (){
                  //                       setState(() {
                  //                         deptSelection: DeptWidget().deptRepository.deptDBRetrieveRef.toString();
                  //                         controllerDept.text = (index+1).toString();
                  //                         _deptNameController.text = deptSelection[index].toString();
                  //                       });
                  //                     },
                  //                     child: ListTile(
                  //                       title: Text(deptName[index]),
                  //                     ),
                  //                   );
                  //                 })),
                  //           ):const SizedBox(),
                  //         ],
                  //       ),
                  //     )
                  // ),

                  Visibility(
                    visible: visShow,
                    child: TextField(
                      controller: _userRoleController,
                      decoration: const InputDecoration(
                          labelText: 'User Role'),
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
                              .doc(documentSnapshot!.id)
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
                          _userRoleController.text = '';
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
                        final String deptName = _deptNameController.text;
                        final String userRole = _userRoleController.text;
                        const bool official = true;

                        if (deptName != null) {
                          await _deptRoles.add({
                            "deptName": deptName,
                            "userRole": userRole,
                            "official": official,
                          });

                          _deptNameController.text = '';
                          _userRoleController.text = '';

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

  Future<void> _updateDeptRoles([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      _deptNameController.text = documentSnapshot['deptName'];
      _userRoleController.text = documentSnapshot['userRole'];
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
                        final String deptName = _deptNameController.text;
                        final String userRole = _userRoleController.text;
                        const bool official = true;

                        if (deptName != null) {
                          await _deptRoles
                              .doc(documentSnapshot!.id)
                              .update({
                            "deptName": deptName,
                            "userRole": userRole,
                            "official": official,
                          });

                          _deptNameController.text = '';
                          _userRoleController.text = '';

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

  Future<void> _deleteDeptRole(String deptID) async {
    await _deptInfo.doc(deptID).delete();
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
                        final String deptName = _deptNameController.text;
                        const bool official = true;

                        if (deptName != null) {
                          await _deptInfo.add({
                            "deptName": deptName,
                            "official": official,
                          });

                          _deptNameController.text = '';

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
                              .doc(documentSnapshot!.id)
                              .update({
                            "deptName": deptName,
                            "official": official,
                          });

                          _deptNameController.text = '';

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

  Future<void> _deleteDept(String deptID) async {
    await _deptInfo.doc(deptID).delete();
    Fluttertoast.showToast(msg: "You have successfully deleted a department & role!");
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[350],
        appBar: AppBar(
          title: const Text('Department and Officials'),
          backgroundColor: Colors.green,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Departments'),
              Tab(text: 'Roles List'),
              Tab(text: 'Official User List'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ///Tab for department list view
            StreamBuilder(
              stream: _deptRoles.snapshots(),
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
                                                                  _deleteDept(deleteDept);

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
                                                    "  Edit Dept. Name  ",
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
            ),

            ///Tab for department roles
            StreamBuilder(
              stream: _deptRoles.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                if (streamSnapshot.hasData) {
                  return ListView.builder(
                    itemCount: streamSnapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final DocumentSnapshot deptDocumentSnapshot = streamSnapshot.data!.docs[index];
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
                                  "Department: ${deptDocumentSnapshot['deptName']}",),
                                departmentField(
                                  Icons.account_circle_outlined,
                                  "Role: ${deptDocumentSnapshot['userRole']}",),
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
                                                            title: const Text("Delete this Role & Department!"),
                                                            content: const Text(
                                                                "Are you sure about deleting this Role linked to the Department associated with it?"),
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
                                                                  _deleteDeptRole(deleteDept);
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
                                                  _updateDeptRoles(deptDocumentSnapshot);
                                                },
                                                borderRadius: BorderRadius.circular(
                                                    32),
                                                child: const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 10,
                                                  ),
                                                  child: Text(
                                                    "Edit Role Info",
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
            ),

            ///Tab for users list view
            StreamBuilder(
              stream: _usersList.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                if (streamSnapshot.hasData) {
                  return ListView.builder(
                    itemCount: streamSnapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final DocumentSnapshot userDocumentSnapshot = streamSnapshot.data!.docs[index];
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
            ),
          ],
        ),

        floatingActionButton: Row(
          children: [
            const SizedBox(width: 10,),
            FloatingActionButton(
              onPressed: () => _createDept(),
              backgroundColor: Colors.green,
              child: const Icon(Icons.business),
            ),
            const SizedBox(width: 10,),
            FloatingActionButton(
              onPressed: () => _createDeptRoles(),
              backgroundColor: Colors.green,
              child: const Icon(Icons.add_business),
            ),
            const SizedBox(width: 10,),
            FloatingActionButton(
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

class DeptDBRetrieve{
  String id;
  String deptName;
  bool official;

  DeptDBRetrieve({
    required this.id,
    required this.deptName,
    required this.official,
  });
}

class DeptRoleDBRetrieve{
  String id;
  String deptName;
  String userRole;
  bool official;

  DeptRoleDBRetrieve({
    required this.id,
    required this.deptName,
    required this.userRole,
    required this.official,
  });
}

class DeptRepository {
  final DatabaseReference deptDBRetrieveRef =
  FirebaseDatabase.instance.ref().child('departments');

  Future<List<DeptDBRetrieve>> fetchDept() async {
    final DatabaseEvent event = await deptDBRetrieveRef.once();
    final DataSnapshot deptSnapshot = event.snapshot;
    final dynamic data = deptSnapshot.value;
    final List<DeptDBRetrieve> deptList = [];

    if (data != null) {
      data.forEach((key, value) {
        deptList.add(
          DeptDBRetrieve(
            id: key,
            deptName: value['deptName'],
            official: value['official'],
          ),
        );
      });
    }
    return deptList;
  }
}

class DeptWidget extends StatelessWidget {
  final DeptRepository deptRepository = DeptRepository();

  DeptWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FutureBuilder<List<DeptDBRetrieve>>(
        future: deptRepository.fetchDept(),
        builder: (BuildContext context, AsyncSnapshot<List<DeptDBRetrieve>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            final List<DeptDBRetrieve> dept = snapshot.data!;
            // Use the todos list to build your UI
            return ListView.builder(
              itemCount: dept.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(dept[index].deptName),
                  // subtitle: Text(dept[index].official ? 'official' : 'Pending'),
                );
              },
            );
          }
        },
      ),
    );
  }
}
