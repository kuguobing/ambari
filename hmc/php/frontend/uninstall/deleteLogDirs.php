<?php

include_once '../util/Logger.php';
include_once '../conf/Config.inc';
include_once 'localDirs.php';
include_once "../util/lock.php";
include_once '../db/HMCDBAccessor.php';
include_once './uninstall/uninstallUtil.php';

$logger = new HMCLogger("CleanupLogDirs");
$dbAccessor = new HMCDBAccessor($GLOBALS["DB_PATH"]);

function getCommandLine() {
  $cmdLine = "rm -rf /var/log/hadoop /var/log/hbase /var/log/zookeeper /var/log/hive /var/log/oozie /var/log/templeton /grid/?/hadoop /grid/?/hdp ";
  $cmdLine = $cmdLine . 'sleep $[ $RANDOM % 5 ]; ';
  return $cmdLine;
}

$clusterName = $argv[1];
$deployUser = $argv[2];
$rootTxnId = $argv[3];
$mySubTxnId = $argv[4];
$parentSubTxnId = $argv[5];
$hostsStr = $argv[6];

$cmdLine = getCommandLine();
// stage name should match corr. stage in stages.php
$stageName = "LogCleanup";

handleUninstallTransaction($clusterName, $deployUser, $rootTxnId,
  $mySubTxnId, $parentSubTxnId, $hostsStr,
  $stageName, $cmdLine, $dbAccessor, $logger);

?>
