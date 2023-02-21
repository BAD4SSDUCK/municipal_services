<?php 
$hostname = "localhost:8080";//localhost:8080
$username = "root";//If installed without a username this would be ("root")
$password = "Cyberfox7865";//If installed without a password this is left empty as ("") password usally Cyberfox7865#
$database = "municipal-tracking";
$port = "8080";
$socket = "3306";

$connectNow = new mysqli($hostname, $username, $password, $database, $port, $socket);

//$connectNow = new mysqli("localhost:8080", "root", "", "municipal-tracking","");

if ($connectNow -> connect_errno){
    echo "Failed to connect to database: " . $connectNow -> connect_error;
    exit();
}

///Need to fix connection.php as it is still not retrieving DB conection. 
//it's returning(connection refused) 
?>