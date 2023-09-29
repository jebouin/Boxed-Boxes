<?php include("constants.php"); ?>
<!DOCTYPE>
<html>
<head>
    <meta charset="utf-8"/>
    <link rel="stylesheet" href="style.css">
    <title><?php echo htmlspecialchars($gameName, ENT_QUOTES, "UTF-8"); ?></title>
</head>
<body id="body">
    <div id="loader">
        <div id="dvd">
            <div class="no-select" id="circle"></div>
            <div class="no-select" id="circle2"></div>
            <img class="no-select" id="avatar" src="avatar.png">
            <div class="no-select" id="center"></div>
            <div class="no-select" id="center2"></div>
        </div>
        <div id="bo-percentage">
            Loading...
        </div>
    </div>
    <canvas id="webgl"></canvas>
    <script>
        function updateProgress(p) {
            var elem = document.getElementById("bo-percentage");
            elem.innerText = "Loading... " + p + "%";
        }
        function onGameLoaded() {
            var elem = document.getElementById("loader");
            elem.remove();
        }
    </script>
    <script type="text/javascript" src="<?php echo $gameId . '.js' ?>"></script>
</body>
</html>