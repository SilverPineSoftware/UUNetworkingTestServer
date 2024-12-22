<?php
require_once('common.php');
header('Content-type: application/json');

//$seconds = uuGetHeader('timeout');

$seconds = uuGetQueryStringField('timeout');

error_log('Sleeping for ' . $seconds);
sleep($seconds);
error_log('Done sleeping');

$result = new stdClass();
$result->timeout = $seconds;

echo json_encode($result);

?>

