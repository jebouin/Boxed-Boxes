package entities;

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

    public var hitbox : IBounds;
    public var x : Int = 0;
    public var y : Int = 0;
    var rx : Float;
    var ry : Float;
    var deleted : Bool = false;
    public var collisionEnabled : Bool = false;
    public var canPushBorder : Bool = false;

    public function new() {
        all.push(this);
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

    public function stepLeft() {
        x--;
        if(Solid.entityCollides(this)) {
            x++;
            return false;
        }
        return true;
    }
    public function stepRight() {
        x++;
        if(Solid.entityCollides(this)) {
            x--;
            return false;
        }
        return true;
    }
    public function stepUp() {
        y--;
        if(Solid.entityCollides(this)) {
            y++;
            return false;
        }
        return true;
    }
    public function stepDown() {
        y++;
        if(Solid.entityCollides(this)) {
            y--;
            return false;
        }
        return true;
    }
}