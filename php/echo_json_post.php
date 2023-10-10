<?php
header('Content-type: application/json');

$headers = uuHeaders();
$headerJson = json_encode($headers);
header("UU-Request-Header-Echo: $headerJson");

$uuStatusCode = getHeader('HTTP_UU_STATUS_CODE');
if ($uuStatusCode != NULL)
{
	http_response_code(intval($uuStatusCode));
}

//$body = arrayToObject($_POST);
$incoming_post = file_get_contents('php://input');
$body = json_decode($incoming_post);

$uuReturnObjectCount = getHeader('HTTP_UU_RETURN_OBJECT_COUNT');
if ($uuReturnObjectCount != NULL)
{
	$count = intval($uuReturnObjectCount);
	
	if ($count > 1)
	{
		$obj = $body;
		$arr = array();
		
		for ($i = 0; $i < $count; $i++)
		{
			$arr[] = $obj;
		}
		
		$body = $arr;
	}
}

echo json_encode($body);

function arrayToObject($arr)
{
	$obj = new stdClass();
		
	$fieldNames = array_keys($arr);
	foreach ($fieldNames as $field)
	{
		$val = $arr[$field];
		if (is_numeric($val))
		{
			$obj->$field = intval($val);
		}
		else
		{
			$obj->$field = $val;
		}
	}

	return $obj;
}

function uuHeaders()
{
	$obj = arrayToObject($_SERVER);
	$uuHeaders = new stdClass();

	$fields = get_object_vars($obj);
	$fieldNames = array_keys($fields);

	foreach ($fieldNames as $field)
	{
		error_log("Field: $field");

		if (strpos($field, 'HTTP_UU_') === 0)
		{
			$uuHeaders->$field = $obj->$field;
		}
	}

	return $uuHeaders;
}

function getFromArray($arr, $key)
{
	if (isset($arr[$key]))
	{
		return $arr[$key];
	}
	else 
	{
		return NULL;
	}
}

function getHeader($key)
{
	return getFromArray($_SERVER, $key);
}


?>

