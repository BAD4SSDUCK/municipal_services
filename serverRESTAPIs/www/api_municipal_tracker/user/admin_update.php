<?php
include '../connection.php';

$uid = $_POST['uid'];
$userName = $_POST['userName'];
$adminRoll = $_POST['adminRoll'];
$firstName = $_POST['firstName'];
$lastName = $_POST['lastName'];
$email = $_POST['email'];
$cellNumber = $_POST['cellNumber'];
$official = $_POST['official'];
  
$sql = "UPDATE users SET userName ='Doe' WHERE id=2";

$sqlQuery = "UPDATE users SET userName = '$userName', adminRoll = '$adminRoll', firstName = '$firstName', lastName = '$lastName', email = '$email', cellNumber = '$cellNumber', official = '$official' WHERE uid = '$uid'";

$resultOfQuery = $connectNow->query($sqlQuery);

if($resultOfQuery){
    echo json_encode(array("success"=>true));
}
else{
    echo json_encode(array("success"=>false));
}
$connectNow->close();

?>