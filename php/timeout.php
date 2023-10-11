<?php
require_once('common.php');
header('Content-type: application/json');

$seconds = uuGetHeader('timeout');
sleep($seconds);

$result = new stdClass();
$result->timeout = $seconds;

echo json_encode($result);

?>

