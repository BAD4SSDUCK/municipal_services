import 'dart:convert';

import 'package:municipal_tracker_msunduzi/code/SQLApp/model/property.dart';
import 'package:shared_preferences/shared_preferences.dart';

///This is the class that saves the property information to local storage

class RememberPropertyInfo{

  //save-remember property-info
  static Future<void> storePropertyInfo(Property propertyInfo) async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String propertyJsonData = jsonEncode(propertyInfo.toJson());
    await preferences.setString("currentProperty", propertyJsonData);
  }

  //This keeps the local data of the properties locally so that a property does not have to reload everytime they open the app

  //get-read property-info
  static Future<Property?> readPropertyInfo() async{
    Property? currentPropertyInfo;
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? propertyInfo = preferences.getString("currentProperty");
    if(propertyInfo != null){
      Map<String, dynamic> propertyDataMap = jsonDecode(propertyInfo);
      currentPropertyInfo = Property.fromJson(propertyDataMap);
    }
    return currentPropertyInfo;
  }

  //removing the app local storage/cache so the property data is removed
  static Future<void> removePropertyInfo() async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove("currentProperty");

  }

}
