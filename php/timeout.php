<?php
header('Content-type: application/json');

$seconds = $_GET['timeout'];
sleep($seconds);

$result = new stdClass();
$result->timeout = $seconds;

echo json_encode($result);

?>

