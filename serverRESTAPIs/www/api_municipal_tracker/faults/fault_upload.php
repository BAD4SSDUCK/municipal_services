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

  $connect->query("INSERT INTO faultTable (uid, accountNumber, propertyAddress,  electricFaultDes, waterFaultDes, faultResolved, dateReported) VALUES ('".$uid."','".$accountNumber."','".$address."','".$eDescription."','".$wDescription."', '".$faultResolved."', '".$reportDate."')");
?>