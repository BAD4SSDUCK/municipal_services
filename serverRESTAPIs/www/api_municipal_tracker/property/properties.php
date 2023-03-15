<?php
include '../connection.php';
include '/user_properties';
///Need to fix connection.php as it is still not retrieving DB conection. it returning(connection denied) 


//POST = sending/saving data to mysql db
//GET = retrieve/read data from db

$address = $_POST['address'];
$cellNumber = $_POST['cellNumber'];

///The bellow is incase the vales from table need to be set to objects
// $accountNumber = $_GET['accountNumber'];
// $areaCode = $_GET['areaCode'];
// $eBill = $_GET['eBill'];
// $electricityMeterNumber = $_GET['electricityMeterNumber'];
// $electricityMeterReading = $_GET['electricityMeterReading'];
// $waterMeterNumber = $_GET['waterMeterNumber'];
// $waterMeterReading = $_GET['waterMeterReading'];
// $firstName = $_GET['firstName'];
// $lastName = $_GET['lastName'];
// $idNumber = $_GET['idNumber'];
// $uid = $_GET['uid'];
// $monthUpdated = $_GET['monthUpdated'];
// $year = $_GET['year'];

///To be fixed for retrieving all data
$sqlQuery = $connectNow->query("SELECT * FROM propertyTable WHERE cellNumber = '$cellNumber'");

$resultOfQuery = array();

while($rowData = $sqlQuery->fetch_assoc()){
    $resultOfQuery[] = $rowData;
}

echo json_encode($resultOfQuery);
?>