package ;

import h2d.TileGroup;
import assets.LevelProject;

class LevelRender {
    var walls : TileGroup;

    public function new(level:LevelProject_Level) {
        walls = level.l_Walls.render();
        Game.inst.world.add(walls, Game.LAYER_WALLS);
    }

    public function delete() {
        walls.remove();
    }
}

class Level {
    public static inline var TS = 8;
    public static inline var HTS = 4;
    public var widthTiles : Int;
    public var heightTiles : Int;
    public var widthPixels : Int;
    public var heightPixels : Int;
    var project : LevelProject;
    var level : LevelProject_Level = null;
    var render : LevelRender = null;

    public function new() {
        project = new LevelProject();
    }

    public function delete() {
        if(render != null) {
            render.delete();
        }
    }

    public function loadLevelById(id:Int) {
        var levelName = "Main_" + id;
        var world = project.all_worlds.Default;
        var level = world.getLevel(levelName);
        if(level == null) {
            return false;
        }
        loadLevel(level);
        return true;
    }

    function loadLevel(newLevel:LevelProject_Level) {
        if(render != null) {
            render.delete();
        }
        level = newLevel;
        render = new LevelRender(level);
    }
}