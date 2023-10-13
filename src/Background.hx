package ;

import hxd.Res;
import h2d.Tile;

class Background {
    var timer : Float = 0;
    var parallaxes : Array<Parallax> = [];

    public function new() {
    }

    public function addParallax(zone:Int, frame:Int, speed:Float, levelWidth:Int, levelHeight:Int, displace:Bool) {
        var r = Res.load("gfx/backgrounds/back" + zone + ".png");
        var tile = r.toTile();
        var sub = tile.sub(frame * Main.WIDTH, 0, Main.WIDTH, tile.iheight);
        var p = new Parallax(sub, 180, Game.LAYER_BACK, speed, levelWidth, levelHeight, displace);
        parallaxes.push(p);
        return p;
    }

    public function loadLevel(globalLevelId:Int, levelWidth:Int, levelHeight:Int) {
        for(p in parallaxes) {
            p.remove();
        }
        parallaxes = [];
        var zone = Std.int((globalLevelId - 1) / (Title.GROUP_WIDTH * Title.GROUP_HEIGHT));
        var tile = Res.load("gfx/backgrounds/back" + zone + ".png").toTile();
        var count = Std.int(tile.iwidth / Main.WIDTH);
        if(zone == 0) {
            var p = addParallax(zone, 0, .05, levelWidth, levelHeight, false);
            p.scrollX = -6;
            addParallax(zone, 1, .4, levelWidth, levelHeight, false);
            p = addParallax(zone, 2, .4, levelWidth, levelHeight, true);
            p.displaceMultX = p.displaceMultY = 4;
            p = addParallax(zone, 3, .6, levelWidth, levelHeight, true);
            p.displaceMultX = p.displaceMultY = 10;
            addParallax(zone, 4, .8, levelWidth, levelHeight, false);
        } else if(zone == 1) {
            addParallax(zone, 0, 0, levelWidth, levelHeight, false);
            var p = addParallax(zone, 1, .3, levelWidth, levelHeight, true);
            p.displaceMultX = 10;
            addParallax(zone, 2, .3, levelWidth, levelHeight, false);
            addParallax(zone, 3, .3, levelWidth, levelHeight, false);
            addParallax(zone, 4, .8, levelWidth, levelHeight, false);
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
            p.update(dt);
        }
    }
}