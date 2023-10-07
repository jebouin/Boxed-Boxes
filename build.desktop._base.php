<?php include("constants.php"); ?>
build._base.hxml

--macro hxd.res.Config.addIgnoredDir("exportMP3")
--no-traces
-D windowSize=<?php echo $windowSize ?>
-D hl
-hl bin/hl/<?php echo $gameId ?>.hl