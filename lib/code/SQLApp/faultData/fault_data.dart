import 'package:municipal_track/code/SQLApp/model/fault_report.dart';
import 'package:municipal_track/code/SQLApp/faultData/fault_storage.dart';

import 'package:municipal_track/code/SQLApp/model/user.dart';
import 'package:municipal_track/code/SQLApp/userPreferences/user_preferences.dart';

import 'package:get/get.dart';


///This is the controller using getx for the information on the mySql

class FaultData extends GetxController {

  Rx<Fault> _faultData = Fault(0, 0, '', '', '', '', '', false, '').obs;
  Fault get fault => _faultData.value;

  Rx<User> _currentUser = User(0,'', '', '', '', '', '').obs;
  User get user => _currentUser.value;
  getUserInfo() async {
    User? getUserInfoFromLocalStorage = await RememberUserPrefs.readUserInfo();
    _currentUser.value = getUserInfoFromLocalStorage!;
  }

  getFaultInfo() async {
    if(_currentUser.value.uid == _faultData.value.uid) {
      Fault? getFaultInfoFromLocalStorage = await RememberFaultInfo
          .readFaultInfo();
      _faultData.value = getFaultInfoFromLocalStorage!;
    }
  }


}
