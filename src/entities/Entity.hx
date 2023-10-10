package entities;

import haxe.ds.Vector;
import ldtk.Json.IdentifierStyle;
import haxe.ds.IntMap;
import h2d.Tile;
import h2d.col.IBounds;
import h2d.Bitmap;

class Entity {
    public static var all : Array<Entity> = [];
    public static var idToEntity : IntMap<Entity> = new IntMap<Entity>();

    static function sortTopDown() {
        all.sort(function(a, b) {
            return a.y - b.y;
        });
    }
    static function sortBottomUp() {
        all.sort(function(a, b) {
            return (b.y + b.hitbox.yMax) - (a.y + a.hitbox.yMax);
        });
    }
    static function sortLeftRight() { 
        all.sort(function(a, b) {
            return a.x - b.x;
        });
    }
    static function sortRightLeft() {
        all.sort(function(a, b) {
            return (b.x + b.hitbox.xMax) - (a.x + a.hitbox.xMax);
        });
    }

    public static function updateAll(dt:Float) {
        function iterateAndCheckAll(f:Entity->Void) {
            var i = 0;
            while(i < all.length) {
                var entity = all[i];
                f(entity);
                if(entity.deleted) {
                    all.splice(i, 1);
                } else {
                    i++;
                }
            }
        }
        iterateAndCheckAll(function(e) {
            e.updateBeforeMove(dt);
        });
        trace("MOVING " + all.length + " ENTITIES");
        var iterations = 0;
        while(iterations < Game.MAX_MOVE_STEPS) {
            var moved = false;
            sortLeftRight();
            iterateAndCheckAll(function(e) {
                if(e.tryMoveLeft()) {
                    moved = true;
                }
            });
            sortRightLeft();
            iterateAndCheckAll(function(e) {
                if(e.tryMoveRight()) {
                    moved = true;
                }
            });
            sortTopDown();
            iterateAndCheckAll(function(e) {
                if(e.tryMoveUp()) {
                    moved = true;
                }
            });
            sortBottomUp();
            iterateAndCheckAll(function(e) {
                if(e.tryMoveDown()) {
                    moved = true;
                }
            });
            iterations++;
            if(!moved) {
                #if debug_collisions
                trace("NO MORE MOVEMENT POSSIBLE AFTER " + iterations + " ITERATIONS");
                #end
                break;
            }
        }
        iterateAndCheckAll(function(e) {
            e.updateAfterMove(dt);
        });
    }

    public static function deleteAll() {
        for(entity in all) {
            entity.delete();
        }
        all = [];
    }

    public var id(default, null) : Int;
    public var hitbox : IBounds;
    public var x : Int = 0;
    public var y : Int = 0;
    public var vx : Float = 0.;
    public var vy : Float = 0.;
    public var rx : Float = 0.;
    public var ry : Float = 0.;
    var deleted : Bool = false;
    public var collisionEnabled : Bool = false;
    public var canPushBorders : Bool = false;
    public var canPushEntities : Bool = false;
    var hitLeft : Bool = false;
    var hitRight : Bool = false;
    var hitUp : Bool = false;
    var hitDown : Bool = false;
    var borderId : Int = -1;
    public var isInside(default, null) : Bool = false;
    public var triedPushingHorizontal : Bool = false;

    public function new(?hitbox:IBounds=null) {
        id = all.length;
        all.push(this);
        idToEntity.set(id, this);
        if(hitbox != null) {
            setHitbox(hitbox);
        }
    }

    public function delete() {
        if(deleted) return;
        deleted = true;
        idToEntity.remove(id);
    }

    public function die(dx:Float, dy:Float) {
        delete();
    }

    public function updateBeforeMove(dt:Float) {
        borderId = getBorderId();
        hitLeft = hitRight = hitUp = hitDown = false;
        triedPushingHorizontal = false;
        rx += vx * dt;
        ry += vy * dt;
    }

    public function updateAfterMove(dt:Float) {
        updateBorderConstraint();
    }

    public function tryMoveLeft() {
        var amountX = Math.round(rx);
        if(amountX >= 0) return false;
        if(collisionEnabled) {
            var res = StepResult.newLeft();
            canStepLeft(res);
            res.apply(this);
            if(!res.success) {
                vx = 0;
                hitLeft = true;
                rx -= amountX;
                return false;
            }
        } else {
            rx++;
            x--;
        }
        return true;
    }

