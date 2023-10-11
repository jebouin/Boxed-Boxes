package entities;

import h2d.Graphics;
import h2d.col.IBounds;
import assets.LevelProject;

class Solid {
    public static var all : Array<Solid> = [];

    public static function deleteAll() {
        for(s in all) {
            s.delete();
        }
        all = [];
    }

    public static function pointCollides(x:Int, y:Int, dx:Int, dy:Int) {
        for(s in all) {
            if(s.collisionType == Full) {
                if(x > s.bounds.xMin && x < s.bounds.xMax && y > s.bounds.yMin && y < s.bounds.yMax) {
                    return true;
                }
            } else if(s.collisionType == PlatformLeft && dx < 0) {
                if(s.bounds.yMin < y && s.bounds.yMax > y && x == s.bounds.xMax - 1) {
                    return true;
                }
            } else if(s.collisionType == PlatformRight && dx > 0) {
                if(s.bounds.yMin < y && s.bounds.yMax > y && x == s.bounds.xMin + 1) {
                    return true;
                }
            } else if(s.collisionType == PlatformUp && dy < 0) {
                if(s.bounds.xMin < x && s.bounds.xMax > x && y == s.bounds.yMax - 1) {
                    return true;
                }
            } else if(s.collisionType == PlatformDown && dy > 0) {
                if(s.bounds.xMin < x && s.bounds.xMax > x && y == s.bounds.yMin + 1) {
                    return true;
                }
            }
        }
        return false;
    }

    public static function entityCollides(entity:Entity, dx:Int, dy:Int) {
        return entityCollidesAt(entity, entity.x, entity.y, dx, dy);
    }

    public static function entityCollidesAt(entity:Entity, x:Int, y:Int, dx:Int, dy:Int) {
        for(s in all) {
            if(s.collisionType == Full) {
                if(x + entity.hitbox.xMax > s.bounds.xMin && x + entity.hitbox.xMin < s.bounds.xMax && 
                   y + entity.hitbox.yMax > s.bounds.yMin && y + entity.hitbox.yMin < s.bounds.yMax) {
                    return true;
                }
            } else if(s.collisionType == PlatformLeft && dx < 0) {
                if(s.bounds.yMin < y + entity.hitbox.yMax && s.bounds.yMax > y + entity.hitbox.yMin && x + entity.hitbox.xMin == s.bounds.xMax - 1) {
                    return true;
                }
            } else if(s.collisionType == PlatformRight && dx > 0) {
                if(s.bounds.yMin < y + entity.hitbox.yMax && s.bounds.yMax > y + entity.hitbox.yMin && x + entity.hitbox.xMax == s.bounds.xMin + 1) {
                    return true;
                }
            } else if(s.collisionType == PlatformUp && dy < 0) {
                if(s.bounds.xMin < x + entity.hitbox.xMax && s.bounds.xMax > x + entity.hitbox.xMin && y + entity.hitbox.yMin == s.bounds.yMax - 1) {
                    return true;
                }
            } else if(s.collisionType == PlatformDown && dy > 0) {
                if(s.bounds.xMin < x + entity.hitbox.xMax && s.bounds.xMax > x + entity.hitbox.xMin && y + entity.hitbox.yMax == s.bounds.yMin + 1) {
                    return true;
                }
            }
        }
        return false;
    }

    public var bounds(default, null) : IBounds;
    var collisionType : Enum_Collision;
    #if debug
    var g : Graphics;
    #end

    public function new(x:Int, y:Int, width:Int, height:Int, collisionType:Enum_Collision) {
        bounds = IBounds.fromValues(x, y, width, height);
        this.collisionType = collisionType;
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