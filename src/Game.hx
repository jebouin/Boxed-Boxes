package ;

import entities.Hero;
import entities.Entity;
import SceneManager.Scene;

class Game extends Scene {
    static var _layer = 0;
    public static var LAYER_CLEAR = _layer++;
    public static var LAYER_BACK = _layer++;
    public static var LAYER_HERO = _layer++;
    public static var LAYER_ENTITIES = _layer++;
    public static var LAYER_LIMITS = _layer++;
    public static var LAYER_WALLS = _layer++;
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
        hero = new Hero();
        level = new Level();
        loadFirstLevel();
    }

    override public function delete() {
        super.delete();
        inst = null;
        level.delete();
        Entity.deleteAll();
    }

    override public function update(dt:Float) {
        super.update(dt);
        Entity.updateAll(dt);
        camera.update(dt);
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

    public function onLevelLoaded() {
        hero.spawn();
        camera.setBounds(level.getCameraBounds());
        camera.setTarget(hero, true);
    }
}