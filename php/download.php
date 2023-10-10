<?php

require_once('common.php');
uuCheckForStatusCodeHeader();

$file = uuRequireQueryStringField('uu_file');
uuDebugLog('File: ' . $file);

$path = UU_FILE_FOLDER . $file;
uuDebugLog('Requested File: ' . $path);

if (file_exists($path))
{
	ob_get_clean();

	header("Content-Disposition: attachment; filename=\"" . basename($path) . "\"");
	header("Content-Type: " . mime_content_type($path));
	header("Content-Length: " . filesize($path));
	header('Content-Transfer-Encoding: binary');
	header('Expires: 0');
	header('Pragma: public');
	header("Connection: close");

	ob_clean();
	flush();
	readfile($path);
	exit;
}
else
{
	uuExit(404, 'File ' . $file . ' does not exist.');
}

?>

