import 'dart:convert';

import 'package:municipal_track/code/SQLApp/model/fault_report.dart';
import 'package:shared_preferences/shared_preferences.dart';

///This is the class that saves the property information to local storage

class RememberFaultInfo{

  //save-remember property-info
  static Future<void> storeFaultInfo(Fault faultInfo) async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String faultJsonData = jsonEncode(faultInfo.toJson());
    await preferences.setString("id", faultJsonData);
  }

  //This keeps the local data of the properties locally so that a property does not have to reload everytime they open the app

  //get-read property-info
  static Future<Fault?> readFaultInfo() async{
    Fault? currentFaultInfo;
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? faultInfo = preferences.getString("id");
    if(faultInfo != null){
      Map<String, dynamic> faultDataMap = jsonDecode(faultInfo);
      currentFaultInfo = Fault.fromJson(faultDataMap);
    }
    return currentFaultInfo;
  }

  //removing the app local storage/cache so the property data is removed
  static Future<void> removeFaultInfo() async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove("id");

  }

}
