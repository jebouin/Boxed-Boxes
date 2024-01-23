<?php include("constants.php"); ?>
{
	"skipTerminateQuickPick": true,
	"skipSwitchToOutput": false,
	"skipErrorMessage": true,
	"commands": [
		{
			"text": "ALL",
			"color": "white",
			"commandType":"exec",
			"command": "echo TODO",
			"alignment": "right",
			"skipTerminateQuickPick": false,
			"priority": -9
		},
		{
			"text": "Run",
			"color": "orange",
			"command": "hl bin/dev/<?php echo $gameId?>.hl",
			"alignment": "right",
			"skipTerminateQuickPick": false,
			"priority": -10
		},
		{
			"text": "PAK",
			"color": "white",
			"commandType":"exec",
			"command": "haxe -hl hxd.fmt.pak.Build.hl -lib heaps -main hxd.fmt.pak.Build && hl hxd.fmt.pak.Build.hl -exclude-path bitwigProjects,LevelProject/backups,music/exportWAV,models,sfx/stereo && mv res.pak bin/pak/resWeb.pak && haxe -hl hxd.fmt.pak.Build.hl -lib heaps -main hxd.fmt.pak.Build && hl hxd.fmt.pak.Build.hl -exclude-path bitwigProjects,LevelProject/backups,music/exportMP3,models,sfx/stereo && mv res.pak bin/pak/resDesktop.pak",
			"alignment": "right",
			"skipTerminateQuickPick": false,
			"priority": -10
		},
		{
            "text": "Windows",
            "color": "yellow",
            "command": "./releaseWindows.sh",
            "alignment": "right",
            "skipTerminateQuickPick": false,
            "priority": -12
        },
        {
            "text": "Linux",
            "color": "yellow",
            "command": "./releaseLinux.sh",
            "alignment": "right",
            "skipTerminateQuickPick": false,
            "priority": -13
        },
		{
			"text": "JS",
			"color": "yellow",
			"commandType":"exec",
			"command": "./prebuild.sh && haxe build.web.js.hxml",
			"alignment": "right",
			"skipTerminateQuickPick": false,
			"priority": -15
		},
		{
			"text": "Itch",
			"color": "yellow",
			"commandType":"exec",
			"command": "./prebuild.sh && haxe build.web.itch.hxml",
			"alignment": "right",
			"skipTerminateQuickPick": false,
			"priority": -16
		},
		{
			"text": "NG",
			"color": "yellow",
			"commandType":"exec",
			"command": "./prebuild.sh && haxe build.web.newgrounds.hxml",
			"alignment": "right",
			"skipTerminateQuickPick": false,
			"priority": -17
		},
		{
			"text": "Server",
			"color": "white",
			"command": "cd bin/ && python3 -m http.server",
			"alignment": "right",
			"skipTerminateQuickPick": false,
			"priority": -19
		},
        {
			"text": "Profile",
			"color": "yellow",
			"command": "cp bin/pak/resWeb.pak res.pak && hl --profile 10000 \"bin/hl/<?php echo $gameId?>.hl\" && mv hlprofile.dump tools/ && hl tools/profiler.hl tools/hlprofile.dump && rm res.pak",
			"alignment": "right",
			"skipTerminateQuickPick": false,
			"priority": -20
		},
		{
			"text": "Clean",
			"color": "Blue",
			"command": "./clean.sh",
			"alignment": "right",
			"skipTerminateQuickPick": false,
			"priority": -20
		}
    ]
}