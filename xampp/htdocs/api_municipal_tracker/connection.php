<?php 
$serverHost = "localhost";
$user = "root";//If installed without a username this would be ("root")
$password = "Cyberfox7865#";//If installed without a password this is left empty as ("")
$database = "municipal-tracking";

$connectNow = new mysqli($serverHost, $user, $password, $database);

///Need to fix connection.php as it is still not retrieving DB conection. it returning(connection denied) 
