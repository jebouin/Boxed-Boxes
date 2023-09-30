package entities;

import h2d.Graphics;
import h2d.col.IBounds;

class Solid {
    public static var all : Array<Solid> = [];

    public static function deleteAll() {
        for(s in all) {
            s.delete();
        }
        all = [];
    }

    public static function entityCollides(entity:Entity) {
        for(s in all) {
            if(s.bounds.xMin >= entity.x + entity.hitbox.xMax || s.bounds.xMax <= entity.x + entity.hitbox.xMin ||
               s.bounds.yMin >= entity.y + entity.hitbox.yMax || s.bounds.yMax <= entity.y + entity.hitbox.yMin) {
                continue;
            }
            return true;
        }
        return false;
    }

    public static function entityCollidesAt(entity:Entity, x:Int, y:Int) {
        for(s in all) {
            if(s.bounds.xMin >= x + entity.hitbox.xMax || s.bounds.xMax <= x + entity.hitbox.xMin ||
               s.bounds.yMin >= y + entity.hitbox.yMax || s.bounds.yMax <= y + entity.hitbox.yMin) {
                continue;
            }
            return true;
        }
        return false;
    }

    public var bounds(default, null) : IBounds;
    #if debug
    var g : Graphics;
    #end

    public function new(x:Int, y:Int, width:Int, height:Int) {
        bounds = IBounds.fromValues(x, y, width, height);
        all.push(this);
        #if debug
        g = new Graphics();
        Game.inst.world.add(g, Game.LAYER_DEBUG);
        g.beginFill(Std.random(0x1000000), .5);
        //g.drawRect(bounds.x, bounds.y, bounds.width, bounds.height);
        g.endFill();
        #end
    }

    public function delete() {
        all.remove(this);
        #if debug
        g.remove();
        #end
    }
}