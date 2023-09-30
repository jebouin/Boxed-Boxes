package entities;

import h2d.Tile;
import h2d.TileGroup;
import h2d.ScaleGrid;
import haxe.ds.IntMap;
import h2d.Graphics;
import h2d.col.IBounds;

class Border {
    public static var all : Array<Border> = [];

    public static function deleteAll() {
        for(b in all) {
            b.delete();
        }
        all = [];
    }

    public static function updateAll(dt:Float) {
        for(b in all) {
            b.update(dt);
        }
    }

    public static var tile : Tile;
    public var bounds : IBounds;
    var group : TileGroup;
    public var id(default, null) : Int;

    public function new(bounds:IBounds) {
        if(tile == null) {
            tile = Assets.getTile("entities", "border"); 
        }
        this.bounds = bounds;
        group = new TileGroup(tile);
        Game.inst.world.add(group, Game.LAYER_BORDER);
        render();
        id = all.length;
        all.push(this);
    }

    public function delete() {
        group.remove();
    }

    public function update(dt:Float) {
        group.x = bounds.x;
        group.y = bounds.y;
    }

    public function setBounds(b:IBounds) {
        this.bounds = b;
        render();
    }

    public function render() {
        group.clear();
        if(bounds.width % Level.TS != 0 || bounds.height % Level.TS != 0) {
            throw "Border size must be a multiple of tile size";
        }
        var wt = Std.int(bounds.width / Level.TS), ht = Std.int(bounds.height / Level.TS);
        for(i in 0...ht) {
            for(j in 0...wt) {
                var ti = (i == 0 ? 0 : (i == ht - 1 ? 2 : 1));
                var tj = (j == 0 ? 0 : (j == wt - 1 ? 2 : 1));
                group.add(j * Level.TS, i * Level.TS, tile.sub(tj * Level.TS, ti * Level.TS, Level.TS, Level.TS));
            }
        }
    }

    public function stepLeft() {
        bounds.x -= 1;
        for(e in Entity.all) {
            if(e.canPushBorder) continue;
            var isInside = e.borderId == id;
            if((isInside && bounds.xMax < e.x + e.hitbox.xMax) || (!isInside && intersectsEntity(e))) {
                var chain = new IntMap<Bool>();
                if(!e.pushLeft(chain)) {
                    bounds.x += 1;
                    return false;
                }
            }
        }
        return true;
    }
    public function stepRight() {
        bounds.x += 1;
        for(e in Entity.all) {
            if(e.canPushBorder) continue;
            var isInside = e.borderId == id;
            if((isInside && bounds.xMin > e.x + e.hitbox.xMin) || (!isInside && intersectsEntity(e))) {
                var chain = new IntMap<Bool>();
                if(!e.pushRight(chain)) {
                    bounds.x -= 1;
                    return false;
                }
            }
        }
        return true;
    }
    public function stepUp() {
        bounds.y -= 1;
        for(e in Entity.all) {
            if(e.canPushBorder) continue;
            var isInside = e.borderId == id;
            if((isInside && bounds.yMax < e.y + e.hitbox.yMax) || (!isInside && intersectsEntity(e))) {
                var chain = new IntMap<Bool>();
                if(!e.pushUp(chain)) {
                    bounds.y += 1;
                    return false;
                }
            }
        }
        return true;
    }
    public function stepDown() {
        bounds.y += 1;
        for(e in Entity.all) {
            if(e.canPushBorder) continue;
            var isInside = e.borderId == id;
            if((isInside && bounds.yMin > e.y + e.hitbox.yMin) || (!isInside && intersectsEntity(e))) {
                var chain = new IntMap<Bool>();
                if(!e.pushDown(chain)) {
                    bounds.y -= 1;
                    return false;
                }
            }
        }
        return true;
    }
    public function pushLeft(chain:IntMap<Bool>) {
        bounds.x--;
        for(b in all) {
            if(b == this || !collides(b) || chain.exists(b.id)) continue;
            chain.set(this.id, true);
            if(!b.pushLeft(chain)) {
                bounds.x++;
                return false;
            }
            chain.remove(this.id);
        }
        bounds.x++;
        return stepLeft();
    }
    public function pushRight(chain:IntMap<Bool>) {
        bounds.x++;
        for(b in all) {
            if(b == this || !collides(b) || chain.exists(b.id)) continue;
            chain.set(this.id, true);
            if(!b.pushRight(chain)) {
                bounds.x--;
                return false;
            }
            chain.remove(this.id);
        }
        bounds.x--;
        return stepRight();
    }
    public function pushUp(chain:IntMap<Bool>) {
        bounds.y--;
        for(b in all) {
            if(b == this || !collides(b) || chain.exists(b.id)) continue;
            chain.set(this.id, true);
            if(!b.pushUp(chain)) {
                bounds.y++;
                return false;
            }
            chain.remove(this.id);
        }
        bounds.y++;
        return stepUp();
    }
    public function pushDown(chain:IntMap<Bool>) {
        bounds.y++;
        for(b in all) {
            if(b == this || !collides(b) || chain.exists(b.id)) continue;
            chain.set(this.id, true);
            if(!b.pushDown(chain)) {
                bounds.y--;
                return false;
            }
            chain.remove(this.id);
        }
        bounds.y--;
        return stepDown();
    }

    inline public function containsEntity(e:Entity) {
        return e.x + e.hitbox.xMin >= bounds.xMin && e.x + e.hitbox.xMax <= bounds.xMax && e.y + e.hitbox.yMin >= bounds.yMin && e.y + e.hitbox.yMax <= bounds.yMax;
    }
    inline public function intersectsEntity(e:Entity) {
        return e.x + e.hitbox.xMin < bounds.xMax && e.x + e.hitbox.xMax > bounds.xMin && e.y + e.hitbox.yMin < bounds.yMax && e.y + e.hitbox.yMax > bounds.yMin;
    }
    inline public function collides(other:Border) {
        return !(bounds.xMin >= other.bounds.xMax
            || bounds.xMax <= other.bounds.xMin
            || bounds.yMin >= other.bounds.yMax
            || bounds.yMax <= other.bounds.yMin);
    }
}