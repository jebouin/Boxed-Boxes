package background;

import hxd.Res;
import h2d.Tile;

class Background {
    var timer : Float = 0;
    var parallaxes : Array<Parallax> = [];

    public function new() {
    }

    public function addSlicedParallax(zone:Int, frame:Int, speed:Float, levelWidth:Int, levelHeight:Int, displace:Bool) {
        var r = Res.load("gfx/backgrounds/back" + zone + ".png");
        var tile = r.toTile();
        var sub = tile.sub(frame * Main.WIDTH, 0, Main.WIDTH, tile.iheight);
        var p = new SlicedParallax(sub, 180, Game.LAYER_BACK, speed, levelWidth, levelHeight, displace);
        parallaxes.push(p);
        return p;
    }

    public function addTiledParallax(zone:Int, frame:Int, speed:Float, levelWidth:Int, levelHeight:Int) {
        var r = Res.load("gfx/backgrounds/back" + zone + ".png");
        var tile = r.toTile();
        var sub = tile.sub(frame * Main.WIDTH, 0, Main.WIDTH, tile.iheight);
        var p = new TiledParallax(sub, Game.LAYER_BACK, speed, levelWidth, levelHeight);
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
            var p = addSlicedParallax(zone, 0, .05, levelWidth, levelHeight, false);
            p.scrollX = -6;
            addSlicedParallax(zone, 1, .4, levelWidth, levelHeight, false);
            p = addSlicedParallax(zone, 2, .4, levelWidth, levelHeight, true);
            p.displaceMultX = p.displaceMultY = 5;
            p.displaceTop = p.displaceBottom = false;
            p = addSlicedParallax(zone, 3, .6, levelWidth, levelHeight, true);
            p.displaceMultX = p.displaceMultY = 10;
            p.displaceTop = p.displaceBottom = false;
            addSlicedParallax(zone, 4, .8, levelWidth, levelHeight, false);
        } else if(zone == 1) {
            addSlicedParallax(zone, 0, 0, levelWidth, levelHeight, false);
            var p = addSlicedParallax(zone, 1, .1, levelWidth, levelHeight, true);
            p.displaceMultX = 10;
            p.displaceTop = false;
            addSlicedParallax(zone, 2, .1, levelWidth, levelHeight, false);
            addSlicedParallax(zone, 3, .1, levelWidth, levelHeight, false);
            addSlicedParallax(zone, 4, .8, levelWidth, levelHeight, false);
        } else if(zone == 2) {
            addTiledParallax(zone, 0, 0, levelWidth, levelHeight);
            addTiledParallax(zone, 1, .2, levelWidth, levelHeight);
            addTiledParallax(zone, 2, .5, levelWidth, levelHeight);
            addTiledParallax(zone, 3, .8, levelWidth, levelHeight);
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