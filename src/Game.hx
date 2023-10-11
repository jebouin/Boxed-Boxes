package ;

import fx.Fx;
import h2d.col.Point;
import fx.Death;
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
    Dead;
    TransitionOut;
}

class Game extends Scene {
    public static var MAX_MOVE_STEPS = 100;
    public static var TRANSITION_IN_TIME = 0.5;
    public static var DEAD_TIME = .8;
    public static var TRANSITION_OUT_TIME = 1.3;
    static var _layer = 0;
    public static var LAYER_CLEAR = _layer++;
    public static var LAYER_BACK = _layer++;
    public static var LAYER_FX_BACK = _layer++;
    public static var LAYER_BACK_WALLS = _layer++;
    public static var LAYER_BORDER_BACK = _layer++;
    public static var LAYER_FX_MID = _layer++;
    public static var LAYER_HERO = _layer++;
    public static var LAYER_ENTITIES = _layer++;
    public static var LAYER_WALLS = _layer++;
    public static var LAYER_BORDER = _layer++;
    public static var LAYER_GEM = _layer++;
    public static var LAYER_FX_FRONT = _layer++;
    public static var LAYER_FLASH = _layer++;
    public static var LAYER_DEBUG = _layer++;
    public static var LAYER_WIN = _layer++;
    public static var inst : Game;
    public var level : Level;
    public var hero : Hero;
    public var camera : Camera;
    var background : Background;
    var levelId : Int = 1;
    public var state(default, set) : GameState;
    var stateTimer : Float = 0.;
    var winGraphics : Graphics;
    public var ramp : Pixels;
    public var fx : Fx;
    var deathFx : Death;
    var prevCameraPos : Point;

    public function new(initial:Bool, globalLevelId:Int) {
        super();
        if(inst != null) {
            throw "Game scene already exists";
        }
        inst = this;
        camera = new Camera();
        level = new Level();
        background = new Background();
        winGraphics = new Graphics();
        world.add(winGraphics, LAYER_WIN);
        winGraphics.visible = false;
        state = Play;
        levelId = globalLevelId;
        loadLevelById(levelId);
        fx = new Fx(world, world, world, LAYER_FX_FRONT, LAYER_FX_MID, LAYER_FX_BACK);
        camera.update(0);
    }

    override public function delete() {
        super.delete();
        inst = null;
        level.delete();
        Entity.deleteAll();
        Border.deleteAll();
        Gem.deleteAll();
        if(deathFx != null) {
            deathFx.delete();
        }
        background.delete();
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
            if(Main.inst.controller.isPressed(Action.pause)) {
                delete();
                new Title(levelId);
            }
        } else if(state == TransitionOut) {
            updateTransitionOut(dt);
            if(stateTimer >= TRANSITION_OUT_TIME) {
                var group = getLevelGroup();
                var maskX = winGraphics.x + world.x;
                var maskY = winGraphics.y + world.y;
                new LevelComplete(group, levelId - (group * Title.GROUP_WIDTH * Title.GROUP_HEIGHT), levelId, maskX, maskY);
                Audio.playSound("levelComplete");
                delete();
                return;
            }
        } else if(state == TransitionIn) {
            if(stateTimer >= TRANSITION_IN_TIME) {
                state = Play;
            }
        } else if(state == Dead) {
            var t = stateTimer / DEAD_TIME;
            deathFx.update(dt, t);
            camera.targetX = level.heroSpawnX + 4;
            camera.targetY = level.heroSpawnY + 8;
            var targetPos = camera.getClampedPosition(level.getCameraBounds());
            if(t < .4) {
                t = 0.;
            } else {
                t = Util.smoothStep((t - .4) / .6);
            }
            var pos = new Point(t * targetPos.x + (1. - t) * prevCameraPos.x, t * targetPos.y + (1. - t) * prevCameraPos.y);
            camera.clampedTargetX = pos.x;
            camera.clampedTargetY = pos.y;
            camera.update(dt);
            if(stateTimer >= DEAD_TIME) {
                retry();
            }
        }
        background.update(dt);
        fx.update(dt);
    }

    override public function updateConstantRate(dt:Float) {
        if(state == Dead) {
            if(deathFx != null) {
                deathFx.updateConstantRate(dt);
            }
        }
        fx.updateConstantRate(dt);
        camera.updateConstantRate(dt);
    }

    public function levelComplete() {
        fx.gem();
        Save.gameData.data.completeLevel(levelId);
        updateRamp();
        state = TransitionOut;
    }

    public function updateRamp() {
        var rampTile = Assets.getTile("entities", "ramp" + getLevelGroup());
        ramp = rampTile.getTexture().capturePixels(0, 0, IBounds.fromValues(rampTile.ix, rampTile.iy, rampTile.iwidth, rampTile.iheight));
        return ramp;
    }

    public function loadFirstLevel() {
        levelId = 1;
        level.loadLevelById(levelId);
    }

    public function loadLastLevel() {
        levelId = Title.GROUP_COUNT * Title.GROUP_WIDTH * Title.GROUP_HEIGHT;
    }

    public function loadNextLevel() {
        if(level.loadLevelById(levelId + 1)) {
            levelId++;
        } else {
            loadFirstLevel();
        }
    }

    public function loadPreviousLevel() {
        if(level.loadLevelById(levelId - 1)) {
            levelId--;
        } else {
            loadLastLevel();
        }
    }

    public function loadLevelById(id:Int) {
        levelId = id;
        level.loadLevelById(levelId);
    }

    public function onLevelLoaded() {
        hero.spawn();
        var bounds = level.getCameraBounds();
        camera.setBounds(bounds);
        camera.setTarget(hero, true);
        background.loadLevel(levelId, bounds.width, bounds.height);
    }

    public function retry() {
        state = Play;
        loadLevelById(levelId);
        camera.update(0);
    }

    public function onDeath(dx:Float, dy:Float) {
        state = Dead;
        if(deathFx != null) {
            deathFx.delete();
        }
        deathFx = new Death(hero.x, hero.y, level.heroSpawnX, level.heroSpawnY, dx, dy);
        prevCameraPos = camera.getClampedPosition(level.getCameraBounds());
        camera.resetTarget();
        Main.inst.hitStop(.1);
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
        if(state != Dead && deathFx != null) {
            deathFx.delete();
            deathFx = null;
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
        var endTime = TRANSITION_OUT_TIME - .5;
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

    public function forceCompleteLevel() {
        for(g in Gem.all) {
            hero.x = Std.int(g.anim.x);
            hero.y = Std.int(g.anim.y);
        }
    }
}