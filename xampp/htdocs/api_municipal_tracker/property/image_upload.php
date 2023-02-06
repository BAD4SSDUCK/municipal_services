<?php
include '../connection.php';

  $address = $_POST['address'];
  $uid = $_POST['uid'];
  $eimage = $_FILES['electricImage']['name'];
  $wimage = $_FILES['waterImage']['name'];
  $monthUpdated = $_POST['monthAdded'];
  $year = $_POST['year'];

  $imagePath = "uploads/".$image;

  move_uploaded_file($_FILES['image']['tmp_name'],$imagePath);
  $connect->query("INSERT INTO meterImage (address, uid, image, image, monthAdded, year) VALUES ('".$address."','".$uid."','".$eimage."','".$wimage."','".$monthUpdated."','".$year."')");

?>