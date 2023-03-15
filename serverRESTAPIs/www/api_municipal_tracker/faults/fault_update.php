<?php
include '../connection.php';

  $id = $_POST['id'];
  $uid = $_POST['uid'];
  $accountNumber = $_POST['accountNumber'];
  $address = $_POST['propertyAddress'];
  $eDescription = $_POST['electricFaultDes'];
  $wDescription = $_POST['waterFaultDes'];
  $Description = $_POST['faultDes'];
  $faultIMG = $_POST['faultIMG']['name'];
  $depAllocation = $_POST['depAllocation'];
  $faultResolved = $_POST['faultResolved'];
  $reportDate = $_POST['dateReported'];

  $query = "UPDATE faultTable SET depAllocation = $depAllocation, faultResolved = $faultResolved WHERE id=$id";

    $exeQuery = mysqli_query($connectNow, $query);

    if($exeQuery){
      echo (json_encode(array('code' =>1, 'message' => 'Table updated successfully')));
    } 
    else 
    {
      echo(json_encode(array('code' =>2, 'message' => 'Table update unsuccessful')));
    }

  ?>