    public function tryMoveRight() {
        var amountX = Math.round(rx);
        if(amountX <= 0) return false;
        if(collisionEnabled) {
            var res = StepResult.newRight();
            canStepRight(res);
            res.apply(this);
            if(!res.success) {
                vx = 0;
                hitRight = true;
                rx -= amountX;
                return false;
            }
        } else {
            rx--;
            x++;
        }
        return true;
    }

    public function tryMoveUp() {
        var amountY = Math.round(ry);
        if(amountY >= 0) return false;
        if(collisionEnabled) {
            var res = StepResult.newUp();
            canStepUp(res);
            res.apply(this);
            if(!res.success) {
                vy = 0;
                hitUp = true;
                ry -= amountY;
                return false;
            }
        } else {
            ry++;
            y--;
        }
        return true;
    }

    public function tryMoveDown() {
        var amountY = Math.round(ry);
        if(amountY <= 0) return false;
        if(collisionEnabled) {
            var res = StepResult.newDown();
            canStepDown(res);
            res.apply(this);
            if(!res.success) {
                vy = 0;
                hitDown = true;
                ry -= amountY;
                return false;
            }
        } else {
            ry--;
            y++;
        }
        return true;
    }

    // Assume graph of entities pushing -> pushed is acyclic since direction is constant
    public function canStepLeft(res:StepResult, canPushEntities:Bool=false, canPushBorders:Bool=false) {
        canPushEntities = canPushEntities || this.canPushEntities;
        canPushBorders = canPushBorders || this.canPushBorders;
        res.pushedEntities.set(id, true);
        x--;
        if(Solid.entityCollides(this, -1, 0)) {
            res.cancel();
            return;
        }
        for(e in all) {
            if(!e.collisionEnabled || e == this || !collides(e) || res.pushedEntities.exists(e.id)) continue;
            if(canPushEntities) {
                res.triedPushingHorizontal = true;
                e.canStepLeft(res, canPushEntities, canPushBorders);
                if(!res.success) {
                    return;
                }
            } else {
                res.cancel();
                return;
            }
        }
        for(b in Border.all) {
            if(borderId != -1 && borderId != b.id) continue;
            if(res.pushedBorders.exists(b.id) || !b.verticalWallIntersectsEntity(this, isInside)) continue;
            if(canPushBorders) {
                b.canStepLeft(res);
                if(!res.success) {
                    return;
                }
            } else {
                res.cancel();
                return;
            }
        }
        x++;
    }
    public function canStepRight(res:StepResult, canPushEntities:Bool=false, canPushBorders:Bool=false) {
        canPushEntities = canPushEntities || this.canPushEntities;
        canPushBorders = canPushBorders || this.canPushBorders;
        res.pushedEntities.set(id, true);
        x++;
        if(Solid.entityCollides(this, 1, 0)) {
            res.cancel();
            return;
        }
        for(e in all) {
            if(!e.collisionEnabled || e == this || !collides(e) || res.pushedEntities.exists(e.id)) continue;
            if(canPushEntities) {
                res.triedPushingHorizontal = true;
                e.canStepRight(res, canPushEntities, canPushBorders);
                if(!res.success) {
                    return;
                }
            } else {
                res.cancel();
                return;
            }
        }
        for(b in Border.all) {
            if(borderId != -1 && borderId != b.id) continue;
            if(res.pushedBorders.exists(b.id) || !b.verticalWallIntersectsEntity(this, isInside)) continue;
            if(canPushBorders) {
                b.canStepRight(res);
                if(!res.success) {
                    return;
                }
            } else {
                res.cancel();
                return;
            }
        }
        x--;
    }
    public function canStepUp(res:StepResult, canPushEntities:Bool=false, canPushBorders:Bool=false) {
        canPushEntities = canPushEntities || this.canPushEntities;
        canPushBorders = canPushBorders || this.canPushBorders;
        res.pushedEntities.set(id, true);
        y--;
        if(Solid.entityCollides(this, 0, -1)) {
            res.cancel();
            return;
        }
        for(e in all) {
            if(!e.collisionEnabled || e == this || !collides(e) || res.pushedEntities.exists(e.id)) continue;
            if(canPushEntities) {
                e.canStepUp(res, canPushEntities, canPushBorders);
                if(!res.success) {
                    return;
                }
            } else {
                res.cancel();
                return;
            }
        }
        for(b in Border.all) {
            if(borderId != -1 && borderId != b.id) continue;
            if(res.pushedBorders.exists(b.id) || !b.horizontalWallIntersectsEntity(this, isInside)) continue;
            if(canPushBorders) {
                b.canStepUp(res);
                if(!res.success) {
                    return;
                }
            } else {
                res.cancel();
                return;
            }
        }
        y++;
    }
    public function canStepDown(res:StepResult, canPushEntities:Bool=false, canPushBorders:Bool=false) {
        canPushEntities = canPushEntities || this.canPushEntities;
        canPushBorders = canPushBorders || this.canPushBorders;
        res.pushedEntities.set(id, true);
        y++;
        if(Solid.entityCollides(this, 0, 1)) {
            res.cancel();
            return;
        }
        for(e in all) {
            if(!e.collisionEnabled || e == this || !collides(e) || res.pushedEntities.exists(e.id)) continue;
            if(canPushEntities) {
                e.canStepDown(res, canPushEntities, canPushBorders);
                if(!res.success) {
                    return;
                }
            } else {
                res.cancel();
                return;
            }
        }
        for(b in Border.all) {
            if(borderId != -1 && borderId != b.id) continue;
            if(res.pushedBorders.exists(b.id) || !b.horizontalWallIntersectsEntity(this, isInside)) continue;
            if(canPushBorders) {
                b.canStepDown(res);
                if(!res.success) {
                    return;
                }
            } else {
                res.cancel();
                return;
            }
        }
        y--;
    }
    // Assumes both entities have collision enabled
    inline public function collides(other:Entity) {
        return !(x + hitbox.xMin >= other.x + other.hitbox.xMax
            || x + hitbox.xMax <= other.x + other.hitbox.xMin
            || y + hitbox.yMin >= other.y + other.hitbox.yMax
            || y + hitbox.yMax <= other.y + other.hitbox.yMin);
    }

