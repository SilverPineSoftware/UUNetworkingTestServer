<?php 
require_once('common.php');
require_once('model.php');
require_once('ApiController.php');

class TestController extends ApiController
{
	function single()
	{
		if (uuIsGet())
		{
			$this->single_GET();
		}
		else if (uuIsPost())
		{
			$this->single_POST();
		}
		else if (uuIsPut())
		{
			$this->single_POST();
		}
		else
		{
			$this->setResult(415, NULL);
		}
	}
	
	function single_GET()
	{
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
		
		$this->setResult(200, $body);
	}
	
	function single_POST()
	{
		$incoming_post = uuGetPostBody();
		$body = json_decode($incoming_post);
		$this->setResult(200, $body);
	}
	
	function multiple()
	{
		$count = intval(uuGetQueryStringField('count'));
	
		$result = array();
		for ($i = 0; $i < $count; $i++)
		{
			$body = new TestModel();
			$body->id = "$i";
			$body->name = "Name-$i";
			$body->data = "Data for object $i";

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
			
			$result[] = $body;
		}
		
		$this->setResult(200, $result);
	}
}


?>