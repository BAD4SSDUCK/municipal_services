import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class UsersTableViewPage extends StatefulWidget {
  const UsersTableViewPage({Key? key}) : super(key: key);

  @override
  _UsersTableViewPageState createState() => _UsersTableViewPageState();
}

class _UsersTableViewPageState extends State<UsersTableViewPage> {
// text fields' controllers

  final _accountNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaCodeController = TextEditingController();
  final _meterNumberController = TextEditingController();
  final _cellNumberController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idNumberController = TextEditingController();

  final CollectionReference _userList =
  FirebaseFirestore.instance.collection('users');

  Future<void> _create([DocumentSnapshot? documentSnapshot]) async {

    _accountNumberController.text = '';
    _addressController.text = '';
    _areaCodeController.text = '';
    _meterNumberController.text = '';
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
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
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
                    decoration: const InputDecoration(
                      labelText: 'Area Code',
                    ),
                  ),
                  TextField(
                    controller: _meterNumberController,
                    decoration: const InputDecoration(labelText: 'Meter Number'),
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
                      final String accountNumber =_accountNumberController.text;
                      final String address =_addressController.text;
                      final String areaCode =_areaCodeController.text;
                      final String meterNumber =_meterNumberController.text;
                      final String cellNumber = _cellNumberController.text;
                      final String firstName = _firstNameController.text;
                      final String lastName =_lastNameController.text;
                      final String idNumber =_idNumberController.text;
                      if (accountNumber != null) {
                        await _userList.add({"account number": accountNumber, "address": address, "area code": areaCode , "meter number": meterNumber, "cell number": cellNumber, "first name": firstName, "last name": lastName, "id number": idNumber});

                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _areaCodeController.text = '';
                        _meterNumberController.text = '';
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
  Future<void> _update([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      _accountNumberController.text = documentSnapshot['account number'];
      _addressController.text = documentSnapshot['address'];
      _areaCodeController.text = documentSnapshot['area code'].toString();
      _meterNumberController.text = documentSnapshot['meter number'];
      _cellNumberController.text = documentSnapshot['cell number'];
      _firstNameController.text = documentSnapshot['first name'];
      _lastNameController.text = documentSnapshot['last name'];
      _idNumberController.text = documentSnapshot['id number'];
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
                    decoration: const InputDecoration(
                      labelText: 'Area Code',
                    ),
                  ),
                  TextField(
                    controller: _meterNumberController,
                    decoration: const InputDecoration(labelText: 'Meter Number'),
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
                    child: const Text( 'Update'),
                    onPressed: () async {

                      final String accountNumber = _accountNumberController.text;
                      final String address = _addressController.text;
                      final int areaCode = int.parse(_areaCodeController.text);
                      final String meterNumber = _meterNumberController.text;
                      final String cellNumber = _cellNumberController.text;
                      final String firstName = _firstNameController.text;
                      final String lastName = _lastNameController.text;
                      final String idNumber = _idNumberController.text;

                      if (accountNumber != null) {
                        await _userList
                            .doc(documentSnapshot!.id)
                            .update({"account number": accountNumber,"address": address, "area code": areaCode, "meter number": meterNumber, "cell number": cellNumber,
                          "first name": firstName, "last name": lastName, "id number": idNumber });

                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _areaCodeController.text = '';
                        _meterNumberController.text = '';
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
                itemCount: streamSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final DocumentSnapshot documentSnapshot =
                  streamSnapshot.data!.docs[index];

                  ///this card is to display all details for users
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Number: '+
                            documentSnapshot['account number'],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'Street Address: '+
                            documentSnapshot['address'],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'Area Code: '+
                            documentSnapshot['area code'].toString(),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'Meter Number: '+
                            documentSnapshot['meter number'],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'Phone Number: '+
                            documentSnapshot['cell number'],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'First Name: '+
                            documentSnapshot['first name'],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'Surname: '+
                            documentSnapshot['last name'],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'ID Number: '+
                            documentSnapshot['id number'],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5,),
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
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                              // const SizedBox(width: 6,),
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

                    ///this listtile is to display just two fields per person
                    // child: ListTile(
                    //   title: Text(documentSnapshot['first name']),
                    //   subtitle: Text(documentSnapshot['account number'].toString()),
                    //   trailing: SizedBox(
                    //     width: 50,
                    //     child: Row(
                    //       children: [
                    //         // IconButton(
                    //         //     icon: const Icon(Icons.edit),
                    //         //     onPressed: () =>
                    //         //         _update(documentSnapshot)),
                    //         IconButton(
                    //             icon: const Icon(Icons.supervised_user_circle),
                    //             onPressed: () {
                    //
                    //             },
                    //         )
                    //       ],
                    //     ),
                    //   ),
                    // ),
                  );
                },
              );
            }

            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
// Add new product
//         floatingActionButton: FloatingActionButton(
//           onPressed: () => _create(),
//           child: const Icon(Icons.add),
//
//         ),
//         floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat
    );
  }
}