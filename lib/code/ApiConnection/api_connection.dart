

class API{
  static const hostConnect = "http://localhost:8080/api_municipal_tracker"; //I need to figure out what the host is for the running XAMPP mysql server
  //static const hostConnect = "http://(ip address here)/(name of the api folder)";

  //$hostConnect allows us to pass the folder structure of the base api folder
  //so we do not have to type the entire path of "http://127.0.0.1/api_municipal_tracker/user"
  static const hostConnectUser = "$hostConnect/user";

  //signup user
  static const validatePhone = "$hostConnect/user/validate_phone.php";
  static const signUp = "$hostConnect/user/signup.php";
  static const login = "$hostConnect/user/login.php";

  //getting property information
  static const propertiesInfo = "$hostConnect/property/properties.php";
  static const propertiesUpdate = "$hostConnect/property/properties_update.php";
  static const meterImgUpload = "$hostConnect/property/image_upload.php";
  static const meterImgDownload = "$hostConnect/property/image_download.php";

  //reporting electrical or water faults on a property
  static const reportFault = "$hostConnect/faults/fault_upload.php";
  static const reportFaultUpdated = "$hostConnect/faults/fault_update.php";
  //Getting reports to assign to admin users
  static const reportList = "$hostConnect/faults/fault_list.php";

  //getting pdfList
  static const pdfDBList = "$hostConnect/statements/statement_download.php";

}