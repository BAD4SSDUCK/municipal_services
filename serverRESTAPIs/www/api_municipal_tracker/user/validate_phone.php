<?php

include '../connection.php';

$cellNumber = $_POST['cellNumber'];

$sqlQuery = "SELECT * From users WHERE cellNumber = '$cellNumber'";

$resultOfQuery = $connectNow->query($sqlQuery);

if($resultOfQuery->num_rows > 0){
    
    //num rows length == 1 --- cell number is already in use by someone else --- Error

    echo json_encode(array("phoneFound"=>true));
}
else{

    //num rows lenght == 0 --- valid new account registration proceed with adding the new user --- a user will be allowed to signup successfully

    echo json_encode(array("phoneFound"=>false));
}

//this will check if the cell number trying to register is already existing in the db. if it is the new registration will not validate unless its a new phone number
?>
