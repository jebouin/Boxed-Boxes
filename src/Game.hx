package ;

import Controller.Action;
import entities.Border;
import entities.Hero;
import entities.Entity;
import SceneManager.Scene;

class Game extends Scene {
    static var _layer = 0;
    public static var LAYER_CLEAR = _layer++;
    public static var LAYER_BACK = _layer++;
    public static var LAYER_BACK_WALLS = _layer++;
    public static var LAYER_BORDER_BACK = _layer++;
    public static var LAYER_HERO = _layer++;
    public static var LAYER_ENTITIES = _layer++;
    public static var LAYER_WALLS = _layer++;
    public static var LAYER_BORDER = _layer++;
    public static var LAYER_DEBUG = _layer++;
    public static var inst : Game;
    public var level : Level;
    public var hero : Hero;
    public var camera : Camera;
    var levelId : Int = 1;

    public function new() {
        super();
        if(inst != null) {
            throw "Game scene already exists";
        }
        inst = this;
        camera = new Camera();
        level = new Level();
        //loadFirstLevel();
        loadLevelById(2);
    }

    override public function delete() {
        super.delete();
        inst = null;
        level.delete();
        Entity.deleteAll();
        Border.deleteAll();
    }

    override public function update(dt:Float) {
        super.update(dt);
        Entity.updateAll(dt);
        Border.updateAll(dt);
        /*for(e in Entity.all) {
            e.debug();
        }
        for(b in Border.all) {
            b.debug();
        }
        trace(" ");*/
        camera.update(dt);
        if(Main.inst.controller.isPressed(Action.retry)) {
            retry();
        }
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
}