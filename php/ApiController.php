<?php 
require_once('common.php');

class ApiController
{
	private $resultHttpCode = 200;
	private $resultBody = NULL;
	private $resultContentType = NULL;
	protected $pathArgs = NULL;
	protected $queryArgs = NULL;
	
	function __construct()
	{
		$this->queryArgs = uuQueryArgs();
		unset($this->queryArgs->do);
	}
	
	function __destruct() 
	{
		if (!is_null($this->resultContentType))
		{
			header("Content-type: " . $this->resultContentType);
		}
		else
		{
			header_remove('Content-type');
		}
		
		http_response_code($this->resultHttpCode);
		
		error_log("HTTPCode: " . $this->resultHttpCode);
		error_log("HTTPResponse: " . $this->resultBody);
		
		if (!is_null($this->resultBody))
		{
			echo $this->resultBody;
		}
	}
	
	function setJsonResult($httpCode, $json)
	{
		$encodedJson = NULL;

		if (!is_null($json))
		{
			$encodedJson = json_encode($json);
		}
		
		$this->setResult($httpCode, 'application/json', $encodedJson);
	}

	function setResult($httpCode, $contentType, $body)
	{
		$this->resultHttpCode = $httpCode;
		$this->resultContentType = $contentType;

		if (!is_null($body))
		{
			$this->resultBody = $body;
		}
		else
		{
			$this->resultBody = NULL;
		}
	}
	
	function setError($httpCode, $errorCode, $errorMessage)
	{
		$obj = new stdClass();
		$obj->errorCode = $errorCode;
		$obj->errorMessage = $errorMessage;
		$this->setJsonResult($httpCode, $obj);
	}
}

?>