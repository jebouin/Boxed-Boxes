<?php include("constants.php"); ?>
build.web._base.hxml

-js bin/js/<?php echo $gameId ?>.js
--cmd cp bin/pak/resWeb.pak bin/js/res.pak
-debug