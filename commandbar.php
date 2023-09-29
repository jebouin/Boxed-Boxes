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
			"text": "PAK",
			"color": "white",
			"commandType":"exec",
			"command": "haxe -hl hxd.fmt.pak.Build.hl -lib heaps -main hxd.fmt.pak.Build && hl hxd.fmt.pak.Build.hl -exclude-path bitwigProjects,LevelProject/backups,music/exportWAV,models,sfx/stereo && mv res.pak bin/pak/resWeb.pak && haxe -hl hxd.fmt.pak.Build.hl -lib heaps -main hxd.fmt.pak.Build && hl hxd.fmt.pak.Build.hl -exclude-path bitwigProjects,LevelProject/backups,music/exportMP3,models,sfx/stereo && mv res.pak bin/pak/resDesktop.pak",
			"alignment": "right",
			"skipTerminateQuickPick": false,
			"priority": -10
		},
		{
			"text": "DX",
			"color": "orange",
			"commandType":"exec",
			"command": "./prebuild.sh && haxe build.desktop.directx.hxml",
			"alignment": "right",
			"skipTerminateQuickPick": false,
			"priority": -11
		},
		{
			"text": "OpenGL",
			"color": "orange",
			"commandType":"exec",
			"command": "./prebuild.sh && haxe build.desktop.opengl.hxml",
			"alignment": "right",
			"skipTerminateQuickPick": false,
			"priority": -12
		},
		{
			"text": "Run HL",
			"color": "orange",
			"command": "hl bin/game.hl",
			"alignment": "right",
			"skipTerminateQuickPick": false,
			"priority": -13
		},
        {
            "text": "Windows",
            "color": "yellow",
            "command": "mv -n bin/windows/*.exe \"bin/windows/<?php echo $gameName?>\".exe && ffmpeg -y -i res/gfx/icons/icon.png res/gfx/icons/icon.ico && icotool -c -o res/gfx/icons/icon.ico res/gfx/icons/icon.png && cp \"bin/hl/<?php echo $gameId?>.hl\" bin/windows/hlboot.dat && cp bin/pak/resDesktop.pak bin/windows/res.pak && cd bin/ && rm -f windows/*.sav && mv windows \"<?php echo $gameName?>\" && zip \"<?php echo $gameName?>.zip\" -r \"<?php echo $gameName?>/\" && mv \"<?php echo $gameName?>\" windows",
            "alignment": "right",
            "skipTerminateQuickPick": false,
            "priority": -14
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