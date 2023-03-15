<?php
include '../connection.php';

$result = $conn->query("SELECT * FROM faultTable ORDER BY id DESC");
$list = array();
if ($result) {
    while ($row = mysqli_fetch_assoc($result)) {
        $list[] = $row;
    }
    echo json_encode($list);
}
?>