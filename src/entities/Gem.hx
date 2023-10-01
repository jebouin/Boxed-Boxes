package entities;

import h2d.filter.Glow;

class Gem {
    public static var all : Array<Gem> = [];

    public static function updateAll(dt:Float) {
        for (gem in all) {
            gem.update(dt);
        }
    }
    public static function deleteAll() {
        for (gem in all) {
            gem.delete();
        }
        all = [];
    }

    public var anim : Anim;
    var shineTimer : Float = 0.;
    var timer : Float = 0.;
    var x : Int;
    var y : Int;

    public function new(group:Int, px:Int, py:Int) {
        x = px;
        y = py;
        var animData = Assets.getAnimData("entities", "gem" + group);
        anim = new Anim(animData.tiles, animData.fps, true);
        anim.loops = false;
        Game.inst.world.add(anim, Game.LAYER_GEM);
        anim.x = px;
        anim.y = py;
        all.push(this);
        anim.filter = new Glow(0xFFFFFF, 1., 10., .5, 1., true);
    }

    public function delete() {
        anim.remove();
    }

    public function update(dt:Float) {
        var pt = shineTimer;
        shineTimer += dt;
        if((shineTimer > 1.5 && pt < 1.5) || (shineTimer > 1.8 && pt < 1.8)) {
            anim.playCurrent();
        } else if(shineTimer > 1.8) {
            shineTimer = 0.;
        }
        timer += dt;
        anim.x = x;
        anim.y = y + Math.sin(timer * 2.) * 2.;
        anim.update(dt);
    }

    public function collides(e:Entity) {
        var radius = 6;
        return e.x + e.hitbox.xMax > x - radius && e.x + e.hitbox.xMin < x + radius && e.y + e.hitbox.yMax > y - radius && e.y + e.hitbox.yMin < y + radius;
    }
}