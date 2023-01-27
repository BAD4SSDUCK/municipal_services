
class API{
  static const hostConnect = "http://192.168.18.9/api_municipal_tracker";
  //static const hostConnect = "http://(ip address here)/(name of the api folder)";

  //$hostConnect allows us to pass the folder structure of the base api folder
  //so we do not have to type the entire path of "http://192.168.18.9/api_municipal_tracker/user"
  static const hostConnectUser = "$hostConnect/user";

  //signup user
  static const validatePhone = "$hostConnect/user/validate_phone.php";
  static const signUp = "$hostConnect/user/signup.php";

}