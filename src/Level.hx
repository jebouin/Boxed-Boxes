package ;

import entities.Border;
import entities.Box;
import h2d.Tile;
import entities.Hero;
import entities.Entity;
import entities.Solid;
import h2d.col.IBounds;
import h2d.TileGroup;
import assets.LevelProject;

class LevelRender {
    var walls : TileGroup;
    var backWalls : TileGroup;

    public function new(level:LevelProject_Level) {
        walls = level.l_Walls.render();
        Game.inst.world.add(walls, Game.LAYER_WALLS);
        backWalls = level.l_BackWalls.render();
        Game.inst.world.add(backWalls, Game.LAYER_BACK_WALLS);
    }

    public function delete() {
        walls.remove();
        backWalls.remove();
    }
}

class Level {
    public static inline var TS = 8;
    public static inline var HTS = 4;
    public var widthTiles : Int;
    public var heightTiles : Int;
    public var widthPixels : Int;
    public var heightPixels : Int;
    public var heroSpawnX(default, null) : Int = 0;
    public var heroSpawnY(default, null) : Int = 0;
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

    public function clear() {
        if(render != null) {
            render.delete();
        }
        Entity.deleteAll();
        Solid.deleteAll();
        entities.Border.deleteAll();
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
        clear();
        level = newLevel;
        widthTiles = level.l_Walls.cWid;
        heightTiles = level.l_Walls.cHei;
        widthPixels = widthTiles * TS;
        heightPixels = heightTiles * TS;
        render = new LevelRender(level);
        loadEntities();
        Game.inst.onLevelLoaded();
        trace("Solid count: " + Solid.all.length);
        trace("Entity count: " + Entity.all.length);
    }

    function loadEntities() {
        for(e in level.l_Entities.all_Hero) {
            heroSpawnX = e.cx * TS;
            heroSpawnY = e.cy * TS;
        }
        Game.inst.hero = new Hero();
        for(tile in level.l_Walls.autoTiles) {
            var x = tile.renderX;
            var y = tile.renderY;
            var tags = project.all_tilesets.Tileset.getAllTags(tile.tileId);
            if(tags.length == 0) continue;
            var tag = tags[0];
            if(tag == Full) {
                new Solid(x, y, TS, TS);
            }
        }
        for(b in level.l_Entities.all_Border) {
            new Border(IBounds.fromValues(b.cx * TS, b.cy * TS, b.width, b.height));
        }
        for(b in level.l_Entities.all_Box) {
            new Box(b.cx * TS, b.cy * TS, b.width, b.height);
        }
        Entity.updateAllBorders();
        for(e in Entity.all) {
            trace(e, e.borderId);
        }
    }

    public function getCameraBounds() {
        return IBounds.fromValues(0, 0, widthPixels, heightPixels);
    }
}