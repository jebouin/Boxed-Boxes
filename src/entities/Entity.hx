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
    }

    public var hitboxes : Array<IBounds> = [];
    public var x : Int = 0;
    public var y : Int = 0;
    var rx : Float;
    var ry : Float;
    var deleted : Bool = false;
    public var collisionEnabled : Bool;

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
}