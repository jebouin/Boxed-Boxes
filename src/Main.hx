package ;

import hxd.System;
import h2d.Tile;
import h2d.Bitmap;
import h3d.mat.Texture;
import ui.FPSCounter;
import Controller;
import hxd.Key;

@:native("")
extern class External {
    static function updateProgress(p:Int):Void;
    static function onGameLoaded():Void;
}

@:build(Macros.buildTemplate())
class Main extends hxd.App {
    public static inline var WIDTH = 320;
    public static inline var HEIGHT = 180;
    public static inline var WIDTH2 = 160;
    public static inline var HEIGHT2 = 90;
    public static inline var FPS = 60;
    public static var inst : Main;
    public var controller : Controller;
    public var hasFocus : Bool = true;
    public var screen : Bitmap;
    public var screenTexture : Texture;
    public var hud : Bitmap;
    public var hudTexture : Texture;
    public var scale(default, null) : Int;
    var timeToSimulate : Float = 0.;
    var timeToSimulateConstantRate : Float = 0.;
    var started : Bool = false;
    var maxDrawCalls : Int = 0;
    public var fpsCounter : FPSCounter;
    public var doubleTick : Bool = false;
    var hitStopTimer : Float = 0.;
    public var onHitStopDone : Void->Void = null;

    override function init() {
        initController();
        Assets.init();
        engine.fullScreen = false;
        engine.autoResize = true;
        engine.backgroundColor = Palette.BLACK;
        screenTexture = new Texture(WIDTH, HEIGHT, [Target]);
        screen = new Bitmap(Tile.fromTexture(screenTexture), s2d);
        hudTexture = new Texture(WIDTH, HEIGHT, [Target]);
        hud = new Bitmap(Tile.fromTexture(hudTexture), s2d);
        updateScale();
        var window = hxd.Window.getInstance();
        window.addEventTarget(onEvent);
        #if (debug || sys)
        window.vsync = false;
        #end
        window.title = GAME_NAME;
        SceneManager.init();
        fpsCounter = new FPSCounter(Assets.font);
        startGame();
    }
    function startGame() {
        started = true;
        new Game();
    }
    function initController() {
        controller = new Controller();
        #if debug
        controller.bindKeyAsStickXY(Action.moveX, Action.moveY, Key.F, Key.T, Key.S, Key.R);
        controller.bindKey(Action.jump, Key.N);
        #else
        controller.bindKeyAsStickXY(Action.moveX, Action.moveY, Key.W, Key.D, Key.S, Key.A);
        controller.bindKeyAsStickXY(Action.moveX, Action.moveY, Key.UP, Key.RIGHT, Key.DOWN, Key.LEFT);
        controller.bindKey(Action.jump, [Key.X, Key.SPACE, Key.SHIFT]);
        #end
        controller.bindPadLStick(Action.moveX, Action.moveY);
        controller.bindPadRStick(Action.moveX, Action.moveY);
        controller.bindPadButtonsAsStickXY(Action.moveX, Action.moveY, PadButton.DPAD_UP, PadButton.DPAD_RIGHT, PadButton.DPAD_DOWN, PadButton.DPAD_LEFT);
        controller.bindPad(Action.jump, [PadButton.A, PadButton.B, PadButton.X, PadButton.Y]);
    }
    function onEvent(event:hxd.Event) {
        if(!started) return;
        if(event.kind == EFocus) {
            hasFocus = true;
        } else if(event.kind == EFocusLost) {
            hasFocus = false;
        }
    }
    public function setFullscreen(v:Bool) {
        if(engine.fullScreen == v) return;
        engine.fullScreen = v;
    }
    public function setVSync(v:Bool) {
        #if !sys
        if(!v) return;
        #end
        var window = hxd.Window.getInstance();
        window.vsync = v;
    }
    override function onResize() {
        hxd.Timer.skip();
        fpsCounter.onResize();
        updateScale();
    }
    function updateScale() {
        scale = Std.int(Math.min(s2d.width / WIDTH, s2d.height / HEIGHT));
        screen.setScale(scale);
        hud.setScale(scale);
        var sx = Std.int(Util.quantize(s2d.width * .5 - WIDTH * scale * .5, scale));
        var sy = Std.int(Util.quantize(s2d.height * .5 - HEIGHT * scale * .5, scale));
        screen.x = hud.x = sx;
        screen.y = hud.y = sy;
    }
    function tick() {
        var dt = 1. / 60;
        #if debug
        if(Key.isDown(Key.V)) {
            dt *= .1;
        }
        #end
        SceneManager.update(dt);
        SceneManager.updateBack(dt);
    }
    function tickConstantRate() {
        var dt = 1. / 60;
        SceneManager.updateConstantRate(dt);
    }
    override function update(dt:Float) {
        if(!started) return;
        controller.update(dt);
        if(hasFocus) {
            timeToSimulateConstantRate += dt;
            if(hitStopTimer > 0) {
                var rem = Util.fmin(dt, hitStopTimer);
                dt -= rem;
                hitStopTimer -= rem;
                if(hitStopTimer == 0 && onHitStopDone != null) {
                    onHitStopDone();
                    onHitStopDone = null;
                }
            }
            #if debug
            if(Key.isDown(Key.C)) {
                dt *= .1;
            }
            #end
            timeToSimulate += dt;
            if(timeToSimulate > 1.) {
                timeToSimulate = 1.;
            }
            var ticks = 5;
            while(timeToSimulate >= 1. / FPS && ticks > 0) {
                timeToSimulate -= 1. / FPS;
                tick();
                if(SceneManager.scenes.length == 0) {
                    System.exit();
                }
                controller.afterUpdate();
                ticks--;
            }
            if(doubleTick) {
                tick();
                doubleTick = false;
            }
            ticks = 5;
            while(timeToSimulateConstantRate >= 1. / FPS && ticks > 0) {
                timeToSimulateConstantRate -= 1. / FPS;
                tickConstantRate();
                ticks--;
            }
            SceneManager.updateAfter(dt);
        }
        var cnt = engine.drawCalls;
        if(cnt > maxDrawCalls) {
            maxDrawCalls = cnt;
            #if show_counts
            #end
            trace("Draw calls: " + maxDrawCalls);
        }
        #if debug
        if(Key.isPressed(Key.ESCAPE)) {
            System.exit();
        }
        fpsCounter.update();
        #end
    }
    public function hitStop(duration:Float) {
        hitStopTimer = duration;
    }
    override function render(e:h3d.Engine) {
        e.pushTarget(screenTexture);
        e.clear(engine.backgroundColor, 1);
        SceneManager.renderWorld(e);
        e.popTarget();
        e.pushTarget(hudTexture);
        e.clear(engine.backgroundColor, 1);
        SceneManager.renderHUD(e);
        e.popTarget();
        s2d.render(e);
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