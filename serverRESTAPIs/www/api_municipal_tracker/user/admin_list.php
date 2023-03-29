<?php
include '../connection.php';

$result = $connectNow->query("SELECT * FROM users WHERE official is 1 ORDER BY uid DESC");
$list = array();
if ($result) {
    while ($row = mysqli_fetch_assoc($result)) {
        $list[] = $row;
    }
    echo json_encode($list);
}
?>