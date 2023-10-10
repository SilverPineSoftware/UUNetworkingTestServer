<?php

require_once('common.php');
uuLogFILESVars();
uuCheckForStatusCodeHeader();

header('Content-type: text/plain');

$file = uuRequireFileField('uu_file');

$result = uuSaveFile($file, UU_FILE_FOLDER);

echo 'Upload finished, result: ' . $result;

?>

