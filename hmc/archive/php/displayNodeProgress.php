<?php

$logs = '';

/* Generate long logs. */
for($i = 0; $i < 100; $i++) {
  $logs .= "1111 <br/>";
}

$jsonOutput = array( 
    'txnId' => $txnId, 
    'logs' => $logs );

header("Content-type: application/json");

print (json_encode($jsonOutput));

?>
