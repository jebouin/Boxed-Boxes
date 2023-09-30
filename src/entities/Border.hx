package entities;

import h2d.Graphics;
import h2d.col.IBounds;

class Border {
    var bounds : IBounds;
    var g : Graphics;

    public function new() {
        bounds = IBounds.fromValues(0, 0, 64, 64);
        g = new Graphics();
        Game.inst.world.add(g, Game.LAYER_BORDER);
        render();
    }

    public function delete() {
        g.remove();
    }

    public function update(dt:Float) {
        for(e in Entity.all) {
            if(!e.canPushBorder) continue;
            if(e.x + e.hitbox.xMin < bounds.x) {
                bounds.x = e.x + e.hitbox.xMin;
            }
            if(e.x + e.hitbox.xMax > bounds.x + bounds.width) {
                bounds.x = e.x + e.hitbox.xMax - bounds.width;
            }
            if(e.y + e.hitbox.yMin < bounds.y) {
                bounds.y = e.y + e.hitbox.yMin;
            }
            if(e.y + e.hitbox.yMax > bounds.y + bounds.height) {
                bounds.y = e.y + e.hitbox.yMax - bounds.height;
            }
        }
        render();
    }

    function render() {
        g.clear();
        g.lineStyle(1, 0xFFFFFF);
        g.drawRect(bounds.x, bounds.y, bounds.width, bounds.height);
        g.endFill();
    }
}