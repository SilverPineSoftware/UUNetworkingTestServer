<?php
ob_start("ob_gzhandler");
require_once('common.php');
header('Content-type: application/json');

$incoming_post = uuGetPostBody();

$contentEncoding = uuGetHeader('HTTP_CONTENT_ENCODING');

if ('gzip' == $contentEncoding)
{
	$incoming_post = gzinflate(substr($incoming_post,10,-8));
}

$body = json_decode($incoming_post);
$correlationId = $body->correlationId;

$uploadFolder = UU_FILE_FOLDER;
$fileName = "${correlationId}.json";
$fullFileName = $uploadFolder . $fileName;

file_put_contents($fullFileName, $incoming_post);

?>

