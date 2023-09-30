package entities;

import haxe.ds.IntMap;
import h2d.Tile;
import h2d.col.IBounds;
import h2d.Bitmap;

class Entity {
    public static var all : Array<Entity> = [];

    public static function updateAll(dt:Float) {
        var i = 0;
        while(i < all.length) {
            var entity = all[i];
            entity.update(dt);
            if(entity.deleted) {
                all.splice(i, 1);
            } else {
                i++;
            }
        }
    }

    public static function deleteAll() {
        for(entity in all) {
            entity.delete();
        }
        all = [];
    }

    public var id(default, null) : Int;
    public var hitbox : IBounds;
    var border : Border;
    public var x : Int = 0;
    public var y : Int = 0;
    var rx : Float;
    var ry : Float;
    var deleted : Bool = false;
    public var collisionEnabled : Bool = false;
    public var canPushBorder : Bool = false;
    public var canPushEntities : Bool = false;

    public function new() {
        id = all.length;
        all.push(this);
        border = Game.inst.border;
    }

    public function delete() {
        if(deleted) return;
        deleted = true;
    }

    public function update(dt:Float) {
    }

    public function setPosNoCollision(x:Float, y:Float) {
        var dx = x - this.x;
        var dy = y - this.y;
        moveNoCollision(dx, dy);
    }

    public function moveNoCollision(dx:Float, dy:Float) {
        rx += dx;
        ry += dy;
        var amountX = Math.round(rx);
        var amountY = Math.round(ry);
        rx -= amountX;
        ry -= amountY;
        x += amountX;
        y += amountY;
    }

    public function move(dx:Float, dy:Float) {
        if(!collisionEnabled) {
            moveNoCollision(dx, dy);
            return;
        }
        moveX(dx);
        moveY(dy);
    }
    public function moveX(dx:Float) {
        rx += dx;
        var amount = Math.round(rx);
        if(amount != 0) {
            rx -= amount;
            while(amount < 0) {
                if(!stepLeft()) break;
                amount++;
            }
            while(amount > 0) {
                if(!stepRight()) break;
                amount--;
            }
        }
    }
    public function moveY(dy:Float) {
        ry += dy;
        var amount = Math.round(ry);
        if(amount != 0) {
            ry -= amount;
            while(amount < 0) {
                if(!stepUp()) break;
                amount++;
            }
            while(amount > 0) {
                if(!stepDown()) break;
                amount--;
            }
        }
    }

    public function stepLeft(forceCanPushBorder:Bool=false) {
        x--;
        if(Solid.entityCollides(this)) {
            x++;
            return false;
        }
        if((forceCanPushBorder || canPushBorder) && x + hitbox.xMin < border.bounds.xMin) {
            if(!border.stepLeft()) {
                x++;
                return false;
            }
        }
        if(canPushEntities) {
            for(e in all) {
                if(!e.collisionEnabled || e == this || !collides(e)) continue;
                var chain = new IntMap<Bool>();
                chain.set(id, true);
                if(!e.pushLeft(chain)) {
                    x++;
                    return false;
                }
            }
        }
        return true;
    }
    public function stepRight(forceCanPushBorder:Bool=false) {
        x++;
        if(Solid.entityCollides(this)) {
            x--;
            return false;
        }
        if((forceCanPushBorder || canPushBorder) && x + hitbox.xMax > border.bounds.xMax) {
            if(!border.stepRight()) {
                x--;
                return false;
            }
        }
        if(canPushEntities) {
            for(e in all) {
                if(!e.collisionEnabled || e == this || !collides(e)) continue;
                var chain = new IntMap<Bool>();
                chain.set(id, true);
                if(!e.pushRight(chain)) {
                    x--;
                    return false;
                }
            }
        }
        return true;
    }
    public function stepUp(forceCanPushBorder:Bool=false) {
        y--;
        if(Solid.entityCollides(this)) {
            y++;
            return false;
        }
        if((forceCanPushBorder || canPushBorder) && y + hitbox.yMin < border.bounds.yMin) {
            if(!border.stepUp()) {
                y++;
                return false;
            }
        }
        if(canPushEntities) {
            for(e in all) {
                if(!e.collisionEnabled || e == this || !collides(e)) continue;
                var chain = new IntMap<Bool>();
                chain.set(id, true);
                if(!e.pushUp(chain)) {
                    y++;
                    return false;
                }
            }
        }
        return true;
    }
    public function stepDown(forceCanPushBorder:Bool=false) {
        y++;
        if(Solid.entityCollides(this)) {
            y--;
            return false;
        }
        if((forceCanPushBorder || canPushBorder) && y + hitbox.yMax > border.bounds.yMax) {
            if(!border.stepDown()) {
                y--;
                return false;
            }
        }
        if(canPushEntities) {
            for(e in all) {
                if(!e.collisionEnabled || e == this || !collides(e)) continue;
                var chain = new IntMap<Bool>();
                chain.set(id, true);
                if(!e.pushDown(chain)) {
                    y--;
                    return false;
                }
            }
        }
        return true;
    }
    // For now assume pushing crates can also push the border
    public function pushLeft(chain:IntMap<Bool>) {
        x--;
        for(e in all) {
            if(!collisionEnabled || e == this || !collides(e) || chain.exists(e.id)) continue;
            chain.set(this.id, true);
            if(!e.pushLeft(chain)) {
                x++;
                return false;
            }
            chain.remove(this.id);
        }
        x++;
        return stepLeft(true);
    }
    public function pushRight(chain:IntMap<Bool>) {
        x++;
        for(e in all) {
            if(!collisionEnabled || e == this || !collides(e) || chain.exists(e.id)) continue;
            chain.set(this.id, true);
            if(!e.pushRight(chain)) {
                x--;
                return false;
            }
            chain.remove(this.id);
        }
        x--;
        return stepRight(true);
    }
    public function pushUp(chain:IntMap<Bool>) {
        y--;
        for(e in all) {
            if(!collisionEnabled || e == this || !collides(e) || chain.exists(e.id)) continue;
            chain.set(this.id, true);
            if(!e.pushUp(chain)) {
                y++;
                return false;
            }
            chain.remove(this.id);
        }
        y++;
        return stepUp(true);
    }
    public function pushDown(chain:IntMap<Bool>) {
        y++;
        for(e in all) {
            if(!collisionEnabled || e == this || !collides(e) || chain.exists(e.id)) continue;
            chain.set(this.id, true);
            if(!e.pushDown(chain)) {
                y--;
                return false;
            }
            chain.remove(this.id);
        }
        y--;
        return stepDown(true);
    }
    // Assumes both entities have collision enabled
    inline public function collides(other:Entity) {
        return !(x + hitbox.xMin >= other.x + other.hitbox.xMax
            || x + hitbox.xMax <= other.x + other.hitbox.xMin
            || y + hitbox.yMin >= other.y + other.hitbox.yMax
            || y + hitbox.yMax <= other.y + other.hitbox.yMin);
    }
}