import 'package:municipal_track/code/SQLApp/model/user.dart';
import 'package:municipal_track/code/SQLApp/userPreferences/user_preferences.dart';

import 'package:get/get.dart';
import 'dart:io';

import 'package:municipal_track/code/SQLApp/model/meter_image.dart';
import 'package:municipal_track/code/SQLApp/propertiesData/image_preferences.dart';


///This is the controller using getx for the information on the mySql

class ImageData extends GetxController {

  MultipartFile elecMeterImage = File('') as MultipartFile;
  MultipartFile waterMeterImage = File('') as MultipartFile;

  Rx<MeterImage> _imageData = MeterImage(0, 0, '', elecMeterImage, waterMeterImage, DateTime.now()).obs;
  MeterImage get meterImageData => _imageData.value;

  Rx<User> _currentUser = User(0,'', '', '', '', '', '').obs;
  User get user => _currentUser.value;
  getUserInfo() async {
    User? getUserInfoFromLocalStorage = await RememberUserPrefs.readUserInfo();
    _currentUser.value = getUserInfoFromLocalStorage!;
  }

  getImageInfo() async {
    if(_currentUser.value.uid == _imageData.value.uid) {
      MeterImage? getImageInfoFromLocalStorage = await RememberImageInfo
          .readImageInfo();
      _imageData.value = getImageInfoFromLocalStorage!;
    }
  }


}