package fx;

import entities.Solid;
import h2d.Tile;

class Particle extends CustomSpriteBatch.BatchElement {
    public static inline var BOUNCINESS = .5;
    public static var LIMIT = 1000;
    public static var all : Array<Particle> = [];

    public static inline function canCreate() {
        return all.length < LIMIT;
    }

    public static function create(tile, time, ?col=0xFFFFFF) {
        if(all.length == LIMIT) {
            #if show_counts
			Main.println("Particle limit reached");
			#end
			return null;
		}
		return new Particle(tile, time, col);
    }
    public static function clearAll() {
        all = [];
    }

    public var xx : Float = 0.;
    public var yy : Float = 0.;
    public var xMin : Float = -1e9;
    public var xMax : Float = 1e9;
    public var yMin : Float = -1e9;
    public var yMax : Float = 1e9;
    public var vx : Float = 0.;
    public var vy : Float = 0.;
    public var accx : Float = 0.;
    public var accy : Float = 0.;
    public var time : Float;
    public var timer : Float;
    public var frx : Float = 1.;
    public var fry : Float = 1.;
    public var rotationVel : Float = 0.;
    public var fade : Bool;
    public var baseScaleX : Float = 1.;
    public var baseScaleY : Float = 1.;
    public var targetScaleX : Float = 1.;
    public var targetScaleY : Float = 1.;
    public var updateRotation : Bool;
    public var dieOnCollision : Bool;
    public var bounce : Bool;
    public var trailAnimName : String = null;
    public var trailSpacing : Float = 0.;
    var curTrailDist : Float = 0.;
    var col : Int;

    function new(tile, time, ?col=0xFFFFFF) {
        super(tile);
        all.push(this);
        this.col = col;
        x = y = 0.;
        updateRotation = dieOnCollision = fade = bounce = false;
        this.time = timer = time;
    }

    override public function remove() {
        all.remove(this);
        super.remove();
    }

    inline function updateScale(sx:Float, sy:Float) {
        scaleX = sx;
        scaleY = sy;
    }

    inline function updateAlpha(v:Float) {
        alpha = v;
    }

    override public function update(dt:Float) {
        if(time >= 0) {
            timer -= dt;
            var t = 1. - timer / time;
            if(timer < 0) {
                return false;
            } else {
                updateScale(Util.lerp(baseScaleX, targetScaleX, t), Util.lerp(baseScaleY, targetScaleY, t));
            }
            if(fade) {
                updateAlpha(1. - t);
            }
        }
        var prevX = xx, prevY = yy;
        vx += accx * dt;
        vy += accy * dt;
        if(frx != 1.) {
            vx *= Math.pow(frx, dt);
        }
        if(fry != 1.) {
            vy *= Math.pow(fry, dt);
        }
        var dx = vx * dt;
        var dy = vy * dt;
        if(Game.inst != null) {
            var level = Game.inst.level;
            if(bounce) {
                if(Solid.pointCollides(Std.int(xx), Std.int(yy + dy), Util.sign(dx), Util.sign(dy))) {
                    vy *= -BOUNCINESS;
                    dy *= -BOUNCINESS;
                    vx *= BOUNCINESS;
                    rotationVel *= -BOUNCINESS;
                }
                yy += dy;
                if(Solid.pointCollides(Std.int(xx + dx), Std.int(yy), Util.sign(dx), Util.sign(dy))) {
                    vx *= -BOUNCINESS;
                    dx *= -BOUNCINESS;
                    vy *= BOUNCINESS;
                    rotationVel *= -BOUNCINESS;
                }
                xx += dx;
            } else {
                xx += dx;
                yy += dy;
            }
            var collides = Solid.pointCollides(Std.int(xx), Std.int(yy), Util.sign(dx), Util.sign(dy));
            if(dieOnCollision && collides) {
                return false;
            }
        } else {
            xx += dx;
            yy += dy;
        }
        if(xx <= xMin || xx >= xMax || yy <= yMin || yy >= yMax) {
            return false;
        }
        if(updateRotation) {
            rotation = Math.atan2(vy, vx);
        } else {
            rotation += rotationVel * dt;
        }
        if(trailSpacing > 0) {
            var mx = xx - prevX;
            var my = yy - prevY;
            var dist = Math.sqrt(mx * mx + my * my);
            curTrailDist += dist;
            while(curTrailDist >= trailSpacing) {
                var px = prevX + mx * (curTrailDist - trailSpacing) / dist;
                var py = prevY + my * (curTrailDist - trailSpacing) / dist;
                curTrailDist -= trailSpacing;
                // TODO: Set offset from tile anchor
                // var dist = tinyTrail ? 0 : 3;
                // Game.inst.fx.trailParticle(px + dist * Math.cos(rotation), py + dist * Math.sin(rotation), trailAnimName, col);
            }
        }
        x = xx;
        y = yy;
        return true;
    }

    inline public function setBoundsToLevel(level:Level) {
        var maxSize = Util.fmax(t.width, t.height);
        var bounds = level.getCameraBounds();
        xMin = bounds.xMin - 2 * maxSize;
        yMin = bounds.yMin - 2 * maxSize;
        xMax = bounds.xMax + 2 * maxSize;
        yMax = bounds.yMax + 2 * maxSize;
    }
}