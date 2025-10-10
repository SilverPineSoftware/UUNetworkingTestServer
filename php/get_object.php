<?php
require_once('common.php');
require_once('model.php');

uuLogServerVars();
uuLogGETVars();
uuLogPOSTVars();

$acceptEncoding = uuGetHeader('HTTP_ACCEPT_ENCODING');

if ($acceptEncoding == 'gzip')
{
	error_log('Using GZip');
	ob_start("ob_gzhandler");
	header('Vary: Accept-Encoding');
}
else if ($acceptEncoding == 'deflate')
{
	error_log('Using Deflate');
	header('Vary: Accept-Encoding');
	header('Content-Encoding: deflate');
}
else 
{
	error_log('Using No compression');
}

header('Content-type: application/json');


uuCheckForStatusCodeHeader();

$body = new TestModel();
$body->id = "12345";
$body->name = "IntegrationTest";
$body->data = "This is for live integration testing between mobile libraries and real servers.";

$id = uuGetQueryStringField('id');
if ($id != NULL)
{
	$body->id = $id;
}

$name = uuGetQueryStringField('name');
if ($name != NULL)
{
	$body->name = $name;
}

$data = uuGetQueryStringField('data');
if ($data != NULL)
{
	$body->data = $data;
}

if ($acceptEncoding == 'deflate')
{
	echo gzcompress(json_encode($body), 6);
}
else 
{
	echo json_encode($body);
}

?>