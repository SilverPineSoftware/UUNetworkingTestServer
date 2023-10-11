<?php
require_once('common.php');
require_once('model.php');
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

echo json_encode($body);

?>

