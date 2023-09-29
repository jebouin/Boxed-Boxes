<?php
    $file = fopen("constants.yaml", "r") or die("Unable to open constants file!");
    $gameName = trim(explode(":", fgets($file))[1]);
    $gameId = trim(explode(":", fgets($file))[1]);
    $gameVersion = trim(explode(":", fgets($file))[1]);
    $windowSize = trim(explode(":", fgets($file))[1]);
    fclose($file);
?>