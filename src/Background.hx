package ;

import hxd.Res;
import h2d.Tile;

class Background {
    var timer : Float = 0;
    var parallaxes : Array<Parallax> = [];

    public function new() {
        addParallax(0, 0, .1);
        addParallax(0, 1, .3);
        addParallax(0, 2, .5);
        addParallax(0, 3, .8);
    }

    public function addParallax(zone:Int, frame:Int, speed:Float) {
        var tile = Res.load("gfx/backgrounds/back" + zone + ".png").toTile();
        var sub = tile.sub(0, frame * Main.HEIGHT, Main.WIDTH, Main.HEIGHT);
        var p = new Parallax(sub, Game.LAYER_BACK, speed);
        parallaxes.push(p);
        // TODO: Sort
    }

    public function delete() {
        for(p in parallaxes) {
            p.remove();
        }
    }

    public function update(dt:Float) {
        timer += dt;
        for(p in parallaxes) {
            p.update();
        }
    }
}