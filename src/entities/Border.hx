package entities;

import haxe.ds.IntMap;
import h2d.Graphics;
import h2d.col.IBounds;

class Border {
    public var bounds : IBounds;
    var g : Graphics;

    public function new() {
        bounds = IBounds.fromValues(0, 0, 64, 64);
        g = new Graphics();
        Game.inst.world.add(g, Game.LAYER_BORDER);
        render();
    }

    public function initPosition() {
        bounds.x = Game.inst.hero.x - (bounds.width >> 1);
        bounds.y = Game.inst.hero.y - (bounds.height >> 1);
    }

    public function delete() {
        g.remove();
    }

    public function update(dt:Float) {
        render();
    }

    function render() {
        g.clear();
        g.lineStyle(1, 0xFFFFFF);
        g.drawRect(bounds.x, bounds.y, bounds.width, bounds.height);
        g.endFill();
    }

    public function stepLeft() {
        bounds.x -= 1;
        for(e in Entity.all) {
            if(e.canPushBorder) continue;
            if(bounds.xMax < e.x + e.hitbox.xMax) {
                var chain = new IntMap<Bool>();
                if(!e.pushLeft(chain)) {
                    bounds.x += 1;
                    return false;
                }
            }
        }
        return true;
    }
    public function stepRight() {
        bounds.x += 1;
        for(e in Entity.all) {
            if(e.canPushBorder) continue;
            if(bounds.xMin > e.x + e.hitbox.xMin) {
                var chain = new IntMap<Bool>();
                if(!e.pushRight(chain)) {
                    bounds.x -= 1;
                    return false;
                }
            }
        }
        return true;
    }
    public function stepUp() {
        bounds.y -= 1;
        for(e in Entity.all) {
            if(e.canPushBorder) continue;
            if(bounds.yMax < e.y + e.hitbox.yMax) {
                var chain = new IntMap<Bool>();
                if(!e.pushUp(chain)) {
                    bounds.y += 1;
                    return false;
                }
            }
        }
        return true;
    }
    public function stepDown() {
        bounds.y += 1;
        for(e in Entity.all) {
            if(e.canPushBorder) continue;
            if(bounds.yMin > e.y + e.hitbox.yMin) {
                var chain = new IntMap<Bool>();
                if(!e.pushDown(chain)) {
                    bounds.y -= 1;
                    return false;
                }
            }
        }
        return true;
    }
}