package entities;

import h2d.filter.Mask;
import h2d.Tile;
import h2d.TileGroup;
import h2d.ScaleGrid;
import haxe.ds.IntMap;
import h2d.Graphics;
import h2d.col.IBounds;

typedef WallSegment = {pos:Int, length:Int};
typedef Wall = Array<WallSegment>;

class Border {
    public static var tile : Tile;
    public static var tileBack : Tile;
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
        for(b in all) {
            b.updateWalls();
        }
        for(b in all) {
            b.renderMask();
        }
    }

    public var bounds : IBounds;
    var group : TileGroup;
    var groupBack : TileGroup;
    var mask : Graphics;
    public var id(default, null) : Int;
    var wallLeft : Wall;
    var wallRight : Wall;
    var wallUp : Wall;
    var wallDown : Wall;
    var holesLeft : Wall;
    var holesRight : Wall;
    var holesUp : Wall;
    var holesDown : Wall;

    public function new(bounds:IBounds) {
        if(tile == null) {
            tile = Assets.getTile("entities", "border"); 
            tileBack = Assets.getTile("entities", "borderBack"); 
        }
        this.bounds = bounds;
        group = new TileGroup(tile);
        Game.inst.world.add(group, Game.LAYER_BORDER);
        groupBack = new TileGroup(tileBack);
        groupBack.alpha = .15;
        groupBack.blendMode = Add;
        Game.inst.world.add(groupBack, Game.LAYER_BORDER_BACK);
        mask = new Graphics(group);
        group.filter = new Mask(mask);
        render();
        id = all.length;
        all.push(this);
    }

    public function delete() {
        group.remove();
        groupBack.remove();
    }

    public function update(dt:Float) {
        group.x = groupBack.x = bounds.x;
        group.y = groupBack.y = bounds.y;
    }

    public function setBounds(b:IBounds) {
        this.bounds = b;
        render();
    }

    public function render() {
        group.clear();
        groupBack.clear();
        if(bounds.width % Level.TS != 0 || bounds.height % Level.TS != 0) {
            throw "Border size must be a multiple of tile size";
        }
        var wt = Std.int(bounds.width / Level.TS), ht = Std.int(bounds.height / Level.TS);
        for(i in 0...ht) {
            for(j in 0...wt) {
                var ti = (i == 0 ? 0 : (i == ht - 1 ? 2 : 1));
                var tj = (j == 0 ? 0 : (j == wt - 1 ? 2 : 1));
                group.add(j * Level.TS, i * Level.TS, tile.sub(tj * Level.TS, ti * Level.TS, Level.TS, Level.TS));
                groupBack.add(j * Level.TS, i * Level.TS, tileBack.sub(tj * Level.TS, ti * Level.TS, Level.TS, Level.TS));
            }
        }
    }

    public function renderMask() {
        mask.clear();
        mask.beginFill(0xFFFFFF);
        for(segment in wallLeft) {
            mask.drawRect(0, segment.pos, 1, segment.length);
        }
        for(segment in wallRight) {
            mask.drawRect(bounds.width - 1, segment.pos, 1, segment.length);
        }
        for(segment in wallUp) {
            mask.drawRect(segment.pos, 0, segment.length, 1);
        }
        for(segment in wallDown) {
            mask.drawRect(segment.pos, bounds.height - 1, segment.length, 1);
        }
        mask.endFill();
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

    public function updateWalls() {
        function getSegment(l1:Int, r1:Int, l2:Int, r2:Int) {
            var l = Util.imax(l1, l2);
            var r = Util.imin(r1, r2);
            if(l >= r) return null;
            return {pos:l - l1, length:r - l};
        }
        wallLeft = [];
        wallRight = [];
        wallUp = [];
        wallDown = [];
        for(b in all) {
            if(b == this) continue;
            if(bounds.xMin == b.bounds.xMax) {
                var seg = getSegment(bounds.yMin, bounds.yMax, b.bounds.yMin, b.bounds.yMax);
                if(seg != null) {
                    wallLeft.push(seg);
                }
            }
            if(bounds.xMax == b.bounds.xMin) {
                var seg = getSegment(bounds.yMin, bounds.yMax, b.bounds.yMin, b.bounds.yMax);
                if(seg != null) {
                    wallRight.push(seg);
                }
            }
            if(bounds.yMin == b.bounds.yMax) {
                var seg = getSegment(bounds.xMin, bounds.xMax, b.bounds.xMin, b.bounds.xMax);
                if(seg != null) {
                    wallUp.push(seg);
                }
            }
            if(bounds.yMax == b.bounds.yMin) {
                var seg = getSegment(bounds.xMin, bounds.xMax, b.bounds.xMin, b.bounds.xMax);
                if(seg != null) {
                    wallDown.push(seg);
                }
            }
        }
        holesLeft = simplifyWall(wallLeft);
        holesRight = simplifyWall(wallRight);
        holesUp = simplifyWall(wallUp);
        holesDown = simplifyWall(wallDown);
        wallLeft = invertWall(holesLeft, bounds.height);
        wallRight = invertWall(holesRight, bounds.height);
        wallUp = invertWall(holesUp, bounds.width);
        wallDown = invertWall(holesDown, bounds.width);
    }

    public static function simplifyWall(w:Wall) {
        var res = [];
        var i = 0;
        while(i < w.length) {
            var seg = w[i];
            var j = i + 1;
            while(j < w.length && w[j].pos == seg.pos + seg.length) {
                seg.length += w[j].length;
                j++;
            }
            res.push(seg);
            i = j;
        }
        return res;
    }

    public static function invertWall(w:Wall, totalLength:Int) {
        var res = [];
        var last = 0;
        for(seg in w) {
            if(seg.pos > last) {
                res.push({pos:last, length:seg.pos - last});
            }
            last = seg.pos + seg.length;
        }
        if(last < totalLength) {
            res.push({pos:last, length: totalLength - last});
        }
        return res;
    }
}