<?php
require_once(__DIR__ . '/common.php');

if (uuDispatchStandalonePhp(__DIR__)) {
	exit;
}

require_once(__DIR__ . '/EchoController.php');
require_once(__DIR__ . '/RouteController.php');
require_once(__DIR__ . '/TestController.php');

$action = uuRoutingAction();
if ($action === NULL || $action === '')
{
	header('Content-type: text/plain');
	echo 'UUNetworkingTestServer OK';
	exit;
}

$routeController = new RouteController();
$routeController->addController('echo', new EchoController());
$routeController->addController('test', new TestController());
$routeController->handleAction($action);
