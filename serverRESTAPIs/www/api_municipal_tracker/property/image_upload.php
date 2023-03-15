<?php
include '../connection.php';

  $id = $_POST['id'];
  $address = $_POST['address'];
  $uid = $_POST['uid'];
  $eimage = $_FILES['electricImage']['name'];
  $wimage = $_FILES['waterImage']['name'];
  $Updated = $_POST['uploadDate'];

  if ($wimage == null){
    $imagePath = "image_uploads/".$eimage;
    move_uploaded_file($_FILES['image']['tmp_name'],$imagePath);
    $connect->query("INSERT INTO imageTable (address, uid, image, uploadDate, year) WHERE id = $id VALUES ('".$address."','".$uid."','".$eimage."','".$Updated."','".$year."')");
  } else if ($eimage == null) {
    $imagePath = "image_uploads/".$wimage;
    move_uploaded_file($_FILES['image']['tmp_name'],$imagePath);
    $connect->query("INSERT INTO imageTable (address, uid, image, uploadDate, year) WHERE id = $id VALUES ('".$address."','".$uid."','".$wimage."','".$Updated."','".$year."')");
  }

  //move_uploaded_file($_FILES['image']['tmp_name'],$imagePath);
  //$connect->query("INSERT INTO imageTable (address, uid, image, image, uploadDate, year) WHERE id = $id VALUES ('".$address."','".$uid."','".$eimage."','".$wimage."','".$Updated."','".$year."')");

?>