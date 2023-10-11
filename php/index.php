<?php 
require_once('EchoController.php');
require_once('RouteController.php');
require_once('TestController.php');
$action = uuGetQueryStringField('do');
$routeController = new RouteController();
$routeController->addController('echo', new EchoController());
$routeController->addController('test', new TestController());
$routeController->handleAction($action);
?>
