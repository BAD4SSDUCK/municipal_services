<?php
include '../connection.php';

//POST = sending/saving data to mysql db
//GET = retrieve/read data from db

$cellNumber = $_POST['cellNumber'];
$email = $_POST['email'];
$firstName = $_POST['firstName'];
$lastName = $_POST['lastName'];
$userName = $_POST['userName'];
$userPassword = md5($_POST['userPassword']);

$sqlQuery = "INSERT INTO users SET cellNumber = '$cellNumber', email = '$email', firstName = '$firstName', lastName = '$lastName', userName = '$userName', userpassword = '$userPassword'";

$resultOfQuery = $connectNow->query($sqlQuery);

if($resultOfQuery){
    echo json_encode(array("success"=>true));
}
else{
    echo json_encode(array("success"=>false));
}

