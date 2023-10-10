package ;

import hxd.Res;
import h2d.Tile;

class Background {
    var timer : Float = 0;
    var parallaxes : Array<Parallax> = [];

    public function new() {
    }

    public function addParallax(zone:Int, frame:Int, speed:Float, levelWidth:Int, levelHeight:Int) {
        var r = Res.load("gfx/backgrounds/back" + zone + ".png");
        var tile = r.toTile();
        var sub = tile.sub(frame * Main.WIDTH, 0, Main.WIDTH, tile.iheight);
        var p = new Parallax(sub, 180, Game.LAYER_BACK, speed, levelWidth, levelHeight);
        parallaxes.push(p);
    }

    public function loadLevel(globalLevelId:Int, levelWidth:Int, levelHeight:Int) {
        for(p in parallaxes) {
            p.remove();
        }
        var zone = Std.int((globalLevelId - 1) / (Title.GROUP_WIDTH * Title.GROUP_HEIGHT));
        var tile = Res.load("gfx/backgrounds/back" + zone + ".png").toTile();
        var count = Std.int(tile.iwidth / Main.WIDTH);
        for(i in 0...count) {
            var f = Math.exp(-(3 * (count - i - 1) / count)) * .8;
            addParallax(zone, i, f, levelWidth, levelHeight);
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