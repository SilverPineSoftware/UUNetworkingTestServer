<?php 
require_once('common.php');

class ApiController
{
	private $resultHttpCode = 200;
	private $resultBody = NULL;
	private $resultContentType = 'application/json';
	protected $pathArgs = NULL;
	protected $queryArgs = NULL;
	
	function __construct()
	{
		$this->queryArgs = uuQueryArgs();
		unset($this->queryArgs->do);
	}
	
	function __destruct() 
	{
		header('Content-type: application/json');
		http_response_code($this->resultHttpCode);
		
		error_log("HTTPCode: " . $this->resultHttpCode);
		error_log("HTTPResponse: " . $this->resultBody);
		
		if (!is_null($this->resultBody))
		{
			echo $this->resultBody;
		}
	}
	
	function setResult($httpCode, $json)
	{
		$this->resultHttpCode = $httpCode;
		$this->resultBody = json_encode($json);
	}
	
	function setError($httpCode, $errorCode, $errorMessage)
	{
		$obj = new stdClass();
		$obj->errorCode = $errorCode;
		$obj->errorMessage = $errorMessage;
		$this->setResult($httpCode, $obj);
	}
}

?>