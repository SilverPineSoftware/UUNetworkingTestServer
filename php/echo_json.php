<?php
require_once('common.php');
header('Content-type: application/json');

uuCheckForStatusCodeHeader();

$body = uuArrayToObject($_GET);
$body = uuCheckForReturnCountHeader($body);
echo json_encode($body);

?>

