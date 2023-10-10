package entities;

import haxe.ds.Vector;
import ldtk.Json.IdentifierStyle;
import haxe.ds.IntMap;
import h2d.Tile;
import h2d.col.IBounds;
import h2d.Bitmap;

class Entity {
    public static var all : Array<Entity> = [];

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
                trace("No more movement possible after " + iterations + " iterations");
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
    var rx : Float = 0.;
    var ry : Float = 0.;
    var deleted : Bool = false;
    public var collisionEnabled : Bool = false;
    public var canPushBorder : Bool = false;
    public var canPushEntities : Bool = false;
    var hitLeft : Bool = false;
    var hitRight : Bool = false;
    var hitUp : Bool = false;
    var hitDown : Bool = false;
    var borderId : Int = -1;
    public var isInside(default, null) : Bool = false;
    var stepping : Bool = false;
    var triedPushingHorizontal : Bool = false;

    public function new(?hitbox:IBounds=null) {
        id = all.length;
        all.push(this);
        if(hitbox != null) {
            setHitbox(hitbox);
        }
    }

    public function delete() {
        if(deleted) return;
        deleted = true;
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
        if(!collisionEnabled || stepLeft()) {
            rx++;
            return true;
        }
        vx = 0;
        hitLeft = true;
        rx -= amountX;
        return false;
    }

    public function tryMoveRight() {
        var amountX = Math.round(rx);
        if(amountX <= 0) return false;
        if(!collisionEnabled || stepRight()) {
            rx--;
            return true;
        }
        vx = 0;
        hitRight = true;
        rx -= amountX;
        return false;
    }

    public function tryMoveUp() {
        var amountY = Math.round(ry);
        if(amountY >= 0) return false;
        if(!collisionEnabled || stepUp()) {
            ry++;
            return true;
        }
        vy = 0;
        hitUp = true;
        ry -= amountY;
        return false;
    }

    public function tryMoveDown() {
        var amountY = Math.round(ry);
        if(amountY <= 0) return false;
        if(!collisionEnabled || stepDown()) {
            ry--;
            return true;
        }
        vy = 0;
        hitDown = true;
        ry -= amountY;
        return false;
    }

    public function stepLeft(forceCanPushBorder:Bool=false) {
        if(stepping) return false;
        stepping = true;
        x--;
        if(Solid.entityCollides(this, -1, 0)) {
            cancelStepLeft();
            return false;
        }
        for(e in all) {
            if(!e.collisionEnabled || e == this || !collides(e)) continue;
            if(canPushEntities) {
                triedPushingHorizontal = true;
                var chain = new IntMap<Bool>();
                chain.set(id, true);
                if(!e.pushLeft(chain)) {
                    cancelStepLeft();
                    return false;
                }
            } else {
                cancelStepLeft();
                return false;
            }
        }
        for(b in Border.all) {
            if(borderId != -1 && borderId != b.id) continue;
            if(b.verticalWallIntersectsEntity(this, isInside)) {
                if(forceCanPushBorder || canPushBorder) {
                    triedPushingHorizontal = true;
                    if(!b.pushLeft(new IntMap<Bool>())) {
                        cancelStepLeft();
                        return false;
                    }
                } else {
                    cancelStepLeft();
                    return false;
                }
            }
        }
        stepping = false;
        return true;
    }
    public function stepRight(forceCanPushBorder:Bool=false) {
        if(stepping) return false;
        stepping = true;
        x++;
        if(Solid.entityCollides(this, 1, 0)) {
            cancelStepRight();
            return false;
        }
        for(e in all) {
            if(!e.collisionEnabled || e == this || !collides(e)) continue;
            if(canPushEntities) {
                triedPushingHorizontal = true;
                var chain = new IntMap<Bool>();
                chain.set(id, true);
                if(!e.pushRight(chain)) {
                    cancelStepRight();
                    return false;
                }
            } else {
                cancelStepRight();
                return false;
            }
        }
        for(b in Border.all) {
            if(borderId != -1 && borderId != b.id) continue;
            if(b.verticalWallIntersectsEntity(this, isInside)) {
                if(forceCanPushBorder || canPushBorder) {
                    triedPushingHorizontal = true;
                    if(!b.pushRight(new IntMap<Bool>())) {
                        cancelStepRight();
                        return false;
                    }
                } else {
                    cancelStepRight();
                    return false;
                }
            }
        }
        stepping = false;
        return true;
    }
    public function stepUp(forceCanPushBorder:Bool=false) {
        if(stepping) return false;
        stepping = true;
        y--;
        if(Solid.entityCollides(this, 0, -1)) {
            cancelStepUp();
            return false;
        }
        for(e in all) {
            if(!e.collisionEnabled || e == this || !collides(e)) continue;
            if(canPushEntities) {
                var chain = new IntMap<Bool>();
                chain.set(id, true);
                if(!e.pushUp(chain)) {
                    cancelStepUp();
                    return false;
                }
            } else {
                cancelStepUp();
                return false;
            }
        }
        for(b in Border.all) {
            if(borderId != -1 && borderId != b.id) continue;
            if(b.horizontalWallIntersectsEntity(this, isInside)) {
                if(forceCanPushBorder || canPushBorder) {
                    if(!b.pushUp(new IntMap<Bool>())) {
                        cancelStepUp();
                        return false;
                    }
                } else {
                    cancelStepUp();
                    return false;
                }
            }
        }
        stepping = false;
        return true;
    }
    public function stepDown(forceCanPushBorder:Bool=false) {
        if(stepping) return false;
        stepping = true;
        y++;
        if(Solid.entityCollides(this, 0, 1)) {
            cancelStepDown();
            return false;
        }
        for(e in all) {
            if(!e.collisionEnabled || e == this || !collides(e)) continue;
            if(canPushEntities) {
                var chain = new IntMap<Bool>();
                chain.set(id, true);
                if(!e.pushDown(chain)) {
                    cancelStepDown();
                    return false;
                }
            } else {
                cancelStepDown();
                return false;
            }
        }
        for(b in Border.all) {
            if(borderId != -1 && borderId != b.id) continue;
            if(b.horizontalWallIntersectsEntity(this, isInside)) {
                if(forceCanPushBorder || canPushBorder) {
                    if(!b.pushDown(new IntMap<Bool>())) {
                        cancelStepDown();
                        return false;
                    }
                } else {
                    cancelStepDown();
                    return false;
                }
            }
        }
        stepping = false;
        return true;
    }
    inline function cancelStepLeft() {
        x++;
        stepping = false;
    }
    inline function cancelStepRight() {
        x--;
        stepping = false;
    }
    inline function cancelStepUp() {
        y++;
        stepping = false;
    }
    inline function cancelStepDown() {
        y--;
        stepping = false;
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
        if(!stepLeft(true)) {
            return false;
        }
        if(!canPushEntities) {
            stepDown();
        }
        return true;
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
        if(!stepRight(true)) {
            return false;
        }
        if(!canPushEntities) {
            stepDown();
        }
        return true;
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