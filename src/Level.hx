package ;

import h2d.col.Collider;
import haxe.ds.Vector;
import entities.Gem;
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
    public static var project : LevelProject = null;
    public static var tileIdToCollision : Vector<Enum_Collision>;
    public var widthTiles : Int;
    public var heightTiles : Int;
    public var widthPixels : Int;
    public var heightPixels : Int;
    public var heroSpawnX(default, null) : Int = 0;
    public var heroSpawnY(default, null) : Int = 0;
    var level : LevelProject_Level = null;
    var render : LevelRender = null;
    var levelCollisions : Vector<Vector<Enum_Collision> >;

    public static function init() {
        project = new LevelProject();
        tileIdToCollision = new Vector<Enum_Collision>(1024);
        for(tileId in 0...1024) {
            var tags = project.all_tilesets.Tileset.getAllTags(tileId);
            if(tags.length != 1) {
                tileIdToCollision[tileId] = None;
            } else {
                tileIdToCollision[tileId] = tags[0];
            }
        }
    }

    public function new() {
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
        entities.Gem.deleteAll();
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
        loadCollisions();
        loadEntities();
        Game.inst.onLevelLoaded();
        trace("Solid count: " + Solid.all.length);
        trace("Entity count: " + Entity.all.length);
    }

    function loadEntities() {
        inline function isCollisionSolid(col:Enum_Collision) {
            return col == Full || col == PlatformLeft || col == PlatformRight || col == PlatformUp || col == PlatformDown;
        }
        // Load solids
        inline function createSolid(x:Int, y:Int, width:Int, height:Int, tag:Enum_Collision) {
            if(x == 0) {
                x -= TS;
                width += TS;
            }
            if(x + width == widthPixels) {
                width += TS;
            }
            new Solid(x, y, width, height, tag);
        }
        for(i in 0...heightTiles) {
            var curTag = levelCollisions[i][0];
            var l = 0;
            for(r in 0...widthTiles) {
                var tag = levelCollisions[i][r];
                if(tag != curTag) {
                    if(isCollisionSolid(curTag)) {
                        createSolid(l * TS, i * TS, (r - l) * TS, TS, curTag);
                    }
                    curTag = tag;
                    l = r;
                }
            }
            if(isCollisionSolid(curTag)) {
                createSolid(l * TS, i * TS, (widthTiles - l) * TS, TS, curTag);
            }
        }
        createSolid(0, -(3 * TS - 2), widthPixels, TS, Full);
        // Load borders
        for(b in level.l_Entities.all_Border) {
            new Border(IBounds.fromValues(b.cx * TS, b.cy * TS, b.width, b.height));
        }
        for(b in entities.Border.all) {
            b.updateWalls();
            b.render();
            b.renderMask();
            b.update(0);
        }
        // Load entities
        for(e in level.l_Entities.all_Hero) {
            heroSpawnX = e.cx * TS;
            heroSpawnY = e.cy * TS;
        }
        Game.inst.hero = new Hero();
        for(b in level.l_Entities.all_Box) {
            new Box(b.cx * TS, b.cy * TS, b.width, b.height);
        }
        for(g in level.l_Entities.all_Gem) {
            new Gem(Game.inst.getLevelGroup(), g.pixelX, g.pixelY);
        }
    }

    function loadCollisions() {
        levelCollisions = new Vector<Vector<Enum_Collision> >(heightTiles);
        for(y in 0...heightTiles) {
            levelCollisions[y] = new Vector<Enum_Collision>(widthTiles);
            for(x in 0...widthTiles) {
                levelCollisions[y][x] = None;
            }
        }
        for(tile in level.l_Walls.autoTiles) {
            var tx = Std.int(tile.renderX / TS);
            var ty = Std.int(tile.renderY / TS);
            var tag = tileIdToCollision[tile.tileId];
            levelCollisions[ty][tx] = tag;
        }
    }

    public function getCameraBounds() {
        return IBounds.fromValues(0, 0, widthPixels, heightPixels);
    }

    public function entityTouchesDeath(e:Entity) {
        if(e.x + e.hitbox.xMax < 0) {
            return {dx: -1, dy: 0};
        } else if(e.x + e.hitbox.xMin > widthPixels) {
            return {dx: 1, dy: 0};
        } else if(e.y + e.hitbox.yMin > heightPixels) {
            return {dx: 0, dy: 1};
        }
        var margin = 2, spikeLength = 3;
        var bounds = IBounds.fromValues(e.x + e.hitbox.xMin + margin, e.y + e.hitbox.yMin + margin, e.hitbox.width - margin * 2, e.hitbox.height - margin * 2);
        var tx1 = Std.int(bounds.xMin / TS);
        var ty1 = Std.int(bounds.yMin / TS);
        var tx2 = Std.int(bounds.xMax / TS);
        var ty2 = Std.int(bounds.yMax / TS);
        for(tx in tx1...tx2 + 1) {
            if(tx < 0 || tx >= widthTiles) continue;
            for(ty in ty1...ty2 + 1) {
                if(ty < 0 || ty >= heightTiles) continue;
                var boundsUp = IBounds.fromValues(tx * TS, ty * TS, TS, spikeLength);
                var boundsDown = IBounds.fromValues(tx * TS, ty * TS + TS - spikeLength, TS, spikeLength);
                var boundsLeft = IBounds.fromValues(tx * TS, ty * TS, spikeLength, TS);
                var boundsRight = IBounds.fromValues(tx * TS + TS - spikeLength, ty * TS, spikeLength, TS);
                var col = levelCollisions[ty][tx];
                if(col == SpikeU && boundsUp.intersects(bounds)) {
                    return {dx: 0, dy: -1};
                } else if(col == SpikeD && boundsDown.intersects(bounds)) {
                    return {dx: 0, dy: 1};
                } else if(col == SpikeL && boundsLeft.intersects(bounds)) {
                    return {dx: -1, dy: 0};
                } else if(col == SpikeR && boundsRight.intersects(bounds)) {
                    return {dx: 1, dy: 0};
                } else if(col == SpikeUL && (boundsUp.intersects(bounds) || boundsLeft.intersects(bounds))) {
                    return {dx: -1, dy: -1};
                } else if(col == SpikeUR && (boundsUp.intersects(bounds) || boundsRight.intersects(bounds))) {
                    return {dx: 1, dy: -1};
                } else if(col == SpikeDL && (boundsDown.intersects(bounds) || boundsLeft.intersects(bounds))) {
                    return {dx: -1, dy: 1};
                } else if(col == SpikeDR && (boundsDown.intersects(bounds) || boundsRight.intersects(bounds))) {
                    return {dx: 1, dy: 1};
                }
            }
        }
        return {dx: 0, dy: 0};
    }
}