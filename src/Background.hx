package ;

import hxd.Res;
import h2d.Tile;

class Background {
    var timer : Float = 0;
    var parallaxes : Array<Parallax> = [];

    public function new() {
        loadLevel(0);
    }

    public function addParallax(zone:Int, frame:Int, speed:Float) {
        var r = Res.load("gfx/backgrounds/back" + zone + ".png");
        var sub = r.toTile().sub(0, frame * Main.HEIGHT, Main.WIDTH, Main.HEIGHT);
        var p = new Parallax(sub, Game.LAYER_BACK, speed);
        parallaxes.push(p);
        // TODO: Sort
    }

    public function loadLevel(globalLevelId:Int) {
        for(p in parallaxes) {
            p.remove();
        }
        var zone = Std.int(globalLevelId / (Title.GROUP_WIDTH * Title.GROUP_HEIGHT));
        var tile = Res.load("gfx/backgrounds/back" + zone + ".png").toTile();
        var count = Std.int(tile.iheight / Main.HEIGHT);
        for(i in 0...count) {
            var f = Math.exp(-(3 * (count - i - 1) / count)) * .8;
            addParallax(zone, i, f);
        }
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