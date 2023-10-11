<?php 
require_once('common.php');
require_once('ApiController.php');


class EchoController extends ApiController
{
	function json()
	{
		if (uuIsGet())
		{
			$this->handleGet();
		}
		else if (uuIsPost())
		{
			$this->handlePost();
		}
		else if (uuIsPut())
		{
			$this->handlePut();
		}
		else
		{
			$this->setResult(415, NULL);
		}
	}
	
	private function handleGet()
	{
		$httpCode = 200;
		$uuStatusCode = uuGetHeader('HTTP_UU_STATUS_CODE');
		if ($uuStatusCode != NULL)
		{
			$httpCode = intval($uuStatusCode);
		}
	
		$body = $this->queryArgs;
		$body = uuCheckForReturnCountHeader($body);
		$this->setResult($httpCode, $body);
	}
	
	private function handlePost()
	{
	}
}


?>