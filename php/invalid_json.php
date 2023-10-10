<?php
header('Content-type: application/json');

/*
$obj = new stdClass();
		
$arr = $_GET;
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

$jsonData = json_encode($obj);
*/

echo '{""fieldOne":"valueOne","fieldTwo":99}';

?>

