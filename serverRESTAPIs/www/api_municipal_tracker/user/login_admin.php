<?php
include '../connection.php';

//POST = sending/saving data to mysql db
//GET = retrieve/read data from db

$username = $_POST['username'];
$userPassword = md5($_POST['userPassword']);

$sqlQuery = "SELECT * FROM users WHERE username = '$username' AND userPassword = '$userPassword'";

$resultOfQuery = $connectNow->query($sqlQuery);

if($resultOfQuery->num_rows > 0){ //allow user to login

    $userRecord = array();
    while($rowFound = $resultOfQuery->fetch_assoc()){
        $userRecord[] = $rowFound;
    }

    echo json_encode(
        array(
        "success"=>true,
        "userData"=>$userRecord[0]
        )
    );
}
else{ //does not allow a login
    echo json_encode(array("success"=>false));
}
?>
