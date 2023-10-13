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
    public static var idToBorder : IntMap<Border> = new IntMap<Border>();

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
        idToBorder.set(id, this);
    }

    public function delete() {
        group.remove();
        groupBack.remove();
        idToBorder.remove(id);
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

    public function canStepLeft(res:StepResult) {
        res.pushedBorders.set(this.id, true);
        bounds.x--;
        updateWalls();
        for(e in Entity.all) {
            if(e.canPushBorders || res.pushedEntities.exists(e.id)) continue;
            if(verticalWallIntersectsEntity(e, e.isInside)) {
                res.triedPushingHorizontal = true;
                e.tryStepLeft(res, true, true);
                if(!res.success) {
                    res.fail();
                    return;
                }
            } else if(rightBorderIntersectsEntity(e)) {
                res.fail();
                return;
            }
        }
        for(b in all) {
            if(b == this || !collides(b) || res.pushedBorders.exists(b.id)) continue;
            b.canStepLeft(res);
            if(!res.success) {
                res.fail();
                return;
            }
        }
    }
    public function canStepRight(res:StepResult) {
        res.pushedBorders.set(this.id, true);
        bounds.x++;
        updateWalls();
        for(e in Entity.all) {
            if(e.canPushBorders || res.pushedEntities.exists(e.id)) continue;
            if(verticalWallIntersectsEntity(e, e.isInside)) {
                res.triedPushingHorizontal = true;
                e.tryStepRight(res, true, true);
                if(!res.success) {
                    res.fail();
                    return;
                }
            } else if(leftBorderIntersectsEntity(e)) {
                res.fail();
                return;
            }
        }
        for(b in all) {
            if(b == this || !collides(b) || res.pushedBorders.exists(b.id)) continue;
            b.canStepRight(res);
            if(!res.success) {
                res.fail();
                return;
            }
        }
    }
    public function canStepUp(res:StepResult) {
        res.pushedBorders.set(this.id, true);
        bounds.y--;
        updateWalls();
        for(e in Entity.all) {
            if(e.canPushBorders || res.pushedEntities.exists(e.id)) continue;
            if(horizontalWallIntersectsEntity(e, e.isInside)) {
                e.tryStepUp(res, true, true);
                if(!res.success) {
                    res.fail();
                    return;
                }
            } else if(bottomBorderIntersectsEntity(e)) {
                res.fail();
                return;
            }
        }
        for(b in all) {
            if(b == this || !collides(b) || res.pushedBorders.exists(b.id)) continue;
            b.canStepUp(res);
            if(!res.success) {
                res.fail();
                return;
            }
        }
    }
    public function canStepDown(res:StepResult) {
        res.pushedBorders.set(this.id, true);
        bounds.y++;
        updateWalls();
        for(e in Entity.all) {
            if(e.canPushBorders || res.pushedEntities.exists(e.id)) continue;
            if(horizontalWallIntersectsEntity(e, e.isInside)) {
                e.tryStepDown(res, true, true);
                if(!res.success) {
                    res.fail();
                    return;
                }
            } else if(topBorderIntersectsEntity(e)) {
                res.fail();
                return;
            }
        }
        for(b in all) {
            if(b == this || !collides(b) || res.pushedBorders.exists(b.id)) continue;
            b.canStepDown(res);
            if(!res.success) {
                res.fail();
                return;
            }
        }
    }

    inline public function containsEntity(e:Entity) {
        return e.x + e.hitbox.xMin >= bounds.xMin && e.x + e.hitbox.xMax <= bounds.xMax && e.y + e.hitbox.yMin >= bounds.yMin && e.y + e.hitbox.yMax <= bounds.yMax;
    }
    inline public function rectIntersectsEntity(e:Entity) {
        return e.x + e.hitbox.xMin < bounds.xMax && e.x + e.hitbox.xMax > bounds.xMin && e.y + e.hitbox.yMin < bounds.yMax && e.y + e.hitbox.yMax > bounds.yMin;
    }
    inline public function collides(other:Border) {
        return !(bounds.xMin >= other.bounds.xMax
            || bounds.xMax <= other.bounds.xMin
            || bounds.yMin >= other.bounds.yMax
            || bounds.yMax <= other.bounds.yMin);
    }
    inline public function horizontalWallIntersectsEntity(e:Entity, inside:Bool) {
        return topWallIntersectsEntity(e, inside) || bottomWallIntersectsEntity(e, inside);
    }
    inline public function verticalWallIntersectsEntity(e:Entity, inside:Bool) {
        return leftWallIntersectsEntity(e, inside) || rightWallIntersectsEntity(e, inside);
    }
    inline public function leftWallIntersectsEntity(e:Entity, inside:Bool) {
        return e.x + e.hitbox.xMin < bounds.xMin && e.x + e.hitbox.xMax > bounds.xMin && wallIntersectsSegment(wallLeft, e.y + e.hitbox.yMin - bounds.y, e.y + e.hitbox.yMax - bounds.y, inside);
    }
    inline public function rightWallIntersectsEntity(e:Entity, inside:Bool) {
        return e.x + e.hitbox.xMin < bounds.xMax && e.x + e.hitbox.xMax > bounds.xMax && wallIntersectsSegment(wallRight, e.y + e.hitbox.yMin - bounds.y, e.y + e.hitbox.yMax - bounds.y, inside);
    }
    inline public function topWallIntersectsEntity(e:Entity, inside:Bool) {
        return e.y + e.hitbox.yMin < bounds.yMin && e.y + e.hitbox.yMax > bounds.yMin && wallIntersectsSegment(wallUp, e.x + e.hitbox.xMin - bounds.x, e.x + e.hitbox.xMax - bounds.x, inside);
    }
    inline public function bottomWallIntersectsEntity(e:Entity, inside:Bool) {
        return e.y + e.hitbox.yMin < bounds.yMax && e.y + e.hitbox.yMax > bounds.yMax && wallIntersectsSegment(wallDown, e.x + e.hitbox.xMin - bounds.x, e.x + e.hitbox.xMax - bounds.x, inside);
    }
    inline public function leftBorderIntersectsEntity(e:Entity) {
        return e.x + e.hitbox.xMin < bounds.xMin && e.x + e.hitbox.xMax > bounds.xMin && e.y + e.hitbox.yMin < bounds.yMax && e.y + e.hitbox.yMax > bounds.yMin;
    }
    inline public function rightBorderIntersectsEntity(e:Entity) {
        return e.x + e.hitbox.xMin < bounds.xMax && e.x + e.hitbox.xMax > bounds.xMax && e.y + e.hitbox.yMin < bounds.yMax && e.y + e.hitbox.yMax > bounds.yMin;
    }
    inline public function topBorderIntersectsEntity(e:Entity) {
        return e.y + e.hitbox.yMin < bounds.yMin && e.y + e.hitbox.yMax > bounds.yMin && e.x + e.hitbox.xMin < bounds.xMax && e.x + e.hitbox.xMax > bounds.xMin;
    }
    inline public function bottomBorderIntersectsEntity(e:Entity) {
        return e.y + e.hitbox.yMin < bounds.yMax && e.y + e.hitbox.yMax > bounds.yMax && e.x + e.hitbox.xMin < bounds.xMax && e.x + e.hitbox.xMax > bounds.xMin;
    }
    public function wallIntersectsSegment(w:Wall, l:Int, r:Int, inside:Bool) {
        if(inside) {
            // Corner correction
            l += 2; r -= 2;
        }
        for(seg in w) {
            if(seg.pos + seg.length > l && seg.pos < r) return true;
        }
        return false;
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

    public function debug() {
        trace("Border " + id + " at (" + bounds.xMin + ", " + bounds.yMin + ") to (" + bounds.xMax + ", " + bounds.yMax + ")");
    }
}