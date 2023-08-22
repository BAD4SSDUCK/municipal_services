import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:municipal_tracker_msunduzi/code/PDFViewer/view_pdf.dart';
import 'package:municipal_tracker_msunduzi/code/ApiConnection/api_connection.dart';
import 'package:municipal_tracker_msunduzi/code/SQLApp/pdfview/view_pdf_sql.dart';

import '../propertiesData/properties_data.dart';
import '../userPreferences/current_user.dart';


class pdfSelectionPage extends StatefulWidget {
  const pdfSelectionPage({Key? key}) : super(key: key);

  @override
  State<pdfSelectionPage> createState() => _pdfSelectionPageState();
}

class _pdfSelectionPageState extends State<pdfSelectionPage> {

  bool loading = true;
  late List pdfList;
  late String accNumber;

  final CurrentUser _currentUser = Get.put(CurrentUser());
  final PropertiesData _propertiesData = Get.put(PropertiesData());

  Future fetchAllPdf() async{
    final response = await http.get(Uri.parse(API.pdfDBList));
    if (response.statusCode==200){
      setState((){
        pdfList = jsonDecode(response.body);
        loading = false;
      });
      print(pdfList);
    }
  }

  Future fetchAccPdf() async {
    final response = await http.get(Uri.parse(API.pdfDBList));
    if (_currentUser.user.uid == _propertiesData.properties.uid) {
      if (pdfList.contains(_propertiesData.properties.accountNumber)) {
        if (response.statusCode == 200) {
          setState(() {
            pdfList = jsonDecode(response.body);
            loading = false;
          });
          print('Current user statement for account number $pdfList');
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    //fetchAllPdf();
    fetchAccPdf();
    Fluttertoast.showToast(msg: "Pick the statement you wish the view!", gravity: ToastGravity.CENTER);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Statement"),
        backgroundColor: Colors.green,),
      backgroundColor: Colors.grey[350],
      body: loading
          ? Center(child: CircularProgressIndicator(),)
          : ListView.builder(
          itemCount: pdfList.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: IconButton(icon: Icon(Icons.picture_as_pdf),
                onPressed: () {
                  Fluttertoast.showToast(msg: "Now downloading your statement!\nPlease wait a few seconds!",
                      gravity: ToastGravity.CENTER,);
                  Navigator.push(context,
                    MaterialPageRoute(builder: (context) =>
                        PDFViewPage(url: API.hostConnect+"/pdf/"+pdfList[index]["pdfFile"],
                          name: pdfList[index]["name"],),),);
                },),
              title: Text(pdfList[index]["name"]),
            );
          }),
    );
  }

  ///pdf view loader getting file name onPress/onTap that passes filename to this class
  void openPDF(BuildContext context, File file) => Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
  );

}
