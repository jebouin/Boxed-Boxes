package ;

import h2d.col.IBounds;
import hxd.Pixels;
import h2d.Graphics;
import save.Save;
import entities.Gem;
import Controller.Action;
import entities.Border;
import entities.Hero;
import entities.Entity;
import SceneManager.Scene;

enum GameState {
    TransitionIn;
    Play;
    TransitionOut;
}

class Game extends Scene {
    public static var TRANSITION_IN_TIME = 0.5;
    public static var TRANSITION_OUT_TIME = 1.5;
    static var _layer = 0;
    public static var LAYER_CLEAR = _layer++;
    public static var LAYER_BACK = _layer++;
    public static var LAYER_BACK_WALLS = _layer++;
    public static var LAYER_BORDER_BACK = _layer++;
    public static var LAYER_HERO = _layer++;
    public static var LAYER_ENTITIES = _layer++;
    public static var LAYER_WALLS = _layer++;
    public static var LAYER_BORDER = _layer++;
    public static var LAYER_GEM = _layer++;
    public static var LAYER_DEBUG = _layer++;
    public static var LAYER_WIN = _layer++;
    public static var inst : Game;
    public var level : Level;
    public var hero : Hero;
    public var camera : Camera;
    var levelId : Int = 1;
    public var state(default, set) : GameState;
    var stateTimer : Float = 0.;
    var winGraphics : Graphics;
    var ramp : Pixels;

    public function new(initial:Bool, levelId:Int) {
        super();
        if(inst != null) {
            throw "Game scene already exists";
        }
        inst = this;
        camera = new Camera();
        level = new Level();
        winGraphics = new Graphics();
        world.add(winGraphics, LAYER_WIN);
        winGraphics.visible = false;
        state = initial ? Play : TransitionIn;
        //loadFirstLevel();
        loadLevelById(levelId);
    }

    override public function delete() {
        super.delete();
        inst = null;
        level.delete();
        Entity.deleteAll();
        Border.deleteAll();
        Gem.deleteAll();
    }

    override public function update(dt:Float) {
        super.update(dt);
        stateTimer += dt;
        if(state == Play) {
            Entity.updateAll(dt);
            Border.updateAll(dt);
            Gem.updateAll(dt);
            camera.update(dt);
            if(Main.inst.controller.isPressed(Action.retry)) {
                retry();
            }
        } else if(state == TransitionOut) {
            updateTransitionOut(dt);
            if(stateTimer >= TRANSITION_OUT_TIME) {
                loadNextLevel();
                state = TransitionIn;
            }
        } else if(state == TransitionIn) {
            if(stateTimer >= TRANSITION_IN_TIME) {
                state = Play;
            }
        }
    }

    public function levelComplete() {
        Save.gameData.data.completeLevel(levelId);
        var rampTile = Assets.getTile("entities", "ramp" + getLevelGroup());
        ramp = rampTile.getTexture().capturePixels(0, 0, IBounds.fromValues(rampTile.ix, rampTile.iy, rampTile.iwidth, rampTile.iheight));
        state = TransitionOut;
    }

    public function loadFirstLevel() {
        levelId = 1;
        level.loadLevelById(levelId);
    }

    public function loadNextLevel() {
        if(level.loadLevelById(levelId + 1)) {
            levelId++;
        } else {
            loadFirstLevel();
        }
    }

    public function loadLevelById(id:Int) {
        levelId = id;
        level.loadLevelById(levelId);
    }

    public function onLevelLoaded() {
        hero.spawn();
        camera.setBounds(level.getCameraBounds());
        camera.setTarget(hero, true);
    }

    public function retry() {
        loadLevelById(levelId);
    }

    public function getLevelGroup(?levelId:Int=-1) {
        if(levelId == -1) {
            levelId = this.levelId;
        }
        return Std.int((levelId - 1) / (Title.GROUP_WIDTH * Title.GROUP_HEIGHT));
    }

    public function set_state(v:GameState) {
        state = v;
        stateTimer = 0.;
        if(state == TransitionOut) {
            winGraphics.visible = true;
            for(g in Gem.all) {
                winGraphics.x = g.anim.x;
                winGraphics.y = g.anim.y;
            }
        } else {
            winGraphics.visible = false;
        }
        return v;
    }

    function updateTransitionOut(dt:Float) {
        function drawRect(col:Int, r:Float) {
            var c = col & 0xFFFFFF, al = (col >>> 24) / 255.;
            winGraphics.beginFill(c, al);
            winGraphics.moveTo(0, -r);
            winGraphics.lineTo(r, 0);
            winGraphics.lineTo(0, r);
            winGraphics.lineTo(-r, 0);
            winGraphics.lineTo(0, -r);
            winGraphics.endFill();
        }
        var endTime = TRANSITION_OUT_TIME - .8;
        var t = stateTimer / endTime;
        for(i in 0...ramp.width) {
            var tt = i / ramp.width;
            var col = ramp.getPixel(i, 0);
            var dt = t - tt;
            if(dt <= 0) continue;
            dt = 1. - Math.pow(1. - dt, 2);
            var r = dt * 1.5 * Main.WIDTH;
            drawRect(col, r);
        }
    }
}