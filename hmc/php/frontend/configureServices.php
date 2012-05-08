<?php

include_once '../util/Logger.php';
include_once '../conf/Config.inc';
include_once 'localDirs.php';
include_once "../util/lock.php";
include_once '../db/HMCDBAccessor.php';
include_once './configUtils.php';
include_once '../util/suggestProperties.php';

$logger = new HMCLogger("Options");
$dbAccessor = new HMCDBAccessor($GLOBALS["DB_PATH"]);

// Read from the input
$requestdata = file_get_contents('php://input');
$requestObj = json_decode($requestdata, true);

$clusterName = $_GET['clusterName'];
// TODO: Validate clusterName

$result = validateAndPersistConfigsFromUser($dbAccessor, $logger, $clusterName, $requestObj);
if ($result['result'] != 0) {
  $logger->log_error("Failed to validate configs from user, error=" . $result["error"]);
  print json_encode($result);
  return;
}

$jsonOutput = array();
$jsonOutput['clusterName'] = $clusterName;
print (json_encode(array("result" => 0, "error" => 0, "response" => $jsonOutput)));

?>
