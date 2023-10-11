<?php
require_once('common.php');
header('Content-type: application/json');

uuCheckForStatusCodeHeader();

$incoming_post = uuGetPostBody();
$body = json_decode($incoming_post);
$body = uuCheckForReturnCountHeader($body);
echo json_encode($body);

?>

