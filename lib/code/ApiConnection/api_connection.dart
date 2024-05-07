
///These api's are only for fire
class API{

  static const hostConnect = "http://172.21.160.1:8080/connection.php"; //http://municipal_services.localhost:8080/ //localhost:8080 //I need to figure out what the host is for the running XAMPP mysql server
  //static const hostConnect = "http://(ip address here)/(name of the api folder)";

  //$hostConnect allows us to pass the folder structure of the base api folder
  //so we do not have to type the entire path of "http://127.0.0.1/municipal_services/user"
  static const hostConnectUser = "$hostConnect/user";
  static const adminUserUpdate = "$hostConnect/user/admin_update.php";
  static const adminUserList = "$hostConnect/user/admin_list.php";

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