    public function getBorderId() {
        for(b in Border.all) {
            if(b.containsEntity(this)) {
                return b.id;
            }
        }
        return -1;
    }

    public function debug() {
        trace("Entity " + this + " " + id + " at (" + (x + hitbox.xMin) + ", " + (y + hitbox.yMin) + ") to (" + (x + hitbox.xMax) + ", " + (y + hitbox.yMax) + ")");
    }

    // Make sure the entity is fully inside a border, inside multiple adjacent borders or outside borders
    // A bit hacky since it shouldn't be needed
    function updateBorderConstraint() {
        var bounds = IBounds.fromValues(x + hitbox.xMin, y + hitbox.yMin, hitbox.width, hitbox.height);
        var totalArea = bounds.width * bounds.height;
        var coveredArea = 0, largestInterArea = 0;
        var largestInterBorder = null;
        for(b in Border.all) {
            if(!b.bounds.intersects(bounds)) continue;
            var inter = b.bounds.intersection(bounds);
            var area = inter.width * inter.height;
            coveredArea += area;
            if(area > largestInterArea) {
                largestInterArea = area;
                largestInterBorder = b;
            }
        }
        isInside = coveredArea == totalArea;
        if(coveredArea == 0 || coveredArea == totalArea) return;
        if(x + hitbox.xMin < largestInterBorder.bounds.xMin) {
            x = largestInterBorder.bounds.xMin - hitbox.xMin;
        } else if(x + hitbox.xMax > largestInterBorder.bounds.xMax) {
            x = largestInterBorder.bounds.xMax - hitbox.xMax;
        }
        if(y + hitbox.yMin < largestInterBorder.bounds.yMin) {
            y = largestInterBorder.bounds.yMin - hitbox.yMin;
        } else if(y + hitbox.yMax > largestInterBorder.bounds.yMax) {
            y = largestInterBorder.bounds.yMax - hitbox.yMax;
        }
        onBorderConstraintFixed();
    }

    function onBorderConstraintFixed() {

    }

    public function setHitbox(box:IBounds) {
        collisionEnabled = true;
        hitbox = box;
        for(b in Border.all) {
            if(b.containsEntity(this)) {
                isInside = true;
                break;
            }
        }
    }
}