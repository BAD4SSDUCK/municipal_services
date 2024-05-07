import 'dart:convert';

import 'package:municipal_services/code/SQLApp/model/meter_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:municipal_services/code/SQLApp/propertiesData/image_preferences.dart';

///This is the class that saves the property information to local storage

class RememberImageInfo{

  //save-remember property-info
  static Future<void> storeImageInfo(MeterImage meterImage) async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String imageJsonData = jsonEncode(meterImage.toJson());
    await preferences.setString("meterImage", imageJsonData);
  }

  //This keeps the local data of the properties locally so that a property does not have to reload everytime they open the app

  //get-read property-info
  static Future<MeterImage?> readImageInfo() async{
    MeterImage? currentImageInfo;
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? imageInfo = preferences.getString("meterImage");
    if(imageInfo != null){
      Map<String, dynamic> imageDataMap = jsonDecode(imageInfo);
      currentImageInfo = MeterImage.fromJson(imageDataMap);
    }
    return currentImageInfo;
  }

  //removing the app local storage/cache so the property data is removed
  static Future<void> removeImageInfo() async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove("meterImage");

  }

}
