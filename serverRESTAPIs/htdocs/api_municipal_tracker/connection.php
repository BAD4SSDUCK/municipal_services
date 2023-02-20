<?php 
$host = "localhost:8080";//localhost:8080
$user = "root";//If installed without a username this would be ("root")
$password = "";//If installed without a password this is left empty as ("") password usally Cyberfox7865#
$database = "municipal-tracking";

$connectNow = new mysqli($host, $user, $password, $database);

///Need to fix connection.php as it is still not retrieving DB conection. 
//it's returning(connection denied) 
?>