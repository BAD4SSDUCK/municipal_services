<?php
include '../connection.php';

//POST = sending/saving data to mysql db
//GET = retrieve/read data from db
$id = $_POST['id'];
$electricityMeterReading = $_POST['electricityMeterReading'];
$waterMeterReading = $_POST['waterMeterReading'];
$monthUpdated = $_POST['monthUpdated'];
$year = $_POST['year'];

///To be fixed for retrieving data per user where  users uid == property uid 
//NB. "id" represents primary key for proerties only, "uid" represents primary key of users only

$sqlQuery = "UPDATE propertyTable SET electricityMeterReading = '$electricityMeterReading', waterMeterReading = '$waterMeterReading', monthUpdated = '$monthUpdated', year = '$year' WHERE id = '$id'";

$resultOfQuery = $connectNow->query($sqlQuery);

if($resultOfQuery){
    echo json_encode(array("success"=>true));
}
else{
    echo json_encode(array("success"=>false));
}
?>