<?php include("constants.php"); ?>
build.web._base.hxml

--no-traces
-D itch
-js bin/itch/<?php echo $gameId ?>.js
--cmd cp -t bin/itch/ bin/js/index.html bin/js/style.css bin/js/avatar.png
--cmd cp bin/pak/resWeb.pak bin/itch/res.pak
--cmd cd bin/itch
--cmd zip -r ../itch.zip *
--cmd cd ../..