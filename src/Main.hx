package ;

import haxe.Timer;
import hxd.System;
import h2d.Tile;
import h3d.mat.Texture;
import h2d.Bitmap;
import hxd.Key;
import Date;
#if int_ng
import integration.Newgrounds;
#elseif int_gj
import integration.Gamejolt;
#end

@:native("")
extern class External {
    static function updateProgress(p:Int):Void;
    static function onGameLoaded():Void;
}

@:build(Macros.buildTemplate())
class Main extends hxd.App {
    public static inline var WIDTH = 320;
    public static inline var HEIGHT = 180;
    public static inline var FPS = 60;
    public static var inst : Main;
    public var hasFocus : Bool;
    var maxDrawCalls : Int;
    var started : Bool;
    var test : h2d.Graphics;

    override function init() {
        engine.fullScreen = false;
        engine.autoResize = true;
        hasFocus = true;
        var window = hxd.Window.getInstance();
        window.addEventTarget(onEvent);
        window.title = GAME_NAME;

        maxDrawCalls = 0;
        #if int_ng
        Newgrounds.init(startGame);
        #elseif int_gj
        Gamejolt.init(startGame);
        #else
        startGame();
        #end

        test = new h2d.Graphics(s2d);
        test.beginFill(0xFF0000);
        test.drawCircle(0, 0, 100);
        test.endFill();
    }
    function startGame() {
        started = true;
    }
    function onEvent(event:hxd.Event) {
        if(!started) return;
        if(event.kind == EFocus) {
            hasFocus = true;
        } else if(event.kind == EFocusLost) {
            hasFocus = false;
        }
    }
    override function update(dt:Float) {
        if(!started) return;
        var cnt = engine.drawCalls;
        if(cnt > maxDrawCalls) {
            maxDrawCalls = cnt;
        }
        #if js
        if(Key.isPressed(Key.F)) {
            engine.fullScreen = !engine.fullScreen;
        }
        #end
        var time = Timer.stamp();
        test.x = Math.cos(2.7 * time) * 200 + 800;
        test.y = Math.sin(2 * time) * 200 + 450;
    }
    public function setFullscreen(v:Bool) {
        if(engine.fullScreen == v) return;
        engine.fullScreen = v;
    }

    static function main() {
        #if js
        var loader = new hxd.net.BinaryLoader("res.pak");
        loader.load();
        loader.onProgress = function(cur:Int, max:Int) {
            var p = Math.floor(100 * cur / max);
            External.updateProgress(p);
        }
        loader.onLoaded = function(bytes:haxe.io.Bytes) {
            var fs = new hxd.fmt.pak.FileSystem();
            fs.addPak(new hxd.fmt.pak.FileSystem.FileInput(bytes));
            hxd.Res.loader = new hxd.res.Loader(fs);
            External.onGameLoaded();
            onAssetsLoaded();
        }
        #elseif debug
        var loader = hxd.Res.initLocal();
        onAssetsLoaded();
        #else
        var loader = hxd.Res.initPak();
        onAssetsLoaded();
        #end
    }

    static function onAssetsLoaded() {
        hxd.Timer.skip();
        inst = new Main();
    }

    public static function println(v:Dynamic) {
        #if debug
            #if js
                js.html.Console.log(Std.string(v));
            #elseif sys
                Sys.println(Std.string(v));
            #else
                trace(Std.string(v));
            #end
        #end
	}
}