<?php

$query = $_SERVER['QUERY_STRING'];
if (strlen($query) > 0)
{
	$query = "?" . $query;
}

$host = $_SERVER['HTTP_HOST'];
$prefix = 'http://';

if ($_SERVER['HTTPS'] == 'on')
{
	$prefix = 'https://';
}

header('Location: ' . $prefix . $host . '/uu/get_object.php' . $query);
exit;
?>

