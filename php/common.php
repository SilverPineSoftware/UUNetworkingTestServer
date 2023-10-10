<?php

define('UU_FILE_FOLDER', '/var/www-uu-upload/');

function uuArrayToObject($arr)
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
	$obj = uuArrayToObject($_SERVER);
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

function uuGetFromArray($arr, $key)
{
	if ($arr && $key && isset($arr[$key]))
	{
		return $arr[$key];
	}
	else 
	{
		return NULL;
	}
}

function uuGetHeader($key)
{
	return uuGetFromArray($_SERVER, $key);
}

function uuRequireQueryStringField($key)
{
	$file = uuGetFromArray($_GET, $key);
	if ($file == NULL)
	{
		uuExit(400, 'Expected query string argument: ' . $key);
	}
	
	return $file;
}

function uuGetFileField($key)
{
	return uuGetFromArray($_FILES, $key);
}

function uuRequireFileField($key)
{
	$file = uuGetFileField($key);
	if ($file == NULL)
	{
		uuExit(400, 'Expected file: ' . $key);
	}
	
	return $file;
}

function uuCheckForStatusCodeHeader()
{
	$uuStatusCode = uuGetHeader('HTTP_UU_STATUS_CODE');
	if ($uuStatusCode != NULL)
	{
		http_response_code(intval($uuStatusCode));
	}
}

function uuExit($httpStatusCode, $message)
{
	http_response_code($httpStatusCode);
	header('Content-type: text/plain');
	echo $message;
	die();
}

function uuSaveFile($fileInfo, $localPath)
{
	if ($fileInfo && $localPath)
	{
		$tempFileName = $fileInfo['tmp_name'];
		if (!$tempFileName)
		{
			uuDebugLog('unable to get temp file name for image ' . $localPath);
			return false;
		}
		
		$fileName = $fileInfo['name'];
		$fullLocalPath = $localPath . $fileName;
		
		$result = move_uploaded_file($tempFileName, $fullLocalPath);
		if($result)
		{
			return true;
		}
		else
		{
			uuDebugLog('Failed to save file ' . $tempFileName . ', localPath=' . $localPath);
			return false;
		}
	}
	
	return false;
}


// LOGGING

function uuDebugLog($msg)
{
	error_log($msg);
}

function uuLogArray($array, $name)
{
	if ($array)
	{
		uuDebugLog($name . ' has ' . count($array) . ' entries');
		
		$keys = array_keys($array);
		foreach ($keys as $key)
		{
			$val = $array[$key];
			
			if (is_array($val) || is_object($val))
			{
				uuDebugLog($key . '=' . uuVarDumpToString($val));
			}
			else
			{
				uuDebugLog($key . '=' . $val);
			}
		}
	}
	else
	{
		uuDebugLog($name . ' is null');
	}
}

function uuLogServerVars()
{
	uuLogArray($_SERVER, '_SERVER');
}

function uuLogGETVars()
{
	uuLogArray($_GET, '_GET');
}

function uuLogPOSTVars()
{
	uuLogArray($_POST, '_POST');
}

function uuLogFILESVars()
{
	uuLogArray($_FILES, '_FILES');
}

function uuVarDumpToString($obj)
{
	ob_start();
	var_dump($obj);
	$dump = ob_get_contents();
	ob_end_clean();
	return $dump;
}


?>
