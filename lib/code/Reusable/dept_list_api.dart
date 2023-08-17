import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

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

  String? valueFromFirebase;
  Future<String?> getData() async{
    var a = await deptDBRetrieveCol.doc('deptName').get();
    // setState((){
    //   valueFromFirebase = a['deptName'];
    // });
  }

  final CollectionReference deptDBRetrieveCol =
  FirebaseFirestore.instance.collection('departments');

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
    return FutureBuilder<List<DeptDBRetrieve>>(
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
                subtitle: Text(dept[index].official ? 'official' : 'Pending'),
              );
            },
          );
        }
      },
    );
  }
}
