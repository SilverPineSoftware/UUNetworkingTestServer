<?php 
require_once('common.php');
require_once('ApiController.php');

class RouteController extends ApiController
{
	private $controllers = NULL;
	
	function __construct()
	{
		parent::__construct();
		
		$controllers = array();
	}
	
	function addController($action, $controller)
	{
		$this->controllers[$action] = $controller;
	}
	
	public function handleAction($action)
	{
		$parts = explode('/', $action);
		if (count($parts) < 2)
		{
			$this->setError(400, 1000, 'Unable to route request: ' . $action);
			return; 
		}
		
		$controllerName = $parts[0];
		$controllerMethod = $parts[1];
		$pathArgs = array_splice($parts, 2, count($parts) - 2);
			
		error_log("Action: $action");
		error_log("ControllerName: $controllerName");
		error_log("ControllerMethod: $controllerMethod");
		error_log("PathArgs: " . uuVarDumpToString($pathArgs));
		error_log("QueryArgs: " . uuVarDumpToString($this->queryArgs));
		
		$controller = uuGetFromArray($this->controllers, $controllerName);
		if ($controller != NULL)
		{
			if (method_exists($controller, $controllerMethod))
			{
				$controller->$controllerMethod();
			}
			else
			{
				$this->setError(400, 1001, 'Unable to route request: ' . $action);
			}
		}
		else
		{
			$this->setError(400, 1002, 'Unable to route request: ' . $action);
		}
	}
}


?>