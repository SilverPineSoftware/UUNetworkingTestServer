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
			$this->setJsonResult(415, NULL);
		}
	}
	
	private function handleGet()
	{
		$httpCode = uuCheckForStatusCodeHeader();
	
		$body = $this->queryArgs;
		$body = uuCheckForReturnCountHeader($body);
		$this->setJsonResult($httpCode, $body);
	}
	
	private function handlePost()
	{
		$httpCode = uuCheckForStatusCodeHeader();

		$incoming_post = uuGetPostBody();
		$body = json_decode($incoming_post);
		$body = uuCheckForReturnCountHeader($body);
		$this->setJsonResult($httpCode, $body);
	}

	private function handlePut()
	{
		$httpCode = uuCheckForStatusCodeHeader();

		$incoming_post = uuGetPostBody();
		$body = json_decode($incoming_post);
		$body = uuCheckForReturnCountHeader($body);
		$this->setJsonResult($httpCode, $body);
	}
}


?>