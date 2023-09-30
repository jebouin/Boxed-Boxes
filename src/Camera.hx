package ;

import entities.Hero;
import h2d.col.IBounds;
import h2d.col.Point;

class Camera {
    var target : Hero;
    public var targetX : Float = 0.;
    public var targetY : Float = 0.;
    public var clampedTargetX : Float;
    public var clampedTargetY : Float;
    public var targetOffX : Float = 0.;
    public var targetOffY : Float = 0.;
    public var viewportWidth : Float;
    public var viewportHeight : Float;
    public var bounds(default, null) : IBounds;
    var sodX : SecondOrderDynamics;
    var sodY : SecondOrderDynamics;

    public function new(?bounds:IBounds) {
        this.bounds = bounds;
        sodX = new SecondOrderDynamics(2., 1.5, 0., 0., Precise);
        sodY = new SecondOrderDynamics(2., 1.5, 0., 0., Precise);
        updateViewport();
    }

    public function setTarget(target:Hero, immediate:Bool) {
        this.target = target;
        if(immediate) {
            sodX.reset(0.);
            sodY.reset(0.);
            targetX = target.x + targetOffX;
            targetY = target.y + targetOffY;
        }
    }

    public function getTargetWithoutOffset() {
        if(target == null) return null;
        return new Point(target.x, target.y);
    }

    public function update(dt:Float) {
        if(target != null) {
            var tx = target.x + targetOffX;
            var ty = target.y + targetOffY;
            sodX.update(dt, target.eyeOffsetX);
            sodY.update(dt, target.eyeOffsetY);
            targetX = tx + sodX.pos;
            targetY = ty + sodY.pos;
            var newClampedTarget = getClampedPosition(bounds);
            clampedTargetX = newClampedTarget.x;
            clampedTargetY = newClampedTarget.y;
        }
        var world = Game.inst.world;
        var wx = clampedTargetX - viewportWidth * .5;
        var wy = clampedTargetY - viewportHeight * .5;
        world.x = -wx;
        world.y = -wy;
    }

    public function updateViewport() {
        viewportWidth = Main.WIDTH;
        viewportHeight = Main.HEIGHT;
    }

    public function setBounds(bounds:IBounds) {
        this.bounds = bounds;
    }

    public function getClampedPosition(bounds:IBounds) {
        var clampedTarget = new Point(targetX, targetY);
		if(bounds != null) {
			if(viewportWidth > bounds.width) {
				clampedTarget.x = bounds.getCenter().x;
			} else {
				var hw = viewportWidth * .5;
				if(targetX - hw < bounds.xMin) {
					clampedTarget.x = bounds.xMin + hw;
				} else if(targetX + hw > bounds.xMax) {
					clampedTarget.x = bounds.xMax - hw;
				} else {
					clampedTarget.x = targetX;
				}
			}
			if(viewportHeight > bounds.height) {
				clampedTarget.y = bounds.getCenter().y;
			} else {
				var hh = viewportHeight * .5;
				if(targetY - hh < bounds.yMin) {
					clampedTarget.y = bounds.yMin + hh;
				} else if(targetY + hh > bounds.yMax) {
					clampedTarget.y = bounds.yMax - hh;
				} else {
					clampedTarget.y = targetY;
				}
			}
        }
        return clampedTarget;
    }
}