<?php
include '../connection.php';

//POST = sending/saving data to mysql db
//GET = retrieve/read data from db
$accountNumber = $_GET['accountNumber'];
$address = $_GET['address'];
$areaCode = $_GET['areaCode'];
$cellNumber = $_GET['cellNumber'];
$eBill = $_GET['eBill'];
$electricityMeterNumber = $_GET['electricityMeterNumber'];
$electricityMeterReading = $_GET['electricityMeterReading'];
$waterMeterNumber = $_GET['waterMeterNumber'];
$waterMeterReading = $_GET['waterMeterReading'];
$firstName = $_GET['firstName'];
$lastName = $_GET['lastName'];
$idNumber = $_GET['idNumber'];
$uid = $_GET['uid'];
$monthUpdated = $_GET['monthUpdated'];
$year = $_GET['year'];

///To be fixed for retrieving data per user where  users uid == property uid 
//NB. "id" represents primary key for proerties only, "uid" represents primary key of users only

$sqlQuery = "INSERT INTO users SET cellNumber = '$cellNumber', email = '$email', firstName = '$firstName', lastName = '$lastName', userName = '$userName', userpassword = '$userPassword'";

$resultOfQuery = $connectNow->query($sqlQuery);

if($resultOfQuery){
    echo json_encode(array("success"=>true));
}
else{
    echo json_encode(array("success"=>false));
}
?>