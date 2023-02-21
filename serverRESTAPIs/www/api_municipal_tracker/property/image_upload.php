<?php
include '../connection.php';

  $address = $_POST['address'];
  $uid = $_POST['uid'];
  $eimage = $_FILES['electricImage']['name'];
  $wimage = $_FILES['waterImage']['name'];
  $Updated = $_POST['uploadDate'];

  $imagePath = "uploads/".$image;

  move_uploaded_file($_FILES['image']['tmp_name'],$imagePath);
  $connect->query("INSERT INTO imageTable (address, uid, image, image, uploadDate, year) VALUES ('".$address."','".$uid."','".$eimage."','".$wimage."','".$Updated."','".$year."')");
?>