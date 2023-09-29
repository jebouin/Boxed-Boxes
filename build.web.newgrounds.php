<?php include("constants.php"); ?>
build.web._base.hxml

-lib newgrounds
-D newgrounds
-js bin/newgrounds/<?php echo $gameId ?>.js
--cmd cp -t bin/newgrounds/ bin/js/index.html bin/js/style.css bin/js/avatar.png
--cmd cp bin/pak/resWeb.pak bin/newgrounds/res.pak
--cmd cd bin/newgrounds
--cmd zip -r ../newgrounds.zip *
--cmd cd ../..